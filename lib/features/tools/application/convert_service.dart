import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:docnook/domain/sheetmodel/sheet_model.dart';
import 'package:docnook/engines/convert/doc_fonts.dart';
import 'package:docnook/engines/convert/docmodel_to_pdf.dart';
import 'package:docnook/engines/convert/docx_writer.dart';
import 'package:docnook/engines/convert/pdf_to_docmodel.dart';
import 'package:docnook/engines/convert/sheet_export.dart';
import 'package:docnook/engines/convert/sheet_to_pdf.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/office/parse_document.dart';
import 'package:docnook/engines/office/pptx/pptx_parser.dart';
import 'package:docnook/engines/office/sheet/csv_parser.dart';
import 'package:docnook/engines/office/sheet/ods_parser.dart';
import 'package:docnook/engines/office/xlsx/xlsx_parser.dart';
import 'package:docnook/engines/pdf/pdfium_editor.dart';
import 'package:docnook/engines/pdf/raster.dart';
import 'package:docnook/engines/scan/scan_pdf_writer.dart';
import 'package:docnook/features/scan/application/scan_service.dart';
import 'package:docnook/features/tools/application/pdf_tools_service.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

final convertServiceProvider = Provider<ConvertService>(ConvertService.new);

/// A PDF picked for a converter, with its password if it has one.
typedef PdfPick = ({ToolInput input, String? password});

/// The converters (BLUEPRINT 2.3). Outputs go to
/// `Documents/DocNook/Converted/`. Batch converters keep going when one
/// file fails and list it on the result screen.
class ConvertService {
  ConvertService(this._ref);

  final Ref _ref;
  DocFontBytes? _fonts;

  PdfToolsService get _tools => _ref.read(pdfToolsServiceProvider);
  JobRunner get _jobs => _tools.jobs;

  static const _subdir = 'Converted';
  static const _long = Duration(minutes: 10);

  /// The bundled fonts, loaded from the app bundle once.
  Future<DocFontBytes> fonts() async => _fonts ??= DocFontBytes.of([
    for (final f in DocFontBytes.files)
      (await rootBundle.load('assets/docfonts/$f')).buffer.asUint8List(),
  ]);

  static String _base(String name) => p.basenameWithoutExtension(name);

  /// Runs [each] for every input; failures are collected, not fatal,
  /// unless every input fails.
  Future<ToolResult> _batch(
    ToolId tool,
    List<ToolInput> inputs,
    EditControl control,
    Future<List<ToolOutput>> Function(
      ToolInput input,
      Directory work,
      EditControl c,
    )
    each,
  ) => _tools.guarded(tool, (work) async {
    final outputs = <ToolOutput>[];
    final failures = <(String, DocNookFailure)>[];
    for (var i = 0; i < inputs.length; i++) {
      control.check();
      final step = EditControl(
        onProgress: (v, {page, of}) =>
            control.report((i + v) / inputs.length, page: page, of: of),
        isCancelled: () {
          try {
            control.check();
            return false;
          } on DocNookFailure {
            return true;
          }
        },
      );
      try {
        outputs.addAll(await each(inputs[i], work, step));
      } on DocNookFailure catch (f) {
        if (f.kind == FailureKind.cancelled) rethrow;
        failures.add((inputs[i].name, f));
      } on Object catch (e) {
        failures.add((inputs[i].name, DocNookFailure.from(e)));
      }
    }
    if (outputs.isEmpty) {
      throw failures.isEmpty
          ? const DocNookFailure.unknown()
          : failures.first.$2;
    }
    return ToolResult(tool: tool, outputs: outputs, failures: failures);
  });

  // Images → PDF ----------------------------------------------------------------

  Future<ToolResult> imagesToPdf({
    required List<ToolInput> inputs,
    required ScanPageSize pageSize,
    required double margin,
    required ScanQuality quality,
    required String name,
    required EditControl control,
  }) => _tools.guarded(ToolId.imagesToPdf, (work) async {
    final plans = <PdfPagePlan>[];
    final failures = <(String, DocNookFailure)>[];
    for (var i = 0; i < inputs.length; i++) {
      control.check();
      try {
        final source = await _tools.localPath(inputs[i]);
        final prepared = (await _jobs.run(prepareImageMax, (
          source,
          p.join(work.path, 'img_$i.jpg'),
          quality.jpegQuality,
          quality.maxEdge,
        ), debugName: 'prepare-image').result).orThrow;
        plans.add(_imagePage(prepared, pageSize, margin));
      } on DocNookFailure catch (f) {
        if (f.kind == FailureKind.cancelled) rethrow;
        failures.add((inputs[i].name, f));
      }
      control.report(
        0.85 * (i + 1) / inputs.length,
        page: i + 1,
        of: inputs.length,
      );
    }
    if (plans.isEmpty) {
      throw failures.isEmpty
          ? const DocNookFailure.unknown()
          : failures.first.$2;
    }
    final out = p.join(work.path, 'out.pdf');
    (await _jobs
            .run(
              _scanPdfJob,
              ScanPdfRequest(output: out, pages: plans, title: name),
              timeout: _long,
              debugName: 'images-pdf',
            )
            .result)
        .orThrow;
    final output = await _tools.publish(
      out,
      name,
      pages: plans.length,
      subdir: _subdir,
    );
    return ToolResult(
      tool: ToolId.imagesToPdf,
      outputs: [output],
      failures: failures,
    );
  });

  /// One picture on one page: centred inside [margin] on A4 / Letter, or
  /// a page the picture's own shape ("Fit", 595 pt wide).
  static PdfPagePlan _imagePage(
    PreparedImage image,
    ScanPageSize size,
    double margin,
  ) {
    final aspect = image.height / image.width;
    if (size == ScanPageSize.fit) {
      const w = 595.28;
      final inner = w - margin * 2;
      final h = inner * aspect + margin * 2;
      return PdfPagePlan(w, h, [
        PlacedImage(
          path: image.path,
          x: margin,
          y: margin,
          width: inner,
          height: inner * aspect,
        ),
      ]);
    }
    // Landscape pictures go on landscape pages.
    final landscape = image.width > image.height;
    final pw = landscape ? size.height : size.width;
    final ph = landscape ? size.width : size.height;
    final maxW = pw - margin * 2;
    final maxH = ph - margin * 2;
    var w = maxW;
    var h = w * aspect;
    if (h > maxH) {
      h = maxH;
      w = h / aspect;
    }
    return PdfPagePlan(pw, ph, [
      PlacedImage(
        path: image.path,
        x: (pw - w) / 2,
        y: (ph - h) / 2,
        width: w,
        height: h,
      ),
    ]);
  }

  // PDF → images / text / Word ------------------------------------------------

  Future<ToolResult> pdfToImages({
    required List<PdfPick> inputs,
    required bool png,
    required int dpi,
    required EditControl control,
  }) => _batch(ToolId.pdfToImages, [for (final i in inputs) i.input], control, (
    input,
    work,
    c,
  ) async {
    final password = inputs.firstWhere((i) => i.input == input).password;
    final path = await _tools.localPath(input);
    final doc = await PdfDocument.openFile(
      path,
      passwordProvider: password == null ? null : () => password,
    );
    final outputs = <ToolOutput>[];
    try {
      final count = doc.pages.length;
      final digits = math.max(2, '$count'.length);
      for (var i = 0; i < count; i++) {
        c.check();
        final page = doc.pages[i];
        // Cap the size so a poster-sized page can't exhaust memory.
        final scale = math.min(
          dpi / 72,
          6000 / math.max(page.width, page.height),
        );
        final image = await page.render(
          fullWidth: page.width * scale,
          fullHeight: page.height * scale,
          backgroundColor: 0xFFFFFFFF,
        );
        if (image == null) throw const DocNookFailure.corrupt(detail: 'render');
        final pixels = Uint8List.fromList(image.pixels);
        final (w, h) = (image.width, image.height);
        image.dispose();
        final ext = png ? 'png' : 'jpg';
        final file = p.join(work.path, 'p$i.$ext');
        (await _jobs
                .run(
                  rasterPage,
                  RasterPageArgs(
                    bgra: pixels,
                    width: w,
                    height: h,
                    output: file,
                    quality: 88,
                    png: png,
                  ),
                  debugName: 'pdf-image',
                )
                .result)
            .orThrow;
        final number = '${i + 1}'.padLeft(digits, '0');
        outputs.add(
          await _tools.publish(
            file,
            count == 1 ? _base(input.name) : '${_base(input.name)}_p$number',
            subdir: _subdir,
            format: png ? DocFormat.png : DocFormat.jpeg,
            extension: ext,
          ),
        );
        c.report((i + 1) / count, page: i + 1, of: count);
      }
    } finally {
      await doc.dispose();
    }
    return outputs;
  });

  /// Text layer of every page; pages without one are read with OCR when
  /// [ocr] is on (scanned PDFs).
  Future<ToolResult> pdfToText({
    required ToolInput input,
    required String? password,
    required bool ocr,
    required String name,
    required EditControl control,
  }) => _tools.guarded(ToolId.pdfToText, (work) async {
    final path = await _tools.localPath(input);
    final doc = await PdfDocument.openFile(
      path,
      passwordProvider: password == null ? null : () => password,
    );
    final out = StringBuffer();
    try {
      final count = doc.pages.length;
      for (var i = 0; i < count; i++) {
        control.check();
        final page = doc.pages[i];
        var text = (await page.loadText())?.fullText.trim() ?? '';
        if (text.length < 8 && ocr) text = await _ocrPage(page, work, i);
        if (i > 0) out.write('\n\n');
        out.write(text);
        control.report(0.9 * (i + 1) / count, page: i + 1, of: count);
      }
    } finally {
      await doc.dispose();
    }
    final file = p.join(work.path, 'out.txt');
    File(file).writeAsStringSync(out.toString(), flush: true);
    final output = await _tools.publish(
      file,
      name,
      subdir: _subdir,
      format: DocFormat.plainText,
      extension: 'txt',
    );
    return ToolResult(tool: ToolId.pdfToText, outputs: [output]);
  });

  Future<String> _ocrPage(PdfPage page, Directory work, int index) async {
    const scale = 200 / 72;
    final image = await page.render(
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
      backgroundColor: 0xFFFFFFFF,
    );
    if (image == null) return '';
    final pixels = Uint8List.fromList(image.pixels);
    final (w, h) = (image.width, image.height);
    image.dispose();
    final jpg = p.join(work.path, 'ocr_$index.jpg');
    (await _jobs
            .run(
              rasterPage,
              RasterPageArgs(
                bgra: pixels,
                width: w,
                height: h,
                output: jpg,
                quality: 85,
              ),
            )
            .result)
        .orThrow;
    try {
      final result = await _ref
          .read(ocrServiceProvider)
          .recognize(jpg, width: w, height: h);
      return result.text;
    } on Object {
      return '';
    }
  }

  Future<ToolResult> pdfToWord({
    required ToolInput input,
    required String? password,
    required String name,
    required EditControl control,
  }) => _tools.guarded(ToolId.pdfToWord, (work) async {
    final path = await _tools.localPath(input);
    final source = PdfSource(path, password: password);
    final info = await PdfiumEditor.inspect(source);
    final pages = <PdfPageContent>[];
    final count = info.pageCount;
    for (var i = 0; i < count; i++) {
      control.check();
      final pageInfo = info.pages[i];
      final vw = pageInfo.visibleWidth;
      final vh = pageInfo.visibleHeight;
      final (text, raw, sizes) = await PdfiumEditor.pageChars(source, i);
      final boxes = <(double, double, double, double)>[];
      for (var c = 0; c + 3 < raw.length; c += 4) {
        final (l, t) = pageInfo.toVisible(raw[c], raw[c + 3]);
        final (rr, b) = pageInfo.toVisible(raw[c + 2], raw[c + 1]);
        boxes.add((
          math.min(l, rr) * vw,
          math.min(t, b) * vh,
          math.max(l, rr) * vw,
          math.max(t, b) * vh,
        ));
      }
      final pictures = await PdfiumEditor.extractImages(source, i);
      pages.add(
        PdfPageContent(
          width: vw,
          height: vh,
          lines: linesFromChars(text, boxes, sizes: sizes),
          pictures: [
            for (final (jpeg, x, y, w, h) in pictures)
              PdfPagePicture(jpeg, x, y, w, h),
          ],
        ),
      );
      control.report(0.7 * (i + 1) / count, page: i + 1, of: count);
    }
    final out = p.join(work.path, 'out.docx');
    (await _jobs
            .run(
              _pdfToDocxJob,
              (pages, out, name),
              timeout: _long,
              debugName: 'pdf-docx',
            )
            .result)
        .orThrow;
    final output = await _tools.publish(
      out,
      name,
      subdir: _subdir,
      format: DocFormat.docx,
      extension: 'docx',
    );
    return ToolResult(tool: ToolId.pdfToWord, outputs: [output]);
  });

  // Documents → PDF -------------------------------------------------------------

  /// Word, ODT, RTF, PowerPoint, text and Markdown → PDF, one PDF per file.
  Future<ToolResult> documentsToPdf({
    required ToolId tool,
    required List<ToolInput> inputs,
    required EditControl control,
  }) async {
    final fonts = await this.fonts();
    return await _batch(tool, inputs, control, (input, work, c) async {
      final path = await _tools.localPath(input);
      final out = p.join(work.path, '${inputs.indexOf(input)}.pdf');
      final pages =
          (await _jobs
                  .run(
                    _documentToPdfJob,
                    (path, input.format, fonts, out),
                    timeout: _long,
                    debugName: 'doc-pdf',
                  )
                  .result)
              .orThrow;
      c.report(0.9);
      return [
        await _tools.publish(
          out,
          _base(input.name),
          pages: pages,
          subdir: _subdir,
        ),
      ];
    });
  }

  Future<ToolResult> sheetsToPdf({
    required List<ToolInput> inputs,
    required bool fitToWidth,
    required EditControl control,
  }) async {
    final fonts = await this.fonts();
    return await _batch(ToolId.excelToPdf, inputs, control, (
      input,
      work,
      c,
    ) async {
      final path = await _tools.localPath(input);
      final out = p.join(work.path, '${inputs.indexOf(input)}.pdf');
      final pages =
          (await _jobs
                  .run(
                    _sheetToPdfJob,
                    (path, input.format, fonts, out, fitToWidth),
                    timeout: _long,
                    debugName: 'sheet-pdf',
                  )
                  .result)
              .orThrow;
      c.report(0.9);
      return [
        await _tools.publish(
          out,
          _base(input.name),
          pages: pages,
          subdir: _subdir,
        ),
      ];
    });
  }

  // CSV ↔ Excel, image text -------------------------------------------------------

  /// CSV/TSV → XLSX; XLSX/ODS → one CSV per visible sheet.
  Future<ToolResult> csvExcel({
    required ToolInput input,
    required String name,
    required EditControl control,
  }) => _tools.guarded(ToolId.csvExcel, (work) async {
    final path = await _tools.localPath(input);
    final format = input.format;
    final wb = (await _jobs.run(_parseWorkbookJob, (
      path,
      format,
    ), timeout: _long).result).orThrow;
    control.report(0.5);
    if (format == DocFormat.csv || format == DocFormat.tsv) {
      final out = p.join(work.path, 'out.xlsx');
      (await _jobs.run(writeXlsxJob, (wb, out, true)).result).orThrow;
      final output = await _tools.publish(
        out,
        name,
        subdir: _subdir,
        format: DocFormat.xlsx,
        extension: 'xlsx',
      );
      return ToolResult(tool: ToolId.csvExcel, outputs: [output]);
    }
    final outputs = <ToolOutput>[];
    final visible = [
      for (var i = 0; i < wb.sheets.length; i++)
        if (!wb.sheets[i].hidden) i,
    ];
    for (final i in visible) {
      control.check();
      final out = p.join(work.path, 'sheet_$i.csv');
      (await _jobs.run(writeCsvJob, (wb, i, out)).result).orThrow;
      outputs.add(
        await _tools.publish(
          out,
          visible.length == 1 ? name : '${name}_${wb.sheets[i].name}',
          subdir: _subdir,
          format: DocFormat.csv,
          extension: 'csv',
        ),
      );
    }
    return ToolResult(tool: ToolId.csvExcel, outputs: outputs);
  });

  /// OCR of one picture, saved as a .txt (Scan group, "Extract text").
  Future<ToolResult> extractText({
    required ToolInput input,
    required String name,
    required EditControl control,
  }) => _tools.guarded(ToolId.extractText, (work) async {
    final path = await _tools.localPath(input);
    final prepared = (await _jobs.run(prepareImageMax, (
      path,
      p.join(work.path, 'ocr.jpg'),
      90,
      3000,
    )).result).orThrow;
    control.report(0.3);
    final page = await _ref
        .read(ocrServiceProvider)
        .recognize(
          prepared.path,
          width: prepared.width,
          height: prepared.height,
        );
    final text = page.text.trim();
    if (text.isEmpty) throw const DocNookFailure.unsupported(detail: 'no text');
    final out = p.join(work.path, 'out.txt');
    File(out).writeAsStringSync(text, flush: true);
    final output = await _tools.publish(
      out,
      name,
      subdir: _subdir,
      format: DocFormat.plainText,
      extension: 'txt',
    );
    return ToolResult(tool: ToolId.extractText, outputs: [output]);
  });

  /// The text of a .txt output, for the "Copy text" action.
  static Future<String> readText(String path) async =>
      utf8.decode(await File(path).readAsBytes(), allowMalformed: true);
}

// Isolate entry points.

int _scanPdfJob(ScanPdfRequest request, JobContext _) => writeScanPdf(request);

/// Parses and renders in one isolate, so the parsed model never has to be
/// copied between isolates.
Future<int> _documentToPdfJob(
  (String, DocFormat, DocFontBytes, String) args,
  JobContext context,
) async {
  final (path, format, fonts, output) = args;
  final DocModel model;
  var mono = false;
  switch (format) {
    case DocFormat.pptx:
      model = PptxParser.parseFile(path);
    case DocFormat.plainText || DocFormat.code:
      mono = format == DocFormat.code;
      final text = decodeText(File(path).readAsBytesSync());
      model = DocModel(
        sections: [
          DocSection(
            blocks: [
              for (final line in const LineSplitter().convert(text))
                Paragraph([
                  TextRun(line.isEmpty ? ' ' : line),
                ], style: const ParagraphStyle(spaceAfter: 2)),
            ],
          ),
        ],
      );
    case DocFormat.docx ||
        DocFormat.dotx ||
        DocFormat.odt ||
        DocFormat.rtf ||
        DocFormat.markdown:
      model = parseToDocModel(ParseRequest(path, format), context);
    case _:
      throw const DocNookFailure.unsupported();
  }
  context.progress(0.3);
  return await docModelToPdf(
    DocToPdfRequest(
      model: model,
      fonts: fonts,
      output: output,
      monospaceBody: mono,
    ),
    context,
  );
}

Workbook _parseWorkbook(String path, DocFormat format) => switch (format) {
  DocFormat.xlsx || DocFormat.xlsm => XlsxParser.parseFile(path),
  DocFormat.ods => OdsParser.parseFile(path),
  DocFormat.tsv => CsvParser.parseFile(path, delimiter: '\t'),
  DocFormat.csv => CsvParser.parseFile(path),
  _ => throw const DocNookFailure.unsupported(),
};

Workbook _parseWorkbookJob((String, DocFormat) args, JobContext _) =>
    _parseWorkbook(args.$1, args.$2);

Future<int> _sheetToPdfJob(
  (String, DocFormat, DocFontBytes, String, bool) args,
  JobContext context,
) {
  final (path, format, fonts, output, fit) = args;
  final wb = _parseWorkbook(path, format);
  context.progress(0.3);
  return sheetToPdf(
    SheetToPdfRequest(
      workbook: wb,
      fonts: fonts,
      output: output,
      fitToWidth: fit,
    ),
    context,
  );
}

int _pdfToDocxJob(
  (List<PdfPageContent>, String, String) args,
  JobContext context,
) {
  final (pages, output, title) = args;
  final model = pdfPagesToDocModel(pages, title: title);
  return writeDocxJob((model, output), context);
}

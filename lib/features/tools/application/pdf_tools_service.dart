import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/data/files/file_type_detector.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/pdf/pdfium_editor.dart';
import 'package:docnook/engines/pdf/raster.dart';
import 'package:docnook/engines/pdf/security/pdf_encryptor.dart';
import 'package:docnook/engines/scan/scan_pdf_writer.dart';
import 'package:docnook/features/scan/application/scan_service.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

final pdfToolsServiceProvider = Provider<PdfToolsService>(PdfToolsService.new);

/// Runs the PDF tools (BLUEPRINT 2.4) and publishes their output to
/// `Documents/DocNook/Edited/` (FR-CORE-03). Inputs are never modified,
/// except by Organize when the user picked "overwrite" (CLAUDE.md rule 10).
class PdfToolsService {
  PdfToolsService(this._ref);

  final Ref _ref;

  JobRunner get _jobs => _ref.read(jobRunnerProvider);
  JobRunner get jobs => _jobs;

  static final _toolSuffixes = RegExp(
    '(_(merged|organized|compressed|protected|unlocked|watermarked|'
    r'numbered|signed|annotated|filled|redacted))+$',
  );

  /// `Merged_2026-11-11_1432` for Merge; `name_suffix` otherwise.
  static String defaultName(ToolId tool, String? inputName, DateTime now) {
    final stamp = DateFormat('yyyy-MM-dd_HHmm').format(now);
    if (tool == ToolId.merge ||
        tool == ToolId.imagesToPdf ||
        inputName == null) {
      final label = switch (tool) {
        ToolId.merge => 'Merged',
        ToolId.imagesToPdf => 'Images',
        _ => tool.converts ? 'Converted' : 'Edited',
      };
      return '${label}_$stamp';
    }
    // A chained result keeps one suffix: "Report_unlocked", not
    // "Report_protected_unlocked".
    final base = p
        .basenameWithoutExtension(inputName)
        .replaceFirst(_toolSuffixes, '');
    final suffix = switch (tool) {
      ToolId.merge => 'merged',
      ToolId.split => 'part',
      ToolId.organize => 'organized',
      ToolId.compress => 'compressed',
      ToolId.protect => 'protected',
      ToolId.unlock => 'unlocked',
      ToolId.watermark => 'watermarked',
      ToolId.pageNumbers => 'numbered',
      ToolId.sign => 'signed',
      ToolId.annotate => 'annotated',
      ToolId.fillForms => 'filled',
      ToolId.redact => 'redacted',
      // Converters keep the name; the new extension tells them apart.
      _ => '',
    };
    return suffix.isEmpty ? base : '${base}_$suffix';
  }

  /// A readable local copy of [input] (content URIs are streamed into the
  /// cache once per uri and size).
  Future<String> localPath(ToolInput input) async {
    final uri = input.uri;
    if (!uri.startsWith('content://')) {
      final path = uri.startsWith('file://')
          ? Uri.parse(uri).toFilePath()
          : uri;
      if (!File(path).existsSync()) {
        throw const DocNookFailure.corrupt(detail: 'missing');
      }
      return path;
    }
    final paths = _ref.read(appPathsProvider);
    final ext = FileTypeDetector.extensionOf(input.name);
    final key = sha1
        .convert(utf8.encode('$uri|${input.size ?? ''}'))
        .toString();
    final dest = p.join(paths.opened, ext.isEmpty ? key : '$key.$ext');
    final cached = File(dest);
    if (cached.existsSync() &&
        (input.size == null || cached.lengthSync() == input.size)) {
      return dest;
    }
    final copied = await _ref.read(platformProvider).copyToCache(uri, dest);
    copied.orThrow;
    return dest;
  }

  /// Page sizes and flags; throws `passwordRequired` / `wrongPassword`.
  Future<PdfInfo> inspect(ToolInput input, {String? password}) async =>
      await PdfiumEditor.inspect(
        PdfSource(await localPath(input), password: password),
      );

  Directory workDir() =>
      Directory(_ref.read(appPathsProvider).tmp).createTempSync('tool_');

  Future<ToolResult> guarded(
    ToolId tool,
    Future<ToolResult> Function(Directory work) body,
  ) async {
    final work = workDir();
    try {
      return await body(work);
    } finally {
      try {
        work.deleteSync(recursive: true);
      } on FileSystemException {
        // Swept after 24 h.
      }
    }
  }

  /// Copies [file] to `Documents/DocNook/Edited/<name>.pdf` and registers
  /// it in the library.
  Future<ToolOutput> _publish(String file, String name, {int? pages}) =>
      publish(file, name, pages: pages);

  /// Copies [file] to `Documents/DocNook/<subdir>/<name>.<ext>` and
  /// registers it in the library (FR-CORE-03).
  Future<ToolOutput> publish(
    String file,
    String name, {
    int? pages,
    String subdir = 'Edited',
    DocFormat format = DocFormat.pdf,
    String extension = 'pdf',
  }) async {
    final clean = ScanService.safeName(name);
    final saved =
        (await _ref
                .read(platformProvider)
                .saveToDocuments(
                  source: file,
                  subdir: subdir,
                  name: '$clean.$extension',
                  mime: format.mime,
                ))
            .orThrow;
    final size = File(file).lengthSync();
    final uri = saved.path ?? saved.uri;
    final documents = _ref.read(documentRepositoryProvider);
    final id = await documents.upsert(
      uri: uri,
      name: saved.name,
      format: format,
      source: DocSource.created,
      extension: extension,
      sizeBytes: size,
      modifiedAt: DateTime.now(),
    );
    final count = format == DocFormat.pdf
        ? pages ?? await _pageCount(file)
        : pages;
    if (count != null) await documents.setPageCount(id, count);
    return ToolOutput(
      uri: uri,
      name: saved.name,
      bytes: size,
      pages: count,
      documentId: id,
      mime: format.mime,
    );
  }

  Future<int?> _pageCount(String file) async {
    try {
      return (await PdfiumEditor.inspect(PdfSource(file))).pageCount;
    } on DocNookFailure {
      return null;
    }
  }

  // Merge, split, organize ----------------------------------------------------

  /// Joins PDFs and pictures in the given order (pictures become one page
  /// each, sized like A4 at their own aspect ratio).
  Future<ToolResult> merge({
    required List<ToolInput> inputs,
    required Map<int, String> passwords,
    required String name,
    required EditControl control,
  }) => guarded(ToolId.merge, (work) async {
    final sources = <PdfSource>[];
    final pages = <PageSpec>[];
    final images = <int>[];
    for (var i = 0; i < inputs.length; i++) {
      if (inputs[i].type == DocType.image) images.add(i);
    }
    // Pictures first become one small PDF, so every input is a PDF.
    final imagePdf = images.isEmpty
        ? null
        : await _imagesToPdf(
            [for (final i in images) inputs[i]],
            p.join(work.path, 'images.pdf'),
            work,
            control,
          );
    var imageIndex = 0;
    for (var i = 0; i < inputs.length; i++) {
      control.check();
      if (inputs[i].type == DocType.image) {
        if (!sources.any((s) => s.path == imagePdf)) {
          sources.add(PdfSource(imagePdf!));
        }
        final src = sources.indexWhere((s) => s.path == imagePdf);
        pages.add(PageSpec.page(src, imageIndex++));
        continue;
      }
      final path = await localPath(inputs[i]);
      final source = PdfSource(path, password: passwords[i]);
      final info = await PdfiumEditor.inspect(source);
      sources.add(source);
      final src = sources.length - 1;
      for (var k = 0; k < info.pageCount; k++) {
        pages.add(PageSpec.page(src, k));
      }
    }
    final out = p.join(work.path, 'out.pdf');
    await PdfiumEditor.assemble(
      sources: sources,
      pages: pages,
      output: out,
      control: _scaled(control, 0.2, 0.95),
    );
    final output = await _publish(out, name, pages: pages.length);
    return ToolResult(tool: ToolId.merge, outputs: [output]);
  });

  Future<String> _imagesToPdf(
    List<ToolInput> images,
    String output,
    Directory work,
    EditControl control,
  ) async {
    final plans = <PdfPagePlan>[];
    for (var i = 0; i < images.length; i++) {
      control.check();
      final source = await localPath(images[i]);
      final prepared = (await _jobs.run(prepareImage, (
        source,
        p.join(work.path, 'img_$i.jpg'),
        90,
      ), debugName: 'prepare-image').result).orThrow;
      plans.add(
        planSinglePage(
          path: prepared.path,
          pixelWidth: prepared.width,
          pixelHeight: prepared.height,
          size: ScanPageSize.fit,
        ),
      );
      control.report(0.2 * (i + 1) / images.length);
    }
    (await _jobs
            .run(
              _scanPdfJob,
              ScanPdfRequest(output: output, pages: plans),
              timeout: const Duration(minutes: 5),
              debugName: 'images-pdf',
            )
            .result)
        .orThrow;
    return output;
  }

  /// One output per group of 0-based page indices.
  Future<ToolResult> split({
    required ToolInput input,
    required String? password,
    required List<List<int>> groups,
    required String name,
    required EditControl control,
  }) => guarded(ToolId.split, (work) async {
    final path = await localPath(input);
    final outputs = <ToolOutput>[];
    for (var g = 0; g < groups.length; g++) {
      control.check();
      final out = p.join(work.path, 'part_$g.pdf');
      await PdfiumEditor.assemble(
        sources: [PdfSource(path, password: password)],
        pages: [for (final i in groups[g]) PageSpec.page(0, i)],
        output: out,
        control: _scaled(control, g / groups.length, (g + 1) / groups.length),
      );
      final partName = groups.length == 1 ? name : '${name}_${g + 1}';
      outputs.add(await _publish(out, partName, pages: groups[g].length));
    }
    return ToolResult(tool: ToolId.split, outputs: outputs);
  });

  /// Rebuilds the document from [pages] (reorder, rotate, delete,
  /// duplicate, blank pages). [extraImages] are pictures inserted as pages:
  /// a [PageSpec] with source 1 points into them, in order.
  Future<ToolResult> organize({
    required ToolInput input,
    required String? password,
    required List<PageSpec> pages,
    required List<ToolInput> extraImages,
    required String name,
    required bool overwrite,
    required EditControl control,
  }) => guarded(ToolId.organize, (work) async {
    final path = await localPath(input);
    final sources = [PdfSource(path, password: password)];
    if (extraImages.isNotEmpty) {
      sources.add(
        PdfSource(
          await _imagesToPdf(
            extraImages,
            p.join(work.path, 'inserted.pdf'),
            work,
            control,
          ),
        ),
      );
    }
    final out = p.join(work.path, 'out.pdf');
    await PdfiumEditor.assemble(
      sources: sources,
      pages: pages,
      output: out,
      control: _scaled(control, 0.2, 0.95),
    );
    if (overwrite && input.overwritable) {
      return await _overwrite(input, path, out, ToolId.organize, pages.length);
    }
    return ToolResult(
      tool: ToolId.organize,
      outputs: [await _publish(out, name, pages: pages.length)],
    );
  });

  /// Replaces the original file: only when the user chose "overwrite".
  Future<ToolResult> _overwrite(
    ToolInput input,
    String original,
    String built,
    ToolId tool,
    int pages,
  ) async {
    final temp = '$original.docnook-tmp';
    File(built).copySync(temp);
    File(temp).renameSync(original);
    final size = File(original).lengthSync();
    final documents = _ref.read(documentRepositoryProvider);
    final id = await documents.upsert(
      uri: original,
      name: input.name,
      format: DocFormat.pdf,
      source: DocSource.discovered,
      extension: 'pdf',
      sizeBytes: size,
      modifiedAt: DateTime.now(),
    );
    await documents.setPageCount(id, pages);
    return ToolResult(
      tool: tool,
      overwritten: true,
      outputs: [
        ToolOutput(
          uri: original,
          name: input.name,
          bytes: size,
          pages: pages,
          documentId: id,
        ),
      ],
    );
  }

  // Compress -------------------------------------------------------------------

  Future<ToolResult> compress({
    required ToolInput input,
    required String? password,
    required CompressLevel level,
    required bool ocr,
    required String name,
    required EditControl control,
  }) => guarded(ToolId.compress, (work) async {
    final path = await localPath(input);
    final source = PdfSource(path, password: password);
    final before = File(path).lengthSync();
    final out = p.join(work.path, 'out.pdf');
    switch (level) {
      case CompressLevel.light:
        // A plain re-save drops old incremental updates; rebuilding from
        // the pages also drops unused objects. Keep whichever is smaller.
        final resaved = p.join(work.path, 'resaved.pdf');
        await PdfiumEditor.resave(source: source, output: resaved);
        control.report(0.4);
        final info = await PdfiumEditor.inspect(source);
        await PdfiumEditor.assemble(
          sources: [source],
          pages: [for (var i = 0; i < info.pageCount; i++) PageSpec.page(0, i)],
          output: out,
          control: _scaled(control, 0.4, 0.9),
        );
        if (File(resaved).lengthSync() < File(out).lengthSync()) {
          File(resaved).copySync(out);
        }
      case CompressLevel.balanced:
        await PdfiumEditor.recompressImages(
          source: source,
          output: out,
          control: _scaled(control, 0, 0.95),
        );
      case CompressLevel.strong:
        final info = await PdfiumEditor.inspect(source);
        final raster = await _rasterize(
          path: path,
          password: password,
          pages: {for (var i = 0; i < info.pageCount; i++) i: const []},
          scale: 1.6,
          quality: 55,
          ocr: ocr,
          work: work,
          control: _scaled(control, 0, 0.95),
        );
        File(raster).copySync(out);
    }
    final output = await _publish(out, name);
    return ToolResult(
      tool: ToolId.compress,
      outputs: [output],
      inputBytes: before,
    );
  });

  /// Renders the given pages (0-based index → boxes to black out) to JPEG
  /// and writes them, in index order, as a new PDF. With [ocr] each page
  /// gets an invisible text layer so its text stays searchable.
  Future<String> _rasterize({
    required String path,
    required String? password,
    required Map<int, List<RedactBox>> pages,
    required double scale,
    required int quality,
    required bool ocr,
    required Directory work,
    required EditControl control,
  }) async {
    final doc = await PdfDocument.openFile(
      path,
      passwordProvider: password == null ? null : () => password,
    );
    final plans = <PdfPagePlan>[];
    final indices = pages.keys.toList()..sort();
    try {
      for (var k = 0; k < indices.length; k++) {
        control.check();
        final index = indices[k];
        final page = doc.pages[index];
        final w = (page.width * scale).round();
        final h = (page.height * scale).round();
        final image = await page.render(
          fullWidth: w.toDouble(),
          fullHeight: h.toDouble(),
          backgroundColor: 0xFFFFFFFF,
        );
        if (image == null) throw const DocNookFailure.corrupt(detail: 'render');
        final pixels = Uint8List.fromList(image.pixels);
        final iw = image.width;
        final ih = image.height;
        image.dispose();
        final jpg = p.join(work.path, 'r_$index.jpg');
        (await _jobs
                .run(
                  rasterPage,
                  RasterPageArgs(
                    bgra: pixels,
                    width: iw,
                    height: ih,
                    output: jpg,
                    quality: quality,
                    boxes: [
                      for (final b in pages[index]!) ...[
                        b.left,
                        b.top,
                        b.right,
                        b.bottom,
                      ],
                    ],
                  ),
                  debugName: 'raster',
                )
                .result)
            .orThrow;
        String? text;
        if (ocr) {
          try {
            final result = await _ref
                .read(ocrServiceProvider)
                .recognize(jpg, width: iw, height: ih);
            text = result.encode();
          } on Object {
            // No OCR engine: the page stays an image without text.
          }
        }
        plans.add(
          PdfPagePlan(page.width, page.height, [
            PlacedImage(
              path: jpg,
              x: 0,
              y: 0,
              width: page.width,
              height: page.height,
              ocr: text,
            ),
          ]),
        );
        control.report(
          0.85 * (k + 1) / indices.length,
          page: k + 1,
          of: indices.length,
        );
      }
    } finally {
      await doc.dispose();
    }
    final out = p.join(work.path, 'raster.pdf');
    (await _jobs
            .run(
              _scanPdfJob,
              ScanPdfRequest(output: out, pages: plans),
              timeout: const Duration(minutes: 10),
              debugName: 'raster-pdf',
            )
            .result)
        .orThrow;
    return out;
  }

  // Security -------------------------------------------------------------------

  Future<ToolResult> protect({
    required ToolInput input,
    required String? currentPassword,
    required String password,
    required String name,
    required EditControl control,
  }) => guarded(ToolId.protect, (work) async {
    final path = await localPath(input);
    // A full PDFium save gives the classic cross-reference table the
    // security writer needs, and drops any old security.
    final plain = p.join(work.path, 'plain.pdf');
    await PdfiumEditor.resave(
      source: PdfSource(path, password: currentPassword),
      output: plain,
      removeSecurity: currentPassword != null,
    );
    final pages = (await PdfiumEditor.inspect(PdfSource(plain))).pageCount;
    control.report(0.3);
    final out = p.join(work.path, 'out.pdf');
    (await _jobs
            .run(
              _encryptJob,
              (plain, out, password),
              timeout: const Duration(minutes: 5),
              debugName: 'protect',
            )
            .result)
        .orThrow;
    control.report(0.9);
    return ToolResult(
      tool: ToolId.protect,
      outputs: [await _publish(out, name, pages: pages)],
    );
  });

  Future<ToolResult> unlock({
    required ToolInput input,
    required String password,
    required String name,
    required EditControl control,
  }) => guarded(ToolId.unlock, (work) async {
    final path = await localPath(input);
    final out = p.join(work.path, 'out.pdf');
    await PdfiumEditor.resave(
      source: PdfSource(path, password: password),
      output: out,
      removeSecurity: true,
    );
    control.report(0.9);
    return ToolResult(
      tool: ToolId.unlock,
      outputs: [await _publish(out, name)],
    );
  });

  // Stamps ---------------------------------------------------------------------

  /// Watermark or page numbers. For an image watermark, [imagePath] is
  /// decoded here and [stamp] supplies the other settings.
  Future<ToolResult> stamp({
    required ToolId tool,
    required ToolInput input,
    required String? password,
    required StampSpec stamp,
    required List<int>? pages,
    required String name,
    required EditControl control,
    ToolInput? image,
    int firstNumber = 1,
  }) => guarded(tool, (work) async {
    final path = await localPath(input);
    var spec = stamp;
    if (image != null) {
      final (bgra, w, h) = (await _jobs.run(decodeBgra, (
        await localPath(image),
        1200,
      )).result).orThrow;
      spec = StampSpec.image(
        bgra,
        imageWidth: w,
        imageHeight: h,
        imageWidthPt: stamp.imageWidthPt,
        opacity: stamp.opacity,
        angle: stamp.angle,
        position: stamp.position,
        margin: stamp.margin,
      );
    }
    final out = p.join(work.path, 'out.pdf');
    await PdfiumEditor.stamp(
      source: PdfSource(path, password: password),
      stamp: spec,
      output: out,
      pages: pages,
      firstNumber: firstNumber,
      control: _scaled(control, 0.1, 0.95),
    );
    return ToolResult(tool: tool, outputs: [await _publish(out, name)]);
  });

  // Visual editors -------------------------------------------------------------

  Future<ToolResult> annotate({
    required ToolId tool,
    required ToolInput input,
    required String? password,
    required List<PdfMark> marks,
    required String name,
    required EditControl control,
  }) => guarded(tool, (work) async {
    final path = await localPath(input);
    final out = p.join(work.path, 'out.pdf');
    await PdfiumEditor.annotate(
      source: PdfSource(path, password: password),
      marks: marks,
      output: out,
      control: _scaled(control, 0.1, 0.95),
    );
    return ToolResult(tool: tool, outputs: [await _publish(out, name)]);
  });

  Future<ToolResult> fillForm({
    required ToolInput input,
    required String? password,
    required List<FormFieldValue> values,
    required bool flatten,
    required String name,
    required EditControl control,
  }) => guarded(ToolId.fillForms, (work) async {
    final path = await localPath(input);
    final out = p.join(work.path, 'out.pdf');
    await PdfiumEditor.fillForm(
      source: PdfSource(path, password: password),
      values: values,
      flatten: flatten,
      output: out,
      control: _scaled(control, 0.1, 0.95),
    );
    return ToolResult(
      tool: ToolId.fillForms,
      outputs: [await _publish(out, name)],
    );
  });

  /// Rebuilds every page with a box as a picture with the boxes burnt in;
  /// other pages are copied unchanged (FR-PDF-04).
  Future<ToolResult> redact({
    required ToolInput input,
    required String? password,
    required List<RedactBox> boxes,
    required bool ocr,
    required String name,
    required EditControl control,
  }) => guarded(ToolId.redact, (work) async {
    final path = await localPath(input);
    final info = await PdfiumEditor.inspect(
      PdfSource(path, password: password),
    );
    final byPage = <int, List<RedactBox>>{};
    for (final b in boxes) {
      (byPage[b.page] ??= []).add(b);
    }
    final raster = await _rasterize(
      path: path,
      password: password,
      pages: byPage,
      scale: 200 / 72,
      quality: 85,
      ocr: ocr,
      work: work,
      control: _scaled(control, 0, 0.8),
    );
    final order = byPage.keys.toList()..sort();
    final out = p.join(work.path, 'out.pdf');
    await PdfiumEditor.assemble(
      sources: [
        PdfSource(path, password: password),
        PdfSource(raster),
      ],
      pages: [
        for (var i = 0; i < info.pageCount; i++)
          if (byPage.containsKey(i))
            PageSpec.page(1, order.indexOf(i))
          else
            PageSpec.page(0, i),
      ],
      output: out,
      control: _scaled(control, 0.8, 0.95),
    );
    return ToolResult(
      tool: ToolId.redact,
      outputs: [await _publish(out, name, pages: info.pageCount)],
    );
  });

  /// Maps a step's 0–1 progress into [from]–[to] of the whole job.
  static EditControl _scaled(EditControl c, double from, double to) =>
      EditControl(
        onProgress: (v, {page, of}) =>
            c.report(from + (to - from) * v, page: page, of: of),
        isCancelled: () {
          try {
            c.check();
            return false;
          } on DocNookFailure {
            return true;
          }
        },
      );
}

// Isolate entry points.

int _scanPdfJob(ScanPdfRequest request, JobContext _) => writeScanPdf(request);

int _encryptJob((String, String, String) args, JobContext _) {
  final (input, output, password) = args;
  final bytes = PdfEncryptor.encrypt(
    File(input).readAsBytesSync(),
    userPassword: password,
  );
  File(output).writeAsBytesSync(bytes, flush: true);
  return bytes.length;
}

import 'dart:io';
import 'dart:typed_data';

import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/engines/convert/doc_fonts.dart';
import 'package:docnook/engines/convert/docmodel_to_pdf.dart';
import 'package:docnook/engines/convert/docx_writer.dart';
import 'package:docnook/engines/convert/pdf_to_docmodel.dart';
import 'package:docnook/engines/convert/sheet_export.dart';
import 'package:docnook/engines/convert/sheet_to_pdf.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/office/docx/docx_parser.dart';
import 'package:docnook/engines/office/parse_document.dart';
import 'package:docnook/engines/office/pptx/pptx_parser.dart';
import 'package:docnook/engines/office/sheet/csv_parser.dart';
import 'package:docnook/engines/office/xlsx/xlsx_parser.dart';
import 'package:docnook/engines/pdf/pdfium_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

DocFontBytes _fonts() => DocFontBytes.of([
  for (final f in DocFontBytes.files)
    File('assets/docfonts/$f').readAsBytesSync(),
]);

void main() {
  final dll = File(p.absolute('build/native_assets/windows/pdfium.dll'));
  final pdfium = Platform.isWindows && dll.existsSync();
  late Directory dir;

  setUpAll(() async {
    if (!pdfium) return;
    Pdfrx.pdfiumModulePath = dll.path;
    PdfiumEditor.modulePath = dll.path;
    await PdfrxEntryFunctions.instance.init();
  });
  setUp(() => dir = Directory.systemTemp.createTempSync('docnook_conv'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<String> textOf(String file, int page) async {
    final doc = await PdfDocument.openFile(file);
    try {
      return (await doc.pages[page].loadText())?.fullText ?? '';
    } finally {
      await doc.dispose();
    }
  }

  test('Word document → PDF keeps headings, tables and page count', () async {
    final model = DocxParser.parseFile('test/fixtures/handbook_30p.docx');
    final out = p.join(dir.path, 'handbook.pdf');
    final pages = await docModelToPdf(
      DocToPdfRequest(model: model, fonts: _fonts(), output: out),
      JobContext.detached(),
    );
    expect(pages, greaterThan(5));
    if (!pdfium) return;
    final info = await PdfiumEditor.inspect(PdfSource(out));
    expect(info.pageCount, pages);
    final firstHeading = model.outline().first.title.trim();
    var found = false;
    for (var i = 0; i < 3 && !found; i++) {
      found = (await textOf(out, i)).contains(firstHeading);
    }
    expect(found, isTrue);
  });

  test('ODT, RTF, Markdown and text become PDFs', () async {
    final models = {
      'odt': parseToDocModelSync('test/fixtures/office/minutes.odt'),
      'rtf': parseToDocModelSync('test/fixtures/office/letter.rtf'),
      'md': parseToDocModelSync('test/fixtures/office/readme.md'),
    };
    for (final entry in models.entries) {
      final out = p.join(dir.path, '${entry.key}.pdf');
      final pages = await docModelToPdf(
        DocToPdfRequest(model: entry.value, fonts: _fonts(), output: out),
        JobContext.detached(),
      );
      expect(pages, greaterThanOrEqualTo(1), reason: entry.key);
      expect(File(out).lengthSync(), greaterThan(1000));
    }
  });

  test('slides become one page each at slide size', () async {
    final model = PptxParser.parseFile('test/fixtures/office/deck.pptx');
    final slides = model.blocks.whereType<SlideFrame>().length;
    final out = p.join(dir.path, 'deck.pdf');
    final pages = await docModelToPdf(
      DocToPdfRequest(model: model, fonts: _fonts(), output: out),
      JobContext.detached(),
    );
    expect(pages, slides);
    if (!pdfium) return;
    final info = await PdfiumEditor.inspect(PdfSource(out));
    final frame = model.blocks.whereType<SlideFrame>().first;
    expect(info.pages.first.width, closeTo(frame.width, 1));
  });

  test('characters outside the bundled fonts use a system font', () {
    final fonts = DocFonts.load(
      _fonts(),
      text: 'مرحبا שלום',
      systemDir: Platform.isWindows ? r'C:\Windows\Fonts' : '/usr/share/fonts',
    );
    if (Platform.isWindows) expect(fonts.fallback, isNotEmpty);
  });

  test('spreadsheets → PDF with every sheet', () async {
    final wb = XlsxParser.parseFile('test/fixtures/office/budget.xlsx');
    final out = p.join(dir.path, 'budget.pdf');
    final pages = await sheetToPdf(
      SheetToPdfRequest(workbook: wb, fonts: _fonts(), output: out),
      JobContext.detached(),
    );
    expect(
      pages,
      greaterThanOrEqualTo(wb.sheets.where((s) => !s.hidden).length),
    );
    final csv = CsvParser.parseFile('test/fixtures/office/contacts.csv');
    final out2 = p.join(dir.path, 'contacts.pdf');
    expect(
      await sheetToPdf(
        SheetToPdfRequest(workbook: csv, fonts: _fonts(), output: out2),
        JobContext.detached(),
      ),
      greaterThanOrEqualTo(1),
    );
  });

  test('CSV → XLSX → CSV keeps the data', () {
    final csv = CsvParser.parse(
      Uint8List.fromList(
        'Name,Amount,Note\r\nAda,12.5,"has, comma"\r\nBo,-3,"quote ""x"""\r\n'
            .codeUnits,
      ),
    );
    final xlsx = p.join(dir.path, 'out.xlsx');
    File(xlsx).writeAsBytesSync(buildXlsx(csv, boldHeader: true));
    final back = XlsxParser.parseFile(xlsx);
    expect(back.sheets.single.valueAt(1, 1), 12.5);
    expect(back.sheets.single.valueAt(2, 2), 'quote "x"');
    final text = sheetToCsv(back, back.sheets.single);
    expect(text.split('\r\n')[1], 'Ada,12.5,"has, comma"');
    expect(text.split('\r\n')[2], 'Bo,-3,"quote ""x"""');
  });

  test('DocModel → DOCX opens again with headings and tables', () {
    final model = DocModel(
      sections: [
        DocSection(
          blocks: const [
            Paragraph([TextRun('Quarterly report')], headingLevel: 1),
            Paragraph([
              TextRun('Plain '),
              TextRun('bold', RunStyle(bold: true)),
              TextRun(' & <escaped>'),
            ]),
            PageBreak(),
            Paragraph([TextRun('Second page')]),
          ],
        ),
      ],
    );
    final file = p.join(dir.path, 'out.docx');
    File(file).writeAsBytesSync(buildDocx(model));
    final back = DocxParser.parseFile(file);
    final paragraphs = back.blocks.whereType<Paragraph>().toList();
    expect(paragraphs.first.headingLevel, 1);
    expect(paragraphs.first.plainText, 'Quarterly report');
    expect(paragraphs[1].plainText, 'Plain bold & <escaped>');
    final bold = paragraphs[1].inlines.whereType<TextRun>().firstWhere(
      (r) => r.text == 'bold',
    );
    expect(bold.style.bold, isTrue);
    expect(back.blocks.whereType<PageBreak>(), isNotEmpty);
  });

  test('PDF lines become paragraphs and headings', () {
    PdfTextLine line(String t, double top, double h, {double right = 500}) =>
        PdfTextLine(t, 72, top, right, top + h);
    final model = pdfPagesToDocModel([
      PdfPageContent(
        width: 595,
        height: 842,
        lines: [
          line('Annual Review', 72, 22, right: 260),
          line('This is the first line of a paragraph that', 110, 12),
          line('continues here and ends short.', 124, 12, right: 300),
          line('A second paragraph starts after a gap.', 150, 12, right: 380),
        ],
      ),
    ]);
    final paragraphs = model.blocks.whereType<Paragraph>().toList();
    expect(paragraphs.first.headingLevel, 1);
    expect(paragraphs, hasLength(3));
    expect(
      paragraphs[1].plainText,
      'This is the first line of a paragraph that continues here and ends short.',
    );
  });

  test('PDF → Word keeps whole paragraphs and real headings', () async {
    if (!pdfium) return;
    final model = DocxParser.parseFile('test/fixtures/handbook_30p.docx');
    final pdf = p.join(dir.path, 'handbook.pdf');
    await docModelToPdf(
      DocToPdfRequest(model: model, fonts: _fonts(), output: pdf),
      JobContext.detached(),
    );
    final info = await PdfiumEditor.inspect(PdfSource(pdf));
    final pages = <PdfPageContent>[];
    for (var i = 0; i < 2; i++) {
      final page = info.pages[i];
      final (text, raw, sizes) = await PdfiumEditor.pageChars(
        PdfSource(pdf),
        i,
      );
      final boxes = [
        for (var c = 0; c + 3 < raw.length; c += 4)
          (
            raw[c],
            page.height - raw[c + 3],
            raw[c + 2],
            page.height - raw[c + 1],
          ),
      ];
      pages.add(
        PdfPageContent(
          width: page.width,
          height: page.height,
          lines: linesFromChars(text, boxes, sizes: sizes),
        ),
      );
    }
    final paragraphs = pdfPagesToDocModel(
      pages,
    ).blocks.whereType<Paragraph>().toList();
    String find(String start) =>
        paragraphs.firstWhere((x) => x.plainText.startsWith(start)).plainText;
    // A paragraph's short last line stays with it.
    expect(find('The quarterly review'), endsWith('month end.'));
    expect(paragraphs.where((x) => x.plainText == 'month end.'), isEmpty);
    // One larger word does not turn a body line into a heading.
    final important = paragraphs.firstWhere(
      (x) => x.plainText.startsWith('Important:'),
    );
    expect(important.headingLevel, 0);
    final section = paragraphs.firstWhere(
      (x) => x.plainText.startsWith('1.1 Section detail'),
    );
    expect(section.headingLevel, greaterThan(0));
    expect(paragraphs.first.headingLevel, 1);
  });

  test('characters group into lines', () {
    final lines = linesFromChars('ab\ncd', const [
      (0, 0, 5, 10),
      (5, 0, 10, 10),
      (0, 0, 0, 0),
      (0, 20, 5, 30),
      (5, 20, 10, 30),
    ]);
    expect(lines.map((l) => l.text), ['ab', 'cd']);
  });
}

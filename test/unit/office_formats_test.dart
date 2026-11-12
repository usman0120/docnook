import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/domain/sheetmodel/number_format.dart';
import 'package:docnook/engines/epub/epub_parser.dart';
import 'package:docnook/engines/office/html/html_to_docmodel.dart';
import 'package:docnook/engines/office/legacy/ole_file.dart';
import 'package:docnook/engines/office/odf/odt_parser.dart';
import 'package:docnook/engines/office/parse_document.dart';
import 'package:docnook/engines/office/pptx/pptx_parser.dart';
import 'package:docnook/engines/office/rtf/rtf_parser.dart';
import 'package:docnook/engines/office/sheet/csv_parser.dart';
import 'package:docnook/engines/office/sheet/ods_parser.dart';
import 'package:docnook/engines/office/xlsx/xlsx_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const dir = 'test/fixtures/office';
String fx(String name) => '$dir/$name';

List<Paragraph> paragraphs(DocModel doc) =>
    doc.blocks.whereType<Paragraph>().toList();

void main() {
  test('PPTX: slides, titles, bullets, shapes, pictures, notes, groups', () {
    final doc = PptxParser.parseFile(fx('deck.pptx'));
    final slides = doc.blocks.whereType<SlideFrame>().toList();
    expect(slides, hasLength(3));
    expect(slides.first.width, 720);
    expect(slides.first.height, 540);
    expect(slides[0].title, 'Quarterly Review');
    expect(slides[1].title, 'Highlights');
    expect(slides[1].notes, 'Mention the Lahore office.');

    final body = slides[1].items
        .whereType<SlideText>()
        .where((t) => !t.isTitle)
        .first;
    expect(body.paragraphs.map((p) => p.plainText), [
      'Revenue up 12%',
      'Two new offices',
      'Hiring on track',
    ]);
    expect(
      body.x,
      greaterThan(0),
      reason: 'placeholder position inherited from the layout',
    );

    final third = slides[2].items;
    final boxed = third.whereType<SlideText>().firstWhere(
      (t) => t.paragraphs.first.plainText == 'Boxed text',
    );
    expect(boxed.fill, 0xFF1F3A4D);
    expect(third.whereType<SlideImage>(), hasLength(1));
    expect(doc.images, hasLength(1));
    final big = third.whereType<SlideText>().firstWhere(
      (t) => t.paragraphs.first.plainText == 'Big red',
    );
    final run = big.paragraphs.first.inlines.first as TextRun;
    expect(run.style.fontSize, 40);
    expect(run.style.bold, isTrue);
    expect(run.style.color, 0xFFC0392B);
    expect(
      third.whereType<SlideText>().any(
        (t) => t.paragraphs.first.plainText == 'Grouped caption',
      ),
      isTrue,
    );
    expect(doc.plainText(), contains('Quarterly Review'));
  });

  test('XLSX from openpyxl: values, formats, merges, frozen pane, sheets', () {
    final wb = XlsxParser.parseFile(fx('budget.xlsx'));
    expect(wb.sheets.map((s) => s.name), ['Budget', 'Notes']);
    final s = wb.sheets.first;
    expect(s.valueAt(0, 0), 'Item');
    expect(
      NumberFormatter.format(
        s.valueAt(1, 1),
        wb.styleAt(s.styleIdAt(1, 1)).formatCode,
      ),
      '45,000.00',
    );
    expect(
      NumberFormatter.format(
        s.valueAt(1, 2),
        wb.styleAt(s.styleIdAt(1, 2)).formatCode,
      ),
      '15/03/2026',
    );
    expect(
      NumberFormatter.format(
        s.valueAt(1, 3),
        wb.styleAt(s.styleIdAt(1, 3)).formatCode,
      ),
      '25%',
    );
    expect(s.formulas.values, contains('SUM(B2:B3)'));
    expect(s.merges.single.colSpan, 3);
    expect(s.frozenRows, 1);
    expect(s.frozenCols, 1);
    expect(s.colWidths[0], closeTo(24, 1));
    final header = wb.styleAt(s.styleIdAt(0, 0));
    expect(header.bold, isTrue);
    expect(header.color, 0xFFC0392B);
    expect(header.fill, 0xFFFFF2CC);
  });

  test('XLS (BIFF8 from xlwt): sheet names and cells', () {
    final lines = LegacyText.xls(File(fx('legacy.xls')).readAsBytesSync());
    expect(lines.first, 'Legacy');
    expect(lines, contains('Name\tValue'));
    expect(lines, contains('Alpha\t42'));
    expect(lines, contains('Beta\t3.5'));
  });

  test('ODS: typed values and sheet name', () {
    final wb = OdsParser.parseFile(fx('stock.ods'));
    final s = wb.sheets.single;
    expect(s.name, 'Stock');
    expect(s.valueAt(0, 0), 'Product');
    expect(s.valueAt(2, 1), 500.0);
    expect(s.rowCount, 3);
  });

  test('ODT: heading, styled span, list, table', () {
    final doc = OdtParser.parseFile(fx('minutes.odt'));
    final ps = paragraphs(doc);
    expect(ps.first.headingLevel, 1);
    expect(ps.first.plainText, 'Meeting minutes');
    final attendees = ps.firstWhere((p) => p.plainText.startsWith('Attendees'));
    expect(attendees.style.align, TextAlignment.center);
    expect(
      attendees.inlines.whereType<TextRun>().any(
        (r) => r.style.bold && r.text.contains('Ayesha'),
      ),
      isTrue,
    );
    expect(ps.where((p) => p.list != null).map((p) => p.plainText), [
      'Approve budget',
      'Plan visit',
    ]);
    final table = doc.blocks.whereType<TableBlock>().single;
    expect(table.rows, hasLength(2));
    expect(doc.plainText(), contains('Report\tSana'));
  });

  test(
    'RTF: formatting, colours, unicode, codepage, tables; skips font tables',
    () {
      final doc = RtfParser.parse(File(fx('letter.rtf')).readAsBytesSync());
      final text = doc.plainText();
      expect(text, isNot(contains('Calibri')));
      expect(text, isNot(contains('Fixture')));
      final ps = paragraphs(doc);
      expect(ps.first.plainText, 'Notice');
      expect(ps.first.style.align, TextAlignment.center);
      expect((ps.first.inlines.first as TextRun).style.bold, isTrue);
      expect((ps.first.inlines.first as TextRun).style.fontSize, 16);
      final runs = ps[1].inlines.cast<TextRun>();
      expect(
        runs.firstWhere((r) => r.text.contains('italic')).style.italic,
        isTrue,
      );
      expect(
        runs.firstWhere((r) => r.text.contains('underlined')).style.underline,
        isTrue,
      );
      expect(
        runs.firstWhere((r) => r.text.contains('red')).style.color,
        0xFFC0392B,
      );
      expect(text, contains('100 € and café'));
      expect(
        doc.blocks.whereType<TableBlock>().single.rows.single.cells,
        hasLength(2),
      );
      expect(text, contains('After table.'));
    },
  );

  test('Markdown: headings, emphasis, tasks, nesting, quote, code, table', () {
    final doc = parseToDocModelSync(fx('readme.md'));
    final ps = paragraphs(doc);
    expect(ps.first.headingLevel, 1);
    expect(ps.first.plainText, 'Project notes');
    final body = ps[1].inlines.cast<TextRun>();
    expect(body.firstWhere((r) => r.text == 'bold').style.bold, isTrue);
    expect(body.firstWhere((r) => r.text == 'code').style.font, FontClass.mono);
    expect(
      body.firstWhere((r) => r.text == 'link').style.link,
      'https://example.org',
    );
    final markers = [
      for (final p in ps)
        if (p.list != null) p.list!.marker,
    ];
    expect(markers, ['☑︎', '☐︎', '◦', '1.', '2.']);
    expect(ps.firstWhere((p) => p.plainText == 'Nested item').list!.level, 1);
    expect(
      ps
          .firstWhere((p) => p.plainText == 'Quoted line')
          .inlines
          .cast<TextRun>()
          .first
          .style
          .italic,
      isTrue,
    );
    expect(ps.any((p) => p.plainText == 'let x = 1;'), isTrue);
    expect(doc.blocks.whereType<TableBlock>().single.rows, hasLength(2));
  });

  test('CSV: quotes, doubled quotes, embedded newlines, numbers, header', () {
    final wb = CsvParser.parseFile(fx('contacts.csv'));
    final s = wb.sheets.single;
    expect(s.valueAt(1, 0), 'Khan, Ali');
    expect(s.valueAt(1, 2), 'Said "hello"');
    expect(s.valueAt(2, 2), 'Two\nlines');
    expect(s.rowCount, 3);
    expect(s.frozenRows, 1);
    expect(CsvParser.detectDelimiter('a;b;c\n1;2;3'), ';');
    expect(CsvParser.detectDelimiter('a\tb\n1\t2'), '\t');
    final numbers = CsvParser.parse(
      Uint8List.fromList(utf8.encode('x,007,1.5,-3\n')),
    );
    expect(numbers.sheets.single.valueAt(0, 1), '007');
    expect(numbers.sheets.single.valueAt(0, 2), 1.5);
    expect(numbers.sheets.single.valueAt(0, 3), -3.0);
  });

  test('EPUB: chapters in spine order, nav titles, entities, images', () {
    final book = EpubParser.parseFile(fx('story.epub'));
    expect(book.title, 'The Quiet Shop');
    expect(book.author, 'A. Writer');
    expect(book.chapters.map((c) => c.title), ['Opening', 'The Visit']);
    final first = book.toDocModel();
    final text = first.plainText();
    expect(text, contains('The shop was quiet — until she arrived.'));
    expect(first.blocks.whereType<ImageBlock>(), hasLength(1));
    expect(book.images.values.single.bytes.length, greaterThan(20));
  });

  test('XHTML with an entity declaration is still rejected', () {
    const hostile =
        '<?xml version="1.0"?><!DOCTYPE html [<!ENTITY a "aaaa">]><html><body><p>&a;</p></body></html>';
    expect(
      () => parseXhtmlBody(hostile),
      throwsA(const DocNookFailure.corrupt()),
    );
  });

  test('text decoding: BOMs and Windows-1252 fallback', () {
    expect(
      decodeText(Uint8List.fromList([0xEF, 0xBB, 0xBF, 0x68, 0x69])),
      'hi',
    );
    expect(
      decodeText(Uint8List.fromList([0xFF, 0xFE, 0x68, 0x00, 0x69, 0x00])),
      'hi',
    );
    expect(
      decodeText(Uint8List.fromList([0xFE, 0xFF, 0x00, 0x68, 0x00, 0x69])),
      'hi',
    );
    expect(decodeText(Uint8List.fromList([0x63, 0x61, 0x66, 0xE9])), 'café');
  });

  test('index chunks cover the text', () {
    final doc = parseToDocModelSync(fx('readme.md'));
    final chunks = docModelChunks(doc);
    expect(chunks.single.text, contains('Project notes'));
  });
}

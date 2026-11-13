import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/engines/office/docx/docx_numbering.dart';
import 'package:docnook/engines/office/docx/docx_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _w =
    'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
    'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
    'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
    'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" '
    'xmlns:v="urn:schemas-microsoft-com:vml"';

Uint8List buildDocx(
  String body, {
  String? styles,
  String? numbering,
  String? rels,
  Map<String, String> parts = const {},
  Map<String, List<int>> binary = const {},
}) {
  final archive = Archive();
  void add(String name, List<int> bytes) =>
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
  void text(String name, String content) => add(name, utf8.encode(content));

  text('[Content_Types].xml', '<Types/>');
  text(
    'word/document.xml',
    '<w:document $_w><w:body>$body</w:body></w:document>',
  );
  if (styles != null) {
    text('word/styles.xml', '<w:styles $_w>$styles</w:styles>');
  }
  if (numbering != null) {
    text('word/numbering.xml', '<w:numbering $_w>$numbering</w:numbering>');
  }
  if (rels != null) {
    text(
      'word/_rels/document.xml.rels',
      '<Relationships>$rels</Relationships>',
    );
  }
  parts.forEach(text);
  binary.forEach(add);
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

List<Block> blocksOf(
  String body, {
  String? styles,
  String? numbering,
  String? rels,
}) => DocxParser.parseBytes(
  buildDocx(body, styles: styles, numbering: numbering, rels: rels),
).blocks.toList();

const _styles = '''
<w:docDefaults><w:rPrDefault><w:rPr><w:sz w:val="22"/><w:rFonts w:ascii="Calibri"/></w:rPr></w:rPrDefault>
<w:pPrDefault><w:pPr><w:spacing w:after="160" w:line="259" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/>
  <w:pPr><w:spacing w:before="240" w:after="0"/><w:outlineLvl w:val="0"/></w:pPr>
  <w:rPr><w:b/><w:sz w:val="32"/><w:color w:val="2F5496"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Sub"><w:name w:val="Custom Sub"/><w:basedOn w:val="Heading1"/>
  <w:rPr><w:sz w:val="26"/></w:rPr></w:style>
<w:style w:type="character" w:styleId="Strong"><w:name w:val="Strong"/><w:rPr><w:b/><w:i/></w:rPr></w:style>
<w:style w:type="table" w:styleId="TableGrid"><w:name w:val="Table Grid"/>
  <w:tblPr><w:tblBorders><w:top w:val="single"/><w:left w:val="single"/></w:tblBorders></w:tblPr></w:style>''';

void main() {
  test('paragraph text, runs and direct formatting', () {
    final blocks = blocksOf('''
<w:p><w:pPr><w:jc w:val="center"/><w:ind w:left="720" w:hanging="360"/></w:pPr>
  <w:r><w:t xml:space="preserve">Plain </w:t></w:r>
  <w:r><w:rPr><w:b/><w:i w:val="0"/><w:u w:val="single"/><w:sz w:val="28"/><w:color w:val="FF0000"/><w:highlight w:val="yellow"/></w:rPr><w:t>bold</w:t></w:r>
  <w:r><w:tab/><w:t>after</w:t><w:br/><w:t>line</w:t></w:r>
  <w:r><w:rPr><w:vertAlign w:val="superscript"/><w:rFonts w:ascii="Courier New"/></w:rPr><w:t>2</w:t></w:r>
</w:p>''');
    final p = blocks.single as Paragraph;
    expect(p.plainText, 'Plain bold\tafter\nline2');
    expect(p.style.align, TextAlignment.center);
    expect(p.style.indentStart, 36);
    expect(p.style.firstLine, -18);

    final runs = p.inlines.cast<TextRun>();
    expect(runs[0].style, RunStyle.plain);
    expect(runs[1].style.bold, isTrue);
    expect(runs[1].style.italic, isFalse);
    expect(runs[1].style.underline, isTrue);
    expect(runs[1].style.fontSize, 14);
    expect(runs[1].style.color, 0xFFFF0000);
    expect(runs[1].style.highlight, 0xFFFFFF00);
    expect(runs.last.style.position, VerticalPosition.superscript);
    expect(runs.last.style.font, FontClass.mono);
  });

  test('neighbouring runs with the same style are merged', () {
    final blocks = blocksOf(
      '<w:p><w:r><w:t>Hel</w:t></w:r><w:r><w:t>lo</w:t></w:r>'
      '<w:proofErr w:type="spellStart"/><w:r><w:t> world</w:t></w:r></w:p>',
    );
    final p = blocks.single as Paragraph;
    expect(p.inlines, hasLength(1));
    expect(p.plainText, 'Hello world');
  });

  test('styles inherit through basedOn and document defaults', () {
    final blocks = blocksOf(
      '''
<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Title</w:t></w:r></w:p>
<w:p><w:pPr><w:pStyle w:val="Sub"/></w:pPr><w:r><w:t>Sub</w:t></w:r></w:p>
<w:p><w:r><w:t>Body </w:t></w:r><w:r><w:rPr><w:rStyle w:val="Strong"/></w:rPr><w:t>strong</w:t></w:r></w:p>''',
      styles: _styles,
    );

    final heading = blocks[0] as Paragraph;
    expect(heading.headingLevel, 1);
    final headingRun = heading.inlines.single as TextRun;
    expect(headingRun.style.bold, isTrue);
    expect(headingRun.style.fontSize, 16);
    expect(headingRun.style.color, 0xFF2F5496);
    expect(heading.style.spaceBefore, 12);
    expect(heading.style.spaceAfter, 0);

    final sub = blocks[1] as Paragraph;
    expect(
      sub.headingLevel,
      1,
      reason: 'heading level is inherited from the base style',
    );
    expect((sub.inlines.single as TextRun).style.fontSize, 13);
    expect((sub.inlines.single as TextRun).style.bold, isTrue);

    final body = blocks[2] as Paragraph;
    expect(body.headingLevel, 0);
    expect(body.style.spaceAfter, 8);
    expect(body.style.lineHeight, closeTo(1.08, 0.01));
    final runs = body.inlines.cast<TextRun>();
    expect(runs[0].style.fontSize, 11);
    expect(runs[0].style.bold, isFalse);
    expect(runs[1].style.bold, isTrue);
    expect(runs[1].style.italic, isTrue);
  });

  test('lists: bullets, nested numbering and restarts', () {
    const numbering = '''
<w:abstractNum w:abstractNumId="0">
  <w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:lvlText w:val="%1."/></w:lvl>
  <w:lvl w:ilvl="1"><w:start w:val="1"/><w:numFmt w:val="lowerLetter"/><w:lvlText w:val="%1.%2)"/></w:lvl>
</w:abstractNum>
<w:abstractNum w:abstractNumId="1">
  <w:lvl w:ilvl="0"><w:numFmt w:val="bullet"/><w:lvlText w:val="&#xF0B7;"/></w:lvl>
</w:abstractNum>
<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>
<w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num>
<w:num w:numId="3"><w:abstractNumId w:val="0"/><w:lvlOverride w:ilvl="0"><w:startOverride w:val="1"/></w:lvlOverride></w:num>''';
    String item(String numId, int level, String text) =>
        '<w:p><w:pPr><w:numPr><w:ilvl w:val="$level"/><w:numId w:val="$numId"/></w:numPr></w:pPr>'
        '<w:r><w:t>$text</w:t></w:r></w:p>';

    final blocks = blocksOf(
      [
        item('1', 0, 'one'),
        item('1', 1, 'one-a'),
        item('1', 1, 'one-b'),
        item('1', 0, 'two'),
        item('1', 1, 'two-a'),
        item('2', 0, 'bullet'),
        item('3', 0, 'restarted'),
        item('0', 0, 'not a list'),
      ].join(),
      numbering: numbering,
    );
    final markers = [for (final b in blocks) (b as Paragraph).list?.marker];
    expect(markers, ['1.', '1.a)', '1.b)', '2.', '2.a)', '•', '1.', null]);
    expect((blocks[1] as Paragraph).list!.level, 1);
    expect((blocks[0] as Paragraph).list!.ordered, isTrue);
    expect((blocks[5] as Paragraph).list!.ordered, isFalse);
  });

  test('counter formats', () {
    expect(DocxNumbering.formatCounter(4, 'upperRoman'), 'IV');
    expect(DocxNumbering.formatCounter(1994, 'lowerRoman'), 'mcmxciv');
    expect(DocxNumbering.formatCounter(27, 'upperLetter'), 'AA');
    expect(DocxNumbering.formatCounter(3, 'lowerLetter'), 'c');
    expect(DocxNumbering.formatCounter(7, 'decimalZero'), '07');
  });

  test('tables: grid, spans, vertical merges, fills and nesting', () {
    final blocks = blocksOf('''
<w:tbl>
  <w:tblPr><w:tblStyle w:val="TableGrid"/></w:tblPr>
  <w:tblGrid><w:gridCol w:w="2880"/><w:gridCol w:w="1440"/><w:gridCol w:w="1440"/></w:tblGrid>
  <w:tr><w:trPr><w:tblHeader/></w:trPr>
    <w:tc><w:tcPr><w:gridSpan w:val="2"/><w:shd w:val="clear" w:fill="D9E2F3"/></w:tcPr><w:p><w:r><w:t>Wide</w:t></w:r></w:p></w:tc>
    <w:tc><w:tcPr><w:vMerge w:val="restart"/></w:tcPr><w:p><w:r><w:t>Tall</w:t></w:r></w:p></w:tc>
  </w:tr>
  <w:tr>
    <w:tc><w:p><w:r><w:t>A</w:t></w:r></w:p></w:tc>
    <w:tc><w:p><w:r><w:t>B</w:t></w:r></w:p>
      <w:tbl><w:tr><w:tc><w:p><w:r><w:t>inner</w:t></w:r></w:p></w:tc></w:tr></w:tbl>
      <w:p/></w:tc>
    <w:tc><w:tcPr><w:vMerge/></w:tcPr><w:p/></w:tc>
  </w:tr>
</w:tbl>''', styles: _styles);
    final table = blocks.single as TableBlock;
    expect(table.columnWidths, [144, 72, 72]);
    expect(table.columnCount, 3);
    expect(table.bordered, isTrue);
    expect(table.rows[0].isHeader, isTrue);

    final wide = table.rows[0].cells[0];
    expect(wide.colSpan, 2);
    expect(wide.fill, 0xFFD9E2F3);
    final tall = table.rows[0].cells[1];
    expect(tall.rowSpan, 2);
    expect(table.rows[1].cells[2].covered, isTrue);

    final nested = table.rows[1].cells[1].blocks.whereType<TableBlock>().single;
    expect(
      ((nested.rows.single.cells.single.blocks.single) as Paragraph).plainText,
      'inner',
    );
    expect(nested.bordered, isFalse);
  });

  test('page breaks, tracked changes, fields and hidden text', () {
    final blocks = blocksOf('''
<w:p><w:r><w:t>Before</w:t></w:r><w:r><w:br w:type="page"/></w:r></w:p>
<w:p><w:pPr><w:pageBreakBefore/></w:pPr><w:r><w:t>New page</w:t></w:r></w:p>
<w:p>
  <w:ins w:id="1"><w:r><w:t>inserted </w:t></w:r></w:ins>
  <w:del w:id="2"><w:r><w:delText>deleted </w:delText></w:r></w:del>
  <w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText> PAGE </w:instrText></w:r>
  <w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:t>7</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r>
  <w:r><w:rPr><w:vanish/></w:rPr><w:t>secret</w:t></w:r>
  <w:r><w:rPr><w:caps/></w:rPr><w:t> shout</w:t></w:r>
</w:p>''');
    expect(blocks.map((b) => b.runtimeType), [
      Paragraph,
      PageBreak,
      Paragraph,
      Paragraph,
    ]);
    expect((blocks[3] as Paragraph).plainText, 'inserted 7 SHOUT');
  });

  test('hyperlinks, pictures and text boxes', () {
    final png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3];
    final doc = DocxParser.parseBytes(
      buildDocx(
        '''
<w:p><w:hyperlink r:id="rId1"><w:r><w:t>site</w:t></w:r></w:hyperlink>
  <w:hyperlink w:anchor="top"><w:r><w:t>top</w:t></w:r></w:hyperlink></w:p>
<w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:drawing><wp:inline>
  <wp:extent cx="1270000" cy="635000"/>
  <a:graphic><a:graphicData><pic:pic xmlns:pic="p"><pic:blipFill><a:blip r:embed="rId2"/></pic:blipFill></pic:pic></a:graphicData></a:graphic>
</wp:inline></w:drawing></w:r></w:p>
<w:p><w:r><w:t>Text with </w:t></w:r><w:r><w:drawing><wp:inline><wp:extent cx="127000" cy="127000"/>
  <a:graphic><a:graphicData><a:blip r:embed="rId2"/></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>
<w:p><w:r><w:drawing><wp:inline><wp:extent cx="127000" cy="127000"/><a:graphic><a:graphicData><a:blip r:embed="rId3"/></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>
<w:p><w:r><mc:AlternateContent>
  <mc:Choice Requires="wps"><w:drawing><wp:anchor><wp:extent cx="1" cy="1"/><a:graphic><a:graphicData>
    <wps:wsp xmlns:wps="s"><wps:txbx><w:txbxContent><w:p><w:r><w:t>boxed</w:t></w:r></w:p></w:txbxContent></wps:txbx></wps:wsp>
  </a:graphicData></a:graphic></wp:anchor></w:drawing></mc:Choice>
  <mc:Fallback><w:pict><v:textbox><w:txbxContent><w:p><w:r><w:t>boxed</w:t></w:r></w:p></w:txbxContent></v:textbox></w:pict></mc:Fallback>
</mc:AlternateContent></w:r></w:p>''',
        rels:
            '<Relationship Id="rId1" Target="https://example.org/" TargetMode="External"/>'
            '<Relationship Id="rId2" Target="media/image1.png"/>'
            '<Relationship Id="rId3" Target="media/chart.emf"/>',
        binary: {
          'word/media/image1.png': png,
          'word/media/chart.emf': [1, 2, 3],
        },
      ),
    );
    final blocks = doc.blocks.toList();

    final links = (blocks[0] as Paragraph).inlines.cast<TextRun>();
    expect(links[0].style.link, 'https://example.org/');
    expect(links[1].style.link, '#top');

    final picture = blocks[1] as ImageBlock;
    expect(picture.imageId, 'word/media/image1.png');
    expect(picture.width, 100);
    expect(picture.height, 50);
    expect(picture.align, TextAlignment.center);
    expect(doc.images['word/media/image1.png']!.bytes, png);
    expect(
      doc.images,
      hasLength(1),
      reason: 'the picture is loaded once; EMF is dropped',
    );

    final mixed = blocks[2] as Paragraph;
    expect(mixed.inlines.last, isA<InlineImage>());

    // The text box appears once (Fallback ignored), after its paragraph.
    final boxed = blocks.whereType<Paragraph>().where(
      (p) => p.plainText == 'boxed',
    );
    expect(boxed, hasLength(1));
    expect(doc.simplified, isTrue);
  });

  test('sections, page setup, headers, footers, footnotes and title', () {
    final doc = DocxParser.parseBytes(
      buildDocx(
        '''
<w:p><w:r><w:t>First</w:t></w:r><w:r><w:footnoteReference w:id="2"/></w:r></w:p>
<w:p><w:pPr><w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="720" w:bottom="1440" w:left="720"/></w:sectPr></w:pPr></w:p>
<w:p><w:r><w:t>Second</w:t></w:r></w:p>
<w:sectPr><w:headerReference w:type="default" r:id="rId1"/><w:footerReference w:type="default" r:id="rId2"/>
  <w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/></w:sectPr>''',
        rels:
            '<Relationship Id="rId1" Target="header1.xml"/><Relationship Id="rId2" Target="footer1.xml"/>',
        parts: {
          'word/header1.xml':
              '<w:hdr $_w><w:p><w:r><w:t>Company</w:t></w:r></w:p><w:p/></w:hdr>',
          'word/footer1.xml':
              '<w:ftr $_w><w:p><w:r><w:t>Page 1</w:t></w:r></w:p></w:ftr>',
          'word/footnotes.xml':
              '<w:footnotes $_w><w:footnote w:type="separator" w:id="0"><w:p/></w:footnote>'
              '<w:footnote w:id="2"><w:p><w:r><w:t>The note.</w:t></w:r></w:p></w:footnote></w:footnotes>',
          'docProps/core.xml':
              '<cp:coreProperties xmlns:cp="c" xmlns:dc="d"><dc:title> Annual report </dc:title></cp:coreProperties>',
        },
      ),
    );
    expect(doc.title, 'Annual report');
    expect(doc.sections, hasLength(2));
    expect(doc.sections[0].page.width, 612);
    expect(doc.sections[0].page.marginLeft, 36);
    expect(doc.sections[1].page.width, closeTo(841.9, 0.1));
    expect((doc.sections[1].header.single as Paragraph).plainText, 'Company');
    expect((doc.sections[1].footer.single as Paragraph).plainText, 'Page 1');

    final first = doc.sections[0].blocks.first as Paragraph;
    expect(first.plainText, 'First1');
    expect(
      (first.inlines.last as TextRun).style.position,
      VerticalPosition.superscript,
    );
    final last = doc.sections[1].blocks.last as Paragraph;
    expect(last.plainText, '1. The note.');
  });

  test('outline and plain text', () {
    final doc = DocxParser.parseBytes(
      buildDocx(
        '''
<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Intro</w:t></w:r></w:p>
<w:p><w:r><w:t>Body</w:t></w:r></w:p>
<w:p><w:pPr><w:outlineLvl w:val="1"/></w:pPr><w:r><w:t>Detail</w:t></w:r></w:p>
<w:tbl><w:tr><w:tc><w:p><w:r><w:t>a</w:t></w:r></w:p></w:tc><w:tc><w:p><w:r><w:t>b</w:t></w:r></w:p></w:tc></w:tr></w:tbl>''',
        styles: _styles,
      ),
    );
    final outline = doc.outline();
    expect(outline.map((e) => (e.title, e.level, e.blockIndex)), [
      ('Intro', 1, 0),
      ('Detail', 2, 2),
    ]);
    expect(doc.plainText(), 'Intro\nBody\nDetail\na\tb\n');
  });

  test('rejects files that are not Word documents', () {
    final archive = Archive()..addFile(ArchiveFile('x.txt', 1, [65]));
    expect(
      () => DocxParser.parseBytes(
        Uint8List.fromList(ZipEncoder().encode(archive)),
      ),
      throwsA(const DocNookFailure.corrupt()),
    );
    expect(
      () => DocxParser.parseBytes(buildDocx('').sublist(0, 40)),
      throwsA(const DocNookFailure.corrupt()),
    );
  });
}

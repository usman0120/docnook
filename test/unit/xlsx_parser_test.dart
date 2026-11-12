import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/sheetmodel/number_format.dart';
import 'package:docnook/domain/sheetmodel/sheet_model.dart';
import 'package:docnook/engines/office/xlsx/xlsx_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _ns =
    'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';

/// Builds an .xlsx in memory from raw part XML.
Uint8List buildXlsx({
  required Map<String, String> sheets,
  List<String> sharedStrings = const [],
  String? stylesXml,
  String workbookPr = '',
  Map<String, String> sheetStates = const {},
}) {
  final archive = Archive();
  void add(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  final names = sheets.keys.toList();
  add(
    '[Content_Types].xml',
    '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"/>',
  );
  add(
    'xl/workbook.xml',
    '<?xml version="1.0"?><workbook $_ns>$workbookPr<sheets>${[for (var i = 0; i < names.length; i++) '<sheet name="${names[i]}" sheetId="${i + 1}" r:id="rId${i + 1}"'
          '${sheetStates.containsKey(names[i]) ? ' state="${sheetStates[names[i]]}"' : ''}/>'].join()}</sheets></workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${[for (var i = 0; i < names.length; i++) '<Relationship Id="rId${i + 1}" Type="x" Target="worksheets/sheet${i + 1}.xml"/>'].join()}</Relationships>',
  );
  for (var i = 0; i < names.length; i++) {
    add(
      'xl/worksheets/sheet${i + 1}.xml',
      '<?xml version="1.0"?><worksheet $_ns>${sheets[names[i]]}</worksheet>',
    );
  }
  if (sharedStrings.isNotEmpty) {
    add(
      'xl/sharedStrings.xml',
      '<?xml version="1.0"?><sst $_ns>${sharedStrings.map((s) => '<si>$s</si>').join()}</sst>',
    );
  }
  if (stylesXml != null) {
    add(
      'xl/styles.xml',
      '<?xml version="1.0"?><styleSheet $_ns>$stylesXml</styleSheet>',
    );
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const _styles = '''
<numFmts count="1"><numFmt numFmtId="164" formatCode="&quot;Rs&quot; #,##0.00"/></numFmts>
<fonts count="2">
  <font><sz val="11"/><name val="Calibri"/></font>
  <font><b/><i val="0"/><sz val="14"/><color rgb="FFFF0000"/></font>
</fonts>
<fills count="3">
  <fill><patternFill patternType="none"/></fill>
  <fill><patternFill patternType="gray125"/></fill>
  <fill><patternFill patternType="solid"><fgColor rgb="FFFFFF00"/><bgColor indexed="64"/></patternFill></fill>
</fills>
<borders count="2">
  <border><left/><right/><top/><bottom/></border>
  <border><left style="thin"/><right/><top/><bottom/></border>
</borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="4">
  <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  <xf numFmtId="164" fontId="1" fillId="2" borderId="1"><alignment horizontal="center" wrapText="1"/></xf>
  <xf numFmtId="14" fontId="0" fillId="0" borderId="0"/>
  <xf numFmtId="10" fontId="0" fillId="0" borderId="0"/>
</cellXfs>''';

void main() {
  test('reads values of every cell type', () {
    final wb = XlsxParser.parseBytes(
      buildXlsx(
        sharedStrings: [
          '<t>Name</t>',
          '<r><t>Rich </t></r><r><t>text</t></r><rPh><t>ignored</t></rPh>',
        ],
        sheets: {
          'Data': '''
<sheetData>
  <row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c></row>
  <row r="2">
    <c r="A2"><v>42</v></c>
    <c r="B2"><v>3.5</v></c>
    <c r="C2" t="b"><v>1</v></c>
    <c r="D2" t="e"><v>#DIV/0!</v></c>
    <c r="E2" t="str"><f>A2&amp;"x"</f><v>42x</v></c>
    <c r="F2" t="inlineStr"><is><t>inline</t></is></c>
    <c r="H2"><f>SUM(A2:B2)</f><v>45.5</v></c>
  </row>
</sheetData>''',
        },
      ),
    );
    final sheet = wb.sheets.single;
    expect(sheet.name, 'Data');
    expect(sheet.valueAt(0, 0), 'Name');
    expect(sheet.valueAt(0, 1), 'Rich text');
    expect(sheet.valueAt(1, 0), 42.0);
    expect(sheet.valueAt(1, 1), 3.5);
    expect(sheet.valueAt(1, 2), true);
    expect(sheet.valueAt(1, 3), isA<CellError>());
    expect(sheet.valueAt(1, 4), '42x');
    expect(sheet.valueAt(1, 5), 'inline');
    expect(sheet.valueAt(1, 6), isNull);
    expect(sheet.valueAt(1, 7), 45.5);
    expect(sheet.formulas[Sheet.cellKey(1, 7)], 'SUM(A2:B2)');
    expect(sheet.formulas[Sheet.cellKey(1, 4)], 'A2&"x"');
    expect(sheet.rowCount, 2);
    expect(sheet.colCount, 8);
    expect(wb.cellCount, 9);
  });

  test('reads styles, number formats, widths, merges and frozen panes', () {
    final wb = XlsxParser.parseBytes(
      buildXlsx(
        stylesXml: _styles,
        sheets: {
          'S': '''
<sheetViews><sheetView workbookViewId="0"><pane xSplit="1" ySplit="2" state="frozen"/></sheetView></sheetViews>
<sheetFormatPr defaultColWidth="9.5" defaultRowHeight="15"/>
<cols><col min="1" max="2" width="20" customWidth="1"/><col min="3" max="3" width="5" hidden="1"/></cols>
<sheetData>
  <row r="1" ht="30" customHeight="1"><c r="A1" s="1"><v>1234.5</v></c><c r="B1" s="2"><v>45000</v></c><c r="C1" s="3"><v>0.256</v></c></row>
  <row r="3"><c r="B3" s="1"/></row>
</sheetData>
<mergeCells count="1"><mergeCell ref="A1:B2"/></mergeCells>''',
        },
      ),
    );
    final sheet = wb.sheets.single;
    expect(sheet.frozenCols, 1);
    expect(sheet.frozenRows, 2);
    expect(sheet.defaultColWidth, 9.5);
    expect(sheet.colWidths, {0: 20.0, 1: 20.0, 2: 0.0});
    expect(sheet.rows.first.height, 30);
    expect(sheet.merges.single.contains(1, 1), isTrue);
    expect(sheet.mergeAt(2, 0), isNull);

    final money = wb.styleAt(sheet.styleIdAt(0, 0));
    expect(money.bold, isTrue);
    expect(money.italic, isFalse);
    expect(money.fontSize, 14);
    expect(money.color, 0xFFFF0000);
    expect(money.fill, 0xFFFFFF00);
    expect(money.hAlign, HAlign.center);
    expect(money.wrap, isTrue);
    expect(money.hasBorder, isTrue);
    expect(NumberFormatter.format(1234.5, money.formatCode), 'Rs 1,234.50');

    expect(
      NumberFormatter.format(
        45000,
        wb.styleAt(sheet.styleIdAt(0, 1)).formatCode,
      ),
      '15/03/2023',
    );
    expect(
      NumberFormatter.format(
        0.256,
        wb.styleAt(sheet.styleIdAt(0, 2)).formatCode,
      ),
      '25.60%',
    );

    // A styled but empty cell is kept so its fill and border still draw.
    expect(sheet.styleIdAt(2, 1), 1);
    expect(sheet.valueAt(2, 1), isNull);
    expect(wb.styleAt(0).fill, isNull);
  });

  test('multiple sheets, hidden state and the 1904 date system', () {
    final wb = XlsxParser.parseBytes(
      buildXlsx(
        workbookPr: '<workbookPr date1904="1"/>',
        sheetStates: {'Secret': 'hidden'},
        sheets: {
          'First':
              '<sheetData><row r="1"><c r="A1"><v>1</v></c></row></sheetData>',
          'Secret': '<sheetData/>',
          'Third':
              '<sheetData><row r="5"><c r="C5"><v>9</v></c></row></sheetData>',
        },
      ),
    );
    expect(wb.sheets.map((s) => s.name), ['First', 'Secret', 'Third']);
    expect(wb.sheets[1].hidden, isTrue);
    expect(wb.sheets[1].rowCount, 0);
    expect(wb.sheets[2].valueAt(4, 2), 9.0);
    expect(wb.date1904, isTrue);
  });

  test('cells without addresses fill the next column', () {
    final wb = XlsxParser.parseBytes(
      buildXlsx(
        sheets: {
          'S':
              '<sheetData><row><c><v>1</v></c><c><v>2</v></c></row><row><c><v>3</v></c></row></sheetData>',
        },
      ),
    );
    final sheet = wb.sheets.single;
    expect(sheet.valueAt(0, 0), 1.0);
    expect(sheet.valueAt(0, 1), 2.0);
    expect(sheet.valueAt(1, 0), 3.0);
  });

  test('stops at the cell limit and reports truncation', () {
    final rows = StringBuffer('<sheetData>');
    for (var r = 1; r <= 100; r++) {
      rows.write('<row r="$r">');
      for (var c = 0; c < 10; c++) {
        rows.write('<c r="${CellRef.name(r - 1, c)}"><v>$r</v></c>');
      }
      rows.write('</row>');
    }
    rows.write('</sheetData>');
    final wb = XlsxParser.parseBytes(
      buildXlsx(sheets: {'Big': rows.toString()}),
      maxCells: 250,
    );
    expect(wb.truncated, isTrue);
    expect(wb.cellCount, 250);
  });

  test('rejects XML that declares a DOCTYPE', () {
    final bytes = buildXlsx(
      sheets: {'S': '<sheetData/>'},
      sharedStrings: ['<t>x</t>'],
    );
    // Rebuild with a hostile shared strings part.
    final archive = ZipDecoder().decodeBytes(bytes);
    final hostile = utf8.encode(
      '<?xml version="1.0"?><!DOCTYPE sst [<!ENTITY a "aaaa">]><sst><si><t>&a;</t></si></sst>',
    );
    final rebuilt = Archive();
    for (final file in archive.files) {
      if (file.name == 'xl/sharedStrings.xml') {
        rebuilt.addFile(ArchiveFile(file.name, hostile.length, hostile));
      } else {
        rebuilt.addFile(ArchiveFile(file.name, file.size, file.content));
      }
    }
    expect(
      () => XlsxParser.parseBytes(
        Uint8List.fromList(ZipEncoder().encode(rebuilt)),
      ),
      throwsA(const DocNookFailure.corrupt()),
    );
  });

  test('a ZIP that is not a workbook is reported as corrupt', () {
    final archive = Archive()
      ..addFile(ArchiveFile('hello.txt', 2, utf8.encode('hi')));
    expect(
      () => XlsxParser.parseBytes(
        Uint8List.fromList(ZipEncoder().encode(archive)),
      ),
      throwsA(const DocNookFailure.corrupt()),
    );
    expect(
      () => XlsxParser.parseBytes(Uint8List.fromList(const [1, 2, 3, 4])),
      throwsA(const DocNookFailure.corrupt()),
    );
  });

  test('cell references', () {
    expect(CellRef.columnName(0), 'A');
    expect(CellRef.columnName(25), 'Z');
    expect(CellRef.columnName(26), 'AA');
    expect(CellRef.columnName(16383), 'XFD');
    expect(CellRef.parse('XFD1048576'), (1048575, 16383));
    expect(CellRef.parse(r'$B$3'), (2, 1));
    expect(CellRef.parse('12'), isNull);
    expect(CellRef.parse('A'), isNull);
    final range = CellRef.parseRange('C3:A1')!;
    expect([range.top, range.left, range.bottom, range.right], [0, 0, 2, 2]);
  });
}

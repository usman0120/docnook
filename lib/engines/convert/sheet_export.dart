import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:docnook/domain/sheetmodel/number_format.dart';
import 'package:docnook/domain/sheetmodel/sheet_model.dart';
import 'package:docnook/engines/jobs/job_runner.dart';

/// One sheet as CSV text (RFC 4180): fields with commas, quotes or line
/// breaks are quoted; dates keep their displayed form, plain numbers keep
/// full precision without thousands separators.
String sheetToCsv(Workbook wb, Sheet sheet) {
  final out = StringBuffer();
  for (var r = 0; r < sheet.rowCount; r++) {
    final row = sheet.rowAt(r);
    final fields = <String>[];
    for (var c = 0; c < sheet.colCount; c++) {
      final value = row == null ? null : sheet.valueAt(r, c);
      fields.add(_csvField(_plainValue(wb, sheet, r, c, value)));
    }
    // Trailing empty cells add nothing but commas.
    while (fields.isNotEmpty && fields.last.isEmpty) {
      fields.removeLast();
    }
    out
      ..write(fields.join(','))
      ..write('\r\n');
  }
  return out.toString();
}

String _plainValue(Workbook wb, Sheet sheet, int r, int c, Object? value) {
  if (value == null) return '';
  if (value is num) {
    final code = wb.styleAt(sheet.styleIdAt(r, c)).formatCode;
    return NumberFormatter.isDateFormat(code)
        ? NumberFormatter.format(value, code, date1904: wb.date1904)
        : NumberFormatter.general(value.toDouble());
  }
  if (value is bool) return value ? 'TRUE' : 'FALSE';
  return value.toString();
}

String _csvField(String text) {
  if (text.contains(RegExp('[",\r\n]')) ||
      text.startsWith(' ') ||
      text.endsWith(' ')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

/// Writes [sheet] as a UTF-8 CSV with a byte-order mark, so Excel opens
/// non-English text correctly. Runs in a JobRunner isolate.
int writeCsvJob((Workbook, int, String) args, JobContext _) {
  final (wb, index, output) = args;
  final bytes = [
    0xEF,
    0xBB,
    0xBF,
    ...utf8.encode(sheetToCsv(wb, wb.sheets[index])),
  ];
  File(output).writeAsBytesSync(bytes, flush: true);
  return bytes.length;
}

/// A minimal but valid XLSX: values only (numbers stay numbers), column
/// widths, a bold first row when [boldHeader]. Runs in a JobRunner isolate.
int writeXlsxJob((Workbook, String, bool) args, JobContext _) {
  final (wb, output, boldHeader) = args;
  final bytes = buildXlsx(wb, boldHeader: boldHeader);
  File(output).writeAsBytesSync(bytes, flush: true);
  return bytes.length;
}

Uint8List buildXlsx(Workbook wb, {bool boldHeader = false}) {
  final sheets = wb.sheets.isEmpty
      ? [Sheet(name: 'Sheet1', rows: const [], rowCount: 0, colCount: 0)]
      : wb.sheets;
  final names = <String>[];
  for (final s in sheets) {
    var name = s.name.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
    if (name.isEmpty) name = 'Sheet${names.length + 1}';
    if (name.length > 31) name = name.substring(0, 31);
    var unique = name;
    var n = 2;
    while (names.contains(unique)) {
      unique = '${name.substring(0, name.length.clamp(0, 28))} $n';
      n++;
    }
    names.add(unique);
  }

  final archive = Archive();
  void add(String path, String text) {
    final data = utf8.encode(text);
    archive.addFile(ArchiveFile(path, data.length, data));
  }

  add('[Content_Types].xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
${[for (var i = 0; i < sheets.length; i++) '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join('\n')}
</Types>''');
  add('_rels/.rels', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''');
  add('xl/workbook.xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets>
${[for (var i = 0; i < sheets.length; i++) '<sheet name="${_xml(names[i])}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join('\n')}
</sheets>
</workbook>''');
  add('xl/_rels/workbook.xml.rels', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
${[for (var i = 0; i < sheets.length; i++) '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>'].join('\n')}
<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''');
  add('xl/styles.xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>
<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>
</styleSheet>''');

  for (var i = 0; i < sheets.length; i++) {
    final s = sheets[i];
    final xml = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n')
      ..write(
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
      );
    final widths = <int, double>{};
    for (var c = 0; c < s.colCount; c++) {
      var longest = 0;
      for (final row in s.rows.take(200)) {
        final slot = row.slotOf(c);
        if (slot < 0) continue;
        final len = _plainValue(wb, s, row.index, c, row.values[slot]).length;
        if (len > longest) longest = len;
      }
      widths[c] = s.colWidths[c] ?? (longest + 2).clamp(6, 60).toDouble();
    }
    if (widths.isNotEmpty) {
      xml.write('<cols>');
      widths.forEach((c, w) {
        xml.write(
          '<col min="${c + 1}" max="${c + 1}" width="$w" customWidth="1"/>',
        );
      });
      xml.write('</cols>');
    }
    xml.write('<sheetData>');
    for (final row in s.rows) {
      xml.write('<row r="${row.index + 1}">');
      for (var k = 0; k < row.length; k++) {
        final value = row.values[k];
        if (value == null) continue;
        final ref = CellRef.name(row.index, row.cols[k]);
        final style = boldHeader && row.index == 0 ? ' s="1"' : '';
        if (value is num && value.isFinite) {
          final code = wb.styleAt(row.styleIds[k]).formatCode;
          if (NumberFormatter.isDateFormat(code)) {
            // Keep the date readable without carrying the number format.
            final text = NumberFormatter.format(
              value,
              code,
              date1904: wb.date1904,
            );
            xml.write(
              '<c r="$ref" t="inlineStr"$style><is><t>${_xml(text)}</t></is></c>',
            );
          } else {
            xml.write('<c r="$ref"$style><v>$value</v></c>');
          }
        } else if (value is bool) {
          xml.write('<c r="$ref" t="b"$style><v>${value ? 1 : 0}</v></c>');
        } else {
          final text = value.toString();
          xml.write(
            '<c r="$ref" t="inlineStr"$style><is><t xml:space="preserve">${_xml(text)}</t></is></c>',
          );
        }
      }
      xml.write('</row>');
    }
    xml.write('</sheetData></worksheet>');
    add('xl/worksheets/sheet${i + 1}.xml', xml.toString());
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

String _xml(String text) {
  final out = StringBuffer();
  for (final r in text.runes) {
    switch (r) {
      case 0x26:
        out.write('&amp;');
      case 0x3C:
        out.write('&lt;');
      case 0x3E:
        out.write('&gt;');
      case 0x22:
        out.write('&quot;');
      default:
        // Control characters are not allowed in XML 1.0.
        if (r < 0x20 && r != 0x09 && r != 0x0A && r != 0x0D) continue;
        out.writeCharCode(r);
    }
  }
  return out.toString();
}

/// Escapes text for XML; shared with the DOCX writer.
String xmlEscape(String text) => _xml(text);

import 'dart:io';
import 'dart:typed_data';

import 'package:docnook/domain/sheetmodel/sheet_model.dart';
import 'package:docnook/engines/office/parse_document.dart' show decodeText;

/// Reads CSV / TSV into a one-sheet [Workbook] (RFC 4180: quoted fields,
/// doubled quotes, line breaks inside quotes). The delimiter is detected
/// from the first lines when not given (comma, semicolon, tab, pipe).
abstract final class CsvParser {
  static Workbook parseFile(String path, {String? delimiter, int maxCells = 1000000}) {
    final name = path.split(RegExp(r'[/\\]')).last;
    return parse(File(path).readAsBytesSync(), name: name, delimiter: delimiter, maxCells: maxCells);
  }

  static Workbook parse(Uint8List bytes, {String name = 'Sheet1', String? delimiter, int maxCells = 1000000}) {
    final text = decodeText(bytes);
    final sep = delimiter ?? detectDelimiter(text);
    final rows = <SheetRow>[];
    var cells = 0;
    var maxCol = 0;
    var truncated = false;

    var r = 0;
    final cols = <int>[];
    final values = <Object?>[];
    final field = StringBuffer();
    var col = 0;
    var quoted = false;
    var fieldWasQuoted = false;
    var i = 0;
    final sepCode = sep.codeUnitAt(0);

    void endField() {
      final raw = field.toString();
      field.clear();
      if (raw.isNotEmpty) {
        cols.add(col);
        values.add(fieldWasQuoted ? raw : _value(raw));
        cells++;
        if (col + 1 > maxCol) maxCol = col + 1;
      }
      col++;
      fieldWasQuoted = false;
    }

    void endRow() {
      endField();
      if (cols.isNotEmpty) {
        rows.add(SheetRow(r, Int32List.fromList(cols), List.of(values), Int32List(cols.length)));
      }
      cols.clear();
      values.clear();
      col = 0;
      r++;
    }

    while (i < text.length) {
      final c = text.codeUnitAt(i);
      if (quoted) {
        if (c == 0x22) {
          if (i + 1 < text.length && text.codeUnitAt(i + 1) == 0x22) {
            field.write('"');
            i += 2;
            continue;
          }
          quoted = false;
        } else {
          field.writeCharCode(c);
        }
        i++;
        continue;
      }
      if (c == 0x22 && field.isEmpty) {
        quoted = true;
        fieldWasQuoted = true;
      } else if (c == sepCode) {
        endField();
      } else if (c == 0x0A || c == 0x0D) {
        endRow();
        if (c == 0x0D && i + 1 < text.length && text.codeUnitAt(i + 1) == 0x0A) i++;
        if (cells >= maxCells) {
          truncated = true;
          break;
        }
      } else {
        field.writeCharCode(c);
      }
      i++;
    }
    if (!truncated && (field.isNotEmpty || cols.isNotEmpty || fieldWasQuoted)) endRow();

    final sheet = Sheet(
      name: name,
      rows: rows,
      rowCount: rows.isEmpty ? 0 : rows.last.index + 1,
      colCount: maxCol,
      frozenRows: rows.isNotEmpty && _looksLikeHeader(rows.first) ? 1 : 0,
    );
    return Workbook(sheets: [sheet], styles: const [CellStyle.none], truncated: truncated);
  }

  /// The separator that splits the first lines most consistently.
  static String detectDelimiter(String text) {
    final sample = text.length > 8192 ? text.substring(0, 8192) : text;
    final lines = sample.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).take(10).toList();
    if (lines.isEmpty) return ',';
    var best = ',';
    var bestScore = 0;
    for (final d in const [',', ';', '\t', '|']) {
      final counts = [for (final l in lines) _countOutsideQuotes(l, d)];
      final first = counts.first;
      if (first == 0) continue;
      final consistent = counts.where((n) => n == first).length;
      final score = consistent * 100 + first;
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    return best;
  }

  static int _countOutsideQuotes(String line, String d) {
    var n = 0;
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') quoted = !quoted;
      if (!quoted && c == d) n++;
    }
    return n;
  }

  /// Plain numbers become numbers (so they align right and format), every
  /// other value stays text. Leading zeros ("007") stay text.
  static Object _value(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return raw;
    if (RegExp(r'^-?(0|[1-9]\d{0,14})(\.\d+)?$').hasMatch(t)) {
      return double.tryParse(t) ?? raw;
    }
    return raw;
  }

  static bool _looksLikeHeader(SheetRow row) =>
      row.length > 1 && row.values.every((v) => v is String && v.trim().isNotEmpty);
}

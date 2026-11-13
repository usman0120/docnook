import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/sheetmodel/sheet_model.dart';
import 'package:docnook/engines/archive/safe_zip.dart';
import 'package:docnook/engines/office/xml_events.dart';

/// Reads OpenDocument Spreadsheet (.ods) into a [Workbook] (Good fidelity
/// for data): typed values (number, percentage, currency, date, boolean,
/// text), repeated rows/columns, spans. Number formats are approximated.
abstract final class OdsParser {
  static Workbook parseFile(String path, {int maxCells = 1000000}) {
    final zip = SafeZip.open(path);
    try {
      final content = zip.text('content.xml');
      if (content == null) {
        throw const DocNookFailure.corrupt(detail: 'ods: content');
      }
      return _read(content, maxCells);
    } finally {
      zip.close();
    }
  }

  static Workbook _read(String content, int maxCells) {
    final pull = XmlPull(content);
    final spreadsheet = pull.find('spreadsheet');
    if (spreadsheet == null) {
      throw const DocNookFailure.corrupt(detail: 'ods: body');
    }

    // Styles: index 0 plain, 1 percent, 2 currency, 3 date.
    const styles = [
      CellStyle.none,
      CellStyle(formatCode: '0.00%'),
      CellStyle(formatCode: '#,##0.00'),
      CellStyle(formatCode: 'dd/mm/yyyy'),
    ];

    final sheets = <Sheet>[];
    var budget = maxCells;
    var truncated = false;

    pull.children(spreadsheet, (table) {
      if (table.localName != 'table') return;
      final name = table.attr('table:name') ?? 'Sheet${sheets.length + 1}';
      final rows = <SheetRow>[];
      final merges = <CellRange>[];
      var r = 0;
      var maxCol = 0;

      void readRow(XmlStartElementEvent row) {
        final repeat =
            int.tryParse(row.attr('table:number-rows-repeated') ?? '') ?? 1;
        final cols = <int>[];
        final values = <Object?>[];
        final styleIds = <int>[];
        var c = 0;
        pull.children(row, (cell) {
          if (cell.localName != 'table-cell' &&
              cell.localName != 'covered-table-cell') {
            return;
          }
          final colRepeat =
              int.tryParse(cell.attr('table:number-columns-repeated') ?? '') ??
              1;
          final type = cell.attr('office:value-type');
          Object? value;
          var style = 0;
          switch (type) {
            case 'float':
              value = double.tryParse(cell.attr('office:value') ?? '');
            case 'percentage':
              value = double.tryParse(cell.attr('office:value') ?? '');
              style = 1;
            case 'currency':
              value = double.tryParse(cell.attr('office:value') ?? '');
              style = 2;
            case 'date':
              value = _serial(cell.attr('office:date-value'));
              style = value == null ? 0 : 3;
            case 'boolean':
              value = cell.attr('office:boolean-value') == 'true';
          }
          final text = StringBuffer();
          pull.children(cell, (p) {
            if (p.localName == 'p') {
              if (text.isNotEmpty) text.write('\n');
              text.write(pull.text(p));
            }
          });
          value ??= text.isEmpty ? null : text.toString();
          final spanC =
              int.tryParse(cell.attr('table:number-columns-spanned') ?? '') ??
              1;
          final spanR =
              int.tryParse(cell.attr('table:number-rows-spanned') ?? '') ?? 1;
          if ((spanC > 1 || spanR > 1) && merges.length < 20000) {
            merges.add(CellRange(r, c, r + spanR - 1, c + spanC - 1));
          }
          if (value != null) {
            // Trailing repeats of empty cells are padding, never data.
            final n = colRepeat.clamp(1, 1024);
            for (var k = 0; k < n && budget > 0; k++) {
              cols.add(c + k);
              values.add(value);
              styleIds.add(style);
              budget--;
            }
            if (c + n > maxCol) maxCol = c + n;
          }
          c += colRepeat.clamp(1, 16384);
        });
        if (cols.isNotEmpty) {
          final n = repeat.clamp(1, 1000);
          for (var k = 0; k < n; k++) {
            rows.add(
              SheetRow(
                r + k,
                Int32List.fromList(cols),
                List.of(values),
                Int32List.fromList(styleIds),
              ),
            );
          }
        }
        r += repeat.clamp(1, 1048576);
        if (budget <= 0) truncated = true;
      }

      pull.children(table, (child) {
        switch (child.localName) {
          case 'table-row':
            if (!truncated) readRow(child);
          case 'table-header-rows' || 'table-rows' || 'table-row-group':
            pull.children(child, (row) {
              if (row.localName == 'table-row' && !truncated) readRow(row);
            });
        }
      });

      sheets.add(
        Sheet(
          name: name,
          rows: rows,
          rowCount: rows.isEmpty ? 0 : rows.last.index + 1,
          colCount: maxCol,
          merges: merges,
        ),
      );
    });

    if (sheets.isEmpty) {
      throw const DocNookFailure.corrupt(detail: 'ods: no tables');
    }
    return Workbook(sheets: sheets, styles: styles, truncated: truncated);
  }

  /// "2026-03-15" or "2026-03-15T10:30:00" → Excel serial.
  static double? _serial(String? iso) {
    if (iso == null) return null;
    final t = DateTime.tryParse(
      iso.length == 10 ? '${iso}T00:00:00Z' : '${iso}Z',
    );
    if (t == null) return null;
    return t.difference(DateTime.utc(1899, 12, 30)).inMilliseconds / 86400000;
  }
}

import 'dart:typed_data';

/// SheetModel: the one in-memory form of every spreadsheet DocNook reads
/// (XLSX, ODS, CSV, TSV). It feeds both the grid viewer and Excel→PDF
/// (BLUEPRINT 5.5). Pure Dart; safe to hand between isolates.
final class Workbook {
  Workbook({
    required this.sheets,
    required this.styles,
    this.date1904 = false,
    this.truncated = false,
  });

  final List<Sheet> sheets;

  /// Cell styles, indexed by [SheetRow.styleIds]. Index 0 is the default.
  final List<CellStyle> styles;

  /// True when the workbook counts dates from 1904 (old Mac files).
  final bool date1904;

  /// True when parsing stopped at the cell limit (NFR-LIMIT-01).
  final bool truncated;

  int get cellCount => sheets.fold(0, (sum, s) => sum + s.cellCount);

  CellStyle styleAt(int id) =>
      id >= 0 && id < styles.length ? styles[id] : CellStyle.none;
}

enum HAlign { general, left, center, right }

enum VAlign { top, middle, bottom }

/// Visual and number formatting of a cell. Colours are 0xAARRGGBB.
final class CellStyle {
  const CellStyle({
    this.formatCode = 'General',
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.fontSize,
    this.color,
    this.fill,
    this.hAlign = HAlign.general,
    this.vAlign = VAlign.bottom,
    this.wrap = false,
    this.hasBorder = false,
  });

  static const none = CellStyle();

  /// Excel number format code, e.g. `#,##0.00` or `dd/mm/yyyy`.
  final String formatCode;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final double? fontSize;
  final int? color;
  final int? fill;
  final HAlign hAlign;
  final VAlign vAlign;
  final bool wrap;
  final bool hasBorder;
}

/// A formula error value such as `#DIV/0!`, kept distinct from text.
final class CellError {
  const CellError(this.code);
  final String code;

  @override
  String toString() => code;
}

/// One row's cells, stored sparsely in ascending column order. A value is
/// `null`, [num], [String], [bool] or [CellError]; formulas appear as their
/// cached result.
final class SheetRow {
  SheetRow(this.index, this.cols, this.values, this.styleIds, {this.height});

  final int index;
  final Int32List cols;
  final List<Object?> values;
  final Int32List styleIds;

  /// Row height in points when the file sets one.
  final double? height;

  int get length => cols.length;

  /// Position of [col] in this row's lists, or -1.
  int slotOf(int col) {
    var low = 0;
    var high = cols.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final value = cols[mid];
      if (value == col) return mid;
      if (value < col) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return -1;
  }
}

/// An inclusive rectangle of cells, zero-based.
final class CellRange {
  const CellRange(this.top, this.left, this.bottom, this.right);

  final int top;
  final int left;
  final int bottom;
  final int right;

  bool contains(int row, int col) =>
      row >= top && row <= bottom && col >= left && col <= right;

  int get rowSpan => bottom - top + 1;
  int get colSpan => right - left + 1;
}

final class Sheet {
  Sheet({
    required this.name,
    required this.rows,
    required this.rowCount,
    required this.colCount,
    this.colWidths = const {},
    this.merges = const [],
    this.formulas = const {},
    this.frozenRows = 0,
    this.frozenCols = 0,
    this.defaultColWidth,
    this.hidden = false,
  });

  final String name;

  /// Non-empty rows in ascending row order.
  final List<SheetRow> rows;

  /// Extent of the used area: one past the last used row / column.
  final int rowCount;
  final int colCount;

  /// Column widths in Excel character units, for columns that set one.
  final Map<int, double> colWidths;
  final double? defaultColWidth;
  final List<CellRange> merges;

  /// Formula text by [cellKey], for cells that have one.
  final Map<int, String> formulas;
  final int frozenRows;
  final int frozenCols;
  final bool hidden;

  int get cellCount => rows.fold(0, (sum, r) => sum + r.length);

  /// Packs a zero-based cell address into one int (Excel's limits are
  /// 1,048,576 rows × 16,384 columns).
  static int cellKey(int row, int col) => row * 16384 + col;

  SheetRow? rowAt(int index) {
    var low = 0;
    var high = rows.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final value = rows[mid].index;
      if (value == index) return rows[mid];
      if (value < index) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return null;
  }

  Object? valueAt(int row, int col) {
    final r = rowAt(row);
    if (r == null) return null;
    final slot = r.slotOf(col);
    return slot < 0 ? null : r.values[slot];
  }

  int styleIdAt(int row, int col) {
    final r = rowAt(row);
    if (r == null) return 0;
    final slot = r.slotOf(col);
    return slot < 0 ? 0 : r.styleIds[slot];
  }

  /// The merged range whose top-left or interior covers the cell, if any.
  CellRange? mergeAt(int row, int col) {
    for (final range in merges) {
      if (range.contains(row, col)) return range;
    }
    return null;
  }
}

/// Converts between zero-based indexes and A1-style references.
abstract final class CellRef {
  /// `0 → A`, `25 → Z`, `26 → AA`.
  static String columnName(int col) {
    var n = col + 1;
    final chars = <int>[];
    while (n > 0) {
      final rem = (n - 1) % 26;
      chars.add(0x41 + rem);
      n = (n - 1) ~/ 26;
    }
    return String.fromCharCodes(chars.reversed);
  }

  static String name(int row, int col) => '${columnName(col)}${row + 1}';

  /// Parses `BC12` into zero-based (row, col); null when malformed.
  static (int row, int col)? parse(String ref) {
    var col = 0;
    var i = 0;
    while (i < ref.length) {
      var c = ref.codeUnitAt(i);
      if (c == 0x24) {
        i++; // absolute marker "$"
        continue;
      }
      if (c >= 0x61 && c <= 0x7A) c -= 0x20;
      if (c < 0x41 || c > 0x5A) break;
      col = col * 26 + (c - 0x40);
      i++;
    }
    if (col == 0) return null;
    var row = 0;
    var digits = 0;
    while (i < ref.length) {
      final c = ref.codeUnitAt(i);
      if (c == 0x24) {
        i++;
        continue;
      }
      if (c < 0x30 || c > 0x39) return null;
      row = row * 10 + (c - 0x30);
      digits++;
      i++;
    }
    if (digits == 0 || row == 0) return null;
    return (row - 1, col - 1);
  }

  /// Parses `A1:C3` (or a single cell) into a range.
  static CellRange? parseRange(String ref) {
    final parts = ref.split(':');
    final first = parse(parts.first);
    if (first == null) return null;
    final last = parts.length > 1 ? parse(parts[1]) : first;
    if (last == null) return null;
    return CellRange(
      first.$1 < last.$1 ? first.$1 : last.$1,
      first.$2 < last.$2 ? first.$2 : last.$2,
      first.$1 > last.$1 ? first.$1 : last.$1,
      first.$2 > last.$2 ? first.$2 : last.$2,
    );
  }
}

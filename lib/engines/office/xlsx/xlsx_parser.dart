import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/sheetmodel/number_format.dart';
import 'package:docnook/domain/sheetmodel/sheet_model.dart';
import 'package:docnook/engines/archive/safe_zip.dart';
import 'package:docnook/engines/office/xml_events.dart';

/// Reads .xlsx / .xlsm into a [Workbook].
///
/// Each part is walked as a stream of XML events and cells are appended
/// straight into typed row buffers, so no XML tree and no per-cell objects
/// are built. Runs in an isolate (CLAUDE.md rule 4).
abstract final class XlsxParser {
  /// Excel's own sheet limit; also DocNook's safe limit (NFR-LIMIT-01).
  static const defaultMaxCells = 1000000;

  static Workbook parseFile(
    String path, {
    int maxCells = defaultMaxCells,
    void Function(double progress, String sheetName)? onProgress,
  }) {
    final zip = SafeZip.open(path);
    try {
      return _parse(zip, maxCells, onProgress);
    } finally {
      zip.close();
    }
  }

  static Workbook parseBytes(
    Uint8List bytes, {
    int maxCells = defaultMaxCells,
  }) {
    final zip = SafeZip.fromBytes(bytes);
    try {
      return _parse(zip, maxCells, null);
    } finally {
      zip.close();
    }
  }

  static Workbook _parse(
    SafeZip zip,
    int maxCells,
    void Function(double progress, String sheetName)? onProgress,
  ) {
    final workbookXml = zip.text('xl/workbook.xml');
    if (workbookXml == null) {
      throw const DocNookFailure.corrupt(detail: 'xlsx: no workbook');
    }

    final targets = _relationships(zip.text('xl/_rels/workbook.xml.rels'));
    final entries = <_SheetEntry>[];
    var date1904 = false;
    for (final event in xmlEvents(workbookXml)) {
      if (event is! XmlStartElementEvent) continue;
      if (event.localName == 'workbookPr') {
        date1904 = event.boolAttr('date1904');
      } else if (event.localName == 'sheet') {
        final id = event.attr('r:id') ?? event.attrLocal('id');
        final target = targets[id];
        if (target == null) continue;
        entries.add(
          _SheetEntry(
            event.attr('name') ?? 'Sheet${entries.length + 1}',
            target,
            hidden: (event.attr('state') ?? 'visible') != 'visible',
          ),
        );
      }
    }
    if (entries.isEmpty) {
      throw const DocNookFailure.corrupt(detail: 'xlsx: no sheets');
    }

    final strings = _sharedStrings(zip.text('xl/sharedStrings.xml'));
    final styles = _styles(zip.text('xl/styles.xml'));

    final sheets = <Sheet>[];
    var remaining = maxCells;
    var truncated = false;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      onProgress?.call(i / entries.length, entry.name);
      final xml = zip.text(entry.path);
      if (xml == null || remaining <= 0) {
        if (xml != null) truncated = true;
        sheets.add(
          Sheet(
            name: entry.name,
            rows: const [],
            rowCount: 0,
            colCount: 0,
            hidden: entry.hidden,
          ),
        );
        continue;
      }
      final reader = _SheetReader(strings, remaining)..read(xml);
      remaining -= reader.cellCount;
      truncated = truncated || reader.truncated;
      sheets.add(reader.build(entry.name, hidden: entry.hidden));
    }
    onProgress?.call(1, '');

    return Workbook(
      sheets: sheets,
      styles: styles,
      date1904: date1904,
      truncated: truncated,
    );
  }

  /// Relationship id → part path inside the archive.
  static Map<String, String> _relationships(String? xml) {
    final result = <String, String>{};
    if (xml == null) return result;
    for (final event in xmlEvents(xml)) {
      if (event is! XmlStartElementEvent || event.localName != 'Relationship') {
        continue;
      }
      final id = event.attr('Id');
      var target = event.attr('Target');
      if (id == null || target == null) continue;
      if (event.attr('TargetMode') == 'External') continue;
      // Targets are relative to xl/ unless they start with a slash.
      target = target.startsWith('/') ? target.substring(1) : 'xl/$target';
      result[id] = _collapse(target);
    }
    return result;
  }

  static String _collapse(String path) {
    final parts = <String>[];
    for (final part in path.split('/')) {
      if (part == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (part.isNotEmpty && part != '.') {
        parts.add(part);
      }
    }
    return parts.join('/');
  }

  static List<String> _sharedStrings(String? xml) {
    final strings = <String>[];
    if (xml == null) return strings;
    final buffer = StringBuffer();
    var inItem = false;
    var inText = false;
    var phoneticDepth = 0;
    for (final event in xmlEvents(xml)) {
      if (event is XmlStartElementEvent) {
        switch (event.localName) {
          case 'si':
            inItem = !event.isSelfClosing;
            buffer.clear();
            if (event.isSelfClosing) strings.add('');
          case 't':
            inText = inItem && phoneticDepth == 0 && !event.isSelfClosing;
          case 'rPh':
            // Phonetic guide text (Japanese readings) is not cell content.
            if (!event.isSelfClosing) phoneticDepth++;
        }
      } else if (event is XmlEndElementEvent) {
        switch (event.localName) {
          case 'si':
            strings.add(buffer.toString());
            inItem = false;
          case 't':
            inText = false;
          case 'rPh':
            if (phoneticDepth > 0) phoneticDepth--;
        }
      } else if (inText) {
        if (event is XmlTextEvent) buffer.write(event.value);
        if (event is XmlCDATAEvent) buffer.write(event.value);
      }
    }
    return strings;
  }

  // Default Office theme colours, in the order Excel's theme indexes use
  // (light 1 and dark 1 are swapped relative to the theme part).
  static const _themeColors = [
    0xFFFFFFFF, 0xFF000000, 0xFFE7E6E6, 0xFF44546A, 0xFF4472C4, //
    0xFFED7D31, 0xFFA5A5A5, 0xFFFFC000, 0xFF5B9BD5, 0xFF70AD47,
  ];

  // The classic 56-colour palette used by `indexed` colours (8–63).
  static const _indexedColors = [
    0xFF000000, 0xFFFFFFFF, 0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFFFFFF00,
    0xFFFF00FF, 0xFF00FFFF, 0xFF000000, 0xFFFFFFFF, 0xFFFF0000, 0xFF00FF00,
    0xFF0000FF, 0xFFFFFF00, 0xFFFF00FF, 0xFF00FFFF, 0xFF800000, 0xFF008000,
    0xFF000080, 0xFF808000, 0xFF800080, 0xFF008080, 0xFFC0C0C0, 0xFF808080,
    0xFF9999FF, 0xFF993366, 0xFFFFFFCC, 0xFFCCFFFF, 0xFF660066, 0xFFFF8080,
    0xFF0066CC, 0xFFCCCCFF, 0xFF000080, 0xFFFF00FF, 0xFFFFFF00, 0xFF00FFFF,
    0xFF800080, 0xFF800000, 0xFF008080, 0xFF0000FF, 0xFF00CCFF, 0xFFCCFFFF,
    0xFFCCFFCC, 0xFFFFFF99, 0xFF99CCFF, 0xFFFF99CC, 0xFFCC99FF, 0xFFFFCC99,
    0xFF3366FF, 0xFF33CCCC, 0xFF99CC00, 0xFFFFCC00, 0xFFFF9900, 0xFFFF6600,
    0xFF666699, 0xFF969696, 0xFF003366, 0xFF339966, 0xFF003300, 0xFF333300,
    0xFF993300, 0xFF993366, 0xFF333399, 0xFF333333, //
  ];

  static int? _color(XmlStartElementEvent event) {
    final rgb = event.attr('rgb');
    if (rgb != null) {
      final value = int.tryParse(rgb, radix: 16);
      if (value == null) return null;
      return rgb.length <= 6 ? 0xFF000000 | value : value;
    }
    final theme = event.intAttr('theme');
    if (theme != null && theme >= 0 && theme < _themeColors.length) {
      return _tint(_themeColors[theme], event.doubleAttr('tint') ?? 0);
    }
    final indexed = event.intAttr('indexed');
    if (indexed != null && indexed >= 0 && indexed < _indexedColors.length) {
      return _indexedColors[indexed];
    }
    return null; // "auto" and system colours follow the app theme
  }

  /// Lightens (positive) or darkens (negative) a colour, as Excel's `tint`.
  static int _tint(int argb, double tint) {
    if (tint == 0) return argb;
    int channel(int c) {
      final value = tint < 0 ? c * (1 + tint) : c + (255 - c) * tint;
      return value.round().clamp(0, 255);
    }

    return 0xFF000000 |
        channel(argb >> 16 & 0xFF) << 16 |
        channel(argb >> 8 & 0xFF) << 8 |
        channel(argb & 0xFF);
  }

  static List<CellStyle> _styles(String? xml) {
    if (xml == null) return const [CellStyle.none];

    final formats = <int, String>{};
    final fonts = <_Font>[];
    final fills = <int?>[];
    final borders = <bool>[];
    final styles = <CellStyle>[];

    // Which collection the walker is inside; cellStyleXfs and dxfs reuse the
    // same child element names and must not be mistaken for cell formats.
    var section = '';
    _Font? font;
    var inFill = false;
    int? fillColor;
    var fillIsSolid = false;
    var borderHasLine = false;
    _Xf? xf;

    void finishXf() {
      final x = xf;
      if (x == null) return;
      xf = null;
      final f = x.fontId < fonts.length ? fonts[x.fontId] : const _Font();
      styles.add(
        CellStyle(
          formatCode:
              formats[x.numFmtId] ?? NumberFormatter.builtinCode(x.numFmtId),
          bold: f.bold,
          italic: f.italic,
          underline: f.underline,
          strike: f.strike,
          fontSize: f.size,
          color: f.color,
          fill: x.fillId < fills.length ? fills[x.fillId] : null,
          hAlign: x.hAlign,
          vAlign: x.vAlign,
          wrap: x.wrap,
          hasBorder: x.borderId < borders.length && borders[x.borderId],
        ),
      );
    }

    for (final event in xmlEvents(xml)) {
      if (event is XmlStartElementEvent) {
        final name = event.localName;
        switch (name) {
          case 'numFmts' ||
              'fonts' ||
              'fills' ||
              'borders' ||
              'cellXfs' ||
              'cellStyleXfs' ||
              'cellStyles' ||
              'dxfs' ||
              'tableStyles' ||
              'colors':
            if (!event.isSelfClosing) section = name;
            continue;
        }
        switch (section) {
          case 'numFmts':
            if (name == 'numFmt') {
              final id = event.intAttr('numFmtId');
              final code = event.attr('formatCode');
              if (id != null && code != null) formats[id] = code;
            }
          case 'fonts':
            if (name == 'font') {
              font = const _Font();
              if (event.isSelfClosing) {
                fonts.add(font);
                font = null;
              }
            } else if (font != null) {
              final on =
                  event.attr('val') != '0' && event.attr('val') != 'false';
              font = switch (name) {
                'b' => font.copy(bold: on),
                'i' => font.copy(italic: on),
                'u' => font.copy(underline: event.attr('val') != 'none'),
                'strike' => font.copy(strike: on),
                'sz' => font.copy(size: event.doubleAttr('val')),
                'color' => font.copy(color: _color(event)),
                _ => font,
              };
            }
          case 'fills':
            if (name == 'fill') {
              inFill = true;
              fillColor = null;
              fillIsSolid = false;
              if (event.isSelfClosing) {
                fills.add(null);
                inFill = false;
              }
            } else if (inFill && name == 'patternFill') {
              final pattern = event.attr('patternType');
              fillIsSolid = pattern != null && pattern != 'none';
            } else if (inFill && name == 'fgColor') {
              fillColor = _color(event);
            }
          case 'borders':
            if (name == 'border') {
              borderHasLine = false;
              if (event.isSelfClosing) borders.add(false);
            } else if (const {
              'left',
              'right',
              'top',
              'bottom',
            }.contains(name)) {
              final style = event.attr('style');
              if (style != null && style != 'none') borderHasLine = true;
            }
          case 'cellXfs':
            if (name == 'xf') {
              xf = _Xf(
                event.intAttr('numFmtId') ?? 0,
                event.intAttr('fontId') ?? 0,
                event.intAttr('fillId') ?? 0,
                event.intAttr('borderId') ?? 0,
              );
              if (event.isSelfClosing) finishXf();
            } else if (name == 'alignment' && xf != null) {
              xf!
                ..hAlign = switch (event.attr('horizontal')) {
                  'left' => HAlign.left,
                  'center' ||
                  'centerContinuous' ||
                  'distributed' => HAlign.center,
                  'right' => HAlign.right,
                  _ => HAlign.general,
                }
                ..vAlign = switch (event.attr('vertical')) {
                  'top' => VAlign.top,
                  'center' || 'distributed' || 'justify' => VAlign.middle,
                  _ => VAlign.bottom,
                }
                ..wrap = event.boolAttr('wrapText');
            }
        }
      } else if (event is XmlEndElementEvent) {
        final name = event.localName;
        if (name == section) {
          section = '';
        } else if (section == 'fonts' && name == 'font' && font != null) {
          fonts.add(font);
          font = null;
        } else if (section == 'fills' && name == 'fill' && inFill) {
          fills.add(fillIsSolid ? fillColor : null);
          inFill = false;
        } else if (section == 'borders' && name == 'border') {
          borders.add(borderHasLine);
        } else if (section == 'cellXfs' && name == 'xf') {
          finishXf();
        }
      }
    }
    return styles.isEmpty ? const [CellStyle.none] : styles;
  }
}

final class _SheetEntry {
  const _SheetEntry(this.name, this.path, {required this.hidden});
  final String name;
  final String path;
  final bool hidden;
}

final class _Font {
  const _Font({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.size,
    this.color,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final double? size;
  final int? color;

  _Font copy({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    double? size,
    int? color,
  }) => _Font(
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    strike: strike ?? this.strike,
    size: size ?? this.size,
    color: color ?? this.color,
  );
}

final class _Xf {
  _Xf(this.numFmtId, this.fontId, this.fillId, this.borderId);
  final int numFmtId;
  final int fontId;
  final int fillId;
  final int borderId;
  HAlign hAlign = HAlign.general;
  VAlign vAlign = VAlign.bottom;
  bool wrap = false;
}

/// Walks one worksheet part.
final class _SheetReader {
  _SheetReader(this._strings, this._budget);

  final List<String> _strings;
  final int _budget;

  final rows = <SheetRow>[];
  final colWidths = <int, double>{};
  final merges = <CellRange>[];
  final formulas = <int, String>{};
  double? defaultColWidth;
  int frozenRows = 0;
  int frozenCols = 0;
  int cellCount = 0;
  int maxCol = -1;
  bool truncated = false;

  // Buffers for the row being read.
  final _cols = <int>[];
  final _values = <Object?>[];
  final _styleIds = <int>[];

  void read(String xml) {
    var rowIndex = -1;
    double? rowHeight;
    var inRow = false;

    // State of the cell being read.
    var col = -1;
    var style = 0;
    var type = '';
    var inValue = false;
    var inFormula = false;
    var inInlineText = false;
    var inCell = false;
    final text = StringBuffer();
    final formula = StringBuffer();
    var hasValue = false;
    var hasFormula = false;

    void endCell() {
      inCell = false;
      Object? value;
      if (hasValue) {
        final raw = text.toString();
        switch (type) {
          case 's':
            final index = int.tryParse(raw);
            value = index != null && index >= 0 && index < _strings.length
                ? _strings[index]
                : '';
          case 'b':
            value = raw == '1' || raw == 'true';
          case 'e':
            value = CellError(raw);
          case 'str' || 'inlineStr' || 'd':
            value = raw;
          default:
            value = double.tryParse(raw) ?? raw;
        }
      }
      if (value == null && style == 0 && !hasFormula) return;
      if (value is String && value.isEmpty && style == 0 && !hasFormula) return;

      if (cellCount >= _budget) {
        truncated = true;
        return;
      }
      // Cells normally arrive in column order; keep the row sorted if not.
      if (_cols.isNotEmpty && col <= _cols.last) {
        var at = _cols.length;
        while (at > 0 && _cols[at - 1] > col) {
          at--;
        }
        if (at > 0 && _cols[at - 1] == col) return; // duplicate address
        _cols.insert(at, col);
        _values.insert(at, value);
        _styleIds.insert(at, style);
      } else {
        _cols.add(col);
        _values.add(value);
        _styleIds.add(style);
      }
      cellCount++;
      if (col > maxCol) maxCol = col;
      if (hasFormula) {
        formulas[Sheet.cellKey(rowIndex, col)] = formula.toString();
      }
    }

    void endRow() {
      inRow = false;
      if (_cols.isEmpty) return;
      rows.add(
        SheetRow(
          rowIndex,
          Int32List.fromList(_cols),
          List<Object?>.of(_values, growable: false),
          Int32List.fromList(_styleIds),
          height: rowHeight,
        ),
      );
      _cols.clear();
      _values.clear();
      _styleIds.clear();
    }

    for (final event in xmlEvents(xml)) {
      if (event is XmlStartElementEvent) {
        switch (event.localName) {
          case 'c':
            if (!inRow) continue;
            final ref = event.attr('r');
            final parsed = ref == null ? null : CellRef.parse(ref);
            col = parsed?.$2 ?? col + 1;
            style = event.intAttr('s') ?? 0;
            type = event.attr('t') ?? 'n';
            text.clear();
            formula.clear();
            hasValue = false;
            hasFormula = false;
            inCell = true;
            if (event.isSelfClosing) endCell();
          case 'v':
            inValue = inCell && !event.isSelfClosing;
            if (inValue) hasValue = true;
          case 'f':
            if (inCell) {
              hasFormula = true;
              inFormula = !event.isSelfClosing;
            }
          case 't':
            // Inline string text: <c t="inlineStr"><is><t>…</t></is></c>
            inInlineText =
                inCell && type == 'inlineStr' && !event.isSelfClosing;
            if (inInlineText) hasValue = true;
          case 'row':
            if (truncated) return;
            final r = event.intAttr('r');
            rowIndex = r != null ? r - 1 : rowIndex + 1;
            rowHeight = event.boolAttr('customHeight')
                ? event.doubleAttr('ht')
                : null;
            col = -1;
            inRow = !event.isSelfClosing;
          case 'col':
            final min = event.intAttr('min');
            final max = event.intAttr('max');
            final width = event.doubleAttr('width');
            if (min == null || max == null) continue;
            final hidden = event.boolAttr('hidden');
            // A trailing "all remaining columns" range is a default, not data.
            if (max - min > 255) {
              defaultColWidth ??= hidden ? 0 : width;
              continue;
            }
            for (var c = min; c <= max; c++) {
              if (hidden) {
                colWidths[c - 1] = 0;
              } else if (width != null) {
                colWidths[c - 1] = width;
              }
            }
          case 'sheetFormatPr':
            defaultColWidth =
                event.doubleAttr('defaultColWidth') ?? defaultColWidth;
          case 'pane':
            final state = event.attr('state');
            if (state == 'frozen' || state == 'frozenSplit') {
              frozenCols = (event.doubleAttr('xSplit') ?? 0).round();
              frozenRows = (event.doubleAttr('ySplit') ?? 0).round();
            }
          case 'mergeCell':
            final ref = event.attr('ref');
            final range = ref == null ? null : CellRef.parseRange(ref);
            if (range != null && merges.length < 20000) merges.add(range);
        }
      } else if (event is XmlEndElementEvent) {
        switch (event.localName) {
          case 'c':
            if (inCell) endCell();
          case 'v':
            inValue = false;
          case 'f':
            inFormula = false;
          case 't':
            inInlineText = false;
          case 'row':
            if (inRow) endRow();
        }
      } else if (event is XmlTextEvent) {
        if (inValue || inInlineText) {
          text.write(event.value);
        } else if (inFormula) {
          formula.write(event.value);
        }
      } else if (event is XmlCDATAEvent) {
        if (inValue || inInlineText) text.write(event.value);
      }
    }
  }

  Sheet build(String name, {required bool hidden}) {
    var colCount = maxCol + 1;
    for (final range in merges) {
      if (range.right + 1 > colCount) colCount = range.right + 1;
    }
    var rowCount = rows.isEmpty ? 0 : rows.last.index + 1;
    for (final range in merges) {
      if (range.bottom + 1 > rowCount) rowCount = range.bottom + 1;
    }
    return Sheet(
      name: name,
      rows: rows,
      rowCount: rowCount,
      colCount: colCount,
      colWidths: colWidths,
      defaultColWidth: defaultColWidth,
      merges: merges,
      formulas: formulas,
      frozenRows: frozenRows,
      frozenCols: frozenCols,
      hidden: hidden,
    );
  }
}

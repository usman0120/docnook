import 'dart:async';
import 'dart:math' as math;

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/data/repositories/document_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/domain/sheetmodel/number_format.dart';
import 'package:docnook/domain/sheetmodel/sheet_model.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/office/sheet/csv_parser.dart';
import 'package:docnook/engines/office/sheet/ods_parser.dart';
import 'package:docnook/engines/office/xlsx/xlsx_parser.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/presentation/cant_open_screen.dart';
import 'package:docnook/features/viewer/presentation/viewer_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// What to parse for the grid.
final class SheetRequest {
  const SheetRequest(this.path, this.format);
  final String path;
  final DocFormat format;
}

/// Parses any spreadsheet into a [Workbook] in an isolate.
Workbook parseToWorkbook(SheetRequest request, JobContext context) =>
    switch (request.format) {
      DocFormat.xlsx || DocFormat.xlsm => XlsxParser.parseFile(
        request.path,
        onProgress: (p, _) => context.progress(p),
      ),
      DocFormat.ods => OdsParser.parseFile(request.path),
      DocFormat.csv => CsvParser.parseFile(request.path),
      DocFormat.tsv => CsvParser.parseFile(request.path, delimiter: '\t'),
      _ => throw const DocNookFailure.unsupported(),
    };

/// S16 sheet viewer (FR-READ-03, NFR-PERF-04).
class SheetViewerScreen extends ConsumerStatefulWidget {
  const SheetViewerScreen({required this.document, super.key});

  final OpenedDocument document;

  @override
  ConsumerState<SheetViewerScreen> createState() => _SheetViewerScreenState();
}

class _SheetViewerScreenState extends ConsumerState<SheetViewerScreen> {
  Result<Workbook>? _parsed;
  double _progress = 0;
  int _sheet = 0;
  (int, int)? _selected;
  bool _fitWidth = false;
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  late final DocumentRepository _repo = ref.read(documentRepositoryProvider);
  JobHandle<Workbook>? _job;

  // Search
  bool _searching = false;
  final _searchField = TextEditingController();
  final _searchFocus = FocusNode();
  List<(int, int)> _matches = const [];
  int _active = -1;

  static const _headerHeight = 28.0;
  static const _rowHeaderWidth = 44.0;
  // Excel's width unit is one digit of the default font; at DocNook's cell
  // font size a digit is ~8.4 px.
  static const _charWidth = 8.4;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _job?.cancel();
    unawaited(_save());
    _vertical.dispose();
    _horizontal.dispose();
    _searchField.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final job = ref
        .read(jobRunnerProvider)
        .run(
          parseToWorkbook,
          SheetRequest(widget.document.path, widget.document.format),
        );
    _job = job;
    final sub = job.progress.listen((p) {
      if (mounted) setState(() => _progress = p.value);
    });
    final result = await job.result;
    await sub.cancel();
    _job = null;
    if (!mounted) return;
    final saved = await _repo.position(widget.document.documentId);
    final prefs = await _repo.viewPrefs(widget.document.documentId);
    setState(() {
      _parsed = result;
      _fitWidth = prefs['fit'] == true;
      final wb = result.valueOrNull;
      if (wb != null) {
        _sheet = (saved?.sheet ?? _firstVisibleSheet(wb)).clamp(
          0,
          wb.sheets.length - 1,
        );
      }
    });
    final row = saved?.row;
    final col = saved?.col;
    if (row != null && col != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollTo(row, col, select: false),
      );
    }
  }

  int _firstVisibleSheet(Workbook wb) {
    final i = wb.sheets.indexWhere((s) => !s.hidden && s.cellCount > 0);
    return i < 0 ? 0 : i;
  }

  Future<void> _save() async {
    final wb = _parsed?.valueOrNull;
    if (wb == null) return;
    final sheet = wb.sheets[_sheet];
    final (row, col) = _topLeft(sheet);
    await _repo.savePosition(
      widget.document.documentId,
      ReadingPosition(sheet: _sheet, row: row, col: col),
      progress: sheet.rowCount <= 1 ? 1 : row / (sheet.rowCount - 1),
      viewPrefs: {'fit': _fitWidth},
    );
  }

  // --------------------------------------------------------- geometry

  double _scale(Sheet sheet, double viewWidth) {
    if (!_fitWidth) return 1;
    var total = 0.0;
    for (var c = 0; c < sheet.colCount; c++) {
      total += _rawColWidth(sheet, c);
    }
    if (total <= 0) return 1;
    return ((viewWidth - _rowHeaderWidth) / total).clamp(0.35, 1).toDouble();
  }

  double _rawColWidth(Sheet sheet, int c) {
    final chars =
        sheet.colWidths[c] ?? sheet.defaultColWidth ?? _autoWidth(sheet, c);
    return chars <= 0 ? 0 : math.max(chars * _charWidth + 10, 28);
  }

  /// Files without stored widths (CSV, most ODS) size columns to their
  /// content, measured on the first 300 rows and capped at 40 characters.
  final _autoWidths = <Sheet, List<double>>{};

  double _autoWidth(Sheet sheet, int c) {
    final widths = _autoWidths.putIfAbsent(sheet, () {
      final out = List<double>.filled(sheet.colCount, 0);
      final wb = _parsed?.valueOrNull;
      for (final row in sheet.rows.take(300)) {
        for (var i = 0; i < row.length; i++) {
          final col = row.cols[i];
          if (col >= out.length) continue;
          final text = wb == null
              ? '${row.values[i] ?? ''}'
              : NumberFormatter.format(
                  row.values[i],
                  wb.styleAt(row.styleIds[i]).formatCode,
                  date1904: wb.date1904,
                );
          final longest = text
              .split(String.fromCharCode(10))
              .fold<int>(0, (m, l) => math.max(m, l.length));
          out[col] = math.max(out[col], longest.toDouble());
        }
      }
      return [for (final w in out) w == 0 ? 9.14 : w.clamp(6, 40).toDouble()];
    });
    return c < widths.length ? widths[c] : 9.14;
  }

  double _rowHeight(Sheet sheet, int r, double scale) {
    final h = sheet.rowAt(r)?.height;
    return math.max((h == null ? 20.0 : h * 1.33) * scale, 18 * scale) + 4;
  }

  (int, int) _topLeft(Sheet sheet) {
    final scale = _lastScale;
    var y = _vertical.hasClients ? _vertical.offset : 0.0;
    var row = 0;
    while (row < sheet.rowCount && y > 0) {
      y -= _rowHeight(sheet, row, scale);
      if (y > 0) row++;
    }
    var x = _horizontal.hasClients ? _horizontal.offset : 0.0;
    var col = 0;
    while (col < sheet.colCount && x > 0) {
      x -= _rawColWidth(sheet, col) * scale;
      if (x > 0) col++;
    }
    return (row, col);
  }

  double _lastScale = 1;

  void _scrollTo(int row, int col, {bool select = true}) {
    final wb = _parsed?.valueOrNull;
    if (wb == null) return;
    final sheet = wb.sheets[_sheet];
    final scale = _lastScale;
    var y = 0.0;
    for (var r = 0; r < row; r++) {
      y += _rowHeight(sheet, r, scale);
    }
    var x = 0.0;
    for (var c = 0; c < col; c++) {
      x += _rawColWidth(sheet, c) * scale;
    }
    if (_vertical.hasClients) {
      _vertical.jumpTo(
        math.min(math.max(y - 60, 0), _vertical.position.maxScrollExtent),
      );
    }
    if (_horizontal.hasClients) {
      _horizontal.jumpTo(
        math.min(math.max(x - 40, 0), _horizontal.position.maxScrollExtent),
      );
    }
    if (select) setState(() => _selected = (row, col));
  }

  // ------------------------------------------------------------ search

  void _runSearch(String text) {
    final wb = _parsed?.valueOrNull;
    final term = text.trim().toLowerCase();
    if (wb == null || term.isEmpty) {
      setState(() {
        _matches = const [];
        _active = -1;
      });
      return;
    }
    final sheet = wb.sheets[_sheet];
    final found = <(int, int)>[];
    for (final row in sheet.rows) {
      for (var i = 0; i < row.length && found.length < 5000; i++) {
        final shown = NumberFormatter.format(
          row.values[i],
          wb.styleAt(row.styleIds[i]).formatCode,
          date1904: wb.date1904,
        );
        if (shown.toLowerCase().contains(term))
          found.add((row.index, row.cols[i]));
      }
    }
    setState(() {
      _matches = found;
      _active = found.isEmpty ? -1 : 0;
    });
    if (found.isNotEmpty) _scrollTo(found.first.$1, found.first.$2);
  }

  void _step(int delta) {
    if (_matches.isEmpty) return;
    _active = (_active + delta) % _matches.length;
    _scrollTo(_matches[_active].$1, _matches[_active].$2);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final doc = widget.document;
    final platform = ref.read(platformProvider);
    final parsed = _parsed;

    if (parsed case Err(:final failure)) {
      return CantOpenScreen(
        failure: failure,
        onOpenWith: () => unawaited(
          platform.openWith(doc.request.uri, mime: doc.format.mime),
        ),
      );
    }
    final wb = parsed?.valueOrNull;
    final visibleSheets = wb == null
        ? const <int>[]
        : [
            for (var i = 0; i < wb.sheets.length; i++)
              if (!wb.sheets[i].hidden) i,
          ];

    return Scaffold(
      backgroundColor: c.surface,
      body: Column(
        children: [
          ViewerTopBar(
            visible: true,
            title: doc.name,
            search: _searching
                ? SearchBarContent(
                    controller: _searchField,
                    focusNode: _searchFocus,
                    hint: l.searchInDocument,
                    status: _searchField.text.trim().isEmpty
                        ? null
                        : _matches.isEmpty
                        ? l.searchNoMatches
                        : l.searchMatches(_active + 1, _matches.length),
                    onChanged: _runSearch,
                    onPrevious: _matches.isEmpty ? null : () => _step(-1),
                    onNext: _matches.isEmpty ? null : () => _step(1),
                    onClose: () {
                      _searchField.clear();
                      _runSearch('');
                      setState(() => _searching = false);
                    },
                  )
                : null,
            actions: [
              IconAction(
                icon: PhosphorIconsRegular.magnifyingGlass,
                label: l.searchInDocument,
                onPressed: wb == null
                    ? null
                    : () {
                        setState(() => _searching = true);
                        _searchFocus.requestFocus();
                      },
              ),
              IconAction(
                icon: _fitWidth
                    ? PhosphorIconsRegular.arrowsOut
                    : PhosphorIconsRegular.arrowsIn,
                label: _fitWidth ? l.sheetActualSize : l.sheetFitWidth,
                selected: _fitWidth,
                onPressed: wb == null
                    ? null
                    : () => setState(() => _fitWidth = !_fitWidth),
              ),
              ViewerOverflowMenu(
                items: [
                  (
                    l.actionShare,
                    PhosphorIconsRegular.shareNetwork,
                    () => platform.share([doc.path], mime: doc.format.mime),
                  ),
                  (
                    l.actionOpenWith,
                    PhosphorIconsRegular.arrowSquareOut,
                    () => platform.openWith(
                      doc.request.uri,
                      mime: doc.format.mime,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (wb?.truncated ?? false) _Note(text: l.sheetTruncated),
          Expanded(
            child: wb == null
                ? LoadingState(
                    label: _progress > 0
                        ? '${(_progress * 100).round()}%'
                        : l.openingFile,
                  )
                : wb.sheets[_sheet].cellCount == 0
                ? Center(
                    child: EmptyState(
                      art: EmptyArt.paperStack,
                      title: l.sheetEmpty,
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) =>
                        _grid(context, wb, constraints.maxWidth),
                  ),
          ),
          if (_selected != null && wb != null)
            _CellPanel(
              workbook: wb,
              sheet: wb.sheets[_sheet],
              cell: _selected!,
              onClose: () => setState(() => _selected = null),
            ),
          if (visibleSheets.length > 1)
            _SheetTabs(
              names: [for (final i in visibleSheets) wb!.sheets[i].name],
              selected: visibleSheets.indexOf(_sheet),
              onSelect: (i) {
                setState(() {
                  _sheet = visibleSheets[i];
                  _selected = null;
                  _matches = const [];
                });
                if (_vertical.hasClients) _vertical.jumpTo(0);
                if (_horizontal.hasClients) _horizontal.jumpTo(0);
                if (_searchField.text.isNotEmpty) _runSearch(_searchField.text);
              },
            ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, Workbook wb, double width) {
    final c = context.colors;
    final sheet = wb.sheets[_sheet];
    final scale = _scale(sheet, width);
    _lastScale = scale;
    final gridLine = BorderSide(color: c.hairline, width: 0.6);
    final headerStyle = DocNookText.caption.copyWith(
      color: c.inkMuted,
      fontSize: 11 * math.max(scale, 0.8),
    );
    final active = _active >= 0 && _active < _matches.length
        ? _matches[_active]
        : null;
    final matchSet = {for (final m in _matches) m};

    // Merged cells are looked up once per build.
    final mergeAt = <int, CellRange>{};
    for (final m in sheet.merges) {
      if (m.rowSpan * m.colSpan > 2000) continue;
      for (var r = m.top; r <= m.bottom; r++) {
        for (var cc = m.left; cc <= m.right; cc++) {
          mergeAt[Sheet.cellKey(r, cc)] = m;
        }
      }
    }

    return TableView.builder(
      verticalDetails: ScrollableDetails.vertical(controller: _vertical),
      horizontalDetails: ScrollableDetails.horizontal(controller: _horizontal),
      diagonalDragBehavior: DiagonalDragBehavior.free,
      rowCount: math.max(sheet.rowCount, 1) + 1,
      columnCount: math.max(sheet.colCount, 1) + 1,
      pinnedRowCount: 1 + math.min(sheet.frozenRows, 20),
      pinnedColumnCount: 1 + math.min(sheet.frozenCols, 10),
      columnBuilder: (i) => TableSpan(
        extent: FixedTableSpanExtent(
          i == 0 ? _rowHeaderWidth : _rawColWidth(sheet, i - 1) * scale,
        ),
        foregroundDecoration: TableSpanDecoration(
          border: TableSpanBorder(trailing: gridLine),
        ),
      ),
      rowBuilder: (i) => TableSpan(
        extent: FixedTableSpanExtent(
          i == 0 ? _headerHeight : _rowHeight(sheet, i - 1, scale),
        ),
        foregroundDecoration: TableSpanDecoration(
          border: TableSpanBorder(trailing: gridLine),
        ),
      ),
      cellBuilder: (context, v) {
        final r = v.row - 1;
        final col = v.column - 1;
        if (v.row == 0 && v.column == 0) {
          return TableViewCell(child: ColoredBox(color: c.surfaceSunken));
        }
        if (v.row == 0) {
          return TableViewCell(
            child: ColoredBox(
              color: c.surfaceSunken,
              child: Center(
                child: Text(CellRef.columnName(col), style: headerStyle),
              ),
            ),
          );
        }
        if (v.column == 0) {
          return TableViewCell(
            child: ColoredBox(
              color: c.surfaceSunken,
              child: Center(child: Text('${r + 1}', style: headerStyle)),
            ),
          );
        }
        final merge = mergeAt[Sheet.cellKey(r, col)];
        final mr = merge?.top ?? r;
        final mc = merge?.left ?? col;
        final value = sheet.valueAt(mr, mc);
        final style = wb.styleAt(sheet.styleIdAt(mr, mc));
        final selected = _selected == (mr, mc);
        final isMatch = matchSet.contains((mr, mc));
        final cell = _CellView(
          value: value,
          style: style,
          date1904: wb.date1904,
          scale: scale,
          selected: selected,
          highlight: active == (mr, mc) ? 2 : (isMatch ? 1 : 0),
          onTap: () => setState(() => _selected = (mr, mc)),
        );
        if (merge == null) return TableViewCell(child: cell);
        // Merge fields are given only for the axis that actually spans.
        return TableViewCell(
          rowMergeStart: merge.rowSpan > 1 ? merge.top + 1 : null,
          rowMergeSpan: merge.rowSpan > 1 ? merge.rowSpan : null,
          columnMergeStart: merge.colSpan > 1 ? merge.left + 1 : null,
          columnMergeSpan: merge.colSpan > 1 ? merge.colSpan : null,
          child: cell,
        );
      },
    );
  }
}

class _CellView extends StatelessWidget {
  const _CellView({
    required this.value,
    required this.style,
    required this.date1904,
    required this.scale,
    required this.selected,
    required this.highlight,
    required this.onTap,
  });

  final Object? value;
  final CellStyle style;
  final bool date1904;
  final double scale;
  final bool selected;
  final int highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = NumberFormatter.format(
      value,
      style.formatCode,
      date1904: date1904,
    );
    final numeric =
        value is num && !NumberFormatter.isDateFormat(style.formatCode);
    final align = switch (style.hAlign) {
      HAlign.left => Alignment.centerLeft,
      HAlign.center => Alignment.center,
      HAlign.right => Alignment.centerRight,
      HAlign.general =>
        numeric || value is bool ? Alignment.centerRight : Alignment.centerLeft,
    };
    var fill = style.fill == null ? null : Color(style.fill!);
    if (fill != null && c.isDark && fill.computeLuminance() > 0.6)
      fill = fill.withValues(alpha: 0.18);
    var ink = style.color == null ? c.ink : Color(style.color!);
    if ((ink.computeLuminance() - (fill ?? c.surface).computeLuminance())
            .abs() <
        0.25)
      ink = c.ink;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: highlight == 2
              ? c.accent.withValues(alpha: 0.45)
              : highlight == 1
              ? c.accent.withValues(alpha: 0.18)
              : fill,
          border: selected ? Border.all(color: c.primary, width: 2) : null,
        ),
        padding: EdgeInsets.symmetric(horizontal: 4 * scale + 1),
        alignment: switch (style.vAlign) {
          VAlign.top => Alignment(align.x, -1),
          VAlign.middle => Alignment(align.x, 0),
          VAlign.bottom => Alignment(align.x, 0.6),
        },
        child: Text(
          text,
          maxLines: style.wrap ? 6 : 1,
          overflow: TextOverflow.clip,
          softWrap: style.wrap,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontFamily: Fonts.sans,
            fontSize: ((style.fontSize ?? 11) * 1.25 * scale)
                .clamp(7, 40)
                .toDouble(),
            fontWeight: style.bold ? FontWeight.w600 : FontWeight.w400,
            fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
            decoration: TextDecoration.combine([
              if (style.underline) TextDecoration.underline,
              if (style.strike) TextDecoration.lineThrough,
            ]),
            color: value is CellError ? c.danger : ink,
            fontFeatures: numeric ? const [FontFeature.tabularFigures()] : null,
          ),
        ),
      ),
    );
  }
}

/// Bottom panel with the selected cell's full value, formula and format.
class _CellPanel extends StatelessWidget {
  const _CellPanel({
    required this.workbook,
    required this.sheet,
    required this.cell,
    required this.onClose,
  });

  final Workbook workbook;
  final Sheet sheet;
  final (int, int) cell;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final (r, col) = cell;
    final value = sheet.valueAt(r, col);
    final style = workbook.styleAt(sheet.styleIdAt(r, col));
    final shown = NumberFormatter.format(
      value,
      style.formatCode,
      date1904: workbook.date1904,
    );
    final formula = sheet.formulas[Sheet.cellKey(r, col)];
    return Container(
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.x2,
        Space.x1,
        Space.x3,
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CellRef.name(r, col),
                    style: DocNookText.label.copyWith(color: c.primary),
                  ),
                  const SizedBox(height: Space.x1),
                  SelectableText(
                    shown.isEmpty ? '—' : shown,
                    style: DocNookText.body.copyWith(color: c.ink),
                  ),
                  if (formula != null) ...[
                    const SizedBox(height: Space.x2),
                    Text(
                      l.sheetFormula,
                      style: DocNookText.caption.copyWith(color: c.inkMuted),
                    ),
                    SelectableText(
                      '=$formula',
                      style: DocNookText.mono.copyWith(color: c.ink),
                    ),
                  ],
                  if (style.formatCode != 'General' && value is num) ...[
                    const SizedBox(height: Space.x2),
                    Text(
                      '${l.sheetFormat}: ${style.formatCode}',
                      style: DocNookText.caption.copyWith(color: c.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconAction(
            icon: PhosphorIconsRegular.x,
            label: l.actionClose,
            color: c.inkMuted,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _SheetTabs extends StatelessWidget {
  const _SheetTabs({
    required this.names,
    required this.selected,
    required this.onSelect,
  });

  final List<String> names;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: Sizes.touch,
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.x2),
        itemCount: names.length,
        itemBuilder: (context, i) {
          final active = i == selected;
          return Semantics(
            button: true,
            selected: active,
            child: InkWell(
              onTap: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Space.x4),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: active ? c.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  names[i],
                  style: DocNookText.label.copyWith(
                    color: active ? c.ink : c.inkMuted,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      color: c.surfaceSunken,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.screen,
        vertical: Space.x2,
      ),
      child: Text(text, style: DocNookText.caption.copyWith(color: c.ink)),
    );
  }
}

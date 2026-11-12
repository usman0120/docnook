import 'dart:async';
import 'dart:math' as math;

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/data/files/file_type_detector.dart';
import 'package:docnook/data/repositories/document_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/engines/text/highlighter.dart';
import 'package:docnook/engines/text/text_file.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/presentation/cant_open_screen.dart';
import 'package:docnook/features/viewer/presentation/viewer_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// S18 text and code viewer: monospace, optional wrap and line numbers,
/// syntax colours, streaming for large logs (FR-READ-05).
class TextViewerScreen extends ConsumerStatefulWidget {
  const TextViewerScreen({
    required this.document,
    this.extraActions = const [],
    super.key,
  });

  final OpenedDocument document;

  /// Extra overflow actions (Markdown's "Formatted" toggle).
  final List<(String, IconData, FutureOr<void> Function())> extraActions;

  @override
  ConsumerState<TextViewerScreen> createState() => _TextViewerScreenState();
}

class _TextViewerScreenState extends ConsumerState<TextViewerScreen> {
  Result<LineIndex>? _indexed;
  LineReader? _reader;
  double _progress = 0;
  bool _wrap = true;
  bool _numbers = false;
  double _fontSize = 13;
  double _sizeAtScaleStart = 13;
  final _scroll = ScrollController();
  final _horizontal = ScrollController();
  late final Syntax _syntax = syntaxFor(
    FileTypeDetector.extensionOf(widget.document.name),
  );
  late final DocumentRepository _repo = ref.read(documentRepositoryProvider);
  Timer? _saveTimer;

  bool _searching = false;
  final _searchField = TextEditingController();
  final _searchFocus = FocusNode();
  List<int> _hits = const [];
  int _active = -1;
  String _term = '';
  int _searchGeneration = 0;

  double get _lineHeight => (_fontSize * 1.55).roundToDouble();

  @override
  void initState() {
    super.initState();
    // Logs read better unwrapped; prose and code wrap by default.
    _wrap = FileTypeDetector.extensionOf(widget.document.name) != 'log';
    _scroll.addListener(_onScroll);
    unawaited(_load());
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    unawaited(_save());
    _reader?.close();
    _scroll.dispose();
    _horizontal.dispose();
    _searchField.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final job = ref
        .read(jobRunnerProvider)
        .run(
          indexLines,
          widget.document.path,
          timeout: const Duration(minutes: 3),
        );
    final sub = job.progress.listen((p) {
      if (mounted) setState(() => _progress = p.value);
    });
    final result = await job.result;
    await sub.cancel();
    if (!mounted) return;
    final prefs = await _repo.viewPrefs(widget.document.documentId);
    final saved = await _repo.position(widget.document.documentId);
    setState(() {
      _indexed = result;
      if (result case Ok(:final value))
        _reader = LineReader(widget.document.path, value);
      _wrap = (prefs['wrap'] as bool?) ?? _wrap;
      _numbers = (prefs['numbers'] as bool?) ?? _numbers;
      _fontSize = ((prefs['font'] as num?)?.toDouble() ?? _fontSize).clamp(
        9,
        28,
      );
    });
    final line = saved?.row;
    if (line != null && line > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToLine(line));
    }
  }

  void _onScroll() {
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 800),
      () => unawaited(_save()),
    );
  }

  int get _firstVisibleLine =>
      _scroll.hasClients ? (_scroll.offset / _lineHeight).floor() : 0;

  Future<void> _save() async {
    final index = _indexed?.valueOrNull;
    if (index == null) return;
    final line = _firstVisibleLine;
    await _repo.savePosition(
      widget.document.documentId,
      ReadingPosition(row: line),
      progress: index.lineCount <= 1 ? 1 : line / (index.lineCount - 1),
      viewPrefs: {'wrap': _wrap, 'numbers': _numbers, 'font': _fontSize},
    );
  }

  void _jumpToLine(int line) {
    if (!_scroll.hasClients) return;
    // Wrapped lines vary in height; the estimate lands close and the user
    // sees the highlighted hit.
    final target = math.min(
      line * _lineHeight,
      _scroll.position.maxScrollExtent,
    );
    _scroll.jumpTo(math.max(target - _lineHeight * 2, 0));
  }

  Future<void> _runSearch(String text) async {
    final term = text.trim();
    final index = _indexed?.valueOrNull;
    final generation = ++_searchGeneration;
    if (term.isEmpty || index == null) {
      setState(() {
        _term = '';
        _hits = const [];
        _active = -1;
      });
      return;
    }
    final result = await ref
        .read(jobRunnerProvider)
        .run(searchLines, LineSearch(widget.document.path, index, term))
        .result;
    if (!mounted || generation != _searchGeneration) return;
    final hits = result.valueOrNull ?? const <int>[];
    setState(() {
      _term = term;
      _hits = hits;
      _active = hits.isEmpty ? -1 : 0;
    });
    if (hits.isNotEmpty) _jumpToLine(hits.first);
  }

  void _step(int delta) {
    if (_hits.isEmpty) return;
    setState(() => _active = (_active + delta) % _hits.length);
    _jumpToLine(_hits[_active]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final doc = widget.document;
    final platform = ref.read(platformProvider);
    final indexed = _indexed;
    if (indexed case Err(:final failure)) {
      return CantOpenScreen(
        failure: failure,
        onOpenWith: () =>
            unawaited(platform.openWith(doc.request.uri, mime: 'text/plain')),
      );
    }
    final index = indexed?.valueOrNull;
    final reader = _reader;

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
                    status: _term.isEmpty
                        ? null
                        : (_hits.isEmpty
                              ? l.searchNoMatches
                              : l.searchMatches(_active + 1, _hits.length)),
                    onChanged: (t) => unawaited(_runSearch(t)),
                    onPrevious: _hits.isEmpty ? null : () => _step(-1),
                    onNext: _hits.isEmpty ? null : () => _step(1),
                    onClose: () {
                      _searchField.clear();
                      unawaited(_runSearch(''));
                      setState(() => _searching = false);
                    },
                  )
                : null,
            actions: [
              IconAction(
                icon: PhosphorIconsRegular.magnifyingGlass,
                label: l.searchInDocument,
                onPressed: index == null
                    ? null
                    : () {
                        setState(() => _searching = true);
                        _searchFocus.requestFocus();
                      },
              ),
              ViewerOverflowMenu(
                items: [
                  ...widget.extraActions,
                  (
                    _wrap ? l.textNoWrap : l.textWrap,
                    PhosphorIconsRegular.textAlignLeft,
                    () => setState(() => _wrap = !_wrap),
                  ),
                  (
                    l.textLineNumbers,
                    PhosphorIconsRegular.listNumbers,
                    () => setState(() => _numbers = !_numbers),
                  ),
                  (
                    l.docTextLarger,
                    PhosphorIconsRegular.textAa,
                    () => setState(
                      () => _fontSize = math.min(_fontSize + 1.5, 28),
                    ),
                  ),
                  (
                    l.docTextSmaller,
                    PhosphorIconsRegular.textAa,
                    () => setState(
                      () => _fontSize = math.max(_fontSize - 1.5, 9),
                    ),
                  ),
                  (
                    l.textJumpStart,
                    PhosphorIconsRegular.arrowLineUp,
                    () => _scroll.jumpTo(0),
                  ),
                  (
                    l.textJumpEnd,
                    PhosphorIconsRegular.arrowLineDown,
                    () => _scroll.jumpTo(_scroll.position.maxScrollExtent),
                  ),
                  (
                    l.actionShare,
                    PhosphorIconsRegular.shareNetwork,
                    () => platform.share([doc.path], mime: 'text/plain'),
                  ),
                  (
                    l.actionOpenWith,
                    PhosphorIconsRegular.arrowSquareOut,
                    () =>
                        platform.openWith(doc.request.uri, mime: 'text/plain'),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: index == null || reader == null
                ? LoadingState(
                    label: _progress > 0.05
                        ? '${(_progress * 100).round()}%'
                        : l.openingFile,
                  )
                : GestureDetector(
                    onScaleStart: (_) => _sizeAtScaleStart = _fontSize,
                    onScaleUpdate: (d) {
                      if (d.pointerCount < 2) return;
                      setState(
                        () => _fontSize = (_sizeAtScaleStart * d.scale).clamp(
                          9,
                          28,
                        ),
                      );
                    },
                    child: _lines(context, index, reader, c),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _lines(
    BuildContext context,
    LineIndex index,
    LineReader reader,
    DocNookColors c,
  ) {
    final style = DocNookText.mono.copyWith(
      fontSize: _fontSize,
      height: 1.55,
      color: c.ink,
    );
    final numberWidth = _numbers
        ? ('${index.lineCount}'.length * _fontSize * 0.62 + 16)
        : 0.0;
    final activeLine = _active >= 0 && _active < _hits.length
        ? _hits[_active]
        : -1;
    final hitSet = _hits.toSet();
    final palette = _Palette.of(c);

    Widget line(BuildContext context, int i) {
      final text = reader.line(i);
      final spans = _spans(
        text,
        palette,
        style,
        hitSet.contains(i),
        i == activeLine,
        c,
      );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_numbers)
            SizedBox(
              width: numberWidth,
              child: Text(
                '${i + 1}',
                textAlign: TextAlign.right,
                textScaler: TextScaler.noScaling,
                style: style.copyWith(color: c.inkMuted.withValues(alpha: 0.7)),
              ),
            ),
          if (_numbers) const SizedBox(width: Space.x3),
          if (_wrap)
            Expanded(
              child: Text.rich(
                TextSpan(children: spans),
                textScaler: TextScaler.noScaling,
              ),
            )
          else
            Text.rich(
              TextSpan(children: spans),
              softWrap: false,
              textScaler: TextScaler.noScaling,
            ),
        ],
      );
    }

    final list = ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        Space.screen,
        Space.x3,
        Space.screen,
        MediaQuery.paddingOf(context).bottom + Space.x8,
      ),
      itemCount: index.lineCount,
      itemExtent: _wrap ? null : _lineHeight,
      itemBuilder: line,
    );

    if (_wrap)
      return SelectionArea(
        child: Scrollbar(controller: _scroll, child: list),
      );
    final width =
        numberWidth +
        Space.x3 +
        index.longestLine * _fontSize * 0.62 +
        Space.screen * 2;
    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        controller: _horizontal,
        child: SingleChildScrollView(
          controller: _horizontal,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(width, constraints.maxWidth),
            child: SelectionArea(
              child: Scrollbar(controller: _scroll, child: list),
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _spans(
    String text,
    _Palette p,
    TextStyle base,
    bool hit,
    bool active,
    DocNookColors c,
  ) {
    final tokens = highlightLine(text, _syntax);
    final spans = <InlineSpan>[
      for (final t in tokens)
        TextSpan(
          text: t.text,
          style: base.copyWith(color: p.color(t.kind)),
        ),
    ];
    if (!hit || _term.isEmpty) return spans;
    // Re-split around the search term so it can be highlighted.
    final lower = text.toLowerCase();
    final term = _term.toLowerCase();
    final out = <InlineSpan>[];
    var pos = 0;
    var at = lower.indexOf(term);
    final bg = c.accent.withValues(alpha: active ? 0.6 : 0.28);
    while (at >= 0) {
      if (at > pos)
        out.add(TextSpan(text: text.substring(pos, at), style: base));
      out.add(
        TextSpan(
          text: text.substring(at, at + term.length),
          style: base.copyWith(backgroundColor: bg),
        ),
      );
      pos = at + term.length;
      at = lower.indexOf(term, pos);
    }
    if (pos < text.length)
      out.add(TextSpan(text: text.substring(pos), style: base));
    return out;
  }
}

/// Syntax colours derived from the theme tokens.
final class _Palette {
  const _Palette(
    this.ink,
    this.keyword,
    this.string,
    this.number,
    this.comment,
    this.tag,
    this.attribute,
  );

  factory _Palette.of(DocNookColors c) => c.isDark
      ? _Palette(
          c.ink,
          const Color(0xFF9CC0D3),
          const Color(0xFF8FD1A0),
          const Color(0xFFE0A84A),
          c.inkMuted,
          const Color(0xFFF2B8B5),
          const Color(0xFFC9A6E8),
        )
      : _Palette(
          c.ink,
          const Color(0xFF1F3A4D),
          const Color(0xFF2E6B3F),
          const Color(0xFF9A5B00),
          c.inkMuted,
          const Color(0xFFB3261E),
          const Color(0xFF6E4C9E),
        );

  final Color ink;
  final Color keyword;
  final Color string;
  final Color number;
  final Color comment;
  final Color tag;
  final Color attribute;

  Color color(TokenKind kind) => switch (kind) {
    TokenKind.keyword => keyword,
    TokenKind.string => string,
    TokenKind.number => number,
    TokenKind.comment => comment,
    TokenKind.tag => tag,
    TokenKind.attribute => attribute,
    TokenKind.plain || TokenKind.punctuation => ink,
  };
}

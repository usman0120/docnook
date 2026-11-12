import 'dart:async';
import 'dart:math' as math;

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/data/repositories/document_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/engines/office/parse_document.dart';
import 'package:docnook/features/search/application/indexer.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/docmodel/docmodel_view.dart';
import 'package:docnook/features/viewer/presentation/cant_open_screen.dart';
import 'package:docnook/features/viewer/presentation/viewer_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// S15 (and the shared reflow viewer for ODT, RTF, legacy .doc, Markdown):
/// a DocModel reflowed to the screen width (FR-READ-03, FR-READ-07).
class DocumentViewerScreen extends ConsumerStatefulWidget {
  const DocumentViewerScreen({
    required this.document,
    this.banner,
    this.extraActions = const [],
    super.key,
  });

  final OpenedDocument document;

  /// Extra overflow actions (Markdown's "Source" toggle).
  final List<(String, IconData, FutureOr<void> Function())> extraActions;

  /// Shown above the text, e.g. the legacy-format notice.
  final String? banner;

  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  Result<DocModel>? _parsed;
  List<Block> _blocks = const [];
  double _baseSize = 11;
  double _textScale = 1;
  double _scaleAtGestureStart = 1;
  bool _chrome = true;
  bool _bannerDismissed = false;
  int _firstVisible = 0;

  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};
  final _heights = <int, double>{};
  Timer? _saveTimer;

  // Search
  bool _searching = false;
  final _searchField = TextEditingController();
  final _searchFocus = FocusNode();
  List<BlockMatch> _matches = const [];
  int _active = -1;
  List<String>? _blockText;

  late final DocumentRepository _repo = ref.read(documentRepositoryProvider);
  late final Indexer _indexer = ref.read(indexerProvider);
  late final void Function() _endPause;
  JobHandleCancel? _job;

  int get _docId => widget.document.documentId;

  @override
  void initState() {
    super.initState();
    _endPause = _indexer.pause();
    _scroll.addListener(_onScroll);
    unawaited(_load());
  }

  @override
  void dispose() {
    _job?.call();
    _saveTimer?.cancel();
    unawaited(_save());
    _endPause();
    _scroll.dispose();
    _searchField.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final handle = ref
        .read(jobRunnerProvider)
        .run(
          parseToDocModel,
          ParseRequest(widget.document.path, widget.document.format),
          debugName: 'parse-doc',
        );
    _job = handle.cancel;
    final result = await handle.result;
    _job = null;
    if (!mounted) return;
    if (result case Ok(:final value)) {
      _blocks = value.blocks.toList();
      _baseSize = DocRenderStyle.detectBaseSize(value);
      final saved = await _repo.position(_docId);
      final prefs = await _repo.viewPrefs(_docId);
      _textScale = ((prefs['textScale'] as num?)?.toDouble() ?? 1).clamp(
        0.7,
        2.2,
      );
      _bannerDismissed = prefs['bannerSeen'] == true;
      setState(() => _parsed = result);
      final block = saved?.block;
      if (block != null && block > 0) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(_scrollToBlock(block)),
        );
      }
      unawaited(_indexIfNeeded(value));
    } else {
      setState(() => _parsed = result);
    }
  }

  Future<void> _indexIfNeeded(DocModel doc) async {
    final info = await _repo.byId(_docId);
    if (info == null || info.indexed) return;
    await ref.read(searchRepositoryProvider).store(info, docModelChunks(doc));
  }

  void _onScroll() {
    // Track the first visible block for resume and the progress bar.
    for (final entry
        in _keys.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y + box.size.height > 120) {
        if (_firstVisible != entry.key) _firstVisible = entry.key;
        break;
      }
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 800),
      () => unawaited(_save()),
    );
  }

  Future<void> _save() async {
    if (_blocks.isEmpty) return;
    await _repo.savePosition(
      _docId,
      ReadingPosition(block: _firstVisible),
      progress: _blocks.length <= 1 ? 1 : _firstVisible / (_blocks.length - 1),
      viewPrefs: {'textScale': _textScale, 'bannerSeen': _bannerDismissed},
    );
  }

  /// Brings block [index] to the top. Heights of unbuilt blocks are
  /// estimated from those already measured, then refined once built.
  Future<void> _scrollToBlock(int index) async {
    if (!_scroll.hasClients) return;
    for (var attempt = 0; attempt < 6; attempt++) {
      final key = _keys[index];
      final context = key?.currentContext;
      if (context != null) {
        await Scrollable.ensureVisible(
          context,
          duration: Duration.zero,
          alignment: 0.05,
        );
        return;
      }
      final measured = _heights.values;
      final average = measured.isEmpty
          ? 60.0
          : measured.reduce((a, b) => a + b) / measured.length;
      var offset = 0.0;
      for (var i = 0; i < index; i++) {
        offset += _heights[i] ?? average;
      }
      _scroll.jumpTo(math.min(offset, _scroll.position.maxScrollExtent));
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  // ------------------------------------------------------------ search

  void _runSearch(String text) {
    final term = text.trim().toLowerCase();
    if (term.isEmpty) {
      setState(() {
        _matches = const [];
        _active = -1;
      });
      return;
    }
    _blockText ??= [
      for (final b in _blocks) b is Paragraph ? b.plainText : _deepText(b),
    ];
    final found = <BlockMatch>[];
    for (var i = 0; i < _blockText!.length && found.length < 2000; i++) {
      final hay = _blockText![i].toLowerCase();
      var at = hay.indexOf(term);
      while (at >= 0) {
        found.add(BlockMatch(i, at, at + term.length));
        at = hay.indexOf(term, at + term.length);
      }
    }
    setState(() {
      _matches = found;
      _active = found.isEmpty ? -1 : 0;
    });
    if (found.isNotEmpty) unawaited(_scrollToBlock(found.first.block));
  }

  static String _deepText(Block b) => DocModel(
    sections: [
      DocSection(blocks: [b]),
    ],
  ).plainText();

  void _step(int delta) {
    if (_matches.isEmpty) return;
    setState(() => _active = (_active + delta) % _matches.length);
    unawaited(_scrollToBlock(_matches[_active].block));
  }

  // ------------------------------------------------------------- panels

  Future<void> _showOutline(DocModel doc) async {
    final l = AppLocalizations.of(context);
    final outline = doc.outline();
    final index = await showDocNookSheet<int>(
      context,
      title: l.pdfOutline,
      expand: outline.length > 8,
      builder: (context, scroll) {
        final c = context.colors;
        if (outline.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.x4,
              Space.screen,
              Space.x8,
            ),
            child: Text(
              l.docNoOutline,
              style: DocNookText.body.copyWith(color: c.inkMuted),
            ),
          );
        }
        return ListView.builder(
          controller: scroll,
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: Space.x8),
          itemCount: outline.length,
          itemBuilder: (context, i) {
            final e = outline[i];
            return InkWell(
              onTap: () => Navigator.of(context).pop(e.blockIndex),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Sizes.touch),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: Space.screen + (e.level - 1).clamp(0, 4) * Space.x4,
                    end: Space.screen,
                    top: Space.x2,
                    bottom: Space.x2,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      e.title,
                      style:
                          (e.level == 1
                                  ? DocNookText.bodyStrong
                                  : DocNookText.body)
                              .copyWith(
                                color: e.level == 1 ? c.ink : c.inkMuted,
                              ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (index != null) await _scrollToBlock(index);
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
    final model = parsed?.valueOrNull;

    final style = DocRenderStyle(
      ink: c.ink,
      inkMuted: c.inkMuted,
      page: c.surface,
      hairline: c.hairline,
      link: c.primary,
      highlight: c.accent.withValues(alpha: 0.30),
      activeHighlight: c.accent.withValues(alpha: 0.65),
      textScale: _textScale,
      baseFontSize: _baseSize,
    );
    final matchesByBlock = <int, List<BlockMatch>>{};
    for (final m in _matches) {
      (matchesByBlock[m.block] ??= []).add(m);
    }
    final activeMatch = _active >= 0 && _active < _matches.length
        ? _matches[_active]
        : null;
    final banner =
        widget.banner ??
        (model?.simplified == true && !_bannerDismissed
            ? l.docSimplifiedBanner
            : null);

    return Scaffold(
      backgroundColor: c.surface,
      body: Column(
        children: [
          ViewerTopBar(
            visible: _chrome || _searching,
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
                onPressed: model == null
                    ? null
                    : () {
                        setState(() => _searching = true);
                        _searchFocus.requestFocus();
                      },
              ),
              ViewerOverflowMenu(
                items: [
                  ...widget.extraActions,
                  if (model != null)
                    (
                      l.pdfOutline,
                      PhosphorIconsRegular.listBullets,
                      () => _showOutline(model),
                    ),
                  (
                    l.docTextLarger,
                    PhosphorIconsRegular.textAa,
                    () => _setScale(_textScale * 1.15),
                  ),
                  (
                    l.docTextSmaller,
                    PhosphorIconsRegular.textAa,
                    () => _setScale(_textScale / 1.15),
                  ),
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
          if (banner != null)
            _Banner(
              text: banner,
              onClose: widget.banner != null
                  ? null
                  : () {
                      setState(() => _bannerDismissed = true);
                      unawaited(_save());
                    },
            ),
          Expanded(
            child: model == null
                ? LoadingState(label: l.openingFile)
                : GestureDetector(
                    onScaleStart: (_) => _scaleAtGestureStart = _textScale,
                    onScaleUpdate: (d) {
                      if (d.pointerCount < 2) return;
                      final next = (_scaleAtGestureStart * d.scale).clamp(
                        0.7,
                        2.2,
                      );
                      if ((next - _textScale).abs() > 0.02)
                        setState(() => _textScale = next);
                    },
                    onScaleEnd: (_) => unawaited(_save()),
                    onTap: () => setState(() => _chrome = !_chrome),
                    child: SelectionArea(
                      child: Scrollbar(
                        controller: _scroll,
                        child: ListView.builder(
                          controller: _scroll,
                          padding: EdgeInsets.fromLTRB(
                            Space.x6,
                            Space.x4,
                            Space.x6,
                            MediaQuery.paddingOf(context).bottom + Space.x12,
                          ),
                          itemCount: _blocks.length,
                          itemBuilder: (context, i) {
                            final key = _keys[i] ??= GlobalKey();
                            return _Measured(
                              key: key,
                              onSize: (h) => _heights[i] = h,
                              child: DocBlockView(
                                block: _blocks[i],
                                doc: model,
                                style: style,
                                matches: matchesByBlock[i] ?? const [],
                                activeMatch: activeMatch,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _setScale(double scale) {
    setState(() => _textScale = scale.clamp(0.7, 2.2));
    unawaited(_save());
  }
}

typedef JobHandleCancel = void Function();

/// Reports its laid-out height, so scrolling to a block can estimate
/// positions of blocks not yet built.
class _Measured extends StatefulWidget {
  const _Measured({required this.onSize, required this.child, super.key});
  final ValueChanged<double> onSize;
  final Widget child;

  @override
  State<_Measured> createState() => _MeasuredState();
}

class _MeasuredState extends State<_Measured> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = context.size;
      if (mounted && size != null) widget.onSize(size.height);
    });
    return widget.child;
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.onClose});
  final String text;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.x2,
        Space.x1,
        Space.x2,
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIconsRegular.info,
            size: Sizes.iconSmall,
            color: c.inkMuted,
          ),
          const SizedBox(width: Space.x2),
          Expanded(
            child: Text(
              text,
              style: DocNookText.caption.copyWith(color: c.ink),
            ),
          ),
          if (onClose != null)
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

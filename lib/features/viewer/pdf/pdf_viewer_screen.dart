import 'dart:async';
import 'dart:math' as math;

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/data/repositories/document_repository.dart';
import 'package:docnook/data/repositories/settings_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/domain/read_aloud/read_aloud_source.dart';
import 'package:docnook/features/search/application/indexer.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:docnook/features/tools/presentation/tool_sheets.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/pdf/pdf_panels.dart';
import 'package:docnook/features/viewer/presentation/cant_open_screen.dart';
import 'package:docnook/features/viewer/presentation/password_dialog.dart';
import 'package:docnook/features/viewer/presentation/viewer_chrome.dart';
import 'package:docnook/features/viewer/read_aloud/read_aloud_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

/// Inverts page colours for night reading, then rotates hue by 180° so
/// photos and coloured charts keep roughly their own hues (FR-READ-04).
const _nightFilter = ColorFilter.matrix([
  0.574, -1.430, -0.144, 0, 255, //
  -0.426, -0.570, -0.144, 0, 255,
  -0.426, -1.430, 0.856, 0, 255,
  0, 0, 0, 1, 0,
]);

/// S12 PDF viewer (FR-READ-01 … FR-READ-04).
class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({required this.document, super.key});

  final OpenedDocument document;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen>
    with ReadAloudHost {
  final _controller = PdfViewerController();
  late final PdfTextSearcher _searcher = PdfTextSearcher(_controller)
    ..addListener(_onSearchChanged);
  final _searchField = TextEditingController();
  final _searchFocus = FocusNode();

  late final DocumentRepository _repo = ref.read(documentRepositoryProvider);
  int get _docId => widget.document.documentId;

  /// Null until the saved position has loaded.
  int? _initialPage;
  int _page = 1;
  int _pageCount = 0;
  bool _chrome = true;
  bool _searching = false;
  bool _night = false;
  PdfScrollMode _scroll = PdfScrollMode.vertical;
  int _passwordAttempts = 0;
  bool _passwordCancelled = false;
  Object? _loadError;
  Timer? _saveTimer;
  bool _starred = false;

  /// Page text for Read Aloud, by page index; offsets match the highlight.
  final _pageTexts = <int, PdfPageText>{};

  late final Indexer _indexer = ref.read(indexerProvider);
  late final void Function() _endIndexPause;

  @override
  void initState() {
    super.initState();
    _endIndexPause = _indexer.pause();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final settings = ref.read(settingsRepositoryProvider);
    final saved = await _repo.position(_docId);
    final prefs = await _repo.viewPrefs(_docId);
    final nightDefault = await settings.getBool(
      SettingsRepository.keyNightDefault,
    );
    final scrollDefault = SettingsRepository.enumOf(
      PdfScrollMode.values,
      await settings.get(SettingsRepository.keyPdfScroll),
      PdfScrollMode.vertical,
    );
    final info = await _repo.byId(_docId);
    if (!mounted) return;
    setState(() {
      _initialPage = widget.document.request.page ?? saved?.page ?? 1;
      _page = _initialPage!;
      _night = (prefs['night'] as bool?) ?? nightDefault;
      _scroll = SettingsRepository.enumOf(
        PdfScrollMode.values,
        prefs['scroll'] as String?,
        scrollDefault,
      );
      _starred = info?.starred ?? false;
    });
    final term = widget.document.request.searchTerm;
    if (term != null && term.isNotEmpty) {
      _searchField.text = term;
      _searching = true;
    }
  }

  @override
  void dispose() {
    disposeReadAloud();
    _saveTimer?.cancel();
    unawaited(_savePosition());
    unawaited(_indexAfterClose());
    _searcher
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchField.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Indexes this document from its readable copy once reading ends (the
  /// background indexer cannot read content URIs on its own).
  Future<void> _indexAfterClose() async {
    final indexer = _indexer;
    final repo = _repo;
    final path = widget.document.path;
    _endIndexPause();
    final info = await repo.byId(_docId);
    if (info == null || info.indexed || info.encrypted) return;
    await indexer.indexDocument(info, localPath: path);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _savePosition() async {
    if (_pageCount == 0) return;
    await _repo.savePosition(
      _docId,
      ReadingPosition(page: _page),
      progress: _pageCount <= 1 ? 1 : (_page - 1) / (_pageCount - 1),
      viewPrefs: {'night': _night, 'scroll': _scroll.name},
    );
  }

  void _onPageChanged(int? page) {
    if (page == null || page == _page) return;
    setState(() => _page = page);
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 800),
      () => unawaited(_savePosition()),
    );
  }

  Future<String?> _providePassword() async {
    if (!mounted) return null;
    final password = await askPassword(
      context,
      wrongBefore: _passwordAttempts > 0,
    );
    _passwordAttempts++;
    if (password == null) _passwordCancelled = true;
    return password;
  }

  void _onReady(PdfDocument document, PdfViewerController controller) {
    setState(() => _pageCount = document.pages.length);
    unawaited(
      _repo.setPageCount(
        _docId,
        document.pages.length,
        encrypted: document.isEncrypted,
      ),
    );
    unawaited(_saveThumbnail(document));
    if (_searching && _searchField.text.isNotEmpty) {
      _runSearch(_searchField.text);
    }
  }

  /// Keeps the Recents thumbnail in step with the file (BLUEPRINT 9.4).
  Future<void> _saveThumbnail(PdfDocument document) async {
    final key = 'doc$_docId-${widget.document.sizeBytes ?? 0}';
    final info = await _repo.byId(_docId);
    if (info?.thumbKey == key) return;
    final saved = await ref
        .read(thumbnailCacheProvider)
        .savePdfThumbnail(document, key);
    if (saved) await _repo.setThumbKey(_docId, key);
  }

  void _toggleChrome() {
    setState(() => _chrome = !_chrome);
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        _chrome ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
      ),
    );
  }

  void _openSearch() {
    setState(() {
      _searching = true;
      _chrome = true;
    });
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    _searcher.resetTextSearch();
    _searchField.clear();
    setState(() => _searching = false);
  }

  void _runSearch(String text) {
    final term = text.trim();
    if (term.isEmpty) {
      _searcher.resetTextSearch();
      return;
    }
    _searcher.startTextSearch(term);
  }

  // ---------------------------------------------------------- read aloud

  void _readAloud() {
    if (!_controller.isReady) return;
    unawaited(startReadAloud(_PdfSource(this), fromUnit: _page - 1));
  }

  Future<String> _pageText(int index) async {
    final cached = _pageTexts[index];
    if (cached != null) return cached.fullText;
    try {
      final text = await _controller.document.pages[index].loadStructuredText();
      _pageTexts[index] = text;
      return text.fullText;
    } on Object {
      return '';
    }
  }

  /// One rectangle per line of the sentence, in document coordinates.
  List<Rect> _sentenceRects(ReadAloudSpot spot, PdfPage page, Rect pageRect) {
    final text = _pageTexts[spot.unit];
    if (text == null) return const [];
    final rects = <Rect>[];
    final end = math.min(spot.end, text.charRects.length);
    for (var i = math.max(0, spot.start); i < end; i++) {
      final r = text.charRects[i].toRectInDocument(
        page: page,
        pageRect: pageRect,
      );
      if (r.isEmpty) continue;
      final last = rects.isEmpty ? null : rects.last;
      // Same line: grow the current rectangle.
      if (last != null &&
          (r.center.dy - last.center.dy).abs() < last.height * 0.6) {
        rects[rects.length - 1] = last.expandToInclude(r);
      } else {
        rects.add(r);
      }
    }
    return rects;
  }

  void _paintReadAloud(Canvas canvas, Rect pageRect, PdfPage page) {
    final spot = readAloudSpot;
    if (spot == null || spot.unit != page.pageNumber - 1) return;
    final paint = Paint()
      ..color = context.colors.accent.withValues(alpha: 0.35);
    for (final r in _sentenceRects(spot, page, pageRect)) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(1.5), const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  void followReadAloud(ReadAloudSpot spot) {
    if (!_controller.isReady) return;
    _controller.invalidate();
    final layouts = _controller.layout.pageLayouts;
    if (spot.unit >= layouts.length) return;
    final page = _controller.document.pages[spot.unit];
    final rects = _sentenceRects(spot, page, layouts[spot.unit]);
    if (rects.isEmpty) {
      if (_page != spot.unit + 1) unawaited(_goToPage(spot.unit + 1));
      return;
    }
    final area = rects.reduce((a, b) => a.expandToInclude(b));
    if (!_controller.visibleRect.contains(area.topLeft) ||
        !_controller.visibleRect.contains(area.bottomRight)) {
      unawaited(_controller.ensureVisible(area, margin: 48));
    }
  }

  Future<void> _goToPage(int page) async {
    if (!_controller.isReady) return;
    await _controller.goToPage(pageNumber: page.clamp(1, _pageCount));
  }

  Future<void> _askPage() async {
    final page = await askPageNumber(
      context,
      current: _page,
      total: _pageCount,
    );
    if (page != null) await _goToPage(page);
  }

  Future<void> _toggleNight() async {
    setState(() => _night = !_night);
    await _savePosition();
  }

  Future<void> _setScroll(PdfScrollMode mode) async {
    final page = _page;
    setState(() {
      _scroll = mode;
      _initialPage = page;
    });
    await _savePosition();
  }

  Future<void> _toggleStar() async {
    setState(() => _starred = !_starred);
    await _repo.setStarred(_docId, starred: _starred);
  }

  PdfPageLayout _horizontalLayout(List<PdfPage> pages, PdfViewerParams params) {
    final height = pages.fold<double>(0, (h, p) => p.height > h ? p.height : h);
    final rects = <Rect>[];
    var x = params.margin;
    for (final page in pages) {
      final scale = height / page.height;
      final w = page.width * scale;
      rects.add(Rect.fromLTWH(x, params.margin, w, height));
      x += w + params.margin;
    }
    return PdfPageLayout(
      pageLayouts: rects,
      documentSize: Size(x, height + params.margin * 2),
    );
  }

  /// Opens a PDF tool with this document (the local copy, so a file
  /// shared from another app works too).
  Future<void> _openTools(OpenedDocument doc) async {
    final router = GoRouter.of(context);
    final tool = await pickNextTool(context, includeMerge: true);
    if (tool == null) return;
    await router.push(
      '/tool/${tool.name}',
      extra: [
        ToolInput(
          uri: doc.path,
          name: doc.name,
          mime: 'application/pdf',
          size: doc.sizeBytes,
          documentId: doc.documentId,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final doc = widget.document;

    if (_passwordCancelled || _loadError != null) {
      final failure = _passwordCancelled
          ? const DocNookFailure.passwordRequired()
          : const DocNookFailure.corrupt();
      final platform = ref.read(platformProvider);
      return CantOpenScreen(
        failure: failure,
        retryLabel: _passwordCancelled ? l.passwordOpen : null,
        onRetry: _passwordCancelled
            ? () => setState(() {
                _passwordCancelled = false;
                _passwordAttempts = 0;
              })
            : null,
        onOpenWith: () => unawaited(
          platform.openWith(doc.request.uri, mime: 'application/pdf'),
        ),
      );
    }

    final initialPage = _initialPage;
    final background = _night ? const Color(0xFF0F0F0E) : c.surfaceSunken;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _night ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: background,
        body: Column(
          children: [
            ViewerTopBar(
              visible: _chrome,
              title: doc.name,
              night: _night,
              search: _searching
                  ? SearchBarContent(
                      controller: _searchField,
                      focusNode: _searchFocus,
                      hint: l.searchInDocument,
                      status: _searchStatus(l),
                      onChanged: _runSearch,
                      onPrevious: _searcher.hasMatches
                          ? () => unawaited(_searcher.goToPrevMatch())
                          : null,
                      onNext: _searcher.hasMatches
                          ? () => unawaited(_searcher.goToNextMatch())
                          : null,
                      onClose: _closeSearch,
                    )
                  : null,
              actions: [
                IconAction(
                  icon: PhosphorIconsRegular.magnifyingGlass,
                  label: l.searchInDocument,
                  color: _night ? Colors.white : null,
                  onPressed: _openSearch,
                ),
                ViewerOverflowMenu(
                  night: _night,
                  items: [
                    if (_pageCount > 0)
                      (
                        l.actionReadAloud,
                        PhosphorIconsRegular.speakerHigh,
                        _readAloud,
                      ),
                    (l.pdfGoToPage, PhosphorIconsRegular.hash, _askPage),
                    if (_scroll == PdfScrollMode.vertical)
                      (
                        l.pdfScrollHorizontal,
                        PhosphorIconsRegular.arrowsHorizontal,
                        () => _setScroll(PdfScrollMode.horizontal),
                      )
                    else
                      (
                        l.pdfScrollVertical,
                        PhosphorIconsRegular.arrowsVertical,
                        () => _setScroll(PdfScrollMode.vertical),
                      ),
                    (
                      _starred ? l.actionUnstar : l.actionStar,
                      _starred
                          ? PhosphorIconsFill.star
                          : PhosphorIconsRegular.star,
                      _toggleStar,
                    ),
                    (
                      l.actionShare,
                      PhosphorIconsRegular.shareNetwork,
                      () => ref.read(platformProvider).share([
                        doc.path,
                      ], mime: 'application/pdf'),
                    ),
                    (
                      l.actionOpenWith,
                      PhosphorIconsRegular.arrowSquareOut,
                      () => ref
                          .read(platformProvider)
                          .openWith(doc.request.uri, mime: 'application/pdf'),
                    ),
                    (
                      l.actionPdfTools,
                      PhosphorIconsRegular.wrench,
                      () => unawaited(_openTools(doc)),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: initialPage == null
                  ? const LoadingState()
                  : PdfViewer.file(
                      doc.path,
                      // Recreated when the layout mode changes so it lays out again.
                      key: ValueKey(_scroll),
                      controller: _controller,
                      initialPageNumber: initialPage,
                      passwordProvider: _providePassword,
                      params: PdfViewerParams(
                        backgroundColor: background,
                        sizeDelegateProvider:
                            const PdfViewerSizeDelegateProviderLegacy(
                              maxScale: 8,
                              minScale: 0.5,
                            ),
                        pageDropShadow: _night
                            ? null
                            : BoxShadow(
                                color: c.ink.withValues(alpha: 0.10),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                        pageImageColorFilter: _night ? _nightFilter : null,
                        layoutPages: _scroll == PdfScrollMode.horizontal
                            ? _horizontalLayout
                            : null,
                        matchTextColor: c.accent.withValues(alpha: 0.30),
                        activeMatchTextColor: c.accent.withValues(alpha: 0.60),
                        pagePaintCallbacks: [
                          _searcher.pageTextMatchPaintCallback,
                          _paintReadAloud,
                        ],
                        textSelectionParams: const PdfTextSelectionParams(),
                        onViewerReady: _onReady,
                        onPageChanged: _onPageChanged,
                        onGeneralTap: (context, controller, details) {
                          if (details.type == PdfViewerGeneralTapType.tap) {
                            if (_searching) {
                              FocusScope.of(context).unfocus();
                            } else {
                              _toggleChrome();
                            }
                            return true;
                          }
                          return false;
                        },
                        errorBannerBuilder:
                            (context, error, stackTrace, documentRef) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_passwordCancelled) {
                                  setState(() => _loadError = error);
                                }
                              });
                              return const SizedBox.shrink();
                            },
                        loadingBannerBuilder: (context, downloaded, total) =>
                            const LoadingState(),
                        viewerOverlayBuilder: (context, size, handleLinkTap) =>
                            [
                              if (_pageCount > 1)
                                PdfViewerScrollThumb(
                                  controller: _controller,
                                  orientation:
                                      _scroll == PdfScrollMode.horizontal
                                      ? ScrollbarOrientation.bottom
                                      : ScrollbarOrientation.right,
                                  thumbSize: const Size(44, 28),
                                  thumbBuilder:
                                      (
                                        context,
                                        thumbSize,
                                        pageNumber,
                                        controller,
                                      ) => PageThumbChip(
                                        label: l.pdfPageOf(
                                          pageNumber ?? _page,
                                          _pageCount,
                                        ),
                                        visible: _chrome,
                                      ),
                                ),
                            ],
                      ),
                    ),
            ),
            readAloudBar(night: _night),
            ViewerBottomBar(
              visible: _chrome && !_searching && !readAloudActive,
              night: _night,
              items: [
                (
                  l.pdfThumbnails,
                  PhosphorIconsRegular.squaresFour,
                  _pageCount == 0 ? null : _showThumbnails,
                ),
                (
                  l.pdfOutline,
                  PhosphorIconsRegular.listBullets,
                  _pageCount == 0 ? null : _showOutline,
                ),
                (
                  l.pdfBookmarks,
                  PhosphorIconsRegular.bookmarkSimple,
                  _pageCount == 0 ? null : _showBookmarks,
                ),
                (
                  _night ? l.pdfDayMode : l.pdfNightMode,
                  _night ? PhosphorIconsRegular.sun : PhosphorIconsRegular.moon,
                  _toggleNight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _searchStatus(AppLocalizations l) {
    if (_searchField.text.trim().isEmpty) return null;
    if (_searcher.hasMatches) {
      return l.searchMatches(
        (_searcher.currentIndex ?? 0) + 1,
        _searcher.matches.length,
      );
    }
    if (_searcher.isSearching) return l.searchSearching;
    return l.searchNoMatches;
  }

  Future<void> _showThumbnails() async {
    final page = await showPageThumbnails(
      context,
      document: _controller.document,
      current: _page,
    );
    if (page != null) await _goToPage(page);
  }

  Future<void> _showOutline() async {
    final outline = await _controller.document.loadOutline();
    if (!mounted) return;
    final dest = await showOutline(context, outline);
    if (dest != null) await _controller.goToDest(dest);
  }

  Future<void> _showBookmarks() async {
    final page = await showBookmarks(
      context,
      repository: _repo,
      documentId: _docId,
      currentPage: _page,
    );
    if (page != null) await _goToPage(page);
  }
}

/// Read Aloud over the pages of the open PDF.
class _PdfSource implements ReadAloudSource {
  _PdfSource(this._state);
  final _PdfViewerScreenState _state;

  @override
  int get unitCount => _state._pageCount;

  @override
  Future<String> unitText(int unit) => _state._pageText(unit);
}

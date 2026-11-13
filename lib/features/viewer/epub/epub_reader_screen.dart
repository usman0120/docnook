import 'dart:async';
import 'dart:math' as math;

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/data/repositories/document_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/engines/epub/epub_parser.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/office/parse_document.dart';
import 'package:docnook/features/search/application/indexer.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/docmodel/docmodel_view.dart';
import 'package:docnook/features/viewer/presentation/cant_open_screen.dart';
import 'package:docnook/features/viewer/presentation/viewer_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

EpubBook parseEpub(String path, JobContext context) =>
    EpubParser.parseFile(path);

enum ReadingTheme { paper, white, night }

/// S20 EPUB reader.
class EpubReaderScreen extends ConsumerStatefulWidget {
  const EpubReaderScreen({required this.document, super.key});

  final OpenedDocument document;

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen> {
  Result<EpubBook>? _book;
  int _chapter = 0;
  double _textScale = 1.1;
  double _spacing = 1.1;
  ReadingTheme _theme = ReadingTheme.paper;
  bool _chrome = true;
  final _scroll = ScrollController();
  double _chapterProgress = 0;
  Timer? _saveTimer;
  late final DocumentRepository _repo = ref.read(documentRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_load());
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    unawaited(_save());
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await ref
        .read(jobRunnerProvider)
        .run(parseEpub, widget.document.path)
        .result;
    if (!mounted) return;
    final saved = await _repo.position(widget.document.documentId);
    final prefs = await _repo.viewPrefs(widget.document.documentId);
    final book = result.valueOrNull;
    setState(() {
      _book = result;
      _textScale = ((prefs['scale'] as num?)?.toDouble() ?? _textScale).clamp(
        0.8,
        2,
      );
      _spacing = ((prefs['spacing'] as num?)?.toDouble() ?? _spacing).clamp(
        0.9,
        1.8,
      );
      _theme = ReadingTheme.values.asNameMap()[prefs['theme']] ?? _theme;
      if (book != null) {
        _chapter = (saved?.chapter ?? 0).clamp(0, book.chapters.length - 1);
      }
    });
    final offset = saved?.offset;
    if (offset != null && offset > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(offset * _scroll.position.maxScrollExtent);
        }
      });
    }
    if (book != null) unawaited(_index(book));
  }

  Future<void> _index(EpubBook book) async {
    final info = await _repo.byId(widget.document.documentId);
    if (info == null || info.indexed) return;
    await ref
        .read(searchRepositoryProvider)
        .store(info, docModelChunks(book.toDocModel()));
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final p = max <= 0 ? 1.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    if ((p - _chapterProgress).abs() > 0.01) {
      setState(() => _chapterProgress = p);
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 800),
      () => unawaited(_save()),
    );
  }

  Future<void> _save() async {
    final book = _book?.valueOrNull;
    if (book == null) return;
    final total = book.chapters.length;
    await _repo.savePosition(
      widget.document.documentId,
      ReadingPosition(chapter: _chapter, offset: _chapterProgress),
      progress: ((_chapter + _chapterProgress) / total).clamp(0, 1),
      viewPrefs: {
        'scale': _textScale,
        'spacing': _spacing,
        'theme': _theme.name,
      },
    );
  }

  void _goChapter(int i, {bool toEnd = false}) {
    final book = _book?.valueOrNull;
    if (book == null || i < 0 || i >= book.chapters.length) return;
    setState(() {
      _chapter = i;
      _chapterProgress = toEnd ? 1 : 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(toEnd ? _scroll.position.maxScrollExtent : 0);
      }
    });
    unawaited(_save());
  }

  /// Page forward/back by a screenful; at the chapter edge, move chapters.
  void _page(int direction) {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final step = pos.viewportDimension * 0.9;
    if (direction > 0 && pos.pixels >= pos.maxScrollExtent - 2) {
      _goChapter(_chapter + 1);
    } else if (direction < 0 && pos.pixels <= 2) {
      _goChapter(_chapter - 1, toEnd: true);
    } else {
      _scroll.animateTo(
        (pos.pixels + direction * step).clamp(0, pos.maxScrollExtent),
        duration: Motion.of(context, Motion.fast),
        curve: Motion.curve,
      );
    }
  }

  static (Color, Color, Color) _colorsFor(ReadingTheme theme) =>
      switch (theme) {
        ReadingTheme.paper => (
          const Color(0xFFF7F3E8),
          const Color(0xFF2B2722),
          const Color(0xFF6E665A),
        ),
        ReadingTheme.white => (
          const Color(0xFFFFFFFF),
          const Color(0xFF1C1B19),
          const Color(0xFF5F5B53),
        ),
        ReadingTheme.night => (
          const Color(0xFF141413),
          const Color(0xFFD9D5CC),
          const Color(0xFF9A958B),
        ),
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final platform = ref.read(platformProvider);
    final result = _book;
    if (result case Err(:final failure)) {
      return CantOpenScreen(
        failure: failure,
        onOpenWith: () => unawaited(
          platform.openWith(
            widget.document.request.uri,
            mime: DocFormat.epub.mime,
          ),
        ),
      );
    }
    final book = result?.valueOrNull;
    final (page, ink, muted) = _colorsFor(_theme);
    final night = _theme == ReadingTheme.night;
    final style = DocRenderStyle(
      ink: ink,
      inkMuted: muted,
      page: page,
      hairline: muted.withValues(alpha: 0.3),
      link: night ? const Color(0xFF9CC0D3) : const Color(0xFF1F3A4D),
      highlight: c.accent.withValues(alpha: 0.3),
      activeHighlight: c.accent,
      textScale: _textScale,
      lineSpacing: _spacing,
    );
    final chapter = book?.chapters[_chapter];
    final model = book == null
        ? null
        : DocModel(sections: const [], images: book.images);

    return Scaffold(
      backgroundColor: page,
      body: Column(
        children: [
          ViewerTopBar(
            visible: _chrome,
            night: night,
            title: book?.title ?? widget.document.name,
            actions: [
              IconAction(
                icon: PhosphorIconsRegular.listBullets,
                label: l.epubChapters,
                color: night ? Colors.white : null,
                onPressed: book == null
                    ? null
                    : () => unawaited(_showChapters(book)),
              ),
              IconAction(
                icon: PhosphorIconsRegular.textAa,
                label: l.epubTheme,
                color: night ? Colors.white : null,
                onPressed: book == null
                    ? null
                    : () => unawaited(_showSettings()),
              ),
              ViewerOverflowMenu(
                night: night,
                items: [
                  (
                    l.actionShare,
                    PhosphorIconsRegular.shareNetwork,
                    () => platform.share([
                      widget.document.path,
                    ], mime: DocFormat.epub.mime),
                  ),
                  (
                    l.actionOpenWith,
                    PhosphorIconsRegular.arrowSquareOut,
                    () => platform.openWith(
                      widget.document.request.uri,
                      mime: DocFormat.epub.mime,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: book == null || chapter == null || model == null
                ? LoadingState(label: l.openingFile)
                : LayoutBuilder(
                    builder: (context, constraints) => GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (d) {
                        final x = d.localPosition.dx / constraints.maxWidth;
                        if (x < 0.28) {
                          _page(-1);
                        } else if (x > 0.72) {
                          _page(1);
                        } else {
                          setState(() => _chrome = !_chrome);
                        }
                      },
                      child: Center(
                        child: ConstrainedBox(
                          // Comfortable line length on wide screens.
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: SelectionArea(
                            child: ListView.builder(
                              key: ValueKey(_chapter),
                              controller: _scroll,
                              padding: EdgeInsets.fromLTRB(
                                Space.x6,
                                Space.x6,
                                Space.x6,
                                MediaQuery.paddingOf(context).bottom +
                                    Space.x12,
                              ),
                              itemCount: chapter.blocks.length + 1,
                              itemBuilder: (context, i) {
                                if (i == chapter.blocks.length) {
                                  return _chapterEnd(book, l, muted);
                                }
                                return DocBlockView(
                                  block: chapter.blocks[i],
                                  doc: model,
                                  style: style,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          if (book != null)
            AnimatedOpacity(
              duration: Motion.of(context, Motion.fast),
              opacity: _chrome ? 1 : 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Space.screen,
                  Space.x2,
                  Space.screen,
                  MediaQuery.paddingOf(context).bottom + Space.x2,
                ),
                child: Column(
                  children: [
                    ThinProgress(
                      (_chapter + _chapterProgress) / book.chapters.length,
                    ),
                    const SizedBox(height: Space.x1),
                    Text(
                      l.epubChapterProgress(_chapter + 1, book.chapters.length),
                      style: DocNookText.caption.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chapterEnd(EpubBook book, AppLocalizations l, Color muted) {
    if (_chapter >= book.chapters.length - 1) {
      return const SizedBox(height: Space.x8);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x8),
      child: Center(
        child: QuietButton(
          label: '${l.epubNext}: ${book.chapters[_chapter + 1].title}',
          onPressed: () => _goChapter(_chapter + 1),
          color: muted,
        ),
      ),
    );
  }

  Future<void> _showChapters(EpubBook book) async {
    final l = AppLocalizations.of(context);
    final chosen = await showDocNookSheet<int>(
      context,
      title: l.epubChapters,
      expand: book.chapters.length > 8,
      builder: (context, scroll) {
        final c = context.colors;
        return ListView.builder(
          controller: scroll,
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: Space.x8),
          itemCount: book.chapters.length,
          itemBuilder: (context, i) => ListTile(
            selected: i == _chapter,
            selectedColor: c.primary,
            title: Text(book.chapters[i].title),
            onTap: () => Navigator.of(context).pop(i),
          ),
        );
      },
    );
    if (chosen != null) _goChapter(chosen);
  }

  Future<void> _showSettings() async {
    final l = AppLocalizations.of(context);
    await showDocNookSheet<void>(
      context,
      title: l.epubTheme,
      builder: (context, _) => StatefulBuilder(
        builder: (context, setSheet) {
          final c = context.colors;
          void update(VoidCallback change) {
            setState(change);
            setSheet(() {});
            unawaited(_save());
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              0,
              Space.screen,
              Space.x6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (final t in ReadingTheme.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.x1,
                          ),
                          child: _ThemeChip(
                            label: switch (t) {
                              ReadingTheme.paper => l.epubThemePaper,
                              ReadingTheme.white => l.epubThemeWhite,
                              ReadingTheme.night => l.epubThemeNight,
                            },
                            colors: _colorsFor(t),
                            selected: _theme == t,
                            onTap: () => update(() => _theme = t),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Space.x4),
                Text(
                  l.docTextLarger,
                  style: DocNookText.label.copyWith(color: c.inkMuted),
                ),
                Slider(
                  value: _textScale,
                  min: 0.8,
                  max: 2,
                  divisions: 12,
                  label: '${(_textScale * 100).round()}%',
                  onChanged: (v) => update(() => _textScale = v),
                ),
                Text(
                  l.epubLineSpacing,
                  style: DocNookText.label.copyWith(color: c.inkMuted),
                ),
                Slider(
                  value: _spacing,
                  min: 0.9,
                  max: 1.8,
                  divisions: 9,
                  label: _spacing.toStringAsFixed(1),
                  onChanged: (v) => update(() => _spacing = math.max(0.9, v)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final (Color, Color, Color) colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, ink, _) = colors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.cardAll,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: Radii.cardAll,
            border: Border.all(
              color: selected ? c.primary : c.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(label, style: DocNookText.label.copyWith(color: ink)),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/data/repositories/document_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/choice.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/office/parse_document.dart';
import 'package:docnook/engines/office/pptx/pptx_parser.dart';
import 'package:docnook/features/search/application/indexer.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/docmodel/docmodel_view.dart';
import 'package:docnook/features/viewer/presentation/cant_open_screen.dart';
import 'package:docnook/features/viewer/presentation/viewer_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

DocModel parsePptx(String path, JobContext context) =>
    PptxParser.parseFile(path);

enum _Mode { slides, outline }

/// S17 slides viewer (Basic fidelity, clearly labelled).
class SlidesViewerScreen extends ConsumerStatefulWidget {
  const SlidesViewerScreen({required this.document, super.key});

  final OpenedDocument document;

  @override
  ConsumerState<SlidesViewerScreen> createState() => _SlidesViewerScreenState();
}

class _SlidesViewerScreenState extends ConsumerState<SlidesViewerScreen> {
  Result<DocModel>? _parsed;
  List<SlideFrame> _slides = const [];
  int _index = 0;
  _Mode _mode = _Mode.slides;
  bool _showNotes = false;
  PageController? _pages;
  final _strip = ScrollController();
  late final DocumentRepository _repo = ref.read(documentRepositoryProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_save());
    _pages?.dispose();
    _strip.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await ref
        .read(jobRunnerProvider)
        .run(parsePptx, widget.document.path)
        .result;
    if (!mounted) return;
    final saved = await _repo.position(widget.document.documentId);
    final model = result.valueOrNull;
    if (model != null) {
      _slides = model.blocks.whereType<SlideFrame>().toList();
      _index = (saved?.page ?? 0).clamp(0, _slides.length - 1);
      _pages = PageController(initialPage: _index);
      unawaited(_indexText(model));
    }
    setState(() => _parsed = result);
  }

  Future<void> _indexText(DocModel model) async {
    final info = await _repo.byId(widget.document.documentId);
    if (info == null || info.indexed) return;
    await ref.read(searchRepositoryProvider).store(info, docModelChunks(model));
  }

  Future<void> _save() async {
    if (_slides.isEmpty) return;
    await _repo.savePosition(
      widget.document.documentId,
      ReadingPosition(page: _index),
      progress: _slides.length <= 1 ? 1 : _index / (_slides.length - 1),
    );
  }

  void _go(int i) {
    final target = i.clamp(0, _slides.length - 1);
    if (_mode == _Mode.outline) setState(() => _mode = _Mode.slides);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pages?.animateToPage(
        target,
        duration: Motion.of(context),
        curve: Motion.curve,
      );
    });
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
          platform.openWith(doc.request.uri, mime: DocFormat.pptx.mime),
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
      highlight: c.accent.withValues(alpha: 0.3),
      activeHighlight: c.accent,
    );

    return Scaffold(
      backgroundColor: c.surfaceSunken,
      body: Column(
        children: [
          ViewerTopBar(
            visible: true,
            title: doc.name,
            actions: [
              if (_slides.any((s) => s.notes != null))
                IconAction(
                  icon: PhosphorIconsRegular.note,
                  label: l.slidesNotes,
                  selected: _showNotes,
                  color: _showNotes ? c.primary : null,
                  onPressed: () => setState(() => _showNotes = !_showNotes),
                ),
              ViewerOverflowMenu(
                items: [
                  (
                    l.actionShare,
                    PhosphorIconsRegular.shareNetwork,
                    () => platform.share([doc.path], mime: DocFormat.pptx.mime),
                  ),
                  (
                    l.actionOpenWith,
                    PhosphorIconsRegular.arrowSquareOut,
                    () => platform.openWith(
                      doc.request.uri,
                      mime: DocFormat.pptx.mime,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (model != null)
            Container(
              color: c.paper,
              padding: const EdgeInsets.only(top: Space.x2, bottom: Space.x2),
              child: SegmentedChoice<_Mode>(
                values: _Mode.values,
                selected: _mode,
                label: (m) =>
                    m == _Mode.slides ? l.slidesSlides : l.slidesOutline,
                onSelected: (m) => setState(() => _mode = m),
              ),
            ),
          if (model != null && _mode == _Mode.slides)
            Container(
              width: double.infinity,
              color: c.paper,
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                0,
                Space.screen,
                Space.x2,
              ),
              child: Text(
                l.slidesBanner,
                textAlign: TextAlign.center,
                style: DocNookText.caption.copyWith(color: c.inkMuted),
              ),
            ),
          Expanded(
            child: model == null
                ? LoadingState(label: l.openingFile)
                : _mode == _Mode.outline
                ? _outline(model, l, c)
                : Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pages,
                          itemCount: _slides.length,
                          onPageChanged: (i) {
                            setState(() => _index = i);
                            unawaited(_save());
                            _scrollStrip(i);
                          },
                          itemBuilder: (context, i) => Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(Space.x4),
                              child: InteractiveViewer(
                                maxScale: 4,
                                child: SlideView(
                                  slide: _slides[i],
                                  doc: model,
                                  style: style,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_showNotes && _slides[_index].notes != null)
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 160),
                          color: c.paper,
                          padding: const EdgeInsets.all(Space.screen),
                          child: SingleChildScrollView(
                            child: Text(
                              _slides[_index].notes!,
                              style: DocNookText.body.copyWith(color: c.ink),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.x2),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            l.slideOf(_index + 1, _slides.length),
                            style: DocNookText.label.copyWith(
                              color: c.inkMuted,
                            ),
                          ),
                        ),
                      ),
                      _thumbnails(model, style, c),
                    ],
                  ),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }

  void _scrollStrip(int i) {
    if (!_strip.hasClients) return;
    final target = (i * 96.0 - 120).clamp(0.0, _strip.position.maxScrollExtent);
    _strip.animateTo(
      target,
      duration: Motion.of(context, Motion.fast),
      curve: Motion.curve,
    );
  }

  Widget _thumbnails(DocModel model, DocRenderStyle style, DocNookColors c) =>
      Container(
        height: 76,
        color: c.paper,
        child: ListView.builder(
          controller: _strip,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.x2,
            vertical: Space.x2,
          ),
          itemCount: _slides.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x1),
            child: GestureDetector(
              onTap: () => _go(i),
              child: Container(
                width: 84,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: i == _index ? c.primary : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: IgnorePointer(
                  child: SlideView(slide: _slides[i], doc: model, style: style),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _outline(
    DocModel model,
    AppLocalizations l,
    DocNookColors c,
  ) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(
      Space.screen,
      Space.x2,
      Space.screen,
      Space.x8,
    ),
    itemCount: _slides.length,
    separatorBuilder: (_, _) => Divider(color: c.hairline),
    itemBuilder: (context, i) {
      final slide = _slides[i];
      final texts = slide.items.whereType<SlideText>().where((t) => !t.isTitle);
      return InkWell(
        onTap: () => _go(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${i + 1}. ${slide.title?.isNotEmpty == true ? slide.title : ''}',
                style: DocNookText.bodyStrong.copyWith(color: c.ink),
              ),
              for (final t in texts)
                for (final p in t.paragraphs)
                  if (!p.isEmpty)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: Space.x4 + (p.list?.level ?? 0) * Space.x4,
                        top: 2,
                      ),
                      child: Text(
                        '${p.list != null ? '${p.list!.marker} ' : ''}${p.plainText}',
                        style: DocNookText.body.copyWith(color: c.inkMuted),
                      ),
                    ),
            ],
          ),
        ),
      );
    },
  );
}

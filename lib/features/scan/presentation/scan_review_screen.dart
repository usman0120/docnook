import 'dart:async';
import 'dart:io';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:docnook/features/scan/application/scan_service.dart';
import 'package:docnook/features/scan/presentation/crop_screen.dart';
import 'package:docnook/features/scan/presentation/scan_launcher.dart';
import 'package:docnook/features/viewer/presentation/viewer_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// S24 Review and edit: page pager, filmstrip, and per-page tools.
class ScanReviewScreen extends ConsumerStatefulWidget {
  const ScanReviewScreen({required this.sessionId, super.key});

  final int sessionId;

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  final _pager = PageController();
  int _index = 0;
  int _lastCount = 0;

  /// Set when the user taps Add page, so the pager follows the new pages.
  /// Pages that arrive with a fresh scan don't move it off page 1.
  bool _followNew = false;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  ScanService get _service => ref.read(scanServiceProvider);

  void _goTo(int index) {
    setState(() => _index = index);
    if (_pager.hasClients) {
      _pager.animateToPage(
        index,
        duration: Motion.standard,
        curve: Motion.curve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final async = ref.watch(scanSessionProvider(widget.sessionId));
    final session = async.value;

    if (session == null) {
      return Scaffold(
        backgroundColor: c.paper,
        body: Column(
          children: [
            ViewerTopBar(
              visible: true,
              title: l.toolScanDoc,
              actions: const [],
            ),
            Expanded(
              child: switch (async) {
                AsyncError() => ErrorState(
                  title: l.scanLoadErrorTitle,
                  body: l.scanLoadErrorBody,
                  actionLabel: l.actionBack,
                  onAction: () => context.go('/home'),
                ),
                AsyncData() => EmptyState(
                  art: EmptyArt.scannerFrame,
                  title: l.scanGoneTitle,
                  primaryLabel: l.actionBack,
                  onPrimary: () => context.go('/home'),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      );
    }

    final pages = session.pages;
    // Jump to a page that was just added.
    if (_followNew && pages.length > _lastCount && _lastCount > 0) {
      final target = pages.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goTo(target);
      });
    }
    _lastCount = pages.length;
    final index = pages.isEmpty ? 0 : _index.clamp(0, pages.length - 1);
    final page = pages.isEmpty ? null : pages[index];

    return Scaffold(
      backgroundColor: c.surfaceSunken,
      body: Column(
        children: [
          ViewerTopBar(
            visible: true,
            title: session.title,
            actions: [
              IconAction(
                icon: PhosphorIconsRegular.trash,
                label: l.scanDiscard,
                onPressed: () => unawaited(_discard(session)),
              ),
              QuietButton(
                label: l.actionNext,
                onPressed: pages.isEmpty
                    ? null
                    : () => context.push('/scan/${session.id}/export'),
              ),
            ],
          ),
          Expanded(
            child: pages.isEmpty
                ? EmptyState(
                    art: EmptyArt.scannerFrame,
                    title: l.scanNoPagesTitle,
                    primaryLabel: l.scanAddPage,
                    onPrimary: () => unawaited(_add(session)),
                  )
                : PageView.builder(
                    controller: _pager,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _PagePreview(
                      page: pages[i],
                      book: session.mode == ScanMode.book,
                      onSplit: (split) => unawaited(
                        ref
                            .read(scanRepositoryProvider)
                            .updatePage(
                              pages[i],
                              geometry: pages[i].geometry.copyWith(
                                split: split,
                              ),
                            ),
                      ),
                    ),
                  ),
          ),
          if (pages.isNotEmpty) ...[
            _Filmstrip(
              pages: pages,
              selected: index,
              onSelect: _goTo,
              onAdd: () => unawaited(_add(session)),
              onReorder: (ids) => unawaited(_service.reorder(session.id, ids)),
            ),
            ViewerBottomBar(
              visible: true,
              items: [
                (
                  l.scanCrop,
                  PhosphorIconsRegular.crop,
                  () => unawaited(_crop(session, page!)),
                ),
                (
                  l.scanRotate,
                  PhosphorIconsRegular.arrowClockwise,
                  () => unawaited(_service.rotate(session.id, page!)),
                ),
                (
                  l.scanFilter,
                  PhosphorIconsRegular.slidersHorizontal,
                  () => unawaited(_filter(session, page!)),
                ),
                (
                  l.scanRetake,
                  PhosphorIconsRegular.camera,
                  () => unawaited(retakePage(context, ref, session, page!)),
                ),
                (
                  l.actionDelete,
                  PhosphorIconsRegular.trash,
                  () => unawaited(_delete(page!)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _add(ScanSession session) async {
    _followNew = true;
    await addPages(context, ref, session);
  }

  Future<void> _crop(ScanSession session, ScanPage page) async {
    final geometry = await Navigator.of(context).push<PageGeometry>(
      MaterialPageRoute(builder: (_) => CropScreen(page: page)),
    );
    if (geometry == null) return;
    await _service.setGeometry(session.id, page, geometry);
  }

  Future<void> _filter(ScanSession session, ScanPage page) async {
    final l = AppLocalizations.of(context);
    var all = false;
    final picked = await showDocNookSheet<ScanFilter>(
      context,
      title: l.scanFilter,
      builder: (context, _) => StatefulBuilder(
        builder: (context, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in ScanFilter.values)
              _SheetChoice(
                label: _filterLabel(l, f),
                selected: f == page.filter,
                onTap: () => Navigator.of(context).pop(f),
              ),
            SwitchListTile(
              value: all,
              title: Text(l.scanApplyToAll, style: DocNookText.body),
              onChanged: (v) => setSheet(() => all = v),
            ),
            const SizedBox(height: Space.x2),
          ],
        ),
      ),
    );
    if (picked == null) return;
    if (all) {
      await _service.setFilterForAll(session, picked);
    } else if (picked != page.filter) {
      await _service.setFilter(session.id, page, picked);
    }
  }

  Future<void> _delete(ScanPage page) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.scanDeletePageTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );
    if (ok ?? false) await _service.deletePage(page);
  }

  Future<void> _discard(ScanSession session) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.scanDiscardTitle),
        content: Text(l.scanDiscardBody(session.pages.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.scanDiscard),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    await _service.discard(session.id);
    if (mounted) context.go('/home');
  }
}

String _filterLabel(AppLocalizations l, ScanFilter f) => switch (f) {
  ScanFilter.original => l.scanFilterOriginal,
  ScanFilter.document => l.scanFilterDocument,
  ScanFilter.grayscale => l.scanFilterGrayscale,
  ScanFilter.enhanced => l.scanFilterEnhanced,
};

class _SheetChoice extends StatelessWidget {
  const _SheetChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.screen,
            vertical: Space.x3,
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: DocNookText.body)),
              if (selected)
                Icon(
                  PhosphorIconsRegular.check,
                  size: Sizes.icon,
                  color: c.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One page, centred on the work surface. In Book mode a vertical line
/// shows where the spread is split; drag it to adjust.
class _PagePreview extends ConsumerWidget {
  const _PagePreview({
    required this.page,
    required this.book,
    required this.onSplit,
  });

  final ScanPage page;
  final bool book;
  final ValueChanged<double> onSplit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final busy = ref.watch(renderingPagesProvider).contains(page.id);
    final path = page.processedPath;
    return Padding(
      padding: const EdgeInsets.all(Space.x4),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (path == null)
              const SizedBox.shrink()
            else
              _AspectImage(
                path: path,
                semanticLabel: l.scanPageLabel(page.position + 1),
                builder: (image) => DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: c.hairline),
                  ),
                  child: book
                      ? _SplitOverlay(
                          split: page.geometry.split ?? 0.5,
                          onChanged: onSplit,
                          child: image,
                        )
                      : image,
                ),
              ),
            if (busy || path == null)
              const SizedBox.square(
                dimension: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
          ],
        ),
      ),
    );
  }
}

/// Loads a file image and lays it out at its own aspect ratio, so overlays
/// can be positioned on the picture itself.
class _AspectImage extends StatefulWidget {
  const _AspectImage({
    required this.path,
    required this.builder,
    this.semanticLabel,
  });

  final String path;
  final Widget Function(Widget image) builder;
  final String? semanticLabel;

  @override
  State<_AspectImage> createState() => _AspectImageState();
}

class _AspectImageState extends State<_AspectImage> {
  double? _aspect;
  ImageStream? _stream;
  late ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _aspect = info.image.width / info.image.height);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_AspectImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _resolve();
  }

  void _resolve() {
    final stream = FileImage(
      File(widget.path),
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _aspect;
    if (aspect == null) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: aspect,
      child: widget.builder(
        Image.file(
          File(widget.path),
          fit: BoxFit.fill,
          gaplessPlayback: true,
          semanticLabel: widget.semanticLabel,
        ),
      ),
    );
  }
}

class _SplitOverlay extends StatefulWidget {
  const _SplitOverlay({
    required this.split,
    required this.onChanged,
    required this.child,
  });

  final double split;

  /// Called once, when the drag ends.
  final ValueChanged<double> onChanged;
  final Widget child;

  @override
  State<_SplitOverlay> createState() => _SplitOverlayState();
}

class _SplitOverlayState extends State<_SplitOverlay> {
  /// Where the line is while dragging, and until the saved value arrives.
  double? _dragging;
  bool _active = false;

  @override
  void didUpdateWidget(_SplitOverlay old) {
    super.didUpdateWidget(old);
    if (old.split != widget.split) _dragging = null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final split = _dragging ?? widget.split;
    return LayoutBuilder(
      builder: (context, box) {
        final x = split * box.maxWidth;
        return Stack(
          children: [
            Positioned.fill(child: widget.child),
            Positioned(
              left: x - Sizes.touch / 2,
              top: 0,
              bottom: 0,
              width: Sizes.touch,
              child: Semantics(
                label: l.scanSplitLine,
                slider: true,
                value: '${(split * 100).round()}%',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (d) => setState(() {
                    _active = true;
                    _dragging = ((x + d.delta.dx) / box.maxWidth).clamp(
                      0.2,
                      0.8,
                    );
                  }),
                  onHorizontalDragEnd: (_) {
                    final value = _dragging;
                    if (value != null) widget.onChanged(value);
                    setState(() => _active = false);
                  },
                  child: Center(
                    child: Container(width: _active ? 3 : 2, color: c.accent),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Thumbnails of all pages. Tap to show, long-press and drag to reorder.
class _Filmstrip extends StatelessWidget {
  const _Filmstrip({
    required this.pages,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
    required this.onReorder,
  });

  final List<ScanPage> pages;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<List<int>> onReorder;

  static const _thumbWidth = 52.0;
  static const _thumbHeight = 68.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Container(
      height: _thumbHeight + Space.x4 * 2,
      color: c.paper,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.screen - Space.x1,
          vertical: Space.x4,
        ),
        itemCount: pages.length,
        onReorderItem: (from, to) {
          final ids = [for (final p in pages) p.id];
          final moved = ids.removeAt(from);
          ids.insert(to, moved);
          onReorder(ids);
        },
        footer: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x1),
          child: Semantics(
            button: true,
            label: l.scanAddPage,
            child: InkWell(
              onTap: onAdd,
              borderRadius: Radii.chipAll,
              child: Container(
                width: _thumbWidth,
                height: _thumbHeight,
                decoration: BoxDecoration(
                  borderRadius: Radii.chipAll,
                  border: Border.all(color: c.hairline),
                ),
                child: Icon(
                  PhosphorIconsRegular.plus,
                  size: Sizes.icon,
                  color: c.inkMuted,
                ),
              ),
            ),
          ),
        ),
        itemBuilder: (context, i) {
          final page = pages[i];
          final path = page.processedPath;
          final active = i == selected;
          return Padding(
            key: ValueKey(page.id),
            padding: const EdgeInsets.symmetric(horizontal: Space.x1),
            child: Semantics(
              button: true,
              selected: active,
              label: l.scanPageLabel(i + 1),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  width: _thumbWidth,
                  height: _thumbHeight,
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(
                      color: active ? c.primary : c.hairline,
                      width: active ? 2 : Sizes.hairline,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (path != null)
                        Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          cacheWidth: 160,
                          gaplessPlayback: true,
                        ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.x1,
                          ),
                          color: c.ink.withValues(alpha: 0.72),
                          child: Text(
                            '${i + 1}',
                            style: DocNookText.caption.copyWith(color: c.paper),
                          ),
                        ),
                      ),
                    ],
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

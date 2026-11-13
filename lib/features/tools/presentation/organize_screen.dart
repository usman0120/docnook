import 'dart:async';
import 'dart:io';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/features/tools/application/pdf_tools_service.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:docnook/features/tools/presentation/tool_flow_screen.dart';
import 'package:docnook/features/tools/presentation/tool_scaffold.dart';
import 'package:docnook/features/tools/presentation/tool_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

/// One tile of the grid: a page of the original, a blank page or an
/// inserted picture, with a stable key for drag and drop.
final class _Tile {
  _Tile(this.spec, {this.image}) : key = UniqueKey();
  final PageSpec spec;

  /// For inserted pictures: the picture (source 1, page = its index).
  final ToolInput? image;
  final Key key;

  _Tile turned(int turns) => _Tile(spec.turned(turns), image: image);
  _Tile copy() => _Tile(spec, image: image);
}

/// S13 Organize pages.
class OrganizeScreen extends ConsumerStatefulWidget {
  const OrganizeScreen({required this.input, super.key});

  final PreparedInput input;

  @override
  ConsumerState<OrganizeScreen> createState() => _OrganizeScreenState();
}

class _OrganizeScreenState extends ConsumerState<OrganizeScreen> {
  late List<_Tile> _tiles = [
    for (var i = 0; i < widget.input.info!.pageCount; i++)
      _Tile(PageSpec.page(0, i)),
  ];
  final _selected = <Key>{};
  final _images = <ToolInput>[];
  final _history = <List<_Tile>>[];
  PdfDocumentRef? _doc;

  PdfInfo get _info => widget.input.info!;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  Future<void> _resolve() async {
    final path = await ref
        .read(pdfToolsServiceProvider)
        .localPath(widget.input.input);
    if (!mounted) return;
    final password = widget.input.password;
    setState(() {
      // Created once: a new reference per rebuild reloads the document.
      _doc = PdfDocumentRefFile(
        path,
        passwordProvider: password == null ? null : () => password,
      );
    });
  }

  bool get _changed => _history.isNotEmpty;

  void _edit(List<_Tile> next) => setState(() {
    _history.add(_tiles);
    _tiles = next;
  });

  void _undo() => setState(() {
    if (_history.isNotEmpty) _tiles = _history.removeLast();
    _selected.clear();
  });

  List<_Tile> get _targets {
    final picked = _tiles.where((t) => _selected.contains(t.key)).toList();
    return picked.isEmpty ? _tiles : picked;
  }

  void _rotate() {
    final keys = {for (final t in _targets) t.key};
    final next = <_Tile>[];
    final keep = <Key>{};
    for (final t in _tiles) {
      if (keys.contains(t.key)) {
        final r = t.turned(1);
        next.add(r);
        if (_selected.contains(t.key)) keep.add(r.key);
      } else {
        next.add(t);
      }
    }
    _edit(next);
    _selected
      ..clear()
      ..addAll(keep);
  }

  void _delete() {
    if (_selected.isEmpty) return;
    final next = _tiles.where((t) => !_selected.contains(t.key)).toList();
    if (next.isEmpty) {
      _snack(AppLocalizations.of(context).organizeKeepOne);
      return;
    }
    _edit(next);
    _selected.clear();
  }

  void _duplicate() {
    if (_selected.isEmpty) return;
    final next = <_Tile>[];
    for (final t in _tiles) {
      next.add(t);
      if (_selected.contains(t.key)) next.add(t.copy());
    }
    _edit(next);
    _selected.clear();
  }

  int get _insertAt {
    var at = -1;
    for (var i = 0; i < _tiles.length; i++) {
      if (_selected.contains(_tiles[i].key)) at = i;
    }
    return at < 0 ? _tiles.length : at + 1;
  }

  Future<void> _insert() async {
    final l = AppLocalizations.of(context);
    final choice = await showDocNookSheet<String>(
      context,
      title: l.organizeInsert,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(PhosphorIconsRegular.file, size: Sizes.icon),
            title: Text(l.organizeInsertBlank, style: DocNookText.body),
            onTap: () => Navigator.of(context).pop('blank'),
          ),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.image, size: Sizes.icon),
            title: Text(l.organizeInsertImage, style: DocNookText.body),
            onTap: () => Navigator.of(context).pop('image'),
          ),
          const SizedBox(height: Space.x2),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    final at = _insertAt;
    if (choice == 'blank') {
      // Same size as the page before it, so the document stays even.
      final before = at > 0 ? _tiles[at - 1].spec : null;
      final ref0 = before == null || before.isBlank || before.source != 0
          ? _info.pages.first
          : _info.pages[before.index];
      final next = [..._tiles]
        ..insert(
          at,
          _Tile(
            PageSpec.blank(
              width: ref0.visibleWidth,
              height: ref0.visibleHeight,
            ),
          ),
        );
      _edit(next);
      return;
    }
    final files = await ref
        .read(platformProvider)
        .pickFiles(mimes: const ['image/*'], multiple: true);
    if (files.isEmpty || !mounted) return;
    final next = [..._tiles];
    var k = at;
    for (final f in files) {
      final input = ToolInput(
        uri: f.uri,
        name: f.name ?? 'image',
        mime: f.mime,
        size: f.size,
      );
      _images.add(input);
      next.insert(
        k++,
        _Tile(PageSpec.page(1, _images.length - 1), image: input),
      );
    }
    _edit(next);
  }

  Future<void> _extract() async {
    if (_selected.isEmpty) return;
    final pages = [
      for (final t in _tiles)
        if (_selected.contains(t.key) && !t.spec.isBlank && t.spec.source == 0)
          t.spec.index,
    ];
    if (pages.isEmpty) return;
    final service = ref.read(pdfToolsServiceProvider);
    await runToolJob(
      context,
      ref,
      ToolId.split,
      (control) => service.split(
        input: widget.input.input,
        password: widget.input.password,
        groups: [pages],
        name: PdfToolsService.defaultName(
          ToolId.split,
          widget.input.input.name,
          DateTime.now(),
        ),
        control: control,
      ),
      closeTools: false,
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    var overwrite = false;
    if (widget.input.input.overwritable) {
      final choice = await showDocNookSheet<bool>(
        context,
        title: l.organizeSaveTitle,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            Space.x4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                label: l.organizeSaveCopy,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: Space.x2),
              SecondaryButton(
                label: l.organizeOverwrite,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: Space.x2),
              Text(
                l.organizeOverwriteHelp,
                style: DocNookText.caption.copyWith(
                  color: context.colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      );
      if (choice == null || !mounted) return;
      overwrite = choice;
    }
    final service = ref.read(pdfToolsServiceProvider);
    final pages = [for (final t in _tiles) t.spec];
    await runToolJob(
      context,
      ref,
      ToolId.organize,
      (control) => service.organize(
        input: widget.input.input,
        password: widget.input.password,
        pages: pages,
        extraImages: _images,
        name: PdfToolsService.defaultName(
          ToolId.organize,
          widget.input.input.name,
          DateTime.now(),
        ),
        overwrite: overwrite,
        control: control,
      ),
    );
  }

  Future<bool> _confirmLeave() async {
    if (!_changed) return true;
    final l = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.editDiscardTitle),
        content: Text(l.editDiscardBody),
        actions: [
          QuietButton(
            label: l.actionCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          QuietButton(
            label: l.actionDiscard,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  void _move(Key dragged, int to) {
    final from = _tiles.indexWhere((t) => t.key == dragged);
    if (from < 0 || from == to) return;
    final next = [..._tiles];
    final tile = next.removeAt(from);
    next.insert(to > from ? to - 1 : to, tile);
    _edit(next);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final doc = _doc;
    final selecting = _selected.isNotEmpty;
    return ToolScaffold(
      title: toolTitle(l, ToolId.organize),
      subtitle: selecting
          ? l.organizeSelected(_selected.length)
          : l.pagesCount(_tiles.length),
      actionLabel: l.organizeSave,
      onAction: _changed ? () => unawaited(_save()) : null,
      onBack: _confirmLeave,
      actions: [
        if (_history.isNotEmpty)
          IconAction(
            icon: PhosphorIconsRegular.arrowCounterClockwise,
            label: l.actionUndo,
            onPressed: _undo,
          ),
        if (selecting)
          QuietButton(
            label: l.actionClear,
            onPressed: () => setState(_selected.clear),
          )
        else
          QuietButton(
            label: l.actionSelectAll,
            onPressed: () =>
                setState(() => _selected.addAll(_tiles.map((t) => t.key))),
          ),
      ],
      bottom: _ActionBar(
        children: [
          _BarAction(
            icon: PhosphorIconsRegular.arrowClockwise,
            label: l.organizeRotate,
            onPressed: _rotate,
          ),
          _BarAction(
            icon: PhosphorIconsRegular.trash,
            label: l.actionDelete,
            onPressed: selecting ? _delete : null,
          ),
          _BarAction(
            icon: PhosphorIconsRegular.copy,
            label: l.organizeDuplicate,
            onPressed: selecting ? _duplicate : null,
          ),
          _BarAction(
            icon: PhosphorIconsRegular.export,
            label: l.organizeExtract,
            onPressed: selecting ? () => unawaited(_extract()) : null,
          ),
          _BarAction(
            icon: PhosphorIconsRegular.plus,
            label: l.organizeInsert,
            onPressed: () => unawaited(_insert()),
          ),
        ],
      ),
      body: doc == null
          ? const LoadingState()
          : PdfDocumentViewBuilder(
              documentRef: doc,
              loadingBuilder: (_) => const LoadingState(),
              errorBuilder: (_, _, _) => ErrorState(
                title: l.toolPickErrorTitle,
                body: l.errCorruptBody,
              ),
              builder: (context, document) {
                if (document == null) return const LoadingState();
                final scale = MediaQuery.textScalerOf(context).scale(1);
                return GridView.builder(
                  padding: const EdgeInsets.all(Space.screen),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: scale > 1.6 ? 2 : 3,
                    mainAxisSpacing: Space.x4,
                    crossAxisSpacing: Space.x3,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: _tiles.length,
                  itemBuilder: (context, i) {
                    final tile = _tiles[i];
                    final selected = _selected.contains(tile.key);
                    final card = _PageCard(
                      tile: tile,
                      number: i + 1,
                      document: document,
                      info: _info,
                      selected: selected,
                    );
                    return DragTarget<Key>(
                      onWillAcceptWithDetails: (d) => d.data != tile.key,
                      onAcceptWithDetails: (d) => _move(d.data, i),
                      builder: (context, candidates, _) =>
                          LongPressDraggable<Key>(
                            data: tile.key,
                            feedback: SizedBox(
                              width: 96,
                              height: 140,
                              child: Opacity(opacity: 0.85, child: card),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: card,
                            ),
                            child: Semantics(
                              selected: selected,
                              button: true,
                              label: l.organizePageLabel(i + 1),
                              onTapHint: l.organizeTapHint,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(() {
                                  if (!_selected.remove(tile.key)) {
                                    _selected.add(tile.key);
                                  }
                                }),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: candidates.isEmpty
                                        ? null
                                        : Border(
                                            left: BorderSide(
                                              color: c.primary,
                                              width: 3,
                                            ),
                                          ),
                                  ),
                                  child: card,
                                ),
                              ),
                            ),
                          ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.tile,
    required this.number,
    required this.document,
    required this.info,
    required this.selected,
  });

  final _Tile tile;
  final int number;
  final PdfDocument document;
  final PdfInfo info;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = tile.spec;
    Widget page;
    if (spec.isBlank) {
      page = const ColoredBox(color: Color(0xFFFFFFFF));
    } else if (tile.image != null) {
      page = _InsertedImage(input: tile.image!);
    } else {
      final base = info.pages[spec.index].rotation;
      page = PdfPageView(
        document: document,
        pageNumber: spec.index + 1,
        maximumDpi: 40,
        rotationOverride:
            PdfPageRotation.values[(base + spec.quarterTurns) & 3],
        decoration: const BoxDecoration(),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border.all(
                color: selected ? c.primary : c.hairline,
                width: selected ? 2 : 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                page,
                if (selected)
                  Positioned(
                    right: Space.x1,
                    top: Space.x1,
                    child: Icon(
                      PhosphorIconsFill.checkCircle,
                      size: Sizes.icon,
                      color: c.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.x1),
        Text(
          '$number',
          style: DocNookText.caption.copyWith(
            color: selected ? c.primary : c.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _InsertedImage extends ConsumerWidget {
  const _InsertedImage({required this.input});
  final ToolInput input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.read(pdfToolsServiceProvider).localPath(input);
    return FutureBuilder<String>(
      future: future,
      builder: (context, snap) => snap.hasData
          ? Image.file(File(snap.data!), fit: BoxFit.contain, cacheWidth: 240)
          : const SizedBox.shrink(),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.paper,
      border: Border(top: BorderSide(color: context.colors.hairline)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x1),
      child: Row(children: [for (final c in children) Expanded(child: c)]),
    ),
  );
}

/// Icon with a short label underneath, for editor bottom bars.
class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = onPressed == null ? c.inkMuted.withValues(alpha: 0.4) : c.ink;
    return InkWell(
      onTap: onPressed,
      borderRadius: Radii.chipAll,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.touch),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: Sizes.icon, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DocNookText.caption.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/data/repositories/library_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/features/home/application/open_actions.dart';
import 'package:docnook/features/library/application/library_controller.dart';
import 'package:docnook/features/library/presentation/document_list.dart';
import 'package:docnook/features/library/presentation/file_sheets.dart';
import 'package:docnook/features/library/presentation/files_screen.dart';
import 'package:docnook/features/library/presentation/selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// S05: one collection, same list behaviour as Files.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({required this.id, required this.name, super.key});

  final int id;
  final String name;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  late String _name = widget.name;
  final _selected = <int, DocumentInfo>{};

  void _toggle(DocumentInfo d) => setState(() {
    if (_selected.remove(d.id) == null) _selected[d.id] = d;
  });

  Future<void> _rename() async {
    final l = AppLocalizations.of(context);
    final name = await askText(
      context,
      title: l.renameCollection,
      label: l.collectionName,
      action: l.actionRename,
      initial: _name,
    );
    if (name == null) return;
    await ref.read(libraryRepositoryProvider).renameCollection(widget.id, name);
    setState(() => _name = name);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteCollection),
        content: Text(l.deleteCollectionBody),
        actions: [
          QuietButton(
            label: l.actionCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          QuietButton(
            label: l.actionDelete,
            color: context.colors.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(libraryRepositoryProvider).deleteCollection(widget.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final docs = ref
        .watch(
          libraryDocsProvider((
            filter: LibraryFilter.all,
            sort: LibrarySort.name,
            collection: widget.id,
          )),
        )
        .value;
    final selecting = _selected.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconAction(
          icon: selecting
              ? PhosphorIconsRegular.x
              : PhosphorIconsRegular.arrowLeft,
          label: selecting ? l.actionDeselect : l.actionBack,
          onPressed: selecting
              ? () => setState(_selected.clear)
              : () => Navigator.of(context).maybePop(),
        ),
        title: Text(selecting ? l.selectedCount(_selected.length) : _name),
        actions: [
          if (!selecting)
            PopupMenuButton<int>(
              tooltip: l.actionMore,
              icon: const Icon(
                PhosphorIconsRegular.dotsThreeVertical,
                size: Sizes.icon,
              ),
              position: PopupMenuPosition.under,
              onSelected: (i) => unawaited(i == 0 ? _rename() : _delete()),
              itemBuilder: (_) => [
                PopupMenuItem(value: 0, child: Text(l.renameCollection)),
                PopupMenuItem(
                  value: 1,
                  child: Text(
                    l.deleteCollection,
                    style: DocNookText.body.copyWith(color: c.danger),
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: selecting
          ? SafeArea(
              child: SelectionActionBar(
                docs: _selected.values.toList(),
                collectionId: widget.id,
                onDone: () => setState(_selected.clear),
              ),
            )
          : null,
      body: docs == null
          ? const LoadingState()
          : docs.isEmpty
          ? Center(
              child: EmptyState(
                art: EmptyArt.paperStack,
                title: l.collectionEmpty,
                body: l.collectionEmptyBody,
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.screen,
                    0,
                    Space.screen,
                    Space.x2,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      l.documentsCount(docs.length),
                      style: DocNookText.caption.copyWith(color: c.inkMuted),
                    ),
                  ),
                ),
                DocumentSliver(
                  docs: docs,
                  grid: false,
                  selected: _selected.keys.toSet(),
                  onTap: (d) => unawaited(openDocument(context, d)),
                  onLongPress: _toggle,
                  onMore: (d) => unawaited(
                    showFileActions(context, ref, d, collectionId: widget.id),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: Space.x8)),
              ],
            ),
    );
  }
}

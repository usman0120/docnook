import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/data/db/app_database.dart';
import 'package:docnook/data/repositories/library_repository.dart';
import 'package:docnook/data/repositories/settings_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/choice.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/features/home/application/open_actions.dart';
import 'package:docnook/features/library/application/library_controller.dart';
import 'package:docnook/features/library/presentation/access_primer.dart';
import 'package:docnook/features/library/presentation/document_list.dart';
import 'package:docnook/features/library/presentation/file_sheets.dart';
import 'package:docnook/features/library/presentation/selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum FilesSegment { documents, collections, folders }

typedef LibraryQuery = ({
  LibraryFilter filter,
  LibrarySort sort,
  int? collection,
});

final libraryDocsProvider = StreamProvider.autoDispose
    .family<List<DocumentInfo>, LibraryQuery>(
      (ref, q) => ref
          .watch(libraryRepositoryProvider)
          .watchLibrary(
            filter: q.filter,
            sort: q.sort,
            collectionId: q.collection,
          ),
    );

final collectionsProvider = StreamProvider.autoDispose<List<CollectionInfo>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchCollections(),
);

final folderGrantsProvider = StreamProvider.autoDispose<List<FolderGrantRow>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchFolderGrants(),
);

/// Whether a list is in multi-select mode; the shell hides Scan meanwhile.
final selectionActiveProvider = NotifierProvider<_SelectionActive, bool>(
  _SelectionActive.new,
);

class _SelectionActive extends Notifier<bool> {
  @override
  bool build() => false;
  void set({required bool active}) => state = active;
}

/// S04 Files.
class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen>
    with WidgetsBindingObserver {
  FilesSegment _segment = FilesSegment.documents;
  LibraryFilter _filter = LibraryFilter.all;
  LibrarySort _sort = LibrarySort.recent;
  bool _grid = false;
  final _selected = <int, DocumentInfo>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadPrefs());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from the system access screen: re-check, then scan.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final discovery = ref.read(discoveryProvider);
      if (!discovery.hasAccess) {
        unawaited(
          ref.read(discoveryProvider.notifier).refreshAccess(thenScan: true),
        );
      }
    }
  }

  Future<void> _loadPrefs() async {
    final settings = ref.read(settingsRepositoryProvider);
    final sort = SettingsRepository.enumOf(
      LibrarySort.values,
      await settings.get(SettingsRepository.keyLibrarySort),
      LibrarySort.recent,
    );
    final grid =
        await settings.get(SettingsRepository.keyLibraryView) == 'grid';
    if (mounted) {
      setState(() {
        _sort = sort;
        _grid = grid;
      });
    }
  }

  void _setSelecting(bool Function() change) {
    setState(() => change());
    ref
        .read(selectionActiveProvider.notifier)
        .set(active: _selected.isNotEmpty);
  }

  void _toggle(DocumentInfo doc) => _setSelecting(() {
    if (_selected.remove(doc.id) == null) _selected[doc.id] = doc;
    return true;
  });

  void _clearSelection() => _setSelecting(() {
    _selected.clear();
    return true;
  });

  String _filterLabel(AppLocalizations l, LibraryFilter f) => switch (f) {
    LibraryFilter.all => l.filterAll,
    LibraryFilter.pdf => l.filterPdf,
    LibraryFilter.word => l.filterWord,
    LibraryFilter.sheets => l.filterSheets,
    LibraryFilter.slides => l.filterSlides,
    LibraryFilter.images => l.filterImages,
    LibraryFilter.text => l.filterText,
    LibraryFilter.ebooks => l.filterEbooks,
    LibraryFilter.archives => l.filterArchives,
    LibraryFilter.starred => l.filterStarred,
  };

  String _sortLabel(AppLocalizations l, LibrarySort s) => switch (s) {
    LibrarySort.recent => l.sortRecent,
    LibrarySort.name => l.sortName,
    LibrarySort.modified => l.sortModified,
    LibrarySort.size => l.sortSize,
    LibrarySort.type => l.sortType,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final selecting = _selected.isNotEmpty;
    final query = (filter: _filter, sort: _sort, collection: null);
    final docs = ref.watch(libraryDocsProvider(query));

    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(discoveryProvider.notifier).scan(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverSafeArea(
                  bottom: false,
                  sliver: SliverToBoxAdapter(
                    child: selecting
                        ? SelectionHeader(
                            count: _selected.length,
                            onClose: _clearSelection,
                            onSelectAll: () => _setSelecting(() {
                              for (final d
                                  in docs.value ?? const <DocumentInfo>[]) {
                                _selected[d.id] = d;
                              }
                              return true;
                            }),
                          )
                        : LargeTitle(
                            l.filesTitle,
                            actions: [
                              if (_segment == FilesSegment.documents) ...[
                                _SortMenu(
                                  value: _sort,
                                  label: (s) => _sortLabel(l, s),
                                  onSelected: (s) {
                                    setState(() => _sort = s);
                                    unawaited(
                                      ref
                                          .read(settingsRepositoryProvider)
                                          .set(
                                            SettingsRepository.keyLibrarySort,
                                            s.name,
                                          ),
                                    );
                                  },
                                ),
                                IconAction(
                                  icon: _grid
                                      ? PhosphorIconsRegular.listBullets
                                      : PhosphorIconsRegular.squaresFour,
                                  label: _grid ? l.viewList : l.viewGrid,
                                  onPressed: () {
                                    setState(() => _grid = !_grid);
                                    unawaited(
                                      ref
                                          .read(settingsRepositoryProvider)
                                          .set(
                                            SettingsRepository.keyLibraryView,
                                            _grid ? 'grid' : 'list',
                                          ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SearchField(
                    hint: l.searchHint,
                    icon: PhosphorIconsRegular.magnifyingGlass,
                    onTap: () => context.push('/search'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: Space.x3)),
                SliverToBoxAdapter(
                  child: SegmentedChoice<FilesSegment>(
                    values: FilesSegment.values,
                    selected: _segment,
                    label: (s) => switch (s) {
                      FilesSegment.documents => l.segmentDocuments,
                      FilesSegment.collections => l.segmentCollections,
                      FilesSegment.folders => l.segmentFolders,
                    },
                    onSelected: (s) {
                      _clearSelection();
                      setState(() => _segment = s);
                    },
                  ),
                ),
                ...switch (_segment) {
                  FilesSegment.documents => _documents(context, l, docs),
                  FilesSegment.collections => [const _CollectionsSliver()],
                  FilesSegment.folders => [const _FoldersSliver()],
                },
                SliverToBoxAdapter(
                  child: SizedBox(height: selecting ? 120 : 96),
                ),
              ],
            ),
          ),
          if (selecting)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SelectionActionBar(
                docs: _selected.values.toList(),
                onDone: _clearSelection,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _documents(
    BuildContext context,
    AppLocalizations l,
    AsyncValue<List<DocumentInfo>> docs,
  ) {
    final discovery = ref.watch(discoveryProvider);
    final list = docs.value;
    return [
      const SliverToBoxAdapter(child: SizedBox(height: Space.x2)),
      SliverToBoxAdapter(
        child: FilterChips<LibraryFilter>(
          values: LibraryFilter.values,
          selected: _filter,
          label: (f) => _filterLabel(l, f),
          onSelected: (f) {
            _clearSelection();
            setState(() => _filter = f);
          },
        ),
      ),
      if (discovery.running)
        SliverToBoxAdapter(child: _DiscoveryBanner(found: discovery.found)),
      if (discovery.checked &&
          !discovery.canDiscover &&
          (list?.isNotEmpty ?? false))
        SliverToBoxAdapter(
          child: _PermissionCard(
            onTap: () => unawaited(showAccessPrimer(context, ref)),
          ),
        ),
      if (list == null)
        const SliverFillRemaining(hasScrollBody: false, child: LoadingState())
      else if (list.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: _emptyFor(context, l, discovery)),
        )
      else
        DocumentSliver(
          docs: list,
          grid: _grid,
          selected: _selected.keys.toSet(),
          onTap: (d) => unawaited(openDocument(context, d)),
          onLongPress: _toggle,
          onMore: (d) => unawaited(showFileActions(context, ref, d)),
        ),
    ];
  }

  Widget _emptyFor(
    BuildContext context,
    AppLocalizations l,
    DiscoveryState discovery,
  ) {
    if (_filter == LibraryFilter.all && !discovery.canDiscover) {
      return EmptyState(
        art: EmptyArt.openFolder,
        title: l.filesEmptyTitle,
        body: l.filesEmptyBody,
        primaryLabel: l.actionFindDocuments,
        onPrimary: () => unawaited(showAccessPrimer(context, ref)),
        secondaryLabel: l.actionOpenFile,
        onSecondary: () => unawaited(pickAndOpen(context, ref)),
      );
    }
    if (_filter == LibraryFilter.starred) {
      return EmptyState(art: EmptyArt.paperStack, title: l.starredEmpty);
    }
    if (discovery.running) return const SizedBox.shrink();
    return EmptyState(
      art: EmptyArt.openFolder,
      title: _filter == LibraryFilter.all
          ? l.filesEmptyTitle
          : l.filterEmpty(_filterLabel(l, _filter)),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({
    required this.value,
    required this.label,
    required this.onSelected,
  });

  final LibrarySort value;
  final String Function(LibrarySort) label;
  final ValueChanged<LibrarySort> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return PopupMenuButton<LibrarySort>(
      tooltip: l.sortBy,
      icon: const Icon(PhosphorIconsRegular.sortAscending, size: Sizes.icon),
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final s in LibrarySort.values)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Expanded(child: Text(label(s))),
                if (s == value)
                  Icon(
                    PhosphorIconsBold.check,
                    size: Sizes.iconSmall,
                    color: c.primary,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DiscoveryBanner extends StatelessWidget {
  const _DiscoveryBanner({required this.found});
  final int found;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.x2,
        Space.screen,
        0,
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
            ),
            const SizedBox(width: Space.x2),
            Text(
              l.findingDocuments(found),
              style: DocNookText.caption.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.x3,
        Space.screen,
        Space.x1,
      ),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardAll,
          side: BorderSide(color: c.hairline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.cardAll,
          child: Padding(
            padding: const EdgeInsets.all(Space.x4),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.folderOpen,
                  size: Sizes.icon,
                  color: c.primary,
                ),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.permissionCardTitle,
                        style: DocNookText.bodyStrong.copyWith(color: c.ink),
                      ),
                      Text(
                        l.permissionCardBody,
                        style: DocNookText.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  PhosphorIconsRegular.caretRight,
                  size: Sizes.iconSmall,
                  color: c.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionsSliver extends ConsumerWidget {
  const _CollectionsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final collections = ref.watch(collectionsProvider).value;
    Future<void> create() async {
      final name = await askText(
        context,
        title: l.newCollection,
        label: l.collectionName,
        action: l.collectionCreate,
      );
      if (name != null) {
        await ref.read(libraryRepositoryProvider).createCollection(name);
      }
    }

    if (collections == null) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingState(),
      );
    }
    if (collections.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: EmptyState(
            art: EmptyArt.paperStack,
            title: l.collectionsEmptyTitle,
            body: l.collectionsEmptyBody,
            primaryLabel: l.newCollection,
            onPrimary: () => unawaited(create()),
          ),
        ),
      );
    }
    return SliverList.list(
      children: [
        const SizedBox(height: Space.x3),
        ListTile(
          leading: Icon(
            PhosphorIconsRegular.plus,
            size: Sizes.icon,
            color: c.primary,
          ),
          title: Text(
            l.newCollection,
            style: DocNookText.body.copyWith(color: c.primary),
          ),
          onTap: () => unawaited(create()),
        ),
        const Hairline(indent: Space.screen),
        for (final col in collections) ...[
          ListTile(
            leading: const Icon(
              PhosphorIconsRegular.folderSimple,
              size: Sizes.icon,
            ),
            title: Text(col.name),
            subtitle: Text(l.documentsCount(col.count)),
            trailing: Icon(
              PhosphorIconsRegular.caretRight,
              size: Sizes.iconSmall,
              color: c.inkMuted,
            ),
            onTap: () => context.push('/collection/${col.id}', extra: col.name),
          ),
          const Hairline(indent: Space.screen),
        ],
      ],
    );
  }
}

class _FoldersSliver extends ConsumerWidget {
  const _FoldersSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final discovery = ref.watch(discoveryProvider);
    final grants =
        ref.watch(folderGrantsProvider).value ?? const <FolderGrantRow>[];
    return SliverList.list(
      children: [
        const SizedBox(height: Space.x3),
        ListTile(
          leading: Icon(
            PhosphorIconsRegular.folderSimpleStar,
            size: Sizes.icon,
            color: c.accent,
          ),
          title: Text(l.foldersDocNook),
          subtitle: Text(l.foldersDocNookBody),
        ),
        const Hairline(indent: Space.screen),
        ListTile(
          leading: const Icon(
            PhosphorIconsRegular.hardDrives,
            size: Sizes.icon,
          ),
          title: Text(l.foldersAllStorage),
          subtitle: Text(discovery.hasAccess ? l.yes : l.permissionCardBody),
          trailing: discovery.hasAccess
              ? Icon(
                  PhosphorIconsBold.check,
                  size: Sizes.iconSmall,
                  color: c.success,
                )
              : QuietButton(
                  label: l.primerAllow,
                  onPressed: () => unawaited(showAccessPrimer(context, ref)),
                ),
        ),
        SectionHeader(l.foldersGranted),
        if (grants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.screen,
              vertical: Space.x2,
            ),
            child: Text(
              l.foldersEmpty,
              style: DocNookText.body.copyWith(color: c.inkMuted),
            ),
          ),
        for (final grant in grants) ...[
          ListTile(
            leading: const Icon(PhosphorIconsRegular.folder, size: Sizes.icon),
            title: Text(grant.displayName),
            trailing: IconAction(
              icon: PhosphorIconsRegular.x,
              label: l.foldersRemove,
              color: c.inkMuted,
              onPressed: () async {
                await ref
                    .read(libraryRepositoryProvider)
                    .removeFolderGrant(grant);
                await ref.read(platformProvider).releaseTree(grant.treeUri);
                await ref.read(discoveryProvider.notifier).refreshAccess();
              },
            ),
          ),
          const Hairline(indent: Space.screen),
        ],
        Padding(
          padding: const EdgeInsets.all(Space.screen),
          child: SecondaryButton(
            label: l.foldersAdd,
            icon: PhosphorIconsRegular.folderPlus,
            onPressed: () =>
                unawaited(ref.read(discoveryProvider.notifier).addFolder()),
          ),
        ),
      ],
    );
  }
}

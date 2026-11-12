import 'dart:async';

import 'package:docnook/app/providers.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/data/repositories/library_repository.dart';
import 'package:docnook/engines/library/discovery.dart';
import 'package:docnook/features/search/application/indexer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State of document discovery, shown as the "Finding documents…" banner.
final class DiscoveryState {
  const DiscoveryState({
    this.hasAccess = false,
    this.folderCount = 0,
    this.running = false,
    this.found = 0,
    this.checked = false,
  });

  /// All-files (or legacy storage) access is granted.
  final bool hasAccess;

  /// Folders granted through the system folder picker.
  final int folderCount;
  final bool running;

  /// Documents found so far in the current run.
  final int found;

  /// Access has been checked at least once (avoids flashing the primer).
  final bool checked;

  bool get canDiscover => hasAccess || folderCount > 0;

  DiscoveryState copyWith({
    bool? hasAccess,
    int? folderCount,
    bool? running,
    int? found,
    bool? checked,
  }) => DiscoveryState(
    hasAccess: hasAccess ?? this.hasAccess,
    folderCount: folderCount ?? this.folderCount,
    running: running ?? this.running,
    found: found ?? this.found,
    checked: checked ?? this.checked,
  );
}

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(ref.watch(databaseProvider)),
);

final discoveryProvider = NotifierProvider<DiscoveryController, DiscoveryState>(
  DiscoveryController.new,
);

/// Finds documents on the phone (FR-ORG-01).
class DiscoveryController extends Notifier<DiscoveryState> {
  @override
  DiscoveryState build() {
    unawaited(refreshAccess(thenScan: true));
    return const DiscoveryState();
  }

  Future<void> refreshAccess({bool thenScan = false}) async {
    final platform = ref.read(platformProvider);
    final hasAccess = await platform.hasStorageAccess();
    final grants = await ref.read(libraryRepositoryProvider).folderGrants();
    state = state.copyWith(
      hasAccess: hasAccess,
      folderCount: grants.length,
      checked: true,
    );
    if (thenScan && state.canDiscover) await scan();
  }

  /// Asks for all-files access (Android 11+) or the storage prompt (7–10).
  /// On Android 11+ this opens system settings; access is re-checked when
  /// the app resumes.
  Future<void> requestAccess() async {
    final platform = ref.read(platformProvider);
    if (await platform.sdkInt() >= 30) {
      await platform.requestAllFilesAccess();
    } else if (await platform.requestLegacyStorage()) {
      await refreshAccess(thenScan: true);
    }
  }

  /// Lets the user pick a folder instead of granting all-files access.
  Future<bool> addFolder() async {
    final platform = ref.read(platformProvider);
    final tree = await platform.pickTree();
    if (tree == null) return false;
    final name = await platform.treeName(tree) ?? 'Folder';
    await ref.read(libraryRepositoryProvider).addFolderGrant(tree, name);
    await refreshAccess(thenScan: true);
    return true;
  }

  /// Walks storage and granted folders, then saves the results.
  Future<void> scan() async {
    if (state.running) return;
    final platform = ref.read(platformProvider);
    final library = ref.read(libraryRepositoryProvider);
    state = state.copyWith(running: true, found: 0);
    try {
      final found = <FoundFile>[];
      final scopes = <String>[];

      if (state.hasAccess) {
        final root = await platform.storageRoot();
        if (root != null) {
          final job = ref
              .read(jobRunnerProvider)
              .run(
                discoverFiles,
                DiscoveryRequest(root: root),
                timeout: const Duration(minutes: 3),
              );
          final sub = job.progress.listen((p) {
            final n = int.tryParse(p.label ?? '');
            if (n != null) state = state.copyWith(found: n);
          });
          final result = await job.result;
          await sub.cancel();
          if (result case Ok(:final value)) {
            found.addAll(value);
            scopes.add(root);
          }
        }
      }

      for (final grant in await library.folderGrants()) {
        final listed = await platform.listTree(grant.treeUri);
        if (listed case Ok(:final value)) {
          for (final e in value) {
            if (!isDocumentName(e.name) || (e.size ?? 0) == 0) continue;
            found.add(
              FoundFile(
                uri: e.uri,
                name: e.name,
                size: e.size ?? 0,
                modifiedMs: e.modified ?? 0,
              ),
            );
          }
          scopes.add(grant.treeUri);
        }
        state = state.copyWith(found: found.length);
      }

      await library.applyDiscovery(found, scopes: scopes);
      state = state.copyWith(found: found.length);
      ref.read(indexerProvider).kick();
    } finally {
      state = state.copyWith(running: false);
    }
  }
}

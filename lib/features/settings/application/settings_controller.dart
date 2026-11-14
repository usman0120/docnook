import 'package:docnook/app/providers.dart';
import 'package:docnook/data/files/app_paths.dart';
import 'package:docnook/data/repositories/settings_repository.dart';
import 'package:docnook/features/library/application/library_controller.dart';
import 'package:docnook/features/search/application/indexer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bytes in DocNook's caches (opened copies and thumbnails).
final cacheSizeProvider = FutureProvider.autoDispose<int>((ref) async {
  final paths = ref.watch(appPathsProvider);
  return await AppPaths.sizeOf(paths.opened) +
      await AppPaths.sizeOf(paths.thumbs);
});

/// One setting's stored value, live.
final settingProvider = StreamProvider.autoDispose.family<String?, String>(
  (ref, key) => ref.watch(settingsRepositoryProvider).watch(key),
);

final settingsControllerProvider = Provider<SettingsController>(
  SettingsController.new,
);

/// S30 actions that do more than store a value (FR-SET-01).
class SettingsController {
  SettingsController(this._ref);
  final Ref _ref;

  SettingsRepository get _settings => _ref.read(settingsRepositoryProvider);

  Future<void> set(String key, String value) => _settings.set(key, value);

  Future<void> setBool(String key, {required bool value}) =>
      _settings.setBool(key, value: value);

  /// Removes opened copies and thumbnails; documents are untouched.
  Future<void> clearCache() async {
    final paths = _ref.read(appPathsProvider);
    await AppPaths.trim(paths.opened, 0);
    await _ref.read(thumbnailCacheProvider).clear();
    _ref.invalidate(cacheSizeProvider);
  }

  /// Empties the search index and lets the background indexer start over.
  Future<void> rebuildIndex() async {
    await _ref.read(searchRepositoryProvider).resetAll();
    _ref.read(indexerProvider).kick();
  }

  /// Hidden files show up after the next scan, which starts now.
  Future<void> setShowHidden({required bool value}) async {
    await _settings.setBool(SettingsRepository.keyShowHidden, value: value);
    final discovery = _ref.read(discoveryProvider.notifier);
    if (_ref.read(discoveryProvider).canDiscover) await discovery.scan();
  }

  Future<void> rescan() => _ref.read(discoveryProvider.notifier).scan();

  Future<void> requestAccess() =>
      _ref.read(discoveryProvider.notifier).requestAccess();

  Future<bool> addFolder() => _ref.read(discoveryProvider.notifier).addFolder();
}

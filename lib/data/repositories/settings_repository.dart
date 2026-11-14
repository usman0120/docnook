import 'package:docnook/data/db/app_database.dart';

enum ThemePreference { system, light, dark }

enum PdfScrollMode { vertical, horizontal }

enum OutputQuality { small, balanced, best }

/// Typed settings over the `app_settings` table (FR-SET-01). No
/// SharedPreferences, so everything lives in one private database.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const keyOnboarded = 'onboarded';
  static const keyTheme = 'theme';
  static const keyPdfScroll = 'pdf_scroll';
  static const keyNightDefault = 'night_default';
  static const keyKeepScreenOn = 'keep_screen_on';
  static const keyQuality = 'output_quality';
  static const keyFileNaming = 'file_naming';
  static const keyReadAloudRate = 'read_aloud_rate';
  static const keyShowHidden = 'show_hidden';
  static const keyRecentSearches = 'recent_searches';
  static const keyLibraryView = 'library_view';
  static const keyLibrarySort = 'library_sort';

  Future<String?> get(String key) async => (await (_db.select(
    _db.appSettings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Stream<String?> watch(String key) =>
      (_db.select(_db.appSettings)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Future<void> set(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      );

  Future<void> remove(String key) =>
      (_db.delete(_db.appSettings)..where((s) => s.key.equals(key))).go();

  Future<bool> getBool(String key, {bool fallback = false}) async {
    final value = await get(key);
    return value == null ? fallback : value == 'true';
  }

  Future<void> setBool(String key, {required bool value}) => set(key, '$value');

  Stream<bool> watchBool(String key, {bool fallback = false}) =>
      watch(key).map((v) => v == null ? fallback : v == 'true');

  static T enumOf<T extends Enum>(List<T> values, String? name, T fallback) =>
      values.asNameMap()[name] ?? fallback;

  Stream<ThemePreference> watchTheme() => watch(
    keyTheme,
  ).map((v) => enumOf(ThemePreference.values, v, ThemePreference.system));
}

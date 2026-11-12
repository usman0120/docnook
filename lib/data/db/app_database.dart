import 'package:docnook/data/db/tables.dart';
import 'package:drift/drift.dart';

export 'package:docnook/data/db/tables.dart';

part 'app_database.g.dart';

/// `docnook.db`: one SQLite database in app-private storage (BLUEPRINT 6).
@DriftDatabase(
  tables: [
    Documents,
    Collections,
    CollectionItems,
    ReadingStates,
    Bookmarks,
    ScanSessions,
    ScanPages,
    Jobs,
    FolderGrants,
    Signatures,
    VaultItems,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createSearchIndex();
      await _createIndexes();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// One row per PDF page or ~4 KB chunk of other formats, so results can
  /// jump to the right place (BLUEPRINT 6.1).
  Future<void> _createSearchIndex() => customStatement('''
    CREATE VIRTUAL TABLE IF NOT EXISTS doc_search USING fts5(
      title, body,
      document_id UNINDEXED, page UNINDEXED,
      tokenize = 'unicode61 remove_diacritics 2'
    )''');

  Future<void> _createIndexes() async {
    for (final sql in const [
      'CREATE INDEX IF NOT EXISTS documents_type_modified ON documents (doc_type, modified_at DESC)',
      'CREATE INDEX IF NOT EXISTS documents_last_opened ON documents (last_opened_at DESC)',
      'CREATE INDEX IF NOT EXISTS documents_starred ON documents (is_starred)',
      'CREATE INDEX IF NOT EXISTS documents_missing ON documents (is_missing)',
      'CREATE INDEX IF NOT EXISTS jobs_finished ON jobs (finished_at DESC)',
    ]) {
      await customStatement(sql);
    }
  }
}

import 'dart:convert';

import 'package:docnook/data/db/app_database.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:drift/drift.dart';

/// Reads and writes document metadata, reading positions and bookmarks.
class DocumentRepository {
  DocumentRepository(this._db);

  final AppDatabase _db;

  static int _now() => DateTime.now().toUtc().millisecondsSinceEpoch;

  static DateTime? _time(int? ms) => ms == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();

  static DocumentInfo mapRow(DocumentRow row, {double? progress}) =>
      DocumentInfo(
        id: row.id,
        uri: row.uri,
        name: row.displayName,
        type: DocType.values.asNameMap()[row.docType] ?? DocType.other,
        source: DocSource.values.asNameMap()[row.source] ?? DocSource.picked,
        extension: row.extension,
        mime: row.mime,
        sizeBytes: row.sizeBytes,
        modifiedAt: _time(row.modifiedAt),
        lastOpenedAt: _time(row.lastOpenedAt),
        pageCount: row.pageCount,
        progress: progress,
        starred: row.isStarred,
        encrypted: row.isEncrypted,
        missing: row.isMissing,
        indexed: row.indexState == 'done',
        thumbKey: row.thumbKey,
      );

  /// Creates or refreshes the row for [uri] and returns its id.
  Future<int> upsert({
    required String uri,
    required String name,
    required DocFormat format,
    required DocSource source,
    String? extension,
    int? sizeBytes,
    DateTime? modifiedAt,
  }) async {
    final existing = await (_db.select(
      _db.documents,
    )..where((d) => d.uri.equals(uri))).getSingleOrNull();
    if (existing != null) {
      await (_db.update(
        _db.documents,
      )..where((d) => d.id.equals(existing.id))).write(
        DocumentsCompanion(
          displayName: Value(name),
          docType: Value(format.docType.name),
          mime: Value(format.mime),
          extension: Value(extension),
          sizeBytes: Value(sizeBytes ?? existing.sizeBytes),
          modifiedAt: Value(
            modifiedAt?.toUtc().millisecondsSinceEpoch ?? existing.modifiedAt,
          ),
          isMissing: const Value(false),
        ),
      );
      return existing.id;
    }
    return _db
        .into(_db.documents)
        .insert(
          DocumentsCompanion.insert(
            uri: uri,
            displayName: name,
            docType: format.docType.name,
            mime: Value(format.mime),
            extension: Value(extension),
            sizeBytes: Value(sizeBytes),
            modifiedAt: Value(modifiedAt?.toUtc().millisecondsSinceEpoch),
            addedAt: _now(),
            source: source.name,
          ),
        );
  }

  Future<void> markOpened(int id) => _db.customUpdate(
    'UPDATE documents SET last_opened_at = ?, open_count = open_count + 1 WHERE id = ?',
    variables: [Variable.withInt(_now()), Variable.withInt(id)],
    updates: {_db.documents},
  );

  Future<void> setPageCount(int id, int pages, {bool? encrypted}) =>
      (_db.update(_db.documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(
          pageCount: Value(pages),
          isEncrypted: encrypted == null
              ? const Value.absent()
              : Value(encrypted),
        ),
      );

  Future<void> setStarred(int id, {required bool starred}) =>
      (_db.update(_db.documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(isStarred: Value(starred)),
      );

  Future<void> setThumbKey(int id, String key) =>
      (_db.update(_db.documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(thumbKey: Value(key)),
      );

  Future<void> markMissing(int id) =>
      (_db.update(_db.documents)..where((d) => d.id.equals(id))).write(
        const DocumentsCompanion(isMissing: Value(true)),
      );

  Future<void> rename(int id, {required String uri, required String name}) =>
      (_db.update(_db.documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(uri: Value(uri), displayName: Value(name)),
      );

  Future<void> remove(int id) =>
      (_db.delete(_db.documents)..where((d) => d.id.equals(id))).go();

  /// Forgets the document in Recents without deleting the file.
  Future<void> clearRecent(int id) =>
      (_db.update(_db.documents)..where((d) => d.id.equals(id))).write(
        const DocumentsCompanion(lastOpenedAt: Value(null)),
      );

  Future<DocumentInfo?> byId(int id) async {
    final row = await (_db.select(
      _db.documents,
    )..where((d) => d.id.equals(id))).getSingleOrNull();
    return row == null ? null : mapRow(row);
  }

  Future<DocumentInfo?> byUri(String uri) async {
    final row = await (_db.select(
      _db.documents,
    )..where((d) => d.uri.equals(uri))).getSingleOrNull();
    return row == null ? null : mapRow(row);
  }

  /// Recently opened documents, newest first, with reading progress.
  Stream<List<DocumentInfo>> watchRecent({int limit = 10}) {
    final query =
        _db.select(_db.documents).join([
            leftOuterJoin(
              _db.readingStates,
              _db.readingStates.documentId.equalsExp(_db.documents.id),
            ),
          ])
          ..where(_db.documents.lastOpenedAt.isNotNull())
          ..orderBy([OrderingTerm.desc(_db.documents.lastOpenedAt)])
          ..limit(limit);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          mapRow(
            row.readTable(_db.documents),
            progress: row.readTableOrNull(_db.readingStates)?.progress,
          ),
      ],
    );
  }

  // ------------------------------------------------------ reading state

  Future<ReadingPosition?> position(int documentId) async {
    final row = await (_db.select(
      _db.readingStates,
    )..where((r) => r.documentId.equals(documentId))).getSingleOrNull();
    if (row == null) return null;
    try {
      return ReadingPosition.fromJson(
        jsonDecode(row.positionJson) as Map<String, Object?>,
      );
    } on FormatException {
      return null;
    }
  }

  Future<Map<String, Object?>> viewPrefs(int documentId) async {
    final row = await (_db.select(
      _db.readingStates,
    )..where((r) => r.documentId.equals(documentId))).getSingleOrNull();
    final json = row?.viewPrefsJson;
    if (json == null) return const {};
    try {
      return jsonDecode(json) as Map<String, Object?>;
    } on FormatException {
      return const {};
    }
  }

  Future<void> savePosition(
    int documentId,
    ReadingPosition position, {
    required double progress,
    Map<String, Object?>? viewPrefs,
  }) => _db
      .into(_db.readingStates)
      .insertOnConflictUpdate(
        ReadingStatesCompanion.insert(
          documentId: Value(documentId),
          positionJson: jsonEncode(position.toJson()),
          progress: Value(progress.clamp(0, 1).toDouble()),
          viewPrefsJson: viewPrefs == null
              ? const Value.absent()
              : Value(jsonEncode(viewPrefs)),
          updatedAt: _now(),
        ),
      );

  // ---------------------------------------------------------- bookmarks

  Stream<List<BookmarkRow>> watchBookmarks(int documentId) =>
      (_db.select(_db.bookmarks)
            ..where((b) => b.documentId.equals(documentId))
            ..orderBy([(b) => OrderingTerm.asc(b.createdAt)]))
          .watch();

  Future<void> addBookmark(
    int documentId, {
    required int page,
    required String label,
  }) => _db
      .into(_db.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          documentId: documentId,
          anchorJson: jsonEncode({'page': page}),
          label: label,
          createdAt: _now(),
        ),
      );

  Future<void> removeBookmark(int id) =>
      (_db.delete(_db.bookmarks)..where((b) => b.id.equals(id))).go();

  static int? bookmarkPage(BookmarkRow row) {
    try {
      return ((jsonDecode(row.anchorJson) as Map<String, Object?>)['page']
              as num?)
          ?.toInt();
    } on FormatException {
      return null;
    }
  }
}

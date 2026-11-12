import 'package:docnook/data/db/app_database.dart';
import 'package:docnook/data/files/file_type_detector.dart';
import 'package:docnook/data/repositories/document_repository.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/engines/library/discovery.dart';
import 'package:drift/drift.dart';

/// Filter chips of the Files tab (BLUEPRINT 10.3, S04).
enum LibraryFilter {
  all,
  pdf,
  word,
  sheets,
  slides,
  images,
  text,
  ebooks,
  archives,
  starred,
}

enum LibrarySort { recent, name, modified, size, type }

/// A user collection with its item count.
final class CollectionInfo {
  const CollectionInfo({
    required this.id,
    required this.name,
    required this.count,
  });
  final int id;
  final String name;
  final int count;
}

final class DiscoverySummary {
  const DiscoverySummary({
    required this.found,
    required this.added,
    required this.missing,
  });
  final int found;
  final int added;
  final int missing;
}

/// The library: discovered documents, filters, collections, folder grants.
class LibraryRepository {
  LibraryRepository(this._db);

  final AppDatabase _db;

  static int _now() => DateTime.now().toUtc().millisecondsSinceEpoch;

  /// Saves a discovery run. Files under [scopes] (path prefixes or tree URI
  /// prefixes) that were found before but not now are marked missing; their
  /// rows stay so Recents and collections can say "no longer available".
  Future<DiscoverySummary> applyDiscovery(
    List<FoundFile> found, {
    required List<String> scopes,
  }) => _db.transaction(() async {
    final before =
        (await _db
                .customSelect('SELECT COUNT(*) AS n FROM documents')
                .getSingle())
            .read<int>('n');
    final now = _now();
    for (var start = 0; start < found.length; start += 500) {
      final chunk = found.sublist(start, (start + 500).clamp(0, found.length));
      await _db.batch((batch) {
        for (final f in chunk) {
          final ext = FileTypeDetector.extensionOf(f.name);
          final format =
              FileTypeDetector.formatForExtension(ext) ?? DocFormat.unknown;
          batch.customStatement(
            'INSERT INTO documents (uri, display_name, extension, mime, doc_type, size_bytes, '
            'modified_at, added_at, source, is_missing) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0) '
            'ON CONFLICT(uri) DO UPDATE SET display_name = excluded.display_name, '
            'size_bytes = excluded.size_bytes, modified_at = excluded.modified_at, '
            'is_missing = 0, '
            // A changed file must be indexed again.
            "index_state = CASE WHEN documents.modified_at IS NOT excluded.modified_at "
            "THEN 'none' ELSE documents.index_state END",
            [
              f.uri,
              f.name,
              ext,
              format.mime,
              format.docType.name,
              f.size,
              f.modifiedMs,
              now,
              'discovered',
            ],
          );
        }
      });
    }

    final seen = {for (final f in found) f.uri};
    var missing = 0;
    for (final scope in scopes) {
      final rows =
          await (_db.select(_db.documents)
                ..where(
                  (d) => d.uri.like('${_escapeLike(scope)}%', escapeChar: r'\'),
                )
                ..where((d) => d.isMissing.equals(false)))
              .get();
      final gone = [
        for (final r in rows)
          if (!seen.contains(r.uri)) r.id,
      ];
      for (var i = 0; i < gone.length; i += 500) {
        final ids = gone.sublist(i, (i + 500).clamp(0, gone.length));
        await (_db.update(_db.documents)..where((d) => d.id.isIn(ids))).write(
          const DocumentsCompanion(isMissing: Value(true)),
        );
      }
      missing += gone.length;
    }
    final after =
        (await _db
                .customSelect('SELECT COUNT(*) AS n FROM documents')
                .getSingle())
            .read<int>('n');
    return DiscoverySummary(
      found: found.length,
      added: after - before,
      missing: missing,
    );
  });

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  static List<String>? _typesFor(LibraryFilter filter) => switch (filter) {
    LibraryFilter.pdf => ['pdf'],
    LibraryFilter.word => ['word'],
    LibraryFilter.sheets => ['sheet'],
    LibraryFilter.slides => ['slides'],
    LibraryFilter.images => ['image'],
    LibraryFilter.text => ['text', 'markdown'],
    LibraryFilter.ebooks => ['epub'],
    LibraryFilter.archives => ['archive'],
    LibraryFilter.all || LibraryFilter.starred => null,
  };

  /// Library documents for a filter and sort; missing files are hidden.
  Stream<List<DocumentInfo>> watchLibrary({
    LibraryFilter filter = LibraryFilter.all,
    LibrarySort sort = LibrarySort.recent,
    int? collectionId,
  }) {
    final query = _db.select(_db.documents).join([
      leftOuterJoin(
        _db.readingStates,
        _db.readingStates.documentId.equalsExp(_db.documents.id),
      ),
      if (collectionId != null)
        innerJoin(
          _db.collectionItems,
          _db.collectionItems.documentId.equalsExp(_db.documents.id) &
              _db.collectionItems.collectionId.equals(collectionId),
        ),
    ])..where(_db.documents.isMissing.equals(false));

    final types = _typesFor(filter);
    if (types != null) query.where(_db.documents.docType.isIn(types));
    if (filter == LibraryFilter.starred)
      query.where(_db.documents.isStarred.equals(true));

    final d = _db.documents;
    query.orderBy(switch (sort) {
      LibrarySort.recent => [
        OrderingTerm(
          expression: coalesce([d.lastOpenedAt, d.modifiedAt, d.addedAt]),
          mode: OrderingMode.desc,
        ),
      ],
      LibrarySort.name => [
        OrderingTerm.asc(d.displayName.collate(Collate.noCase)),
      ],
      LibrarySort.modified => [
        OrderingTerm(
          expression: coalesce([d.modifiedAt, d.addedAt]),
          mode: OrderingMode.desc,
        ),
      ],
      LibrarySort.size => [OrderingTerm.desc(d.sizeBytes)],
      LibrarySort.type => [
        OrderingTerm.asc(d.docType),
        OrderingTerm.asc(d.displayName.collate(Collate.noCase)),
      ],
    });

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          DocumentRepository.mapRow(
            row.readTable(d),
            progress: row.readTableOrNull(_db.readingStates)?.progress,
          ),
      ],
    );
  }

  Stream<int> watchCount() => _db
      .customSelect(
        'SELECT COUNT(*) AS n FROM documents WHERE is_missing = 0',
        readsFrom: {_db.documents},
      )
      .watchSingle()
      .map((r) => r.read<int>('n'));

  /// Name matches for search, newest first.
  Future<List<DocumentInfo>> searchNames(String term, {int limit = 30}) async {
    final rows =
        await (_db.select(_db.documents)
              ..where(
                (d) => d.displayName.like(
                  '%${_escapeLike(term)}%',
                  escapeChar: r'\',
                ),
              )
              ..where((d) => d.isMissing.equals(false))
              ..orderBy([
                (d) => OrderingTerm(
                  expression: coalesce([d.lastOpenedAt, d.modifiedAt]),
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(limit))
            .get();
    return [for (final r in rows) DocumentRepository.mapRow(r)];
  }

  // -------------------------------------------------------- collections

  Stream<List<CollectionInfo>> watchCollections() => _db
      .customSelect(
        'SELECT c.id, c.name, COUNT(d.id) AS n FROM collections c '
        'LEFT JOIN collection_items i ON i.collection_id = c.id '
        'LEFT JOIN documents d ON d.id = i.document_id AND d.is_missing = 0 '
        'GROUP BY c.id ORDER BY c.sort_order, c.name COLLATE NOCASE',
        readsFrom: {_db.collections, _db.collectionItems, _db.documents},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            CollectionInfo(
              id: r.read<int>('id'),
              name: r.read<String>('name'),
              count: r.read<int>('n'),
            ),
        ],
      );

  Future<int> createCollection(String name) => _db
      .into(_db.collections)
      .insert(
        CollectionsCompanion.insert(name: name.trim(), createdAt: _now()),
      );

  Future<void> renameCollection(int id, String name) =>
      (_db.update(_db.collections)..where((c) => c.id.equals(id))).write(
        CollectionsCompanion(name: Value(name.trim())),
      );

  Future<void> deleteCollection(int id) =>
      (_db.delete(_db.collections)..where((c) => c.id.equals(id))).go();

  Future<void> addToCollection(int collectionId, Iterable<int> documentIds) =>
      _db.batch((batch) {
        for (final id in documentIds) {
          batch.insert(
            _db.collectionItems,
            CollectionItemsCompanion.insert(
              collectionId: collectionId,
              documentId: id,
              addedAt: _now(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });

  Future<void> removeFromCollection(
    int collectionId,
    Iterable<int> documentIds,
  ) =>
      (_db.delete(_db.collectionItems)..where(
            (i) =>
                i.collectionId.equals(collectionId) &
                i.documentId.isIn(documentIds),
          ))
          .go();

  Future<List<String>> collectionsOf(int documentId) async {
    final rows = await _db
        .customSelect(
          'SELECT c.name FROM collections c JOIN collection_items i ON i.collection_id = c.id '
          'WHERE i.document_id = ? ORDER BY c.name COLLATE NOCASE',
          variables: [Variable.withInt(documentId)],
        )
        .get();
    return [for (final r in rows) r.read<String>('name')];
  }

  // ------------------------------------------------------ folder grants

  Stream<List<FolderGrantRow>> watchFolderGrants() => (_db.select(
    _db.folderGrants,
  )..orderBy([(g) => OrderingTerm.asc(g.displayName)])).watch();

  Future<List<FolderGrantRow>> folderGrants() =>
      _db.select(_db.folderGrants).get();

  Future<void> addFolderGrant(String treeUri, String name) => _db
      .into(_db.folderGrants)
      .insert(
        FolderGrantsCompanion.insert(
          treeUri: treeUri,
          displayName: name,
          grantedAt: _now(),
        ),
        mode: InsertMode.insertOrReplace,
      );

  /// Forgets a folder and the documents found only through it.
  Future<void> removeFolderGrant(FolderGrantRow grant) =>
      _db.transaction(() async {
        await (_db.delete(
          _db.folderGrants,
        )..where((g) => g.id.equals(grant.id))).go();
        await (_db.delete(_db.documents)
              ..where(
                (d) => d.uri.like(
                  '${_escapeLike(grant.treeUri)}%',
                  escapeChar: r'\',
                ),
              )
              ..where((d) => d.source.equals('discovered')))
            .go();
      });
}

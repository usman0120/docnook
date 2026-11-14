import 'package:docnook/data/db/app_database.dart';
import 'package:docnook/data/repositories/document_repository.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:drift/drift.dart';

/// One hit inside a document's text.
final class ContentHit {
  const ContentHit({
    required this.document,
    required this.page,
    required this.snippet,
  });

  final DocumentInfo document;

  /// 1-based page for PDFs; chunk number (from 1) for other formats.
  final int page;

  /// Two lines of context with the match wrapped in `[` and `]`.
  final String snippet;
}

/// Text chunk ready to store in the index.
final class IndexChunk {
  const IndexChunk(this.page, this.text);
  final int page;
  final String text;
}

/// The full-text index (`doc_search`, FTS5) and its bookkeeping
/// (FR-ORG-02, FR-SCAN-03).
class SearchRepository {
  SearchRepository(this._db);

  final AppDatabase _db;

  /// Body text kept per document (BLUEPRINT 6.1).
  static const maxBodyChars = 2 * 1024 * 1024;

  /// Next documents waiting for indexing, oldest first.
  Future<List<DocumentInfo>> pending({
    required List<String> types,
    int limit = 20,
  }) async {
    final rows =
        await (_db.select(_db.documents)
              ..where((d) => d.indexState.equals('none'))
              ..where((d) => d.isMissing.equals(false))
              ..where((d) => d.docType.isIn(types))
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

  /// Replaces a document's index rows. Chunks beyond [maxBodyChars] total
  /// are dropped.
  Future<void> store(
    DocumentInfo doc,
    List<IndexChunk> chunks,
  ) => _db.transaction(() async {
    await _db.customStatement('DELETE FROM doc_search WHERE document_id = ?', [
      doc.id,
    ]);
    var total = 0;
    for (final chunk in chunks) {
      final text = chunk.text.trim();
      if (text.isEmpty) continue;
      total += text.length;
      if (total > maxBodyChars) break;
      await _db.customStatement(
        'INSERT INTO doc_search (title, body, document_id, page) VALUES (?, ?, ?, ?)',
        [doc.name, text, doc.id, chunk.page],
      );
    }
    await _setState(doc.id, 'done');
  });

  /// Empties the index and marks every document for indexing again
  /// (Settings → Library → Rebuild search index).
  Future<void> resetAll() => _db.transaction(() async {
    await _db.customStatement('DELETE FROM doc_search');
    await _db
        .update(_db.documents)
        .write(const DocumentsCompanion(indexState: Value('none')));
  });

  Future<void> markFailed(int documentId) => _setState(documentId, 'failed');
  Future<void> markSkipped(int documentId) => _setState(documentId, 'skipped');

  Future<void> _setState(int id, String state) =>
      (_db.update(_db.documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(
          indexState: Value(state),
          indexedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );

  Future<bool> isIndexed(int documentId) async {
    final row = await (_db.select(
      _db.documents,
    )..where((d) => d.id.equals(documentId))).getSingleOrNull();
    return row?.indexState == 'done';
  }

  /// Turns what the user typed into a safe FTS5 query: each word becomes a
  /// quoted prefix term, so punctuation can never break the syntax.
  static String? ftsQuery(String input) {
    final words = RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(input.toLowerCase())
        .map((m) => m.group(0)!)
        .where((w) => w.isNotEmpty)
        .take(8)
        .toList();
    if (words.isEmpty) return null;
    return words.map((w) => '"$w"*').join(' ');
  }

  /// Content hits, best first, one per (document, page), at most [limit].
  Future<List<ContentHit>> searchContent(String input, {int limit = 40}) async {
    final query = ftsQuery(input);
    if (query == null) return const [];
    final rows = await _db
        .customSelect(
          'SELECT s.document_id AS doc, s.page AS page, '
          "snippet(doc_search, 1, '[', ']', '…', 9) AS snip "
          'FROM doc_search s JOIN documents d ON d.id = s.document_id '
          'WHERE doc_search MATCH ? AND d.is_missing = 0 '
          'ORDER BY bm25(doc_search) LIMIT ?',
          variables: [
            Variable.withString('body : ($query)'),
            Variable.withInt(limit),
          ],
          readsFrom: {_db.documents},
        )
        .get();
    if (rows.isEmpty) return const [];
    final ids = {for (final r in rows) r.read<int>('doc')};
    final docs = {
      for (final d in await (_db.select(
        _db.documents,
      )..where((d) => d.id.isIn(ids))).get())
        d.id: DocumentRepository.mapRow(d),
    };
    return [
      for (final r in rows)
        if (docs[r.read<int>('doc')] != null)
          ContentHit(
            document: docs[r.read<int>('doc')]!,
            page: r.read<int>('page'),
            snippet: r.read<String>('snip').replaceAll(RegExp(r'\s+'), ' '),
          ),
    ];
  }
}

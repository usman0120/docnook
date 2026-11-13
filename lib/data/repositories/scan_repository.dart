import 'package:docnook/data/db/app_database.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:drift/drift.dart';

/// Scan drafts (FR-SCAN-01): every captured page and edit is written here at
/// once, so a scan survives the app being closed or killed.
class ScanRepository {
  ScanRepository(this._db);

  final AppDatabase _db;

  int _now() => DateTime.now().toUtc().millisecondsSinceEpoch;

  Future<int> createSession({
    required ScanMode mode,
    required String title,
    ScanPageSize pageSize = ScanPageSize.a4,
    ScanQuality quality = ScanQuality.balanced,
    bool ocr = false,
  }) {
    final now = _now();
    return _db
        .into(_db.scanSessions)
        .insert(
          ScanSessionsCompanion.insert(
            title: title,
            status: 'draft',
            mode: mode.key,
            pageSize: pageSize.name,
            quality: quality.name,
            ocrEnabled: Value(ocr),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<ScanSession?> load(int id) async {
    final row = await (_db.select(
      _db.scanSessions,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _session(row, await _pages(id));
  }

  /// One session and its pages; emits again after every change.
  Stream<ScanSession?> watchSession(int id) => _db
      .customSelect('SELECT 1', readsFrom: {_db.scanSessions, _db.scanPages})
      .watch()
      .asyncMap((_) => load(id));

  /// Unfinished scans, newest first.
  Stream<List<ScanSession>> watchDrafts() {
    final query = _db.select(_db.scanSessions)
      ..where((s) => s.status.equals('draft'))
      ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]);
    return query.watch().asyncMap(
      (rows) async => [for (final r in rows) _session(r, await _pages(r.id))],
    );
  }

  Future<List<ScanPage>> _pages(int sessionId) async {
    final rows =
        await (_db.select(_db.scanPages)
              ..where((p) => p.sessionId.equals(sessionId))
              ..orderBy([(p) => OrderingTerm.asc(p.position)]))
            .get();
    return [for (final r in rows) _page(r)];
  }

  ScanSession _session(ScanSessionRow r, List<ScanPage> pages) => ScanSession(
    id: r.id,
    title: r.title,
    mode: ScanMode.fromKey(r.mode),
    pages: pages,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt, isUtc: true),
    pageSize: ScanPageSize.fromName(r.pageSize),
    quality: ScanQuality.fromName(r.quality),
    ocrEnabled: r.ocrEnabled,
  );

  ScanPage _page(ScanPageRow r) => ScanPage(
    id: r.id,
    position: r.position,
    originalPath: r.originalPath,
    processedPath: r.processedPath,
    geometry: PageGeometry.decode(r.cornersJson),
    filter: ScanFilter.fromName(r.filter),
    rotation: r.rotation,
    ocr: OcrPage.decode(r.ocrText),
  );

  Future<int> addPage(
    int sessionId,
    String originalPath, {
    PageGeometry geometry = const PageGeometry(),
    ScanFilter filter = ScanFilter.original,
  }) => _db.transaction(() async {
    final max = await _db
        .customSelect(
          'SELECT COALESCE(MAX(position), -1) AS m FROM scan_pages '
          'WHERE session_id = ?',
          variables: [Variable.withInt(sessionId)],
        )
        .getSingle();
    final id = await _db
        .into(_db.scanPages)
        .insert(
          ScanPagesCompanion.insert(
            sessionId: sessionId,
            position: max.read<int>('m') + 1,
            originalPath: originalPath,
            cornersJson: Value(geometry.encode()),
            filter: Value(filter.name),
          ),
        );
    await _touch(sessionId);
    return id;
  });

  Future<void> updatePage(
    ScanPage page, {
    String? processedPath,
    PageGeometry? geometry,
    ScanFilter? filter,
    int? rotation,
    String? originalPath,
    bool clearOcr = false,
  }) async {
    await (_db.update(_db.scanPages)..where((p) => p.id.equals(page.id))).write(
      ScanPagesCompanion(
        processedPath: processedPath == null
            ? const Value.absent()
            : Value(processedPath),
        cornersJson: geometry == null
            ? const Value.absent()
            : Value(geometry.encode()),
        filter: filter == null ? const Value.absent() : Value(filter.name),
        rotation: rotation == null ? const Value.absent() : Value(rotation),
        originalPath: originalPath == null
            ? const Value.absent()
            : Value(originalPath),
        ocrText: clearOcr ? const Value(null) : const Value.absent(),
      ),
    );
    await _touchPage(page.id);
  }

  /// Puts pages in the order of [pageIds].
  Future<void> reorder(int sessionId, List<int> pageIds) =>
      _db.transaction(() async {
        for (var i = 0; i < pageIds.length; i++) {
          await (_db.update(_db.scanPages)..where(
                (p) => p.id.equals(pageIds[i]) & p.sessionId.equals(sessionId),
              ))
              .write(ScanPagesCompanion(position: Value(i)));
        }
        await _touch(sessionId);
      });

  Future<void> deletePage(ScanPage page) async {
    final row = await (_db.select(
      _db.scanPages,
    )..where((p) => p.id.equals(page.id))).getSingleOrNull();
    await (_db.delete(_db.scanPages)..where((p) => p.id.equals(page.id))).go();
    if (row != null) await _touch(row.sessionId);
  }

  Future<void> updateSettings(
    int sessionId, {
    String? title,
    ScanMode? mode,
    ScanPageSize? pageSize,
    ScanQuality? quality,
    bool? ocr,
  }) => (_db.update(_db.scanSessions)..where((s) => s.id.equals(sessionId)))
      .write(
        ScanSessionsCompanion(
          title: title == null ? const Value.absent() : Value(title),
          mode: mode == null ? const Value.absent() : Value(mode.key),
          pageSize: pageSize == null
              ? const Value.absent()
              : Value(pageSize.name),
          quality: quality == null ? const Value.absent() : Value(quality.name),
          ocrEnabled: ocr == null ? const Value.absent() : Value(ocr),
          updatedAt: Value(_now()),
        ),
      );

  Future<void> deleteSession(int sessionId) =>
      (_db.delete(_db.scanSessions)..where((s) => s.id.equals(sessionId))).go();

  Future<void> _touch(int sessionId) =>
      (_db.update(_db.scanSessions)..where((s) => s.id.equals(sessionId)))
          .write(ScanSessionsCompanion(updatedAt: Value(_now())));

  Future<void> _touchPage(int pageId) async {
    final row = await (_db.select(
      _db.scanPages,
    )..where((p) => p.id.equals(pageId))).getSingleOrNull();
    if (row != null) await _touch(row.sessionId);
  }
}

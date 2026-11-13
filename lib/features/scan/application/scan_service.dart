import 'dart:async';
import 'dart:io';

import 'package:docnook/app/providers.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/data/ocr/ocr_service.dart';
import 'package:docnook/data/repositories/scan_repository.dart';
import 'package:docnook/data/repositories/search_repository.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/scan/scan_image.dart';
import 'package:docnook/engines/scan/scan_pdf_writer.dart';
import 'package:docnook/features/library/application/library_controller.dart';
import 'package:docnook/features/search/application/indexer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => ScanRepository(ref.watch(databaseProvider)),
);

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService(ref.watch(platformProvider));
  ref.onDispose(() => unawaited(service.close()));
  return service;
});

final scanServiceProvider = Provider<ScanService>(ScanService.new);

/// Unfinished scans for the Home card.
final scanDraftsProvider = StreamProvider<List<ScanSession>>(
  (ref) => ref.watch(scanRepositoryProvider).watchDrafts(),
);

/// One scan, live from the database.
final scanSessionProvider = StreamProvider.autoDispose
    .family<ScanSession?, int>(
      (ref, id) => ref.watch(scanRepositoryProvider).watchSession(id),
    );

/// Page ids whose preview is being re-rendered.
final renderingPagesProvider = NotifierProvider<_RenderingPages, Set<int>>(
  _RenderingPages.new,
);

class _RenderingPages extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void add(int id) => state = {...state, id};
  void remove(int id) => state = {...state}..remove(id);
}

/// Preview images: big enough to read on a phone, small enough to be quick.
const _previewEdge = 1600;
const _previewQuality = 82;

/// What an export produced.
final class ScanExportResult {
  const ScanExportResult({
    required this.documentIds,
    required this.names,
    required this.paths,
    required this.totalBytes,
    required this.pageCount,
    required this.mime,
  });

  final List<int> documentIds;
  final List<String> names;

  /// Path or content URI of each saved file.
  final List<String> paths;
  final int totalBytes;
  final int pageCount;
  final String mime;
}

/// Export choices from S25.
final class ScanExportOptions {
  const ScanExportOptions({
    required this.name,
    required this.asPdf,
    required this.pageSize,
    required this.quality,
    required this.ocr,
    this.collectionId,
  });

  final String name;
  final bool asPdf;
  final ScanPageSize pageSize;
  final ScanQuality quality;
  final bool ocr;
  final int? collectionId;
}

/// Scan use cases (FR-SCAN-01..04): building drafts from captured photos,
/// page edits, and export.
class ScanService {
  ScanService(this._ref);

  final Ref _ref;

  ScanRepository get _repo => _ref.read(scanRepositoryProvider);
  JobRunner get _jobs => _ref.read(jobRunnerProvider);

  String _sessionDir(int id) {
    final dir = Directory(p.join(_ref.read(appPathsProvider).scans, '$id'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  static String defaultTitle(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'Scan ${now.year}-${two(now.month)}-${two(now.day)} '
        '${two(now.hour)}.${two(now.minute)}';
  }

  Future<int> createSession(ScanMode mode) =>
      _repo.createSession(mode: mode, title: defaultTitle(DateTime.now()));

  /// Adds photos to a session. [detectEdges] finds the page in raw camera
  /// photos; the ML Kit scanner already returns cropped pages.
  Future<void> addImages(
    int sessionId,
    List<String> sources, {
    required ScanMode mode,
    bool detectEdges = false,
  }) async {
    final dir = _sessionDir(sessionId);
    for (final source in sources) {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final original = p.join(dir, 'orig_$stamp.jpg');
      await _copyLocal(source, original);
      var geometry = const PageGeometry();
      if (detectEdges) {
        final quad = await _jobs
            .run(_detectQuadJob, original, debugName: 'detect')
            .result;
        geometry = PageGeometry(quad: quad.valueOrNull ?? Quad.full);
      }
      if (mode == ScanMode.book) {
        final split = await _jobs.run(_detectSplitJob, (
          original,
          geometry.quad.toList(),
        ), debugName: 'split').result;
        geometry = geometry.copyWith(split: split.valueOrNull ?? 0.5);
      }
      final id = await _repo.addPage(sessionId, original, geometry: geometry);
      final session = await _repo.load(sessionId);
      final page = session?.pages.where((pg) => pg.id == id).firstOrNull;
      if (page != null) unawaited(renderPreview(sessionId, page));
    }
  }

  Future<void> _copyLocal(String source, String dest) async {
    if (source.startsWith('content://')) {
      final r = await _ref.read(platformProvider).copyToCache(source, dest);
      if (r case Err(:final failure)) throw failure;
      return;
    }
    final path = source.startsWith('file://')
        ? Uri.parse(source).toFilePath()
        : source;
    await File(path).copy(dest);
    // The scanner and camera leave their copies in our cache; the session
    // folder now holds the only one we need.
    if (p.isWithin(_ref.read(appPathsProvider).cache, path)) {
      _deleteQuietly(path);
    }
  }

  /// Re-renders a page's preview after an edit.
  Future<void> renderPreview(int sessionId, ScanPage page) async {
    final rendering = _ref.read(renderingPagesProvider.notifier)..add(page.id);
    try {
      final out = p.join(
        _sessionDir(sessionId),
        'prev_${page.id}_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      final result = await _jobs
          .run(
            _renderJob,
            RenderArgs(
              source: page.originalPath,
              output: out,
              corners: page.geometry.quad.toList(),
              rotation: page.rotation,
              filter: page.filter.name,
              maxEdge: _previewEdge,
              jpegQuality: _previewQuality,
            ),
            debugName: 'preview',
          )
          .result;
      if (result.isOk) {
        final old = page.processedPath;
        await _repo.updatePage(page, processedPath: out);
        if (old != null && old != out) _deleteQuietly(old);
      }
    } finally {
      rendering.remove(page.id);
    }
  }

  Future<void> setGeometry(
    int sessionId,
    ScanPage page,
    PageGeometry geometry,
  ) async {
    await _repo.updatePage(page, geometry: geometry, clearOcr: true);
    await renderPreview(sessionId, page.copyWithEdits(geometry: geometry));
  }

  Future<void> rotate(int sessionId, ScanPage page) async {
    final rotation = (page.rotation + 90) % 360;
    await _repo.updatePage(page, rotation: rotation, clearOcr: true);
    await renderPreview(sessionId, page.copyWithEdits(rotation: rotation));
  }

  Future<void> setFilter(
    int sessionId,
    ScanPage page,
    ScanFilter filter,
  ) async {
    await _repo.updatePage(page, filter: filter);
    await renderPreview(sessionId, page.copyWithEdits(filter: filter));
  }

  /// Applies [filter] to every page of the session.
  Future<void> setFilterForAll(ScanSession session, ScanFilter filter) async {
    await Future.wait([
      for (final page in session.pages)
        if (page.filter != filter) setFilter(session.id, page, filter),
    ]);
  }

  /// Replaces a page's photo, keeping its place and filter.
  Future<void> retake(
    int sessionId,
    ScanPage page,
    String source, {
    required ScanMode mode,
    bool detectEdges = false,
  }) async {
    final dir = _sessionDir(sessionId);
    final original = p.join(
      dir,
      'orig_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await _copyLocal(source, original);
    var geometry = const PageGeometry();
    if (detectEdges) {
      final quad = await _jobs.run(_detectQuadJob, original).result;
      geometry = PageGeometry(quad: quad.valueOrNull ?? Quad.full);
    }
    if (mode == ScanMode.book) {
      final split = await _jobs.run(_detectSplitJob, (
        original,
        geometry.quad.toList(),
      )).result;
      geometry = geometry.copyWith(split: split.valueOrNull ?? 0.5);
    }
    final old = page.originalPath;
    await _repo.updatePage(
      page,
      originalPath: original,
      geometry: geometry,
      rotation: 0,
      clearOcr: true,
    );
    _deleteQuietly(old);
    await renderPreview(
      sessionId,
      page.copyWithEdits(
        originalPath: original,
        geometry: geometry,
        rotation: 0,
      ),
    );
  }

  Future<void> deletePage(ScanPage page) async {
    await _repo.deletePage(page);
    _deleteQuietly(page.originalPath);
    final processed = page.processedPath;
    if (processed != null) _deleteQuietly(processed);
  }

  Future<void> reorder(int sessionId, List<int> pageIds) =>
      _repo.reorder(sessionId, pageIds);

  /// Detects the page corners again, for the crop screen's "Auto" button.
  Future<Quad> detectQuad(ScanPage page) async =>
      (await _jobs.run(_detectQuadJob, page.originalPath).result).valueOrNull ??
      Quad.full;

  /// Throws the draft and its photos away.
  Future<void> discard(int sessionId) async {
    await _repo.deleteSession(sessionId);
    final dir = Directory(
      p.join(_ref.read(appPathsProvider).scans, '$sessionId'),
    );
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
    } on FileSystemException {
      // Removed by the next sweep.
    }
  }

  /// Expected output size in bytes, for S25.
  static int estimateBytes(ScanSession session, ScanQuality quality) {
    var pixels = 0.0;
    for (final page in session.pages) {
      final halves =
          session.mode == ScanMode.book && page.geometry.split != null ? 2 : 1;
      // Pages are about A4-shaped; the long edge is capped by quality.
      final long = quality.maxEdge.toDouble();
      pixels += halves * long * long * 0.707 / (halves == 2 ? 2 : 1);
    }
    return (pixels * quality.bytesPerPixel).round() + 2048;
  }

  /// Renders every page at the chosen quality, reads text when asked,
  /// writes the PDF or JPGs, saves them to Documents/DocNook/Scans and
  /// indexes the text (FR-SCAN-03). [onProgress] gets 0–1.
  Future<Result<ScanExportResult>> export(
    ScanSession session,
    ScanExportOptions options, {
    void Function(double value)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final tmp = Directory(
      p.join(
        _ref.read(appPathsProvider).tmp,
        'scan_${session.id}_${DateTime.now().microsecondsSinceEpoch}',
      ),
    )..createSync(recursive: true);
    try {
      void checkCancel() {
        if (isCancelled?.call() ?? false) {
          throw const DocNookFailure.cancelled();
        }
      }

      // 1. Output images, in order. Book spreads become two pages.
      final jobs = <RenderArgs>[];
      for (final page in session.pages) {
        final split = session.mode == ScanMode.book
            ? page.geometry.split
            : null;
        for (final half in split == null ? const [null] : const [0, 1]) {
          jobs.add(
            RenderArgs(
              source: page.originalPath,
              output: p.join(tmp.path, 'page_${jobs.length + 1}.jpg'),
              corners: page.geometry.quad.toList(),
              rotation: page.rotation,
              filter: page.filter.name,
              maxEdge: options.quality.maxEdge,
              jpegQuality: options.quality.jpegQuality,
              split: split,
              half: half,
            ),
          );
        }
      }
      if (jobs.isEmpty) throw const DocNookFailure.unsupported();
      final renderShare = options.ocr ? 0.45 : 0.8;
      var done = 0;
      final sizes = await Future.wait([
        for (final job in jobs)
          _jobs.run(_renderJob, job, debugName: 'render').result.then((r) {
            done++;
            onProgress?.call(renderShare * done / jobs.length);
            return switch (r) {
              Ok(:final value) => value,
              Err(:final failure) => throw failure,
            };
          }),
      ]);
      checkCancel();

      // 2. OCR.
      final ocr = List<OcrPage?>.filled(jobs.length, null);
      if (options.ocr) {
        final service = _ref.read(ocrServiceProvider);
        for (var i = 0; i < jobs.length; i++) {
          checkCancel();
          try {
            ocr[i] = await service.recognize(
              jobs[i].output,
              width: sizes[i].width,
              height: sizes[i].height,
            );
          } on Object {
            ocr[i] = null;
          }
          onProgress?.call(renderShare + 0.4 * (i + 1) / jobs.length);
        }
      }
      checkCancel();

      // 3. Write outputs.
      final outputs = <(String, String, List<IndexChunk>)>[];
      final baseName = _safeName(options.name);
      if (options.asPdf) {
        final plans = <PdfPagePlan>[];
        var start = 0;
        if (session.mode == ScanMode.idCard) {
          final count = jobs.length >= 2 ? 2 : jobs.length;
          plans.add(
            planIdCardPage(
              cards: [
                for (var i = 0; i < count; i++)
                  (
                    path: jobs[i].output,
                    width: sizes[i].width,
                    height: sizes[i].height,
                    ocr: ocr[i]?.encode(),
                  ),
              ],
              size: options.pageSize,
            ),
          );
          start = count;
        }
        for (var i = start; i < jobs.length; i++) {
          plans.add(
            planSinglePage(
              path: jobs[i].output,
              pixelWidth: sizes[i].width,
              pixelHeight: sizes[i].height,
              size: options.pageSize,
              ocr: ocr[i]?.encode(),
            ),
          );
        }
        final pdf = p.join(tmp.path, 'out.pdf');
        final written = await _jobs
            .run(
              _pdfJob,
              ScanPdfRequest(output: pdf, pages: plans, title: options.name),
              timeout: const Duration(minutes: 5),
              debugName: 'scan-pdf',
            )
            .result;
        if (written case Err(:final failure)) throw failure;
        final chunks = _chunks(session.mode, ocr);
        outputs.add((pdf, '$baseName.pdf', chunks));
      } else if (session.mode == ScanMode.idCard) {
        final sheet = p.join(tmp.path, 'id.jpg');
        final r = await _jobs.run(_idSheetJob, (
          [for (final j in jobs.take(2)) j.output],
          sheet,
          options.quality.jpegQuality,
        )).result;
        if (r case Err(:final failure)) throw failure;
        outputs.add((sheet, '$baseName.jpg', _chunks(session.mode, ocr)));
      } else {
        for (var i = 0; i < jobs.length; i++) {
          final text = ocr[i]?.text ?? '';
          outputs.add((
            jobs[i].output,
            jobs.length == 1 ? '$baseName.jpg' : '${baseName}_${i + 1}.jpg',
            [if (text.isNotEmpty) IndexChunk(1, text)],
          ));
        }
      }
      onProgress?.call(0.9);
      checkCancel();

      // 4. Save, register, index.
      final platform = _ref.read(platformProvider);
      final documents = _ref.read(documentRepositoryProvider);
      final search = _ref.read(searchRepositoryProvider);
      final ids = <int>[];
      final names = <String>[];
      final paths = <String>[];
      var total = 0;
      for (final (path, name, chunks) in outputs) {
        final format = options.asPdf ? DocFormat.pdf : DocFormat.jpeg;
        final saved = await platform.saveToDocuments(
          source: path,
          subdir: 'Scans',
          name: name,
          mime: format.mime,
        );
        final file = switch (saved) {
          Ok(:final value) => value,
          Err(:final failure) => throw failure,
        };
        final size = File(path).lengthSync();
        total += size;
        final uri = file.path ?? file.uri;
        final id = await documents.upsert(
          uri: uri,
          name: file.name,
          format: format,
          source: DocSource.scanned,
          extension: options.asPdf ? 'pdf' : 'jpg',
          sizeBytes: size,
          modifiedAt: DateTime.now(),
        );
        if (options.asPdf) {
          await documents.setPageCount(id, _pageCount(session, jobs.length));
        }
        final info = await documents.byId(id);
        // Without OCR text the background indexer reads the file later,
        // like any other document.
        if (info != null && chunks.isNotEmpty) await search.store(info, chunks);
        ids.add(id);
        names.add(file.name);
        paths.add(uri);
      }
      final collection = options.collectionId;
      if (collection != null) {
        await _ref
            .read(libraryRepositoryProvider)
            .addToCollection(collection, ids);
      }
      onProgress?.call(1);
      await discard(session.id);
      return Ok(
        ScanExportResult(
          documentIds: ids,
          names: names,
          paths: paths,
          totalBytes: total,
          pageCount: options.asPdf
              ? _pageCount(session, jobs.length)
              : ids.length,
          mime: options.asPdf ? DocFormat.pdf.mime : DocFormat.jpeg.mime,
        ),
      );
    } on DocNookFailure catch (f) {
      return Err(f);
    } on Object catch (e) {
      return Err(DocNookFailure.from(e));
    } finally {
      try {
        tmp.deleteSync(recursive: true);
      } on FileSystemException {
        // Swept after 24 h.
      }
    }
  }

  static int _pageCount(ScanSession session, int images) =>
      session.mode == ScanMode.idCard ? images - (images >= 2 ? 1 : 0) : images;

  static List<IndexChunk> _chunks(ScanMode mode, List<OcrPage?> ocr) {
    final chunks = <IndexChunk>[];
    if (mode == ScanMode.idCard) {
      final text = ocr.take(2).map((o) => o?.text ?? '').join('\n').trim();
      if (text.isNotEmpty) chunks.add(IndexChunk(1, text));
      for (var i = 2; i < ocr.length; i++) {
        final t = ocr[i]?.text ?? '';
        if (t.isNotEmpty) chunks.add(IndexChunk(i, t));
      }
      return chunks;
    }
    for (var i = 0; i < ocr.length; i++) {
      final t = ocr[i]?.text ?? '';
      if (t.isNotEmpty) chunks.add(IndexChunk(i + 1, t));
    }
    return chunks;
  }

  /// A file name without characters Android or other systems reject.
  static String _safeName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final base = cleaned.isEmpty ? defaultTitle(DateTime.now()) : cleaned;
    return base.length > 120 ? base.substring(0, 120).trim() : base;
  }

  void _deleteQuietly(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } on FileSystemException {
      // Swept with the session.
    }
  }
}

extension on ScanPage {
  ScanPage copyWithEdits({
    String? originalPath,
    PageGeometry? geometry,
    ScanFilter? filter,
    int? rotation,
  }) => ScanPage(
    id: id,
    position: position,
    originalPath: originalPath ?? this.originalPath,
    processedPath: processedPath,
    geometry: geometry ?? this.geometry,
    filter: filter ?? this.filter,
    rotation: rotation ?? this.rotation,
    ocr: ocr,
  );
}

// Isolate entry points (top-level so they can be sent to JobRunner).

Quad _detectQuadJob(String path, JobContext _) => detectPageQuad(path);

double _detectSplitJob((String, List<double>) args, JobContext _) =>
    detectSplit(args.$1, args.$2);

ImageSize _renderJob(RenderArgs args, JobContext _) => renderScanImage(args);

int _pdfJob(ScanPdfRequest request, JobContext _) => writeScanPdf(request);

ImageSize _idSheetJob((List<String>, String, int) args, JobContext _) =>
    composeIdCardSheet(cards: args.$1, output: args.$2, jpegQuality: args.$3);

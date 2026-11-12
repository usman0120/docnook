import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/data/files/app_paths.dart';
import 'package:docnook/data/files/file_type_detector.dart';
import 'package:docnook/data/platform/platform_channel.dart';
import 'package:docnook/data/repositories/document_repository.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:path/path.dart' as p;

/// What the user asked to open.
final class OpenRequest {
  const OpenRequest({
    required this.uri,
    this.name,
    this.mime,
    this.size,
    this.source = DocSource.picked,
    this.page,
    this.searchTerm,
    this.fromIntent = false,
  });

  factory OpenRequest.fromIncoming(
    IncomingFile file, {
    required DocSource source,
  }) => OpenRequest(
    uri: file.uri,
    name: file.name,
    mime: file.mime,
    size: file.size,
    source: source,
    fromIntent: source == DocSource.intent,
  );

  factory OpenRequest.fromDocument(
    DocumentInfo doc, {
    int? page,
    String? searchTerm,
  }) => OpenRequest(
    uri: doc.uri,
    name: doc.name,
    mime: doc.mime,
    size: doc.sizeBytes,
    source: doc.source,
    page: page,
    searchTerm: searchTerm,
  );

  /// Path, `file://` or `content://`.
  final String uri;
  final String? name;
  final String? mime;
  final int? size;
  final DocSource source;

  /// Page to open at, overriding the saved position (search results).
  final int? page;
  final String? searchTerm;

  /// True when another app sent the file; Back returns to that app.
  final bool fromIntent;
}

/// A document ready for a viewer: a readable local file and its real type.
final class OpenedDocument {
  const OpenedDocument({
    required this.documentId,
    required this.path,
    required this.name,
    required this.format,
    required this.request,
    this.sizeBytes,
  });

  final int documentId;
  final String path;
  final String name;
  final DocFormat format;
  final OpenRequest request;
  final int? sizeBytes;
}

/// Safe size limits per format (NFR-LIMIT-01). Larger files open with a
/// warning and a "try anyway" choice (FR-READ-05).
int? safeLimitFor(DocFormat format) => switch (format.docType) {
  DocType.pdf => 500 * 1024 * 1024,
  DocType.word => 50 * 1024 * 1024,
  DocType.sheet => 30 * 1024 * 1024,
  DocType.slides => 100 * 1024 * 1024,
  DocType.epub => 100 * 1024 * 1024,
  DocType.image => 60 * 1024 * 1024,
  DocType.archive => 2 * 1024 * 1024 * 1024,
  DocType.text || DocType.markdown => null, // streamed
  DocType.other => null,
};

/// Turns an [OpenRequest] into an [OpenedDocument] (BLUEPRINT 5.2).
class OpenDocument {
  OpenDocument({
    required AppPaths paths,
    required PlatformChannel platform,
    required DocumentRepository documents,
  }) : _paths = paths,
       _platform = platform,
       _documents = documents;

  final AppPaths _paths;
  final PlatformChannel _platform;
  final DocumentRepository _documents;

  Future<Result<OpenedDocument>> call(OpenRequest request) async {
    final local = await _localFile(request);
    if (local case Err(:final failure)) return Err(failure);
    final path = local.valueOrNull!;

    final name = request.name ?? p.basename(path);
    final file = File(path);
    final FileStat stat;
    try {
      stat = await file.stat();
      if (stat.type == FileSystemEntityType.notFound) {
        return const Err(DocNookFailure.corrupt(detail: 'missing'));
      }
    } on FileSystemException {
      return const Err(DocNookFailure.permissionDenied());
    }

    final DocFormat format;
    try {
      format = await Isolate.run(
        () => FileTypeDetector.detectFile(
          path,
          name: name,
          mimeHint: request.mime,
        ),
      );
    } on FileSystemException {
      return const Err(DocNookFailure.permissionDenied());
    }

    final id = await _documents.upsert(
      uri: _canonicalUri(request.uri),
      name: name,
      format: format,
      source: request.source,
      extension: FileTypeDetector.extensionOf(name),
      sizeBytes: stat.size,
      modifiedAt: stat.modified,
    );
    await _documents.markOpened(id);

    return Ok(
      OpenedDocument(
        documentId: id,
        path: path,
        name: name,
        format: format,
        request: request,
        sizeBytes: stat.size,
      ),
    );
  }

  static String _canonicalUri(String uri) =>
      uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;

  /// A readable local path for [request.uri]. Content URIs are copied into
  /// the cache once per (uri, size); later opens reuse the copy.
  Future<Result<String>> _localFile(OpenRequest request) async {
    final uri = request.uri;
    if (!uri.startsWith('content://')) {
      final path = _canonicalUri(uri);
      return File(path).existsSync()
          ? Ok(path)
          : const Err(DocNookFailure.corrupt(detail: 'missing'));
    }

    final ext = FileTypeDetector.extensionOf(request.name);
    final key = sha1
        .convert(utf8.encode('$uri|${request.size ?? ''}'))
        .toString();
    final dest = p.join(_paths.opened, ext.isEmpty ? key : '$key.$ext');
    final cached = File(dest);
    if (cached.existsSync() &&
        (request.size == null || cached.lengthSync() == request.size)) {
      // Touch so the LRU trim keeps recently opened copies.
      await cached.setLastAccessed(DateTime.now());
      return Ok(dest);
    }

    final copied = await _platform.copyToCache(uri, dest);
    return switch (copied) {
      Ok() => Ok(dest),
      Err(:final failure) => Err(failure),
    };
  }
}

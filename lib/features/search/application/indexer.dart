import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:docnook/app/providers.dart';
import 'package:docnook/data/repositories/search_repository.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(databaseProvider)),
);

final indexerProvider = Provider<Indexer>((ref) {
  final indexer = Indexer(ref);
  ref.onDispose(indexer.dispose);
  return indexer;
});

/// Text larger than this is indexed only up to the limit.
const _maxTextBytes = 8 * 1024 * 1024;

/// Splits plain text into ~4 KB chunks on line boundaries (BLUEPRINT 6.1).
List<IndexChunk> chunkText(String text, {int size = 4096}) {
  final chunks = <IndexChunk>[];
  var start = 0;
  while (start < text.length) {
    var end = start + size;
    if (end >= text.length) {
      end = text.length;
    } else {
      final newline = text.lastIndexOf('\n', end);
      if (newline > start + size ~/ 2) end = newline + 1;
    }
    chunks.add(IndexChunk(chunks.length + 1, text.substring(start, end)));
    start = end;
  }
  return chunks;
}

List<IndexChunk> _readTextChunks(String path) {
  final file = File(path).openSync();
  try {
    final length = file.lengthSync();
    final bytes = file.readSync(
      length < _maxTextBytes ? length : _maxTextBytes,
    );
    return chunkText(utf8.decode(bytes, allowMalformed: true));
  } finally {
    file.closeSync();
  }
}

/// Indexes document text for search, one document at a time, only while the
/// app is idle (BLUEPRINT 6.2). PDF text comes from PDFium on the main
/// isolate (it already works natively and asynchronously); plain text is
/// read in a background isolate.
class Indexer {
  Indexer(this._ref);

  final Ref _ref;
  bool _running = false;
  bool _disposed = false;
  int _pauses = 0;

  SearchRepository get _search => _ref.read(searchRepositoryProvider);

  /// Viewers call this while a document is open so indexing never competes
  /// with reading. Returns a function that ends the pause.
  void Function() pause() {
    _pauses++;
    var ended = false;
    return () {
      if (ended) return;
      ended = true;
      _pauses--;
      if (_pauses == 0) kick();
    };
  }

  void dispose() => _disposed = true;

  /// Starts the background loop if it is not already running.
  void kick() {
    if (_running || _disposed) return;
    unawaited(_loop());
  }

  Future<void> _loop() async {
    _running = true;
    try {
      while (!_disposed) {
        if (_pauses > 0) return;
        final batch = await _search.pending(
          types: const ['pdf', 'text', 'markdown'],
          limit: 10,
        );
        if (batch.isEmpty) return;
        for (final doc in batch) {
          if (_pauses > 0 || _disposed) return;
          await indexDocument(doc);
          // Let frames and user work through between documents.
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }
      }
    } finally {
      _running = false;
    }
  }

  /// Indexes one document from [localPath] (a readable copy) or its own
  /// path. Content URIs without a local copy are skipped until opened.
  Future<void> indexDocument(DocumentInfo doc, {String? localPath}) async {
    final path = localPath ?? (doc.isContentUri ? null : doc.uri);
    if (path == null || !File(path).existsSync()) {
      await _search.markSkipped(doc.id);
      return;
    }
    try {
      final chunks = switch (doc.type) {
        DocType.pdf => await _pdfChunks(path),
        DocType.text ||
        DocType.markdown => await Isolate.run(() => _readTextChunks(path)),
        _ => null,
      };
      if (chunks == null) {
        await _search.markSkipped(doc.id);
      } else {
        await _search.store(doc, chunks);
      }
    } on _Interrupted {
      // Left as 'none'; picked up again when the app is idle.
    } on Object {
      // Password-protected or damaged files stay searchable by name only.
      await _search.markFailed(doc.id);
    }
  }

  Future<List<IndexChunk>?> _pdfChunks(String path) async {
    // No password provider: encrypted PDFs throw and are marked failed,
    // so their text never enters the index (passwords are never stored).
    final document = await PdfDocument.openFile(
      path,
      firstAttemptByEmptyPassword: true,
    );
    try {
      final chunks = <IndexChunk>[];
      var total = 0;
      for (final page in document.pages) {
        if (_pauses > 0 || _disposed) throw const _Interrupted();
        final text = await page.loadText();
        final value = text?.fullText ?? '';
        total += value.length;
        chunks.add(IndexChunk(page.pageNumber, value));
        if (total > SearchRepository.maxBodyChars) break;
      }
      return chunks;
    } finally {
      await document.dispose();
    }
  }
}

/// Indexing stopped because a document was opened; nothing is saved.
final class _Interrupted implements Exception {
  const _Interrupted();
}

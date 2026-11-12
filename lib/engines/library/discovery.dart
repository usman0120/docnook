import 'dart:io';

import 'package:docnook/data/files/file_type_detector.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:path/path.dart' as p;

/// A document found on storage.
final class FoundFile {
  const FoundFile({
    required this.uri,
    required this.name,
    required this.size,
    required this.modifiedMs,
  });

  /// Absolute path, or a `content://` document URI for granted folders.
  final String uri;
  final String name;
  final int size;
  final int modifiedMs;
}

/// What to walk and what to skip.
final class DiscoveryRequest {
  const DiscoveryRequest({
    required this.root,
    this.includeHidden = false,
    this.maxFiles = 50000,
  });

  final String root;
  final bool includeHidden;
  final int maxFiles;
}

/// Folder names never worth walking: app data, caches and trash.
const _skippedNames = {
  'android',
  'lost+found',
  'cache',
  '.cache',
  'thumbnails',
  '.thumbnails',
  '.trash',
  '.trashed',
  'node_modules',
};

/// True for names DocNook can open, decided by extension (cheap; the real
/// type is sniffed when the file is opened).
bool isDocumentName(String name) {
  final ext = FileTypeDetector.extensionOf(name);
  if (ext.isEmpty) return false;
  // Code and config files are openable but would flood the library.
  if (FileTypeDetector.codeExtensions.contains(ext) &&
      ext != 'json' &&
      ext != 'xml') {
    return false;
  }
  return FileTypeDetector.isSupportedExtension(ext);
}

/// Walks [DiscoveryRequest.root] for documents. A [JobBody]: runs in an
/// isolate so the UI never waits on the file system (FR-ORG-01).
List<FoundFile> discoverFiles(DiscoveryRequest request, JobContext context) {
  final found = <FoundFile>[];
  final pending = <Directory>[Directory(request.root)];
  var lastReport = 0;

  while (pending.isNotEmpty && found.length < request.maxFiles) {
    final dir = pending.removeLast();
    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } on FileSystemException {
      continue; // unreadable folder
    }
    for (final entity in entries) {
      final name = p.basename(entity.path);
      if (!request.includeHidden && name.startsWith('.')) continue;
      if (entity is Directory) {
        if (!_skippedNames.contains(name.toLowerCase())) pending.add(entity);
      } else if (entity is File && isDocumentName(name)) {
        try {
          final stat = entity.statSync();
          if (stat.size == 0) continue;
          found.add(
            FoundFile(
              uri: entity.path,
              name: name,
              size: stat.size,
              modifiedMs: stat.modified.toUtc().millisecondsSinceEpoch,
            ),
          );
        } on FileSystemException {
          continue;
        }
      }
    }
    if (found.length - lastReport >= 50) {
      lastReport = found.length;
      // Progress is unknown in advance; report the count as the label.
      context.progress(0, '${found.length}');
    }
  }
  context.progress(1, '${found.length}');
  return found;
}

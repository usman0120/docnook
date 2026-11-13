import 'dart:io';

import 'package:docnook/engines/jobs/job_runner.dart';

/// For each of [paths] (plain file paths), whether the file still exists.
/// Runs in a JobRunner isolate: a large library means thousands of stat
/// calls.
List<bool> filesExist(List<String> paths, JobContext context) {
  final out = List<bool>.filled(paths.length, true);
  for (var i = 0; i < paths.length; i++) {
    out[i] = _exists(paths[i]);
    if (i % 200 == 0) context.progress(i / paths.length);
  }
  return out;
}

bool _exists(String path) {
  try {
    return File(path).existsSync();
  } on FileSystemException {
    // Can't tell (for example, no permission): keep the document.
    return true;
  }
}

/// True for a library location that is a plain file path rather than a
/// content URI.
bool isFilePath(String uri) =>
    !uri.contains('://') || uri.startsWith('file://');

/// The file path for a plain path or file:// URI.
String filePathOf(String uri) =>
    uri.startsWith('file://') ? Uri.parse(uri).toFilePath(windows: false) : uri;

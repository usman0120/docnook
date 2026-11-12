import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// App-private folders (BLUEPRINT 5.6, 8.1). Created on first use.
final class AppPaths {
  AppPaths._(this.cache, this.files);

  static Future<AppPaths> resolve() async {
    final cache = await getApplicationCacheDirectory();
    final files = await getApplicationSupportDirectory();
    return AppPaths._(cache.path, files.path);
  }

  /// For tests.
  factory AppPaths.at(String root) =>
      AppPaths._(p.join(root, 'cache'), p.join(root, 'files'));

  final String cache;
  final String files;

  /// Local copies of files opened through content URIs.
  String get opened => _dir(cache, 'opened');

  /// Work-in-progress outputs; swept after 24 h.
  String get tmp => _dir(cache, 'tmp');

  /// Decrypted vault files; wiped on close and on every start.
  String get vaultTmp => _dir(cache, 'vault_tmp');
  String get thumbs => _dir(cache, 'thumbs');
  String get share => _dir(cache, 'share');
  String get scans => _dir(files, 'scans');
  String get signatures => _dir(files, 'signatures');
  String get vault => _dir(files, 'vault');
  String get database => p.join(_dir(files, 'db'), 'docnook.db');

  static String _dir(String root, String name) {
    final dir = Directory(p.join(root, name));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  /// Removes leftovers from earlier runs: old temp files and every decrypted
  /// vault file (BLUEPRINT 8.1).
  Future<void> sweep({DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(const Duration(hours: 24));
    await _deleteWhere(tmp, (stat) => stat.modified.isBefore(cutoff));
    await _deleteWhere(vaultTmp, (_) => true);
  }

  /// Keeps a cache folder under [maxBytes] by removing least recently used
  /// files first.
  static Future<void> trim(String dir, int maxBytes) async {
    final entries = <(File, FileStat)>[];
    var total = 0;
    await for (final entity in Directory(dir).list(recursive: true)) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      entries.add((entity, stat));
      total += stat.size;
    }
    if (total <= maxBytes) return;
    entries.sort((a, b) => a.$2.accessed.compareTo(b.$2.accessed));
    for (final (file, stat) in entries) {
      if (total <= maxBytes) break;
      try {
        await file.delete();
        total -= stat.size;
      } on FileSystemException {
        // In use or already gone.
      }
    }
  }

  static Future<int> sizeOf(String dir) async {
    var total = 0;
    final directory = Directory(dir);
    if (!directory.existsSync()) return 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  static Future<void> _deleteWhere(
    String dir,
    bool Function(FileStat) test,
  ) async {
    final directory = Directory(dir);
    if (!directory.existsSync()) return;
    await for (final entity in directory.list()) {
      try {
        final stat = await entity.stat();
        if (test(stat)) await entity.delete(recursive: true);
      } on FileSystemException {
        // Ignore files that vanish or are locked.
      }
    }
  }
}

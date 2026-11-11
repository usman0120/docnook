import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:docnook/core/failures.dart';

/// Limits that keep hostile archives from exhausting memory or disk
/// (BLUEPRINT 8.1, NFR-LIMIT-01).
final class ZipLimits {
  const ZipLimits({
    this.maxEntries = 10000,
    this.maxTotalBytes = 2 * 1024 * 1024 * 1024,
    this.maxRatio = 100,
    this.maxEntryBytes = 512 * 1024 * 1024,
  });

  final int maxEntries;
  final int maxTotalBytes;

  /// Uncompressed-to-compressed ratio above which a large archive is treated
  /// as a bomb. Small archives are exempt: a tiny, very repetitive sheet is
  /// harmless whatever its ratio.
  final int maxRatio;
  final int maxEntryBytes;

  static const _ratioFloorBytes = 64 * 1024 * 1024;
}

/// Read-only ZIP access used by every ZIP-based format (DOCX, XLSX, PPTX,
/// ODF, EPUB and plain archives). Opens lazily: nothing is inflated until an
/// entry is read, and the limits are checked from the directory first.
final class SafeZip {
  SafeZip._(this._input, this._archive, this._byName);

  /// Opens [path]. Throws [DocNookFailure] `corrupt` for unreadable or
  /// bomb-like archives.
  factory SafeZip.open(String path, {ZipLimits limits = const ZipLimits()}) {
    final input = InputFileStream(path);
    try {
      final archive = ZipDecoder().decodeStream(input);
      _check(archive, input.length, limits);
      return SafeZip._(input, archive, _index(archive));
    } on DocNookFailure {
      input.closeSync();
      rethrow;
    } on Object catch (error) {
      input.closeSync();
      throw DocNookFailure.corrupt(detail: 'zip: ${error.runtimeType}');
    }
  }

  /// Opens an archive held in memory (an entry inside another archive).
  factory SafeZip.fromBytes(Uint8List bytes, {ZipLimits limits = const ZipLimits()}) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      _check(archive, bytes.length, limits);
      return SafeZip._(null, archive, _index(archive));
    } on DocNookFailure {
      rethrow;
    } on Object catch (error) {
      throw DocNookFailure.corrupt(detail: 'zip: ${error.runtimeType}');
    }
  }

  final InputFileStream? _input;
  final Archive _archive;
  final Map<String, ArchiveFile> _byName;

  static Map<String, ArchiveFile> _index(Archive archive) => {
    for (final file in archive.files)
      if (file.isFile) _normalize(file.name): file,
  };

  static void _check(Archive archive, int compressedLength, ZipLimits limits) {
    if (archive.length > limits.maxEntries) {
      throw const DocNookFailure.corrupt(detail: 'zip: too many entries');
    }
    var total = 0;
    for (final file in archive.files) {
      if (file.size > limits.maxEntryBytes) {
        throw const DocNookFailure.tooLarge(detail: 'zip: entry too large');
      }
      total += file.size;
    }
    if (total > limits.maxTotalBytes) {
      throw const DocNookFailure.tooLarge(detail: 'zip: total too large');
    }
    if (total > ZipLimits._ratioFloorBytes &&
        compressedLength > 0 &&
        total ~/ compressedLength > limits.maxRatio) {
      throw const DocNookFailure.corrupt(detail: 'zip: compression ratio');
    }
  }

  /// Entry names use forward slashes and no leading slash.
  static String _normalize(String name) {
    var result = name.replaceAll(r'\', '/');
    while (result.startsWith('/')) {
      result = result.substring(1);
    }
    return result;
  }

  /// A path that is safe to create under an extraction folder, or null for
  /// entries that try to escape it (zip-slip): `..` segments, absolute paths,
  /// drive letters.
  static String? safeRelativePath(String entryName) {
    final normalized = entryName.replaceAll(r'\', '/');
    if (normalized.startsWith('/') || normalized.contains(':')) return null;
    final parts = <String>[];
    for (final part in normalized.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') return null;
      parts.add(part);
    }
    return parts.isEmpty ? null : parts.join('/');
  }

  Iterable<String> get names => _byName.keys;

  /// All entries including directories, for the archive browser.
  List<ArchiveFile> get entries => _archive.files;

  bool has(String name) => _byName.containsKey(_normalize(name));

  int sizeOf(String name) => _byName[_normalize(name)]?.size ?? 0;

  /// Finds an entry ignoring case, for producers that write `Word/Document.xml`.
  String? findIgnoreCase(String name) {
    final wanted = _normalize(name).toLowerCase();
    for (final key in _byName.keys) {
      if (key.toLowerCase() == wanted) return key;
    }
    return null;
  }

  /// Inflates one entry, or returns null when it does not exist.
  Uint8List? bytes(String name) {
    final file = _byName[_normalize(name)];
    if (file == null) return null;
    try {
      final data = file.readBytes();
      // Release the inflated copy held by the archive; callers own [data].
      file.clear();
      return data;
    } on Object catch (error) {
      throw DocNookFailure.corrupt(detail: 'zip entry: ${error.runtimeType}');
    }
  }

  /// Reads an entry as text (UTF-8, or UTF-16 when it has a byte-order mark).
  String? text(String name) {
    final data = bytes(name);
    return data == null ? null : decodeText(data);
  }

  static String decodeText(Uint8List data) {
    if (data.length >= 2) {
      final littleEndian = data[0] == 0xFF && data[1] == 0xFE;
      final bigEndian = data[0] == 0xFE && data[1] == 0xFF;
      if (littleEndian || bigEndian) {
        final view = ByteData.sublistView(data);
        final units = Uint16List((data.length - 2) ~/ 2);
        for (var i = 0; i < units.length; i++) {
          units[i] = view.getUint16(2 + i * 2, littleEndian ? Endian.little : Endian.big);
        }
        return String.fromCharCodes(units);
      }
    }
    return utf8.decode(data, allowMalformed: true);
  }

  void close() {
    _archive.clearSync();
    _input?.closeSync();
  }
}

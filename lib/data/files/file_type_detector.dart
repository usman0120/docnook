import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:docnook/domain/entities/doc_type.dart';

/// Random-access bytes to sniff. Implemented over a file and, in tests, over
/// an in-memory buffer.
abstract interface class ByteSource {
  int get length;

  /// Reads up to [count] bytes at [offset]; shorter at end of data.
  Uint8List read(int offset, int count);
}

final class MemoryByteSource implements ByteSource {
  MemoryByteSource(this._bytes);
  final Uint8List _bytes;

  @override
  int get length => _bytes.length;

  @override
  Uint8List read(int offset, int count) {
    if (offset >= _bytes.length || count <= 0) return Uint8List(0);
    final end = (offset + count).clamp(0, _bytes.length);
    return Uint8List.sublistView(_bytes, offset, end);
  }
}

final class FileByteSource implements ByteSource {
  FileByteSource(this._file) : length = _file.lengthSync();
  final RandomAccessFile _file;

  @override
  final int length;

  @override
  Uint8List read(int offset, int count) {
    if (offset >= length || count <= 0) return Uint8List(0);
    _file.setPositionSync(offset);
    return _file.readSync(count);
  }
}

/// Decides a file's real format: magic bytes first, then extension, then the
/// MIME type the sender claimed (BLUEPRINT 5.2). Renamed and extension-less
/// files still open in the right viewer, and `application/octet-stream` from
/// WhatsApp or a file manager is never trusted.
abstract final class FileTypeDetector {
  static const _headSize = 4096;

  /// Central directories larger than this are not inspected; the file is then
  /// classified by extension. Keeps hostile archives from costing memory.
  static const _maxCentralDirectory = 4 * 1024 * 1024;

  static DocFormat detectFile(String path, {String? name, String? mimeHint}) {
    final file = File(path).openSync();
    try {
      return detect(
        FileByteSource(file),
        name: name ?? path,
        mimeHint: mimeHint,
      );
    } finally {
      file.closeSync();
    }
  }

  static DocFormat detect(ByteSource source, {String? name, String? mimeHint}) {
    final ext = extensionOf(name);
    final head = source.read(0, _headSize);

    final byMagic = _byMagic(source, head, ext);
    if (byMagic != null) return byMagic;

    final byExt = formatForExtension(ext);
    if (byExt != null && _isTextual(byExt)) {
      // A textual extension on binary content (a renamed blob) is not text.
      return _looksLikeText(head) ? byExt : DocFormat.unknown;
    }
    if (byExt != null) return byExt;

    final byMime = _formatForMime(mimeHint);
    if (byMime != null && (!_isTextual(byMime) || _looksLikeText(head))) {
      return byMime;
    }

    if (head.isNotEmpty && _looksLikeText(head)) return DocFormat.plainText;
    return DocFormat.unknown;
  }

  /// Lower-case extension without the dot, or '' when there is none.
  static String extensionOf(String? name) {
    if (name == null) return '';
    final slash = name.lastIndexOf(RegExp(r'[/\\]'));
    final base = slash >= 0 ? name.substring(slash + 1) : name;
    final dot = base.lastIndexOf('.');
    if (dot <= 0 || dot == base.length - 1) return '';
    return base.substring(dot + 1).toLowerCase();
  }

  /// Format implied by an extension alone. Used by the discovery scanner to
  /// decide which files are worth indexing without opening each one.
  static DocFormat? formatForExtension(String ext) =>
      _byExtension[ext] ?? (codeExtensions.contains(ext) ? DocFormat.code : null);

  static bool isSupportedExtension(String ext) =>
      formatForExtension(ext) != null;

  static const codeExtensions = <String>{
    'json', 'xml', 'yaml', 'yml', 'ini', 'toml', 'conf', 'cfg', 'properties',
    'html', 'htm', 'css', 'scss', 'js', 'mjs', 'ts', 'jsx', 'tsx', 'dart',
    'java', 'kt', 'kts', 'swift', 'c', 'h', 'cpp', 'hpp', 'cc', 'cs', 'go',
    'rs', 'py', 'rb', 'php', 'pl', 'lua', 'r', 'sql', 'sh', 'bash', 'bat',
    'ps1', 'gradle', 'tex', 'srt', 'vtt', 'env', 'gitignore', 'diff', 'patch',
  };

  static const _byExtension = <String, DocFormat>{
    'pdf': DocFormat.pdf,
    'docx': DocFormat.docx,
    'docm': DocFormat.docx,
    'dotx': DocFormat.dotx,
    'odt': DocFormat.odt,
    'doc': DocFormat.doc,
    'dot': DocFormat.doc,
    'rtf': DocFormat.rtf,
    'xlsx': DocFormat.xlsx,
    'xlsm': DocFormat.xlsm,
    'ods': DocFormat.ods,
    'xls': DocFormat.xls,
    'csv': DocFormat.csv,
    'tsv': DocFormat.tsv,
    'tab': DocFormat.tsv,
    'pptx': DocFormat.pptx,
    'ppsx': DocFormat.pptx,
    'ppt': DocFormat.ppt,
    'pps': DocFormat.ppt,
    'txt': DocFormat.plainText,
    'text': DocFormat.plainText,
    'log': DocFormat.plainText,
    'md': DocFormat.markdown,
    'markdown': DocFormat.markdown,
    'epub': DocFormat.epub,
    'jpg': DocFormat.jpeg,
    'jpeg': DocFormat.jpeg,
    'png': DocFormat.png,
    'webp': DocFormat.webp,
    'gif': DocFormat.gif,
    'bmp': DocFormat.bmp,
    'heic': DocFormat.heic,
    'heif': DocFormat.heic,
    'zip': DocFormat.zip,
  };

  static DocFormat? _formatForMime(String? mime) {
    if (mime == null) return null;
    final clean = mime.split(';').first.trim().toLowerCase();
    if (clean.isEmpty || clean == 'application/octet-stream') return null;
    for (final format in DocFormat.values) {
      if (format.mime == clean && format != DocFormat.code) return format;
    }
    return switch (clean) {
      'text/rtf' || 'application/x-rtf' => DocFormat.rtf,
      'text/comma-separated-values' || 'application/csv' => DocFormat.csv,
      'text/x-markdown' => DocFormat.markdown,
      'application/json' ||
      'application/xml' ||
      'text/xml' ||
      'text/html' => DocFormat.code,
      'image/jpg' => DocFormat.jpeg,
      'image/heif' => DocFormat.heic,
      'application/x-zip-compressed' => DocFormat.zip,
      _ => clean.startsWith('text/') ? DocFormat.plainText : null,
    };
  }

  static bool _isTextual(DocFormat f) =>
      f == DocFormat.plainText ||
      f == DocFormat.code ||
      f == DocFormat.markdown ||
      f == DocFormat.csv ||
      f == DocFormat.tsv;

  static DocFormat? _byMagic(ByteSource source, Uint8List head, String ext) {
    if (head.length < 4) return null;

    // PDF: the marker may sit after a little junk, so search the first 1 KB.
    final pdfLimit = head.length < 1024 ? head.length : 1024;
    if (_indexOf(head, const [0x25, 0x50, 0x44, 0x46, 0x2D], pdfLimit) >= 0) {
      return DocFormat.pdf;
    }

    if (_startsWith(head, const [0x50, 0x4B, 0x03, 0x04]) ||
        _startsWith(head, const [0x50, 0x4B, 0x05, 0x06])) {
      return _zipContainer(source, head, ext);
    }

    if (_startsWith(head, const [
      0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, //
    ])) {
      return _oleContainer(source, head, ext);
    }

    if (_startsWith(head, const [0x7B, 0x5C, 0x72, 0x74, 0x66])) {
      return DocFormat.rtf; // {\rtf
    }
    if (_startsWith(head, const [0xFF, 0xD8, 0xFF])) return DocFormat.jpeg;
    if (_startsWith(head, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return DocFormat.png;
    }
    if (_startsWith(head, const [0x47, 0x49, 0x46, 0x38])) return DocFormat.gif;
    if (head.length >= 12 &&
        _startsWith(head, const [0x52, 0x49, 0x46, 0x46]) &&
        _matchesAt(head, 8, const [0x57, 0x45, 0x42, 0x50])) {
      return DocFormat.webp;
    }
    if (head.length >= 12 && _matchesAt(head, 4, const [0x66, 0x74, 0x79, 0x70])) {
      final brand = ascii.decode(head.sublist(8, 12), allowInvalid: true);
      const heifBrands = {'heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1', 'heim'};
      if (heifBrands.contains(brand)) return DocFormat.heic;
    }
    // "BM" is too short to trust alone: also require a sane header size field.
    if (head.length >= 18 && head[0] == 0x42 && head[1] == 0x4D) {
      final dib = head[14] | head[15] << 8 | head[16] << 16 | head[17] << 24;
      if (const {12, 40, 52, 56, 64, 108, 124}.contains(dib)) {
        return DocFormat.bmp;
      }
    }
    return null;
  }

  /// DOCX, XLSX, PPTX, ODT, ODS and EPUB are all ZIP files; tell them apart by
  /// what is inside rather than by name.
  static DocFormat _zipContainer(ByteSource source, Uint8List head, String ext) {
    // ODF and EPUB store an uncompressed `mimetype` entry first.
    final declared = _leadingMimetypeEntry(head);
    if (declared != null) {
      if (declared == DocFormat.epub.mime) return DocFormat.epub;
      if (declared.startsWith('application/vnd.oasis.opendocument.text')) {
        return DocFormat.odt;
      }
      if (declared.startsWith('application/vnd.oasis.opendocument.spreadsheet')) {
        return DocFormat.ods;
      }
    }

    final names = _zipEntryNames(source);
    if (names != null) {
      if (names.contains('[Content_Types].xml')) {
        if (names.any((n) => n.startsWith('word/'))) {
          return ext == 'dotx' ? DocFormat.dotx : DocFormat.docx;
        }
        if (names.any((n) => n.startsWith('xl/'))) {
          return ext == 'xlsm' ? DocFormat.xlsm : DocFormat.xlsx;
        }
        if (names.any((n) => n.startsWith('ppt/'))) return DocFormat.pptx;
      }
      if (names.contains('META-INF/container.xml')) return DocFormat.epub;
      return DocFormat.zip;
    }

    // Directory unreadable or too large: fall back to the name, but only for
    // formats that really are ZIP containers.
    const zipBased = {
      DocFormat.docx, DocFormat.dotx, DocFormat.xlsx, DocFormat.xlsm,
      DocFormat.pptx, DocFormat.odt, DocFormat.ods, DocFormat.epub, //
    };
    final byExt = _byExtension[ext];
    return byExt != null && zipBased.contains(byExt) ? byExt : DocFormat.zip;
  }

  static String? _leadingMimetypeEntry(Uint8List head) {
    if (head.length < 38) return null;
    final data = ByteData.sublistView(head);
    final method = data.getUint16(8, Endian.little);
    final size = data.getUint32(18, Endian.little);
    final nameLength = data.getUint16(26, Endian.little);
    final extraLength = data.getUint16(28, Endian.little);
    if (method != 0 || nameLength != 8 || size == 0 || size > 200) return null;
    final name = ascii.decode(head.sublist(30, 38), allowInvalid: true);
    if (name != 'mimetype') return null;
    final start = 38 + extraLength;
    if (start + size > head.length) return null;
    return ascii
        .decode(head.sublist(start, start + size), allowInvalid: true)
        .trim();
  }

  /// Entry names from the ZIP central directory, or null if it cannot be read
  /// cheaply. Reads only the directory, never entry data.
  static Set<String>? _zipEntryNames(ByteSource source) {
    const eocdMin = 22;
    if (source.length < eocdMin) return null;
    final tailSize = source.length < 65557 ? source.length : 65557;
    final tailOffset = source.length - tailSize;
    final tail = source.read(tailOffset, tailSize);

    var eocd = -1;
    for (var i = tail.length - eocdMin; i >= 0; i--) {
      if (tail[i] == 0x50 &&
          tail[i + 1] == 0x4B &&
          tail[i + 2] == 0x05 &&
          tail[i + 3] == 0x06) {
        eocd = i;
        break;
      }
    }
    if (eocd < 0) return null;

    final end = ByteData.sublistView(tail, eocd);
    final dirSize = end.getUint32(12, Endian.little);
    final dirOffset = end.getUint32(16, Endian.little);
    if (dirSize == 0 ||
        dirSize > _maxCentralDirectory ||
        dirOffset == 0xFFFFFFFF ||
        dirOffset + dirSize > source.length) {
      return null;
    }

    final dir = source.read(dirOffset, dirSize);
    final view = ByteData.sublistView(dir);
    final names = <String>{};
    var pos = 0;
    while (pos + 46 <= dir.length) {
      if (view.getUint32(pos, Endian.little) != 0x02014B50) break;
      final nameLength = view.getUint16(pos + 28, Endian.little);
      final extraLength = view.getUint16(pos + 30, Endian.little);
      final commentLength = view.getUint16(pos + 32, Endian.little);
      final nameEnd = pos + 46 + nameLength;
      if (nameEnd > dir.length) break;
      names.add(utf8.decode(dir.sublist(pos + 46, nameEnd), allowMalformed: true));
      pos = nameEnd + extraLength + commentLength;
    }
    return names;
  }

  /// Old .doc/.xls/.ppt share one container format; the stream names in its
  /// directory say which application wrote it.
  static DocFormat _oleContainer(ByteSource source, Uint8List head, String ext) {
    final byExt = _byExtension[ext];
    final fallback = byExt != null && byExt.isLegacyOffice
        ? byExt
        : DocFormat.unknown;
    if (head.length < 512) return fallback;

    final header = ByteData.sublistView(head);
    final sectorShift = header.getUint16(30, Endian.little);
    if (sectorShift != 9 && sectorShift != 12) return fallback;
    final sectorSize = 1 << sectorShift;
    final firstDirSector = header.getUint32(48, Endian.little);
    if (firstDirSector > 0x00FFFFFF) return fallback;

    final dir = source.read((firstDirSector + 1) * sectorSize, sectorSize);
    final dirView = ByteData.sublistView(dir);
    for (var entry = 0; entry + 128 <= dir.length; entry += 128) {
      final nameBytes = dirView.getUint16(entry + 64, Endian.little);
      if (nameBytes < 2 || nameBytes > 64) continue;
      final units = <int>[
        for (var i = 0; i < nameBytes - 2; i += 2)
          dirView.getUint16(entry + i, Endian.little),
      ];
      switch (String.fromCharCodes(units)) {
        case 'WordDocument':
          return DocFormat.doc;
        case 'Workbook' || 'Book':
          return DocFormat.xls;
        case 'PowerPoint Document':
          return DocFormat.ppt;
      }
    }
    return fallback;
  }

  /// True when [head] reads as text: valid UTF-8 or UTF-16 with a BOM, and no
  /// control bytes that only binary data contains.
  static bool _looksLikeText(Uint8List head) {
    if (head.isEmpty) return true;
    if (head.length >= 2 &&
        ((head[0] == 0xFF && head[1] == 0xFE) ||
            (head[0] == 0xFE && head[1] == 0xFF))) {
      return true;
    }
    var suspicious = 0;
    for (final byte in head) {
      if (byte == 0) return false;
      if (byte < 0x09 || (byte > 0x0D && byte < 0x20 && byte != 0x1B)) {
        suspicious++;
      }
    }
    if (suspicious * 100 > head.length) return false;
    try {
      // The head may cut a multi-byte character; drop up to 3 trailing bytes.
      var end = head.length;
      while (end > 0 && head.length - end < 3 && (head[end - 1] & 0xC0) == 0x80) {
        end--;
      }
      if (end > 0 && head[end - 1] >= 0xC0) end--;
      utf8.decode(Uint8List.sublistView(head, 0, end));
      return true;
    } on FormatException {
      // Legacy 8-bit encodings (ANSI CSVs) are still text if mostly printable.
      return suspicious == 0;
    }
  }

  static bool _startsWith(Uint8List data, List<int> magic) =>
      _matchesAt(data, 0, magic);

  static bool _matchesAt(Uint8List data, int offset, List<int> magic) {
    if (data.length < offset + magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (data[offset + i] != magic[i]) return false;
    }
    return true;
  }

  static int _indexOf(Uint8List data, List<int> needle, int limit) {
    final last = limit - needle.length;
    for (var i = 0; i <= last; i++) {
      if (_matchesAt(data, i, needle)) return i;
    }
    return -1;
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:docnook/core/failures.dart';

/// Read-only reader for the Compound File Binary format (the container of
/// old .doc, .xls and .ppt files). Enough to read named streams.
final class OleFile {
  OleFile._(
    this._bytes,
    this._sectorSize,
    this._fat,
    this._miniFat,
    this._miniStream,
    this._entries,
  );

  factory OleFile.parse(Uint8List bytes) {
    if (bytes.length < 512 ||
        !_startsWith(bytes, const [
          0xD0,
          0xCF,
          0x11,
          0xE0,
          0xA1,
          0xB1,
          0x1A,
          0xE1,
        ])) {
      throw const DocNookFailure.corrupt(detail: 'ole: header');
    }
    final h = ByteData.sublistView(bytes);
    final shift = h.getUint16(30, Endian.little);
    if (shift != 9 && shift != 12) {
      throw const DocNookFailure.corrupt(detail: 'ole: sector size');
    }
    final sectorSize = 1 << shift;
    final miniShift = h.getUint16(32, Endian.little);
    if (miniShift != 6) {
      throw const DocNookFailure.corrupt(detail: 'ole: mini sector');
    }
    final fatSectors = h.getUint32(44, Endian.little);
    final firstDir = h.getUint32(48, Endian.little);
    final firstMiniFat = h.getUint32(60, Endian.little);
    final miniFatCount = h.getUint32(64, Endian.little);
    var difSector = h.getUint32(68, Endian.little);
    final difCount = h.getUint32(72, Endian.little);

    int sectorOffset(int s) => (s + 1) * sectorSize;
    bool valid(int s) =>
        s < 0xFFFFFFFA && sectorOffset(s) + sectorSize <= bytes.length;

    // FAT sector list: 109 in the header, the rest in the DIFAT chain.
    final fatList = <int>[];
    for (var i = 0; i < 109 && fatList.length < fatSectors; i++) {
      final s = h.getUint32(76 + i * 4, Endian.little);
      if (s >= 0xFFFFFFFA) break;
      fatList.add(s);
    }
    for (
      var n = 0;
      n < difCount && valid(difSector) && fatList.length < fatSectors;
      n++
    ) {
      final base = sectorOffset(difSector);
      final perSector = sectorSize ~/ 4 - 1;
      for (var i = 0; i < perSector && fatList.length < fatSectors; i++) {
        final s = h.getUint32(base + i * 4, Endian.little);
        if (s >= 0xFFFFFFFA) break;
        fatList.add(s);
      }
      difSector = h.getUint32(base + perSector * 4, Endian.little);
    }

    final fat = Uint32List(fatList.length * sectorSize ~/ 4);
    var k = 0;
    for (final s in fatList) {
      if (!valid(s)) throw const DocNookFailure.corrupt(detail: 'ole: fat');
      final base = sectorOffset(s);
      for (var i = 0; i < sectorSize ~/ 4; i++) {
        fat[k++] = h.getUint32(base + i * 4, Endian.little);
      }
    }

    Uint8List chain(int start, {int? size}) {
      final out = BytesBuilder(copy: false);
      var s = start;
      var guard = 0;
      while (s < 0xFFFFFFFA && guard++ < fat.length + 1) {
        if (!valid(s)) break;
        out.add(
          Uint8List.sublistView(
            bytes,
            sectorOffset(s),
            sectorOffset(s) + sectorSize,
          ),
        );
        if (size != null && out.length >= size) break;
        s = s < fat.length ? fat[s] : 0xFFFFFFFE;
      }
      final data = out.toBytes();
      return size != null && data.length > size
          ? Uint8List.sublistView(data, 0, size)
          : data;
    }

    // Directory.
    final dir = chain(firstDir);
    final entries = <String, _Entry>{};
    _Entry? root;
    for (var off = 0; off + 128 <= dir.length; off += 128) {
      final d = ByteData.sublistView(dir, off, off + 128);
      final nameLen = d.getUint16(64, Endian.little);
      final type = d.getUint8(66);
      if (type == 0 || nameLen < 2 || nameLen > 64) continue;
      final units = [
        for (var i = 0; i < nameLen - 2; i += 2) d.getUint16(i, Endian.little),
      ];
      final entry = _Entry(
        String.fromCharCodes(units),
        type,
        d.getUint32(116, Endian.little),
        d.getUint32(120, Endian.little),
      );
      if (type == 5) {
        root = entry;
      } else {
        entries.putIfAbsent(entry.name, () => entry);
      }
    }

    final miniStream = root == null
        ? Uint8List(0)
        : chain(root.start, size: root.size);
    final miniFatBytes = miniFatCount == 0 ? Uint8List(0) : chain(firstMiniFat);
    final miniFat = Uint32List(miniFatBytes.length ~/ 4);
    final mf = ByteData.sublistView(miniFatBytes);
    for (var i = 0; i < miniFat.length; i++) {
      miniFat[i] = mf.getUint32(i * 4, Endian.little);
    }

    return OleFile._(bytes, sectorSize, fat, miniFat, miniStream, entries)
      .._chain = chain;
  }

  final Uint8List _bytes;
  final int _sectorSize;
  final Uint32List _fat;
  final Uint32List _miniFat;
  final Uint8List _miniStream;
  final Map<String, _Entry> _entries;
  late Uint8List Function(int start, {int? size}) _chain;

  static bool _startsWith(Uint8List b, List<int> m) {
    for (var i = 0; i < m.length; i++) {
      if (b[i] != m[i]) return false;
    }
    return true;
  }

  bool has(String name) => _entries.containsKey(name);

  /// The bytes of stream [name], or null.
  Uint8List? stream(String name) {
    final e = _entries[name];
    if (e == null || e.type != 2) return null;
    if (e.size > _bytes.length * 4) {
      throw const DocNookFailure.corrupt(detail: 'ole: stream size');
    }
    if (e.size < 4096) {
      final out = BytesBuilder(copy: false);
      var s = e.start;
      var guard = 0;
      while (s < 0xFFFFFFFA &&
          guard++ <= _miniFat.length &&
          out.length < e.size) {
        final off = s * 64;
        if (off + 64 > _miniStream.length) break;
        out.add(Uint8List.sublistView(_miniStream, off, off + 64));
        s = s < _miniFat.length ? _miniFat[s] : 0xFFFFFFFE;
      }
      final data = out.toBytes();
      return data.length > e.size
          ? Uint8List.sublistView(data, 0, e.size)
          : data;
    }
    return _chain(e.start, size: e.size);
  }

  // Kept for debugging sector math.
  int get sectorSize => _sectorSize;
  int get fatLength => _fat.length;
}

final class _Entry {
  const _Entry(this.name, this.type, this.start, this.size);
  final String name;
  final int type; // 1 storage, 2 stream, 5 root
  final int start;
  final int size;
}

/// Extracts readable text from legacy Office files (FR-READ-07).
abstract final class LegacyText {
  /// Paragraphs of a Word 97–2003 document.
  static List<String> doc(Uint8List bytes) {
    final ole = OleFile.parse(bytes);
    final word = ole.stream('WordDocument');
    if (word == null || word.length < 0x1A2) {
      throw const DocNookFailure.corrupt(detail: 'doc: stream');
    }
    final fib = ByteData.sublistView(word);
    final flags = fib.getUint16(0x0A, Endian.little);
    if (flags & 0x0100 != 0) throw const DocNookFailure.passwordRequired();
    final table = ole.stream((flags & 0x0200) != 0 ? '1Table' : '0Table');

    final text = StringBuffer();
    final fcClx = fib.getUint32(0x01A2, Endian.little);
    final lcbClx = fib.getUint32(0x01A6, Endian.little);
    if (table != null && lcbClx > 0 && fcClx + lcbClx <= table.length) {
      _readPieces(word, table, fcClx, lcbClx, text);
    } else {
      // No piece table: fall back to scanning the stream for text runs.
      text.write(_scanText(word));
    }
    return _splitParagraphs(text.toString());
  }

  static void _readPieces(
    Uint8List word,
    Uint8List table,
    int fc,
    int lcb,
    StringBuffer out,
  ) {
    final t = ByteData.sublistView(table);
    var pos = fc;
    final end = fc + lcb;
    while (pos < end) {
      final kind = table[pos];
      if (kind == 1) {
        final size = t.getUint16(pos + 1, Endian.little);
        pos += 3 + size;
      } else if (kind == 2) {
        final size = t.getUint32(pos + 1, Endian.little);
        final start = pos + 5;
        final n = (size - 4) ~/ 12;
        for (var i = 0; i < n; i++) {
          final cpStart = t.getUint32(start + i * 4, Endian.little);
          final cpEnd = t.getUint32(start + (i + 1) * 4, Endian.little);
          final pcd = start + (n + 1) * 4 + i * 8;
          var fcValue = t.getUint32(pcd + 2, Endian.little);
          final compressed = fcValue & 0x40000000 != 0;
          fcValue &= 0x3FFFFFFF;
          final count = cpEnd - cpStart;
          if (count <= 0 || count > 10000000) continue;
          if (compressed) {
            final offset = fcValue ~/ 2;
            for (var j = 0; j < count && offset + j < word.length; j++) {
              out.writeCharCode(_cp1252(word[offset + j]));
            }
          } else {
            final w = ByteData.sublistView(word);
            for (
              var j = 0;
              j < count && fcValue + j * 2 + 1 < word.length;
              j++
            ) {
              out.writeCharCode(w.getUint16(fcValue + j * 2, Endian.little));
            }
          }
        }
        return;
      } else {
        return;
      }
    }
  }

  /// Text of every slide, one entry per text box.
  static List<String> ppt(Uint8List bytes) {
    final ole = OleFile.parse(bytes);
    final stream = ole.stream('PowerPoint Document');
    if (stream == null) {
      throw const DocNookFailure.corrupt(detail: 'ppt: stream');
    }
    final out = <String>[];
    final d = ByteData.sublistView(stream);
    void walk(int start, int end, int depth) {
      var pos = start;
      while (pos + 8 <= end && depth < 20) {
        final verInst = d.getUint16(pos, Endian.little);
        final type = d.getUint16(pos + 2, Endian.little);
        final len = d.getUint32(pos + 4, Endian.little);
        final body = pos + 8;
        if (body + len > end) return;
        if ((verInst & 0x0F) == 0x0F) {
          walk(body, body + len, depth + 1); // container
        } else if (type == 0x0FA0) {
          final units = [
            for (var i = 0; i + 1 < len; i += 2)
              d.getUint16(body + i, Endian.little),
          ];
          out.add(String.fromCharCodes(units));
        } else if (type == 0x0FA8) {
          out.add(
            String.fromCharCodes([
              for (var i = 0; i < len; i++) _cp1252(stream[body + i]),
            ]),
          );
        }
        pos = body + len;
      }
    }

    walk(0, stream.length, 0);
    return [
      for (final t in out)
        if (t.trim().isNotEmpty)
          t.replaceAll('\r', '\n').replaceAll('\u000B', '\n').trim(),
    ];
  }

  /// Rows of every sheet (cells joined by tabs), prefixed by sheet names.
  static List<String> xls(Uint8List bytes) {
    final ole = OleFile.parse(bytes);
    final stream = ole.stream('Workbook') ?? ole.stream('Book');
    if (stream == null) {
      throw const DocNookFailure.corrupt(detail: 'xls: stream');
    }
    final d = ByteData.sublistView(stream);
    final sst = <String>[];
    final cells = <int, Map<int, Map<int, String>>>{}; // sheet → row → col
    var sheet = -1;
    final sheetNames = <String>[];

    // Shared strings may continue across CONTINUE records; collect them first.
    var pos = 0;
    while (pos + 4 <= stream.length) {
      final type = d.getUint16(pos, Endian.little);
      final len = d.getUint16(pos + 2, Endian.little);
      final body = pos + 4;
      if (body + len > stream.length) break;
      switch (type) {
        case 0x0085: // BOUNDSHEET
          if (len > 8) {
            final n = stream[body + 6];
            final wide = stream[body + 7] & 1 == 1;
            sheetNames.add(_xlString(stream, body + 8, n, wide));
          }
        case 0x00FC: // SST
          final parts = <Uint8List>[
            Uint8List.sublistView(stream, body, body + len),
          ];
          var next = body + len;
          while (next + 4 <= stream.length &&
              d.getUint16(next, Endian.little) == 0x003C) {
            final l = d.getUint16(next + 2, Endian.little);
            parts.add(Uint8List.sublistView(stream, next + 4, next + 4 + l));
            next += 4 + l;
          }
          sst.addAll(_readSst(parts));
        case 0x0809: // BOF
          if (len >= 4 && d.getUint16(body + 2, Endian.little) == 0x0010) {
            sheet++;
          }
        case 0x00FD: // LABELSST
          if (sheet >= 0 && len >= 10) {
            final idx = d.getUint32(body + 6, Endian.little);
            _put(
              cells,
              sheet,
              d.getUint16(body, Endian.little),
              d.getUint16(body + 2, Endian.little),
              idx < sst.length ? sst[idx] : '',
            );
          }
        case 0x0203: // NUMBER
          if (sheet >= 0 && len >= 14) {
            _put(
              cells,
              sheet,
              d.getUint16(body, Endian.little),
              d.getUint16(body + 2, Endian.little),
              _num(d.getFloat64(body + 6, Endian.little)),
            );
          }
        case 0x027E: // RK
          if (sheet >= 0 && len >= 10) {
            _put(
              cells,
              sheet,
              d.getUint16(body, Endian.little),
              d.getUint16(body + 2, Endian.little),
              _num(_rk(d.getUint32(body + 6, Endian.little))),
            );
          }
        case 0x00BD: // MULRK
          if (sheet >= 0 && len >= 6) {
            final row = d.getUint16(body, Endian.little);
            final first = d.getUint16(body + 2, Endian.little);
            final n = (len - 6) ~/ 6;
            for (var i = 0; i < n; i++) {
              _put(
                cells,
                sheet,
                row,
                first + i,
                _num(_rk(d.getUint32(body + 4 + i * 6 + 2, Endian.little))),
              );
            }
          }
        case 0x0204: // LABEL (BIFF5)
          if (sheet >= 0 && len >= 8) {
            final n = d.getUint16(body + 6, Endian.little);
            final wide = len > 8 + n && stream[body + 8] == 1;
            _put(
              cells,
              sheet,
              d.getUint16(body, Endian.little),
              d.getUint16(body + 2, Endian.little),
              _xlString(stream, body + (wide ? 9 : 8), n, wide),
            );
          }
        case 0x0006: // FORMULA: cached number result only
          if (sheet >= 0 &&
              len >= 20 &&
              d.getUint16(body + 12, Endian.little) != 0xFFFF) {
            _put(
              cells,
              sheet,
              d.getUint16(body, Endian.little),
              d.getUint16(body + 2, Endian.little),
              _num(d.getFloat64(body + 6, Endian.little)),
            );
          }
      }
      pos = body + len;
    }

    final lines = <String>[];
    final sheets = cells.keys.toList()..sort();
    for (final s in sheets) {
      lines.add(s < sheetNames.length ? sheetNames[s] : 'Sheet ${s + 1}');
      final rows = cells[s]!;
      for (final r in rows.keys.toList()..sort()) {
        final row = rows[r]!;
        final maxCol = row.keys.reduce((a, b) => a > b ? a : b);
        lines.add([for (var c = 0; c <= maxCol; c++) row[c] ?? ''].join('\t'));
      }
      lines.add('');
    }
    return lines;
  }

  static void _put(
    Map<int, Map<int, Map<int, String>>> cells,
    int sheet,
    int row,
    int col,
    String value,
  ) {
    if (row > 65535 || col > 255) return;
    ((cells[sheet] ??= {})[row] ??= {})[col] = value;
  }

  static String _num(double v) => v == v.roundToDouble() && v.abs() < 1e15
      ? v.toInt().toString()
      : v.toStringAsPrecision(10).replaceFirst(RegExp(r'\.?0+$'), '');

  static double _rk(int rk) {
    double value;
    if (rk & 2 != 0) {
      value = (rk >> 2).toSigned(30).toDouble();
    } else {
      final b = ByteData(8)..setUint32(4, rk & 0xFFFFFFFC, Endian.little);
      value = b.getFloat64(0, Endian.little);
    }
    return rk & 1 != 0 ? value / 100 : value;
  }

  static String _xlString(Uint8List b, int start, int n, bool wide) {
    if (wide) {
      final d = ByteData.sublistView(b);
      return String.fromCharCodes([
        for (var i = 0; i < n && start + i * 2 + 1 < b.length; i++)
          d.getUint16(start + i * 2, Endian.little),
      ]);
    }
    return String.fromCharCodes([
      for (var i = 0; i < n && start + i < b.length; i++) _cp1252(b[start + i]),
    ]);
  }

  /// Reads the shared string table, honouring strings split across
  /// CONTINUE records (each continuation restarts with a flags byte).
  static List<String> _readSst(List<Uint8List> parts) {
    final out = <String>[];
    var part = 0;
    var pos = 8;
    if (parts.first.length < 8) return out;
    final total = ByteData.sublistView(parts.first).getUint32(4, Endian.little);

    int byte() {
      while (part < parts.length && pos >= parts[part].length) {
        part++;
        pos = 0;
      }
      if (part >= parts.length) throw const FormatException('sst');
      return parts[part][pos++];
    }

    int u16() => byte() | byte() << 8;
    int u32() => u16() | u16() << 16;

    try {
      for (var i = 0; i < total && out.length < 200000; i++) {
        final count = u16();
        var flags = byte();
        final rich = flags & 0x08 != 0;
        final ext = flags & 0x04 != 0;
        final runs = rich ? u16() : 0;
        final extLen = ext ? u32() : 0;
        final chars = <int>[];
        while (chars.length < count) {
          if (pos >= parts[part].length) {
            part++;
            pos = 0;
            if (part >= parts.length) break;
            flags = byte(); // new option byte after a CONTINUE boundary
          }
          chars.add(flags & 1 != 0 ? u16() : byte());
        }
        for (var r = 0; r < runs * 4 + extLen; r++) {
          byte();
        }
        out.add(String.fromCharCodes(chars));
      }
    } on FormatException {
      // Truncated table: keep what was read.
    }
    return out;
  }

  static String _scanText(Uint8List word) {
    final out = StringBuffer();
    for (var i = 0x600; i < word.length; i++) {
      final b = word[i];
      if (b == 0x0D || b == 0x09 || (b >= 0x20 && b < 0x7F) || b >= 0xA0) {
        out.writeCharCode(_cp1252(b));
      }
    }
    return out.toString();
  }

  static List<String> _splitParagraphs(String text) {
    final cleaned = text
        // Field codes: keep the result between separator (0x14) and end (0x15).
        .replaceAll(RegExp('\u0013[^\u0014\u0015]*\u0014'), '')
        .replaceAll(RegExp('[\u0013\u0014\u0015]'), '')
        .replaceAll('\u0007', '\t') // cell / row marks
        .replaceAll('\u000B', '\n')
        .replaceAll('\u000C', '\r')
        .replaceAll(RegExp('[\u0000-\u0008\u000E-\u001F]'), '');
    return [
      for (final p in cleaned.split('\r')) p.replaceAll(RegExp(r'\t+$'), ''),
    ];
  }

  static int _cp1252(int b) {
    const map = {
      0x80: 0x20AC, 0x82: 0x201A, 0x84: 0x201E, 0x85: 0x2026, 0x91: 0x2018, //
      0x92: 0x2019, 0x93: 0x201C, 0x94: 0x201D, 0x95: 0x2022, 0x96: 0x2013,
      0x97: 0x2014, 0x99: 0x2122,
    };
    return map[b] ?? b;
  }

  /// Latin-1 decoding for tests.
  static String latin(List<int> b) => latin1.decode(b, allowInvalid: true);
}

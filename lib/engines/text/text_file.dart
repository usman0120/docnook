import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:docnook/engines/jobs/job_runner.dart';

/// Where every line starts in a text file, built once in an isolate so huge
/// logs can be shown by reading only the visible lines (FR-READ-05).
final class LineIndex {
  const LineIndex({
    required this.starts,
    required this.length,
    required this.encoding,
    required this.longestLine,
    required this.bomLength,
  });

  /// Byte offset of each line's first byte.
  final Int64List starts;
  final int length;

  /// 'utf8', 'utf16le', 'utf16be' or 'latin1'.
  final String encoding;

  /// Longest line in characters (approximate for UTF-8), capped at 4000.
  final int longestLine;
  final int bomLength;

  int get lineCount => starts.length;
}

/// Indexes [path]. A [JobBody].
LineIndex indexLines(String path, JobContext context) {
  final file = File(path).openSync();
  try {
    final length = file.lengthSync();
    final head = file.readSync(length < 4096 ? length : 4096);
    var encoding = 'utf8';
    var bom = 0;
    if (head.length >= 2 && head[0] == 0xFF && head[1] == 0xFE) {
      encoding = 'utf16le';
      bom = 2;
    } else if (head.length >= 2 && head[0] == 0xFE && head[1] == 0xFF) {
      encoding = 'utf16be';
      bom = 2;
    } else if (head.length >= 3 &&
        head[0] == 0xEF &&
        head[1] == 0xBB &&
        head[2] == 0xBF) {
      bom = 3;
    } else {
      try {
        utf8.decode(head.sublist(0, _safeUtf8End(head)));
      } on FormatException {
        encoding = 'latin1';
      }
    }

    final unit = encoding.startsWith('utf16') ? 2 : 1;
    final starts = <int>[bom];
    var longest = 0;
    var lineStart = bom;
    const chunk = 1 << 20;
    var offset = 0;
    var prev = -1; // last byte of the previous chunk, for UTF-16 pairs
    file.setPositionSync(0);
    while (offset < length) {
      final data = file.readSync(chunk);
      if (data.isEmpty) break;
      for (var i = 0; i < data.length; i++) {
        final pos = offset + i;
        final byte = data[i];
        final before = prev;
        prev = byte;
        if (pos < bom) continue;
        final isNewline = unit == 1
            ? byte == 0x0A
            : ((pos - bom).isOdd &&
                  (encoding == 'utf16le'
                      ? byte == 0x00 && before == 0x0A
                      : byte == 0x0A && before == 0x00));
        if (isNewline) {
          final lineLength = (pos + 1 - lineStart) ~/ unit;
          if (lineLength > longest) longest = lineLength;
          lineStart = pos + 1;
          starts.add(lineStart);
        }
      }
      offset += data.length;
      context.progress(offset / length);
    }
    if (length - lineStart > longest * unit) {
      longest = (length - lineStart) ~/ unit;
    }
    // A trailing newline does not start a real line.
    if (starts.length > 1 && starts.last >= length) starts.removeLast();
    return LineIndex(
      starts: Int64List.fromList(starts),
      length: length,
      encoding: encoding,
      longestLine: longest > 4000 ? 4000 : longest,
      bomLength: bom,
    );
  } finally {
    file.closeSync();
  }
}

int _safeUtf8End(Uint8List b) {
  var end = b.length;
  while (end > 0 && b.length - end < 3 && (b[end - 1] & 0xC0) == 0x80) {
    end--;
  }
  if (end > 0 && b[end - 1] >= 0xC0) end--;
  return end;
}

/// Reads lines from an indexed file in blocks, keeping a small cache.
class LineReader {
  LineReader(String path, this.index) : _file = File(path).openSync();

  final LineIndex index;
  final RandomAccessFile _file;
  final _cache = <int, List<String>>{};
  static const block = 200;

  /// Longest line shown, so a single huge line cannot stall a frame.
  static const maxLineChars = 4000;

  String line(int i) {
    final b = i ~/ block;
    final lines = _cache[b] ??= _readBlock(b);
    if (_cache.length > 40) _cache.remove(_cache.keys.first);
    final k = i - b * block;
    return k < lines.length ? lines[k] : '';
  }

  List<String> _readBlock(int b) {
    final first = b * block;
    final last = (first + block).clamp(0, index.lineCount);
    final start = index.starts[first];
    final end = last < index.lineCount ? index.starts[last] : index.length;
    _file.setPositionSync(start);
    final bytes = _file.readSync((end - start).clamp(0, 64 << 20));
    final out = <String>[];
    for (var i = first; i < last; i++) {
      final s = index.starts[i] - start;
      final e =
          (i + 1 < index.lineCount ? index.starts[i + 1] : index.length) -
          start;
      var text = _decode(
        Uint8List.sublistView(bytes, s, e.clamp(s, bytes.length)),
      );
      if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
      if (text.endsWith('\r')) text = text.substring(0, text.length - 1);
      if (text.length > maxLineChars) {
        text = '${text.substring(0, maxLineChars)}…';
      }
      out.add(text.replaceAll('\t', '    '));
    }
    return out;
  }

  String _decode(Uint8List b) => switch (index.encoding) {
    'utf16le' => String.fromCharCodes([
      for (var i = 0; i + 1 < b.length; i += 2) b[i] | b[i + 1] << 8,
    ]),
    'utf16be' => String.fromCharCodes([
      for (var i = 0; i + 1 < b.length; i += 2) b[i] << 8 | b[i + 1],
    ]),
    'latin1' => latin1.decode(b),
    _ => utf8.decode(b, allowMalformed: true),
  };

  void close() => _file.closeSync();
}

final class LineSearch {
  const LineSearch(this.path, this.index, this.term);
  final String path;
  final LineIndex index;
  final String term;
}

/// Line numbers containing [LineSearch.term] (case-insensitive), at most
/// 5000. A [JobBody].
List<int> searchLines(LineSearch request, JobContext context) {
  final reader = LineReader(request.path, request.index);
  try {
    final term = request.term.toLowerCase();
    final hits = <int>[];
    for (var i = 0; i < request.index.lineCount && hits.length < 5000; i++) {
      if (reader.line(i).toLowerCase().contains(term)) hits.add(i);
      if (i % 5000 == 0) context.progress(i / request.index.lineCount);
    }
    return hits;
  } finally {
    reader.close();
  }
}

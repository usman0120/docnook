import 'dart:convert';
import 'dart:typed_data';

import 'package:docnook/core/failures.dart';

/// A minimal PDF object model: just enough to read every object of a file
/// saved by PDFium and write it back, so the security writer can encrypt
/// strings and streams. Not a general PDF library.
sealed class PdfObj {
  const PdfObj();
}

/// Numbers, booleans, `null` and names are kept as their source text so they
/// round-trip byte for byte.
final class PdfRaw extends PdfObj {
  const PdfRaw(this.text);
  final String text;
}

final class PdfRef extends PdfObj {
  const PdfRef(this.number, this.generation);
  final int number;
  final int generation;
}

final class PdfStr extends PdfObj {
  const PdfStr(this.bytes);
  final Uint8List bytes;
}

final class PdfArr extends PdfObj {
  const PdfArr(this.items);
  final List<PdfObj> items;
}

final class PdfDict extends PdfObj {
  PdfDict([Map<String, PdfObj>? entries]) : entries = entries ?? {};

  /// Keys include the leading slash, e.g. `/Type`.
  final Map<String, PdfObj> entries;

  PdfObj? operator [](String key) => entries[key];
  void operator []=(String key, PdfObj value) => entries[key] = value;

  String? nameOf(String key) {
    final value = entries[key];
    return value is PdfRaw && value.text.startsWith('/') ? value.text : null;
  }
}

final class PdfStream extends PdfObj {
  const PdfStream(this.dict, this.data);
  final PdfDict dict;
  final Uint8List data;
}

/// One indirect object as found in the file.
final class PdfIndirect {
  const PdfIndirect(this.number, this.generation, this.value);
  final int number;
  final int generation;
  final PdfObj value;
}

Never _corrupt(String detail) => throw DocNookFailure.corrupt(detail: detail);

/// Recursive-descent reader over the raw file bytes.
final class PdfReader {
  PdfReader(this.bytes);

  final Uint8List bytes;
  int pos = 0;

  /// Resolves an indirect `/Length`. Set by the document loader.
  int? Function(PdfRef ref)? resolveInt;

  static bool _isWhite(int c) =>
      c == 0x20 ||
      c == 0x0A ||
      c == 0x0D ||
      c == 0x09 ||
      c == 0x0C ||
      c == 0x00;

  static bool _isDelimiter(int c) =>
      c == 0x28 || // (
      c == 0x29 || // )
      c == 0x3C || // <
      c == 0x3E || // >
      c == 0x5B || // [
      c == 0x5D || // ]
      c == 0x7B || // {
      c == 0x7D || // }
      c == 0x2F || // /
      c == 0x25; // %

  void skipWhitespace() {
    while (pos < bytes.length) {
      final c = bytes[pos];
      if (_isWhite(c)) {
        pos++;
      } else if (c == 0x25) {
        while (pos < bytes.length && bytes[pos] != 0x0A && bytes[pos] != 0x0D) {
          pos++;
        }
      } else {
        break;
      }
    }
  }

  /// Reads a bare token (number, keyword) up to whitespace or a delimiter.
  String readToken() {
    skipWhitespace();
    final start = pos;
    while (pos < bytes.length &&
        !_isWhite(bytes[pos]) &&
        !_isDelimiter(bytes[pos])) {
      pos++;
    }
    return latin1.decode(Uint8List.sublistView(bytes, start, pos));
  }

  bool _matches(String keyword) {
    if (pos + keyword.length > bytes.length) return false;
    for (var i = 0; i < keyword.length; i++) {
      if (bytes[pos + i] != keyword.codeUnitAt(i)) return false;
    }
    return true;
  }

  int readInt() {
    final token = readToken();
    return int.tryParse(token) ?? _corrupt('expected integer');
  }

  void expectKeyword(String keyword) {
    skipWhitespace();
    if (!_matches(keyword)) _corrupt('expected $keyword');
    pos += keyword.length;
  }

  /// Reads `N G obj ... endobj` at [offset].
  PdfIndirect readIndirectAt(int offset) {
    if (offset < 0 || offset >= bytes.length) _corrupt('object offset');
    pos = offset;
    final number = readInt();
    final generation = readInt();
    expectKeyword('obj');
    final value = readObject();
    skipWhitespace();
    if (value is PdfDict && _matches('stream')) {
      return PdfIndirect(number, generation, _readStream(value));
    }
    return PdfIndirect(number, generation, value);
  }

  PdfStream _readStream(PdfDict dict) {
    pos += 'stream'.length;
    // The keyword is followed by CRLF or LF (a lone CR is tolerated).
    if (pos < bytes.length && bytes[pos] == 0x0D) pos++;
    if (pos < bytes.length && bytes[pos] == 0x0A) pos++;
    final start = pos;

    int? length;
    final declared = dict['/Length'];
    if (declared is PdfRaw) {
      length = int.tryParse(declared.text);
    } else if (declared is PdfRef) {
      final saved = pos;
      length = resolveInt?.call(declared);
      pos = saved;
    }

    if (length != null && length >= 0 && start + length <= bytes.length) {
      pos = start + length;
      skipWhitespace();
      if (_matches('endstream')) {
        return PdfStream(
          dict,
          Uint8List.sublistView(bytes, start, start + length),
        );
      }
    }

    // Wrong or missing /Length: find the terminator instead.
    final end = _indexOf('endstream', start);
    if (end < 0) _corrupt('unterminated stream');
    var dataEnd = end;
    if (dataEnd > start && bytes[dataEnd - 1] == 0x0A) dataEnd--;
    if (dataEnd > start && bytes[dataEnd - 1] == 0x0D) dataEnd--;
    pos = end;
    return PdfStream(dict, Uint8List.sublistView(bytes, start, dataEnd));
  }

  int _indexOf(String needle, int from) {
    final first = needle.codeUnitAt(0);
    final last = bytes.length - needle.length;
    for (var i = from; i <= last; i++) {
      if (bytes[i] != first) continue;
      var ok = true;
      for (var j = 1; j < needle.length; j++) {
        if (bytes[i + j] != needle.codeUnitAt(j)) {
          ok = false;
          break;
        }
      }
      if (ok) return i;
    }
    return -1;
  }

  PdfObj readObject([int depth = 0]) {
    if (depth > 200) _corrupt('nesting too deep');
    skipWhitespace();
    if (pos >= bytes.length) _corrupt('unexpected end');
    final c = bytes[pos];

    if (c == 0x3C) {
      if (pos + 1 < bytes.length && bytes[pos + 1] == 0x3C) {
        return _readDict(depth);
      }
      return _readHexString();
    }
    if (c == 0x28) return _readLiteralString();
    if (c == 0x5B) return _readArray(depth);
    if (c == 0x2F) return _readName();

    final token = readToken();
    if (token.isEmpty) _corrupt('unexpected delimiter');

    // "N G R" is a reference; look ahead without consuming on failure.
    final number = int.tryParse(token);
    if (number != null && number >= 0) {
      final saved = pos;
      final second = readToken();
      final generation = int.tryParse(second);
      if (generation != null && generation >= 0) {
        skipWhitespace();
        if (pos < bytes.length && bytes[pos] == 0x52) {
          final after = pos + 1;
          if (after >= bytes.length ||
              _isWhite(bytes[after]) ||
              _isDelimiter(bytes[after])) {
            pos = after;
            return PdfRef(number, generation);
          }
        }
      }
      pos = saved;
    }
    return PdfRaw(token);
  }

  PdfRaw _readName() {
    final start = pos;
    pos++;
    while (pos < bytes.length &&
        !_isWhite(bytes[pos]) &&
        !_isDelimiter(bytes[pos])) {
      pos++;
    }
    return PdfRaw(latin1.decode(Uint8List.sublistView(bytes, start, pos)));
  }

  PdfDict _readDict(int depth) {
    pos += 2;
    final dict = PdfDict();
    while (true) {
      skipWhitespace();
      if (pos >= bytes.length) _corrupt('unterminated dictionary');
      if (bytes[pos] == 0x3E &&
          pos + 1 < bytes.length &&
          bytes[pos + 1] == 0x3E) {
        pos += 2;
        return dict;
      }
      if (bytes[pos] != 0x2F) _corrupt('dictionary key');
      final key = _readName().text;
      dict.entries[key] = readObject(depth + 1);
    }
  }

  PdfArr _readArray(int depth) {
    pos++;
    final items = <PdfObj>[];
    while (true) {
      skipWhitespace();
      if (pos >= bytes.length) _corrupt('unterminated array');
      if (bytes[pos] == 0x5D) {
        pos++;
        return PdfArr(items);
      }
      items.add(readObject(depth + 1));
    }
  }

  PdfStr _readHexString() {
    pos++;
    final out = BytesBuilder(copy: false);
    int? high;
    while (true) {
      if (pos >= bytes.length) _corrupt('unterminated hex string');
      final c = bytes[pos++];
      if (c == 0x3E) break;
      final digit = _hexValue(c);
      if (digit < 0) continue; // whitespace and stray bytes are ignored
      if (high == null) {
        high = digit;
      } else {
        out.addByte(high << 4 | digit);
        high = null;
      }
    }
    if (high != null) out.addByte(high << 4);
    return PdfStr(out.toBytes());
  }

  static int _hexValue(int c) {
    if (c >= 0x30 && c <= 0x39) return c - 0x30;
    if (c >= 0x41 && c <= 0x46) return c - 0x41 + 10;
    if (c >= 0x61 && c <= 0x66) return c - 0x61 + 10;
    return -1;
  }

  PdfStr _readLiteralString() {
    pos++;
    final out = BytesBuilder(copy: false);
    var depth = 1;
    while (true) {
      if (pos >= bytes.length) _corrupt('unterminated string');
      final c = bytes[pos++];
      if (c == 0x5C) {
        if (pos >= bytes.length) _corrupt('unterminated string');
        final e = bytes[pos++];
        switch (e) {
          case 0x6E:
            out.addByte(0x0A);
          case 0x72:
            out.addByte(0x0D);
          case 0x74:
            out.addByte(0x09);
          case 0x62:
            out.addByte(0x08);
          case 0x66:
            out.addByte(0x0C);
          case 0x0D:
            // Backslash-newline is a line continuation.
            if (pos < bytes.length && bytes[pos] == 0x0A) pos++;
          case 0x0A:
            break;
          default:
            if (e >= 0x30 && e <= 0x37) {
              var value = e - 0x30;
              for (var i = 0; i < 2; i++) {
                if (pos < bytes.length &&
                    bytes[pos] >= 0x30 &&
                    bytes[pos] <= 0x37) {
                  value = value * 8 + (bytes[pos++] - 0x30);
                } else {
                  break;
                }
              }
              out.addByte(value & 0xFF);
            } else {
              out.addByte(e);
            }
        }
      } else if (c == 0x28) {
        depth++;
        out.addByte(c);
      } else if (c == 0x29) {
        depth--;
        if (depth == 0) break;
        out.addByte(c);
      } else if (c == 0x0D) {
        // An unescaped end-of-line inside a string reads as a single LF.
        if (pos < bytes.length && bytes[pos] == 0x0A) pos++;
        out.addByte(0x0A);
      } else {
        out.addByte(c);
      }
    }
    return PdfStr(out.toBytes());
  }
}

/// Serialises objects back to PDF syntax. [transformString] and
/// [transformStream] let the caller encrypt content on the way out.
final class PdfWriter {
  PdfWriter({this.transformString, this.transformStream});

  final Uint8List Function(Uint8List plain)? transformString;
  final Uint8List Function(Uint8List plain)? transformStream;

  final BytesBuilder _out = BytesBuilder(copy: false);

  int get length => _out.length;
  Uint8List takeBytes() => _out.takeBytes();

  void raw(String text) => _out.add(latin1.encode(text));
  void bytes(List<int> data) => _out.add(data);

  static const _hex = '0123456789abcdef';

  void _hexString(Uint8List data) {
    final buffer = Uint8List(data.length * 2 + 2);
    buffer[0] = 0x3C;
    for (var i = 0; i < data.length; i++) {
      buffer[1 + i * 2] = _hex.codeUnitAt(data[i] >> 4);
      buffer[2 + i * 2] = _hex.codeUnitAt(data[i] & 0x0F);
    }
    buffer[buffer.length - 1] = 0x3E;
    _out.add(buffer);
  }

  /// Writes [value]. With [encrypt] false, strings are written as they are
  /// (used for the encryption dictionary itself and signature contents).
  void object(PdfObj value, {bool encrypt = true}) {
    switch (value) {
      case PdfRaw(:final text):
        raw(text);
      case PdfRef(:final number, :final generation):
        raw('$number $generation R');
      case PdfStr(:final bytes):
        final transform = encrypt ? transformString : null;
        _hexString(transform == null ? bytes : transform(bytes));
      case PdfArr(:final items):
        raw('[');
        for (var i = 0; i < items.length; i++) {
          if (i > 0) raw(' ');
          object(items[i], encrypt: encrypt);
        }
        raw(']');
      case PdfDict():
        _dict(value, encrypt: encrypt);
      case PdfStream(:final dict, :final data):
        final transform = encrypt ? transformStream : null;
        final payload = transform == null ? data : transform(data);
        final header = PdfDict({...dict.entries})
          ..['/Length'] = PdfRaw('${payload.length}');
        _dict(header, encrypt: encrypt);
        raw('\nstream\n');
        _out.add(payload);
        raw('\nendstream');
    }
  }

  void _dict(PdfDict dict, {required bool encrypt}) {
    // A signature's /Contents is never encrypted (ISO 32000-2, 7.6.2).
    final isSignature =
        dict.entries.containsKey('/ByteRange') ||
        dict.nameOf('/Type') == '/Sig';
    raw('<<');
    dict.entries.forEach((key, value) {
      raw(key);
      raw(' ');
      object(value, encrypt: encrypt && !(isSignature && key == '/Contents'));
      raw(' ');
    });
    raw('>>');
  }

  void indirect(
    int number,
    int generation,
    PdfObj value, {
    bool encrypt = true,
  }) {
    raw('$number $generation obj\n');
    object(value, encrypt: encrypt);
    raw('\nendobj\n');
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:docnook/domain/docmodel/doc_model.dart';

/// Reads RTF into a [DocModel] (Basic fidelity): paragraphs, bold, italic,
/// underline, strike, font size, colours, alignment, page breaks, simple
/// tables (one paragraph per cell). Pictures, fields and objects are
/// skipped.
abstract final class RtfParser {
  static DocModel parse(Uint8List bytes) => _RtfReader(bytes).read();
}

final class _State {
  _State();

  _State.copy(_State o)
    : bold = o.bold,
      italic = o.italic,
      underline = o.underline,
      strike = o.strike,
      size = o.size,
      color = o.color,
      align = o.align,
      skip = o.skip,
      unicodeSkip = o.unicodeSkip,
      superscript = o.superscript,
      subscript = o.subscript;

  bool bold = false;
  bool italic = false;
  bool underline = false;
  bool strike = false;
  double? size;
  int? color;
  TextAlignment align = TextAlignment.start;
  bool skip = false;
  int unicodeSkip = 1;
  bool superscript = false;
  bool subscript = false;

  RunStyle get run => RunStyle(
    bold: bold,
    italic: italic,
    underline: underline,
    strike: strike,
    fontSize: size,
    color: color,
    position: superscript
        ? VerticalPosition.superscript
        : subscript
        ? VerticalPosition.subscript
        : VerticalPosition.baseline,
  );
}

/// Destinations whose content is not document text.
const _skipDestinations = {
  'fonttbl', 'colortbl', 'stylesheet', 'info', 'pict', 'object', 'header', //
  'footer', 'headerl', 'headerr', 'footerl', 'footerr', 'headerf', 'footerf',
  'fldinst', 'themedata', 'colorschememapping', 'datastore', 'latentstyles',
  'listtable', 'listoverridetable', 'rsidtbl', 'generator', 'xmlnstbl',
  'mmathPr', 'pgdsctbl', 'filetbl', 'revtbl', 'bkmkstart', 'bkmkend',
  'nonshppict', 'shppict', 'shpinst', 'sp', 'footnote', 'annotation', 'atnid',
};

final class _RtfReader {
  _RtfReader(this._bytes);

  final Uint8List _bytes;
  int _pos = 0;

  final _blocks = <Block>[];
  final _colors = <int?>[];
  var _runs = <Inline>[];
  final _text = StringBuffer();
  _State _state = _State();
  final _stack = <_State>[];

  // Table state.
  List<TableRow>? _tableRows;
  List<TableCell>? _rowCells;
  List<Block>? _cellBlocks;
  bool _inTable = false;

  int _codepage = 1252;

  DocModel read() {
    while (_pos < _bytes.length) {
      final c = _bytes[_pos];
      if (c == 0x7B) {
        _pos++;
        _stack.add(_State.copy(_state));
        _checkDestination();
      } else if (c == 0x7D) {
        _pos++;
        _flushText();
        if (_stack.isNotEmpty) _state = _stack.removeLast();
      } else if (c == 0x5C) {
        _control();
      } else if (c == 0x0D || c == 0x0A) {
        _pos++;
      } else {
        _pos++;
        if (!_state.skip) _text.writeCharCode(_decodeByte(c));
      }
    }
    _endParagraph(force: false);
    _endTable();
    return DocModel(sections: [DocSection(blocks: _blocks)], simplified: true);
  }

  /// Right after `{`: `{\*\dest` and known destinations are skipped whole.
  void _checkDestination() {
    if (_pos + 1 < _bytes.length && _bytes[_pos] == 0x5C && _bytes[_pos + 1] == 0x2A) {
      _flushText();
      _state.skip = true;
      return;
    }
    if (_pos < _bytes.length && _bytes[_pos] == 0x5C) {
      final save = _pos;
      _pos++;
      final word = _readWord();
      _pos = save;
      if (_skipDestinations.contains(word)) {
        _flushText();
        _state.skip = true;
        if (word == 'colortbl') {
          _pos = save;
          _readColorTable();
        }
      }
    }
  }

  void _readColorTable() {
    // {\colortbl;\red0\green0\blue0;...}
    var r = 0, g = 0, b = 0;
    var any = false;
    while (_pos < _bytes.length && _bytes[_pos] != 0x7D) {
      final c = _bytes[_pos];
      if (c == 0x5C) {
        _pos++;
        final word = _readWord();
        final n = _readNumber();
        if (word == 'red') {
          r = n ?? 0;
          any = true;
        } else if (word == 'green') {
          g = n ?? 0;
        } else if (word == 'blue') {
          b = n ?? 0;
        }
        if (_pos < _bytes.length && _bytes[_pos] == 0x20) _pos++;
      } else if (c == 0x3B) {
        _colors.add(any ? (0xFF000000 | r << 16 | g << 8 | b) : null);
        r = g = b = 0;
        any = false;
        _pos++;
      } else {
        _pos++;
      }
    }
  }

  String _readWord() {
    final start = _pos;
    while (_pos < _bytes.length) {
      final c = _bytes[_pos];
      if ((c >= 0x61 && c <= 0x7A) || (c >= 0x41 && c <= 0x5A)) {
        _pos++;
      } else {
        break;
      }
    }
    return ascii.decode(_bytes.sublist(start, _pos), allowInvalid: true);
  }

  int? _readNumber() {
    final start = _pos;
    if (_pos < _bytes.length && _bytes[_pos] == 0x2D) _pos++;
    while (_pos < _bytes.length && _bytes[_pos] >= 0x30 && _bytes[_pos] <= 0x39) {
      _pos++;
    }
    if (_pos == start) return null;
    return int.tryParse(ascii.decode(_bytes.sublist(start, _pos)));
  }

  void _control() {
    _pos++; // backslash
    if (_pos >= _bytes.length) return;
    final c = _bytes[_pos];
    // Control symbols.
    if (!((c >= 0x61 && c <= 0x7A) || (c >= 0x41 && c <= 0x5A))) {
      _pos++;
      switch (c) {
        case 0x5C || 0x7B || 0x7D:
          if (!_state.skip) _text.writeCharCode(c);
        case 0x27: // \'hh
          if (_pos + 2 <= _bytes.length) {
            final hex = int.tryParse(ascii.decode(_bytes.sublist(_pos, _pos + 2), allowInvalid: true), radix: 16);
            _pos += 2;
            if (hex != null && !_state.skip) _text.writeCharCode(_decodeByte(hex));
          }
        case 0x7E: // non-breaking space
          if (!_state.skip) _text.write(' ');
        case 0x2D: // optional hyphen
          break;
        case 0x5F:
          if (!_state.skip) _text.write('‑');
        case 0x0D || 0x0A:
          _paragraph();
        case 0x2A:
          _state.skip = true;
      }
      return;
    }
    final word = _readWord();
    final param = _readNumber();
    if (_pos < _bytes.length && _bytes[_pos] == 0x20) _pos++; // delimiter space

    switch (word) {
      case 'par':
        _paragraph();
      case 'line':
        if (!_state.skip) _text.write('\n');
      case 'tab':
        if (!_state.skip) _text.write('\t');
      case 'page':
        _paragraph();
        _blocks.add(const PageBreak());
      case 'b':
        _style(() => _state.bold = param != 0);
      case 'i':
        _style(() => _state.italic = param != 0);
      case 'ul':
        _style(() => _state.underline = param != 0);
      case 'ulnone':
        _style(() => _state.underline = false);
      case 'strike':
        _style(() => _state.strike = param != 0);
      case 'super':
        _style(() => _state.superscript = true);
      case 'sub':
        _style(() => _state.subscript = true);
      case 'nosupersub':
        _style(() {
          _state
            ..superscript = false
            ..subscript = false;
        });
      case 'fs':
        _style(() => _state.size = param == null ? null : param / 2);
      case 'cf':
        _style(() => _state.color = param != null && param > 0 && param < _colors.length ? _colors[param] : null);
      case 'plain':
        _style(() {
          _state
            ..bold = false
            ..italic = false
            ..underline = false
            ..strike = false
            ..size = null
            ..color = null
            ..superscript = false
            ..subscript = false;
        });
      case 'pard':
        _state.align = TextAlignment.start;
        _inTable = false;
      case 'qc':
        _state.align = TextAlignment.center;
      case 'qr':
        _state.align = TextAlignment.end;
      case 'qj':
        _state.align = TextAlignment.justify;
      case 'ql':
        _state.align = TextAlignment.start;
      case 'u':
        if (param != null && !_state.skip) {
          _text.writeCharCode(param < 0 ? param + 65536 : param);
          _skipFallback(_state.unicodeSkip);
        }
      case 'uc':
        _state.unicodeSkip = param ?? 1;
      case 'ansicpg':
        _codepage = param ?? 1252;
      case 'intbl':
        _inTable = true;
      case 'cell':
        _paragraph();
        _endCell();
      case 'row':
        _endRow();
      case 'bullet':
        if (!_state.skip) _text.write('•');
      case 'emdash':
        if (!_state.skip) _text.write('—');
      case 'endash':
        if (!_state.skip) _text.write('–');
      case 'lquote':
        if (!_state.skip) _text.write('‘');
      case 'rquote':
        if (!_state.skip) _text.write('’');
      case 'ldblquote':
        if (!_state.skip) _text.write('“');
      case 'rdblquote':
        if (!_state.skip) _text.write('”');
      case 'bin':
        _pos += (param ?? 0).clamp(0, _bytes.length - _pos);
    }
  }

  /// Skips the ANSI fallback characters after a \u escape.
  void _skipFallback(int count) {
    var left = count;
    while (left > 0 && _pos < _bytes.length) {
      final c = _bytes[_pos];
      if (c == 0x7B || c == 0x7D) return;
      if (c == 0x5C) {
        if (_pos + 1 < _bytes.length && _bytes[_pos + 1] == 0x27) {
          _pos += 4;
        } else {
          return;
        }
      } else {
        _pos++;
      }
      left--;
    }
  }

  void _style(void Function() change) {
    _flushText();
    change();
  }

  /// Windows-1252 bytes 0x80–0x9F differ from Latin-1; map the common ones.
  int _decodeByte(int b) {
    if (_codepage != 1252 || b < 0x80 || b > 0x9F) return b;
    const map = {
      0x80: 0x20AC, 0x82: 0x201A, 0x84: 0x201E, 0x85: 0x2026, 0x86: 0x2020, //
      0x87: 0x2021, 0x89: 0x2030, 0x8A: 0x0160, 0x8B: 0x2039, 0x8C: 0x0152,
      0x91: 0x2018, 0x92: 0x2019, 0x93: 0x201C, 0x94: 0x201D, 0x95: 0x2022,
      0x96: 0x2013, 0x97: 0x2014, 0x99: 0x2122, 0x9A: 0x0161, 0x9B: 0x203A,
      0x9C: 0x0153, 0x9F: 0x0178,
    };
    return map[b] ?? b;
  }

  void _flushText() {
    if (_text.isEmpty) return;
    if (!_state.skip) _runs.add(TextRun(_text.toString(), _state.run));
    _text.clear();
  }

  void _paragraph() => _endParagraph(force: true);

  void _endParagraph({required bool force}) {
    _flushText();
    if (_runs.isEmpty && !force) return;
    final paragraph = Paragraph(_runs, style: ParagraphStyle(align: _state.align, spaceAfter: 4));
    _runs = <Inline>[];
    if (_inTable) {
      (_cellBlocks ??= []).add(paragraph);
    } else {
      _endTable();
      _blocks.add(paragraph);
    }
  }

  void _endCell() {
    (_rowCells ??= []).add(TableCell(_cellBlocks ?? []));
    _cellBlocks = null;
  }

  void _endRow() {
    final cells = _rowCells;
    _rowCells = null;
    if (cells == null || cells.isEmpty) return;
    (_tableRows ??= []).add(TableRow(cells));
  }

  void _endTable() {
    final rows = _tableRows;
    _tableRows = null;
    if (rows != null && rows.isNotEmpty) _blocks.add(TableBlock(rows));
  }
}

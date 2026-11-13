/// A small, line-by-line syntax highlighter for JSON, XML/HTML and common
/// C-like / script languages. Deliberately simple: tokens never span lines,
/// so any line can be coloured on its own while scrolling.
enum TokenKind {
  plain,
  keyword,
  string,
  number,
  comment,
  tag,
  attribute,
  punctuation,
}

final class Token {
  const Token(this.text, this.kind);
  final String text;
  final TokenKind kind;
}

enum Syntax { none, json, xml, code, hash, sql, ini }

Syntax syntaxFor(String extension) => switch (extension) {
  'json' => Syntax.json,
  'xml' || 'html' || 'htm' || 'svg' || 'plist' || 'xhtml' => Syntax.xml,
  'py' ||
  'rb' ||
  'sh' ||
  'bash' ||
  'yaml' ||
  'yml' ||
  'toml' ||
  'r' ||
  'pl' ||
  'ps1' ||
  'conf' ||
  'properties' ||
  'env' => Syntax.hash,
  'sql' => Syntax.sql,
  'ini' || 'cfg' => Syntax.ini,
  'dart' ||
  'java' ||
  'kt' ||
  'kts' ||
  'js' ||
  'mjs' ||
  'ts' ||
  'jsx' ||
  'tsx' ||
  'c' ||
  'h' ||
  'cpp' ||
  'hpp' ||
  'cc' || //
  'cs' ||
  'go' ||
  'rs' ||
  'swift' ||
  'php' ||
  'css' ||
  'scss' ||
  'gradle' ||
  'lua' => Syntax.code,
  _ => Syntax.none,
};

const _keywords = {
  'abstract',
  'as',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue', //
  'def',
  'default',
  'do',
  'elif',
  'else',
  'enum',
  'export',
  'extends',
  'false',
  'final',
  'finally',
  'fn',
  'for',
  'from',
  'fun',
  'func',
  'function',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'let',
  'match',
  'mut',
  'new',
  'nil',
  'none',
  'null',
  'object',
  'override',
  'package',
  'private',
  'protected',
  'pub',
  'public',
  'return',
  'self',
  'static',
  'struct',
  'super',
  'switch',
  'this',
  'throw',
  'throws',
  'true',
  'try',
  'type',
  'typeof',
  'use',
  'val',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
  'lambda',
  'pass',
  'raise',
  'None',
  'True',
  'False',
  'and',
  'or',
  'not',
  'select',
  'insert',
  'update',
  'delete',
  'where',
  'join',
  'left',
  'right',
  'inner',
  'outer',
  'group',
  'order',
  'by',
  'having',
  'limit',
  'values',
  'into',
  'create',
  'table',
  'drop',
  'alter',
  'echo', 'then', 'fi', 'done', 'esac', 'local',
};

List<Token> highlightLine(String line, Syntax syntax) {
  if (syntax == Syntax.none || line.isEmpty) {
    return [Token(line, TokenKind.plain)];
  }
  if (syntax == Syntax.xml) return _xml(line);
  if (syntax == Syntax.ini) {
    final t = line.trimLeft();
    if (t.startsWith(';') || t.startsWith('#')) {
      return [Token(line, TokenKind.comment)];
    }
    if (t.startsWith('[')) return [Token(line, TokenKind.tag)];
  }
  final out = <Token>[];
  var i = 0;
  final plain = StringBuffer();
  void flush() {
    if (plain.isNotEmpty) {
      out.add(Token(plain.toString(), TokenKind.plain));
      plain.clear();
    }
  }

  final lineComment = switch (syntax) {
    Syntax.hash || Syntax.ini => '#',
    Syntax.sql => '--',
    Syntax.code => '//',
    _ => null,
  };

  while (i < line.length) {
    final c = line[i];
    if (lineComment != null && line.startsWith(lineComment, i)) {
      flush();
      out.add(Token(line.substring(i), TokenKind.comment));
      return out;
    }
    if (syntax == Syntax.code && line.startsWith('/*', i)) {
      final end = line.indexOf('*/', i + 2);
      flush();
      final stop = end < 0 ? line.length : end + 2;
      out.add(Token(line.substring(i, stop), TokenKind.comment));
      i = stop;
      continue;
    }
    if (c == '"' || c == "'" || c == '`') {
      flush();
      var j = i + 1;
      while (j < line.length && line[j] != c) {
        if (line[j] == r'\') j++;
        j++;
      }
      final stop = j < line.length ? j + 1 : line.length;
      final text = line.substring(i, stop);
      // JSON keys read better as attributes than as strings.
      final isKey =
          syntax == Syntax.json &&
          line.substring(stop).trimLeft().startsWith(':');
      out.add(Token(text, isKey ? TokenKind.attribute : TokenKind.string));
      i = stop;
      continue;
    }
    if (_isDigit(c) && (i == 0 || !_isWord(line[i - 1]))) {
      flush();
      var j = i;
      while (j < line.length && (_isWord(line[j]) || line[j] == '.')) {
        j++;
      }
      out.add(Token(line.substring(i, j), TokenKind.number));
      i = j;
      continue;
    }
    if (_isWord(c)) {
      var j = i;
      while (j < line.length && _isWord(line[j])) {
        j++;
      }
      final word = line.substring(i, j);
      final kw = syntax == Syntax.sql
          ? _keywords.contains(word.toLowerCase())
          : _keywords.contains(word);
      if (kw) {
        flush();
        out.add(Token(word, TokenKind.keyword));
      } else {
        plain.write(word);
      }
      i = j;
      continue;
    }
    if ('{}[](),;:'.contains(c) && syntax == Syntax.json) {
      flush();
      out.add(Token(c, TokenKind.punctuation));
      i++;
      continue;
    }
    plain.write(c);
    i++;
  }
  flush();
  return out;
}

List<Token> _xml(String line) {
  final out = <Token>[];
  var i = 0;
  while (i < line.length) {
    if (line.startsWith('<!--', i)) {
      final end = line.indexOf('-->', i);
      final stop = end < 0 ? line.length : end + 3;
      out.add(Token(line.substring(i, stop), TokenKind.comment));
      i = stop;
    } else if (line[i] == '<') {
      final end = line.indexOf('>', i);
      final stop = end < 0 ? line.length : end + 1;
      final tag = line.substring(i, stop);
      final m = RegExp(
        r'^(</?[\w:.-]*)(.*?)(/?>?)$',
        dotAll: true,
      ).firstMatch(tag);
      if (m == null) {
        out.add(Token(tag, TokenKind.tag));
      } else {
        out.add(Token(m.group(1)!, TokenKind.tag));
        for (final a in RegExp(
          r'''(\s+)([\w:.-]+)(=)?("[^"]*"|'[^']*')?|(\s+)''',
        ).allMatches(m.group(2)!)) {
          if (a.group(5) != null) {
            out.add(Token(a.group(5)!, TokenKind.plain));
            continue;
          }
          out
            ..add(Token(a.group(1)!, TokenKind.plain))
            ..add(Token(a.group(2)!, TokenKind.attribute));
          if (a.group(3) != null) {
            out.add(const Token('=', TokenKind.punctuation));
          }
          if (a.group(4) != null) out.add(Token(a.group(4)!, TokenKind.string));
        }
        if (m.group(3)!.isNotEmpty) out.add(Token(m.group(3)!, TokenKind.tag));
      }
      i = stop;
    } else {
      final next = line.indexOf('<', i);
      final stop = next < 0 ? line.length : next;
      out.add(Token(line.substring(i, stop), TokenKind.plain));
      i = stop;
    }
  }
  return out;
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

bool _isWord(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 0x30 && u <= 0x39) ||
      (u >= 0x41 && u <= 0x5A) ||
      (u >= 0x61 && u <= 0x7A) ||
      u == 0x5F ||
      u == 0x24;
}

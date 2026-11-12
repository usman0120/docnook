import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/engines/office/docx/docx_styles.dart' show classifyFont;
import 'package:docnook/engines/office/xml_events.dart';

/// A minimal HTML tree, built from XHTML (EPUB) or the Markdown AST.
sealed class HtmlNode {
  const HtmlNode();
}

final class HtmlElement extends HtmlNode {
  HtmlElement(this.tag, [Map<String, String>? attrs, List<HtmlNode>? children])
    : attrs = attrs ?? {},
      children = children ?? [];
  final String tag;
  final Map<String, String> attrs;
  final List<HtmlNode> children;
}

final class HtmlText extends HtmlNode {
  const HtmlText(this.text);
  final String text;
}

/// Common HTML named entities, which XHTML files use without declaring.
const _entities = {
  'nbsp': 160, 'copy': 169, 'reg': 174, 'trade': 8482, 'mdash': 8212, //
  'ndash': 8211, 'hellip': 8230, 'lsquo': 8216, 'rsquo': 8217, 'ldquo': 8220,
  'rdquo': 8221, 'laquo': 171, 'raquo': 187, 'bull': 8226, 'middot': 183,
  'deg': 176, 'times': 215, 'divide': 247, 'euro': 8364, 'pound': 163,
  'yen': 165, 'cent': 162, 'sect': 167, 'para': 182, 'shy': 173,
  'eacute': 233, 'egrave': 232, 'aacute': 225, 'agrave': 224, 'ouml': 246,
  'uuml': 252, 'auml': 228, 'szlig': 223, 'ccedil': 231, 'ntilde': 241,
  'thinsp': 8201, 'ensp': 8194, 'emsp': 8195, 'zwnj': 8204, 'zwj': 8205,
};

/// Makes an XHTML file safe for the strict XML reader: a plain
/// `<!DOCTYPE html …>` is removed, HTML named entities become numeric. Any
/// internal subset (`<!DOCTYPE … [ … ]>`) is still rejected, so entity
/// expansion attacks stay impossible (BLUEPRINT 8.1).
String sanitizeXhtml(String source) {
  var s = source;
  final doctype = RegExp(r'<!DOCTYPE[^>\[]*>', caseSensitive: false);
  s = s.replaceFirst(doctype, '');
  s = s.replaceAllMapped(RegExp('&([a-zA-Z]+);'), (m) {
    final name = m.group(1)!;
    if (const {'amp', 'lt', 'gt', 'quot', 'apos'}.contains(name)) return m.group(0)!;
    final code = _entities[name];
    return code == null ? '' : '&#$code;';
  });
  return s;
}

/// Parses an XHTML document's `<body>` into [HtmlNode]s.
List<HtmlNode> parseXhtmlBody(String xhtml) {
  final pull = XmlPull(sanitizeXhtml(xhtml));
  final body = pull.find('body');
  if (body == null) return const [];
  List<HtmlNode> childrenOf(XmlStartElementEvent e) {
    final out = <HtmlNode>[];
    pull.children(
      e,
      (child) {
        final attrs = {for (final a in child.attributes) a.localName: a.value};
        out.add(HtmlElement(child.localName.toLowerCase(), attrs, childrenOf(child)));
      },
      onText: (t) => out.add(HtmlText(t)),
    );
    return out;
  }

  return childrenOf(body);
}

/// Converts HTML nodes to DocModel blocks: headings, paragraphs, lists,
/// tables, images, quotes, code, emphasis, links (Good fidelity for EPUB
/// and Markdown).
final class HtmlToDocModel {
  HtmlToDocModel({this.resolveImage});

  /// Returns an image id for an `src`, loading it into the model's images,
  /// or null to skip the picture.
  final String? Function(String src)? resolveImage;

  final List<Block> _blocks = [];
  List<Inline> _inlines = [];
  ParagraphStyle _paraStyle = ParagraphStyle.plain;
  int _heading = 0;
  ListInfo? _list;

  List<Block> convert(List<HtmlNode> nodes) {
    _walkBlocks(nodes, RunStyle.plain, 0);
    _flush();
    return _blocks;
  }

  static const _blockTags = {
    'p', 'div', 'section', 'article', 'header', 'footer', 'main', 'aside', 'nav', //
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li', 'table', 'blockquote',
    'pre', 'hr', 'figure', 'figcaption', 'dl', 'dt', 'dd', 'body', 'center',
  };

  void _flush() {
    final inlines = _trim(_inlines);
    if (inlines.isNotEmpty || _list != null) {
      _blocks.add(Paragraph(inlines, style: _paraStyle, headingLevel: _heading, list: _list));
    }
    _inlines = [];
    _paraStyle = ParagraphStyle.plain;
    _heading = 0;
    _list = null;
  }

  /// Collapses whitespace like a browser: runs of spaces become one, and
  /// leading/trailing space in a paragraph is dropped.
  static List<Inline> _trim(List<Inline> inlines) {
    final out = <Inline>[];
    var lastSpace = true;
    for (final i in inlines) {
      if (i is! TextRun) {
        out.add(i);
        lastSpace = false;
        continue;
      }
      if (i.style.font == FontClass.mono && i.text.contains('\n')) {
        out.add(i); // preformatted
        lastSpace = i.text.endsWith('\n');
        continue;
      }
      var t = i.text.replaceAll(RegExp(r'[ \t\r\n\f]+'), ' ');
      if (lastSpace && t.startsWith(' ')) t = t.substring(1);
      if (t.isEmpty) continue;
      lastSpace = t.endsWith(' ');
      final last = out.isEmpty ? null : out.last;
      if (last is TextRun && last.style == i.style) {
        out[out.length - 1] = TextRun(last.text + t, last.style);
      } else {
        out.add(TextRun(t, i.style));
      }
    }
    if (out.isNotEmpty && out.last is TextRun) {
      final last = out.last as TextRun;
      final t = last.text.trimRight();
      if (t.isEmpty) {
        out.removeLast();
      } else {
        out[out.length - 1] = TextRun(t, last.style);
      }
    }
    return out;
  }

  void _walkBlocks(List<HtmlNode> nodes, RunStyle style, int depth) {
    if (depth > 60) return;
    for (final node in nodes) {
      switch (node) {
        case HtmlText(:final text):
          _inlines.add(TextRun(text, style));
        case HtmlElement(:final tag) when _blockTags.contains(tag):
          _block(node, style, depth);
        case final HtmlElement e:
          _inline(e, style, depth);
      }
    }
  }

  void _block(HtmlElement e, RunStyle style, int depth) {
    switch (e.tag) {
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        _flush();
        _heading = int.parse(e.tag.substring(1));
        _paraStyle = ParagraphStyle(align: _align(e), spaceBefore: 8, spaceAfter: 4);
        _walkBlocks(e.children, style, depth + 1);
        _flush();
      case 'ul' || 'ol':
        _flush();
        final ordered = e.tag == 'ol';
        var n = int.tryParse(e.attrs['start'] ?? '') ?? 1;
        final level = _listDepth;
        _listDepth++;
        for (final child in e.children) {
          if (child is! HtmlElement || child.tag != 'li') continue;
          _flush();
          final checkbox = _checkbox(child);
          _list = ListInfo(
            level: level.clamp(0, 8),
            marker: checkbox ?? (ordered ? '${n++}.' : (level.isEven ? '•' : '◦')),
            ordered: ordered,
          );
          _walkBlocks(child.children, style, depth + 1);
          _flush();
        }
        _listDepth--;
      case 'li':
        _flush();
        _list = ListInfo(level: _listDepth.clamp(0, 8), marker: '•');
        _walkBlocks(e.children, style, depth + 1);
        _flush();
      case 'blockquote':
        _flush();
        final before = _quoteDepth;
        _quoteDepth++;
        _walkQuote(e, style, depth);
        _quoteDepth = before;
      case 'pre':
        _flush();
        _paraStyle = ParagraphStyle(indentStart: 8 + _quoteDepth * 18.0, background: 0x14808080);
        _inlines.add(TextRun(_textOf(e).replaceAll(RegExp(r'\n$'), ''), style.copyWith(font: FontClass.mono)));
        _flush();
      case 'hr':
        _flush();
        _blocks.add(const PageBreak());
      case 'table':
        _flush();
        final table = _table(e, style, depth);
        if (table.rows.isNotEmpty) _blocks.add(table);
      case 'figcaption' || 'dt':
        _flush();
        _walkBlocks(e.children, e.tag == 'dt' ? style.copyWith(bold: true) : style.copyWith(italic: true), depth + 1);
        _flush();
      default:
        _flush();
        _paraStyle = ParagraphStyle(
          align: _align(e),
          indentStart: _quoteDepth * 18.0 + (e.tag == 'dd' ? 18 : 0),
          spaceAfter: 6,
        );
        _walkBlocks(e.children, style, depth + 1);
        _flush();
    }
  }

  int _listDepth = 0;
  int _quoteDepth = 0;

  void _walkQuote(HtmlElement e, RunStyle style, int depth) {
    for (final child in e.children) {
      if (child is HtmlElement && _blockTags.contains(child.tag)) {
        _block(child, style.copyWith(italic: true), depth + 1);
      } else {
        _paraStyle = ParagraphStyle(indentStart: _quoteDepth * 18.0);
        _walkBlocks([child], style.copyWith(italic: true), depth + 1);
      }
    }
    _flush();
  }

  static String? _checkbox(HtmlElement li) {
    for (final c in li.children) {
      if (c is HtmlElement && c.tag == 'input' && c.attrs['type'] == 'checkbox') {
        return c.attrs.containsKey('checked') ? '☑' : '☐';
      }
    }
    return null;
  }

  static TextAlignment _align(HtmlElement e) {
    final css = '${e.attrs['style'] ?? ''} ${e.attrs['align'] ?? ''}'.toLowerCase();
    if (e.tag == 'center' || css.contains('center')) return TextAlignment.center;
    if (css.contains('right')) return TextAlignment.end;
    if (css.contains('justify')) return TextAlignment.justify;
    return TextAlignment.start;
  }

  void _inline(HtmlElement e, RunStyle style, int depth) {
    switch (e.tag) {
      case 'br':
        _inlines.add(TextRun('\n', style));
      case 'b' || 'strong':
        _walkBlocks(e.children, style.copyWith(bold: true), depth + 1);
      case 'i' || 'em' || 'cite' || 'dfn' || 'var':
        _walkBlocks(e.children, style.copyWith(italic: true), depth + 1);
      case 'u' || 'ins':
        _walkBlocks(e.children, style.copyWith(underline: true), depth + 1);
      case 's' || 'del' || 'strike':
        _walkBlocks(e.children, style.copyWith(strike: true), depth + 1);
      case 'sup':
        _walkBlocks(e.children, style.copyWith(position: VerticalPosition.superscript), depth + 1);
      case 'sub':
        _walkBlocks(e.children, style.copyWith(position: VerticalPosition.subscript), depth + 1);
      case 'code' || 'kbd' || 'samp' || 'tt':
        _walkBlocks(e.children, style.copyWith(font: FontClass.mono), depth + 1);
      case 'mark':
        _walkBlocks(e.children, style.copyWith(highlight: 0xFFFFF59D), depth + 1);
      case 'a':
        final href = e.attrs['href'];
        _walkBlocks(e.children, href == null ? style : style.copyWith(link: href), depth + 1);
      case 'img' || 'image':
        final src = e.attrs['src'] ?? e.attrs['href'];
        final id = src == null ? null : resolveImage?.call(src);
        if (id != null) {
          final w = double.tryParse(e.attrs['width'] ?? '') ?? 280;
          final h = double.tryParse(e.attrs['height'] ?? '') ?? w * 0.66;
          final alone = _inlines.every((i) => i is TextRun && i.text.trim().isEmpty);
          if (alone) {
            _flush();
            _blocks.add(ImageBlock(id, width: w, height: h, align: TextAlignment.center));
          } else {
            _inlines.add(InlineImage(id, width: w, height: h));
          }
        }
      case 'span' || 'font':
        final css = (e.attrs['style'] ?? '').toLowerCase();
        var s = style;
        if (css.contains('bold')) s = s.copyWith(bold: true);
        if (css.contains('italic')) s = s.copyWith(italic: true);
        final face = e.attrs['face'];
        if (face != null) s = s.copyWith(font: classifyFont(face));
        _walkBlocks(e.children, s, depth + 1);
      case 'script' || 'style' || 'head' || 'title' || 'svg' || 'math' || 'input':
        break;
      default:
        _walkBlocks(e.children, style, depth + 1);
    }
  }

  TableBlock _table(HtmlElement e, RunStyle style, int depth) {
    final rows = <TableRow>[];
    void collect(HtmlElement node, bool header) {
      for (final child in node.children) {
        if (child is! HtmlElement) continue;
        if (child.tag == 'thead') {
          collect(child, true);
        } else if (child.tag == 'tbody' || child.tag == 'tfoot') {
          collect(child, false);
        } else if (child.tag == 'tr') {
          final cells = <TableCell>[];
          var isHeader = header;
          for (final cell in child.children) {
            if (cell is! HtmlElement || (cell.tag != 'td' && cell.tag != 'th')) continue;
            if (cell.tag == 'th') isHeader = true;
            final inner = HtmlToDocModel(resolveImage: resolveImage);
            final blocks = inner.convert(
              cell.tag == 'th'
                  ? [HtmlElement('b', {}, cell.children)]
                  : cell.children,
            );
            cells.add(
              TableCell(
                blocks,
                colSpan: (int.tryParse(cell.attrs['colspan'] ?? '') ?? 1).clamp(1, 30),
              ),
            );
          }
          if (cells.isNotEmpty) rows.add(TableRow(cells, isHeader: isHeader));
        }
      }
    }

    collect(e, false);
    return TableBlock(rows);
  }

  static String _textOf(HtmlNode node) => switch (node) {
    HtmlText(:final text) => text,
    HtmlElement(:final tag) when tag == 'br' => '\n',
    HtmlElement(:final children) => children.map(_textOf).join(),
  };
}

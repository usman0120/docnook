import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/engines/archive/safe_zip.dart';
import 'package:docnook/engines/office/docx/docx_styles.dart';
import 'package:docnook/engines/office/xml_events.dart';

/// Reads OpenDocument Text (.odt) into a [DocModel] (Basic fidelity):
/// headings, paragraphs, bold/italic/underline/colour/size from automatic
/// and named styles, lists, tables with spans, images, page breaks.
abstract final class OdtParser {
  static DocModel parseFile(String path) {
    final zip = SafeZip.open(path);
    try {
      return _OdtReader(zip).read();
    } finally {
      zip.close();
    }
  }
}

/// ODF lengths ("2.5cm", "12pt", "0.4in", "10mm") → points.
double? odfLength(String? value) {
  if (value == null) return null;
  final m = RegExp(
    r'^(-?[\d.]+)\s*(cm|mm|in|pt|pc|px)?$',
  ).firstMatch(value.trim());
  if (m == null) return null;
  final n = double.tryParse(m.group(1)!);
  if (n == null) return null;
  return switch (m.group(2)) {
    'cm' => n * 72 / 2.54,
    'mm' => n * 72 / 25.4,
    'in' => n * 72,
    'pc' => n * 12,
    'px' => n * 0.75,
    _ => n,
  };
}

/// `#rrggbb` → 0xFFrrggbb.
int? odfColor(String? value) {
  if (value == null || !value.startsWith('#') || value.length != 7) return null;
  final rgb = int.tryParse(value.substring(1), radix: 16);
  return rgb == null ? null : 0xFF000000 | rgb;
}

final class _Style {
  RunStyle run = RunStyle.plain;
  ParagraphStyle? para;
  String? parent;
  bool pageBreakBefore = false;
  bool pageBreakAfter = false;
  int? cellFill;
}

final class _OdtReader {
  _OdtReader(this._zip);

  final SafeZip _zip;
  final _styles = <String, _Style>{};
  final _images = <String, DocImage>{};
  late XmlPull _pull;

  DocModel read() {
    final content = _zip.text('content.xml');
    if (content == null)
      throw const DocNookFailure.corrupt(detail: 'odt: no content');
    final stylesXml = _zip.text('styles.xml');
    if (stylesXml != null) _readStyles(XmlPull(stylesXml), 'styles');
    _readStyles(XmlPull(content), 'automatic-styles');

    _pull = XmlPull(content);
    final body = _pull.find('text');
    final blocks = <Block>[];
    if (body != null) _pull.children(body, (child) => _block(child, blocks, 0));
    return DocModel(
      sections: [DocSection(blocks: blocks)],
      images: _images,
    );
  }

  void _readStyles(XmlPull pull, String container) {
    final root = pull.find(container);
    if (root == null) return;
    pull.children(root, (style) {
      if (style.localName != 'style') return;
      final name = style.attr('style:name');
      if (name == null) return;
      final s = _Style()..parent = style.attr('style:parent-style-name');
      pull.children(style, (prop) {
        switch (prop.localName) {
          case 'text-properties':
            final weight = prop.attr('fo:font-weight');
            final fontStyle = prop.attr('fo:font-style');
            final underline = prop.attr('style:text-underline-style');
            final strike = prop.attr('style:text-line-through-style');
            final position = prop.attr('style:text-position') ?? '';
            final font =
                prop.attr('style:font-name') ?? prop.attr('fo:font-family');
            s.run = RunStyle(
              bold:
                  weight == 'bold' || (int.tryParse(weight ?? '') ?? 0) >= 600,
              italic: fontStyle == 'italic' || fontStyle == 'oblique',
              underline: underline != null && underline != 'none',
              strike: strike != null && strike != 'none',
              fontSize: odfLength(prop.attr('fo:font-size')),
              color: odfColor(prop.attr('fo:color')),
              highlight: odfColor(prop.attr('fo:background-color')),
              font: font == null ? null : classifyFont(font),
              position: position.startsWith('super')
                  ? VerticalPosition.superscript
                  : position.startsWith('sub')
                  ? VerticalPosition.subscript
                  : VerticalPosition.baseline,
            );
          case 'paragraph-properties':
            s
              ..pageBreakBefore = prop.attr('fo:break-before') == 'page'
              ..pageBreakAfter = prop.attr('fo:break-after') == 'page'
              ..para = ParagraphStyle(
                align: switch (prop.attr('fo:text-align')) {
                  'center' => TextAlignment.center,
                  'end' || 'right' => TextAlignment.end,
                  'justify' => TextAlignment.justify,
                  _ => TextAlignment.start,
                },
                indentStart: (odfLength(prop.attr('fo:margin-left')) ?? 0)
                    .clamp(0, 300)
                    .toDouble(),
                firstLine: (odfLength(prop.attr('fo:text-indent')) ?? 0)
                    .clamp(-100, 100)
                    .toDouble(),
                spaceBefore: (odfLength(prop.attr('fo:margin-top')) ?? 0)
                    .clamp(0, 100)
                    .toDouble(),
                spaceAfter: (odfLength(prop.attr('fo:margin-bottom')) ?? 0)
                    .clamp(0, 100)
                    .toDouble(),
                background: odfColor(prop.attr('fo:background-color')),
              );
          case 'table-cell-properties':
            s.cellFill = odfColor(prop.attr('fo:background-color'));
        }
      });
      _styles[name] = s;
    });
  }

  /// Run style with parents resolved (named → parent chain).
  RunStyle _run(String? name, RunStyle inherited) {
    final chain = <_Style>[];
    var current = name == null ? null : _styles[name];
    while (current != null && chain.length < 10) {
      chain.add(current);
      current = current.parent == null ? null : _styles[current.parent];
    }
    var out = inherited;
    for (final s in chain.reversed) {
      final r = s.run;
      out = out.copyWith(
        bold: r.bold ? true : null,
        italic: r.italic ? true : null,
        underline: r.underline ? true : null,
        strike: r.strike ? true : null,
        fontSize: r.fontSize,
        color: r.color,
        highlight: r.highlight,
        font: r.font,
        position: r.position == VerticalPosition.baseline ? null : r.position,
      );
    }
    return out;
  }

  _Style? _style(String? name) {
    var current = name == null ? null : _styles[name];
    for (var i = 0; current != null && i < 10; i++) {
      if (current.para != null || current.pageBreakBefore) return current;
      current = current.parent == null ? null : _styles[current.parent];
    }
    return name == null ? null : _styles[name];
  }

  void _block(
    XmlStartElementEvent e,
    List<Block> out,
    int listLevel, [
    String? marker,
  ]) {
    switch (e.localName) {
      case 'p' || 'h':
        final styleName = e.attr('text:style-name');
        final style = _style(styleName);
        if (style?.pageBreakBefore ?? false) out.add(const PageBreak());
        final inlines = <Inline>[];
        _inlines(e, inlines, _run(styleName, RunStyle.plain));
        final level = e.localName == 'h'
            ? (int.tryParse(e.attr('text:outline-level') ?? '') ?? 1).clamp(
                1,
                6,
              )
            : 0;
        out.add(
          Paragraph(
            _merge(inlines),
            style: style?.para ?? ParagraphStyle.plain,
            headingLevel: level,
            list: marker == null
                ? null
                : ListInfo(
                    level: listLevel,
                    marker: marker,
                    ordered: marker != '•',
                  ),
          ),
        );
        if (style?.pageBreakAfter ?? false) out.add(const PageBreak());
      case 'list':
        var n = 0;
        _pull.children(e, (item) {
          if (item.localName != 'list-item' && item.localName != 'list-header')
            return;
          n++;
          var first = true;
          _pull.children(item, (child) {
            if (child.localName == 'list') {
              _block(child, out, listLevel + 1);
            } else {
              // Numbering style details are not resolved: bullets are shown,
              // which is honest for "Basic" fidelity.
              _block(
                child,
                out,
                listLevel,
                first ? (item.localName == 'list-header' ? '' : '•') : '',
              );
              first = false;
            }
          });
        });
        assert(n >= 0, 'items');
      case 'table':
        out.add(_table(e));
      case 'section' ||
          'index-body' ||
          'table-of-content' ||
          'alphabetical-index' ||
          'illustration-index':
        _pull.children(e, (child) => _block(child, out, listLevel));
      case 'soft-page-break':
        break;
      case 'frame':
        final inlines = <Inline>[];
        _frame(e, inlines);
        for (final i in inlines) {
          if (i is InlineImage)
            out.add(ImageBlock(i.imageId, width: i.width, height: i.height));
        }
    }
  }

  void _inlines(XmlStartElementEvent e, List<Inline> out, RunStyle style) {
    _pull.children(
      e,
      (child) {
        switch (child.localName) {
          case 'span':
            _inlines(child, out, _run(child.attr('text:style-name'), style));
          case 'a':
            final href = child.attr('xlink:href');
            _inlines(child, out, style.copyWith(link: href));
          case 's':
            out.add(
              TextRun(
                ' ' *
                    (int.tryParse(child.attr('text:c') ?? '') ?? 1).clamp(
                      1,
                      40,
                    ),
                style,
              ),
            );
          case 'tab':
            out.add(TextRun('\t', style));
          case 'line-break':
            out.add(TextRun('\n', style));
          case 'frame':
            _frame(child, out);
          case 'note':
            _pull.children(child, (n) {
              if (n.localName == 'note-citation') {
                out.add(
                  TextRun(
                    _pull.text(n),
                    style.copyWith(position: VerticalPosition.superscript),
                  ),
                );
              }
            });
          case 'bookmark' ||
              'bookmark-start' ||
              'bookmark-end' ||
              'soft-page-break' ||
              'annotation':
            break;
          default:
            _inlines(child, out, style);
        }
      },
      onText: (text) =>
          out.add(TextRun(text.replaceAll(RegExp(r'\s+'), ' '), style)),
    );
  }

  void _frame(XmlStartElementEvent frame, List<Inline> out) {
    final width = odfLength(frame.attr('svg:width')) ?? 200;
    final height = odfLength(frame.attr('svg:height')) ?? 150;
    _pull.children(frame, (child) {
      if (child.localName != 'image') return;
      final href = child.attr('xlink:href');
      if (href == null || href.startsWith('http')) return;
      if (!_images.containsKey(href)) {
        final lower = href.toLowerCase();
        final mime = lower.endsWith('.png')
            ? 'image/png'
            : (lower.endsWith('.jpg') || lower.endsWith('.jpeg'))
            ? 'image/jpeg'
            : lower.endsWith('.gif')
            ? 'image/gif'
            : null;
        final bytes = mime == null ? null : _zip.bytes(href);
        if (bytes == null) return;
        _images[href] = DocImage(bytes, mime: mime);
      }
      out.add(InlineImage(href, width: width, height: height));
    });
  }

  TableBlock _table(XmlStartElementEvent e) {
    final rows = <TableRow>[];
    final widths = <double>[];
    void row(XmlStartElementEvent r, {required bool header}) {
      final cells = <TableCell>[];
      _pull.children(r, (cell) {
        if (cell.localName == 'covered-table-cell') {
          cells.add(TableCell(const [], covered: true));
          return;
        }
        if (cell.localName != 'table-cell') return;
        final blocks = <Block>[];
        _pull.children(cell, (child) => _block(child, blocks, 0));
        final span =
            (int.tryParse(cell.attr('table:number-columns-spanned') ?? '') ?? 1)
                .clamp(1, 60);
        final rowSpan =
            (int.tryParse(cell.attr('table:number-rows-spanned') ?? '') ?? 1)
                .clamp(1, 1000);
        final repeat =
            (int.tryParse(cell.attr('table:number-columns-repeated') ?? '') ??
                    1)
                .clamp(1, 60);
        for (var i = 0; i < repeat; i++) {
          cells.add(
            TableCell(
              blocks,
              colSpan: span,
              rowSpan: rowSpan,
              fill: _styles[cell.attr('table:style-name')]?.cellFill,
            ),
          );
        }
      });
      // A covered cell directly after a spanning cell is part of that span.
      final merged = <TableCell>[];
      var skip = 0;
      for (final c in cells) {
        if (skip > 0 && c.covered) {
          skip--;
          continue;
        }
        merged.add(c);
        skip = c.colSpan - 1;
      }
      if (merged.isNotEmpty) rows.add(TableRow(merged, isHeader: header));
    }

    _pull.children(e, (child) {
      switch (child.localName) {
        case 'table-column':
          final repeat =
              (int.tryParse(
                        child.attr('table:number-columns-repeated') ?? '',
                      ) ??
                      1)
                  .clamp(1, 60);
          for (var i = 0; i < repeat; i++) {
            widths.add(72);
          }
        case 'table-header-rows':
          _pull.children(child, (r) {
            if (r.localName == 'table-row') row(r, header: true);
          });
        case 'table-row':
          row(child, header: false);
        case 'table-rows':
          _pull.children(child, (r) {
            if (r.localName == 'table-row') row(r, header: false);
          });
      }
    });
    return TableBlock(rows, columnWidths: widths, bordered: true);
  }

  static List<Inline> _merge(List<Inline> inlines) {
    final out = <Inline>[];
    for (final i in inlines) {
      final last = out.isEmpty ? null : out.last;
      if (i is TextRun && last is TextRun && i.style == last.style) {
        out[out.length - 1] = TextRun(last.text + i.text, last.style);
      } else {
        out.add(i);
      }
    }
    return out;
  }
}

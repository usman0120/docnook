import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/engines/archive/safe_zip.dart';
import 'package:docnook/engines/office/docx/docx_numbering.dart';
import 'package:docnook/engines/office/docx/docx_styles.dart';
import 'package:docnook/engines/office/xml_events.dart';

/// Reads .docx / .dotx into a [DocModel].
///
/// Fidelity is "Good": paragraph and character styles, headings, lists,
/// tables with merged cells, pictures, page breaks, simplified headers and
/// footers, footnotes. Floating layout (text boxes, wrapped pictures,
/// columns) is flattened into the text flow and flagged as simplified.
/// Runs in an isolate (CLAUDE.md rule 4).
abstract final class DocxParser {
  static DocModel parseFile(String path) {
    final zip = SafeZip.open(path);
    try {
      return _DocxReader(zip).read();
    } finally {
      zip.close();
    }
  }

  static DocModel parseBytes(Uint8List bytes) {
    final zip = SafeZip.fromBytes(bytes);
    try {
      return _DocxReader(zip).read();
    } finally {
      zip.close();
    }
  }
}

/// Image formats the platform can decode; others (EMF, WMF) are dropped.
const _imageMimes = <String, String>{
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'gif': 'image/gif',
  'bmp': 'image/bmp',
  'webp': 'image/webp',
};

/// Total embedded picture bytes kept in memory for one document.
const _maxImageBytes = 96 * 1024 * 1024;

final class _Picture {
  _Picture(this.relId, this.width, this.height);
  final String relId;
  final double width;
  final double height;
}

/// State of the paragraph being read.
final class _ParagraphContext {
  _ParagraphContext(this.props, this.styleRun);
  ParaProps props;
  RunProps styleRun;
  final inlines = <Inline>[];
  final trailing = <Block>[];
  bool breakBefore = false;
  bool breakAfter = false;
}

final class _DocxReader {
  _DocxReader(this._zip);

  final SafeZip _zip;
  late final DocxStyles _styles;
  late final DocxNumbering _numbering;
  final _images = <String, DocImage>{};
  int _imageBytes = 0;
  bool _simplified = false;

  /// Relationships and reader of the part currently being walked. Headers,
  /// footers and footnotes have their own relationship files.
  Map<String, String> _rels = const {};
  String _partDir = 'word/';
  late XmlPull _pull;

  final _footnotes = <String, List<Block>>{};
  final _footnoteOrder = <String>[];
  SectionProps? _pendingSection;

  DocModel read() {
    final documentPath = _zip.has('word/document.xml')
        ? 'word/document.xml'
        : _zip.findIgnoreCase('word/document.xml');
    final xml = documentPath == null ? null : _zip.text(documentPath);
    if (xml == null) {
      throw const DocNookFailure.corrupt(detail: 'docx: no document part');
    }

    _styles = DocxStyles.parse(_zip.text('word/styles.xml'));
    _numbering = DocxNumbering.parse(_zip.text('word/numbering.xml'));
    _readNotes('word/footnotes.xml', 'footnote');

    _usePart('word/document.xml');
    _pull = XmlPull(xml);
    final body = _pull.find('body');
    if (body == null) {
      throw const DocNookFailure.corrupt(detail: 'docx: no body');
    }

    final sections = <DocSection>[];
    var blocks = <Block>[];
    void closeSection(SectionProps props) {
      // Header and footer parts have their own reader; keep the body's.
      final savedPull = _pull;
      // Resolve both paths first: reading a part switches relationships.
      final headerPath = _partPath(props.headerRelId);
      final footerPath = _partPath(props.footerRelId);
      final header = _readHeaderFooter(headerPath, 'hdr');
      final footer = _readHeaderFooter(footerPath, 'ftr');
      _pull = savedPull;
      _usePart('word/document.xml');
      sections.add(
        DocSection(
          blocks: blocks,
          page: props.page,
          header: header,
          footer: footer,
        ),
      );
      blocks = <Block>[];
    }

    _pull.children(body, (child) {
      if (child.localName == 'sectPr') {
        closeSection(SectionProps.read(_pull, child));
        return;
      }
      _blockChild(child, blocks);
      final pending = _pendingSection;
      if (pending != null) {
        _pendingSection = null;
        closeSection(pending);
      }
    });
    if (blocks.isNotEmpty || sections.isEmpty) {
      sections.add(DocSection(blocks: blocks));
    }

    _appendFootnotes(sections.last.blocks);

    return DocModel(
      sections: sections,
      images: _images,
      title: _readTitle(),
      simplified: _simplified,
    );
  }

  void _usePart(String partPath) {
    final slash = partPath.lastIndexOf('/');
    _partDir = partPath.substring(0, slash + 1);
    final relsPath = '${_partDir}_rels/${partPath.substring(slash + 1)}.rels';
    _rels = _readRels(_zip.text(relsPath));
  }

  Map<String, String> _readRels(String? xml) {
    final result = <String, String>{};
    if (xml == null) return result;
    for (final event in xmlEvents(xml)) {
      if (event is! XmlStartElementEvent || event.localName != 'Relationship') {
        continue;
      }
      final id = event.attr('Id');
      final target = event.attr('Target');
      if (id == null || target == null) continue;
      result[id] = event.attr('TargetMode') == 'External'
          ? 'external:$target'
          : target;
    }
    return result;
  }

  /// Resolves an internal relationship target to a path inside the archive.
  String? _partPath(String? relId) {
    final target = _rels[relId];
    if (target == null || target.startsWith('external:')) return null;
    final raw = target.startsWith('/')
        ? target.substring(1)
        : '$_partDir$target';
    final parts = <String>[];
    for (final part in raw.split('/')) {
      if (part == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (part.isNotEmpty && part != '.') {
        parts.add(part);
      }
    }
    return parts.join('/');
  }

  String? _readTitle() {
    final xml = _zip.text('docProps/core.xml');
    if (xml == null) return null;
    final pull = XmlPull(xml);
    final element = pull.find('title');
    if (element == null) return null;
    final title = pull.text(element).trim();
    return title.isEmpty ? null : title;
  }

  List<Block> _readHeaderFooter(String? path, String rootName) {
    final xml = path == null ? null : _zip.text(path);
    if (xml == null) return const [];
    _usePart(path!);
    _pull = XmlPull(xml);
    final blocks = <Block>[];
    final root = _pull.find(rootName);
    if (root != null) {
      _pull.children(root, (child) => _blockChild(child, blocks));
    }
    // Keep only what a simplified header can show: non-empty text lines.
    return [
      for (final block in blocks)
        if (block is Paragraph && !block.isEmpty) block,
    ];
  }

  void _readNotes(String path, String element) {
    final xml = _zip.text(path);
    if (xml == null) return;
    _usePart(path);
    _pull = XmlPull(xml);
    final root = _pull.find('${element}s');
    if (root == null) return;
    _pull.children(root, (note) {
      if (note.localName != element) return;
      final id = note.attr('w:id');
      final type = note.attr('w:type');
      // Separator pseudo-notes carry no content.
      if (id == null || (type != null && type != 'normal')) return;
      final blocks = <Block>[];
      _pull.children(note, (child) => _blockChild(child, blocks));
      _footnotes[id] = blocks;
    });
  }

  void _appendFootnotes(List<Block> blocks) {
    if (_footnoteOrder.isEmpty) return;
    const small = RunStyle(fontSize: 9);
    blocks.add(
      const Paragraph([
        TextRun('Footnotes', RunStyle(bold: true, fontSize: 10)),
      ], style: ParagraphStyle(spaceBefore: 18, spaceAfter: 4)),
    );
    for (var i = 0; i < _footnoteOrder.length; i++) {
      final content = _footnotes[_footnoteOrder[i]] ?? const [];
      final text = [
        for (final block in content)
          if (block is Paragraph) block.plainText.trim(),
      ].where((t) => t.isNotEmpty).join(' ');
      blocks.add(
        Paragraph([
          TextRun('${i + 1}. $text', small),
        ], style: const ParagraphStyle(spaceAfter: 2)),
      );
    }
  }

  // ---------------------------------------------------------------- blocks

  /// Handles one block-level child of a body, cell, text box or note.
  void _blockChild(XmlStartElementEvent element, List<Block> out) {
    switch (element.localName) {
      case 'p':
        _readParagraph(element, out);
      case 'tbl':
        out.add(_readTable(element));
      case 'sdt':
        _pull.children(element, (child) {
          if (child.localName == 'sdtContent') {
            _pull.children(child, (inner) => _blockChild(inner, out));
          }
        });
      case 'AlternateContent':
        // Choice and Fallback hold the same content twice; read Choice only.
        _pull.children(element, (child) {
          if (child.localName == 'Choice') {
            _pull.children(child, (inner) => _blockChild(inner, out));
          }
        });
      case 'ins' || 'moveTo' || 'customXml' || 'smartTag':
        _pull.children(element, (inner) => _blockChild(inner, out));
    }
  }

  void _readParagraph(XmlStartElementEvent element, List<Block> out) {
    final (basePara, baseRun) = _styles.resolve(null);
    final context = _ParagraphContext(basePara, baseRun);
    var direct = ParaProps();

    _pull.children(element, (child) {
      if (child.localName == 'pPr') {
        direct = ParaProps.read(_pull, child);
        final (stylePara, styleRun) = _styles.resolve(direct.styleId);
        context
          ..props = stylePara.merged(direct)
          ..styleRun = styleRun;
        if (direct.section != null) _pendingSection = direct.section;
      } else {
        _inlineChild(child, context, null);
      }
    });

    final props = context.props;
    if ((props.pageBreakBefore ?? false) || context.breakBefore) {
      if (out.isNotEmpty && out.last is! PageBreak) out.add(const PageBreak());
    }

    final inlines = _mergeRuns(context.inlines);
    final pictures = inlines.whereType<InlineImage>().toList();
    final hasText = inlines.any(
      (i) => i is TextRun && i.text.trim().isNotEmpty,
    );

    if (pictures.isNotEmpty && !hasText) {
      // A paragraph that only holds pictures becomes picture blocks.
      for (final picture in pictures) {
        out.add(
          ImageBlock(
            picture.imageId,
            width: picture.width,
            height: picture.height,
            align: props.align ?? TextAlignment.start,
          ),
        );
      }
    } else {
      var heading = _styles.headingLevelOf(direct.styleId);
      final outline = props.outlineLevel;
      if (heading == 0 && outline != null && outline >= 0 && outline < 9) {
        heading = (outline + 1).clamp(1, 6);
      }

      ListInfo? list;
      final numId = props.numId;
      // Headings numbered through a list keep their number as plain text.
      if (numId != null && numId != '0' && hasText) {
        list = _numbering.next(numId, props.numLevel ?? 0);
      }

      out.add(
        Paragraph(
          inlines,
          style: props.toStyle(inList: list != null),
          headingLevel: heading,
          list: list,
        ),
      );
    }

    out.addAll(context.trailing);
    if (context.breakAfter) out.add(const PageBreak());
  }

  /// Joins neighbouring runs that share a style; Word splits text into many
  /// runs for spell-check and revision marks.
  List<Inline> _mergeRuns(List<Inline> inlines) {
    if (inlines.length < 2) return inlines;
    final merged = <Inline>[];
    for (final inline in inlines) {
      final last = merged.isEmpty ? null : merged.last;
      if (inline is TextRun && last is TextRun && inline.style == last.style) {
        merged[merged.length - 1] = TextRun(
          last.text + inline.text,
          last.style,
        );
      } else {
        merged.add(inline);
      }
    }
    return merged;
  }

  // --------------------------------------------------------------- inlines

  void _inlineChild(
    XmlStartElementEvent element,
    _ParagraphContext context,
    String? link,
  ) {
    switch (element.localName) {
      case 'r':
        _readRun(element, context, link);
      case 'hyperlink':
        final target = _rels[element.attr('r:id')];
        final anchor = element.attr('w:anchor');
        final href = target != null
            ? (target.startsWith('external:') ? target.substring(9) : target)
            : (anchor != null ? '#$anchor' : null);
        _pull.children(
          element,
          (child) => _inlineChild(child, context, href ?? link),
        );
      case 'ins' ||
          'moveTo' ||
          'smartTag' ||
          'fldSimple' ||
          'customXml' ||
          'dir' ||
          'bdo':
        _pull.children(element, (child) => _inlineChild(child, context, link));
      case 'sdt':
        _pull.children(element, (child) {
          if (child.localName == 'sdtContent') {
            _pull.children(
              child,
              (inner) => _inlineChild(inner, context, link),
            );
          }
        });
      case 'AlternateContent':
        _pull.children(element, (child) {
          if (child.localName == 'Choice') {
            _pull.children(
              child,
              (inner) => _inlineChild(inner, context, link),
            );
          }
        });
      // 'del' and 'moveFrom' hold removed text and are skipped.
    }
  }

  void _readRun(
    XmlStartElementEvent element,
    _ParagraphContext context,
    String? link,
  ) {
    var props = context.styleRun;
    RunStyle? style;
    final text = StringBuffer();

    RunStyle currentStyle() => style ??= props.toStyle(link: link);

    void flush() {
      if (text.isEmpty) return;
      if (!(props.hidden ?? false)) {
        final value = (props.caps ?? false)
            ? text.toString().toUpperCase()
            : text.toString();
        context.inlines.add(TextRun(value, currentStyle()));
      }
      text.clear();
    }

    void runChild(XmlStartElementEvent child) {
      switch (child.localName) {
        case 'rPr':
          final direct = RunProps.read(_pull, child);
          props = context.styleRun
              .merged(_styles.characterStyle(direct.styleId))
              .merged(direct);
          style = null;
        case 't':
          text.write(_pull.text(child));
        case 'tab':
          text.write('\t');
        case 'cr':
          text.write('\n');
        case 'br':
          final type = child.attr('w:type');
          if (type == 'page') {
            flush();
            if (context.inlines.isEmpty) {
              context.breakBefore = true;
            } else {
              context.breakAfter = true;
            }
          } else if (type != 'column') {
            text.write('\n');
          }
        case 'noBreakHyphen':
          text.write('‑');
        case 'sym':
          text.write(_symbol(child.attr('w:char')));
        case 'footnoteReference':
          final id = child.attr('w:id');
          if (id != null && _footnotes.containsKey(id)) {
            flush();
            if (!_footnoteOrder.contains(id)) _footnoteOrder.add(id);
            context.inlines.add(
              TextRun(
                '${_footnoteOrder.indexOf(id) + 1}',
                currentStyle().copyWith(position: VerticalPosition.superscript),
              ),
            );
          }
        case 'drawing' || 'pict' || 'object':
          flush();
          _readGraphic(child, context);
        case 'AlternateContent':
          _pull.children(child, (inner) {
            if (inner.localName == 'Choice') _pull.children(inner, runChild);
          });
        // 'delText', 'instrText' and field markers are not shown.
      }
    }

    _pull.children(element, runChild);
    flush();
  }

  static String _symbol(String? hex) {
    final code = int.tryParse(hex ?? '', radix: 16);
    if (code == null) return '';
    // Symbol-font characters live in the private-use area; without the font
    // the closest honest rendering is a bullet.
    if (code >= 0xF000 && code <= 0xF8FF) return '•';
    return String.fromCharCode(code);
  }

  /// Reads a drawing (DrawingML or VML): pictures become inline images, text
  /// boxes are flattened to blocks after the paragraph.
  void _readGraphic(XmlStartElementEvent element, _ParagraphContext context) {
    final pictures = <_Picture>[];
    var width = 0.0;
    var height = 0.0;
    var floating = false;

    void walk(XmlStartElementEvent node) {
      switch (node.localName) {
        case 'anchor':
          floating = true;
          _pull.children(node, walk);
        case 'extent':
          // The first extent is the drawing's own size.
          if (width == 0) {
            width = Units.emu(node.attr('cx'));
            height = Units.emu(node.attr('cy'));
          }
        case 'blip':
          final id = node.attr('r:embed') ?? node.attr('r:link');
          if (id != null) pictures.add(_Picture(id, width, height));
        case 'imagedata':
          final id = node.attr('r:id');
          if (id != null) pictures.add(_Picture(id, width, height));
        case 'shape':
          // VML size lives in a CSS-like style attribute, in points.
          final style = node.attr('style') ?? '';
          final w = RegExp(r'width:([\d.]+)pt').firstMatch(style);
          final h = RegExp(r'height:([\d.]+)pt').firstMatch(style);
          if (w != null && h != null && width == 0) {
            width = double.parse(w.group(1)!);
            height = double.parse(h.group(1)!);
          }
          _pull.children(node, walk);
        case 'txbxContent':
          _simplified = true;
          _pull.children(node, (child) => _blockChild(child, context.trailing));
        default:
          _pull.children(node, walk);
      }
    }

    _pull.children(element, walk);
    if (floating) _simplified = true;

    for (final picture in pictures) {
      final id = _loadImage(picture.relId);
      if (id == null) {
        _simplified = true;
        continue;
      }
      // Size comes from the drawing; fall back to a sensible default.
      final w = picture.width > 0 ? picture.width : (width > 0 ? width : 240.0);
      final h = picture.height > 0
          ? picture.height
          : (height > 0 ? height : 180.0);
      context.inlines.add(InlineImage(id, width: w, height: h));
    }
  }

  /// Loads a picture part once and returns its image id, or null when the
  /// format cannot be shown or the memory budget is spent.
  String? _loadImage(String relId) {
    final path = _partPath(relId);
    if (path == null) return null;
    if (_images.containsKey(path)) return path;
    final dot = path.lastIndexOf('.');
    final mime = dot < 0
        ? null
        : _imageMimes[path.substring(dot + 1).toLowerCase()];
    if (mime == null) return null;
    final size = _zip.sizeOf(path);
    if (size == 0 || _imageBytes + size > _maxImageBytes) return null;
    final bytes = _zip.bytes(path);
    if (bytes == null) return null;
    _imageBytes += bytes.length;
    _images[path] = DocImage(bytes, mime: mime);
    return path;
  }

  // ---------------------------------------------------------------- tables

  TableBlock _readTable(XmlStartElementEvent element) {
    final widths = <double>[];
    final rows = <TableRow>[];
    bool? bordered;
    var cellBorders = false;
    // Top cell of each open vertical merge, by grid column.
    final open = <int, TableCell>{};

    void readRow(XmlStartElementEvent row) {
      final cells = <TableCell>[];
      var isHeader = false;
      var column = 0;

      void readCell(XmlStartElementEvent cell) {
        final blocks = <Block>[];
        var span = 1;
        String? merge;
        int? fill;
        _pull.children(cell, (child) {
          if (child.localName == 'tcPr') {
            _pull.children(child, (p) {
              switch (p.localName) {
                case 'gridSpan':
                  span = (int.tryParse(p.attr('w:val') ?? '') ?? 1).clamp(
                    1,
                    63,
                  );
                case 'vMerge':
                  merge = p.attr('w:val') ?? 'continue';
                case 'shd':
                  fill = parseHexColor(p.attr('w:fill'));
                case 'tcBorders':
                  if (DocxStyles.readHasBorders(_pull, p)) cellBorders = true;
              }
            });
          } else {
            _blockChild(child, blocks);
          }
        });

        final top = open[column];
        if (merge == 'continue' && top != null) {
          top.rowSpan++;
          cells.add(TableCell(const [], colSpan: span, covered: true));
        } else {
          final built = TableCell(blocks, colSpan: span, fill: fill);
          cells.add(built);
          if (merge == 'restart') {
            open[column] = built;
          } else {
            open.remove(column);
          }
        }
        column += span;
      }

      void rowChild(XmlStartElementEvent child) {
        switch (child.localName) {
          case 'trPr':
            _pull.children(child, (p) {
              if (p.localName == 'tblHeader') isHeader = true;
            });
          case 'tc':
            readCell(child);
          case 'sdt':
            _pull.children(child, (inner) {
              if (inner.localName == 'sdtContent') {
                _pull.children(inner, rowChild);
              }
            });
        }
      }

      _pull.children(row, rowChild);
      if (cells.isNotEmpty) rows.add(TableRow(cells, isHeader: isHeader));
    }

    _pull.children(element, (child) {
      switch (child.localName) {
        case 'tblPr':
          _pull.children(child, (p) {
            if (p.localName == 'tblStyle') {
              bordered ??= _styles.tableBordered(p.attr('w:val'));
            } else if (p.localName == 'tblBorders') {
              bordered = DocxStyles.readHasBorders(_pull, p);
            }
          });
        case 'tblGrid':
          _pull.children(child, (g) {
            if (g.localName == 'gridCol') {
              widths.add(Units.twips(g.attr('w:w')));
            }
          });
        case 'tr':
          readRow(child);
        case 'sdt':
          _pull.children(child, (inner) {
            if (inner.localName == 'sdtContent') {
              _pull.children(inner, (r) {
                if (r.localName == 'tr') readRow(r);
              });
            }
          });
      }
    });

    return TableBlock(
      rows,
      columnWidths: widths,
      bordered: (bordered ?? false) || cellBorders,
    );
  }
}

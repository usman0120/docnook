import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/engines/archive/safe_zip.dart';
import 'package:docnook/engines/office/docx/docx_styles.dart'
    show Units, classifyFont, parseHexColor;
import 'package:docnook/engines/office/xml_events.dart';

/// Reads .pptx into a [DocModel] of [SlideFrame]s (Basic fidelity): slide
/// size, text boxes with run styles, pictures, rectangles/ellipses/lines,
/// solid fills, slide titles and speaker notes. Placeholders inherit
/// position from the layout and master when the slide does not set it.
abstract final class PptxParser {
  static DocModel parseFile(String path) {
    final zip = SafeZip.open(path);
    try {
      return _PptxReader(zip).read();
    } finally {
      zip.close();
    }
  }
}

const _themeColors = {
  'tx1': 0xFF000000, 'dk1': 0xFF000000, 'bg1': 0xFFFFFFFF, 'lt1': 0xFFFFFFFF, //
  'tx2': 0xFF44546A, 'dk2': 0xFF44546A, 'bg2': 0xFFE7E6E6, 'lt2': 0xFFE7E6E6,
  'accent1': 0xFF4472C4, 'accent2': 0xFFED7D31, 'accent3': 0xFFA5A5A5,
  'accent4': 0xFFFFC000, 'accent5': 0xFF5B9BD5, 'accent6': 0xFF70AD47,
  'hlink': 0xFF0563C1,
};

final class _Placeholder {
  _Placeholder(this.x, this.y, this.w, this.h);
  final double x;
  final double y;
  final double w;
  final double h;
}

final class _PptxReader {
  _PptxReader(this._zip);

  final SafeZip _zip;
  final _images = <String, DocImage>{};
  int _imageBytes = 0;
  double _width = 720;
  double _height = 540;
  Map<String, int> _theme = Map.of(_themeColors);

  DocModel read() {
    final presentation = _zip.text('ppt/presentation.xml');
    if (presentation == null)
      throw const DocNookFailure.corrupt(detail: 'pptx: presentation');
    final rels = _rels('ppt/_rels/presentation.xml.rels', 'ppt/');
    _readTheme();

    final slideIds = <String>[];
    final pull = XmlPull(presentation);
    final root = pull.find('presentation');
    if (root == null) throw const DocNookFailure.corrupt(detail: 'pptx: root');
    pull.children(root, (child) {
      if (child.localName == 'sldSz') {
        _width = Units.emu(child.attr('cx'));
        _height = Units.emu(child.attr('cy'));
      } else if (child.localName == 'sldIdLst') {
        pull.children(child, (id) {
          final rid = id.attr('r:id');
          if (rid != null) slideIds.add(rid);
        });
      }
    });
    if (_width < 10 || _height < 10) {
      _width = 720;
      _height = 540;
    }

    final slides = <Block>[];
    for (final rid in slideIds) {
      final path = rels[rid];
      if (path == null) continue;
      final frame = _slide(path);
      if (frame != null) slides.add(frame);
    }
    if (slides.isEmpty)
      throw const DocNookFailure.corrupt(detail: 'pptx: no slides');
    return DocModel(
      sections: [DocSection(blocks: slides)],
      images: _images,
      simplified: true,
    );
  }

  void _readTheme() {
    final xml = _zip.text('ppt/theme/theme1.xml');
    if (xml == null) return;
    final pull = XmlPull(xml);
    final scheme = pull.find('clrScheme');
    if (scheme == null) return;
    pull.children(scheme, (slot) {
      pull.children(slot, (c) {
        final value = c.attr('val') == null
            ? null
            : parseHexColor(c.attr('val'));
        final sys = c.attr('lastClr') == null
            ? null
            : parseHexColor(c.attr('lastClr'));
        final color = value ?? sys;
        if (color != null) _theme[slot.localName] = color;
      });
    });
    _theme['tx1'] = _theme['dk1'] ?? 0xFF000000;
    _theme['bg1'] = _theme['lt1'] ?? 0xFFFFFFFF;
    _theme['tx2'] = _theme['dk2'] ?? _theme['tx2']!;
    _theme['bg2'] = _theme['lt2'] ?? _theme['bg2']!;
  }

  Map<String, String> _rels(String relsPath, String dir) {
    final out = <String, String>{};
    final xml = _zip.text(relsPath);
    if (xml == null) return out;
    for (final e in xmlEvents(xml)) {
      if (e is! XmlStartElementEvent || e.localName != 'Relationship') continue;
      final id = e.attr('Id');
      final target = e.attr('Target');
      if (id == null || target == null || e.attr('TargetMode') == 'External')
        continue;
      out[id] = _resolve(dir, target);
    }
    return out;
  }

  static String _resolve(String dir, String target) {
    final raw = target.startsWith('/') ? target.substring(1) : '$dir$target';
    final parts = <String>[];
    for (final p in raw.split('/')) {
      if (p == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (p.isNotEmpty && p != '.') {
        parts.add(p);
      }
    }
    return parts.join('/');
  }

  static String _dirOf(String path) =>
      path.substring(0, path.lastIndexOf('/') + 1);
  static String _relsOf(String path) =>
      '${_dirOf(path)}_rels/${path.substring(path.lastIndexOf('/') + 1)}.rels';

  /// Placeholder positions declared by a layout or master, by type and idx.
  Map<String, _Placeholder> _placeholders(String? path) {
    final out = <String, _Placeholder>{};
    if (path == null) return out;
    final xml = _zip.text(path);
    if (xml == null) return out;
    final pull = XmlPull(xml);
    final tree = pull.find('spTree');
    if (tree == null) return out;
    pull.children(tree, (sp) {
      if (sp.localName != 'sp') return;
      String? key;
      _Placeholder? box;
      void walk(XmlStartElementEvent e) {
        switch (e.localName) {
          case 'ph':
            key = '${e.attr('type') ?? 'body'}:${e.attr('idx') ?? ''}';
          case 'off':
            box = _Placeholder(
              Units.emu(e.attr('x')),
              Units.emu(e.attr('y')),
              box?.w ?? 0,
              box?.h ?? 0,
            );
          case 'ext':
            box = _Placeholder(
              box?.x ?? 0,
              box?.y ?? 0,
              Units.emu(e.attr('cx')),
              Units.emu(e.attr('cy')),
            );
          case 'txBody':
            break;
          default:
            pull.children(e, walk);
        }
      }

      pull.children(sp, walk);
      if (key != null && box != null) {
        out[key!] = box!;
        out.putIfAbsent('${key!.split(':').first}:', () => box!);
      }
    });
    return out;
  }

  SlideFrame? _slide(String path) {
    final xml = _zip.text(path);
    if (xml == null) return null;
    final rels = _rels(_relsOf(path), _dirOf(path));
    final layoutPath = rels.values
        .where((p) => p.contains('slideLayout'))
        .firstOrNull;
    final layoutRels = layoutPath == null
        ? const <String, String>{}
        : _rels(_relsOf(layoutPath), _dirOf(layoutPath));
    final masterPath = layoutRels.values
        .where((p) => p.contains('slideMaster'))
        .firstOrNull;
    final inherited = {
      ..._placeholders(masterPath),
      ..._placeholders(layoutPath),
    };

    final items = <SlideItem>[];
    int? background;
    String? title;
    final pull = XmlPull(xml);
    final root = pull.find('sld');
    if (root == null) return null;

    late void Function(XmlStartElementEvent, double, double, double) shape;

    void shapes(XmlStartElementEvent tree, double ox, double oy, double scale) {
      pull.children(tree, (node) => shape(node, ox, oy, scale));
    }

    shape = (node, ox, oy, scale) {
      switch (node.localName) {
        case 'sp':
          final item = _shape(pull, node, inherited, ox, oy, scale);
          if (item case SlideText(
            :final isTitle,
            :final paragraphs,
          ) when isTitle) {
            title ??= paragraphs.map((p) => p.plainText).join(' ').trim();
          }
          if (item != null) items.add(item);
        case 'pic':
          final pic = _picture(pull, node, rels, ox, oy, scale);
          if (pic != null) items.add(pic);
        case 'cxnSp':
          final line = _shape(
            pull,
            node,
            inherited,
            ox,
            oy,
            scale,
            forceLine: true,
          );
          if (line != null) items.add(line);
        case 'grpSp':
          // grpSpPr comes first and sets the transform for the members:
          // a member at (cx, cy) in child space lands at off + (c - chOff) * k.
          var gox = ox, goy = oy, gk = scale;
          pull.children(node, (g) {
            if (g.localName == 'grpSpPr') {
              var gx = 0.0, gy = 0.0, chx = 0.0, chy = 0.0, gw = 0.0, chw = 0.0;
              pull.children(g, (xf) {
                if (xf.localName != 'xfrm') return;
                pull.children(xf, (v) {
                  switch (v.localName) {
                    case 'off':
                      gx = Units.emu(v.attr('x'));
                      gy = Units.emu(v.attr('y'));
                    case 'ext':
                      gw = Units.emu(v.attr('cx'));
                    case 'chOff':
                      chx = Units.emu(v.attr('x'));
                      chy = Units.emu(v.attr('y'));
                    case 'chExt':
                      chw = Units.emu(v.attr('cx'));
                  }
                });
              });
              final k = chw > 0 && gw > 0 ? gw / chw : 1.0;
              gk = scale * k;
              gox = ox + (gx - chx * k) * scale;
              goy = oy + (gy - chy * k) * scale;
            } else {
              shape(g, gox, goy, gk);
            }
          });
      }
    };

    pull.children(root, (child) {
      if (child.localName != 'cSld') return;
      pull.children(child, (c) {
        if (c.localName == 'bg') {
          pull.children(c, (bgPr) {
            pull.children(bgPr, (fill) {
              if (fill.localName == 'solidFill')
                background = _color(pull, fill);
            });
          });
        } else if (c.localName == 'spTree') {
          shapes(c, 0, 0, 1);
        }
      });
    });

    return SlideFrame(
      width: _width,
      height: _height,
      items: items,
      background: background,
      title: title,
      notes: _notes(rels),
    );
  }

  String? _notes(Map<String, String> rels) {
    final path = rels.values.where((p) => p.contains('notesSlide')).firstOrNull;
    final xml = path == null ? null : _zip.text(path);
    if (xml == null) return null;
    final buffer = StringBuffer();
    for (final e in xmlEvents(xml)) {
      if (e is XmlTextEvent) buffer.write(e.value);
      if (e is XmlEndElementEvent && e.localName == 'p') buffer.write('\n');
    }
    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _color(XmlPull pull, XmlStartElementEvent fill) {
    int? out;
    pull.children(fill, (c) {
      switch (c.localName) {
        case 'srgbClr':
          out = parseHexColor(c.attr('val'));
        case 'schemeClr':
          out = _theme[c.attr('val')];
        case 'sysClr':
          out = parseHexColor(c.attr('lastClr'));
      }
      // lumMod/lumOff/alpha children are ignored (Basic fidelity).
    });
    return out;
  }

  SlideItem? _shape(
    XmlPull pull,
    XmlStartElementEvent sp,
    Map<String, _Placeholder> inherited,
    double ox,
    double oy,
    double scale, {
    bool forceLine = false,
  }) {
    double? x, y, w, h;
    String? phKey;
    var isTitle = false;
    var geometry = forceLine ? 'line' : 'rect';
    int? fill;
    int? stroke;
    var strokeWidth = 1.0;
    var noFill = false;
    final paragraphs = <Paragraph>[];
    var anchor = SlideAnchor.top;

    pull.children(sp, (child) {
      switch (child.localName) {
        case 'nvSpPr' || 'nvCxnSpPr':
          pull.children(child, (nv) {
            pull.children(nv, (ph) {
              if (ph.localName == 'ph') {
                final type = ph.attr('type') ?? 'body';
                isTitle = type == 'title' || type == 'ctrTitle';
                phKey = '$type:${ph.attr('idx') ?? ''}';
              }
            });
          });
        case 'spPr':
          pull.children(child, (p) {
            switch (p.localName) {
              case 'xfrm':
                pull.children(p, (v) {
                  if (v.localName == 'off') {
                    x = Units.emu(v.attr('x'));
                    y = Units.emu(v.attr('y'));
                  } else if (v.localName == 'ext') {
                    w = Units.emu(v.attr('cx'));
                    h = Units.emu(v.attr('cy'));
                  }
                });
              case 'prstGeom':
                geometry = p.attr('prst') ?? geometry;
              case 'solidFill':
                fill = _color(pull, p);
              case 'noFill':
                noFill = true;
              case 'ln':
                strokeWidth = (Units.emu(p.attr('w')) * scale)
                    .clamp(0.5, 12)
                    .toDouble();
                pull.children(p, (l) {
                  if (l.localName == 'solidFill') stroke = _color(pull, l);
                });
            }
          });
        case 'txBody':
          pull.children(child, (t) {
            if (t.localName == 'bodyPr') {
              anchor = switch (t.attr('anchor')) {
                'ctr' => SlideAnchor.middle,
                'b' => SlideAnchor.bottom,
                _ => SlideAnchor.top,
              };
            } else if (t.localName == 'p') {
              final p = _paragraph(pull, t, isTitle);
              paragraphs.add(p);
            }
          });
      }
    });

    if ((x == null || w == null) && phKey != null) {
      final box = inherited[phKey] ?? inherited['${phKey!.split(':').first}:'];
      if (box != null) {
        x ??= box.x;
        y ??= box.y;
        w ??= box.w;
        h ??= box.h;
      }
    }
    if (x == null || w == null || h == null) return null;
    final rx = ox + x! * scale,
        ry = oy + (y ?? 0) * scale,
        rw = w! * scale,
        rh = h! * scale;

    final hasText = paragraphs.any((p) => !p.isEmpty);
    if (hasText) {
      return SlideText(
        rx,
        ry,
        rw,
        rh,
        paragraphs: paragraphs,
        fill: noFill ? null : fill,
        stroke: stroke,
        anchor: anchor,
        isTitle: isTitle,
      );
    }
    final kind = switch (geometry) {
      'ellipse' => SlideShapeKind.ellipse,
      'roundRect' => SlideShapeKind.roundedRectangle,
      'line' || 'straightConnector1' => SlideShapeKind.line,
      _ => SlideShapeKind.rectangle,
    };
    if ((noFill || fill == null) &&
        stroke == null &&
        kind != SlideShapeKind.line)
      return null;
    return SlideShape(
      rx,
      ry,
      rw,
      rh,
      kind: kind,
      fill: noFill ? null : fill,
      stroke: stroke ?? (kind == SlideShapeKind.line ? 0xFF5F5B53 : null),
      strokeWidth: strokeWidth,
    );
  }

  Paragraph _paragraph(XmlPull pull, XmlStartElementEvent p, bool isTitle) {
    final runs = <Inline>[];
    var align = TextAlignment.start;
    var level = 0;
    var bullet = false;
    String? bulletChar;
    double? defaultSize;

    RunStyle readRunProps(XmlStartElementEvent rPr) {
      final size = double.tryParse(rPr.attr('sz') ?? '');
      int? color;
      String? font;
      pull.children(rPr, (c) {
        if (c.localName == 'solidFill') color = _color(pull, c);
        if (c.localName == 'latin') font = c.attr('typeface');
      });
      return RunStyle(
        bold: rPr.attr('b') == '1',
        italic: rPr.attr('i') == '1',
        underline: (rPr.attr('u') ?? 'none') != 'none',
        strike: (rPr.attr('strike') ?? 'noStrike') != 'noStrike',
        fontSize: size == null
            ? (defaultSize ?? (isTitle ? 36 : 18))
            : size / 100,
        color: color,
        font: font == null || font!.startsWith('+')
            ? null
            : classifyFont(font!),
      );
    }

    pull.children(p, (c) {
      switch (c.localName) {
        case 'pPr':
          level = int.tryParse(c.attr('lvl') ?? '') ?? 0;
          align = switch (c.attr('algn')) {
            'ctr' => TextAlignment.center,
            'r' => TextAlignment.end,
            'just' => TextAlignment.justify,
            _ => TextAlignment.start,
          };
          pull.children(c, (b) {
            if (b.localName == 'buChar') {
              bullet = true;
              bulletChar = b.attr('char');
            } else if (b.localName == 'buAutoNum') {
              bullet = true;
              bulletChar = '•';
            } else if (b.localName == 'defRPr') {
              final s = double.tryParse(b.attr('sz') ?? '');
              if (s != null) defaultSize = s / 100;
            }
          });
        case 'r':
          var style = RunStyle(
            fontSize: defaultSize ?? (isTitle ? 36 : 18),
            bold: isTitle,
          );
          var text = '';
          pull.children(c, (rc) {
            if (rc.localName == 'rPr') style = readRunProps(rc);
            if (rc.localName == 't') text = pull.text(rc);
          });
          runs.add(TextRun(text, style));
        case 'br':
          runs.add(TextRun('\n', RunStyle(fontSize: defaultSize ?? 18)));
        case 'fld':
          pull.children(c, (rc) {
            if (rc.localName == 't')
              runs.add(
                TextRun(pull.text(rc), RunStyle(fontSize: defaultSize ?? 18)),
              );
          });
      }
    });

    final marker = bullet ? _bulletText(bulletChar) : null;
    return Paragraph(
      runs,
      style: ParagraphStyle(align: align, spaceAfter: 4),
      list: marker == null ? null : ListInfo(level: level, marker: marker),
    );
  }

  static String _bulletText(String? char) {
    if (char == null || char.isEmpty) return '•';
    final code = char.runes.first;
    return code >= 0xE000 && code <= 0xF8FF ? '•' : char;
  }

  SlideImage? _picture(
    XmlPull pull,
    XmlStartElementEvent pic,
    Map<String, String> rels,
    double ox,
    double oy,
    double scale,
  ) {
    String? rid;
    double? x, y, w, h;
    void walk(XmlStartElementEvent e) {
      switch (e.localName) {
        case 'blip':
          rid = e.attr('r:embed');
        case 'off':
          x = Units.emu(e.attr('x'));
          y = Units.emu(e.attr('y'));
        case 'ext':
          if (e.attr('cx') != null) {
            w = Units.emu(e.attr('cx'));
            h = Units.emu(e.attr('cy'));
          }
        default:
          pull.children(e, walk);
      }
    }

    pull.children(pic, walk);
    final path = rid == null ? null : rels[rid];
    if (path == null || x == null || w == null || h == null) return null;
    final lower = path.toLowerCase();
    if (!(lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif'))) {
      return null;
    }
    if (!_images.containsKey(path)) {
      final size = _zip.sizeOf(path);
      if (size == 0 || _imageBytes + size > 96 * 1024 * 1024) return null;
      final bytes = _zip.bytes(path);
      if (bytes == null) return null;
      _imageBytes += bytes.length;
      _images[path] = DocImage(bytes);
    }
    return SlideImage(
      ox + x! * scale,
      oy + (y ?? 0) * scale,
      w! * scale,
      h! * scale,
      imageId: path,
    );
  }
}

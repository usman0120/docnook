import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/engines/office/xml_events.dart';

/// Unit conversions used across WordprocessingML.
abstract final class Units {
  /// Twentieths of a point → points.
  static double twips(String? value) => (double.tryParse(value ?? '') ?? 0) / 20;

  /// English Metric Units → points.
  static double emu(String? value) => (double.tryParse(value ?? '') ?? 0) / 12700;
}

/// Run formatting where every field may be unset, so layers (document
/// defaults → paragraph style → character style → direct) can be merged.
final class RunProps {
  bool? bold;
  bool? italic;
  bool? underline;
  bool? strike;
  bool? caps;
  bool? hidden;
  double? size;
  int? color;
  bool colorAuto = false;
  int? highlight;
  FontClass? font;
  VerticalPosition? position;
  String? styleId;

  /// Overlays [over] on top of this layer.
  RunProps merged(RunProps? over) {
    if (over == null) return this;
    return RunProps()
      ..bold = over.bold ?? bold
      ..italic = over.italic ?? italic
      ..underline = over.underline ?? underline
      ..strike = over.strike ?? strike
      ..caps = over.caps ?? caps
      ..hidden = over.hidden ?? hidden
      ..size = over.size ?? size
      ..color = over.colorAuto ? null : (over.color ?? color)
      ..highlight = over.highlight ?? highlight
      ..font = over.font ?? font
      ..position = over.position ?? position;
  }

  RunStyle toStyle({String? link}) => RunStyle(
    bold: bold ?? false,
    italic: italic ?? false,
    underline: underline ?? false,
    strike: strike ?? false,
    fontSize: size,
    color: color,
    highlight: highlight,
    font: font,
    position: position ?? VerticalPosition.baseline,
    link: link,
  );

  static RunProps read(XmlPull pull, XmlStartElementEvent element) {
    final props = RunProps();
    pull.children(element, (child) {
      switch (child.localName) {
        case 'b':
          props.bold = _toggle(child);
        case 'i':
          props.italic = _toggle(child);
        case 'u':
          props.underline = child.attr('w:val') != 'none';
        case 'strike' || 'dstrike':
          props.strike = _toggle(child);
        case 'caps':
          props.caps = _toggle(child);
        case 'vanish' || 'webHidden':
          props.hidden = _toggle(child);
        case 'sz':
          final half = double.tryParse(child.attr('w:val') ?? '');
          if (half != null && half > 0) props.size = half / 2;
        case 'color':
          final value = child.attr('w:val');
          if (value == 'auto') {
            props.colorAuto = true;
          } else {
            props.color = parseHexColor(value);
          }
        case 'highlight':
          props.highlight = _highlights[child.attr('w:val')];
        case 'shd':
          props.highlight ??= parseHexColor(child.attr('w:fill'));
        case 'vertAlign':
          props.position = switch (child.attr('w:val')) {
            'superscript' => VerticalPosition.superscript,
            'subscript' => VerticalPosition.subscript,
            _ => VerticalPosition.baseline,
          };
        case 'rFonts':
          final name = child.attr('w:ascii') ?? child.attr('w:hAnsi') ?? child.attr('w:cs');
          if (name != null) props.font = classifyFont(name);
        case 'rStyle':
          props.styleId = child.attr('w:val');
      }
    });
    return props;
  }

  /// `<w:b/>` is on; `<w:b w:val="0"/>` is off.
  static bool _toggle(XmlStartElementEvent element) {
    final value = element.attr('w:val');
    return value == null || (value != '0' && value != 'false' && value != 'off');
  }

  static const _highlights = <String, int>{
    'yellow': 0xFFFFFF00,
    'green': 0xFF00FF00,
    'cyan': 0xFF00FFFF,
    'magenta': 0xFFFF00FF,
    'blue': 0xFF0000FF,
    'red': 0xFFFF0000,
    'darkBlue': 0xFF000080,
    'darkCyan': 0xFF008080,
    'darkGreen': 0xFF008000,
    'darkMagenta': 0xFF800080,
    'darkRed': 0xFF800000,
    'darkYellow': 0xFF808000,
    'darkGray': 0xFF808080,
    'lightGray': 0xFFC0C0C0,
    'black': 0xFF000000,
    'white': 0xFFFFFFFF,
  };
}

/// `RRGGBB` → 0xFFRRGGBB; null for "auto", empty or malformed values.
int? parseHexColor(String? value) {
  if (value == null || value.length != 6) return null;
  final rgb = int.tryParse(value, radix: 16);
  return rgb == null ? null : 0xFF000000 | rgb;
}

/// Maps a font name onto the three families DocNook bundles.
FontClass classifyFont(String name) {
  final n = name.toLowerCase();
  const mono = ['courier', 'consolas', 'mono', 'menlo', 'lucida console', 'fixedsys'];
  for (final key in mono) {
    if (n.contains(key)) return FontClass.mono;
  }
  if (n.contains('sans')) return FontClass.sans;
  const serif = [
    'times', 'georgia', 'garamond', 'cambria', 'serif', 'antiqua', 'palatino',
    'baskerville', 'bookman', 'century', 'minion', 'didot', 'constantia',
    'liberation serif', 'caslon', 'jameel', 'nastaliq', //
  ];
  for (final key in serif) {
    if (n.contains(key)) return FontClass.serif;
  }
  return FontClass.sans;
}

/// Paragraph formatting with unset fields, mergeable like [RunProps].
final class ParaProps {
  TextAlignment? align;
  double? indentStart;
  double? indentEnd;
  double? firstLine;
  double? spaceBefore;
  double? spaceAfter;
  double? lineHeight;
  int? outlineLevel;
  String? numId;
  int? numLevel;
  bool? pageBreakBefore;
  int? background;
  bool? rtl;
  String? styleId;

  /// Formatting of the paragraph's runs, set by a paragraph style.
  RunProps? run;

  /// Section properties carried by the last paragraph of a section.
  SectionProps? section;

  ParaProps merged(ParaProps? over) {
    if (over == null) return this;
    return ParaProps()
      ..align = over.align ?? align
      ..indentStart = over.indentStart ?? indentStart
      ..indentEnd = over.indentEnd ?? indentEnd
      ..firstLine = over.firstLine ?? firstLine
      ..spaceBefore = over.spaceBefore ?? spaceBefore
      ..spaceAfter = over.spaceAfter ?? spaceAfter
      ..lineHeight = over.lineHeight ?? lineHeight
      ..outlineLevel = over.outlineLevel ?? outlineLevel
      ..numId = over.numId ?? numId
      ..numLevel = over.numLevel ?? numLevel
      ..pageBreakBefore = over.pageBreakBefore ?? pageBreakBefore
      ..background = over.background ?? background
      ..rtl = over.rtl ?? rtl
      ..run = run == null ? over.run : run!.merged(over.run);
  }

  ParagraphStyle toStyle({bool inList = false}) => ParagraphStyle(
    align: align ?? TextAlignment.start,
    // List indentation is drawn by the renderer from the list level.
    indentStart: inList ? 0 : (indentStart ?? 0).clamp(0, 400).toDouble(),
    indentEnd: (indentEnd ?? 0).clamp(0, 400).toDouble(),
    firstLine: inList ? 0 : (firstLine ?? 0).clamp(-200, 200).toDouble(),
    spaceBefore: (spaceBefore ?? 0).clamp(0, 200).toDouble(),
    spaceAfter: (spaceAfter ?? 0).clamp(0, 200).toDouble(),
    lineHeight: lineHeight,
    background: background,
    rtl: rtl ?? false,
  );

  static ParaProps read(XmlPull pull, XmlStartElementEvent element) {
    final props = ParaProps();
    pull.children(element, (child) {
      switch (child.localName) {
        case 'pStyle':
          props.styleId = child.attr('w:val');
        case 'jc':
          props.align = switch (child.attr('w:val')) {
            'center' => TextAlignment.center,
            'right' || 'end' => TextAlignment.end,
            'both' || 'distribute' => TextAlignment.justify,
            _ => TextAlignment.start,
          };
        case 'ind':
          final start = child.attr('w:start') ?? child.attr('w:left');
          final end = child.attr('w:end') ?? child.attr('w:right');
          if (start != null) props.indentStart = Units.twips(start);
          if (end != null) props.indentEnd = Units.twips(end);
          final hanging = child.attr('w:hanging');
          final first = child.attr('w:firstLine');
          if (hanging != null) {
            props.firstLine = -Units.twips(hanging);
          } else if (first != null) {
            props.firstLine = Units.twips(first);
          }
        case 'spacing':
          final before = child.attr('w:before');
          final after = child.attr('w:after');
          if (before != null) props.spaceBefore = Units.twips(before);
          if (after != null) props.spaceAfter = Units.twips(after);
          final line = double.tryParse(child.attr('w:line') ?? '');
          final rule = child.attr('w:lineRule') ?? 'auto';
          // "auto" lines are 240ths of a line; fixed heights are left to the
          // renderer because they depend on the font size.
          if (line != null && rule == 'auto') {
            props.lineHeight = (line / 240).clamp(0.8, 3).toDouble();
          }
        case 'outlineLvl':
          props.outlineLevel = int.tryParse(child.attr('w:val') ?? '');
        case 'numPr':
          pull.children(child, (n) {
            if (n.localName == 'numId') props.numId = n.attr('w:val');
            if (n.localName == 'ilvl') {
              props.numLevel = int.tryParse(n.attr('w:val') ?? '');
            }
          });
        case 'pageBreakBefore':
          final value = child.attr('w:val');
          props.pageBreakBefore = value == null || (value != '0' && value != 'false');
        case 'shd':
          props.background = parseHexColor(child.attr('w:fill'));
        case 'bidi':
          final value = child.attr('w:val');
          props.rtl = value == null || (value != '0' && value != 'false');
        case 'rPr':
          props.run = RunProps.read(pull, child);
        case 'sectPr':
          props.section = SectionProps.read(pull, child);
      }
    });
    return props;
  }
}

final class SectionProps {
  PageSetup page = PageSetup.a4;
  String? headerRelId;
  String? footerRelId;

  static SectionProps read(XmlPull pull, XmlStartElementEvent element) {
    final props = SectionProps();
    var width = PageSetup.a4.width;
    var height = PageSetup.a4.height;
    var left = 72.0;
    var top = 72.0;
    var right = 72.0;
    var bottom = 72.0;
    pull.children(element, (child) {
      switch (child.localName) {
        case 'pgSz':
          final w = Units.twips(child.attr('w:w'));
          final h = Units.twips(child.attr('w:h'));
          if (w > 72 && h > 72) {
            width = w;
            height = h;
          }
        case 'pgMar':
          left = Units.twips(child.attr('w:left')).abs();
          top = Units.twips(child.attr('w:top')).abs();
          right = Units.twips(child.attr('w:right')).abs();
          bottom = Units.twips(child.attr('w:bottom')).abs();
        case 'headerReference':
          if ((child.attr('w:type') ?? 'default') == 'default') {
            props.headerRelId = child.attr('r:id');
          }
        case 'footerReference':
          if ((child.attr('w:type') ?? 'default') == 'default') {
            props.footerRelId = child.attr('r:id');
          }
      }
    });
    // Margins that leave no room for text are a damaged file; use defaults.
    if (left + right > width - 72 || top + bottom > height - 72) {
      left = top = right = bottom = 72;
    }
    props.page = PageSetup(
      width: width,
      height: height,
      marginLeft: left,
      marginTop: top,
      marginRight: right,
      marginBottom: bottom,
    );
    return props;
  }
}

final class _StyleDef {
  _StyleDef(this.id);
  final String id;
  String? name;
  String? basedOn;
  ParaProps para = ParaProps();
  RunProps run = RunProps();
  bool? tableBordered;
}

/// The style sheet (`word/styles.xml`) with inheritance resolved on demand.
final class DocxStyles {
  DocxStyles._();

  factory DocxStyles.parse(String? xml) {
    final styles = DocxStyles._();
    if (xml == null) return styles;
    final pull = XmlPull(xml);
    final root = pull.find('styles');
    if (root == null) return styles;

    pull.children(root, (child) {
      if (child.localName == 'docDefaults') {
        pull.children(child, (d) {
          if (d.localName == 'rPrDefault') {
            pull.children(d, (r) {
              if (r.localName == 'rPr') styles.defaultRun = RunProps.read(pull, r);
            });
          } else if (d.localName == 'pPrDefault') {
            pull.children(d, (p) {
              if (p.localName == 'pPr') styles.defaultPara = ParaProps.read(pull, p);
            });
          }
        });
      } else if (child.localName == 'style') {
        final id = child.attr('w:styleId');
        if (id == null) return;
        final def = _StyleDef(id);
        final isDefault = child.attr('w:default') == '1';
        final type = child.attr('w:type');
        pull.children(child, (s) {
          switch (s.localName) {
            case 'name':
              def.name = s.attr('w:val');
            case 'basedOn':
              def.basedOn = s.attr('w:val');
            case 'pPr':
              def.para = ParaProps.read(pull, s);
            case 'rPr':
              def.run = RunProps.read(pull, s);
            case 'tblPr':
              pull.children(s, (t) {
                if (t.localName == 'tblBorders') {
                  def.tableBordered = readHasBorders(pull, t);
                }
              });
          }
        });
        styles._defs[id] = def;
        if (isDefault && type == 'paragraph') styles._defaultParagraphId = id;
      }
    });
    return styles;
  }

  final Map<String, _StyleDef> _defs = {};
  final Map<String, (ParaProps, RunProps)> _resolved = {};
  String? _defaultParagraphId;
  RunProps defaultRun = RunProps();
  ParaProps defaultPara = ParaProps();

  /// True when any side of a borders element draws a line.
  static bool readHasBorders(XmlPull pull, XmlStartElementEvent element) {
    var any = false;
    pull.children(element, (side) {
      final value = side.attr('w:val');
      if (value != null && value != 'nil' && value != 'none') any = true;
    });
    return any;
  }

  /// Paragraph and run formatting of a style with its `basedOn` chain and the
  /// document defaults applied. A null id means the default paragraph style.
  (ParaProps, RunProps) resolve(String? styleId) {
    final id = styleId ?? _defaultParagraphId;
    if (id == null) return (defaultPara, defaultRun);
    final cached = _resolved[id];
    if (cached != null) return cached;

    final chain = <_StyleDef>[];
    var current = _defs[id];
    while (current != null && chain.length < 20 && !chain.contains(current)) {
      chain.add(current);
      current = current.basedOn == null ? null : _defs[current.basedOn];
    }
    var para = defaultPara;
    var run = defaultRun;
    for (final def in chain.reversed) {
      para = para.merged(def.para);
      run = run.merged(def.run).merged(def.para.run);
    }
    return _resolved[id] = (para, run);
  }

  /// Run formatting contributed by a character style.
  RunProps? characterStyle(String? styleId) {
    if (styleId == null) return null;
    final chain = <_StyleDef>[];
    var current = _defs[styleId];
    while (current != null && chain.length < 20 && !chain.contains(current)) {
      chain.add(current);
      current = current.basedOn == null ? null : _defs[current.basedOn];
    }
    if (chain.isEmpty) return null;
    var run = RunProps();
    for (final def in chain.reversed) {
      run = run.merged(def.run);
    }
    return run;
  }

  /// Heading level (1–6) a style implies through its name, or 0.
  int headingLevelOf(String? styleId) {
    var current = _defs[styleId];
    for (var hops = 0; current != null && hops < 20; hops++) {
      final name = (current.name ?? current.id).toLowerCase().replaceAll(' ', '');
      final match = RegExp(r'^heading(\d)$').firstMatch(name);
      if (match != null) return int.parse(match.group(1)!).clamp(1, 6);
      if (name == 'title') return 1;
      current = current.basedOn == null ? null : _defs[current.basedOn];
    }
    return 0;
  }

  bool? tableBordered(String? styleId) {
    var current = _defs[styleId];
    for (var hops = 0; current != null && hops < 20; hops++) {
      if (current.tableBordered != null) return current.tableBordered;
      current = current.basedOn == null ? null : _defs[current.basedOn];
    }
    return null;
  }
}

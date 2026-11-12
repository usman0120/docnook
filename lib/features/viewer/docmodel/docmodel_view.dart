import 'dart:math' as math;

import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide TableCell, TableRow;

/// How a DocModel is drawn on screen: reflowed to the screen width, text
/// scaled relative to the document's own body size.
final class DocRenderStyle {
  const DocRenderStyle({
    required this.ink,
    required this.inkMuted,
    required this.page,
    required this.hairline,
    required this.link,
    required this.highlight,
    required this.activeHighlight,
    this.textScale = 1,
    this.baseFontSize = 11,
    this.lineSpacing = 1,
  });

  /// Reader-chosen multiplier on line height (EPUB line spacing).
  final double lineSpacing;

  final Color ink;
  final Color inkMuted;
  final Color page;
  final Color hairline;
  final Color link;
  final Color highlight;
  final Color activeHighlight;

  /// Pinch-to-resize factor (reflow, not image zoom).
  final double textScale;

  /// The document's most common body size, mapped to DocNook's 15 px body.
  final double baseFontSize;

  double px(double? points) =>
      ((points ?? baseFontSize) / baseFontSize) * 15 * textScale;

  bool get dark => page.computeLuminance() < 0.4;

  /// Document colours that would vanish on this page (black text in dark
  /// mode, white text in light) fall back to the theme's ink.
  Color text(int? argb) {
    if (argb == null) return ink;
    final color = Color(argb);
    final contrast = _contrast(color, page);
    return contrast < 3 ? ink : color;
  }

  Color? fill(int? argb) {
    if (argb == null) return null;
    final color = Color(argb);
    // Very light fills on a dark page become a faint tint instead of a glare.
    if (dark && color.computeLuminance() > 0.6)
      return color.withValues(alpha: 0.12);
    return color;
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance() + 0.05;
    final lb = b.computeLuminance() + 0.05;
    return la > lb ? la / lb : lb / la;
  }

  /// The most common run size in [doc], or 11 pt.
  static double detectBaseSize(DocModel doc) {
    final counts = <double, int>{};
    var seen = 0;
    for (final block in doc.blocks) {
      if (block is! Paragraph || block.headingLevel > 0) continue;
      for (final inline in block.inlines) {
        if (inline is TextRun && inline.style.fontSize != null) {
          counts.update(
            inline.style.fontSize!,
            (n) => n + inline.text.length,
            ifAbsent: () => inline.text.length,
          );
        }
      }
      if (++seen > 400) break;
    }
    if (counts.isEmpty) return 11;
    final best = counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    return best.clamp(7, 24).toDouble();
  }
}

/// A search match inside one block: character range in its plain text.
final class BlockMatch {
  const BlockMatch(this.block, this.start, this.end);
  final int block;
  final int start;
  final int end;
}

/// Renders one block of a DocModel. Text blocks become selectable rich text.
class DocBlockView extends StatelessWidget {
  const DocBlockView({
    required this.block,
    required this.doc,
    required this.style,
    this.matches = const [],
    this.activeMatch,
    this.onLink,
    super.key,
  });

  final Block block;
  final DocModel doc;
  final DocRenderStyle style;

  /// Matches inside this block (character ranges in its plain text).
  final List<BlockMatch> matches;
  final BlockMatch? activeMatch;
  final ValueChanged<String>? onLink;

  @override
  Widget build(BuildContext context) => switch (block) {
    final Paragraph p => _paragraph(context, p),
    final TableBlock t => _TableView(table: t, doc: doc, style: style),
    final ImageBlock i => _image(i),
    PageBreak() => _PageBreakView(style: style),
    final SlideFrame s => SlideView(slide: s, doc: doc, style: style),
  };

  Widget _image(ImageBlock block) {
    final image = doc.images[block.imageId];
    if (image == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x2),
      child: Align(
        alignment: switch (block.align) {
          TextAlignment.center => Alignment.center,
          TextAlignment.end => Alignment.centerRight,
          _ => Alignment.centerLeft,
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(
              constraints.maxWidth,
              block.width * 1.4 * style.textScale,
            );
            return Image.memory(
              image.bytes,
              width: width,
              height: width * block.height / math.max(block.width, 1),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(1, 2400),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }

  Widget _paragraph(BuildContext context, Paragraph p) => ParagraphView(
    paragraph: p,
    doc: doc,
    style: style,
    matches: matches,
    activeMatch: activeMatch,
    onLink: onLink,
  );
}

/// One paragraph: headings, list markers, indents, spacing, rich runs.
class ParagraphView extends StatelessWidget {
  const ParagraphView({
    required this.paragraph,
    required this.doc,
    required this.style,
    this.matches = const [],
    this.activeMatch,
    this.onLink,
    this.selectable = true,
    super.key,
  });

  final Paragraph paragraph;
  final DocModel doc;
  final DocRenderStyle style;
  final List<BlockMatch> matches;
  final BlockMatch? activeMatch;
  final ValueChanged<String>? onLink;
  final bool selectable;

  static const _headingScale = [1.0, 1.6, 1.35, 1.18, 1.08, 1.0, 1.0];

  @override
  Widget build(BuildContext context) {
    final p = paragraph;
    final ps = p.style;
    final level = p.headingLevel.clamp(0, 6);
    final scale = style.textScale;

    TextStyle base(RunStyle rs) {
      var size = style.px(rs.fontSize);
      // Headings without an explicit size get a readable step up.
      if (level > 0 && rs.fontSize == null) size *= _headingScale[level];
      final family = switch (rs.font) {
        FontClass.serif => Fonts.serif,
        FontClass.mono => Fonts.mono,
        _ => Fonts.sans,
      };
      return TextStyle(
        fontFamily: family,
        fontSize: rs.position == VerticalPosition.baseline ? size : size * 0.7,
        height:
            (ps.lineHeight == null
                ? 1.45
                : (ps.lineHeight! * 1.2).clamp(1.1, 2.6)) *
            style.lineSpacing,
        fontWeight: rs.bold || level > 0 ? FontWeight.w600 : FontWeight.w400,
        fontStyle: rs.italic ? FontStyle.italic : FontStyle.normal,
        color: rs.link != null ? style.link : style.text(rs.color),
        backgroundColor: rs.highlight == null
            ? null
            : style.fill(rs.highlight)?.withValues(alpha: 0.45),
        decoration: TextDecoration.combine([
          if (rs.underline || rs.link != null) TextDecoration.underline,
          if (rs.strike) TextDecoration.lineThrough,
        ]),
        decorationColor: rs.link != null ? style.link : style.text(rs.color),
        fontFeatures: rs.position == VerticalPosition.superscript
            ? const [FontFeature.superscripts()]
            : rs.position == VerticalPosition.subscript
            ? const [FontFeature.subscripts()]
            : null,
      );
    }

    final spans = <InlineSpan>[];
    var offset = 0;
    for (final inline in p.inlines) {
      switch (inline) {
        case TextRun(:final text, style: final rs):
          final ts = base(rs);
          final recognizer = rs.link != null && onLink != null
              ? (TapGestureRecognizer()..onTap = () => onLink!(rs.link!))
              : null;
          spans.addAll(_withMatches(text, offset, ts, recognizer));
          offset += text.length;
        case InlineImage(:final imageId, :final width, :final height):
          final image = doc.images[imageId];
          if (image != null) {
            final w = math.min(width * 1.4 * scale, 320.0);
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Image.memory(
                  image.bytes,
                  width: w,
                  height: w * height / math.max(width, 1),
                  fit: BoxFit.contain,
                ),
              ),
            );
          }
      }
    }

    final list = p.list;
    final textAlign = switch (ps.align) {
      TextAlignment.center => TextAlign.center,
      TextAlignment.end => TextAlign.end,
      TextAlignment.justify => TextAlign.justify,
      TextAlignment.start => TextAlign.start,
    };

    final rich = Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      textDirection: ps.rtl ? TextDirection.rtl : null,
      textScaler: TextScaler.noScaling, // sizes already include the text scale
    );

    Widget body = rich;
    if (list != null) {
      final markerStyle =
          base(
            p.inlines.whereType<TextRun>().firstOrNull?.style ?? RunStyle.plain,
          ).copyWith(
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.none,
            backgroundColor: null,
          );
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: list.marker.length > 3
                ? 14.0 + list.marker.length * 7 * scale
                : 26 * scale,
            child: Text(
              list.marker,
              textScaler: TextScaler.noScaling,
              style: markerStyle,
            ),
          ),
          Expanded(child: rich),
        ],
      );
    }

    final indent =
        (list != null ? (list.level + 1) * 14.0 : ps.indentStart * 0.8).clamp(
          0,
          140,
        ) *
        scale;
    final firstLine = list == null && ps.firstLine > 0
        ? math.min(ps.firstLine * 0.8, 48.0)
        : 0.0;
    Widget result = Padding(
      padding: EdgeInsetsDirectional.only(
        start: indent.toDouble(),
        end: (ps.indentEnd * 0.5).clamp(0, 60).toDouble(),
        top: math.max(ps.spaceBefore, level > 0 ? 10 : 0) * scale,
        bottom: math.max(ps.spaceAfter, level > 0 ? 4 : 6) * scale,
      ),
      child: firstLine > 0
          ? Padding(
              padding: EdgeInsetsDirectional.only(start: firstLine),
              child: body,
            )
          : body,
    );
    if (ps.background != null) {
      result = ColoredBox(color: style.fill(ps.background)!, child: result);
    }
    if (level > 0) result = Semantics(header: true, child: result);
    return result;
  }

  /// Splits [text] around search matches so they can be highlighted.
  List<InlineSpan> _withMatches(
    String text,
    int offset,
    TextStyle ts,
    GestureRecognizer? recognizer,
  ) {
    if (matches.isEmpty || text.isEmpty)
      return [TextSpan(text: text, style: ts, recognizer: recognizer)];
    final spans = <InlineSpan>[];
    var cursor = 0;
    final end = offset + text.length;
    for (final m in matches) {
      if (m.end <= offset || m.start >= end) continue;
      final s = math.max(m.start - offset, cursor);
      final e = math.min(m.end - offset, text.length);
      if (s > cursor)
        spans.add(
          TextSpan(
            text: text.substring(cursor, s),
            style: ts,
            recognizer: recognizer,
          ),
        );
      final active =
          activeMatch != null &&
          activeMatch!.block == m.block &&
          activeMatch!.start == m.start;
      spans.add(
        TextSpan(
          text: text.substring(s, e),
          style: ts.copyWith(
            backgroundColor: active ? style.activeHighlight : style.highlight,
          ),
          recognizer: recognizer,
        ),
      );
      cursor = e;
    }
    if (cursor < text.length)
      spans.add(
        TextSpan(
          text: text.substring(cursor),
          style: ts,
          recognizer: recognizer,
        ),
      );
    return spans;
  }
}

class _PageBreakView extends StatelessWidget {
  const _PageBreakView({required this.style});
  final DocRenderStyle style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.x4),
    child: Row(
      children: [
        Expanded(child: Container(height: 1, color: style.hairline)),
        const SizedBox(width: Space.x2),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: style.hairline,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: Space.x2),
        Expanded(child: Container(height: 1, color: style.hairline)),
      ],
    ),
  );
}

/// A table reflowed to the available width. Column widths keep the
/// document's proportions; merged cells span columns, and vertically merged
/// cells hide the border between them.
class _TableView extends StatelessWidget {
  const _TableView({
    required this.table,
    required this.doc,
    required this.style,
  });

  final TableBlock table;
  final DocModel doc;
  final DocRenderStyle style;

  @override
  Widget build(BuildContext context) {
    final columns = math.max(table.columnCount, 1);
    final widths = List<double>.generate(
      columns,
      (i) => i < table.columnWidths.length && table.columnWidths[i] > 1
          ? table.columnWidths[i]
          : 72,
    );
    final total = widths.fold<double>(0, (a, b) => a + b);
    final border = BorderSide(
      color: table.bordered
          ? style.inkMuted.withValues(alpha: 0.45)
          : Colors.transparent,
      width: 0.8,
    );
    final inner = DocRenderStyle(
      ink: style.ink,
      inkMuted: style.inkMuted,
      page: style.page,
      hairline: style.hairline,
      link: style.link,
      highlight: style.highlight,
      activeHighlight: style.activeHighlight,
      textScale: style.textScale * 0.92,
      baseFontSize: style.baseFontSize,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow screens: keep columns readable and scroll sideways.
        final minWidth = columns * 72.0 * style.textScale;
        final width = math.max(constraints.maxWidth, minWidth);
        final scale = width / total;

        final table = Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x2),
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                for (var r = 0; r < this.table.rows.length; r++)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (cell, col) in _cellsWithColumns(
                          this.table.rows[r],
                        ))
                          SizedBox(
                            width: _span(widths, col, cell.colSpan) * scale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: inner.fill(cell.fill),
                                border: Border(
                                  left: border,
                                  right: border,
                                  top: cell.covered ? BorderSide.none : border,
                                  bottom:
                                      cell.rowSpan > 1 || _coveredBelow(r, col)
                                      ? BorderSide.none
                                      : border,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (final b in cell.blocks)
                                      DocBlockView(
                                        block: b,
                                        doc: doc,
                                        style: inner,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
        if (width <= constraints.maxWidth) return table;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: table,
        );
      },
    );
  }

  static double _span(List<double> widths, int start, int span) {
    var w = 0.0;
    for (var i = start; i < start + span; i++) {
      w += i < widths.length ? widths[i] : 72;
    }
    return w;
  }

  Iterable<(TableCell, int)> _cellsWithColumns(TableRow row) sync* {
    var col = 0;
    for (final cell in row.cells) {
      yield (cell, col);
      col += cell.colSpan;
    }
  }

  bool _coveredBelow(int r, int col) {
    if (r + 1 >= table.rows.length) return false;
    var c = 0;
    for (final cell in table.rows[r + 1].cells) {
      if (c == col) return cell.covered;
      c += cell.colSpan;
    }
    return false;
  }
}

/// A slide drawn at its real proportions, scaled to the available width.
class SlideView extends StatelessWidget {
  const SlideView({
    required this.slide,
    required this.doc,
    required this.style,
    super.key,
  });

  final SlideFrame slide;
  final DocModel doc;
  final DocRenderStyle style;

  @override
  Widget build(BuildContext context) {
    final w = math.max(slide.width, 1.0);
    final h = math.max(slide.height, 1.0);
    // Slides keep their own colours: they are pictures of a design.
    final slideStyle = DocRenderStyle(
      ink: const Color(0xFF1C1B19),
      inkMuted: const Color(0xFF5F5B53),
      page: Color(slide.background ?? 0xFFFFFFFF),
      hairline: const Color(0xFFE4E0D6),
      link: const Color(0xFF1F3A4D),
      highlight: style.highlight,
      activeHighlight: style.activeHighlight,
      baseFontSize: 18,
    );
    return AspectRatio(
      aspectRatio: w / h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final k = constraints.maxWidth / w;
          return ClipRect(
            child: Container(
              decoration: BoxDecoration(
                color: Color(slide.background ?? 0xFFFFFFFF),
                border: Border.all(color: style.hairline),
              ),
              child: Stack(
                children: [
                  for (final item in slide.items)
                    Positioned(
                      left: item.x * k,
                      top: item.y * k,
                      width: math.max(item.width * k, 1),
                      height: math.max(item.height * k, 1),
                      child: _slideItem(item, k, slideStyle),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _slideItem(SlideItem item, double k, DocRenderStyle s) {
    switch (item) {
      case SlideImage(:final imageId):
        final image = doc.images[imageId];
        return image == null
            ? const SizedBox.shrink()
            : Image.memory(
                image.bytes,
                fit: BoxFit.fill,
                gaplessPlayback: true,
              );
      case SlideShape(
        :final kind,
        :final fill,
        :final stroke,
        :final strokeWidth,
      ):
        return CustomPaint(
          painter: _ShapePainter(
            kind,
            fill == null ? null : Color(fill),
            stroke == null ? null : Color(stroke),
            strokeWidth * k,
          ),
        );
      case SlideText(
        :final paragraphs,
        :final fill,
        :final stroke,
        :final anchor,
      ):
        // Slide text sizes are in points on a fixed canvas: scale with it.
        final textStyle = DocRenderStyle(
          ink: s.ink,
          inkMuted: s.inkMuted,
          page: fill == null ? s.page : Color(fill),
          hairline: s.hairline,
          link: s.link,
          highlight: s.highlight,
          activeHighlight: s.activeHighlight,
          baseFontSize: 15,
          textScale: k,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: fill == null ? null : Color(fill),
            border: stroke == null
                ? null
                : Border.all(color: Color(stroke), width: math.max(k, 0.5)),
          ),
          child: ClipRect(
            child: Padding(
              padding: EdgeInsets.all(7 * k),
              // Like PowerPoint's "shrink text on overflow": the whole frame
              // scales down to fit its box instead of spilling out.
              child: Align(
                alignment: switch (anchor) {
                  SlideAnchor.top => Alignment.topLeft,
                  SlideAnchor.middle => Alignment.centerLeft,
                  SlideAnchor.bottom => Alignment.bottomLeft,
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: math.max(item.width * k - 14 * k, 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final p in paragraphs)
                          ParagraphView(
                            paragraph: p,
                            doc: doc,
                            style: textStyle,
                            selectable: false,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.kind, this.fill, this.stroke, this.strokeWidth);

  final SlideShapeKind kind;
  final Color? fill;
  final Color? stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    void draw(Paint paint) {
      switch (kind) {
        case SlideShapeKind.rectangle:
          canvas.drawRect(rect, paint);
        case SlideShapeKind.roundedRectangle:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect,
              Radius.circular(size.shortestSide * 0.16),
            ),
            paint,
          );
        case SlideShapeKind.ellipse:
          canvas.drawOval(rect, paint);
        case SlideShapeKind.line:
          canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
      }
    }

    if (fill != null && kind != SlideShapeKind.line)
      draw(Paint()..color = fill!);
    if (stroke != null) {
      draw(
        Paint()
          ..color = stroke!
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(strokeWidth, 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.kind != kind ||
      old.fill != fill ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth;
}

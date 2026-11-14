import 'dart:io';
import 'dart:math' as math;

import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/engines/convert/doc_fonts.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// What [docModelToPdf] needs: the parsed document, fonts and where to
/// write.
final class DocToPdfRequest {
  const DocToPdfRequest({
    required this.model,
    required this.fonts,
    required this.output,
    this.monospaceBody = false,
    this.systemFontDir = '/system/fonts',
  });

  final DocModel model;
  final DocFontBytes fonts;
  final String output;

  /// Plain text and code: set the body in the mono font.
  final bool monospaceBody;
  final String systemFontDir;
}

/// DocModel → PDF (BLUEPRINT 5.5): the second renderer of the shared model.
/// Flowing blocks paginate with the section's page size and margins;
/// slides become one page each at their own size. Runs in a JobRunner
/// isolate. Returns the page count.
Future<int> docModelToPdf(DocToPdfRequest request, JobContext context) async {
  final fonts = DocFonts.load(
    request.fonts,
    text: request.model.plainText(),
    systemDir: request.systemFontDir,
  );
  final renderer = _Renderer(request.model, fonts, request.monospaceBody);
  final doc = pw.Document(title: request.model.title, creator: 'DocNook');
  final sections = request.model.sections;
  for (var s = 0; s < sections.length; s++) {
    renderer.addSection(doc, sections[s]);
    context.progress(0.8 * (s + 1) / sections.length);
  }
  if (renderer.pages == 0) {
    // An empty document still becomes a valid one-page PDF.
    doc.addPage(pw.Page(build: (_) => pw.SizedBox()));
  }
  final bytes = await doc.save();
  File(request.output).writeAsBytesSync(bytes, flush: true);
  context.progress(1);
  return doc.document.pdfPageList.pages.length;
}

class _Renderer {
  _Renderer(this.model, this.fonts, this.mono);

  final DocModel model;
  final DocFonts fonts;
  final bool mono;
  int pages = 0;

  static const body = 11.0;
  static const _headingScale = [1.0, 1.6, 1.35, 1.18, 1.08, 1.0, 1.0];
  static const _ink = PdfColor.fromInt(0xFF1B1B1F);
  static const _rule = PdfColor.fromInt(0xFFBDBDBD);

  final _imageCache = <String, pw.ImageProvider?>{};

  pw.ImageProvider? _image(String id) => _imageCache.putIfAbsent(id, () {
    final image = model.images[id];
    if (image == null) return null;
    try {
      return pw.MemoryImage(image.bytes);
    } on Object {
      return null; // EMF/WMF and other formats the PDF writer can't embed.
    }
  });

  void addSection(pw.Document doc, DocSection section) {
    final flow = <Block>[];
    void flush() {
      if (flow.isEmpty) return;
      final blocks = [...flow];
      flow.clear();
      final page = section.page;
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat(
              page.width,
              page.height,
              marginLeft: page.marginLeft,
              marginTop: page.marginTop,
              marginRight: page.marginRight,
              marginBottom: page.marginBottom,
            ),
            theme: fonts.theme(),
          ),
          maxPages: 5000,
          header: section.header.isEmpty
              ? null
              : (_) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: _blocks(section.header, scale: 0.85),
                  ),
                ),
          footer: section.footer.isEmpty
              ? null
              : (_) => pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: _blocks(section.footer, scale: 0.85),
                  ),
                ),
          build: (context) {
            final widgets = _blocks(blocks, topLevel: true);
            return widgets.isEmpty ? [pw.SizedBox()] : widgets;
          },
        ),
      );
      pages++;
    }

    for (final block in section.blocks) {
      if (block is SlideFrame) {
        flush();
        doc.addPage(_slide(block));
        pages++;
      } else {
        flow.add(block);
      }
    }
    flush();
  }

  // Blocks ------------------------------------------------------------------

  List<pw.Widget> _blocks(
    List<Block> blocks, {
    bool topLevel = false,
    double scale = 1,
  }) {
    final out = <pw.Widget>[];
    for (final block in blocks) {
      switch (block) {
        case Paragraph():
          out.add(_paragraph(block, scale: scale, span: topLevel));
        case TableBlock():
          out.add(_table(block, scale: scale));
        case ImageBlock():
          final image = _image(block.imageId);
          if (image != null) {
            out.add(
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Align(
                  alignment: switch (block.align) {
                    TextAlignment.center => pw.Alignment.center,
                    TextAlignment.end => pw.Alignment.centerRight,
                    _ => pw.Alignment.centerLeft,
                  },
                  child: pw.ConstrainedBox(
                    constraints: pw.BoxConstraints(
                      maxWidth: block.width,
                      maxHeight: block.height,
                    ),
                    child: pw.Image(image),
                  ),
                ),
              ),
            );
          }
        case PageBreak():
          if (topLevel) out.add(pw.NewPage());
        case SlideFrame():
          break; // Handled per section.
      }
    }
    return out;
  }

  FontFamily _family(FontClass? font) => switch (font) {
    FontClass.serif => FontFamily.serif,
    FontClass.mono => FontFamily.mono,
    FontClass.sans => FontFamily.sans,
    null => mono ? FontFamily.mono : FontFamily.sans,
  };

  pw.TextStyle _style(RunStyle rs, double size, {bool forceBold = false}) {
    final bold = rs.bold || forceBold;
    final decorations = [
      if (rs.underline || rs.link != null) pw.TextDecoration.underline,
      if (rs.strike) pw.TextDecoration.lineThrough,
    ];
    final shifted = rs.position != VerticalPosition.baseline;
    return pw.TextStyle(
      font: fonts.font(_family(rs.font), bold: bold, italic: rs.italic),
      fontFallback: fonts.fallback,
      fontSize: shifted ? size * 0.7 : size,
      color: rs.link != null
          ? const PdfColor.fromInt(0xFF1A3A8F)
          : (rs.color == null ? _ink : pdfColor(rs.color!)),
      background: rs.highlight == null
          ? null
          : pw.BoxDecoration(color: pdfColor(rs.highlight!)),
      decoration: decorations.isEmpty
          ? null
          : pw.TextDecoration.combine(decorations),
    );
  }

  pw.Widget _paragraph(Paragraph p, {double scale = 1, bool span = false}) {
    final level = p.headingLevel.clamp(0, 6);
    final ps = p.style;
    final spans = <pw.InlineSpan>[];
    for (final inline in p.inlines) {
      switch (inline) {
        case TextRun(:final text, :final style):
          var size = (style.fontSize ?? body) * scale;
          if (level > 0 && style.fontSize == null) size *= _headingScale[level];
          final ts = _style(style, size, forceBold: level > 0);
          final link = style.link;
          spans.add(
            pw.TextSpan(
              text: text.replaceAll('\t', '    '),
              style: ts,
              annotation: link != null && !link.startsWith('#')
                  ? pw.AnnotationUrl(link)
                  : null,
              baseline: switch (style.position) {
                VerticalPosition.superscript => size * 0.35,
                VerticalPosition.subscript => -size * 0.15,
                VerticalPosition.baseline => 0,
              },
            ),
          );
        case InlineImage(:final imageId, :final width, :final height):
          final image = _image(imageId);
          if (image != null) {
            spans.add(
              pw.WidgetSpan(
                child: pw.SizedBox(
                  width: width,
                  height: height,
                  child: pw.Image(image),
                ),
              ),
            );
          }
      }
    }
    if (spans.isEmpty) spans.add(const pw.TextSpan(text: ' '));
    final align = switch (ps.align) {
      TextAlignment.center => pw.TextAlign.center,
      TextAlignment.end => ps.rtl ? pw.TextAlign.left : pw.TextAlign.right,
      TextAlignment.justify => pw.TextAlign.justify,
      TextAlignment.start => ps.rtl ? pw.TextAlign.right : pw.TextAlign.left,
    };
    final text = pw.RichText(
      text: pw.TextSpan(children: spans),
      textAlign: align,
      textDirection: ps.rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      overflow: span ? pw.TextOverflow.span : pw.TextOverflow.visible,
    );
    final lineSpacing = ps.lineHeight == null
        ? 0.0
        : math.max(0, (ps.lineHeight! - 1.15) * body);
    final list = p.list;
    final indent = list != null
        ? (list.level + 1) * 14.0
        : math.max(0, ps.indentStart).toDouble();
    final before = level > 0 ? math.max(ps.spaceBefore, 10.0) : ps.spaceBefore;
    final after = level > 0 ? math.max(ps.spaceAfter, 4.0) : ps.spaceAfter;
    pw.Widget child = text;
    if (list != null && list.marker.isNotEmpty) {
      child = pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: list.marker.length > 3 ? 12.0 + list.marker.length * 6 : 16,
            child: _marker(list.marker, body * scale),
          ),
          pw.Expanded(child: text),
        ],
      );
    }
    return pw.Padding(
      padding: pw.EdgeInsets.only(
        left: list != null ? indent - 14 : indent,
        right: math.max(0, ps.indentEnd).toDouble(),
        top: before.clamp(0, 48).toDouble(),
        bottom: (after + lineSpacing).clamp(0, 48).toDouble(),
      ),
      child: ps.background == null
          ? child
          : pw.Container(color: pdfColor(ps.background!), child: child),
    );
  }

  /// A list marker. Hollow bullets and check boxes are drawn as shapes,
  /// since the bundled fonts have no glyphs for them.
  pw.Widget _marker(String marker, double size) {
    final m = marker.replaceAll('︎', '').replaceAll('️', '');
    final box = size * 0.62;
    final shape = switch (m) {
      '◦' || '○' => 0,
      '☐' => 1,
      '☑' || '☒' => 2,
      '▪' || '■' => 3,
      _ => -1,
    };
    if (shape < 0) return pw.Text(m, style: _style(RunStyle.plain, size));
    final d = shape == 0 ? box * 0.55 : box;
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: (size * 1.2 - d) / 2),
      child: pw.CustomPaint(
        size: PdfPoint(d, d),
        painter: (canvas, area) {
          const ink = PdfColors.grey800;
          canvas
            ..setStrokeColor(ink)
            ..setFillColor(ink)
            ..setLineWidth(math.max(0.5, size * 0.06));
          switch (shape) {
            case 0:
              canvas
                ..drawEllipse(d / 2, d / 2, d / 2 - 0.4, d / 2 - 0.4)
                ..strokePath();
            case 3:
              canvas
                ..drawRect(d * 0.2, d * 0.2, d * 0.6, d * 0.6)
                ..fillPath();
            default:
              canvas
                ..drawRect(0.4, 0.4, d - 0.8, d - 0.8)
                ..strokePath();
              if (shape == 2) {
                canvas
                  ..moveTo(d * 0.22, d * 0.5)
                  ..lineTo(d * 0.42, d * 0.28)
                  ..lineTo(d * 0.8, d * 0.75)
                  ..strokePath();
              }
          }
        },
      ),
    );
  }

  pw.Widget _table(TableBlock t, {double scale = 1}) {
    final columns = t.columnCount;
    if (columns == 0) return pw.SizedBox();
    final widths = <int, pw.TableColumnWidth>{
      for (var i = 0; i < columns; i++)
        i: pw.FlexColumnWidth(
          i < t.columnWidths.length && t.columnWidths[i] > 0
              ? t.columnWidths[i]
              : 1,
        ),
    };
    final rows = <pw.TableRow>[];
    for (final row in t.rows) {
      final cells = <pw.Widget>[];
      for (final cell in row.cells) {
        final content = cell.covered
            ? <pw.Widget>[]
            : _blocks(cell.blocks, scale: scale * 0.95);
        cells.add(
          pw.Container(
            color: cell.fill == null ? null : pdfColor(cell.fill!),
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: content,
            ),
          ),
        );
        // pdf tables have no column span: the spanned columns stay empty.
        for (var k = 1; k < cell.colSpan; k++) {
          cells.add(pw.SizedBox());
        }
      }
      while (cells.length < columns) {
        cells.add(pw.SizedBox());
      }
      rows.add(
        pw.TableRow(
          repeat: row.isHeader,
          children: cells.take(columns).toList(),
        ),
      );
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Table(
        border: t.bordered
            ? pw.TableBorder.all(width: 0.5, color: _rule)
            : null,
        columnWidths: widths,
        children: rows,
      ),
    );
  }

  // Slides ------------------------------------------------------------------

  pw.Page _slide(SlideFrame s) => pw.Page(
    pageTheme: pw.PageTheme(
      pageFormat: PdfPageFormat(s.width, s.height),
      theme: fonts.theme(),
    ),
    build: (_) => pw.Container(
      color: s.background == null ? PdfColors.white : pdfColor(s.background!),
      child: pw.Stack(
        children: [
          for (final item in s.items)
            pw.Positioned(
              left: item.x,
              top: item.y,
              child: pw.SizedBox(
                width: math.max(1, item.width),
                height: math.max(1, item.height),
                child: _slideItem(item),
              ),
            ),
        ],
      ),
    ),
  );

  pw.Widget _slideItem(SlideItem item) {
    switch (item) {
      case SlideText(
        :final paragraphs,
        :final fill,
        :final stroke,
        :final anchor,
      ):
        return pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            color: fill == null ? null : pdfColor(fill),
            border: stroke == null
                ? null
                : pw.Border.all(color: pdfColor(stroke), width: 0.75),
          ),
          child: pw.Column(
            mainAxisAlignment: switch (anchor) {
              SlideAnchor.top => pw.MainAxisAlignment.start,
              SlideAnchor.middle => pw.MainAxisAlignment.center,
              SlideAnchor.bottom => pw.MainAxisAlignment.end,
            },
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [for (final p in paragraphs) _paragraph(p)],
          ),
        );
      case SlideImage(:final imageId):
        final image = _image(imageId);
        return image == null
            ? pw.SizedBox()
            : pw.Image(image, fit: pw.BoxFit.fill);
      case SlideShape(
        :final kind,
        :final fill,
        :final stroke,
        :final strokeWidth,
      ):
        return pw.CustomPaint(
          painter: (canvas, size) {
            final w = size.x;
            final h = size.y;
            final filled = fill != null && kind != SlideShapeKind.line;
            final stroked = stroke != null || kind == SlideShapeKind.line;
            // Colours first: PDF forbids them between path and paint.
            if (filled) canvas.setFillColor(pdfColor(fill));
            if (stroked) {
              canvas
                ..setStrokeColor(pdfColor(stroke ?? 0xFF000000))
                ..setLineWidth(strokeWidth);
            }
            switch (kind) {
              case SlideShapeKind.line:
                canvas
                  ..moveTo(0, h)
                  ..lineTo(w, 0);
              case SlideShapeKind.ellipse:
                canvas.drawEllipse(w / 2, h / 2, w / 2, h / 2);
              case SlideShapeKind.roundedRectangle:
                final r = math.min(w, h) * 0.1;
                canvas.drawRRect(0, 0, w, h, r, r);
              case SlideShapeKind.rectangle:
                canvas.drawRect(0, 0, w, h);
            }
            if (filled && stroked) {
              canvas.fillAndStrokePath();
            } else if (filled) {
              canvas.fillPath();
            } else {
              canvas.strokePath();
            }
          },
        );
    }
  }
}

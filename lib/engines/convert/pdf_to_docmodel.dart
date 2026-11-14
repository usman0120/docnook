import 'dart:math' as math;
import 'dart:typed_data';

import 'package:docnook/domain/docmodel/doc_model.dart';

/// One line of text on a PDF page, in points from the page's top-left.
final class PdfTextLine {
  const PdfTextLine(
    this.text,
    this.left,
    this.top,
    this.right,
    this.bottom, {
    double? size,
    double? baseline,
    this.bold = false,
  }) : _size = size,
       _baseline = baseline;
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double? _size;
  final double? _baseline;

  /// Most of the line is in a bold font.
  final bool bold;

  double get height => bottom - top;

  /// The line's typical font size; the glyph height when unknown.
  double get size => _size ?? height;

  /// Where most characters sit, measured like [top].
  double get baseline => _baseline ?? bottom;
}

/// A picture on a PDF page (JPEG bytes), placed like [PdfTextLine].
final class PdfPagePicture {
  const PdfPagePicture(this.jpeg, this.left, this.top, this.width, this.height);
  final Uint8List jpeg;
  final double left;
  final double top;
  final double width;
  final double height;
}

final class PdfPageContent {
  const PdfPageContent({
    required this.width,
    required this.height,
    required this.lines,
    this.pictures = const [],
  });

  final double width;
  final double height;
  final List<PdfTextLine> lines;
  final List<PdfPagePicture> pictures;
}

double _median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  return sorted[sorted.length ~/ 2];
}

/// Builds lines from a page's characters and their boxes (top-left origin):
/// a new line starts at a line break or where the next character sits on
/// a different baseline. [sizes], when given, holds each character's font
/// size, negative for bold (as PdfiumEditor.pageChars returns it).
List<PdfTextLine> linesFromChars(
  String text,
  List<(double l, double t, double r, double b)> boxes, {
  List<double>? sizes,
}) {
  final lines = <PdfTextLine>[];
  final buf = StringBuffer();
  var (l, t, r, b) = (double.infinity, double.infinity, -1.0, -1.0);
  final lineSizes = <double>[];
  final bottoms = <double>[];
  var boldCount = 0;
  void end() {
    final s = buf.toString().trim();
    if (s.isNotEmpty && r >= l) {
      final size = _median(lineSizes);
      lines.add(
        PdfTextLine(
          s,
          l,
          t,
          r,
          b,
          size: size > 0 ? size : null,
          baseline: bottoms.isEmpty ? null : _median(bottoms),
          bold: lineSizes.isNotEmpty && boldCount * 2 > lineSizes.length,
        ),
      );
    }
    buf.clear();
    lineSizes.clear();
    bottoms.clear();
    boldCount = 0;
    (l, t, r, b) = (double.infinity, double.infinity, -1.0, -1.0);
  }

  for (var i = 0; i < text.length && i < boxes.length; i++) {
    final ch = text[i];
    if (ch == '\n' || ch == '\r') {
      end();
      continue;
    }
    final box = boxes[i];
    final empty = box.$3 <= box.$1 || box.$4 <= box.$2;
    if (!empty && buf.isNotEmpty && b > 0) {
      final mid = (box.$2 + box.$4) / 2;
      final sameLine = mid > t && mid < b;
      if (!sameLine) end();
    }
    buf.write(ch);
    if (!empty && ch.trim().isNotEmpty) {
      bottoms.add(box.$4);
      if (sizes != null && i < sizes.length && sizes[i] != 0) {
        lineSizes.add(sizes[i].abs());
        if (sizes[i] < 0) boldCount++;
      }
    }
    if (!empty) {
      l = math.min(l, box.$1);
      t = math.min(t, box.$2);
      r = math.max(r, box.$3);
      b = math.max(b, box.$4);
    }
  }
  end();
  return lines;
}

/// PDF text → DocModel (BLUEPRINT 5.5, "Basic" fidelity): lines join into
/// paragraphs by spacing and indentation; larger or bold short lines
/// become headings; pictures sit between paragraphs at their position;
/// each PDF page starts a new page.
DocModel pdfPagesToDocModel(List<PdfPageContent> pages, {String? title}) {
  // Typical body size, weighted by text length.
  final sizes = <double>[];
  final pitches = <double>[];
  for (final page in pages) {
    PdfTextLine? prev;
    for (final line in page.lines) {
      for (var k = 0; k < math.min(line.text.length, 40); k++) {
        sizes.add(line.size);
      }
      // Baseline to baseline between lines of the same size.
      if (prev != null && (prev.size - line.size).abs() < 0.5) {
        final d = line.baseline - prev.baseline;
        if (d > 0) pitches.add(d / line.size);
      }
      prev = line;
    }
  }
  final body = sizes.isEmpty ? 12.0 : math.max(4, _median(sizes)).toDouble();
  // Typical line spacing as a multiple of the font size.
  // The lower quartile: steps inside paragraphs outnumber the gaps
  // between them.
  pitches.sort();
  final pitch = pitches.isEmpty
      ? 1.25
      : pitches[pitches.length ~/ 4].clamp(1.0, 2.0);

  final images = <String, DocImage>{};
  final blocks = <Block>[];
  for (var p = 0; p < pages.length; p++) {
    final page = pages[p];
    if (p > 0) blocks.add(const PageBreak());
    final items = <(double, Object)>[
      for (final l in page.lines) (l.top, l),
      for (final pic in page.pictures) (pic.top, pic),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final lines = page.lines;
    final leftEdge = lines.isEmpty
        ? 0.0
        : lines.map((l) => l.left).reduce(math.min);
    final rightEdge = lines.isEmpty
        ? page.width
        : lines.map((l) => l.right).reduce(math.max);
    final width = math.max(1, rightEdge - leftEdge);

    var current = <PdfTextLine>[];
    void flush() {
      if (current.isEmpty) return;
      blocks.add(_paragraph(current, body, leftEdge));
      current = [];
    }

    for (final (_, item) in items) {
      if (item is PdfPagePicture) {
        flush();
        final id = 'p${p}_${images.length}';
        images[id] = DocImage(item.jpeg, mime: 'image/jpeg');
        blocks.add(ImageBlock(id, width: item.width, height: item.height));
        continue;
      }
      final line = item as PdfTextLine;
      if (current.isNotEmpty) {
        final prev = current.last;
        final step = line.baseline - prev.baseline;
        final spaced = step > prev.size * pitch * 1.3 || step < 0;
        final sizeChange = (line.size - prev.size).abs() > body * 0.15;
        final boldChange = line.bold != prev.bold;
        final indented = (line.left - prev.left).abs() > body * 1.2;
        final prevShort = prev.right < leftEdge + width * 0.75;
        if (spaced || sizeChange || boldChange || indented || prevShort) {
          flush();
        }
      }
      current.add(line);
    }
    flush();
  }
  return DocModel(
    title: title,
    images: images,
    simplified: true,
    sections: [DocSection(blocks: blocks)],
  );
}

Paragraph _paragraph(List<PdfTextLine> lines, double body, double leftEdge) {
  final out = StringBuffer();
  for (var i = 0; i < lines.length; i++) {
    final text = lines[i].text;
    if (i == 0) {
      out.write(text);
      continue;
    }
    final prev = out.toString();
    // Re-join words hyphenated at the line end.
    if (prev.endsWith('-') &&
        text.isNotEmpty &&
        text[0].toLowerCase() == text[0] &&
        text[0].toUpperCase() != text[0]) {
      out
        ..clear()
        ..write(prev.substring(0, prev.length - 1))
        ..write(text);
    } else {
      out
        ..write(' ')
        ..write(text);
    }
  }
  final size = _median([for (final l in lines) l.size]);
  final ratio = size / body;
  final bold = lines.every((l) => l.bold);
  final short = lines.length <= 3 && out.length <= 160;
  final level = !short
      ? 0
      : ratio >= 1.8
      ? 1
      : ratio >= 1.45
      ? 2
      : ratio >= 1.15 || (bold && lines.length <= 2)
      ? 3
      : 0;
  final indent = math.max(0, lines.first.left - leftEdge).toDouble();
  return Paragraph(
    [TextRun(out.toString())],
    headingLevel: level,
    style: ParagraphStyle(
      indentStart: indent > body * 2 ? indent : 0,
      spaceAfter: 6,
    ),
  );
}

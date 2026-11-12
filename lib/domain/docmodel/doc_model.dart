import 'dart:typed_data';

import 'package:meta/meta.dart';

/// DocModel: the one in-memory form of every flowing document DocNook reads
/// (DOCX, ODT, RTF, PPTX, PDF→Word). Two renderers consume it: Flutter
/// widgets for the viewer and `pdf` widgets for conversion (BLUEPRINT 5.5).
/// Pure Dart; safe to hand between isolates. Lengths are in points (1/72 in),
/// colours are 0xAARRGGBB.
final class DocModel {
  DocModel({
    required this.sections,
    Map<String, DocImage>? images,
    this.title,
    this.simplified = false,
  }) : images = images ?? {};

  final List<DocSection> sections;

  /// Embedded pictures by id, referenced from [ImageBlock] and [InlineImage].
  final Map<String, DocImage> images;
  final String? title;

  /// True when the source used features the model drops (floating shapes,
  /// columns, text boxes…), so the viewer shows the "simplified layout" note.
  final bool simplified;

  Iterable<Block> get blocks => sections.expand((s) => s.blocks);

  /// Headings in reading order, for the outline panel.
  List<OutlineEntry> outline() {
    final entries = <OutlineEntry>[];
    var index = 0;
    for (final block in blocks) {
      if (block is Paragraph && block.headingLevel > 0) {
        final text = block.plainText.trim();
        if (text.isNotEmpty) {
          entries.add(OutlineEntry(text, block.headingLevel, index));
        }
      }
      index++;
    }
    return entries;
  }

  /// All readable text, one block per line: used for search indexing, Read
  /// Aloud and plain-text export.
  String plainText() {
    final out = StringBuffer();
    void write(Block block) {
      switch (block) {
        case Paragraph():
          final marker = block.list?.marker;
          if (marker != null && marker.isNotEmpty) out.write('$marker ');
          out.writeln(block.plainText);
        case TableBlock(:final rows):
          for (final row in rows) {
            final cells = <String>[];
            for (final cell in row.cells) {
              if (cell.covered) continue;
              final inner = StringBuffer();
              for (final child in cell.blocks) {
                if (child is Paragraph) {
                  if (inner.isNotEmpty) inner.write(' ');
                  inner.write(child.plainText);
                }
              }
              cells.add(inner.toString());
            }
            out.writeln(cells.join('\t'));
          }
        case SlideFrame(:final items):
          for (final item in items) {
            if (item is SlideText) item.paragraphs.forEach(write);
          }
        case ImageBlock() || PageBreak():
          break;
      }
    }

    blocks.forEach(write);
    return out.toString();
  }
}

final class OutlineEntry {
  const OutlineEntry(this.title, this.level, this.blockIndex);
  final String title;
  final int level;

  /// Index into [DocModel.blocks].
  final int blockIndex;
}

final class DocImage {
  const DocImage(this.bytes, {this.mime});
  final Uint8List bytes;
  final String? mime;
}

final class PageSetup {
  const PageSetup({
    this.width = 595.3,
    this.height = 841.9,
    this.marginLeft = 72,
    this.marginTop = 72,
    this.marginRight = 72,
    this.marginBottom = 72,
  });

  /// A4 portrait with 1-inch margins.
  static const a4 = PageSetup();

  final double width;
  final double height;
  final double marginLeft;
  final double marginTop;
  final double marginRight;
  final double marginBottom;

  double get contentWidth => width - marginLeft - marginRight;
}

final class DocSection {
  DocSection({
    required this.blocks,
    this.page = PageSetup.a4,
    this.header = const [],
    this.footer = const [],
  });

  final List<Block> blocks;
  final PageSetup page;
  final List<Block> header;
  final List<Block> footer;
}

sealed class Block {
  const Block();
}

enum TextAlignment { start, center, end, justify }

final class ParagraphStyle {
  const ParagraphStyle({
    this.align = TextAlignment.start,
    this.indentStart = 0,
    this.indentEnd = 0,
    this.firstLine = 0,
    this.spaceBefore = 0,
    this.spaceAfter = 0,
    this.lineHeight,
    this.background,
    this.rtl = false,
  });

  static const plain = ParagraphStyle();

  final TextAlignment align;
  final double indentStart;
  final double indentEnd;

  /// First-line indent; negative for a hanging indent.
  final double firstLine;
  final double spaceBefore;
  final double spaceAfter;

  /// Line height as a multiple of the font size, when the source sets one.
  final double? lineHeight;
  final int? background;
  final bool rtl;
}

/// List membership of a paragraph. The marker text ("•", "1.", "a)") is
/// resolved by the parser so both renderers print the same thing.
final class ListInfo {
  const ListInfo({
    required this.level,
    required this.marker,
    this.ordered = false,
  });
  final int level;
  final String marker;
  final bool ordered;
}

/// A paragraph, heading (when [headingLevel] is 1–6) or list item (when
/// [list] is set).
final class Paragraph extends Block {
  const Paragraph(
    this.inlines, {
    this.style = ParagraphStyle.plain,
    this.headingLevel = 0,
    this.list,
  });

  final List<Inline> inlines;
  final ParagraphStyle style;
  final int headingLevel;
  final ListInfo? list;

  bool get isEmpty =>
      inlines.every((i) => i is TextRun && i.text.trim().isEmpty);

  String get plainText {
    if (inlines.length == 1) {
      final only = inlines.first;
      return only is TextRun ? only.text : '';
    }
    final out = StringBuffer();
    for (final inline in inlines) {
      if (inline is TextRun) out.write(inline.text);
    }
    return out.toString();
  }
}

sealed class Inline {
  const Inline();
}

enum FontClass { sans, serif, mono }

enum VerticalPosition { baseline, superscript, subscript }

@immutable
final class RunStyle {
  const RunStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.fontSize,
    this.color,
    this.highlight,
    this.font,
    this.position = VerticalPosition.baseline,
    this.link,
  });

  static const plain = RunStyle();

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;

  /// Font size in points; null means the renderer's body size.
  final double? fontSize;
  final int? color;
  final int? highlight;

  /// Broad family of the source font; null means the renderer's default.
  final FontClass? font;
  final VerticalPosition position;

  /// Target of a hyperlink (URL or `#bookmark`).
  final String? link;

  RunStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    double? fontSize,
    int? color,
    int? highlight,
    FontClass? font,
    VerticalPosition? position,
    String? link,
  }) => RunStyle(
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    strike: strike ?? this.strike,
    fontSize: fontSize ?? this.fontSize,
    color: color ?? this.color,
    highlight: highlight ?? this.highlight,
    font: font ?? this.font,
    position: position ?? this.position,
    link: link ?? this.link,
  );

  @override
  bool operator ==(Object other) =>
      other is RunStyle &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.strike == strike &&
      other.fontSize == fontSize &&
      other.color == color &&
      other.highlight == highlight &&
      other.font == font &&
      other.position == position &&
      other.link == link;

  @override
  int get hashCode => Object.hash(
    bold,
    italic,
    underline,
    strike,
    fontSize,
    color,
    highlight,
    font,
    position,
    link, //
  );
}

/// Text with one style. Tabs are `\t`, forced line breaks are `\n`.
final class TextRun extends Inline {
  const TextRun(this.text, [this.style = RunStyle.plain]);
  final String text;
  final RunStyle style;
}

/// A picture that sits in the text line.
final class InlineImage extends Inline {
  const InlineImage(this.imageId, {required this.width, required this.height});
  final String imageId;
  final double width;
  final double height;
}

final class ImageBlock extends Block {
  const ImageBlock(
    this.imageId, {
    required this.width,
    required this.height,
    this.align = TextAlignment.start,
  });

  final String imageId;
  final double width;
  final double height;
  final TextAlignment align;
}

final class PageBreak extends Block {
  const PageBreak();
}

final class TableBlock extends Block {
  const TableBlock(
    this.rows, {
    this.columnWidths = const [],
    this.bordered = true,
  });

  final List<TableRow> rows;

  /// Preferred width of each grid column in points; empty when unknown.
  final List<double> columnWidths;
  final bool bordered;

  int get columnCount {
    var max = columnWidths.length;
    for (final row in rows) {
      var n = 0;
      for (final cell in row.cells) {
        n += cell.colSpan;
      }
      if (n > max) max = n;
    }
    return max;
  }
}

final class TableRow {
  const TableRow(this.cells, {this.isHeader = false});
  final List<TableCell> cells;
  final bool isHeader;
}

final class TableCell {
  TableCell(
    this.blocks, {
    this.colSpan = 1,
    this.rowSpan = 1,
    this.covered = false,
    this.fill,
  });

  final List<Block> blocks;
  final int colSpan;

  /// Rows this cell spans downward. Set on the top cell of a vertical merge.
  int rowSpan;

  /// True for the lower cells of a vertical merge: they hold a grid position
  /// but draw nothing.
  final bool covered;
  final int? fill;
}

/// One slide: absolutely positioned items on a fixed-size canvas.
final class SlideFrame extends Block {
  const SlideFrame({
    required this.width,
    required this.height,
    required this.items,
    this.background,
    this.title,
    this.notes,
  });

  final double width;
  final double height;
  final List<SlideItem> items;
  final int? background;
  final String? title;
  final String? notes;
}

sealed class SlideItem {
  const SlideItem(this.x, this.y, this.width, this.height);
  final double x;
  final double y;
  final double width;
  final double height;
}

enum SlideAnchor { top, middle, bottom }

final class SlideText extends SlideItem {
  const SlideText(
    super.x,
    super.y,
    super.width,
    super.height, {
    required this.paragraphs,
    this.fill,
    this.stroke,
    this.anchor = SlideAnchor.top,
    this.isTitle = false,
  });

  final List<Paragraph> paragraphs;
  final int? fill;
  final int? stroke;
  final SlideAnchor anchor;
  final bool isTitle;
}

final class SlideImage extends SlideItem {
  const SlideImage(
    super.x,
    super.y,
    super.width,
    super.height, {
    required this.imageId,
  });
  final String imageId;
}

enum SlideShapeKind { rectangle, roundedRectangle, ellipse, line }

final class SlideShape extends SlideItem {
  const SlideShape(
    super.x,
    super.y,
    super.width,
    super.height, {
    required this.kind,
    this.fill,
    this.stroke,
    this.strokeWidth = 1,
  });

  final SlideShapeKind kind;
  final int? fill;
  final int? stroke;
  final double strokeWidth;
}

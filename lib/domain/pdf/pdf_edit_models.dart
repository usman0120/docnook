import 'package:meta/meta.dart';

/// Plain data describing PDF edits. Everything here is sendable between
/// isolates, and pure Dart (BLUEPRINT 5.1: domain has no plugin imports).
///
/// Coordinates are PDF user space of the page as stored (points, origin at
/// the bottom-left of the media box, before the page's /Rotate is applied),
/// unless a field says otherwise.

/// A PDF to read pages from.
@immutable
final class PdfSource {
  const PdfSource(this.path, {this.password});

  /// Local file path (content URIs are copied to the cache first).
  final String path;
  final String? password;
}

/// One page of an output document: a page of a source, or a blank page.
@immutable
final class PageSpec {
  /// Page [index] (0-based) of source number [source], turned [quarterTurns]
  /// times clockwise on top of its own rotation.
  const PageSpec.page(this.source, this.index, {this.quarterTurns = 0})
    : blankWidth = 0,
      blankHeight = 0;

  /// An empty page of the given size in points.
  const PageSpec.blank({required double width, required double height})
    : source = -1,
      index = -1,
      quarterTurns = 0,
      blankWidth = width,
      blankHeight = height;

  final int source;
  final int index;
  final int quarterTurns;
  final double blankWidth;
  final double blankHeight;

  bool get isBlank => source < 0;

  PageSpec turned(int turns) => isBlank
      ? this
      : PageSpec.page(source, index, quarterTurns: (quarterTurns + turns) % 4);
}

/// Size and rotation of one page.
@immutable
final class PdfPageInfo {
  const PdfPageInfo(
    this.width,
    this.height,
    this.rotation, {
    this.x0 = 0,
    this.y0 = 0,
  });

  /// Size of the visible box (crop box, else media box) in points, before
  /// rotation.
  final double width;
  final double height;

  /// Quarter turns clockwise (0–3) from the page's /Rotate.
  final int rotation;

  /// Bottom-left corner of the visible box in page space.
  final double x0;
  final double y0;

  double get visibleWidth => rotation.isOdd ? height : width;
  double get visibleHeight => rotation.isOdd ? width : height;

  /// A point given as fractions of the page as seen on screen (top-left
  /// origin) in box space: points from the box's bottom-left corner,
  /// before rotation. Add [x0] and [y0] for page space.
  (double, double) fromVisible(double fx, double fy) {
    final vx = fx * visibleWidth;
    final vy = (1 - fy) * visibleHeight;
    return switch (rotation & 3) {
      1 => (width - vy, vx),
      2 => (width - vx, height - vy),
      3 => (vy, height - vx),
      _ => (vx, vy),
    };
  }

  /// The inverse of [fromVisible].
  (double, double) toVisible(double x, double y) {
    final (vx, vy) = switch (rotation & 3) {
      1 => (y, width - x),
      2 => (width - x, height - y),
      3 => (height - y, x),
      _ => (x, y),
    };
    return (vx / visibleWidth, 1 - vy / visibleHeight);
  }
}

/// What DocNook needs to know about a PDF before a tool runs.
@immutable
final class PdfInfo {
  const PdfInfo({
    required this.pages,
    required this.encrypted,
    required this.hasForm,
  });

  final List<PdfPageInfo> pages;
  final bool encrypted;
  final bool hasForm;

  int get pageCount => pages.length;
}

/// Where a stamp sits on the visible page.
enum StampPosition {
  topLeft,
  topCenter,
  topRight,
  center,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Text or an image drawn onto pages: watermarks and page numbers.
///
/// [text] may contain `{n}` (page number) and `{total}` (page count).
/// For an image stamp, [imageBgra] holds [imageWidth] × [imageHeight]
/// pixels in BGRA order, drawn [imageWidthPt] points wide.
@immutable
final class StampSpec {
  const StampSpec.text(
    this.text, {
    this.fontSize = 48,
    this.colorRgb = 0x808080,
    this.bold = false,
    this.opacity = 1,
    this.angle = 0,
    this.position = StampPosition.center,
    this.margin = 28,
  }) : imageBgra = null,
       imageWidth = 0,
       imageHeight = 0,
       imageWidthPt = 0;

  const StampSpec.image(
    List<int> bgra, {
    required this.imageWidth,
    required this.imageHeight,
    required this.imageWidthPt,
    this.opacity = 1,
    this.angle = 0,
    this.position = StampPosition.center,
    this.margin = 28,
  }) : imageBgra = bgra,
       text = '',
       fontSize = 0,
       colorRgb = 0,
       bold = false;

  final String text;
  final double fontSize;
  final int colorRgb;
  final bool bold;
  final List<int>? imageBgra;
  final int imageWidth;
  final int imageHeight;
  final double imageWidthPt;

  /// 0–1.
  final double opacity;

  /// Degrees, counter-clockwise, as seen on screen.
  final double angle;
  final StampPosition position;

  /// Distance from the page edge in points (not used for [center]).
  final double margin;

  bool get isImage => imageBgra != null;

  /// [text] with the page placeholders filled in.
  String textFor(int pageNumber, int total) =>
      text.replaceAll('{n}', '$pageNumber').replaceAll('{total}', '$total');
}

/// Markup drawn by the Annotate and Sign tools, saved as standard PDF
/// annotations (FR-PDF-02).
@immutable
sealed class PdfMark {
  const PdfMark(this.page, this.colorRgb);

  /// 0-based page index.
  final int page;
  final int colorRgb;
}

enum MarkupKind { highlight, underline, strikeOut }

/// Highlight, underline or strike-through over text. [quads] holds eight
/// numbers per text line: x1 y1 (top-left), x2 y2 (top-right),
/// x3 y3 (bottom-left), x4 y4 (bottom-right).
final class TextMarkup extends PdfMark {
  const TextMarkup(super.page, super.colorRgb, this.kind, this.quads);
  final MarkupKind kind;
  final List<double> quads;
}

/// Freehand ink: pen drawings and signatures. Each stroke is a flat list of
/// x, y pairs.
final class InkMark extends PdfMark {
  const InkMark(super.page, super.colorRgb, this.strokes, this.width);
  final List<List<double>> strokes;
  final double width;
}

/// A sticky note at ([x], [y]).
final class NoteMark extends PdfMark {
  const NoteMark(super.page, super.colorRgb, this.x, this.y, this.text);
  final double x;
  final double y;
  final String text;
}

enum FormFieldKind { text, checkbox, radio, combo, list, button, signature }

/// One fillable widget of an AcroForm (S33).
@immutable
final class FormFieldInfo {
  const FormFieldInfo({
    required this.page,
    required this.annotIndex,
    required this.kind,
    required this.name,
    required this.value,
    required this.checked,
    required this.options,
    required this.selected,
    required this.left,
    required this.bottom,
    required this.right,
    required this.top,
    required this.readOnly,
    required this.multiline,
    required this.exportValue,
  });

  final int page;
  final int annotIndex;
  final FormFieldKind kind;
  final String name;
  final String value;
  final bool checked;
  final List<String> options;
  final List<int> selected;
  final double left;
  final double bottom;
  final double right;
  final double top;
  final bool readOnly;
  final bool multiline;

  /// For radio buttons and checkboxes: the value this widget stands for.
  final String exportValue;

  bool get editable =>
      !readOnly &&
      kind != FormFieldKind.button &&
      kind != FormFieldKind.signature;

  String get key => '$page/$annotIndex';
}

/// A new value for a form widget.
@immutable
final class FormFieldValue {
  const FormFieldValue.text(this.page, this.annotIndex, String this.text)
    : checked = null,
      selectedIndex = null;
  const FormFieldValue.checked(this.page, this.annotIndex, bool this.checked)
    : text = null,
      selectedIndex = null;
  const FormFieldValue.choice(
    this.page,
    this.annotIndex,
    int this.selectedIndex,
  ) : text = null,
      checked = null;

  final int page;
  final int annotIndex;
  final String? text;
  final bool? checked;
  final int? selectedIndex;
}

/// Outcome of the Balanced compression pass.
@immutable
final class RecompressStats {
  const RecompressStats(this.imagesSeen, this.imagesRecompressed);
  final int imagesSeen;
  final int imagesRecompressed;
}

/// Parses a page selection such as "1-3, 5, 8-" into 0-based indices
/// (sorted, no duplicates). An open end runs to [pageCount]. Returns null
/// for anything malformed or out of range.
List<int>? parsePageRanges(String input, int pageCount) {
  final text = input.replaceAll(' ', '');
  if (text.isEmpty) return null;
  final out = <int>{};
  for (final part in text.split(',')) {
    if (part.isEmpty) return null;
    final match = RegExp(r'^(\d*)(-?)(\d*)$').firstMatch(part);
    if (match == null) return null;
    final a = match.group(1)!;
    final dash = match.group(2)!.isNotEmpty;
    final b = match.group(3)!;
    if (a.isEmpty && b.isEmpty) return null;
    final start = a.isEmpty ? 1 : int.parse(a);
    final end = dash ? (b.isEmpty ? pageCount : int.parse(b)) : start;
    if (start < 1 || end > pageCount || start > end) return null;
    for (var i = start; i <= end; i++) {
      out.add(i - 1);
    }
  }
  return out.toList()..sort();
}

/// Splits [pageCount] pages into groups of [every] (the last may be short).
List<List<int>> splitEvery(int pageCount, int every) {
  final n = every < 1 ? 1 : every;
  return [
    for (var s = 0; s < pageCount; s += n)
      [for (var i = s; i < s + n && i < pageCount; i++) i],
  ];
}

/// Splits "1-3, 4-6" into one group per comma-separated part.
List<List<int>>? parseRangeGroups(String input, int pageCount) {
  final parts = input.split(',').where((s) => s.trim().isNotEmpty).toList();
  if (parts.isEmpty) return null;
  final groups = <List<int>>[];
  for (final part in parts) {
    final pages = parsePageRanges(part, pageCount);
    if (pages == null) return null;
    groups.add(pages);
  }
  return groups;
}

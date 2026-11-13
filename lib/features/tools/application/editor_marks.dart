import 'dart:math' as math;
import 'dart:ui';

import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/features/tools/application/signature_store.dart';
import 'package:meta/meta.dart';

/// Something drawn in the Annotate / Sign editor (S14), stored as fractions
/// of the page as seen on screen (top-left origin) until saved.
@immutable
sealed class EditorMark {
  const EditorMark(this.page);
  final int page;

  /// Area it covers, for the eraser.
  Rect get bounds;
}

final class MarkupMark extends EditorMark {
  const MarkupMark(super.page, this.kind, this.colorRgb, this.lines);
  final MarkupKind kind;
  final int colorRgb;

  /// One rectangle per text line.
  final List<Rect> lines;

  @override
  Rect get bounds => lines.reduce((a, b) => a.expandToInclude(b));
}

final class PenMark extends EditorMark {
  const PenMark(super.page, this.colorRgb, this.widthPt, this.strokes);
  final int colorRgb;
  final double widthPt;
  final List<List<Offset>> strokes;

  @override
  Rect get bounds => _boundsOf(strokes.expand((s) => s));
}

final class NoteEditorMark extends EditorMark {
  const NoteEditorMark(super.page, this.at, this.text);
  final Offset at;
  final String text;

  @override
  Rect get bounds => Rect.fromCenter(center: at, width: 0.06, height: 0.04);
}

/// A placed signature; [box] can still be moved and resized.
final class SignatureMark extends EditorMark {
  const SignatureMark(super.page, this.signature, this.box);
  final Signature signature;
  final Rect box;

  SignatureMark withBox(Rect next) => SignatureMark(page, signature, next);

  @override
  Rect get bounds => box;

  /// Strokes in page fractions.
  List<List<Offset>> get strokes => [
    for (final s in signature.strokes)
      [
        for (var i = 0; i + 1 < s.length; i += 2)
          Offset(box.left + s[i] * box.width, box.top + s[i + 1] * box.height),
      ],
  ];
}

Rect _boundsOf(Iterable<Offset> points) {
  var (l, t, r, b) = (double.infinity, double.infinity, -1.0, -1.0);
  for (final p in points) {
    l = math.min(l, p.dx);
    t = math.min(t, p.dy);
    r = math.max(r, p.dx);
    b = math.max(b, p.dy);
  }
  return l.isFinite ? Rect.fromLTRB(l, t, r, b) : Rect.zero;
}

/// Brand-neutral ink colours offered by the pen (6) and markup tools.
const penColors = [0x1B1B1F, 0x1A3A8F, 0xC0392B, 0x1E7A46, 0xE07B00, 0x7B3FA0];
const markupColors = [0xFFE066, 0x8FD18F, 0x8EC5FF, 0xFF9AA2];
const penWidths = [1.0, 2.5, 5.0];

/// Converts editor marks to PDF annotations in page space (FR-PDF-02).
List<PdfMark> toPdfMarks(List<EditorMark> marks, PdfInfo info) {
  final out = <PdfMark>[];
  for (final m in marks) {
    final page = info.pages[m.page];
    (double, double) pt(Offset f) {
      final (x, y) = page.fromVisible(f.dx, f.dy);
      return (x + page.x0, y + page.y0);
    }

    List<double> line(List<Offset> stroke) => [
      for (final o in stroke) ...[pt(o).$1, pt(o).$2],
    ];

    switch (m) {
      case MarkupMark(:final kind, :final colorRgb, :final lines):
        out.add(
          TextMarkup(m.page, colorRgb, kind, [
            for (final r in lines) ...[
              ...[pt(r.topLeft).$1, pt(r.topLeft).$2],
              ...[pt(r.topRight).$1, pt(r.topRight).$2],
              ...[pt(r.bottomLeft).$1, pt(r.bottomLeft).$2],
              ...[pt(r.bottomRight).$1, pt(r.bottomRight).$2],
            ],
          ]),
        );
      case PenMark(:final colorRgb, :final widthPt, :final strokes):
        out.add(
          InkMark(m.page, colorRgb, [
            for (final s in strokes) line(s),
          ], widthPt),
        );
      case NoteEditorMark(:final at, :final text):
        final (x, y) = pt(at);
        out.add(NoteMark(m.page, 0xF2B807, x, y, text));
      case SignatureMark():
        final heightPt = m.box.height * page.visibleHeight;
        out.add(
          InkMark(m.page, 0x1B1B1F, [
            for (final s in m.strokes) line(s),
          ], (heightPt * 0.035).clamp(0.8, 3.0)),
        );
    }
  }
  return out;
}

/// Text lines between two touch points, from a page's character boxes
/// (fractions of the visible page). Picks every character from the one
/// nearest [a] to the one nearest [b] in reading order and joins them into
/// one rectangle per line. Empty when the page has no text.
List<Rect> selectTextLines(List<Rect> chars, Offset a, Offset b) {
  if (chars.isEmpty) return const [];
  int nearest(Offset p) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < chars.length; i++) {
      final r = chars[i];
      if (r.isEmpty) continue;
      final dx = p.dx < r.left
          ? r.left - p.dx
          : (p.dx > r.right ? p.dx - r.right : 0.0);
      final dy = p.dy < r.top
          ? r.top - p.dy
          : (p.dy > r.bottom ? p.dy - r.bottom : 0.0);
      final d = dx * dx + dy * dy * 4;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  final i = nearest(a);
  final j = nearest(b);
  final from = math.min(i, j);
  final to = math.max(i, j);
  final lines = <Rect>[];
  Rect? current;
  for (var k = from; k <= to; k++) {
    final r = chars[k];
    if (r.isEmpty || r.width <= 0 || r.height <= 0) continue;
    final cur = current;
    if (cur != null) {
      final mid = r.center.dy;
      final sameLine = mid > cur.top && mid < cur.bottom;
      if (sameLine) {
        current = cur.expandToInclude(r);
        continue;
      }
      lines.add(cur);
    }
    current = r;
  }
  if (current != null) lines.add(current);
  return lines;
}

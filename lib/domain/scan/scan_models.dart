import 'dart:convert';

import 'package:meta/meta.dart';

/// How a scan session lays out its pages (FR-SCAN-04).
enum ScanMode {
  document('document'),
  idCard('id_card'),
  book('book');

  const ScanMode(this.key);

  /// Stored in `scan_sessions.mode`.
  final String key;

  static ScanMode fromKey(String? key) =>
      values.firstWhere((m) => m.key == key, orElse: () => document);
}

/// Per-page look (S24).
enum ScanFilter {
  original,
  document,
  grayscale,
  enhanced;

  static ScanFilter fromName(String? name) =>
      values.firstWhere((f) => f.name == name, orElse: () => original);
}

/// Output page size (S25). [fit] makes each page the size of its image.
enum ScanPageSize {
  a4(595.28, 841.89),
  letter(612, 792),
  fit(0, 0);

  const ScanPageSize(this.width, this.height);

  /// In PDF points (1/72 inch).
  final double width;
  final double height;

  static ScanPageSize fromName(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => a4);
}

/// Output quality (S25): longest image edge and JPEG quality.
enum ScanQuality {
  small(1600, 60, 0.09),
  balanced(2200, 75, 0.14),
  best(3000, 88, 0.24);

  const ScanQuality(this.maxEdge, this.jpegQuality, this.bytesPerPixel);

  final int maxEdge;
  final int jpegQuality;

  /// Rough JPEG size per pixel for paper pages, for the size estimate.
  final double bytesPerPixel;

  static ScanQuality fromName(String? name) =>
      values.firstWhere((q) => q.name == name, orElse: () => balanced);
}

/// A point in 0–1 image coordinates (x to the right, y down).
@immutable
final class NPoint {
  const NPoint(this.x, this.y);
  final double x;
  final double y;

  NPoint clamp() => NPoint(x.clamp(0, 1).toDouble(), y.clamp(0, 1).toDouble());

  @override
  bool operator ==(Object other) =>
      other is NPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'NPoint($x, $y)';
}

/// The four corners of the page inside a photo, clockwise from top-left.
@immutable
final class Quad {
  const Quad(this.topLeft, this.topRight, this.bottomRight, this.bottomLeft);

  static const full = Quad(
    NPoint(0, 0),
    NPoint(1, 0),
    NPoint(1, 1),
    NPoint(0, 1),
  );

  final NPoint topLeft;
  final NPoint topRight;
  final NPoint bottomRight;
  final NPoint bottomLeft;

  List<NPoint> get points => [topLeft, topRight, bottomRight, bottomLeft];

  bool get isFull => this == full;

  Quad withPoint(int index, NPoint p) {
    final list = points..[index] = p.clamp();
    return Quad(list[0], list[1], list[2], list[3]);
  }

  /// True when the corners form a simple convex shape, so the crop makes sense.
  bool get isConvex {
    final ps = points;
    var sign = 0;
    for (var i = 0; i < 4; i++) {
      final a = ps[i];
      final b = ps[(i + 1) % 4];
      final c = ps[(i + 2) % 4];
      final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
      if (cross.abs() < 1e-9) return false;
      final s = cross > 0 ? 1 : -1;
      if (sign == 0) {
        sign = s;
      } else if (s != sign) {
        return false;
      }
    }
    return true;
  }

  List<double> toList() => [
    for (final p in points) ...[p.x, p.y],
  ];

  static Quad? fromList(List<Object?>? list) {
    if (list == null || list.length != 8) return null;
    final v = [for (final e in list) (e! as num).toDouble()];
    return Quad(
      NPoint(v[0], v[1]),
      NPoint(v[2], v[3]),
      NPoint(v[4], v[5]),
      NPoint(v[6], v[7]),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Quad &&
      other.topLeft == topLeft &&
      other.topRight == topRight &&
      other.bottomRight == bottomRight &&
      other.bottomLeft == bottomLeft;

  @override
  int get hashCode => Object.hash(topLeft, topRight, bottomRight, bottomLeft);
}

/// One recognised line, in pixels of the image it was read from.
final class OcrLine {
  const OcrLine(this.text, this.left, this.top, this.width, this.height);

  final String text;
  final double left;
  final double top;
  final double width;
  final double height;

  Map<String, Object> toJson() => {
    't': text,
    'l': left,
    'y': top,
    'w': width,
    'h': height,
  };

  static OcrLine fromJson(Map<String, Object?> m) => OcrLine(
    m['t']! as String,
    (m['l']! as num).toDouble(),
    (m['y']! as num).toDouble(),
    (m['w']! as num).toDouble(),
    (m['h']! as num).toDouble(),
  );
}

/// OCR result of one page image.
final class OcrPage {
  const OcrPage(this.imageWidth, this.imageHeight, this.lines);

  static const empty = OcrPage(1, 1, []);

  final double imageWidth;
  final double imageHeight;
  final List<OcrLine> lines;

  String get text => lines.map((l) => l.text).join('\n');

  String encode() => jsonEncode({
    'w': imageWidth,
    'h': imageHeight,
    'lines': [for (final l in lines) l.toJson()],
  });

  static OcrPage? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, Object?>;
      return OcrPage((m['w']! as num).toDouble(), (m['h']! as num).toDouble(), [
        for (final l in m['lines']! as List<Object?>)
          OcrLine.fromJson((l! as Map).cast<String, Object?>()),
      ]);
    } on Object {
      return null;
    }
  }
}

/// Per-page edits that are kept in `scan_pages.corners_json`: the crop
/// corners and, in Book mode, where the spread is split (0–1 of the width).
final class PageGeometry {
  const PageGeometry({this.quad = Quad.full, this.split});

  final Quad quad;
  final double? split;

  PageGeometry copyWith({Quad? quad, double? split, bool clearSplit = false}) =>
      PageGeometry(
        quad: quad ?? this.quad,
        split: clearSplit ? null : (split ?? this.split),
      );

  String encode() =>
      jsonEncode({'corners': quad.toList(), if (split != null) 'split': split});

  static PageGeometry decode(String? raw) {
    if (raw == null || raw.isEmpty) return const PageGeometry();
    try {
      final m = jsonDecode(raw) as Map<String, Object?>;
      return PageGeometry(
        quad: Quad.fromList(m['corners'] as List<Object?>?) ?? Quad.full,
        split: (m['split'] as num?)?.toDouble(),
      );
    } on Object {
      return const PageGeometry();
    }
  }
}

/// A captured page and its edits.
final class ScanPage {
  const ScanPage({
    required this.id,
    required this.position,
    required this.originalPath,
    this.processedPath,
    this.geometry = const PageGeometry(),
    this.filter = ScanFilter.original,
    this.rotation = 0,
    this.ocr,
  });

  final int id;
  final int position;
  final String originalPath;

  /// Cropped, rotated and filtered image; null until processed.
  final String? processedPath;
  final PageGeometry geometry;
  final ScanFilter filter;

  /// Clockwise quarter turns in degrees: 0, 90, 180 or 270.
  final int rotation;
  final OcrPage? ocr;
}

/// A scan in progress (a draft) and its export settings.
final class ScanSession {
  const ScanSession({
    required this.id,
    required this.title,
    required this.mode,
    required this.pages,
    required this.updatedAt,
    this.pageSize = ScanPageSize.a4,
    this.quality = ScanQuality.balanced,
    this.ocrEnabled = false,
  });

  final int id;
  final String title;
  final ScanMode mode;
  final List<ScanPage> pages;
  final DateTime updatedAt;
  final ScanPageSize pageSize;
  final ScanQuality quality;
  final bool ocrEnabled;
}

/// ID card size in millimetres (ISO/IEC 7810 ID-1).
const idCardWidthMm = 85.6;
const idCardHeightMm = 54.0;

/// Points per millimetre in PDF.
const pointsPerMm = 72 / 25.4;

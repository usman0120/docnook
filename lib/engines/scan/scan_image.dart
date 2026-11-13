import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:image/image.dart' as img;

/// Image work for scans (BLUEPRINT 4.3): perspective crop, rotation,
/// filters, edge and gutter detection. Pure Dart; every entry point is meant
/// to run inside a JobRunner isolate.

/// Arguments for [renderScanImage]. Plain data so it can cross isolates.
final class RenderArgs {
  const RenderArgs({
    required this.source,
    required this.output,
    required this.corners,
    required this.rotation,
    required this.filter,
    required this.maxEdge,
    required this.jpegQuality,
    this.split,
    this.half,
  });

  final String source;
  final String output;

  /// [Quad.toList] of the crop corners.
  final List<double> corners;
  final int rotation;
  final String filter;
  final int maxEdge;
  final int jpegQuality;

  /// Book mode: split point (0–1 of the width of the cropped, rotated
  /// spread), and which half to keep: 0 left, 1 right. Null for a whole page.
  final double? split;
  final int? half;
}

/// Width and height of a written image.
typedef ImageSize = ({int width, int height});

/// Decodes a photo and turns it upright using its EXIF orientation.
img.Image loadUpright(String path) {
  final bytes = File(path).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const DocNookFailure.corrupt();
  final upright = img.bakeOrientation(decoded);
  return upright.numChannels == 3 && upright.format == img.Format.uint8
      ? upright
      : upright.convert(numChannels: 3, format: img.Format.uint8);
}

/// Crops, splits, rotates, filters and writes one scan image as JPEG.
ImageSize renderScanImage(RenderArgs a) {
  final src = loadUpright(a.source);
  final quad = Quad.fromList(a.corners) ?? Quad.full;
  var out = rectify(src, quad, a.half == null ? a.maxEdge : a.maxEdge * 2);
  // Rotate before splitting, so the split is where the user saw it on the
  // upright preview.
  out = rotateQuarter(out, a.rotation);
  if (a.half != null) {
    final split = ((a.split ?? 0.5) * out.width).round().clamp(
      1,
      out.width - 1,
    );
    out = a.half == 0
        ? img.copyCrop(out, x: 0, y: 0, width: split, height: out.height)
        : img.copyCrop(
            out,
            x: split,
            y: 0,
            width: out.width - split,
            height: out.height,
          );
  }
  out = applyFilter(out, ScanFilter.fromName(a.filter));
  final jpeg = img.encodeJpg(out, quality: a.jpegQuality);
  File('${a.output}.part')
    ..writeAsBytesSync(jpeg, flush: true)
    ..renameSync(a.output);
  return (width: out.width, height: out.height);
}

/// Perspective-corrects [src] to the page inside [quad], at most [maxEdge]
/// pixels on its longer side.
img.Image rectify(img.Image src, Quad quad, int maxEdge) {
  var source = src;
  final w = src.width.toDouble();
  final h = src.height.toDouble();
  double dist(NPoint a, NPoint b) =>
      math.sqrt(math.pow((a.x - b.x) * w, 2) + math.pow((a.y - b.y) * h, 2));
  var outW = math.max(
    dist(quad.topLeft, quad.topRight),
    dist(quad.bottomLeft, quad.bottomRight),
  );
  var outH = math.max(
    dist(quad.topLeft, quad.bottomLeft),
    dist(quad.topRight, quad.bottomRight),
  );
  final scale = math.min(1, maxEdge / math.max(outW, outH));
  outW = math.max(1, outW * scale);
  outH = math.max(1, outH * scale);

  // Shrink large photos first with box averaging; rectify itself samples.
  if (scale < 0.5) {
    source = img.copyResize(
      src,
      width: math.max(1, (src.width * scale * 1.5).round()),
      interpolation: img.Interpolation.average,
    );
  }
  if (quad.isFull) {
    if (source.width == outW.round() && source.height == outH.round()) {
      return source;
    }
    return img.copyResize(
      source,
      width: outW.round(),
      height: outH.round(),
      interpolation: img.Interpolation.average,
    );
  }
  final sw = source.width - 1;
  final sh = source.height - 1;
  img.Point px(NPoint p) => img.Point(p.x * sw, p.y * sh);
  return img.copyRectify(
    source,
    topLeft: px(quad.topLeft),
    topRight: px(quad.topRight),
    bottomLeft: px(quad.bottomLeft),
    bottomRight: px(quad.bottomRight),
    interpolation: img.Interpolation.linear,
    toImage: img.Image(width: outW.round(), height: outH.round()),
  );
}

img.Image rotateQuarter(img.Image src, int degrees) {
  final d = ((degrees % 360) + 360) % 360;
  if (d == 0) return src;
  return img.copyRotate(src, angle: d);
}

/// Applies a S24 filter. Document and Enhanced divide out the paper's
/// uneven lighting so the background turns white.
img.Image applyFilter(img.Image src, ScanFilter filter) {
  switch (filter) {
    case ScanFilter.original:
      return src;
    case ScanFilter.grayscale:
      return img.grayscale(src);
    case ScanFilter.document:
      return _flatten(src, color: false);
    case ScanFilter.enhanced:
      return _flatten(src, color: true);
  }
}

img.Image _flatten(img.Image src, {required bool color}) {
  final w = src.width;
  final h = src.height;
  final rgb = src.getBytes(order: img.ChannelOrder.rgb);
  final luma = Uint8List(w * h);
  for (var i = 0, j = 0; i < luma.length; i++, j += 3) {
    luma[i] = (rgb[j] * 77 + rgb[j + 1] * 150 + rgb[j + 2] * 29) >> 8;
  }
  final bg = _Background(luma, w, h);
  final out = Uint8List(color ? w * h * 3 : w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final b = math.max(bg.at(x, y), 40);
      final gain = 255 / b;
      if (color) {
        final j = i * 3;
        for (var c = 0; c < 3; c++) {
          out[j + c] = _curve(rgb[j + c] * gain, strong: false);
        }
      } else {
        out[i] = _curve(luma[i] * gain, strong: true);
      }
    }
  }
  return img.Image.fromBytes(
    width: w,
    height: h,
    bytes: out.buffer,
    numChannels: color ? 3 : 1,
  );
}

/// Contrast curve after flattening: pushes near-white to white and darkens
/// ink. The document curve is steeper than the colour one.
int _curve(double v, {required bool strong}) {
  final x = (v / 255).clamp(0.0, 1.0);
  final lo = strong ? 0.25 : 0.12;
  final hi = strong ? 0.90 : 0.94;
  final t = ((x - lo) / (hi - lo)).clamp(0.0, 1.0);
  // Smooth step keeps mid-tones from banding.
  return (t * t * (3 - 2 * t) * 255).round();
}

/// The paper's brightness around each pixel: a coarse grid of local maxima
/// (text is darker than paper, so maxima ignore it), smoothed and sampled
/// bilinearly.
final class _Background {
  _Background(Uint8List luma, this.w, this.h) {
    cell = math.max(8, math.max(w, h) ~/ 48);
    gw = (w + cell - 1) ~/ cell;
    gh = (h + cell - 1) ~/ cell;
    var grid = Float64List(gw * gh);
    for (var gy = 0; gy < gh; gy++) {
      for (var gx = 0; gx < gw; gx++) {
        // 90th percentile of the cell via a small histogram.
        final hist = List<int>.filled(32, 0);
        var n = 0;
        final y1 = math.min(h, (gy + 1) * cell);
        final x1 = math.min(w, (gx + 1) * cell);
        for (var y = gy * cell; y < y1; y += 2) {
          for (var x = gx * cell; x < x1; x += 2) {
            hist[luma[y * w + x] >> 3]++;
            n++;
          }
        }
        var acc = 0;
        var bin = 31;
        for (; bin > 0; bin--) {
          acc += hist[bin];
          if (acc >= n * 0.1) break;
        }
        grid[gy * gw + gx] = bin * 8.0 + 4;
      }
    }
    // Dilate then blur, so dark blocks (photos, thick text) borrow the
    // paper level from their neighbours.
    grid = _dilate(grid);
    grid = _blur(_blur(grid));
    this.grid = grid;
  }

  final int w;
  final int h;
  late final int cell;
  late final int gw;
  late final int gh;
  late final Float64List grid;

  Float64List _dilate(Float64List g) {
    final out = Float64List(g.length);
    for (var y = 0; y < gh; y++) {
      for (var x = 0; x < gw; x++) {
        var m = 0.0;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final yy = (y + dy).clamp(0, gh - 1);
            final xx = (x + dx).clamp(0, gw - 1);
            m = math.max(m, g[yy * gw + xx]);
          }
        }
        out[y * gw + x] = m;
      }
    }
    return out;
  }

  Float64List _blur(Float64List g) {
    final out = Float64List(g.length);
    for (var y = 0; y < gh; y++) {
      for (var x = 0; x < gw; x++) {
        var s = 0.0;
        var n = 0;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final yy = y + dy;
            final xx = x + dx;
            if (yy < 0 || yy >= gh || xx < 0 || xx >= gw) continue;
            s += g[yy * gw + xx];
            n++;
          }
        }
        out[y * gw + x] = s / n;
      }
    }
    return out;
  }

  double at(int x, int y) {
    final fx = (x / cell - 0.5).clamp(0.0, gw - 1.0);
    final fy = (y / cell - 0.5).clamp(0.0, gh - 1.0);
    final x0 = fx.floor();
    final y0 = fy.floor();
    final x1 = math.min(x0 + 1, gw - 1);
    final y1 = math.min(y0 + 1, gh - 1);
    final tx = fx - x0;
    final ty = fy - y0;
    final a = grid[y0 * gw + x0] * (1 - tx) + grid[y0 * gw + x1] * tx;
    final b = grid[y1 * gw + x0] * (1 - tx) + grid[y1 * gw + x1] * tx;
    return a * (1 - ty) + b * ty;
  }
}

/// Finds the page in a photo: the largest bright region (paper is lighter
/// than most tables), and its four extreme corners. Returns [Quad.full] when
/// nothing convincing is found, so the user starts from the whole photo.
Quad detectPageQuad(String path) => detectQuadIn(loadUpright(path));

Quad detectQuadIn(img.Image photo) {
  const target = 256;
  final small = img.copyResize(
    photo,
    width: photo.width >= photo.height ? target : null,
    height: photo.width >= photo.height ? null : target,
    interpolation: img.Interpolation.average,
  );
  final w = small.width;
  final h = small.height;
  final rgb = small.getBytes(order: img.ChannelOrder.rgb);
  final luma = Uint8List(w * h);
  for (var i = 0, j = 0; i < luma.length; i++, j += 3) {
    luma[i] = (rgb[j] * 77 + rgb[j + 1] * 150 + rgb[j + 2] * 29) >> 8;
  }
  final threshold = otsu(luma);
  final mask = Uint8List(w * h);
  for (var i = 0; i < mask.length; i++) {
    mask[i] = luma[i] > threshold ? 1 : 0;
  }
  // Largest 4-connected bright component.
  final label = Int32List(w * h);
  var best = 0;
  var bestSize = 0;
  var next = 0;
  final stack = <int>[];
  for (var start = 0; start < mask.length; start++) {
    if (mask[start] == 0 || label[start] != 0) continue;
    next++;
    var size = 0;
    stack
      ..clear()
      ..add(start);
    label[start] = next;
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      size++;
      final x = i % w;
      final y = i ~/ w;
      void visit(int j) {
        if (mask[j] == 1 && label[j] == 0) {
          label[j] = next;
          stack.add(j);
        }
      }

      if (x > 0) visit(i - 1);
      if (x < w - 1) visit(i + 1);
      if (y > 0) visit(i - w);
      if (y < h - 1) visit(i + w);
    }
    if (size > bestSize) {
      bestSize = size;
      best = next;
    }
  }
  final area = w * h;
  if (bestSize < area * 0.12 || bestSize > area * 0.97) return Quad.full;

  var tl = (0, 0, 1 << 30);
  var br = (0, 0, -1);
  var tr = (0, 0, -(1 << 30));
  var bl = (0, 0, 1 << 30);
  for (var i = 0; i < label.length; i++) {
    if (label[i] != best) continue;
    final x = i % w;
    final y = i ~/ w;
    if (x + y < tl.$3) tl = (x, y, x + y);
    if (x + y > br.$3) br = (x, y, x + y);
    if (x - y > tr.$3) tr = (x, y, x - y);
    if (x - y < bl.$3) bl = (x, y, x - y);
  }
  NPoint n((int, int, int) p) => NPoint(p.$1 / (w - 1), p.$2 / (h - 1)).clamp();
  final quad = Quad(n(tl), n(tr), n(br), n(bl));
  if (!quad.isConvex || quadArea(quad) < 0.12) return Quad.full;
  return quad;
}

/// Area of a quad in 0–1 units (shoelace formula).
double quadArea(Quad q) {
  final p = q.points;
  var s = 0.0;
  for (var i = 0; i < 4; i++) {
    final a = p[i];
    final b = p[(i + 1) % 4];
    s += a.x * b.y - b.x * a.y;
  }
  return s.abs() / 2;
}

/// Otsu's threshold for an 8-bit histogram.
int otsu(Uint8List values) {
  final hist = List<int>.filled(256, 0);
  for (final v in values) {
    hist[v]++;
  }
  final total = values.length;
  var sum = 0.0;
  for (var i = 0; i < 256; i++) {
    sum += i * hist[i];
  }
  var sumB = 0.0;
  var wB = 0;
  var best = 0.0;
  var threshold = 127;
  for (var t = 0; t < 256; t++) {
    wB += hist[t];
    if (wB == 0) continue;
    final wF = total - wB;
    if (wF == 0) break;
    sumB += t * hist[t];
    final mB = sumB / wB;
    final mF = (sum - sumB) / wF;
    final between = wB * wF * (mB - mF) * (mB - mF);
    if (between > best) {
      best = between;
      threshold = t;
    }
  }
  return threshold;
}

/// Book mode: the gutter of a two-page spread, as 0–1 of the cropped width.
/// Looks for the darkest column band (the fold's shadow) in the middle third;
/// falls back to the centre when there is no clear fold.
double detectSplitIn(img.Image spread) {
  final small = img.copyResize(
    spread,
    width: math.min(400, spread.width),
    interpolation: img.Interpolation.average,
  );
  final w = small.width;
  final h = small.height;
  final rgb = small.getBytes(order: img.ChannelOrder.rgb);
  final cols = Float64List(w);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final j = (y * w + x) * 3;
      cols[x] += rgb[j] * 0.3 + rgb[j + 1] * 0.59 + rgb[j + 2] * 0.11;
    }
  }
  for (var x = 0; x < w; x++) {
    cols[x] /= h;
  }
  final from = (w * 0.35).floor();
  final to = (w * 0.65).ceil();
  const radius = 3;
  var bestX = w ~/ 2;
  var bestV = double.infinity;
  final values = <double>[];
  for (var x = from; x < to; x++) {
    var s = 0.0;
    var n = 0;
    for (var d = -radius; d <= radius; d++) {
      final xx = x + d;
      if (xx < 0 || xx >= w) continue;
      s += cols[xx];
      n++;
    }
    final v = s / n;
    values.add(v);
    if (v < bestV) {
      bestV = v;
      bestX = x;
    }
  }
  if (values.isEmpty) return 0.5;
  values.sort();
  final median = values[values.length ~/ 2];
  if (median - bestV < 6) return 0.5;
  return bestX / w;
}

/// Detects the gutter of the cropped spread in [path].
double detectSplit(String path, List<double> corners) {
  final src = loadUpright(path);
  final spread = rectify(src, Quad.fromList(corners) ?? Quad.full, 800);
  return detectSplitIn(spread);
}

/// ID-card JPG export: front and back at real size on a white A4 sheet at
/// [dpi].
ImageSize composeIdCardSheet({
  required List<String> cards,
  required String output,
  int dpi = 200,
  int jpegQuality = 85,
}) {
  int mm(double v) => (v / 25.4 * dpi).round();
  final sheet = img.Image(width: mm(210), height: mm(297));
  img.fill(sheet, color: img.ColorRgb8(255, 255, 255));
  final placements = idCardPlacements(cards.length);
  for (var i = 0; i < cards.length; i++) {
    final card = loadUpright(cards[i]);
    final portrait = card.height > card.width;
    final slot = placements[i];
    final wMm = portrait ? idCardHeightMm : idCardWidthMm;
    final hMm = portrait ? idCardWidthMm : idCardHeightMm;
    final x = slot.centerXMm - wMm / 2;
    final y = slot.topMm;
    final resized = img.copyResize(
      card,
      width: mm(wMm),
      height: mm(hMm),
      interpolation: img.Interpolation.average,
    );
    img.compositeImage(sheet, resized, dstX: mm(x), dstY: mm(y));
  }
  File('$output.part')
    ..writeAsBytesSync(img.encodeJpg(sheet, quality: jpegQuality), flush: true)
    ..renameSync(output);
  return (width: sheet.width, height: sheet.height);
}

/// Where ID-card images go on an A4 sheet, in millimetres from the top-left:
/// horizontally centred, the front 40 mm from the top and the back 20 mm
/// below it (BLUEPRINT FR-SCAN-04).
List<({double centerXMm, double topMm})> idCardPlacements(int count) => [
  for (var i = 0; i < count; i++)
    (centerXMm: 105.0, topMm: 40 + i * (idCardWidthMm + 20)),
];

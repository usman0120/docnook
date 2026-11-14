import 'dart:io';
import 'dart:typed_data';

import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:image/image.dart' as img;

/// A rendered page to turn into a JPEG, optionally with areas blacked out.
final class RasterPageArgs {
  const RasterPageArgs({
    required this.bgra,
    required this.width,
    required this.height,
    required this.output,
    required this.quality,
    this.boxes = const [],
    this.png = false,
  });

  /// Write a PNG instead of a JPEG (PDF → Images).
  final bool png;

  /// [width] × [height] pixels, BGRA, as PDFium renders them.
  final Uint8List bgra;
  final int width;
  final int height;
  final String output;
  final int quality;

  /// Areas to paint solid black, four numbers each (left, top, right,
  /// bottom) as fractions of the page, top-left origin.
  final List<double> boxes;
}

/// Writes the page as a baseline JPEG with every box painted black. The
/// boxes are burnt into the pixels before encoding, so nothing under them
/// survives (FR-PDF-04). Runs in a JobRunner isolate.
int rasterPage(RasterPageArgs a, JobContext _) {
  final image = img.Image.fromBytes(
    width: a.width,
    height: a.height,
    bytes: a.bgra.buffer,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  );
  final flat = img.Image(width: a.width, height: a.height);
  // Composite on white: transparent areas would otherwise turn black.
  for (final p in image) {
    final alpha = p.a / 255;
    flat.setPixelRgb(
      p.x,
      p.y,
      (p.r * alpha + 255 * (1 - alpha)).round(),
      (p.g * alpha + 255 * (1 - alpha)).round(),
      (p.b * alpha + 255 * (1 - alpha)).round(),
    );
  }
  for (var i = 0; i + 3 < a.boxes.length; i += 4) {
    final l = (a.boxes[i] * a.width).floor().clamp(0, a.width);
    final t = (a.boxes[i + 1] * a.height).floor().clamp(0, a.height);
    final r = (a.boxes[i + 2] * a.width).ceil().clamp(0, a.width);
    final b = (a.boxes[i + 3] * a.height).ceil().clamp(0, a.height);
    if (r <= l || b <= t) continue;
    img.fillRect(
      flat,
      x1: l,
      y1: t,
      x2: r - 1,
      y2: b - 1,
      color: img.ColorRgb8(0, 0, 0),
    );
  }
  final bytes = a.png
      ? img.encodePng(flat)
      : img.encodeJpg(flat, quality: a.quality);
  File(a.output).writeAsBytesSync(bytes, flush: true);
  return bytes.length;
}

/// An image file prepared for a PDF page: a baseline JPEG, upright.
final class PreparedImage {
  const PreparedImage(this.path, this.width, this.height);
  final String path;
  final int width;
  final int height;
}

/// Decodes any supported picture, applies its EXIF orientation and writes
/// a JPEG to [output]. Runs in a JobRunner isolate.
PreparedImage prepareImage((String, String, int) args, JobContext context) =>
    prepareImageMax((args.$1, args.$2, args.$3, 0), context);

/// [prepareImage], shrunk to at most `maxEdge` pixels on the longer side
/// (0 keeps the full size).
PreparedImage prepareImageMax((String, String, int, int) args, JobContext _) {
  final (input, output, quality, maxEdge) = args;
  final bytes = File(input).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('image');
  var upright = img.bakeOrientation(decoded);
  final longest = upright.width > upright.height
      ? upright.width
      : upright.height;
  if (maxEdge > 0 && longest > maxEdge) {
    upright = img.copyResize(
      upright,
      width: upright.width >= upright.height ? maxEdge : null,
      height: upright.height > upright.width ? maxEdge : null,
      interpolation: img.Interpolation.average,
    );
  }
  final flat = upright.hasAlpha
      ? (img.Image(width: upright.width, height: upright.height)
          ..clear(img.ColorRgb8(255, 255, 255)))
      : null;
  if (flat != null) img.compositeImage(flat, upright);
  final out = flat ?? upright;
  File(output).writeAsBytesSync(img.encodeJpg(out, quality: quality));
  return PreparedImage(output, out.width, out.height);
}

/// Decodes a picture (signature, logo) into BGRA pixels, at most [maxEdge]
/// pixels on its longer side. Runs in a JobRunner isolate.
(Uint8List, int, int) decodeBgra((String, int) args, JobContext _) {
  final decoded = img.decodeImage(File(args.$1).readAsBytesSync());
  if (decoded == null) throw const FormatException('image');
  var image = img.bakeOrientation(decoded);
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > args.$2) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? args.$2 : null,
      height: image.height > image.width ? args.$2 : null,
      interpolation: img.Interpolation.average,
    );
  }
  final rgba = image.convert(numChannels: 4);
  final out = Uint8List(rgba.width * rgba.height * 4);
  var o = 0;
  for (final p in rgba) {
    out[o] = p.b.toInt();
    out[o + 1] = p.g.toInt();
    out[o + 2] = p.r.toInt();
    out[o + 3] = p.a.toInt();
    o += 4;
  }
  return (out, rgba.width, rgba.height);
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/scan/scan_models.dart';

/// Writes scans as a PDF (BLUEPRINT 4.3, FR-SCAN-03): each page holds JPEG
/// images placed as-is (DCTDecode, no re-encoding) and, when OCR ran, an
/// invisible text layer (render mode 3) laid over the recognised lines so
/// the text can be selected, copied and searched.
///
/// Pure Dart, streaming: images are copied from disk one at a time.

/// One image on a page, in points from the page's top-left.
final class PlacedImage {
  const PlacedImage({
    required this.path,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.ocr,
  });

  final String path;
  final double x;
  final double y;
  final double width;
  final double height;

  /// [OcrPage.encode] of this image, or null.
  final String? ocr;
}

final class PdfPagePlan {
  const PdfPagePlan(this.width, this.height, this.images);
  final double width;
  final double height;
  final List<PlacedImage> images;
}

final class ScanPdfRequest {
  const ScanPdfRequest({required this.output, required this.pages, this.title});

  final String output;
  final List<PdfPagePlan> pages;
  final String? title;
}

/// Size and colour layout of a baseline or progressive JPEG.
final class JpegInfo {
  const JpegInfo(this.width, this.height, this.components);
  final int width;
  final int height;
  final int components;
}

/// Reads the SOF marker of a JPEG.
JpegInfo readJpegInfo(Uint8List b) {
  if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) {
    throw const DocNookFailure.corrupt();
  }
  var i = 2;
  while (i + 9 < b.length) {
    if (b[i] != 0xFF) {
      i++;
      continue;
    }
    final marker = b[i + 1];
    if (marker == 0xFF) {
      i++;
      continue;
    }
    if (marker == 0xD8 ||
        marker == 0x01 ||
        (marker >= 0xD0 && marker <= 0xD7)) {
      i += 2;
      continue;
    }
    final length = (b[i + 2] << 8) | b[i + 3];
    final isSof =
        marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC;
    if (isSof) {
      final height = (b[i + 5] << 8) | b[i + 6];
      final width = (b[i + 7] << 8) | b[i + 8];
      final components = b[i + 9];
      return JpegInfo(width, height, components);
    }
    i += 2 + length;
  }
  throw const DocNookFailure.corrupt();
}

/// Lays out one image per page. A4 and Letter fit the image inside the page,
/// centred; [ScanPageSize.fit] makes a page of the image's shape, 595 pt
/// (A4 width) across.
PdfPagePlan planSinglePage({
  required String path,
  required int pixelWidth,
  required int pixelHeight,
  required ScanPageSize size,
  String? ocr,
}) {
  final aspect = pixelHeight / pixelWidth;
  if (size == ScanPageSize.fit) {
    const w = 595.28;
    final h = w * aspect;
    return PdfPagePlan(w, h, [
      PlacedImage(path: path, x: 0, y: 0, width: w, height: h, ocr: ocr),
    ]);
  }
  final pw = size.width;
  final ph = size.height;
  var w = pw;
  var h = pw * aspect;
  if (h > ph) {
    h = ph;
    w = ph / aspect;
  }
  return PdfPagePlan(pw, ph, [
    PlacedImage(
      path: path,
      x: (pw - w) / 2,
      y: (ph - h) / 2,
      width: w,
      height: h,
      ocr: ocr,
    ),
  ]);
}

/// ID-card page: front and back at exactly 85.6 × 54 mm (portrait images
/// turned to 54 × 85.6 mm), horizontally centred (FR-SCAN-04).
PdfPagePlan planIdCardPage({
  required List<({String path, int width, int height, String? ocr})> cards,
  required ScanPageSize size,
}) {
  final pw = size == ScanPageSize.letter ? size.width : ScanPageSize.a4.width;
  final ph = size == ScanPageSize.letter ? size.height : ScanPageSize.a4.height;
  final images = <PlacedImage>[];
  var topMm = 40.0;
  for (var i = 0; i < cards.length; i++) {
    final card = cards[i];
    final portrait = card.height > card.width;
    final w = (portrait ? idCardHeightMm : idCardWidthMm) * pointsPerMm;
    final h = (portrait ? idCardWidthMm : idCardHeightMm) * pointsPerMm;
    final top = topMm * pointsPerMm;
    topMm += (portrait ? idCardWidthMm : idCardHeightMm) + 20;
    images.add(
      PlacedImage(
        path: card.path,
        x: (pw - w) / 2,
        y: top,
        width: w,
        height: h,
        ocr: card.ocr,
      ),
    );
  }
  return PdfPagePlan(pw, ph, images);
}

/// Writes [request] and returns the output size in bytes.
int writeScanPdf(ScanPdfRequest request) {
  final partial = File('${request.output}.part');
  final out = _PdfFile(partial.openSync(mode: FileMode.write));
  try {
    out.raw('%PDF-1.7\n%âãÏÓ\n');
    // Object numbers: 1 catalog, 2 pages, 3 font, 4 info, then per page.
    const catalog = 1;
    const pagesId = 2;
    const fontId = 3;
    const infoId = 4;
    var nextId = 5;
    final pageIds = <int>[];
    final plans = <(PdfPagePlan, int, int, List<int>)>[];
    for (final page in request.pages) {
      final pageId = nextId++;
      final contentId = nextId++;
      final imageIds = [for (final _ in page.images) nextId++];
      pageIds.add(pageId);
      plans.add((page, pageId, contentId, imageIds));
    }

    out
      ..object(catalog, '<< /Type /Catalog /Pages $pagesId 0 R >>')
      ..object(
        pagesId,
        '<< /Type /Pages /Count ${pageIds.length} /Kids '
        '[${pageIds.map((id) => '$id 0 R').join(' ')}] >>',
      )
      ..object(
        fontId,
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
        '/Encoding /WinAnsiEncoding >>',
      );
    final title = request.title;
    out.object(
      infoId,
      '<< /Producer ${_pdfString('DocNook')}'
      '${title == null ? '' : ' /Title ${_pdfUtf16(title)}'} >>',
    );

    for (final (page, pageId, contentId, imageIds) in plans) {
      final content = StringBuffer();
      final xobjects = StringBuffer();
      for (var i = 0; i < page.images.length; i++) {
        final placed = page.images[i];
        final bytes = File(placed.path).readAsBytesSync();
        final info = readJpegInfo(bytes);
        final space = switch (info.components) {
          1 => '/DeviceGray',
          4 => '/DeviceCMYK /Decode [1 0 1 0 1 0 1 0]',
          _ => '/DeviceRGB',
        };
        out.stream(
          imageIds[i],
          '/Type /XObject /Subtype /Image /Width ${info.width} '
          '/Height ${info.height} /ColorSpace $space /BitsPerComponent 8 '
          '/Filter /DCTDecode',
          bytes,
        );
        xobjects.write('/Im$i ${imageIds[i]} 0 R ');
        final bottom = page.height - placed.y - placed.height;
        content.write(
          'q ${_n(placed.width)} 0 0 ${_n(placed.height)} '
          '${_n(placed.x)} ${_n(bottom)} cm /Im$i Do Q\n',
        );
        final ocr = OcrPage.decode(placed.ocr);
        if (ocr != null && ocr.lines.isNotEmpty) {
          content.write(textLayer(ocr, placed, page.height));
        }
      }
      final contentBytes = latin1.encode(content.toString());
      out
        ..stream(contentId, '', contentBytes)
        ..object(
          pageId,
          '<< /Type /Page /Parent $pagesId 0 R '
          '/MediaBox [0 0 ${_n(page.width)} ${_n(page.height)}] '
          '/Resources << /Font << /F1 $fontId 0 R >> '
          '/XObject << ${xobjects.toString().trim()} >> >> '
          '/Contents $contentId 0 R >>',
        );
    }
    out.finish(catalog, infoId);
  } on Object {
    out.close();
    if (partial.existsSync()) partial.deleteSync();
    rethrow;
  }
  out.close();
  final done = partial.renameSync(request.output);
  return done.lengthSync();
}

/// Invisible text for the OCR lines of one placed image. Each line gets a
/// font size that matches its box height and a horizontal scale that makes
/// its width match, so selections line up with the printed words.
String textLayer(OcrPage ocr, PlacedImage placed, double pageHeight) {
  final sx = placed.width / ocr.imageWidth;
  final sy = placed.height / ocr.imageHeight;
  final b = StringBuffer('BT 3 Tr\n');
  for (final line in ocr.lines) {
    final text = line.text.trim();
    if (text.isEmpty || line.width <= 0 || line.height <= 0) continue;
    final boxH = line.height * sy;
    final boxW = line.width * sx;
    // Helvetica spans ascender 0.718 to descender 0.207 of the font size.
    final size = boxH / 0.925;
    final x = placed.x + line.left * sx;
    final boxBottom = placed.y + (line.top + line.height) * sy;
    final baseline = pageHeight - boxBottom + 0.207 * size;
    final em = helveticaWidth(text);
    if (em <= 0) continue;
    final scale = (100 * boxW / (em * size)).clamp(1, 1000);
    b.write(
      '/F1 ${_n(size)} Tf ${_n(scale.toDouble())} Tz '
      '1 0 0 1 ${_n(x)} ${_n(baseline)} Tm ${_winAnsiString(text)} Tj\n',
    );
  }
  b.write('ET\n');
  return b.toString();
}

/// Width of [text] in Helvetica, in ems.
double helveticaWidth(String text) {
  var units = 0;
  for (final rune in text.runes) {
    units += rune >= 32 && rune < 127 ? _helvetica[rune - 32] : 556;
  }
  return units / 1000;
}

/// Helvetica advance widths for ASCII 32–126 (Adobe AFM).
const _helvetica = <int>[
  278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, //
  278, 278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, //
  584, 584, 584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, //
  500, 667, 556, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, //
  667, 667, 611, 278, 278, 278, 469, 556, 333, 556, 556, 500, 556, 556, //
  278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, //
  278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584, //
];

/// Unicode code points of WinAnsiEncoding bytes 0x80–0x9F.
const _winAnsiHigh = <int, int>{
  0x20AC: 0x80, 0x201A: 0x82, 0x0192: 0x83, 0x201E: 0x84, 0x2026: 0x85, //
  0x2020: 0x86, 0x2021: 0x87, 0x02C6: 0x88, 0x2030: 0x89, 0x0160: 0x8A, //
  0x2039: 0x8B, 0x0152: 0x8C, 0x017D: 0x8E, 0x2018: 0x91, 0x2019: 0x92, //
  0x201C: 0x93, 0x201D: 0x94, 0x2022: 0x95, 0x2013: 0x96, 0x2014: 0x97, //
  0x02DC: 0x98, 0x2122: 0x99, 0x0161: 0x9A, 0x203A: 0x9B, 0x0153: 0x9C, //
  0x017E: 0x9E, 0x0178: 0x9F,
};

/// A PDF literal string in WinAnsi; characters it cannot hold become '?'.
String _winAnsiString(String text) {
  final b = StringBuffer('(');
  for (final rune in text.runes) {
    int code;
    if (rune >= 32 && rune < 127) {
      code = rune;
    } else if (rune >= 0xA0 && rune <= 0xFF) {
      code = rune;
    } else {
      code = _winAnsiHigh[rune] ?? 0x3F;
    }
    if (code == 0x28 || code == 0x29 || code == 0x5C) {
      b.write('\\${String.fromCharCode(code)}');
    } else if (code < 127) {
      b.writeCharCode(code);
    } else {
      b.write('\\${code.toRadixString(8).padLeft(3, '0')}');
    }
  }
  b.write(')');
  return b.toString();
}

String _pdfString(String ascii) =>
    '(${ascii.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)')})';

/// A text string as UTF-16BE hex, which holds any character.
String _pdfUtf16(String text) {
  final b = StringBuffer('<FEFF');
  for (final unit in text.codeUnits) {
    b.write(unit.toRadixString(16).padLeft(4, '0').toUpperCase());
  }
  b.write('>');
  return b.toString();
}

/// Compact number: two decimals, no trailing zeros.
String _n(double v) {
  final s = v.toStringAsFixed(2);
  if (!s.contains('.')) return s;
  final trimmed = s
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return trimmed == '-0' ? '0' : trimmed;
}

/// Tracks byte offsets of objects for the cross-reference table.
final class _PdfFile {
  _PdfFile(this._file);

  final RandomAccessFile _file;
  final _offsets = <int, int>{};
  var _position = 0;

  void raw(String text) => bytes(latin1.encode(text));

  void bytes(List<int> data) {
    _file.writeFromSync(data);
    _position += data.length;
  }

  void object(int id, String body) {
    _offsets[id] = _position;
    raw('$id 0 obj\n$body\nendobj\n');
  }

  void stream(int id, String dict, List<int> data) {
    _offsets[id] = _position;
    raw('$id 0 obj\n<< $dict /Length ${data.length} >>\nstream\n');
    bytes(data);
    raw('\nendstream\nendobj\n');
  }

  void finish(int root, int info) {
    final size = _offsets.keys.fold(0, (a, b) => a > b ? a : b) + 1;
    final xref = _position;
    final b = StringBuffer('xref\n0 $size\n0000000000 65535 f \n');
    for (var id = 1; id < size; id++) {
      final offset = _offsets[id];
      b.write(
        offset == null
            ? '0000000000 65535 f \n'
            : '${offset.toString().padLeft(10, '0')} 00000 n \n',
      );
    }
    b.write(
      'trailer\n<< /Size $size /Root $root 0 R /Info $info 0 R >>\n'
      'startxref\n$xref\n%%EOF\n',
    );
    raw(b.toString());
  }

  void close() {
    try {
      _file.closeSync();
    } on FileSystemException {
      // Already closed.
    }
  }
}

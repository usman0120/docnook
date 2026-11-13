import 'dart:io';
import 'dart:typed_data';

import 'package:docnook/data/db/app_database.dart';
import 'package:docnook/data/repositories/scan_repository.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:docnook/engines/scan/scan_image.dart';
import 'package:docnook/engines/scan/scan_pdf_writer.dart';
import 'package:docnook/features/scan/application/scan_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// A white sheet with dark text bars, photographed at an angle on a dark
/// table: the four corners are known.
img.Image photo({
  int w = 800,
  int h = 1000,
  List<(int, int)> corners = const [
    (150, 120),
    (650, 160),
    (690, 880),
    (110, 850),
  ],
}) {
  final im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(60, 52, 45));
  img.fillPolygon(
    im,
    vertices: [for (final (x, y) in corners) img.Point(x, y)],
    color: img.ColorRgb8(235, 232, 225),
  );
  for (var y = 300; y < 700; y += 60) {
    img.fillRect(
      im,
      x1: 260,
      y1: y,
      x2: 540,
      y2: y + 14,
      color: img.ColorRgb8(30, 30, 30),
    );
  }
  return im;
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('docnook_scan'));
  tearDown(() => tmp.deleteSync(recursive: true));

  String write(img.Image im, String name) {
    final path = p.join(tmp.path, name);
    File(path).writeAsBytesSync(img.encodeJpg(im, quality: 90));
    return path;
  }

  group('geometry', () {
    test('quad convexity, encode and decode', () {
      expect(Quad.full.isConvex, isTrue);
      const bowtie = Quad(
        NPoint(0, 0),
        NPoint(1, 1),
        NPoint(1, 0),
        NPoint(0, 1),
      );
      expect(bowtie.isConvex, isFalse);
      const g = PageGeometry(
        quad: Quad(
          NPoint(0.1, 0.2),
          NPoint(0.9, 0.1),
          NPoint(0.95, 0.9),
          NPoint(0.05, 0.85),
        ),
        split: 0.48,
      );
      final back = PageGeometry.decode(g.encode());
      expect(back.quad, g.quad);
      expect(back.split, 0.48);
      expect(PageGeometry.decode('not json').quad, Quad.full);
      expect(PageGeometry.decode(null).split, isNull);
    });

    test('OCR page round trip', () {
      const page = OcrPage(1000, 1400, [
        OcrLine('Invoice 42', 100, 120, 300, 40),
      ]);
      final back = OcrPage.decode(page.encode())!;
      expect(back.imageWidth, 1000);
      expect(back.lines.single.text, 'Invoice 42');
      expect(back.text, 'Invoice 42');
      expect(OcrPage.decode('{broken'), isNull);
    });
  });

  group('image processing', () {
    test('finds the page corners in a photo', () {
      final quad = detectQuadIn(photo());
      const expected = [(150, 120), (650, 160), (690, 880), (110, 850)];
      for (var i = 0; i < 4; i++) {
        expect(
          quad.points[i].x * 799,
          closeTo(expected[i].$1, 16),
          reason: 'x$i',
        );
        expect(
          quad.points[i].y * 999,
          closeTo(expected[i].$2, 16),
          reason: 'y$i',
        );
      }
    });

    test('returns the whole photo when there is no page', () {
      final flat = img.Image(width: 300, height: 400);
      img.fill(flat, color: img.ColorRgb8(128, 128, 128));
      expect(detectQuadIn(flat), Quad.full);
    });

    test('renders crop, rotation, filter and size limit', () {
      final source = write(photo(), 'photo.jpg');
      final quad = detectPageQuad(source);
      final out = p.join(tmp.path, 'out.jpg');
      final size = renderScanImage(
        RenderArgs(
          source: source,
          output: out,
          corners: quad.toList(),
          rotation: 90,
          filter: ScanFilter.document.name,
          maxEdge: 400,
          jpegQuality: 80,
        ),
      );
      // The page is taller than wide; after a quarter turn it is wider.
      expect(size.width, 400);
      expect(size.height, lessThan(400));
      final decoded = img.decodeJpg(File(out).readAsBytesSync())!;
      expect(decoded.width, size.width);
      expect(File('$out.part').existsSync(), isFalse);
      // Document filter: paper becomes white.
      final paper = decoded.getPixel(20, size.height ~/ 2);
      expect(paper.r, greaterThan(240));
      expect(paper.g, greaterThan(240));
      expect(paper.b, greaterThan(240));
      // Ink stays dark and grey (no colour cast).
      final ink = decoded.getPixel(size.width ~/ 2, size.height ~/ 2);
      expect((ink.r - ink.g).abs(), lessThan(12));
    });

    test('book spreads split at the gutter and render each half', () {
      final spread = img.Image(width: 1000, height: 700);
      img.fill(spread, color: img.ColorRgb8(240, 238, 230));
      // Shadow of the fold a little right of centre.
      img.fillRect(
        spread,
        x1: 545,
        y1: 0,
        x2: 565,
        y2: 699,
        color: img.ColorRgb8(120, 115, 110),
      );
      final split = detectSplitIn(spread);
      expect(split, closeTo(0.555, 0.02));

      final evenly = img.Image(width: 1000, height: 700);
      img.fill(evenly, color: img.ColorRgb8(240, 238, 230));
      expect(detectSplitIn(evenly), 0.5);

      final source = write(spread, 'spread.jpg');
      final left = renderScanImage(
        RenderArgs(
          source: source,
          output: p.join(tmp.path, 'left.jpg'),
          corners: Quad.full.toList(),
          rotation: 0,
          filter: 'original',
          maxEdge: 2000,
          jpegQuality: 80,
          split: split,
          half: 0,
        ),
      );
      final right = renderScanImage(
        RenderArgs(
          source: source,
          output: p.join(tmp.path, 'right.jpg'),
          corners: Quad.full.toList(),
          rotation: 0,
          filter: 'original',
          maxEdge: 2000,
          jpegQuality: 80,
          split: split,
          half: 1,
        ),
      );
      expect(left.width + right.width, 1000);
      expect(left.width, greaterThan(right.width));
    });

    test('ID card sheet places both sides at real size', () {
      final card = img.Image(width: 856, height: 540);
      img.fill(card, color: img.ColorRgb8(31, 58, 77));
      final front = write(card, 'front.jpg');
      final back = write(card, 'back.jpg');
      final out = p.join(tmp.path, 'id.jpg');
      final size = composeIdCardSheet(cards: [front, back], output: out);
      // A4 at 200 dpi.
      expect(size.width, 1654);
      expect(size.height, 2339);
      final sheet = img.decodeJpg(File(out).readAsBytesSync())!;
      // 85.6 mm at 200 dpi = 674 px wide, centred.
      final left = ((105 - 85.6 / 2) / 25.4 * 200).round();
      final top = (40 / 25.4 * 200).round();
      expect(sheet.getPixel(left + 5, top + 5).b, greaterThan(50));
      expect(sheet.getPixel(left + 5, top + 5).r, lessThan(80));
      expect(sheet.getPixel(left - 8, top + 5).r, greaterThan(240));
      // The back starts 20 mm below the front (40 + 54 + 20 = 114 mm).
      final backTop = (114 / 25.4 * 200).round();
      expect(sheet.getPixel(left + 5, backTop - 8).r, greaterThan(240));
      expect(sheet.getPixel(left + 5, backTop + 8).r, lessThan(80));
    });
  });

  group('PDF writer', () {
    test('reads JPEG headers', () {
      final jpeg = img.encodeJpg(img.Image(width: 31, height: 17));
      final info = readJpegInfo(Uint8List.fromList(jpeg));
      expect(info.width, 31);
      expect(info.height, 17);
      expect(info.components, 3);
      expect(
        () => readJpegInfo(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(anything),
      );
    });

    test('single pages fit inside A4; Fit follows the image', () {
      final a4 = planSinglePage(
        path: 'x',
        pixelWidth: 1000,
        pixelHeight: 2000,
        size: ScanPageSize.a4,
      );
      expect(a4.width, closeTo(595.28, 0.01));
      final placed = a4.images.single;
      expect(placed.height, closeTo(841.89, 0.01));
      expect(placed.x, greaterThan(0));
      final fit = planSinglePage(
        path: 'x',
        pixelWidth: 1000,
        pixelHeight: 500,
        size: ScanPageSize.fit,
      );
      expect(fit.height, closeTo(fit.width / 2, 0.01));
    });

    test('ID card page is exactly 85.6 x 54 mm per side', () {
      final page = planIdCardPage(
        cards: [
          (path: 'f', width: 856, height: 540, ocr: null),
          (path: 'b', width: 540, height: 856, ocr: null),
        ],
        size: ScanPageSize.fit,
      );
      expect(page.width, closeTo(595.28, 0.01));
      expect(page.images[0].width, closeTo(85.6 * 72 / 25.4, 0.01));
      expect(page.images[0].height, closeTo(54 * 72 / 25.4, 0.01));
      // A portrait image is placed portrait.
      expect(page.images[1].width, closeTo(54 * 72 / 25.4, 0.01));
      expect(
        page.images[0].x + page.images[0].width / 2,
        closeTo(page.width / 2, 0.01),
      );
      // Front 40 mm from the top; back 20 mm below the front's 54 mm.
      expect(page.images[0].y, closeTo(40 * 72 / 25.4, 0.01));
      expect(page.images[1].y, closeTo(114 * 72 / 25.4, 0.01));
    });

    test('writes a valid PDF with an invisible text layer', () {
      final im = img.Image(width: 600, height: 800);
      img.fill(im, color: img.ColorRgb8(255, 255, 255));
      final gray = img.grayscale(img.Image.from(im)).convert(numChannels: 1);
      final a = write(im, 'a.jpg');
      final b = p.join(tmp.path, 'b.jpg');
      File(b).writeAsBytesSync(img.encodeJpg(gray));
      const ocr = OcrPage(600, 800, [
        OcrLine('Invoice (No. 42) café €5', 60, 100, 400, 30),
        OcrLine('Total due', 60, 200, 200, 30),
      ]);
      final out = p.join(tmp.path, 'scan.pdf');
      final bytes = writeScanPdf(
        ScanPdfRequest(
          output: out,
          title: 'Scan 2026-11-13 14.32 ü',
          pages: [
            planSinglePage(
              path: a,
              pixelWidth: 600,
              pixelHeight: 800,
              size: ScanPageSize.a4,
              ocr: ocr.encode(),
            ),
            planSinglePage(
              path: b,
              pixelWidth: 600,
              pixelHeight: 800,
              size: ScanPageSize.letter,
            ),
          ],
        ),
      );
      final data = File(out).readAsBytesSync();
      expect(bytes, data.length);
      final text = String.fromCharCodes(data);
      expect(text, startsWith('%PDF-1.7'));
      expect(text, contains('/Count 2'));
      expect(text, contains('3 Tr'));
      expect(text, contains(r'(Invoice \(No. 42\) caf'));
      expect(text, contains('/DeviceRGB'));
      expect(text.trimRight(), endsWith('%%EOF'));
      // Every xref offset points at its object.
      final xrefAt = int.parse(
        RegExp(r'startxref\n(\d+)').firstMatch(text)!.group(1)!,
      );
      final rows = RegExp(
        r'(\d{10}) 00000 n ',
      ).allMatches(text.substring(xrefAt)).toList();
      for (var i = 0; i < rows.length; i++) {
        final offset = int.parse(rows[i].group(1)!);
        expect(
          text.substring(offset, offset + 12),
          startsWith('${i + 1} 0 obj'),
        );
      }
      expect(File('$out.part').existsSync(), isFalse);
    });

    test('helvetica widths', () {
      expect(helveticaWidth('i'), closeTo(0.222, 0.001));
      expect(helveticaWidth('WW'), closeTo(1.888, 0.001));
    });
  });

  test('size estimate follows the real page size and crop', () {
    ScanSession session(List<Quad> quads) => ScanSession(
      id: 1,
      title: 't',
      mode: ScanMode.document,
      updatedAt: DateTime(2026),
      pages: [
        for (var i = 0; i < quads.length; i++)
          ScanPage(
            id: i,
            position: i,
            originalPath: '',
            geometry: PageGeometry(quad: quads[i]),
          ),
      ],
    );
    final full = session([Quad.full, Quad.full]);
    // ML Kit pages are about 1220 x 1730; ten of them came to 2.3 MB.
    final dims = [(1220, 1730), (1220, 1730)];
    final balanced = ScanService.estimateBytes(
      full,
      ScanQuality.balanced,
      dims,
    );
    expect(balanced, closeTo(2 * 232000, 30000));
    // Small caps the long edge at 1600 px and compresses harder.
    expect(
      ScanService.estimateBytes(full, ScanQuality.small, dims),
      lessThan(balanced),
    );
    const half = Quad(
      NPoint(0, 0),
      NPoint(1, 0),
      NPoint(1, 0.5),
      NPoint(0, 0.5),
    );
    expect(
      ScanService.estimateBytes(
        session([half, half]),
        ScanQuality.balanced,
        dims,
      ),
      lessThan(balanced * 0.6),
    );
  });

  group('drafts', () {
    late AppDatabase db;
    late ScanRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ScanRepository(db);
    });
    tearDown(() => db.close());

    test('pages keep their order, edits and survive reloading', () async {
      final id = await repo.createSession(mode: ScanMode.book, title: 'Scan');
      final a = await repo.addPage(id, '/a.jpg');
      final b = await repo.addPage(
        id,
        '/b.jpg',
        geometry: const PageGeometry(split: 0.52),
      );
      var s = (await repo.load(id))!;
      expect(s.mode, ScanMode.book);
      expect(s.pages.map((p) => p.id), [a, b]);
      expect(s.pages.last.geometry.split, 0.52);

      await repo.reorder(id, [b, a]);
      await repo.updatePage(
        s.pages.first,
        rotation: 90,
        filter: ScanFilter.grayscale,
        processedPath: '/p.jpg',
      );
      s = (await repo.load(id))!;
      expect(s.pages.map((p) => p.id), [b, a]);
      final edited = s.pages.firstWhere((p) => p.id == a);
      expect(edited.rotation, 90);
      expect(edited.filter, ScanFilter.grayscale);
      expect(edited.processedPath, '/p.jpg');

      await repo.updateSettings(
        id,
        quality: ScanQuality.best,
        ocr: true,
        title: 'Notes',
      );
      s = (await repo.load(id))!;
      expect(s.quality, ScanQuality.best);
      expect(s.ocrEnabled, isTrue);
      expect(s.title, 'Notes');

      final drafts = await repo.watchDrafts().first;
      expect(drafts.single.pages, hasLength(2));

      await repo.deletePage(edited);
      expect((await repo.load(id))!.pages, hasLength(1));
      await repo.deleteSession(id);
      expect(await repo.load(id), isNull);
      final orphans = await db.select(db.scanPages).get();
      expect(orphans, isEmpty, reason: 'pages cascade with the session');
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/engines/pdf/pdfium_editor.dart';
import 'package:docnook/engines/pdf/security/pdf_encryptor.dart';
import 'package:docnook/engines/scan/scan_pdf_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

/// Runs the real PDFium edits on the desktop. Needs the PDFium library a
/// Windows build leaves in build/native_assets (skipped without it).
void main() {
  final dll = File(p.absolute('build/native_assets/windows/pdfium.dll'));
  final skip = Platform.isWindows && dll.existsSync()
      ? false
      : 'needs a desktop PDFium build';
  late Directory dir;

  setUpAll(() async {
    if (skip != false) return;
    Pdfrx.pdfiumModulePath = dll.path;
    PdfiumEditor.modulePath = dll.path;
    await PdfrxEntryFunctions.instance.init();
  });

  setUp(() => dir = Directory.systemTemp.createTempSync('docnook_edit'));
  tearDown(() => dir.deleteSync(recursive: true));

  String path(String name) => p.join(dir.path, name);

  Future<String> blankPdf(String name, int pages) async {
    final out = path(name);
    await PdfiumEditor.assemble(
      sources: const [],
      pages: [
        for (var i = 0; i < pages; i++)
          const PageSpec.blank(width: 595, height: 842),
      ],
      output: out,
    );
    return out;
  }

  Future<String> pageText(String file, int page, {String? password}) async {
    final doc = await PdfDocument.openFile(
      file,
      passwordProvider: password == null ? null : () => password,
    );
    try {
      final text = await doc.pages[page].loadText();
      return text?.fullText ?? '';
    } finally {
      await doc.dispose();
    }
  }

  test('blank pages, page numbers and a merge', () async {
    final base = await blankPdf('base.pdf', 3);
    final numbered = path('numbered.pdf');
    await PdfiumEditor.stamp(
      source: PdfSource(base),
      stamp: const StampSpec.text(
        'Page {n} of {total}',
        fontSize: 11,
        position: StampPosition.bottomCenter,
      ),
      output: numbered,
    );
    expect(await pageText(numbered, 1), contains('Page 2 of 3'));

    final merged = path('merged.pdf');
    final progress = <double>[];
    await PdfiumEditor.assemble(
      sources: [PdfSource(numbered), PdfSource(base)],
      pages: const [
        PageSpec.page(0, 2),
        PageSpec.page(1, 0, quarterTurns: 1),
        PageSpec.blank(width: 300, height: 400),
        PageSpec.page(0, 0),
      ],
      output: merged,
      control: EditControl(onProgress: (v, {page, of}) => progress.add(v)),
    );
    final info = await PdfiumEditor.inspect(PdfSource(merged));
    expect(info.pageCount, 4);
    expect(info.pages[1].rotation, 1);
    expect(info.pages[2].width, closeTo(300, 0.5));
    expect(await pageText(merged, 0), contains('Page 3 of 3'));
    expect(await pageText(merged, 3), contains('Page 1 of 3'));
    expect(progress.last, 1);
  }, skip: skip);

  test(
    'watermark on a rotated page reads upright and is see-through',
    () async {
      final base = await blankPdf('base.pdf', 1);
      final turned = path('turned.pdf');
      await PdfiumEditor.assemble(
        sources: [PdfSource(base)],
        pages: const [PageSpec.page(0, 0, quarterTurns: 1)],
        output: turned,
      );
      final out = path('wm.pdf');
      await PdfiumEditor.stamp(
        source: PdfSource(turned),
        stamp: const StampSpec.text('CONFIDENTIAL', opacity: 0.3, angle: 45),
        output: out,
      );
      final bytes = File(out).readAsBytesSync();
      expect(latin1.decode(bytes), contains(RegExp(r'/ca \.3')));
      expect(await pageText(out, 0), contains('CONFIDENTIAL'));
    },
    skip: skip,
  );

  test('image stamp stores the picture once for every page', () async {
    final base = await blankPdf('base.pdf', 5);
    final out = path('img.pdf');
    final bgra = Uint8List(64 * 32 * 4);
    for (var i = 0; i < bgra.length; i += 4) {
      bgra[i + 2] = (i * 7) & 0xFF;
      bgra[i + 3] = 255;
    }
    await PdfiumEditor.stamp(
      source: PdfSource(base),
      stamp: StampSpec.image(
        bgra,
        imageWidth: 64,
        imageHeight: 32,
        imageWidthPt: 200,
        opacity: 0.5,
      ),
      output: out,
    );
    final text = latin1.decode(File(out).readAsBytesSync());
    // One picture plus its transparency mask, not one per page.
    expect(RegExp(r'/Subtype\s*/Image').allMatches(text).length, 2);
    expect(
      RegExp(r'/Subtype\s*/Form').allMatches(text).length,
      greaterThanOrEqualTo(1),
    );
  }, skip: skip);

  test('annotations are written with appearance streams', () async {
    final base = await blankPdf('base.pdf', 2);
    final out = path('annot.pdf');
    await PdfiumEditor.annotate(
      source: PdfSource(base),
      marks: const [
        TextMarkup(0, 0xFFE066, MarkupKind.highlight, [
          100, 700, 300, 700, 100, 680, 300, 680, //
        ]),
        InkMark(1, 0x1A3A8F, [
          [100, 100, 150, 140, 200, 110],
        ], 2),
        NoteMark(1, 0xF2B807, 400, 500, 'Check this'),
      ],
      output: out,
    );
    final text = latin1.decode(File(out).readAsBytesSync());
    expect(text, contains('/Highlight'));
    expect(text, contains('/Ink'));
    expect(
      RegExp(r'/AP\s*<<').allMatches(text).length,
      greaterThanOrEqualTo(2),
    );
  }, skip: skip);

  test('protect then unlock round trip', () async {
    final base = await blankPdf('base.pdf', 1);
    final numbered = path('n.pdf');
    await PdfiumEditor.stamp(
      source: PdfSource(base),
      stamp: const StampSpec.text('Secret page'),
      output: numbered,
    );
    final locked = path('locked.pdf');
    File(locked).writeAsBytesSync(
      PdfEncryptor.encrypt(
        File(numbered).readAsBytesSync(),
        userPassword: 'open sesame',
      ),
    );
    await expectLater(
      PdfiumEditor.inspect(PdfSource(locked)),
      throwsA(const DocNookFailure.passwordRequired()),
    );
    await expectLater(
      PdfiumEditor.inspect(PdfSource(locked, password: 'nope')),
      throwsA(const DocNookFailure.wrongPassword()),
    );
    final info = await PdfiumEditor.inspect(
      PdfSource(locked, password: 'open sesame'),
    );
    expect(info.encrypted, isTrue);

    final open = path('open.pdf');
    await PdfiumEditor.resave(
      source: PdfSource(locked, password: 'open sesame'),
      output: open,
      removeSecurity: true,
    );
    final opened = await PdfiumEditor.inspect(PdfSource(open));
    expect(opened.encrypted, isFalse);
    expect(await pageText(open, 0), contains('Secret page'));
  }, skip: skip);

  test('form fields are read, filled and flattened', () async {
    final form = path('form.pdf');
    File(form).writeAsBytesSync(_formPdf());
    final fields = await PdfiumEditor.readForm(PdfSource(form));
    expect(fields.map((f) => f.kind), [
      FormFieldKind.text,
      FormFieldKind.checkbox,
    ]);
    expect(fields.first.name, 'name');

    final filled = path('filled.pdf');
    await PdfiumEditor.fillForm(
      source: PdfSource(form),
      values: [
        FormFieldValue.text(0, fields[0].annotIndex, 'Ada Lovelace'),
        FormFieldValue.checked(0, fields[1].annotIndex, true),
      ],
      flatten: false,
      output: filled,
    );
    final after = await PdfiumEditor.readForm(PdfSource(filled));
    expect(after[0].value, 'Ada Lovelace');
    expect(after[1].checked, isTrue);

    final flat = path('flat.pdf');
    await PdfiumEditor.fillForm(
      source: PdfSource(filled),
      values: const [],
      flatten: true,
      output: flat,
    );
    expect(await PdfiumEditor.readForm(PdfSource(flat)), isEmpty);
    expect(await pageText(flat, 0), contains('Ada Lovelace'));
  }, skip: skip);

  test('balanced compression shrinks a large photo, keeps text', () async {
    final photo = img.Image(width: 2400, height: 3200);
    for (var y = 0; y < photo.height; y++) {
      for (var x = 0; x < photo.width; x++) {
        photo.setPixelRgb(
          x,
          y,
          (x * 3 + y) & 0xFF,
          (x ^ y) & 0xFF,
          (y * 5) & 0xFF,
        );
      }
    }
    final jpg = path('photo.jpg');
    File(jpg).writeAsBytesSync(img.encodeJpg(photo, quality: 95));
    final scan = path('scan.pdf');
    writeScanPdf(
      ScanPdfRequest(
        output: scan,
        pages: [
          PdfPagePlan(595, 793, [
            PlacedImage(path: jpg, x: 0, y: 0, width: 595, height: 793),
          ]),
        ],
      ),
    );
    final labelled = path('labelled.pdf');
    await PdfiumEditor.stamp(
      source: PdfSource(scan),
      stamp: const StampSpec.text('Invoice 42', fontSize: 14),
      output: labelled,
    );
    final out = path('small.pdf');
    final stats = await PdfiumEditor.recompressImages(
      source: PdfSource(labelled),
      output: out,
      maxEdge: 1200,
    );
    expect(stats.imagesRecompressed, 1);
    expect(File(out).lengthSync(), lessThan(File(labelled).lengthSync() ~/ 2));
    expect(await pageText(out, 0), contains('Invoice 42'));
  }, skip: skip);

  test('cancelling stops an edit with no output', () async {
    final base = await blankPdf('base.pdf', 40);
    final out = path('cancel.pdf');
    var calls = 0;
    await expectLater(
      PdfiumEditor.stamp(
        source: PdfSource(base),
        stamp: const StampSpec.text('{n}'),
        output: out,
        control: EditControl(isCancelled: () => ++calls > 1),
      ),
      throwsA(const DocNookFailure.cancelled()),
    );
    expect(File(out).existsSync(), isFalse);
  }, skip: skip);

  test('page ranges', () {
    expect(parsePageRanges('1-3, 5, 8-', 9), [0, 1, 2, 4, 7, 8]);
    expect(parsePageRanges('0', 3), isNull);
    expect(parsePageRanges('2-1', 3), isNull);
    expect(parsePageRanges('4', 3), isNull);
    expect(parsePageRanges('a', 3), isNull);
    expect(splitEvery(5, 2), [
      [0, 1],
      [2, 3],
      [4],
    ]);
    expect(parseRangeGroups('1-2, 3', 3), [
      [0, 1],
      [2],
    ]);
  });
}

/// A one-page AcroForm with a text field and a checkbox.
Uint8List _formPdf() {
  final bodies = [
    '<< /Type /Catalog /Pages 2 0 R /AcroForm << /Fields [4 0 R 5 0 R] '
        '/DA (/Helv 0 Tf 0 g) /DR << /Font << /Helv 8 0 R >> >> >> >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
        '/Annots [4 0 R 5 0 R] >>',
    '<< /Type /Annot /Subtype /Widget /FT /Tx /T (name) /V () '
        '/Rect [100 700 400 724] /F 4 /DA (/Helv 12 Tf 0 g) /P 3 0 R >>',
    '<< /Type /Annot /Subtype /Widget /FT /Btn /T (agree) /V /Off /AS /Off '
        '/Rect [100 650 118 668] /F 4 /P 3 0 R '
        '/MK << /CA (4) >> /DA (/ZaDb 0 Tf 0 g) '
        '/AP << /N << /Yes 6 0 R /Off 7 0 R >> >> >>',
    '<< /Length 0 /Subtype /Form /BBox [0 0 18 18] >>\nstream\n\nendstream',
    '<< /Length 0 /Subtype /Form /BBox [0 0 18 18] >>\nstream\n\nendstream',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
        '/Encoding /WinAnsiEncoding >>',
  ];
  final out = BytesBuilder()..add(latin1.encode('%PDF-1.7\n'));
  final offsets = <int>[];
  for (var i = 0; i < bodies.length; i++) {
    offsets.add(out.length);
    out.add(latin1.encode('${i + 1} 0 obj\n${bodies[i]}\nendobj\n'));
  }
  final xref = out.length;
  final table = StringBuffer(
    'xref\n0 ${bodies.length + 1}\n0000000000 65535 f \n',
  );
  for (final o in offsets) {
    table.write('${o.toString().padLeft(10, '0')} 00000 n \n');
  }
  out.add(
    latin1.encode(
      '${table}trailer\n<< /Size ${bodies.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xref\n%%EOF\n',
    ),
  );
  return out.toBytes();
}

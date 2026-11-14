import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/office/parse_document.dart';
import 'package:docnook/engines/pdf/raster.dart';
import 'package:docnook/engines/scan/scan_image.dart';
import 'package:docnook/engines/text/text_file.dart';
import 'package:docnook/features/viewer/archive/archive_screen.dart';
import 'package:docnook/features/viewer/epub/epub_reader_screen.dart';
import 'package:docnook/features/viewer/sheet/sheet_viewer_screen.dart';
import 'package:docnook/features/viewer/slides/slides_viewer_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Malformed-file corpus run (BLUEPRINT 11, Phase 9; 12.2 "Hostile").
///
/// Every broken, hostile or renamed file is fed to the same job body the
/// viewer uses, in its own isolate as JobRunner does. A case passes when the
/// parser either succeeds or fails with a [DocNookFailure] the S32 screen can
/// explain, within the time limit. A hang, an out-of-memory or an error that
/// is not a recognised failure fails the run.
JobContext get ctx => JobContext.detached();

void main() {
  late Directory dir;
  final random = Random(7);

  setUpAll(() => dir = Directory.systemTemp.createTempSync('docnook_corpus'));
  tearDownAll(() => dir.deleteSync(recursive: true));

  String write(String name, List<int> bytes) {
    final path = p.join(dir.path, name);
    File(path).writeAsBytesSync(bytes);
    return path;
  }

  Uint8List noise(int n) =>
      Uint8List.fromList([for (var i = 0; i < n; i++) random.nextInt(256)]);

  Uint8List fixture(String name) =>
      File('test/fixtures/office/$name').readAsBytesSync();

  Uint8List truncated(Uint8List bytes) =>
      Uint8List.sublistView(bytes, 0, bytes.length * 2 ~/ 5);

  /// Rewrites every XML part of a ZIP-based fixture with [xml].
  Uint8List withXml(Uint8List zipBytes, String xml) {
    final source = ZipDecoder().decodeBytes(zipBytes);
    final out = Archive();
    for (final f in source.files) {
      final data = f.name.endsWith('.xml') || f.name.endsWith('.rels')
          ? Uint8List.fromList(xml.codeUnits)
          : f.content;
      out.addFile(ArchiveFile.bytes(f.name, data));
    }
    return ZipEncoder().encodeBytes(out);
  }

  /// A small ZIP whose directory claims a 3 GB entry (a bomb's signature).
  Uint8List fakeHugeZip(Uint8List zipBytes) {
    final bytes = Uint8List.fromList(zipBytes);
    final data = ByteData.sublistView(bytes);
    // Patch uncompressed sizes in every central directory header.
    for (var i = 0; i + 46 < bytes.length; i++) {
      if (data.getUint32(i, Endian.little) == 0x02014b50) {
        data.setUint32(i + 24, 0xC0000000, Endian.little);
      }
    }
    return bytes;
  }

  const billionLaughs = '''
<?xml version="1.0"?>
<!DOCTYPE lolz [<!ENTITY lol "lol"><!ENTITY lol2 "&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;"><!ENTITY lol3 "&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;">]>
<root>&lol3;</root>''';

  /// A PNG header claiming [w] × [h] pixels with a tiny body.
  Uint8List pngHeader(int w, int h) {
    int crc(List<int> d) => getCrc32(d);
    List<int> chunk(String type, List<int> body) {
      final t = type.codeUnits;
      final len = ByteData(4)..setUint32(0, body.length);
      final c = ByteData(4)..setUint32(0, crc([...t, ...body]));
      return [
        ...len.buffer.asUint8List(),
        ...t,
        ...body,
        ...c.buffer.asUint8List(),
      ];
    }

    final ihdr = ByteData(13)
      ..setUint32(0, w)
      ..setUint32(4, h)
      ..setUint8(8, 8)
      ..setUint8(9, 6);
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
      ...chunk('IHDR', ihdr.buffer.asUint8List()),
      ...chunk('IDAT', const ZLibEncoder().encodeBytes(List.filled(64, 0))),
      ...chunk('IEND', const []),
    ]);
  }

  const olePrefix = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];
  final pk = [0x50, 0x4B, 0x03, 0x04];

  /// Runs one case in a fresh isolate; returns a short outcome label.
  Future<String> run(Object? Function() body) async {
    try {
      await Isolate.run(body).timeout(const Duration(seconds: 30));
      return 'ok';
    } on TimeoutException {
      return 'HANG';
    } on Object catch (error) {
      final failure = DocNookFailure.from(error);
      return failure.kind == FailureKind.unknown
          ? 'UNEXPECTED ${error.runtimeType}'
          : failure.code;
    }
  }

  // name -> (file to write, how to open it)
  final cases = <String, (List<int> Function(), Object? Function(String))>{};

  void docCase(String label, String ext, DocFormat f, List<int> Function() b) {
    cases['$label.$ext'] = (
      b,
      (path) => parseToDocModel(ParseRequest(path, f), ctx),
    );
  }

  void sheetCase(
    String label,
    String ext,
    DocFormat f,
    List<int> Function() b,
  ) {
    cases['$label.$ext'] = (
      b,
      (path) => parseToWorkbook(SheetRequest(path, f), ctx),
    );
  }

  // ------------------------------------------------------------ generic
  final docFormats = {
    'docx': DocFormat.docx,
    'odt': DocFormat.odt,
    'rtf': DocFormat.rtf,
    'doc': DocFormat.doc,
    'ppt': DocFormat.ppt,
    'xls': DocFormat.xls,
    'md': DocFormat.markdown,
    'epub': DocFormat.epub,
  };
  for (final MapEntry(key: ext, value: f) in docFormats.entries) {
    docCase('empty', ext, f, () => const []);
    docCase('noise', ext, f, () => noise(4096));
  }
  final sheetFormats = {
    'xlsx': DocFormat.xlsx,
    'ods': DocFormat.ods,
    'csv': DocFormat.csv,
    'tsv': DocFormat.tsv,
  };
  for (final MapEntry(key: ext, value: f) in sheetFormats.entries) {
    sheetCase('empty', ext, f, () => const []);
    sheetCase('noise', ext, f, () => noise(4096));
  }

  // -------------------------------------------------- truncated fixtures
  docCase(
    'truncated',
    'docx',
    DocFormat.docx,
    () => truncated(File('test/fixtures/handbook_30p.docx').readAsBytesSync()),
  );
  docCase(
    'truncated',
    'odt',
    DocFormat.odt,
    () => truncated(fixture('minutes.odt')),
  );
  docCase(
    'truncated',
    'rtf',
    DocFormat.rtf,
    () => truncated(fixture('letter.rtf')),
  );
  docCase(
    'truncated',
    'epub',
    DocFormat.epub,
    () => truncated(fixture('story.epub')),
  );
  sheetCase(
    'truncated',
    'xlsx',
    DocFormat.xlsx,
    () => truncated(fixture('budget.xlsx')),
  );
  sheetCase(
    'truncated',
    'ods',
    DocFormat.ods,
    () => truncated(fixture('stock.ods')),
  );
  docCase(
    'truncated',
    'xls',
    DocFormat.xls,
    () => truncated(fixture('legacy.xls')),
  );

  // ------------------------------------------- right magic, broken body
  docCase('pk_noise', 'docx', DocFormat.docx, () => [...pk, ...noise(2048)]);
  sheetCase('pk_noise', 'xlsx', DocFormat.xlsx, () => [...pk, ...noise(2048)]);
  docCase(
    'ole_noise',
    'doc',
    DocFormat.doc,
    () => [...olePrefix, ...noise(4096)],
  );
  docCase(
    'ole_noise',
    'ppt',
    DocFormat.ppt,
    () => [...olePrefix, ...noise(4096)],
  );
  docCase(
    'ole_noise',
    'xls',
    DocFormat.xls,
    () => [...olePrefix, ...noise(4096)],
  );
  docCase(
    'deep_groups',
    'rtf',
    DocFormat.rtf,
    () => r'{\rtf1 '.codeUnits + List.filled(200000, 0x7B),
  );
  docCase(
    'deep_quotes',
    'md',
    DocFormat.markdown,
    () => '${'> ' * 5000}hello\n'.codeUnits,
  );
  docCase(
    'deep_lists',
    'md',
    DocFormat.markdown,
    () => [for (var i = 0; i < 3000; i++) ...'${'  ' * i}- item\n'.codeUnits],
  );

  // ---------------------------------------------- broken XML inside ZIPs
  for (final (label, xml) in [
    ('bad_xml', '<w:document><w:body><w:p'),
    ('doctype', billionLaughs),
  ]) {
    docCase(
      label,
      'docx',
      DocFormat.docx,
      () => withXml(
        File('test/fixtures/handbook_30p.docx').readAsBytesSync(),
        xml,
      ),
    );
    docCase(
      label,
      'odt',
      DocFormat.odt,
      () => withXml(fixture('minutes.odt'), xml),
    );
    docCase(
      label,
      'epub',
      DocFormat.epub,
      () => withXml(fixture('story.epub'), xml),
    );
    sheetCase(
      label,
      'xlsx',
      DocFormat.xlsx,
      () => withXml(fixture('budget.xlsx'), xml),
    );
    sheetCase(
      label,
      'ods',
      DocFormat.ods,
      () => withXml(fixture('stock.ods'), xml),
    );
    cases['$label.pptx'] = (
      () => withXml(fixture('deck.pptx'), xml),
      (path) => parsePptx(path, ctx),
    );
  }

  // ------------------------------------------------- bombs and renames
  docCase(
    'bomb',
    'docx',
    DocFormat.docx,
    () =>
        fakeHugeZip(File('test/fixtures/handbook_30p.docx').readAsBytesSync()),
  );
  sheetCase(
    'bomb',
    'xlsx',
    DocFormat.xlsx,
    () => fakeHugeZip(fixture('budget.xlsx')),
  );
  cases['bomb.zip'] = (
    () => fakeHugeZip(fixture('bundle.zip')),
    (path) => listArchive(path, ctx),
  );
  // A Word file saved with a spreadsheet's name and the other way round.
  sheetCase(
    'renamed_docx',
    'xlsx',
    DocFormat.xlsx,
    () => File('test/fixtures/handbook_30p.docx').readAsBytesSync(),
  );
  docCase('renamed_xlsx', 'docx', DocFormat.docx, () => fixture('budget.xlsx'));
  cases['renamed_xlsx.pptx'] = (
    () => fixture('budget.xlsx'),
    (path) => parsePptx(path, ctx),
  );
  cases['renamed_zip.epub'] = (
    () => fixture('bundle.zip'),
    (path) => parseEpub(path, ctx),
  );
  for (final label in ['empty', 'noise']) {
    cases['$label.pptx'] = (
      () => label == 'empty' ? const <int>[] : noise(4096),
      (path) => parsePptx(path, ctx),
    );
    cases['$label.zip'] = (
      () => label == 'empty' ? const <int>[] : noise(4096),
      (path) => listArchive(path, ctx),
    );
  }

  // ---------------------------------------------------------- text files
  cases['noise.txt'] = (() => noise(65536), (path) => indexLines(path, ctx));
  cases['empty.txt'] = (() => const [], (path) => indexLines(path, ctx));
  cases['one_long_line.log'] = (
    () => List.filled(8 * 1024 * 1024, 0x61),
    (path) => indexLines(path, ctx),
  );

  // -------------------------------------------------------------- images
  cases['huge.png'] = (
    () => pngHeader(20000, 20000),
    (path) => prepareImageMax((path, '$path.jpg', 80, 2000), ctx),
  );
  cases['huge_scan.png'] = (() => pngHeader(20000, 20000), loadUpright);
  cases['huge_sign.png'] = (
    () => pngHeader(20000, 20000),
    (path) => decodeBgra((path, 800), ctx),
  );
  cases['noise.jpg'] = (
    () => [0xFF, 0xD8, 0xFF, ...noise(4096)],
    (path) => prepareImageMax((path, '$path.out.jpg', 80, 2000), ctx),
  );

  for (final MapEntry(key: name, value: (bytes, open)) in cases.entries) {
    test('corpus: $name', () async {
      final path = write(name, bytes());
      final outcome = await run(() => open(path));
      expect(
        outcome,
        isNot(anyOf(startsWith('HANG'), startsWith('UNEXPECTED'))),
        reason: '$name -> $outcome',
      );
    });
  }

  test('zip-slip entries are never written outside the folder', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.bytes('../../escape.txt', 'x'.codeUnits))
      ..addFile(ArchiveFile.bytes('ok/inside.txt', 'y'.codeUnits));
    final zipPath = write('slip.zip', ZipEncoder().encodeBytes(archive));
    final dest = Directory(p.join(dir.path, 'out', 'deep'))
      ..createSync(recursive: true);
    final outcome = await run(
      () => extractEntries(
        ExtractRequest(zipPath, const [
          '../../escape.txt',
          'ok/inside.txt',
        ], dest.path),
        JobContext.detached(),
      ),
    );
    expect(outcome, isNot(startsWith('UNEXPECTED')));
    expect(File(p.join(dir.path, 'escape.txt')).existsSync(), isFalse);
    expect(File(p.join(dir.path, 'out', 'escape.txt')).existsSync(), isFalse);
  });
}

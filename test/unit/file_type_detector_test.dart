import 'dart:convert';
import 'dart:typed_data';

import 'package:docnook/data/files/file_type_detector.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a minimal ZIP with stored (uncompressed) entries, in order.
Uint8List buildZip(Map<String, String> entries) {
  final out = BytesBuilder();
  final central = BytesBuilder();
  var count = 0;
  entries.forEach((name, content) {
    final nameBytes = utf8.encode(name);
    final data = utf8.encode(content);
    final offset = out.length;
    final local = ByteData(30)
      ..setUint32(0, 0x04034B50, Endian.little)
      ..setUint16(4, 20, Endian.little)
      ..setUint32(18, data.length, Endian.little)
      ..setUint32(22, data.length, Endian.little)
      ..setUint16(26, nameBytes.length, Endian.little);
    out
      ..add(local.buffer.asUint8List())
      ..add(nameBytes)
      ..add(data);
    final header = ByteData(46)
      ..setUint32(0, 0x02014B50, Endian.little)
      ..setUint16(4, 20, Endian.little)
      ..setUint16(6, 20, Endian.little)
      ..setUint32(20, data.length, Endian.little)
      ..setUint32(24, data.length, Endian.little)
      ..setUint16(28, nameBytes.length, Endian.little)
      ..setUint32(42, offset, Endian.little);
    central
      ..add(header.buffer.asUint8List())
      ..add(nameBytes);
    count++;
  });
  final dirOffset = out.length;
  final dir = central.toBytes();
  final end = ByteData(22)
    ..setUint32(0, 0x06054B50, Endian.little)
    ..setUint16(8, count, Endian.little)
    ..setUint16(10, count, Endian.little)
    ..setUint32(12, dir.length, Endian.little)
    ..setUint32(16, dirOffset, Endian.little);
  out
    ..add(dir)
    ..add(end.buffer.asUint8List());
  return out.toBytes();
}

/// Builds a minimal OLE compound file whose directory names one stream.
Uint8List buildOle(String streamName) {
  final bytes = Uint8List(512 * 3);
  final view = ByteData.sublistView(bytes);
  bytes.setAll(0, const [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1]);
  view
    ..setUint16(30, 9, Endian.little) // 512-byte sectors
    ..setUint32(48, 1, Endian.little); // directory in sector 1
  void entry(int index, String name) {
    final base = 512 * 2 + index * 128;
    for (var i = 0; i < name.length; i++) {
      view.setUint16(base + i * 2, name.codeUnitAt(i), Endian.little);
    }
    view.setUint16(base + 64, (name.length + 1) * 2, Endian.little);
  }

  entry(0, 'Root Entry');
  entry(1, streamName);
  return bytes;
}

DocFormat detect(List<int> bytes, {String? name, String? mime}) =>
    FileTypeDetector.detect(
      MemoryByteSource(Uint8List.fromList(bytes)),
      name: name,
      mimeHint: mime,
    );

void main() {
  group('magic bytes win over names', () {
    test('PDF renamed to .txt is still a PDF', () {
      expect(detect(ascii.encode('%PDF-1.7\n...'), name: 'notes.txt'), DocFormat.pdf);
    });

    test('PDF with no extension and octet-stream MIME', () {
      expect(
        detect(
          ascii.encode('%PDF-1.4\n'),
          name: 'DOC-20261111-WA0004',
          mime: 'application/octet-stream',
        ),
        DocFormat.pdf,
      );
    });

    test('PDF marker after leading junk', () {
      expect(detect([0, 0, 10, ...ascii.encode('%PDF-1.5')]), DocFormat.pdf);
    });

    test('images', () {
      expect(detect([0xFF, 0xD8, 0xFF, 0xE0, 0, 0], name: 'a.pdf'), DocFormat.jpeg);
      expect(
        detect([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0]),
        DocFormat.png,
      );
      expect(detect(ascii.encode('GIF89a....')), DocFormat.gif);
      expect(detect(ascii.encode('RIFF\x10\x00\x00\x00WEBPVP8 ')), DocFormat.webp);
      expect(
        detect([0, 0, 0, 0x18, ...ascii.encode('ftypheic'), 0, 0, 0, 0]),
        DocFormat.heic,
      );
    });

    test('RTF', () {
      expect(detect(ascii.encode(r'{\rtf1\ansi Hello}'), name: 'x.doc'), DocFormat.rtf);
    });
  });

  group('ZIP containers', () {
    test('DOCX, XLSX and PPTX by content, whatever the name', () {
      final docx = buildZip({'[Content_Types].xml': '<Types/>', 'word/document.xml': '<w/>'});
      final xlsx = buildZip({'[Content_Types].xml': '<Types/>', 'xl/workbook.xml': '<w/>'});
      final pptx = buildZip({'[Content_Types].xml': '<Types/>', 'ppt/presentation.xml': '<p/>'});
      expect(detect(docx, name: 'report.zip'), DocFormat.docx);
      expect(detect(xlsx, name: 'budget'), DocFormat.xlsx);
      expect(detect(pptx, name: 'slides.docx'), DocFormat.pptx);
    });

    test('template and macro variants keep their extension meaning', () {
      final docx = buildZip({'[Content_Types].xml': '<Types/>', 'word/document.xml': '<w/>'});
      final xlsx = buildZip({'[Content_Types].xml': '<Types/>', 'xl/workbook.xml': '<w/>'});
      expect(detect(docx, name: 'letter.dotx'), DocFormat.dotx);
      expect(detect(xlsx, name: 'macro.xlsm'), DocFormat.xlsm);
    });

    test('ODT, ODS and EPUB by mimetype entry', () {
      final odt = buildZip({'mimetype': 'application/vnd.oasis.opendocument.text', 'content.xml': '<x/>'});
      final ods = buildZip({'mimetype': 'application/vnd.oasis.opendocument.spreadsheet', 'content.xml': '<x/>'});
      final epub = buildZip({'mimetype': 'application/epub+zip', 'META-INF/container.xml': '<x/>'});
      expect(detect(odt, name: 'a.zip'), DocFormat.odt);
      expect(detect(ods), DocFormat.ods);
      expect(detect(epub, name: 'book.zip'), DocFormat.epub);
    });

    test('plain ZIP stays an archive even when named .docx', () {
      final zip = buildZip({'readme.txt': 'hello', 'photos/a.jpg': 'x'});
      expect(detect(zip, name: 'fake.docx'), DocFormat.zip);
    });
  });

  group('legacy Office containers', () {
    test('stream names decide the application', () {
      expect(detect(buildOle('WordDocument'), name: 'x.xls'), DocFormat.doc);
      expect(detect(buildOle('Workbook')), DocFormat.xls);
      expect(detect(buildOle('PowerPoint Document')), DocFormat.ppt);
    });

    test('unknown stream falls back to the extension', () {
      expect(detect(buildOle('Other'), name: 'old.ppt'), DocFormat.ppt);
      expect(detect(buildOle('Other'), name: 'setup.msi'), DocFormat.unknown);
    });
  });

  group('text', () {
    test('extension picks the text flavour', () {
      expect(detect(utf8.encode('# Title'), name: 'README.md'), DocFormat.markdown);
      expect(detect(utf8.encode('{"a":1}'), name: 'data.json'), DocFormat.code);
      expect(detect(utf8.encode('a,b\n1,2'), name: 'table.csv'), DocFormat.csv);
      expect(detect(utf8.encode('line'), name: 'app.log'), DocFormat.plainText);
    });

    test('unknown extension but readable text opens as text', () {
      expect(detect(utf8.encode('just some words\n'), name: 'notes.xyz'), DocFormat.plainText);
    });

    test('non-ASCII UTF-8 cut mid-character is still text', () {
      final bytes = utf8.encode('é' * 3000).sublist(0, 4096 + 1);
      expect(detect(bytes, name: 'french.txt'), DocFormat.plainText);
    });

    test('ANSI CSV with 8-bit characters is still a CSV', () {
      expect(detect([0x63, 0x61, 0x66, 0xE9, 0x2C, 0x31, 0x0A], name: 'ansi.csv'), DocFormat.csv);
    });

    test('binary blob with a text extension is not text', () {
      expect(detect([1, 2, 0, 0, 5, 6, 0, 9], name: 'blob.txt'), DocFormat.unknown);
    });

    test('MIME hint is used when the name says nothing', () {
      expect(detect(utf8.encode('a,b'), name: 'export', mime: 'text/csv'), DocFormat.csv);
    });

    test('empty file with a known extension keeps that type', () {
      expect(detect(const [], name: 'empty.txt'), DocFormat.plainText);
    });
  });

  test('extensionOf', () {
    expect(FileTypeDetector.extensionOf('/a/b/Report.Final.PDF'), 'pdf');
    expect(FileTypeDetector.extensionOf('.gitignore'), '');
    expect(FileTypeDetector.extensionOf('noext'), '');
    expect(FileTypeDetector.extensionOf('dir.d/file'), '');
    expect(FileTypeDetector.extensionOf(null), '');
  });
}

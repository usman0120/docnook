import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:docnook/engines/pdf/security/pdf_encryptor.dart';
import 'package:docnook/engines/pdf/security/pdf_syntax.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

/// Builds a small classic-xref PDF from object bodies (object n = bodies[n-1]).
Uint8List buildPdf(List<String> bodies, {String trailerExtra = ''}) {
  final out = BytesBuilder()..add(latin1.encode('%PDF-1.4\n'));
  final offsets = <int>[];
  for (var i = 0; i < bodies.length; i++) {
    offsets.add(out.length);
    out.add(latin1.encode('${i + 1} 0 obj\n${bodies[i]}\nendobj\n'));
  }
  final xref = out.length;
  final table = StringBuffer(
    'xref\n0 ${bodies.length + 1}\n0000000000 65535 f \n',
  );
  for (final offset in offsets) {
    table.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  out.add(
    latin1.encode(
      '${table}trailer\n<< /Size ${bodies.length + 1} /Root 1 0 R '
      '/Info 5 0 R $trailerExtra>>\nstartxref\n$xref\n%%EOF\n',
    ),
  );
  return out.toBytes();
}

const content = 'BT /F1 24 Tf 72 720 Td (Hello DocNook) Tj ET';

Uint8List samplePdf({String trailerExtra = ''}) => buildPdf([
  '<< /Type /Catalog /Pages 2 0 R >>',
  '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
  '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>',
  '<< /Length ${content.length} >>\nstream\n$content\nendstream',
  r'<< /Title (Quarterly \(Q3\) report) /Author <446F634E6F6F6B> >>',
], trailerExtra: trailerExtra);

/// Reads an encrypted PDF back the way a reader would: authenticate the
/// password (algorithm 2.A), recover the file key, decrypt objects.
final class EncryptedPdf {
  EncryptedPdf(this.bytes) {
    final text = latin1.decode(bytes);
    final startXref = int.parse(
      RegExp(r'startxref\s+(\d+)').allMatches(text).last.group(1)!,
    );
    final reader = PdfReader(bytes)..pos = startXref;
    expect(reader.readToken(), 'xref');
    reader.readInt();
    final count = reader.readInt();
    for (var i = 0; i < count; i++) {
      final offset = reader.readInt();
      reader.readInt();
      if (reader.readToken() == 'n') offsets[i] = offset;
    }
    expect(reader.readToken(), 'trailer');
    trailer = reader.readObject() as PdfDict;
    final encryptRef = trailer['/Encrypt']! as PdfRef;
    encrypt = object(encryptRef.number) as PdfDict;
  }

  final Uint8List bytes;
  final offsets = <int, int>{};
  late final PdfDict trailer;
  late final PdfDict encrypt;

  PdfObj object(int number) =>
      PdfReader(bytes).readIndirectAt(offsets[number]!).value;

  Uint8List _str(String key) => (encrypt[key]! as PdfStr).bytes;

  static Uint8List _cbcDecrypt(Uint8List key, Uint8List iv, Uint8List data) {
    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), iv));
    final out = Uint8List(data.length);
    for (var i = 0; i < data.length; i += 16) {
      cipher.processBlock(data, i, out, i);
    }
    return out;
  }

  /// Returns the file key, or null when the password is wrong.
  Uint8List? userKey(String password) {
    final pw = utf8.encode(password);
    final u = _str('/U');
    final hash = pdfHash2B(pw, u.sublist(32, 40), const []);
    if (!_equal(hash, u.sublist(0, 32))) return null;
    final intermediate = pdfHash2B(pw, u.sublist(40, 48), const []);
    return _cbcDecrypt(intermediate, Uint8List(16), _str('/UE'));
  }

  Uint8List? ownerKey(String password) {
    final pw = utf8.encode(password);
    final u = _str('/U');
    final o = _str('/O');
    final hash = pdfHash2B(pw, o.sublist(32, 40), u);
    if (!_equal(hash, o.sublist(0, 32))) return null;
    final intermediate = pdfHash2B(pw, o.sublist(40, 48), u);
    return _cbcDecrypt(intermediate, Uint8List(16), _str('/OE'));
  }

  static Uint8List decrypt(Uint8List key, Uint8List data) {
    final plain = _cbcDecrypt(
      key,
      Uint8List.sublistView(data, 0, 16),
      Uint8List.sublistView(data, 16),
    );
    return plain.sublist(0, plain.length - plain.last);
  }

  static bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

void main() {
  test('permission flags produce the standard /P values', () {
    expect(PdfPermissions.all.value, -4);
    expect(
      const PdfPermissions(
        print: false,
        modify: false,
        copy: false,
        annotate: false,
      ).value,
      -3904,
    );
  });

  group('encrypt', () {
    late EncryptedPdf pdf;

    setUp(() {
      pdf = EncryptedPdf(
        PdfEncryptor.encrypt(
          samplePdf(),
          userPassword: 'open-sesame',
          ownerPassword: 'owner-secret',
          random: Random(7),
        ),
      );
    });

    test('writes a revision 6 AES-256 security dictionary', () {
      expect(latin1.decode(pdf.bytes.sublist(0, 8)), '%PDF-1.7');
      expect(pdf.encrypt.nameOf('/Filter'), '/Standard');
      expect((pdf.encrypt['/V']! as PdfRaw).text, '5');
      expect((pdf.encrypt['/R']! as PdfRaw).text, '6');
      expect((pdf.encrypt['/U']! as PdfStr).bytes, hasLength(48));
      expect((pdf.encrypt['/O']! as PdfStr).bytes, hasLength(48));
      expect((pdf.encrypt['/UE']! as PdfStr).bytes, hasLength(32));
      expect((pdf.encrypt['/OE']! as PdfStr).bytes, hasLength(32));
      expect((pdf.encrypt['/Perms']! as PdfStr).bytes, hasLength(16));
      expect(pdf.trailer['/ID'], isA<PdfArr>());
    });

    test('user and owner passwords recover the same file key', () {
      final user = pdf.userKey('open-sesame');
      final owner = pdf.ownerKey('owner-secret');
      expect(user, isNotNull);
      expect(owner, user);
    });

    test('wrong passwords are rejected', () {
      expect(pdf.userKey('open-sesame '), isNull);
      expect(pdf.userKey(''), isNull);
      expect(pdf.ownerKey('open-sesame'), isNull);
    });

    test('/Perms decrypts to the permissions and the adb marker', () {
      final key = pdf.userKey('open-sesame')!;
      final ecb = AESEngine()..init(false, KeyParameter(key));
      final block = Uint8List(16);
      ecb.processBlock((pdf.encrypt['/Perms']! as PdfStr).bytes, 0, block, 0);
      expect(ByteData.sublistView(block).getInt32(0, Endian.little), -4);
      expect(latin1.decode(block.sublist(8, 12)), 'Tadb');
    });

    test('streams and strings decrypt back to the original content', () {
      final key = pdf.userKey('open-sesame')!;
      final stream = pdf.object(4) as PdfStream;
      expect(stream.data.length % 16, 0);
      expect(latin1.decode(EncryptedPdf.decrypt(key, stream.data)), content);

      final info = pdf.object(5) as PdfDict;
      expect(
        latin1.decode(
          EncryptedPdf.decrypt(key, (info['/Title']! as PdfStr).bytes),
        ),
        'Quarterly (Q3) report',
      );
      expect(
        latin1.decode(
          EncryptedPdf.decrypt(key, (info['/Author']! as PdfStr).bytes),
        ),
        'DocNook',
      );
    });

    test('no plaintext content survives in the file', () {
      final text = latin1.decode(pdf.bytes);
      expect(text, isNot(contains('Hello DocNook')));
      expect(text, isNot(contains('Quarterly')));
    });

    test('structure stays readable and the catalog declares the extension', () {
      final catalog = pdf.object(1) as PdfDict;
      expect(catalog.nameOf('/Type'), '/Catalog');
      expect(catalog['/Extensions'], isA<PdfDict>());
      final page = pdf.object(3) as PdfDict;
      expect(page['/Contents'], isA<PdfRef>());
    });
  });

  test('two runs never produce the same ciphertext', () {
    final a = PdfEncryptor.encrypt(samplePdf(), userPassword: 'pw');
    final b = PdfEncryptor.encrypt(samplePdf(), userPassword: 'pw');
    expect(a, isNot(equals(b)));
  });

  test('owner password defaults to the user password', () {
    final pdf = EncryptedPdf(
      PdfEncryptor.encrypt(samplePdf(), userPassword: 'pw'),
    );
    expect(pdf.ownerKey('pw'), pdf.userKey('pw'));
  });

  test('non-ASCII passwords are UTF-8', () {
    final pdf = EncryptedPdf(
      PdfEncryptor.encrypt(samplePdf(), userPassword: 'pässwörd'),
    );
    expect(pdf.userKey('pässwörd'), isNotNull);
    expect(pdf.userKey('password'), isNull);
  });

  test('a stream with a wrong /Length is still read whole', () {
    final broken = buildPdf([
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [] /Count 0 >>',
      '<< >>',
      '<< /Length 3 >>\nstream\n$content\nendstream',
      '<< >>',
    ]);
    final pdf = EncryptedPdf(PdfEncryptor.encrypt(broken, userPassword: 'pw'));
    final key = pdf.userKey('pw')!;
    final stream = pdf.object(4) as PdfStream;
    expect(latin1.decode(EncryptedPdf.decrypt(key, stream.data)), content);
  });

  test('refuses input that is already encrypted', () {
    expect(
      () => PdfEncryptor.encrypt(
        samplePdf(trailerExtra: '/Encrypt 3 0 R '),
        userPassword: 'pw',
      ),
      throwsA(const DocNookFailure.unsupported()),
    );
  });

  test('refuses input that is not a PDF', () {
    expect(
      () => PdfEncryptor.encrypt(
        Uint8List.fromList(utf8.encode('not a pdf at all')),
        userPassword: 'pw',
      ),
      throwsA(const DocNookFailure.corrupt()),
    );
  });
}

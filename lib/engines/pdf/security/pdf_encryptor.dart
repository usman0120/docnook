import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:docnook/engines/pdf/security/pdf_syntax.dart';
import 'package:pointycastle/export.dart';

/// What a reader may do once the document is open with the user password.
/// These are advisory flags honoured by PDF readers; the owner password lifts
/// them. Bit positions follow ISO 32000-2 table 22.
final class PdfPermissions {
  const PdfPermissions({
    this.print = true,
    this.modify = true,
    this.copy = true,
    this.annotate = true,
  });

  static const all = PdfPermissions();

  final bool print;
  final bool modify;
  final bool copy;
  final bool annotate;

  /// The signed 32-bit /P value.
  int get value {
    var bits = 0xFFFFF0C0; // reserved bits that must be 1
    if (print) bits |= 1 << 2 | 1 << 11;
    if (modify) bits |= 1 << 3 | 1 << 10;
    if (copy) bits |= 1 << 4 | 1 << 9;
    if (annotate) bits |= 1 << 5 | 1 << 8;
    return bits.toSigned(32);
  }
}

/// Adds AES-256 password protection (PDF 2.0 standard security handler,
/// revision 6) to an unencrypted PDF.
///
/// PDFium can remove encryption but cannot add it, so DocNook writes it
/// itself: every object is read, its strings and streams are encrypted with
/// AES-256-CBC under a random file key, and the file is written back with a
/// fresh cross-reference table and an /Encrypt dictionary.
///
/// The input must use a classic cross-reference table, which is what PDFium
/// writes when it saves a full (non-incremental) copy. Pure Dart and
/// isolate-safe: call it from a job, not from the UI thread.
abstract final class PdfEncryptor {
  /// Returns the protected PDF. Throws [DocNookFailure] if [input] is not a
  /// readable, unencrypted PDF.
  ///
  /// [ownerPassword] defaults to [userPassword]. [random] is injectable for
  /// tests only.
  static Uint8List encrypt(
    Uint8List input, {
    required String userPassword,
    String? ownerPassword,
    PdfPermissions permissions = PdfPermissions.all,
    Random? random,
    void Function(double progress)? onProgress,
  }) {
    final rng = random ?? Random.secure();
    final doc = _SourceDocument.load(input);
    if (doc.trailer.entries.containsKey('/Encrypt')) {
      throw const DocNookFailure.unsupported(detail: 'already encrypted');
    }

    final fileKey = _randomBytes(rng, 32);
    final security = _SecurityValues.create(
      userPassword: _passwordBytes(userPassword),
      ownerPassword: _passwordBytes(ownerPassword ?? userPassword),
      fileKey: fileKey,
      permissions: permissions.value,
      rng: rng,
    );

    final cipher = _ObjectCipher(fileKey, rng);
    final writer =
        PdfWriter(
            transformString: cipher.encrypt,
            transformStream: cipher.encrypt,
          )
          // AES-256 needs PDF 1.7 extension level 8 or PDF 2.0; state 1.7 and
          // declare the extension in the catalog, as Acrobat and qpdf do.
          ..raw('%PDF-1.7\n')
          ..bytes(const [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A]);

    final rootRef = doc.trailer['/Root'];
    final offsets = <int, int>{};
    final generations = <int, int>{};
    final numbers = doc.offsets.keys.toList()..sort();

    for (var i = 0; i < numbers.length; i++) {
      final number = numbers[i];
      final indirect = doc.read(number);
      if (indirect == null) continue;
      var value = indirect.value;

      // Cross-reference and object streams never appear in a classic-table
      // file; skip any stray one rather than encrypting it wrongly.
      final dict = value is PdfStream
          ? value.dict
          : (value is PdfDict ? value : null);
      final type = dict?.nameOf('/Type');
      if (value is PdfStream && (type == '/XRef' || type == '/ObjStm')) {
        continue;
      }

      if (rootRef is PdfRef && rootRef.number == number && value is PdfDict) {
        value = _withExtension(value);
      }

      offsets[number] = writer.length;
      generations[number] = indirect.generation;
      writer.indirect(number, indirect.generation, value);
      onProgress?.call((i + 1) / numbers.length);
    }

    final encryptNumber = (numbers.isEmpty ? 0 : numbers.last) + 1;
    offsets[encryptNumber] = writer.length;
    generations[encryptNumber] = 0;
    writer.indirect(encryptNumber, 0, security.toDict(), encrypt: false);

    final size = encryptNumber + 1;
    final xrefOffset = writer.length;
    writer.raw('xref\n0 $size\n');
    for (var n = 0; n < size; n++) {
      final offset = offsets[n];
      if (n == 0 || offset == null) {
        writer.raw('0000000000 ${n == 0 ? '65535' : '00000'} f \n');
      } else {
        final generation = generations[n]!.toString().padLeft(5, '0');
        writer.raw('${offset.toString().padLeft(10, '0')} $generation n \n');
      }
    }

    // The file identifier is required when encrypting; keep an existing one.
    final existingId = doc.trailer['/ID'];
    final id = existingId is PdfArr && existingId.items.length == 2
        ? existingId
        : PdfArr([
            PdfStr(_randomBytes(rng, 16)),
            PdfStr(_randomBytes(rng, 16)),
          ]);

    final trailer = PdfDict({
      '/Size': PdfRaw('$size'),
      '/Root': ?doc.trailer['/Root'],
      '/Info': ?doc.trailer['/Info'],
      '/ID': id,
      '/Encrypt': PdfRef(encryptNumber, 0),
    });
    writer
      ..raw('trailer\n')
      ..object(trailer, encrypt: false)
      ..raw('\nstartxref\n$xrefOffset\n%%EOF\n');

    return writer.takeBytes();
  }

  static PdfDict _withExtension(PdfDict catalog) {
    if (catalog.entries.containsKey('/Extensions')) return catalog;
    return PdfDict({...catalog.entries})
      ..['/Extensions'] = PdfDict({
        '/ADBE': PdfDict({
          '/BaseVersion': const PdfRaw('/1.7'),
          '/ExtensionLevel': const PdfRaw('8'),
        }),
      });
  }

  /// Passwords are UTF-8, at most 127 bytes (ISO 32000-2, 7.6.4.3.3).
  static Uint8List _passwordBytes(String password) {
    final bytes = utf8.encode(password);
    return Uint8List.fromList(
      bytes.length > 127 ? bytes.sublist(0, 127) : bytes,
    );
  }
}

Uint8List _randomBytes(Random rng, int count) {
  final out = Uint8List(count);
  for (var i = 0; i < count; i++) {
    out[i] = rng.nextInt(256);
  }
  return out;
}

Uint8List _concat(List<List<int>> parts) {
  final builder = BytesBuilder(copy: false);
  for (final part in parts) {
    builder.add(part);
  }
  return builder.toBytes();
}

/// AES-CBC without padding; [data] must be a multiple of 16 bytes.
Uint8List _aesCbcNoPadding(Uint8List key, Uint8List iv, Uint8List data) {
  final cipher = CBCBlockCipher(AESEngine())
    ..init(true, ParametersWithIV(KeyParameter(key), iv));
  final out = Uint8List(data.length);
  for (var offset = 0; offset < data.length; offset += 16) {
    cipher.processBlock(data, offset, out, offset);
  }
  return out;
}

/// Encrypts one string or stream: random IV, PKCS#7 padding, IV prepended.
/// With AESV3 the file key is used directly for every object.
final class _ObjectCipher {
  _ObjectCipher(this._key, this._rng);

  final Uint8List _key;
  final Random _rng;

  Uint8List encrypt(Uint8List plain) {
    final iv = _randomBytes(_rng, 16);
    final padding = 16 - plain.length % 16;
    final padded = Uint8List(plain.length + padding)
      ..setAll(0, plain)
      ..fillRange(plain.length, plain.length + padding, padding);
    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(_key), iv));
    final out = Uint8List(16 + padded.length)..setAll(0, iv);
    for (var offset = 0; offset < padded.length; offset += 16) {
      cipher.processBlock(padded, offset, out, 16 + offset);
    }
    return out;
  }
}

/// The values of the /Encrypt dictionary for revision 6.
final class _SecurityValues {
  _SecurityValues._(this.u, this.ue, this.o, this.oe, this.perms, this.p);

  factory _SecurityValues.create({
    required Uint8List userPassword,
    required Uint8List ownerPassword,
    required Uint8List fileKey,
    required int permissions,
    required Random rng,
  }) {
    final zeroIv = Uint8List(16);

    // Algorithm 8: /U and /UE.
    final userValidationSalt = _randomBytes(rng, 8);
    final userKeySalt = _randomBytes(rng, 8);
    final u = _concat([
      pdfHash2B(userPassword, userValidationSalt, const []),
      userValidationSalt,
      userKeySalt,
    ]);
    final ue = _aesCbcNoPadding(
      pdfHash2B(userPassword, userKeySalt, const []),
      zeroIv,
      fileKey,
    );

    // Algorithm 9: /O and /OE, bound to /U.
    final ownerValidationSalt = _randomBytes(rng, 8);
    final ownerKeySalt = _randomBytes(rng, 8);
    final o = _concat([
      pdfHash2B(ownerPassword, ownerValidationSalt, u),
      ownerValidationSalt,
      ownerKeySalt,
    ]);
    final oe = _aesCbcNoPadding(
      pdfHash2B(ownerPassword, ownerKeySalt, u),
      zeroIv,
      fileKey,
    );

    // Algorithm 10: /Perms, so a reader can detect a tampered /P.
    final block = Uint8List(16);
    ByteData.sublistView(
      block,
    ).setUint32(0, permissions & 0xFFFFFFFF, Endian.little);
    block
      ..fillRange(4, 8, 0xFF)
      ..[8] =
          0x54 // 'T': metadata is encrypted
      ..[9] =
          0x61 // 'a'
      ..[10] =
          0x64 // 'd'
      ..[11] =
          0x62 // 'b'
      ..setAll(12, _randomBytes(rng, 4));
    final ecb = AESEngine()..init(true, KeyParameter(fileKey));
    final perms = Uint8List(16);
    ecb.processBlock(block, 0, perms, 0);

    return _SecurityValues._(u, ue, o, oe, perms, permissions);
  }

  final Uint8List u;
  final Uint8List ue;
  final Uint8List o;
  final Uint8List oe;
  final Uint8List perms;
  final int p;

  PdfDict toDict() => PdfDict({
    '/Filter': const PdfRaw('/Standard'),
    '/V': const PdfRaw('5'),
    '/R': const PdfRaw('6'),
    '/Length': const PdfRaw('256'),
    '/CF': PdfDict({
      '/StdCF': PdfDict({
        '/AuthEvent': const PdfRaw('/DocOpen'),
        '/CFM': const PdfRaw('/AESV3'),
        '/Length': const PdfRaw('32'),
      }),
    }),
    '/StmF': const PdfRaw('/StdCF'),
    '/StrF': const PdfRaw('/StdCF'),
    '/U': PdfStr(u),
    '/UE': PdfStr(ue),
    '/O': PdfStr(o),
    '/OE': PdfStr(oe),
    '/P': PdfRaw('$p'),
    '/Perms': PdfStr(perms),
    '/EncryptMetadata': const PdfRaw('true'),
  });
}

/// Algorithm 2.B (ISO 32000-2, 7.6.4.3.4): the revision 6 password hash.
/// [userKey] is the 48-byte /U value when hashing an owner password, else
/// empty. Exposed for tests against published vectors.
Uint8List pdfHash2B(List<int> password, List<int> salt, List<int> userKey) {
  var k = SHA256Digest().process(_concat([password, salt, userKey]));
  var round = 0;
  while (true) {
    round++;
    final unit = _concat([password, k, userKey]);
    final k1 = Uint8List(unit.length * 64);
    for (var i = 0; i < 64; i++) {
      k1.setAll(i * unit.length, unit);
    }
    final e = _aesCbcNoPadding(
      Uint8List.sublistView(k, 0, 16),
      Uint8List.sublistView(k, 16, 32),
      k1,
    );
    // The first 16 bytes as a big-endian number mod 3 equals their sum mod 3,
    // because 256 ≡ 1 (mod 3).
    var sum = 0;
    for (var i = 0; i < 16; i++) {
      sum += e[i];
    }
    k = switch (sum % 3) {
      0 => SHA256Digest().process(e),
      1 => SHA384Digest().process(e),
      _ => SHA512Digest().process(e),
    };
    if (round >= 64 && e[e.length - 1] <= round - 32) break;
  }
  return Uint8List.sublistView(k, 0, 32);
}

/// Locates every object of the input through its cross-reference table.
final class _SourceDocument {
  _SourceDocument._(this._reader, this.offsets, this.trailer);

  factory _SourceDocument.load(Uint8List bytes) {
    final reader = PdfReader(bytes);
    final offsets = <int, int>{};
    PdfDict? newestTrailer;

    var xrefOffset = _findStartXref(bytes);
    final visited = <int>{};
    while (xrefOffset != null && visited.add(xrefOffset)) {
      if (xrefOffset < 0 || xrefOffset >= bytes.length) {
        throw const DocNookFailure.corrupt(detail: 'xref offset');
      }
      reader
        ..pos = xrefOffset
        ..skipWhitespace();
      if (reader.readToken() != 'xref') {
        // A cross-reference stream: not produced by PDFium's full save.
        throw const DocNookFailure.unsupported(detail: 'xref stream');
      }

      while (true) {
        reader.skipWhitespace();
        final mark = reader.pos;
        final token = reader.readToken();
        if (token == 'trailer') break;
        final start = int.tryParse(token);
        if (start == null) {
          reader.pos = mark;
          throw const DocNookFailure.corrupt(detail: 'xref section');
        }
        final count = reader.readInt();
        for (var i = 0; i < count; i++) {
          final offset = reader.readInt();
          reader.readInt(); // generation, re-read from the object itself
          final kind = reader.readToken();
          // Newer sections are read first and win over older ones.
          if (kind == 'n' && offset > 0) {
            offsets.putIfAbsent(start + i, () => offset);
          } else if (kind == 'f') {
            offsets.putIfAbsent(start + i, () => -1);
          }
        }
      }

      final trailer = reader.readObject();
      if (trailer is! PdfDict) {
        throw const DocNookFailure.corrupt(detail: 'trailer');
      }
      newestTrailer ??= trailer;
      if (trailer.entries.containsKey('/XRefStm')) {
        throw const DocNookFailure.unsupported(detail: 'hybrid xref');
      }
      final previous = trailer['/Prev'];
      xrefOffset = previous is PdfRaw ? int.tryParse(previous.text) : null;
    }

    if (newestTrailer == null || newestTrailer['/Root'] == null) {
      throw const DocNookFailure.corrupt(detail: 'no trailer');
    }
    offsets.removeWhere((_, offset) => offset < 0);

    final doc = _SourceDocument._(reader, offsets, newestTrailer);
    reader.resolveInt = doc._resolveInt;
    return doc;
  }

  final PdfReader _reader;
  final Map<int, int> offsets;
  final PdfDict trailer;

  PdfIndirect? read(int number) {
    final offset = offsets[number];
    if (offset == null) return null;
    final indirect = _reader.readIndirectAt(offset);
    // An offset pointing at a different object means a damaged table.
    return indirect.number == number ? indirect : null;
  }

  int? _resolveInt(PdfRef ref) {
    final offset = offsets[ref.number];
    if (offset == null) return null;
    final reader = PdfReader(_reader.bytes);
    final value = reader.readIndirectAt(offset).value;
    return value is PdfRaw ? int.tryParse(value.text) : null;
  }

  static int? _findStartXref(Uint8List bytes) {
    const keyword = 'startxref';
    final from = bytes.length > 2048 ? bytes.length - 2048 : 0;
    for (var i = bytes.length - keyword.length; i >= from; i--) {
      var ok = true;
      for (var j = 0; j < keyword.length; j++) {
        if (bytes[i + j] != keyword.codeUnitAt(j)) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      final reader = PdfReader(bytes)..pos = i + keyword.length;
      return int.tryParse(reader.readToken());
    }
    throw const DocNookFailure.corrupt(detail: 'no startxref');
  }
}

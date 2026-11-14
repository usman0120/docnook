import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The bundled Noto fonts as raw bytes: sendable to a JobRunner isolate,
/// where [DocFonts.load] turns them into `pdf` fonts.
final class DocFontBytes {
  const DocFontBytes({
    required this.sans,
    required this.sansBold,
    required this.sansItalic,
    required this.sansBoldItalic,
    required this.serif,
    required this.serifBold,
    required this.serifItalic,
    required this.serifBoldItalic,
    required this.mono,
    required this.monoBold,
  });

  static const files = [
    'NotoSans-Regular.ttf',
    'NotoSans-Bold.ttf',
    'NotoSans-Italic.ttf',
    'NotoSans-BoldItalic.ttf',
    'NotoSerif-Regular.ttf',
    'NotoSerif-Bold.ttf',
    'NotoSerif-Italic.ttf',
    'NotoSerif-BoldItalic.ttf',
    'NotoSansMono-Regular.ttf',
    'NotoSansMono-Bold.ttf',
  ];

  /// Builds from bytes in the order of [files].
  factory DocFontBytes.of(List<Uint8List> b) => DocFontBytes(
    sans: b[0],
    sansBold: b[1],
    sansItalic: b[2],
    sansBoldItalic: b[3],
    serif: b[4],
    serifBold: b[5],
    serifItalic: b[6],
    serifBoldItalic: b[7],
    mono: b[8],
    monoBold: b[9],
  );

  final Uint8List sans;
  final Uint8List sansBold;
  final Uint8List sansItalic;
  final Uint8List sansBoldItalic;
  final Uint8List serif;
  final Uint8List serifBold;
  final Uint8List serifItalic;
  final Uint8List serifBoldItalic;
  final Uint8List mono;
  final Uint8List monoBold;
}

enum FontFamily { sans, serif, mono }

/// Fonts for one conversion. Characters the bundled Noto subsets do not
/// cover (Arabic, Hebrew, Devanagari, Thai…) are drawn with fonts found in
/// the phone's own `/system/fonts/` (BLUEPRINT 4.5), so DocNook ships none.
final class DocFonts {
  DocFonts._(this._fonts, this.fallback);

  /// Loads [bytes] and, when [text] has characters outside them, matching
  /// system fonts from [systemDir].
  factory DocFonts.load(
    DocFontBytes bytes, {
    String text = '',
    String systemDir = '/system/fonts',
  }) {
    pw.Font f(Uint8List b) => pw.Font.ttf(ByteData.sublistView(b));
    final fonts = <(FontFamily, bool, bool), pw.Font>{
      (FontFamily.sans, false, false): f(bytes.sans),
      (FontFamily.sans, true, false): f(bytes.sansBold),
      (FontFamily.sans, false, true): f(bytes.sansItalic),
      (FontFamily.sans, true, true): f(bytes.sansBoldItalic),
      (FontFamily.serif, false, false): f(bytes.serif),
      (FontFamily.serif, true, false): f(bytes.serifBold),
      (FontFamily.serif, false, true): f(bytes.serifItalic),
      (FontFamily.serif, true, true): f(bytes.serifBoldItalic),
      (FontFamily.mono, false, false): f(bytes.mono),
      (FontFamily.mono, true, false): f(bytes.monoBold),
      (FontFamily.mono, false, true): f(bytes.mono),
      (FontFamily.mono, true, true): f(bytes.monoBold),
    };
    return DocFonts._(fonts, _systemFallback(bytes.sans, text, systemDir));
  }

  final Map<(FontFamily, bool, bool), pw.Font> _fonts;

  /// System fonts for characters outside the bundled ones, in order.
  final List<pw.Font> fallback;

  pw.Font font(FontFamily family, {bool bold = false, bool italic = false}) =>
      _fonts[(family, bold, italic)]!;

  pw.ThemeData theme() => pw.ThemeData.withFont(
    base: font(FontFamily.sans),
    bold: font(FontFamily.sans, bold: true),
    italic: font(FontFamily.sans, italic: true),
    boldItalic: font(FontFamily.sans, bold: true, italic: true),
    fontFallback: fallback,
  );

  /// Picks system TrueType fonts that cover the characters of [text] the
  /// bundled sans font lacks. Only plain `.ttf` files: the PDF writer reads
  /// TrueType outlines, not CFF (`.otf`) or collections (`.ttc`).
  static List<pw.Font> _systemFallback(
    Uint8List base,
    String text,
    String systemDir,
  ) {
    if (text.isEmpty) return const [];
    final covered = TtfParser(ByteData.sublistView(base)).charToGlyphIndexMap;
    final missing = <int>{
      for (final r in text.runes)
        if (r > 0x20 && !covered.containsKey(r) && !_ignorable(r)) r,
    };
    if (missing.isEmpty) return const [];
    final dir = Directory(systemDir);
    if (!dir.existsSync()) return const [];
    final candidates =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.ttf'))
            .toList()
          // Regular weights first, Noto before others: the likeliest match.
          ..sort((a, b) => _rank(a.path).compareTo(_rank(b.path)));
    final out = <pw.Font>[];
    for (final file in candidates) {
      if (missing.isEmpty || out.length >= 6) break;
      try {
        final data = ByteData.sublistView(file.readAsBytesSync());
        final map = TtfParser(data).charToGlyphIndexMap;
        final hits = missing.where(map.containsKey).toList();
        if (hits.isEmpty) continue;
        missing.removeAll(hits);
        out.add(pw.Font.ttf(data));
      } on Object {
        // Unreadable or unsupported font file: try the next one.
      }
    }
    return out;
  }

  static bool _ignorable(int r) =>
      (r >= 0x200B && r <= 0x200F) ||
      r == 0xFEFF ||
      (r >= 0xFE00 && r <= 0xFE0F);

  static int _rank(String path) {
    final name = path.split('/').last.toLowerCase();
    var score = 0;
    if (!name.startsWith('noto')) score += 4;
    if (!name.contains('regular')) score += 2;
    if (name.contains('ui')) score += 1;
    return score;
  }
}

/// Points for PDF output from a `0xAARRGGBB` colour.
PdfColor pdfColor(int argb) => PdfColor.fromInt(argb | 0xFF000000);

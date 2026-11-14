import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as img;
import 'package:pdfium_dart/pdfium_dart.dart' as pb;
import 'package:pdfrx/pdfrx.dart' show PdfrxEntryFunctions;

/// Progress and cancellation for a multi-step edit. Edits run in short steps
/// on PDFium's worker isolate; between steps they report progress and stop
/// if [isCancelled] turns true.
final class EditControl {
  EditControl({this.onProgress, bool Function()? isCancelled})
    : _isCancelled = isCancelled ?? _never;

  static bool _never() => false;

  final void Function(double value, {int? page, int? of})? onProgress;
  final bool Function() _isCancelled;

  void report(double value, {int? page, int? of}) =>
      onProgress?.call(value.clamp(0, 1).toDouble(), page: page, of: of);

  void check() {
    if (_isCancelled()) throw const DocNookFailure.cancelled();
  }
}

/// PDF editing through PDFium (BLUEPRINT 4.2): the same library pdfrx ships,
/// called through its FFI bindings on pdfrx's PDFium worker isolate, so
/// edits never run on the UI thread and never race the viewer (PDFium is
/// single-threaded; pdfrx queues every call on that one worker).
///
/// Pages are copied as page objects, never re-rendered (FR-PDF-01).
abstract final class PdfiumEditor {
  /// Path of the PDFium library. Null on Android (the bundled one); tests on
  /// a desktop point it at a local build.
  static String? modulePath;

  /// Pages per worker step: small enough for timely progress and cancel.
  static const _batch = 16;

  static Future<T> _run<M, T>(
    FutureOr<(String?, T?)> Function(M message) body,
    M message,
  ) async {
    await PdfrxEntryFunctions.instance.init();
    final (error, value) = await PdfrxEntryFunctions.instance
        .compute<M, (String?, T?)>(body, message);
    if (error != null) throw _failure(error);
    return value as T;
  }

  static DocNookFailure _failure(String code) => switch (code) {
    'passwordRequired' => const DocNookFailure.passwordRequired(),
    'wrongPassword' => const DocNookFailure.wrongPassword(),
    'unsupported' => const DocNookFailure.unsupported(detail: 'security'),
    'outOfSpace' => const DocNookFailure.outOfSpace(),
    'permissionDenied' => const DocNookFailure.permissionDenied(),
    'cancelled' => const DocNookFailure.cancelled(),
    _ => DocNookFailure.corrupt(detail: code),
  };

  /// Page sizes, encryption and form presence.
  static Future<PdfInfo> inspect(PdfSource source) =>
      _run(_inspect, (modulePath, source.path, source.password));

  /// Builds a new PDF from pages of [sources] (merge, split, organize,
  /// extract). Bookmarks of the sources are not carried over.
  static Future<void> assemble({
    required List<PdfSource> sources,
    required List<PageSpec> pages,
    required String output,
    EditControl? control,
  }) async {
    final c = control ?? EditControl();
    final dest = await _run(_begin, modulePath);
    try {
      final real = [
        for (final s in pages)
          if (!s.isBlank) s,
      ];
      // One import per run of pages from the same source keeps shared
      // resources (fonts, images) copied once.
      final runs = <(int, List<int>)>[];
      for (final s in real) {
        if (runs.isNotEmpty && runs.last.$1 == s.source) {
          runs.last.$2.add(s.index);
        } else {
          runs.add((s.source, [s.index]));
        }
      }
      for (var i = 0; i < runs.length; i++) {
        c.check();
        final (src, indices) = runs[i];
        await _run(_import, (
          modulePath,
          dest,
          src,
          sources[src].path,
          sources[src].password,
          indices,
        ));
        c.report(0.9 * (i + 1) / runs.length);
      }
      c.check();
      await _run(_finish, (
        modulePath,
        dest,
        [
          for (final s in pages)
            (s.isBlank, s.quarterTurns, s.blankWidth, s.blankHeight),
        ],
        output,
      ));
      c.report(1);
    } finally {
      await _run(_end, (modulePath, dest));
    }
  }

  /// Draws [stamp] on the 0-based [pages] (all pages when null).
  /// [firstNumber] is the number shown on the first stamped page.
  static Future<void> stamp({
    required PdfSource source,
    required StampSpec stamp,
    required String output,
    List<int>? pages,
    int firstNumber = 1,
    EditControl? control,
  }) => _edit(source, output, control, (doc, info, c) async {
    final targets = pages ?? [for (var i = 0; i < info.pageCount; i++) i];
    final total = info.pageCount;
    for (var s = 0; s < targets.length; s += _batch) {
      c.check();
      final chunk = targets.sublist(s, math.min(s + _batch, targets.length));
      await _run(_stampPages, (
        modulePath,
        doc,
        chunk,
        [for (final p in chunk) firstNumber + targets.indexOf(p)],
        total,
        stamp,
      ));
      c.report(0.9 * (s + chunk.length) / targets.length);
    }
  });

  /// Writes [marks] as standard PDF annotations with appearance streams.
  static Future<void> annotate({
    required PdfSource source,
    required List<PdfMark> marks,
    required String output,
    EditControl? control,
  }) => _edit(source, output, control, (doc, info, c) async {
    final byPage = <int, List<PdfMark>>{};
    for (final m in marks) {
      (byPage[m.page] ??= []).add(m);
    }
    var done = 0;
    for (final entry in byPage.entries) {
      c.check();
      await _run(_annotatePage, (modulePath, doc, entry.key, entry.value));
      done++;
      c.report(0.9 * done / byPage.length);
    }
  });

  /// Every form widget of the document, in page order.
  static Future<List<FormFieldInfo>> readForm(PdfSource source) =>
      _run(_readForm, (modulePath, source.path, source.password));

  /// Applies [values] through PDFium's form filler (which also redraws each
  /// field), then optionally flattens every page.
  static Future<void> fillForm({
    required PdfSource source,
    required List<FormFieldValue> values,
    required bool flatten,
    required String output,
    EditControl? control,
  }) => _edit(source, output, control, (doc, info, c) async {
    c.report(0.1);
    await _run(_fillForm, (modulePath, doc, values, flatten, info.pageCount));
    c.report(0.9);
  });

  /// Balanced compression: re-encodes large embedded photos as JPEG, keeps
  /// text and vector content untouched.
  static Future<RecompressStats> recompressImages({
    required PdfSource source,
    required String output,
    int maxEdge = 1600,
    int quality = 70,
    EditControl? control,
  }) async {
    var seen = 0;
    var changed = 0;
    await _edit(source, output, control, (doc, info, c) async {
      // Pass 1: images used on more than one page are left alone, because
      // replacing them per page would store several copies.
      final counts = <int, int>{};
      for (var s = 0; s < info.pageCount; s += _batch) {
        c.check();
        final keys = await _run(_imageKeys, (
          modulePath,
          doc,
          s,
          math.min(s + _batch, info.pageCount),
        ));
        for (final k in keys) {
          counts[k] = (counts[k] ?? 0) + 1;
        }
        c.report(0.2 * (s + _batch) / info.pageCount);
      }
      final shared = {
        for (final e in counts.entries)
          if (e.value > 1) e.key,
      };
      for (var i = 0; i < info.pageCount; i++) {
        c.check();
        final (a, b) = await _run(_recompressPage, (
          modulePath,
          doc,
          i,
          shared,
          maxEdge,
          quality,
        ));
        seen += a;
        changed += b;
        c.report(
          0.2 + 0.7 * (i + 1) / info.pageCount,
          page: i + 1,
          of: info.pageCount,
        );
      }
    });
    return RecompressStats(seen, changed);
  }

  /// Pictures on page [page] as JPEG with their place (points from the
  /// top-left of the page), for PDF → Word. Tiny images (rules, bullets)
  /// are skipped.
  static Future<List<(Uint8List, double, double, double, double)>>
  extractImages(PdfSource source, int page) =>
      _run(_extractImages, (modulePath, source.path, source.password, page));

  /// The characters of page [page] with their boxes and font, for PDF →
  /// Word. Boxes are four numbers per character (left, bottom, right, top)
  /// in points from the visible box's bottom-left corner; `sizes` holds
  /// each character's font size, negative when the font is bold.
  static Future<(String, Float64List, Float64List)> pageChars(
    PdfSource source,
    int page,
  ) => _run(_pageChars, (modulePath, source.path, source.password, page));

  /// A full re-save (no incremental updates). With [removeSecurity] the
  /// output has no password (Unlock).
  static Future<void> resave({
    required PdfSource source,
    required String output,
    bool removeSecurity = false,
  }) => _edit(
    source,
    output,
    null,
    (doc, info, c) async {},
    removeSecurity: removeSecurity,
  );

  static Future<void> _edit(
    PdfSource source,
    String output,
    EditControl? control,
    Future<void> Function(int doc, PdfInfo info, EditControl c) body, {
    bool removeSecurity = false,
  }) async {
    final c = control ?? EditControl();
    final (doc, info) = await _run(_open, (
      modulePath,
      source.path,
      source.password,
    ));
    try {
      await body(doc, info, c);
      c.check();
      await _run(_save, (
        modulePath,
        doc,
        output,
        removeSecurity ? _saveNoSecurity : _saveFull,
      ));
      c.report(1);
    } finally {
      await _run(_close, (modulePath, doc));
    }
  }
}

// ---------------------------------------------------------------------------
// Worker side. Everything below runs on pdfrx's PDFium isolate; state kept
// in top-level variables lives there between steps.

const _saveFull = 2; // FPDF_NO_INCREMENTAL
const _saveNoSecurity = 3; // FPDF_REMOVE_SECURITY

pb.PDFium? _lib;
pb.PDFium _pdfium(String? module) => _lib ??= pb.getPdfium(modulePath: module);

/// Sources opened during an assemble, by destination document.
final _assembleSources = <int, Map<int, int>>{};

/// Shared image XObjects for image stamps, by document.
final _stampXObjects = <int, int>{};

/// Documents that had a form environment for filling, by document.
final _formHandles = <int, (int, int)>{};

final class _Fail implements Exception {
  const _Fail(this.code);
  final String code;
}

Future<(String?, T?)> _guard<T>(T Function() body) async {
  try {
    return (null, body());
  } on _Fail catch (f) {
    return (f.code, null);
  } on FileSystemException catch (e) {
    final text = e.toString();
    if (text.contains('ENOSPC') || text.contains('No space left')) {
      return ('outOfSpace', null);
    }
    if (text.contains('EACCES') || text.contains('denied')) {
      return ('permissionDenied', null);
    }
    return ('io', null);
  } on Object catch (e) {
    return (e.runtimeType.toString(), null);
  }
}

pb.FPDF_DOCUMENT _doc(int address) => pb.FPDF_DOCUMENT.fromAddress(address);

pb.FPDF_DOCUMENT _load(pb.PDFium pdf, String path, String? password) {
  // The error code must be read right after the failed call: on Windows
  // freeing memory can reset it, so it may also read 0 and need a retry.
  var error = 0;
  for (var attempt = 0; attempt < 3 && error == 0; attempt++) {
    final filePath = path.toNativeUtf8();
    final secret = (password ?? '').toNativeUtf8();
    final doc = pdf.FPDF_LoadDocument(filePath.cast(), secret.cast());
    error = doc == nullptr ? pdf.FPDF_GetLastError() : 0;
    calloc
      ..free(filePath)
      ..free(secret);
    if (doc != nullptr) return doc;
  }
  throw _Fail(switch (error) {
    4 =>
      password == null || password.isEmpty
          ? 'passwordRequired'
          : 'wrongPassword',
    5 => 'unsupported',
    2 => 'file',
    _ => 'format',
  });
}

PdfInfo _info(pb.PDFium pdf, pb.FPDF_DOCUMENT doc) {
  final count = pdf.FPDF_GetPageCount(doc);
  final pages = <PdfPageInfo>[];
  for (var i = 0; i < count; i++) {
    final page = pdf.FPDF_LoadPage(doc, i);
    if (page == nullptr) {
      pages.add(const PdfPageInfo(595, 842, 0));
      continue;
    }
    final box = _box(pdf, page);
    pages.add(
      PdfPageInfo(
        box.w,
        box.h,
        pdf.FPDFPage_GetRotation(page) & 3,
        x0: box.x0,
        y0: box.y0,
      ),
    );
    pdf.FPDF_ClosePage(page);
  }
  return PdfInfo(
    pages: pages,
    encrypted: pdf.FPDF_GetSecurityHandlerRevision(doc) >= 0,
    hasForm: pdf.FPDF_GetFormType(doc) != 0,
  );
}

Future<(String?, PdfInfo?)> _inspect((String?, String, String?) m) =>
    _guard(() {
      final pdf = _pdfium(m.$1);
      final doc = _load(pdf, m.$2, m.$3);
      try {
        return _info(pdf, doc);
      } finally {
        pdf.FPDF_CloseDocument(doc);
      }
    });

Future<(String?, (int, PdfInfo)?)> _open((String?, String, String?) m) =>
    _guard(() {
      final pdf = _pdfium(m.$1);
      final doc = _load(pdf, m.$2, m.$3);
      return (doc.address, _info(pdf, doc));
    });

Future<(String?, bool?)> _close((String?, int) m) => _guard(() {
  final pdf = _pdfium(m.$1);
  final form = _formHandles.remove(m.$2);
  if (form != null) {
    pdf.FPDFDOC_ExitFormFillEnvironment(
      pb.FPDF_FORMHANDLE.fromAddress(form.$1),
    );
    calloc.free(Pointer<pb.FPDF_FORMFILLINFO>.fromAddress(form.$2));
  }
  final x = _stampXObjects.remove(m.$2);
  if (x != null) pdf.FPDF_CloseXObject(pb.FPDF_XOBJECT.fromAddress(x));
  pdf.FPDF_CloseDocument(_doc(m.$2));
  return true;
});

Future<(String?, bool?)> _save((String?, int, String, int) m) => _guard(() {
  _saveTo(_pdfium(m.$1), _doc(m.$2), m.$3, m.$4);
  return true;
});

typedef _WriteBlock =
    Int Function(Pointer<pb.FPDF_FILEWRITE>, Pointer<Void>, UnsignedLong);

void _saveTo(pb.PDFium pdf, pb.FPDF_DOCUMENT doc, String path, int flags) {
  final file = File(path).openSync(mode: FileMode.write);
  Object? error;
  int write(Pointer<pb.FPDF_FILEWRITE> self, Pointer<Void> data, int size) {
    try {
      file.writeFromSync(data.cast<Uint8>().asTypedList(size));
      return 1;
    } on Object catch (e) {
      error = e;
      return 0;
    }
  }

  final callable = NativeCallable<_WriteBlock>.isolateLocal(
    write,
    exceptionalReturn: 0,
  );
  final fw = calloc<pb.FPDF_FILEWRITE>();
  var ok = 0;
  try {
    fw.ref.version = 1;
    fw.ref.WriteBlock = callable.nativeFunction;
    ok = pdf.FPDF_SaveAsCopy(doc, fw, flags);
  } finally {
    callable.close();
    calloc.free(fw);
    file.closeSync();
  }
  final e = error;
  if (e is FileSystemException) throw e;
  if (ok == 0 || e != null) throw const _Fail('save');
}

// Assemble ------------------------------------------------------------------

Future<(String?, int?)> _begin(String? module) => _guard(() {
  final doc = _pdfium(module).FPDF_CreateNewDocument();
  if (doc == nullptr) throw const _Fail('create');
  _assembleSources[doc.address] = {};
  return doc.address;
});

Future<(String?, bool?)> _import(
  (String?, int, int, String, String?, List<int>) m,
) => _guard(() {
  final pdf = _pdfium(m.$1);
  final dest = _doc(m.$2);
  final opened = _assembleSources[m.$2]!;
  final src = opened[m.$3] ??= _load(pdf, m.$4, m.$5).address;
  final at = pdf.FPDF_GetPageCount(dest);
  final ok = using((arena) {
    final indices = arena<Int>(m.$6.length);
    for (var i = 0; i < m.$6.length; i++) {
      indices[i] = m.$6[i];
    }
    return pdf.FPDF_ImportPagesByIndex(
      dest,
      _doc(src),
      indices,
      m.$6.length,
      at,
    );
  });
  if (ok == 0) throw const _Fail('import');
  if (at == 0) pdf.FPDF_CopyViewerPreferences(dest, _doc(src));
  return true;
});

/// Inserts blank pages, applies rotations and saves.
Future<(String?, bool?)> _finish(
  (String?, int, List<(bool, int, double, double)>, String) m,
) => _guard(() {
  final pdf = _pdfium(m.$1);
  final dest = _doc(m.$2);
  final specs = m.$3;
  for (var i = 0; i < specs.length; i++) {
    final (blank, _, w, h) = specs[i];
    if (!blank) continue;
    final page = pdf.FPDFPage_New(dest, i, w, h);
    if (page == nullptr) throw const _Fail('blank');
    pdf.FPDF_ClosePage(page);
  }
  for (var i = 0; i < specs.length; i++) {
    final (blank, turns, _, _) = specs[i];
    if (blank || turns % 4 == 0) continue;
    final page = pdf.FPDF_LoadPage(dest, i);
    if (page == nullptr) continue;
    pdf
      ..FPDFPage_SetRotation(page, (pdf.FPDFPage_GetRotation(page) + turns) & 3)
      ..FPDF_ClosePage(page);
  }
  _saveTo(pdf, dest, m.$4, _saveFull);
  return true;
});

Future<(String?, bool?)> _end((String?, int) m) => _guard(() {
  final pdf = _pdfium(m.$1);
  for (final src in (_assembleSources.remove(m.$2) ?? const {}).values) {
    pdf.FPDF_CloseDocument(_doc(src));
  }
  pdf.FPDF_CloseDocument(_doc(m.$2));
  return true;
});

// Geometry -------------------------------------------------------------------

/// The page's visible box: crop box if set, else media box.
({double x0, double y0, double w, double h}) _box(
  pb.PDFium pdf,
  pb.FPDF_PAGE page,
) => using((arena) {
  final l = arena<Float>();
  final b = arena<Float>();
  final r = arena<Float>();
  final t = arena<Float>();
  if (pdf.FPDFPage_GetCropBox(page, l, b, r, t) != 0 ||
      pdf.FPDFPage_GetMediaBox(page, l, b, r, t) != 0) {
    return (
      x0: math.min(l.value, r.value),
      y0: math.min(b.value, t.value),
      w: (r.value - l.value).abs(),
      h: (t.value - b.value).abs(),
    );
  }
  return (
    x0: 0.0,
    y0: 0.0,
    w: pdf.FPDF_GetPageWidthF(page),
    h: pdf.FPDF_GetPageHeightF(page),
  );
});

/// Maps a point on the visible (rotated) page to page space.
(double, double) _toPage(
  ({double x0, double y0, double w, double h}) box,
  int rotation,
  double vx,
  double vy,
) {
  final (x, y) = switch (rotation & 3) {
    1 => (box.w - vy, vx),
    2 => (box.w - vx, box.h - vy),
    3 => (vy, box.h - vx),
    _ => (vx, vy),
  };
  return (box.x0 + x, box.y0 + y);
}

/// Where the centre of a stamp of [w] × [h] (already rotated extents) goes
/// on a visible page of [vw] × [vh].
(double, double) _anchor(
  StampPosition pos,
  double vw,
  double vh,
  double w,
  double h,
  double margin,
) {
  final left = margin + w / 2;
  final right = vw - margin - w / 2;
  final bottom = margin + h / 2;
  final top = vh - margin - h / 2;
  return switch (pos) {
    StampPosition.topLeft => (left, top),
    StampPosition.topCenter => (vw / 2, top),
    StampPosition.topRight => (right, top),
    StampPosition.center => (vw / 2, vh / 2),
    StampPosition.bottomLeft => (left, bottom),
    StampPosition.bottomCenter => (vw / 2, bottom),
    StampPosition.bottomRight => (right, bottom),
  };
}

Pointer<UnsignedShort> _wide(String text, Allocator alloc) {
  final units = text.codeUnits;
  final p = alloc<UnsignedShort>(units.length + 1);
  for (var i = 0; i < units.length; i++) {
    p[i] = units[i];
  }
  p[units.length] = 0;
  return p;
}

String _readWide(int Function(Pointer<UnsignedShort> buffer, int length) get) {
  final bytes = get(nullptr, 0);
  if (bytes <= 2) return '';
  final buf = calloc<UnsignedShort>(bytes ~/ 2);
  try {
    get(buf, bytes);
    final n = bytes ~/ 2 - 1;
    return String.fromCharCodes([for (var i = 0; i < n; i++) buf[i]]);
  } finally {
    calloc.free(buf);
  }
}

// Stamps ---------------------------------------------------------------------

Future<(String?, bool?)> _stampPages(
  (String?, int, List<int>, List<int>, int, StampSpec) m,
) => _guard(() {
  final pdf = _pdfium(m.$1);
  final doc = _doc(m.$2);
  final spec = m.$6;
  for (var k = 0; k < m.$3.length; k++) {
    final page = pdf.FPDF_LoadPage(doc, m.$3[k]);
    if (page == nullptr) throw const _Fail('page');
    try {
      final obj = spec.isImage
          ? _imageStampObject(pdf, doc, m.$2, spec)
          : _textStampObject(pdf, doc, spec, spec.textFor(m.$4[k], m.$5));
      if (obj == nullptr) continue;
      _place(pdf, page, obj, spec);
      if (pdf.FPDFPage_InsertObject(page, obj) == 0) {
        pdf.FPDFPageObj_Destroy(obj);
        throw const _Fail('insert');
      }
      if (pdf.FPDFPage_GenerateContent(page) == 0) {
        throw const _Fail('content');
      }
    } finally {
      pdf.FPDF_ClosePage(page);
    }
  }
  return true;
});

pb.FPDF_PAGEOBJECT _textStampObject(
  pb.PDFium pdf,
  pb.FPDF_DOCUMENT doc,
  StampSpec spec,
  String text,
) => using((arena) {
  // Standard 14 fonts are in every reader; WinAnsi covers Latin text.
  final font = spec.bold ? 'Helvetica-Bold' : 'Helvetica';
  final obj = pdf.FPDFPageObj_NewTextObj(
    doc,
    font.toNativeUtf8(allocator: arena).cast(),
    spec.fontSize,
  );
  if (obj == nullptr) throw const _Fail('text');
  pdf.FPDFText_SetText(obj, _wide(_winAnsiSafe(text), arena));
  final rgb = spec.colorRgb;
  pdf.FPDFPageObj_SetFillColor(
    obj,
    (rgb >> 16) & 0xFF,
    (rgb >> 8) & 0xFF,
    rgb & 0xFF,
    (spec.opacity * 255).round().clamp(0, 255),
  );
  return obj;
});

/// Replaces characters the standard fonts cannot draw.
String _winAnsiSafe(String text) =>
    String.fromCharCodes(text.runes.map(_winAnsiRune));

int _winAnsiRune(int r) => r < 0x20 ? 0x20 : (r > 0xFF ? 0x3F : r);

/// An image stamp, as a form object drawing one shared XObject, so a
/// watermark on 300 pages stores the picture once.
pb.FPDF_PAGEOBJECT _imageStampObject(
  pb.PDFium pdf,
  pb.FPDF_DOCUMENT doc,
  int docAddress,
  StampSpec spec,
) {
  final existing = _stampXObjects[docAddress];
  final xobject = existing != null
      ? pb.FPDF_XOBJECT.fromAddress(existing)
      : _buildImageXObject(pdf, doc, spec);
  _stampXObjects[docAddress] = xobject.address;
  return pdf.FPDF_NewFormObjectFromXObject(xobject);
}

pb.FPDF_XOBJECT _buildImageXObject(
  pb.PDFium pdf,
  pb.FPDF_DOCUMENT doc,
  StampSpec spec,
) {
  final w = spec.imageWidthPt;
  final h = w * spec.imageHeight / spec.imageWidth;
  final tmp = pdf.FPDF_CreateNewDocument();
  final page = pdf.FPDFPage_New(tmp, 0, w, h);
  final pixels = calloc<Uint8>(spec.imageWidth * spec.imageHeight * 4);
  try {
    final source = spec.imageBgra!;
    final alpha = spec.opacity.clamp(0, 1);
    final list = pixels.asTypedList(source.length);
    for (var i = 0; i < source.length; i += 4) {
      list[i] = source[i];
      list[i + 1] = source[i + 1];
      list[i + 2] = source[i + 2];
      list[i + 3] = (source[i + 3] * alpha).round();
    }
    final bitmap = pdf.FPDFBitmap_CreateEx(
      spec.imageWidth,
      spec.imageHeight,
      4, // FPDFBitmap_BGRA
      pixels.cast(),
      spec.imageWidth * 4,
    );
    final image = pdf.FPDFPageObj_NewImageObj(tmp);
    using((arena) {
      final pages = arena<pb.FPDF_PAGE>()..value = page;
      pdf.FPDFImageObj_SetBitmap(pages, 1, image, bitmap);
    });
    pdf
      ..FPDFBitmap_Destroy(bitmap)
      ..FPDFImageObj_SetMatrix(image, w, 0, 0, h, 0, 0)
      ..FPDFPage_InsertObject(page, image)
      ..FPDFPage_GenerateContent(page);
    final xobject = pdf.FPDF_NewXObjectFromPage(doc, tmp, 0);
    if (xobject == nullptr) throw const _Fail('xobject');
    return xobject;
  } finally {
    calloc.free(pixels);
    pdf
      ..FPDF_ClosePage(page)
      ..FPDF_CloseDocument(tmp);
  }
}

/// Rotates the object about its centre and moves it to its anchor, taking
/// the page's own rotation into account so it reads upright on screen.
void _place(
  pb.PDFium pdf,
  pb.FPDF_PAGE page,
  pb.FPDF_PAGEOBJECT obj,
  StampSpec spec,
) {
  final (l, b, r, t) = using((arena) {
    final l = arena<Float>();
    final b = arena<Float>();
    final r = arena<Float>();
    final t = arena<Float>();
    pdf.FPDFPageObj_GetBounds(obj, l, b, r, t);
    return (l.value, b.value, r.value, t.value);
  });
  final w = r - l;
  final h = t - b;
  final rotation = pdf.FPDFPage_GetRotation(page) & 3;
  final box = _box(pdf, page);
  final vw = rotation.isOdd ? box.h : box.w;
  final vh = rotation.isOdd ? box.w : box.h;
  final a = spec.angle * math.pi / 180;
  final ew = (w * math.cos(a)).abs() + (h * math.sin(a)).abs();
  final eh = (w * math.sin(a)).abs() + (h * math.cos(a)).abs();
  final (vx, vy) = _anchor(spec.position, vw, vh, ew, eh, spec.margin);
  final (px, py) = _toPage(box, rotation, vx, vy);
  final theta = a + rotation * math.pi / 2;
  final cos = math.cos(theta);
  final sin = math.sin(theta);
  pdf
    ..FPDFPageObj_Transform(obj, 1, 0, 0, 1, -(l + r) / 2, -(b + t) / 2)
    ..FPDFPageObj_Transform(obj, cos, sin, -sin, cos, 0, 0)
    ..FPDFPageObj_Transform(obj, 1, 0, 0, 1, px, py);
}

// Annotations ----------------------------------------------------------------

const _annotText = 1;
const _annotHighlight = 9;
const _annotUnderline = 10;
const _annotStrikeOut = 12;
const _annotInk = 15;
const _annotWidget = 20;
const _flagPrint = 4;

Future<(String?, bool?)> _annotatePage((String?, int, int, List<PdfMark>) m) =>
    _guard(() {
      final pdf = _pdfium(m.$1);
      final page = pdf.FPDF_LoadPage(_doc(m.$2), m.$3);
      if (page == nullptr) throw const _Fail('page');
      try {
        for (final mark in m.$4) {
          _addMark(pdf, page, mark);
        }
        _bakeAppearances(pdf, page);
      } finally {
        pdf.FPDF_ClosePage(page);
      }
      return true;
    });

void _addMark(pb.PDFium pdf, pb.FPDF_PAGE page, PdfMark mark) {
  final subtype = switch (mark) {
    TextMarkup(kind: MarkupKind.highlight) => _annotHighlight,
    TextMarkup(kind: MarkupKind.underline) => _annotUnderline,
    TextMarkup(kind: MarkupKind.strikeOut) => _annotStrikeOut,
    InkMark() => _annotInk,
    NoteMark() => _annotText,
  };
  final annot = pdf.FPDFPage_CreateAnnot(page, subtype);
  if (annot == nullptr) throw const _Fail('annot');
  try {
    final rgb = mark.colorRgb;
    pdf
      ..FPDFAnnot_SetColor(
        annot,
        pb.FPDFANNOT_COLORTYPE.FPDFANNOT_COLORTYPE_Color,
        (rgb >> 16) & 0xFF,
        (rgb >> 8) & 0xFF,
        rgb & 0xFF,
        255,
      )
      ..FPDFAnnot_SetFlags(annot, _flagPrint);
    using((arena) {
      final rect = arena<pb.FS_RECTF>();
      void setRect(double l, double b, double r, double t) {
        rect.ref
          ..left = l
          ..bottom = b
          ..right = r
          ..top = t;
        pdf.FPDFAnnot_SetRect(annot, rect);
      }

      switch (mark) {
        case TextMarkup(:final quads):
          final q = arena<pb.FS_QUADPOINTSF>();
          var (l, b, r, t) = (double.infinity, double.infinity, -1e9, -1e9);
          for (var i = 0; i + 7 < quads.length; i += 8) {
            q.ref
              ..x1 = quads[i]
              ..y1 = quads[i + 1]
              ..x2 = quads[i + 2]
              ..y2 = quads[i + 3]
              ..x3 = quads[i + 4]
              ..y3 = quads[i + 5]
              ..x4 = quads[i + 6]
              ..y4 = quads[i + 7];
            pdf.FPDFAnnot_AppendAttachmentPoints(annot, q);
            for (var j = 0; j < 8; j += 2) {
              l = math.min(l, quads[i + j]);
              r = math.max(r, quads[i + j]);
              b = math.min(b, quads[i + j + 1]);
              t = math.max(t, quads[i + j + 1]);
            }
          }
          setRect(l, b, r, t);
        case InkMark(:final strokes, :final width):
          var (l, b, r, t) = (double.infinity, double.infinity, -1e9, -1e9);
          for (final stroke in strokes) {
            final n = stroke.length ~/ 2;
            if (n == 0) continue;
            final pts = arena<pb.FS_POINTF>(n);
            for (var i = 0; i < n; i++) {
              final x = stroke[i * 2];
              final y = stroke[i * 2 + 1];
              pts[i]
                ..x = x
                ..y = y;
              l = math.min(l, x);
              r = math.max(r, x);
              b = math.min(b, y);
              t = math.max(t, y);
            }
            pdf.FPDFAnnot_AddInkStroke(annot, pts, n);
          }
          pdf.FPDFAnnot_SetBorder(annot, 0, 0, width);
          setRect(l - width, b - width, r + width, t + width);
        case NoteMark(:final x, :final y, :final text):
          setRect(x, y - 24, x + 24, y);
          pdf.FPDFAnnot_SetStringValue(
            annot,
            'Contents'.toNativeUtf8(allocator: arena).cast(),
            _wide(text, arena),
          );
      }
    });
  } finally {
    pdf.FPDFPage_CloseAnnot(annot);
  }
}

/// Rendering a page with annotations makes PDFium write an appearance
/// stream (/AP) into every new markup annotation, so readers that do not
/// generate their own (some versions of Acrobat) still show them.
void _bakeAppearances(pb.PDFium pdf, pb.FPDF_PAGE page) {
  final bitmap = pdf.FPDFBitmap_Create(4, 4, 0);
  if (bitmap == nullptr) return;
  pdf
    ..FPDF_RenderPageBitmap(bitmap, page, 0, 0, 4, 4, 0, 0x01) // FPDF_ANNOT
    ..FPDFBitmap_Destroy(bitmap);
}

// Forms ----------------------------------------------------------------------

(pb.FPDF_FORMHANDLE, Pointer<pb.FPDF_FORMFILLINFO>) _formEnv(
  pb.PDFium pdf,
  pb.FPDF_DOCUMENT doc,
) {
  final info = calloc<pb.FPDF_FORMFILLINFO>();
  info.ref.version = 1;
  final handle = pdf.FPDFDOC_InitFormFillEnvironment(doc, info);
  return (handle, info);
}

FormFieldKind? _kind(int type) => switch (type) {
  1 => FormFieldKind.button,
  2 => FormFieldKind.checkbox,
  3 => FormFieldKind.radio,
  4 => FormFieldKind.combo,
  5 => FormFieldKind.list,
  6 => FormFieldKind.text,
  7 => FormFieldKind.signature,
  _ => null,
};

Future<(String?, List<FormFieldInfo>?)> _readForm(
  (String?, String, String?) m,
) => _guard(() {
  final pdf = _pdfium(m.$1);
  final doc = _load(pdf, m.$2, m.$3);
  final (form, info) = _formEnv(pdf, doc);
  final fields = <FormFieldInfo>[];
  try {
    final count = pdf.FPDF_GetPageCount(doc);
    for (var p = 0; p < count; p++) {
      final page = pdf.FPDF_LoadPage(doc, p);
      if (page == nullptr) continue;
      pdf.FORM_OnAfterLoadPage(page, form);
      try {
        final annots = pdf.FPDFPage_GetAnnotCount(page);
        for (var a = 0; a < annots; a++) {
          final annot = pdf.FPDFPage_GetAnnot(page, a);
          if (annot == nullptr) continue;
          try {
            if (pdf.FPDFAnnot_GetSubtype(annot) != _annotWidget) continue;
            final kind = _kind(pdf.FPDFAnnot_GetFormFieldType(form, annot));
            if (kind == null) continue;
            final flags = pdf.FPDFAnnot_GetFormFieldFlags(form, annot);
            final options = <String>[];
            final selected = <int>[];
            if (kind == FormFieldKind.combo || kind == FormFieldKind.list) {
              final n = pdf.FPDFAnnot_GetOptionCount(form, annot);
              for (var i = 0; i < n; i++) {
                options.add(
                  _readWide(
                    (b, l) =>
                        pdf.FPDFAnnot_GetOptionLabel(form, annot, i, b, l),
                  ),
                );
                if (pdf.FPDFAnnot_IsOptionSelected(form, annot, i) != 0) {
                  selected.add(i);
                }
              }
            }
            final rect = using((arena) {
              final r = arena<pb.FS_RECTF>();
              pdf.FPDFAnnot_GetRect(annot, r);
              return (r.ref.left, r.ref.bottom, r.ref.right, r.ref.top);
            });
            fields.add(
              FormFieldInfo(
                page: p,
                annotIndex: a,
                kind: kind,
                name: _readWide(
                  (b, l) => pdf.FPDFAnnot_GetFormFieldName(form, annot, b, l),
                ),
                value: _readWide(
                  (b, l) => pdf.FPDFAnnot_GetFormFieldValue(form, annot, b, l),
                ),
                checked: pdf.FPDFAnnot_IsChecked(form, annot) != 0,
                options: options,
                selected: selected,
                left: math.min(rect.$1, rect.$3),
                bottom: math.min(rect.$2, rect.$4),
                right: math.max(rect.$1, rect.$3),
                top: math.max(rect.$2, rect.$4),
                readOnly: flags & 1 != 0,
                multiline: kind == FormFieldKind.text && flags & (1 << 12) != 0,
                exportValue: _readWide(
                  (b, l) =>
                      pdf.FPDFAnnot_GetFormFieldExportValue(form, annot, b, l),
                ),
              ),
            );
          } finally {
            pdf.FPDFPage_CloseAnnot(annot);
          }
        }
      } finally {
        pdf
          ..FORM_OnBeforeClosePage(page, form)
          ..FPDF_ClosePage(page);
      }
    }
  } finally {
    pdf
      ..FPDFDOC_ExitFormFillEnvironment(form)
      ..FPDF_CloseDocument(doc);
    calloc.free(info);
  }
  return fields;
});

Future<(String?, bool?)> _fillForm(
  (String?, int, List<FormFieldValue>, bool, int) m,
) => _guard(() {
  final pdf = _pdfium(m.$1);
  final doc = _doc(m.$2);
  final (form, info) = _formEnv(pdf, doc);
  _formHandles[m.$2] = (form.address, info.address);
  final byPage = <int, List<FormFieldValue>>{};
  for (final v in m.$3) {
    (byPage[v.page] ??= []).add(v);
  }
  final pages = m.$4 ? [for (var i = 0; i < m.$5; i++) i] : byPage.keys;
  for (final p in pages) {
    final page = pdf.FPDF_LoadPage(doc, p);
    if (page == nullptr) continue;
    pdf.FORM_OnAfterLoadPage(page, form);
    try {
      for (final v in byPage[p] ?? const <FormFieldValue>[]) {
        final annot = pdf.FPDFPage_GetAnnot(page, v.annotIndex);
        if (annot == nullptr) continue;
        try {
          _applyValue(pdf, form, page, annot, v);
        } finally {
          pdf.FPDFPage_CloseAnnot(annot);
        }
      }
      pdf.FORM_ForceToKillFocus(form);
      if (m.$4) {
        // Let the form filler finish appearances before flattening them.
        pdf
          ..FORM_OnBeforeClosePage(page, form)
          ..FPDFPage_Flatten(page, 0); // FLAT_NORMALDISPLAY
      } else {
        pdf.FORM_OnBeforeClosePage(page, form);
      }
    } finally {
      pdf.FPDF_ClosePage(page);
    }
  }
  return true;
});

void _applyValue(
  pb.PDFium pdf,
  pb.FPDF_FORMHANDLE form,
  pb.FPDF_PAGE page,
  pb.FPDF_ANNOTATION annot,
  FormFieldValue v,
) {
  if (v.text case final text?) {
    pdf
      ..FORM_SetFocusedAnnot(form, annot)
      ..FORM_SelectAllText(form, page);
    using((arena) => pdf.FORM_ReplaceSelection(form, page, _wide(text, arena)));
    pdf.FORM_ForceToKillFocus(form);
  } else if (v.checked case final checked?) {
    if ((pdf.FPDFAnnot_IsChecked(form, annot) != 0) == checked) return;
    final (x, y) = using((arena) {
      final r = arena<pb.FS_RECTF>();
      pdf.FPDFAnnot_GetRect(annot, r);
      return ((r.ref.left + r.ref.right) / 2, (r.ref.top + r.ref.bottom) / 2);
    });
    pdf
      ..FORM_OnMouseMove(form, page, 0, x, y)
      ..FORM_OnLButtonDown(form, page, 0, x, y)
      ..FORM_OnLButtonUp(form, page, 0, x, y)
      ..FORM_ForceToKillFocus(form);
  } else if (v.selectedIndex case final index?) {
    pdf
      ..FORM_SetFocusedAnnot(form, annot)
      ..FORM_SetIndexSelected(form, page, index, 1)
      ..FORM_ForceToKillFocus(form);
  }
}

// Compression ----------------------------------------------------------------

const _objImage = 3;

/// A cheap identity for an image's stored data.
int _imageKey(pb.PDFium pdf, pb.FPDF_PAGEOBJECT obj) {
  final length = pdf.FPDFImageObj_GetImageDataRaw(obj, nullptr, 0);
  if (length <= 0) return 0;
  final buf = calloc<Uint8>(length);
  try {
    pdf.FPDFImageObj_GetImageDataRaw(obj, buf.cast(), length);
    final bytes = buf.asTypedList(length);
    var hash = 0x811C9DC5;
    final step = math.max(1, length ~/ 4096);
    for (var i = 0; i < length; i += step) {
      hash = ((hash ^ bytes[i]) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash ^ (length << 1);
  } finally {
    calloc.free(buf);
  }
}

Future<(String?, List<int>?)> _imageKeys((String?, int, int, int) m) =>
    _guard(() {
      final pdf = _pdfium(m.$1);
      final keys = <int>[];
      for (var p = m.$3; p < m.$4; p++) {
        final page = pdf.FPDF_LoadPage(_doc(m.$2), p);
        if (page == nullptr) continue;
        final seenHere = <int>{};
        for (var i = 0; i < pdf.FPDFPage_CountObjects(page); i++) {
          final obj = pdf.FPDFPage_GetObject(page, i);
          if (pdf.FPDFPageObj_GetType(obj) != _objImage) continue;
          final key = _imageKey(pdf, obj);
          if (seenHere.add(key)) keys.add(key);
        }
        pdf.FPDF_ClosePage(page);
      }
      return keys;
    });

typedef _GetBlock =
    Int Function(
      Pointer<Void>,
      UnsignedLong,
      Pointer<UnsignedChar>,
      UnsignedLong,
    );

Future<(String?, (int, int)?)> _recompressPage(
  (String?, int, int, Set<int>, int, int) m,
) => _guard(() {
  final pdf = _pdfium(m.$1);
  final page = pdf.FPDF_LoadPage(_doc(m.$2), m.$3);
  if (page == nullptr) return (0, 0);
  var seen = 0;
  var changed = 0;
  try {
    for (var i = 0; i < pdf.FPDFPage_CountObjects(page); i++) {
      final obj = pdf.FPDFPage_GetObject(page, i);
      if (pdf.FPDFPageObj_GetType(obj) != _objImage) continue;
      seen++;
      if (pdf.FPDFPageObj_HasTransparency(obj) != 0) continue;
      final raw = pdf.FPDFImageObj_GetImageDataRaw(obj, nullptr, 0);
      if (raw < 64 * 1024) continue;
      if (m.$4.contains(_imageKey(pdf, obj))) continue;
      final jpeg = _encodeImageObject(pdf, page, obj, m.$5, m.$6);
      if (jpeg == null || jpeg.length >= raw * 0.9) continue;
      if (_loadJpeg(pdf, page, obj, jpeg)) changed++;
    }
    if (changed > 0 && pdf.FPDFPage_GenerateContent(page) == 0) {
      throw const _Fail('content');
    }
  } finally {
    pdf.FPDF_ClosePage(page);
  }
  return (seen, changed);
});

Uint8List? _encodeImageObject(
  pb.PDFium pdf,
  pb.FPDF_PAGE page,
  pb.FPDF_PAGEOBJECT obj,
  int maxEdge,
  int quality,
) {
  final meta = calloc<pb.FPDF_IMAGEOBJ_METADATA>();
  try {
    if (pdf.FPDFImageObj_GetImageMetadata(obj, page, meta) != 0 &&
        meta.ref.bits_per_pixel <= 1) {
      return null; // Masks and line art stay as they are.
    }
  } finally {
    calloc.free(meta);
  }
  final bitmap = pdf.FPDFImageObj_GetBitmap(obj);
  if (bitmap == nullptr) return null;
  try {
    final w = pdf.FPDFBitmap_GetWidth(bitmap);
    final h = pdf.FPDFBitmap_GetHeight(bitmap);
    final stride = pdf.FPDFBitmap_GetStride(bitmap);
    final format = pdf.FPDFBitmap_GetFormat(bitmap);
    if (w <= 0 || h <= 0) return null;
    final data = pdf.FPDFBitmap_GetBuffer(
      bitmap,
    ).cast<Uint8>().asTypedList(stride * h);
    final gray = format == 1;
    final bpp = switch (format) {
      1 => 1,
      2 => 3,
      _ => 4,
    };
    var image = img.Image(width: w, height: h, numChannels: gray ? 1 : 3);
    for (var y = 0; y < h; y++) {
      final row = y * stride;
      for (var x = 0; x < w; x++) {
        final o = row + x * bpp;
        if (gray) {
          image.setPixelRgb(x, y, data[o], data[o], data[o]);
        } else {
          image.setPixelRgb(x, y, data[o + 2], data[o + 1], data[o]);
        }
      }
    }
    final longest = math.max(w, h);
    if (longest > maxEdge) {
      image = img.copyResize(
        image,
        width: w >= h ? maxEdge : null,
        height: h > w ? maxEdge : null,
        interpolation: img.Interpolation.average,
      );
    }
    return img.encodeJpg(image, quality: quality);
  } finally {
    pdf.FPDFBitmap_Destroy(bitmap);
  }
}

bool _loadJpeg(
  pb.PDFium pdf,
  pb.FPDF_PAGE page,
  pb.FPDF_PAGEOBJECT obj,
  Uint8List jpeg,
) {
  int getBlock(
    Pointer<Void> param,
    int position,
    Pointer<UnsignedChar> buf,
    int size,
  ) {
    if (position + size > jpeg.length) return 0;
    buf.cast<Uint8>().asTypedList(size).setRange(0, size, jpeg, position);
    return 1;
  }

  final callable = NativeCallable<_GetBlock>.isolateLocal(
    getBlock,
    exceptionalReturn: 0,
  );
  final access = calloc<pb.FPDF_FILEACCESS>();
  final pages = calloc<pb.FPDF_PAGE>()..value = page;
  try {
    access.ref
      ..m_FileLen = jpeg.length
      ..m_GetBlock = callable.nativeFunction
      ..m_Param = nullptr;
    return pdf.FPDFImageObj_LoadJpegFileInline(pages, 1, obj, access) != 0;
  } finally {
    callable.close();
    calloc
      ..free(access)
      ..free(pages);
  }
}

Future<(String?, (String, Float64List, Float64List)?)> _pageChars(
  (String?, String, String?, int) m,
) => _guard(() {
  final pdf = _pdfium(m.$1);
  final doc = _load(pdf, m.$2, m.$3);
  try {
    final page = pdf.FPDF_LoadPage(doc, m.$4);
    if (page == nullptr) return ('', Float64List(0), Float64List(0));
    final textPage = pdf.FPDFText_LoadPage(page);
    try {
      if (textPage == nullptr) return ('', Float64List(0), Float64List(0));
      final box = _box(pdf, page);
      final count = math.max(0, pdf.FPDFText_CountChars(textPage));
      final text = StringBuffer();
      final boxes = Float64List(count * 4);
      final sizes = Float64List(count);
      using((arena) {
        final l = arena<Double>();
        final r = arena<Double>();
        final b = arena<Double>();
        final t = arena<Double>();
        final name = arena<Uint8>(96);
        final flags = arena<Int>();
        for (var i = 0; i < count; i++) {
          text.writeCharCode(pdf.FPDFText_GetUnicode(textPage, i));
          if (pdf.FPDFText_GetCharBox(textPage, i, l, r, b, t) != 0) {
            boxes
              ..[i * 4] = l.value - box.x0
              ..[i * 4 + 1] = b.value - box.y0
              ..[i * 4 + 2] = r.value - box.x0
              ..[i * 4 + 3] = t.value - box.y0;
          }
          final size = pdf.FPDFText_GetFontSize(textPage, i);
          var bold = pdf.FPDFText_GetFontWeight(textPage, i) >= 600;
          if (!bold) {
            final n = pdf.FPDFText_GetFontInfo(
              textPage,
              i,
              name.cast(),
              96,
              flags,
            );
            // n counts the closing zero; a longer name is not copied.
            if (n > 1 && n <= 96) {
              final s = String.fromCharCodes(name.asTypedList(n - 1));
              bold = s.toLowerCase().contains('bold');
            }
          }
          sizes[i] = bold ? -size : size;
        }
      });
      return (text.toString(), boxes, sizes);
    } finally {
      if (textPage != nullptr) pdf.FPDFText_ClosePage(textPage);
      pdf.FPDF_ClosePage(page);
    }
  } finally {
    pdf.FPDF_CloseDocument(doc);
  }
});

Future<(String?, List<(Uint8List, double, double, double, double)>?)>
_extractImages((String?, String, String?, int) m) => _guard(() {
  final pdf = _pdfium(m.$1);
  final doc = _load(pdf, m.$2, m.$3);
  final out = <(Uint8List, double, double, double, double)>[];
  try {
    final page = pdf.FPDF_LoadPage(doc, m.$4);
    if (page == nullptr) return out;
    try {
      final box = _box(pdf, page);
      for (var i = 0; i < pdf.FPDFPage_CountObjects(page); i++) {
        final obj = pdf.FPDFPage_GetObject(page, i);
        if (pdf.FPDFPageObj_GetType(obj) != _objImage) continue;
        final (l, b, r, t) = using((arena) {
          final l = arena<Float>();
          final b = arena<Float>();
          final r = arena<Float>();
          final t = arena<Float>();
          pdf.FPDFPageObj_GetBounds(obj, l, b, r, t);
          return (l.value, b.value, r.value, t.value);
        });
        if (r - l < 24 || t - b < 24) continue;
        final jpeg = _encodeImageObject(pdf, page, obj, 1600, 80);
        if (jpeg == null) continue;
        out.add((jpeg, l - box.x0, box.y0 + box.h - t, r - l, t - b));
        if (out.length >= 40) break;
      }
    } finally {
      pdf.FPDF_ClosePage(page);
    }
  } finally {
    pdf.FPDF_CloseDocument(doc);
  }
  return out;
});

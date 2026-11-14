import 'package:docnook/core/failures.dart';
import 'package:docnook/data/files/file_type_detector.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:meta/meta.dart';

/// Every tool in the Tools hub (S07) that runs through the tool flow.
enum ToolId {
  merge,
  split,
  organize,
  compress,
  protect,
  unlock,
  watermark,
  pageNumbers,
  sign,
  annotate,
  fillForms,
  redact,
  imagesToPdf,
  pdfToImages,
  pdfToText,
  wordToPdf,
  excelToPdf,
  pptToPdf,
  textToPdf,
  pdfToWord,
  csvExcel,
  extractText;

  static ToolId? byName(String name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }

  static const _images = {
    DocFormat.jpeg,
    DocFormat.png,
    DocFormat.webp,
    DocFormat.gif,
    DocFormat.bmp,
  };

  /// The formats this tool takes (BLUEPRINT 2.3, 2.4).
  Set<DocFormat> get accepts => switch (this) {
    merge => {DocFormat.pdf, ..._images},
    imagesToPdf || extractText => _images,
    wordToPdf => {DocFormat.docx, DocFormat.dotx, DocFormat.odt, DocFormat.rtf},
    excelToPdf => {
      DocFormat.xlsx,
      DocFormat.xlsm,
      DocFormat.ods,
      DocFormat.csv,
      DocFormat.tsv,
    },
    pptToPdf => {DocFormat.pptx},
    textToPdf => {DocFormat.plainText, DocFormat.code, DocFormat.markdown},
    csvExcel => {
      DocFormat.csv,
      DocFormat.tsv,
      DocFormat.xlsx,
      DocFormat.xlsm,
      DocFormat.ods,
    },
    _ => {DocFormat.pdf},
  };

  /// MIME types for the system picker.
  List<String> get pickerMimes => {
    for (final f in accepts) f.mime,
    if (accepts.any(_images.contains)) 'image/*',
  }.toList();

  /// Several files at once: Merge and Images → PDF combine them; the
  /// converters run them as a batch (BLUEPRINT 2.3).
  bool get multiple =>
      this == merge ||
      this == imagesToPdf ||
      this == pdfToImages ||
      this == wordToPdf ||
      this == excelToPdf ||
      this == pptToPdf;

  /// Batch converters: one output per input.
  bool get batch => multiple && this != merge && this != imagesToPdf;

  /// Tools with their own full-screen editor instead of an options form.
  bool get visual =>
      this == organize ||
      this == sign ||
      this == annotate ||
      this == fillForms ||
      this == redact;

  bool get converts => index >= imagesToPdf.index;

  /// Where the output goes inside Documents/DocNook.
  String get subdir => converts ? 'Converted' : 'Edited';

  /// How faithful the result is, shown before starting (FR-CONV-01).
  Fidelity? get fidelity => switch (this) {
    imagesToPdf || pdfToImages || textToPdf || pdfToText => Fidelity.full,
    wordToPdf || excelToPdf || csvExcel => Fidelity.good,
    pptToPdf || pdfToWord => Fidelity.basic,
    _ => null,
  };
}

/// A file a tool works on: what the picker or "Do more" hands over.
@immutable
final class ToolInput {
  const ToolInput({
    required this.uri,
    required this.name,
    this.mime,
    this.size,
    this.documentId,
  });

  /// File path or content URI.
  final String uri;
  final String name;
  final String? mime;
  final int? size;
  final int? documentId;

  DocFormat get format {
    final byName = FileTypeDetector.formatForExtension(
      FileTypeDetector.extensionOf(name),
    );
    if (byName != null) return byName;
    if ((mime ?? '').startsWith('image/')) return DocFormat.jpeg;
    if (mime == 'application/pdf') return DocFormat.pdf;
    return DocFormat.unknown;
  }

  DocType get type => format.docType;

  /// True when the original can be replaced in place ("overwrite").
  bool get overwritable => !uri.startsWith('content://');
}

/// One file a tool wrote.
@immutable
final class ToolOutput {
  const ToolOutput({
    required this.uri,
    required this.name,
    required this.bytes,
    this.pages,
    this.documentId,
    this.mime = 'application/pdf',
  });

  final String uri;
  final String name;
  final int bytes;
  final int? pages;
  final int? documentId;
  final String mime;

  ToolInput get asInput => ToolInput(
    uri: uri,
    name: name,
    mime: mime,
    size: bytes,
    documentId: documentId,
  );
}

/// What a finished tool shows on S11.
@immutable
final class ToolResult {
  const ToolResult({
    required this.tool,
    required this.outputs,
    this.inputBytes,
    this.failures = const [],
    this.overwritten = false,
  });

  final ToolId tool;
  final List<ToolOutput> outputs;

  /// Size before, for "4.8 MB → 1.3 MB (−73%)".
  final int? inputBytes;

  /// Inputs of a batch that could not be used, with the reason.
  final List<(String, DocNookFailure)> failures;
  final bool overwritten;

  int get totalBytes => outputs.fold(0, (s, o) => s + o.bytes);
}

enum CompressLevel { light, balanced, strong }

/// One area to redact: page index and the box as fractions of the visible
/// page (left, top, right, bottom; top-left origin).
@immutable
final class RedactBox {
  const RedactBox(this.page, this.left, this.top, this.right, this.bottom);
  final int page;
  final double left;
  final double top;
  final double right;
  final double bottom;
}

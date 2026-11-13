import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:meta/meta.dart';

/// Every tool in the Tools hub (S07).
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
  redact;

  static ToolId? byName(String name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }

  /// Merge takes several files and accepts pictures too.
  bool get multiple => this == merge;
  bool get acceptsImages => this == merge;

  /// Tools with their own full-screen editor instead of an options form.
  bool get visual =>
      this == organize ||
      this == sign ||
      this == annotate ||
      this == fillForms ||
      this == redact;
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

  DocType get type {
    final lower = name.toLowerCase();
    if ((mime ?? '').startsWith('image/') ||
        RegExp(r'\.(jpe?g|png|webp|gif|bmp|heic|heif)$').hasMatch(lower)) {
      return DocType.image;
    }
    return DocType.pdf;
  }

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
  });

  final String uri;
  final String name;
  final int bytes;
  final int? pages;
  final int? documentId;

  ToolInput get asInput => ToolInput(
    uri: uri,
    name: name,
    mime: 'application/pdf',
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

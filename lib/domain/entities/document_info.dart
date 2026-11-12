import 'package:docnook/domain/entities/doc_type.dart';

/// Where a document came from (stored in `documents.source`).
enum DocSource { discovered, picked, intent, created, scanned }

/// A document DocNook knows about. Pure data for the UI and use cases.
final class DocumentInfo {
  const DocumentInfo({
    required this.id,
    required this.uri,
    required this.name,
    required this.type,
    required this.source,
    this.extension,
    this.mime,
    this.sizeBytes,
    this.modifiedAt,
    this.lastOpenedAt,
    this.pageCount,
    this.progress,
    this.starred = false,
    this.encrypted = false,
    this.missing = false,
    this.indexed = false,
    this.thumbKey,
  });

  final int id;

  /// Absolute path or `content://` URI.
  final String uri;
  final String name;
  final DocType type;
  final DocSource source;
  final String? extension;
  final String? mime;
  final int? sizeBytes;
  final DateTime? modifiedAt;
  final DateTime? lastOpenedAt;
  final int? pageCount;

  /// Reading progress 0–1, when the document has been opened.
  final double? progress;
  final bool starred;
  final bool encrypted;
  final bool missing;
  final bool indexed;
  final String? thumbKey;

  bool get isContentUri => uri.startsWith('content://');
}

/// Saved place in a document (FR-READ-03). Fields depend on the viewer:
/// PDF uses page/offset/zoom, sheets use sheet/row/col, EPUB chapter/offset,
/// DocModel viewers use block.
final class ReadingPosition {
  const ReadingPosition({
    this.page,
    this.offset,
    this.zoom,
    this.sheet,
    this.row,
    this.col,
    this.chapter,
    this.block,
  });

  factory ReadingPosition.fromJson(Map<String, Object?> json) =>
      ReadingPosition(
        page: (json['page'] as num?)?.toInt(),
        offset: (json['offset'] as num?)?.toDouble(),
        zoom: (json['zoom'] as num?)?.toDouble(),
        sheet: (json['sheet'] as num?)?.toInt(),
        row: (json['row'] as num?)?.toInt(),
        col: (json['col'] as num?)?.toInt(),
        chapter: (json['chapter'] as num?)?.toInt(),
        block: (json['block'] as num?)?.toInt(),
      );

  final int? page;
  final double? offset;
  final double? zoom;
  final int? sheet;
  final int? row;
  final int? col;
  final int? chapter;
  final int? block;

  Map<String, Object?> toJson() => {
    'page': ?page,
    'offset': ?offset,
    'zoom': ?zoom,
    'sheet': ?sheet,
    'row': ?row,
    'col': ?col,
    'chapter': ?chapter,
    'block': ?block,
  };
}

import 'package:meta/meta.dart';

/// Where Read Aloud gets its text (FR-READ-06). A viewer splits its document
/// into units it can highlight and scroll to: PDF pages, document blocks,
/// text lines, EPUB paragraphs.
abstract interface class ReadAloudSource {
  /// Number of units in reading order.
  int get unitCount;

  /// The plain text of unit [unit]; offsets in it are what the viewer
  /// highlights.
  Future<String> unitText(int unit);
}

/// The sentence being read: characters [start]..[end] of unit [unit].
@immutable
final class ReadAloudSpot {
  const ReadAloudSpot(this.unit, this.start, this.end);
  final int unit;
  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is ReadAloudSpot &&
      other.unit == unit &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(unit, start, end);
}

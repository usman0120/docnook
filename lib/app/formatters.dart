import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:intl/intl.dart';

/// Plain, specific copy for sizes, dates and file facts (BLUEPRINT 9.4).
extension Formatters on AppLocalizations {
  /// "2.1 MB", "640 KB", "12 B".
  String fileSize(int bytes) {
    if (bytes < 1024) return sizeBytes(bytes);
    const units = ['KB', 'MB', 'GB'];
    var value = bytes / 1024;
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final text = value >= 100 || unit == 0
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return '$text ${units[unit]}';
  }

  /// "Just now", "5 min ago", "Today", "Yesterday", "12 Nov", "12 Nov 2024".
  String relativeDate(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = current.difference(time);
    if (diff.inMinutes < 1 && !diff.isNegative) return timeJustNow;
    if (diff.inMinutes < 60 && !diff.isNegative) {
      return timeMinutesAgo(diff.inMinutes);
    }
    final today = DateTime(current.year, current.month, current.day);
    final day = DateTime(time.year, time.month, time.day);
    final days = today.difference(day).inDays;
    if (days == 0) return timeToday;
    if (days == 1) return timeYesterday;
    return time.year == current.year
        ? DateFormat('d MMM').format(time)
        : DateFormat('d MMM y').format(time);
  }

  /// "PDF · 24 pages · Yesterday".
  String documentDetails(DocumentInfo doc) {
    final parts = <String>[_typeName(doc)];
    if (doc.pageCount != null &&
        doc.pageCount! > 0 &&
        doc.type == DocType.pdf) {
      parts.add(pagesCount(doc.pageCount!));
    } else if (doc.sizeBytes != null) {
      parts.add(fileSize(doc.sizeBytes!));
    }
    final when = doc.lastOpenedAt ?? doc.modifiedAt;
    if (when != null) parts.add(relativeDate(when));
    return parts.join(' · ');
  }

  String _typeName(DocumentInfo doc) {
    final ext = doc.extension;
    if (ext != null && ext.isNotEmpty && ext.length <= 5) {
      return ext.toUpperCase();
    }
    return switch (doc.type) {
      DocType.pdf => 'PDF',
      DocType.word => 'Word',
      DocType.sheet => 'Sheet',
      DocType.slides => 'Slides',
      DocType.text => 'Text',
      DocType.markdown => 'Markdown',
      DocType.epub => 'EPUB',
      DocType.image => 'Image',
      DocType.archive => 'ZIP',
      DocType.other => 'File',
    };
  }

  /// One title and one explanation per failure (BLUEPRINT 5.2).
  (String title, String body) failureText(DocNookFailure failure) =>
      switch (failure.kind) {
        FailureKind.unsupported => (errUnsupportedTitle, errUnsupportedBody),
        FailureKind.corrupt when failure.debugDetail == 'missing' => (
          errMissingTitle,
          errMissingBody,
        ),
        FailureKind.corrupt => (errCorruptTitle, errCorruptBody),
        FailureKind.passwordRequired ||
        FailureKind.wrongPassword => (errPasswordTitle, errPasswordBody),
        FailureKind.tooLarge => (errTooLargeTitle, errUnknownBody),
        FailureKind.permissionDenied => (errPermissionTitle, errPermissionBody),
        FailureKind.outOfSpace => (errOutOfSpaceTitle, errOutOfSpaceBody),
        FailureKind.cancelled ||
        FailureKind.unknown => (errUnknownTitle, errUnknownBody),
      };
}

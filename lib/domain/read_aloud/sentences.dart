import 'package:meta/meta.dart';

/// A sentence inside a piece of text: `text.substring(start, end)`.
@immutable
final class SentenceSpan {
  const SentenceSpan(this.start, this.end);
  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is SentenceSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'SentenceSpan($start, $end)';
}

/// Words whose trailing full stop does not end a sentence.
const _abbreviations = {
  'mr',
  'mrs',
  'ms',
  'dr',
  'prof',
  'st',
  'sr',
  'jr',
  'vs',
  'etc',
  'e.g',
  'i.e',
  'eg',
  'ie',
  'no',
  'fig',
  'figs',
  'inc',
  'ltd',
  'co',
  'corp',
  'dept',
  'approx',
  'est',
  'vol',
  'p',
  'pp',
  'ch',
  'sec',
  'jan',
  'feb',
  'mar',
  'apr',
  'jun',
  'jul',
  'aug',
  'sep',
  'sept',
  'oct',
  'nov',
  'dec',
  'mt',
  'ave',
  'rd',
};

/// Longest piece handed to the speech engine at once; longer sentences are
/// cut at a comma or space so highlighting keeps moving and engines with
/// short input limits still speak them.
const maxSentenceChars = 320;

/// Splits [text] into sentences for Read Aloud (FR-READ-06). A sentence ends
/// at `.`, `!`, `?` or `…` followed by a space (closing quotes and brackets
/// stay with it), at a blank line, or at a line that starts a list item.
/// Abbreviations ("Dr.", "e.g."), initials ("J. Smith") and decimals ("3.5")
/// do not end a sentence. Spans exclude surrounding white space, and pieces
/// with no letters or digits are skipped.
List<SentenceSpan> splitSentences(String text) {
  final out = <SentenceSpan>[];
  var start = 0;
  final n = text.length;

  void emit(int end) {
    var s = start;
    var e = end;
    while (s < e && _isSpace(text.codeUnitAt(s))) {
      s++;
    }
    while (e > s && _isSpace(text.codeUnitAt(e - 1))) {
      e--;
    }
    if (e > s && _hasWordChar(text, s, e)) _addCapped(out, text, s, e);
    start = end;
  }

  var i = 0;
  while (i < n) {
    final ch = text[i];
    if (ch == '\n') {
      // Blank line, or a new line starting a list item: a hard break.
      var j = i + 1;
      while (j < n && (text[j] == ' ' || text[j] == '\t' || text[j] == '\r')) {
        j++;
      }
      if (j >= n || text[j] == '\n' || _startsListItem(text, j)) {
        emit(i);
        i = j;
        continue;
      }
      i++;
      continue;
    }
    if (ch == '.' || ch == '!' || ch == '?' || ch == '…') {
      var j = i + 1;
      // Runs like "?!" or "..." and closing quotes or brackets.
      while (j < n && '.!?…"\'”’)]»'.contains(text[j])) {
        j++;
      }
      final atEnd = j >= n;
      if (atEnd || _isSpace(text.codeUnitAt(j))) {
        if (ch != '.' || !_notASentenceEnd(text, start, i, j)) {
          emit(j);
          i = j;
          continue;
        }
      }
      i = j;
      continue;
    }
    i++;
  }
  emit(n);
  return out;
}

bool _isSpace(int c) =>
    c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D || c == 0xA0;

bool _hasWordChar(String text, int s, int e) {
  for (var i = s; i < e; i++) {
    final c = text.codeUnitAt(i);
    if ((c >= 0x30 && c <= 0x39) ||
        (c >= 0x41 && c <= 0x5A) ||
        (c >= 0x61 && c <= 0x7A) ||
        c >= 0xC0) {
      return true;
    }
  }
  return false;
}

bool _startsListItem(String text, int j) {
  final c = text[j];
  if ('•▪◦‣-*–—'.contains(c)) return true;
  // "1." / "12)" style numbering.
  var k = j;
  while (k < text.length && k - j < 4 && _isDigit(text.codeUnitAt(k))) {
    k++;
  }
  return k > j && k < text.length && (text[k] == '.' || text[k] == ')');
}

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

/// True when the full stop at [dot] belongs to an abbreviation, an initial
/// or a number rather than ending the sentence. [after] is the index just
/// past the punctuation run.
bool _notASentenceEnd(String text, int start, int dot, int after) {
  // The word before the full stop.
  var w = dot;
  while (w > start && !_isSpace(text.codeUnitAt(w - 1))) {
    w--;
  }
  final word = text
      .substring(w, dot)
      .toLowerCase()
      .replaceAll(RegExp(r'^[("“‘\[]+'), '');
  if (word.isEmpty) return false;
  if (_abbreviations.contains(word)) return true;
  // A single capital letter: an initial ("J. Smith").
  if (word.length == 1 && RegExp('[a-z]').hasMatch(word)) {
    final original = text[dot - 1];
    if (original.toUpperCase() == original) return true;
  }
  // The next word starts in lower case: a mid-sentence abbreviation.
  var k = after;
  while (k < text.length && _isSpace(text.codeUnitAt(k))) {
    k++;
  }
  if (k < text.length) {
    final next = text[k];
    if (next.toLowerCase() == next && next.toUpperCase() != next) return true;
  }
  return false;
}

/// Adds [s]..[e], cut into pieces of at most [maxSentenceChars] at the last
/// comma, semicolon or space before the limit.
void _addCapped(List<SentenceSpan> out, String text, int from, int e) {
  var s = from;
  while (e - s > maxSentenceChars) {
    final limit = s + maxSentenceChars;
    var cut = -1;
    for (var k = limit; k > s + maxSentenceChars ~/ 2; k--) {
      final c = text[k - 1];
      if (c == ',' || c == ';' || c == ':') {
        cut = k;
        break;
      }
    }
    if (cut < 0) {
      for (var k = limit; k > s + 1; k--) {
        if (_isSpace(text.codeUnitAt(k - 1))) {
          cut = k;
          break;
        }
      }
    }
    if (cut < 0) cut = limit;
    var pieceEnd = cut;
    while (pieceEnd > s && _isSpace(text.codeUnitAt(pieceEnd - 1))) {
      pieceEnd--;
    }
    if (pieceEnd > s) out.add(SentenceSpan(s, pieceEnd));
    s = cut;
    while (s < e && _isSpace(text.codeUnitAt(s))) {
      s++;
    }
  }
  if (e > s) out.add(SentenceSpan(s, e));
}

/// [text] cleaned for the speech engine: line breaks become spaces and
/// words split by a hyphen at a line end are joined.
String speakable(String text) => text
    .replaceAllMapped(RegExp(r'(\w)-\r?\n(\w)'), (m) => '${m[1]}${m[2]}')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

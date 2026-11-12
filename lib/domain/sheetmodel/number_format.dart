import 'package:docnook/domain/sheetmodel/sheet_model.dart';

/// Renders cell values with Excel number-format codes (`#,##0.00`, `0%`,
/// `dd/mm/yyyy`, `[$€-407] #,##0`, …). Covers the formats real spreadsheets
/// use; exotic ones (fractions, conditional sections) fall back to General.
abstract final class NumberFormatter {
  static final Map<String, _Format> _cache = {};

  /// Format codes for Excel's built-in format ids (ECMA-376 18.8.30).
  /// Id 14 is locale-dependent in Excel; DocNook shows day first.
  static String builtinCode(int id) => switch (id) {
    0 => 'General',
    1 => '0',
    2 => '0.00',
    3 => '#,##0',
    4 => '#,##0.00',
    9 => '0%',
    10 => '0.00%',
    11 => '0.00E+00',
    12 => '# ?/?',
    13 => '# ??/??',
    14 => 'dd/mm/yyyy',
    15 => 'd-mmm-yy',
    16 => 'd-mmm',
    17 => 'mmm-yy',
    18 => 'h:mm AM/PM',
    19 => 'h:mm:ss AM/PM',
    20 => 'h:mm',
    21 => 'h:mm:ss',
    22 => 'dd/mm/yyyy h:mm',
    37 => '#,##0;(#,##0)',
    38 => '#,##0;(#,##0)',
    39 => '#,##0.00;(#,##0.00)',
    40 => '#,##0.00;(#,##0.00)',
    45 => 'mm:ss',
    46 => '[h]:mm:ss',
    47 => 'mm:ss.0',
    48 => '##0.0E+0',
    49 => '@',
    _ => 'General',
  };

  static _Format _parsed(String code) {
    if (_cache.length > 2000) _cache.clear();
    return _cache.putIfAbsent(code, () => _Format.parse(code));
  }

  static bool isDateFormat(String code) => _parsed(code).isDate;

  /// The text shown in the grid for [value] under [code].
  static String format(Object? value, String code, {bool date1904 = false}) {
    switch (value) {
      case null:
        return '';
      case final String text:
        return _parsed(code).formatText(text);
      case final bool flag:
        return flag ? 'TRUE' : 'FALSE';
      case final CellError error:
        return error.code;
      case final num number:
        if (number.isNaN || number.isInfinite) return '#NUM!';
        return _parsed(code).formatNumber(number.toDouble(), date1904);
      default:
        return value.toString();
    }
  }

  /// Excel's "General" format: whole numbers plainly, others to at most 10
  /// significant digits, very large or small ones in scientific notation.
  static String general(double value) {
    if (value == 0) return '0';
    final abs = value.abs();
    if (value == value.roundToDouble() && abs < 1e15) {
      return value.toInt().toString();
    }
    if (abs >= 1e11 || abs < 1e-9) {
      final parts = value.toStringAsExponential(5).split('e');
      final mantissa = _trimZeros(parts[0]);
      final exponent = int.parse(parts[1]);
      final sign = exponent < 0 ? '-' : '+';
      return '${mantissa}E$sign${exponent.abs().toString().padLeft(2, '0')}';
    }
    final text = value.toStringAsPrecision(10);
    return text.contains('e') ? _trimZeros(value.toString()) : _trimZeros(text);
  }

  static String _trimZeros(String text) {
    if (!text.contains('.')) return text;
    var end = text.length;
    while (end > 0 && text.codeUnitAt(end - 1) == 0x30) {
      end--;
    }
    if (end > 0 && text.codeUnitAt(end - 1) == 0x2E) end--;
    return text.substring(0, end);
  }

  /// Converts an Excel date serial to a calendar date-time (no time zone).
  static DateTime serialToDate(double serial, {bool date1904 = false}) {
    final epoch = date1904 ? DateTime.utc(1904) : DateTime.utc(1899, 12, 30);
    final millis = (serial * 86400000).round();
    return epoch.add(Duration(milliseconds: millis));
  }
}

enum _T {
  literal,
  digit, // 0 # ?
  point,
  comma,
  percent,
  exponent,
  text, // @
  year,
  month, // may become minute after resolution
  minute,
  day,
  hour,
  second,
  subSecond,
  ampm,
  elapsedH,
  elapsedM,
  elapsedS,
}

final class _Tok {
  _Tok(this.type, this.text);
  _T type;
  final String text;
}

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', //
  'August', 'September', 'October', 'November', 'December',
];
const _days = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday', //
];

final class _Section {
  _Section(this.tokens) {
    var seenPoint = false;
    var lastDigit = -1;
    var firstDigit = -1;
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      switch (t.type) {
        case _T.digit:
          if (firstDigit < 0) firstDigit = i;
          lastDigit = i;
          if (isScientific) {
            // Placeholders after "E+" size the exponent, not the mantissa.
          } else if (seenPoint) {
            maxDecimals++;
            if (t.text == '0') minDecimals = maxDecimals;
          } else if (t.text == '0') {
            minIntegers++;
          }
        case _T.point:
          if (!isDate) seenPoint = true;
        case _T.percent:
          percents++;
        case _T.exponent:
          isScientific = true;
        case _T.text:
          hasText = true;
        case _T.year ||
            _T.month ||
            _T.minute ||
            _T.day ||
            _T.hour ||
            _T.second ||
            _T.ampm ||
            _T.elapsedH ||
            _T.elapsedM ||
            _T.elapsedS:
          isDate = true;
        case _T.literal || _T.comma || _T.subSecond:
          break;
      }
    }
    firstNumberToken = firstDigit;
    lastNumberToken = lastDigit;
    hasDigits = firstDigit >= 0;

    if (hasDigits && !isDate) {
      // Commas between digit placeholders group thousands; commas directly
      // after the last integer placeholder scale by 1000 each.
      var i = firstDigit;
      var lastIntegerDigit = firstDigit;
      for (; i <= lastDigit; i++) {
        if (tokens[i].type == _T.point) break;
        if (tokens[i].type == _T.digit) lastIntegerDigit = i;
      }
      for (var j = firstDigit; j < lastIntegerDigit; j++) {
        if (tokens[j].type == _T.comma) grouping = true;
      }
      void countScale(int after) {
        for (var j = after + 1; j < tokens.length; j++) {
          if (tokens[j].type != _T.comma) break;
          scaleThousands++;
          if (j > lastNumberToken) lastNumberToken = j;
        }
      }

      countScale(lastIntegerDigit);
      if (lastDigit != lastIntegerDigit) countScale(lastDigit);
      isFraction =
          tokens.any((t) => t.type == _T.literal && t.text == '/') &&
          tokens.where((t) => t.type == _T.digit).length >= 2 &&
          !seenPoint;
    }
    if (isDate) {
      twelveHour = tokens.any((t) => t.type == _T.ampm);
    }
  }

  final List<_Tok> tokens;
  bool isDate = false;
  bool isScientific = false;
  bool isFraction = false;
  bool hasText = false;
  bool hasDigits = false;
  bool grouping = false;
  bool twelveHour = false;
  int percents = 0;
  int scaleThousands = 0;
  int minIntegers = 0;
  int minDecimals = 0;
  int maxDecimals = 0;
  int firstNumberToken = -1;
  int lastNumberToken = -1;
}

final class _Format {
  _Format(this.sections, {required this.isGeneral});

  factory _Format.parse(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'general') {
      return _Format(const [], isGeneral: true);
    }
    final sections = <_Section>[];
    for (final part in _splitSections(trimmed)) {
      sections.add(_Section(_tokenize(part)));
    }
    return _Format(sections, isGeneral: false);
  }

  final List<_Section> sections;
  final bool isGeneral;

  bool get isDate => sections.isNotEmpty && sections.first.isDate;

  static List<String> _splitSections(String code) {
    final parts = <String>[];
    final current = StringBuffer();
    var inQuote = false;
    var inBracket = false;
    for (var i = 0; i < code.length; i++) {
      final ch = code[i];
      if (ch == r'\' && !inQuote && i + 1 < code.length) {
        current
          ..write(ch)
          ..write(code[++i]);
        continue;
      }
      if (ch == '"') inQuote = !inQuote;
      if (!inQuote) {
        if (ch == '[') inBracket = true;
        if (ch == ']') inBracket = false;
        if (ch == ';' && !inBracket) {
          parts.add(current.toString());
          current.clear();
          continue;
        }
      }
      current.write(ch);
    }
    parts.add(current.toString());
    return parts;
  }

  static List<_Tok> _tokenize(String part) {
    final tokens = <_Tok>[];
    void literal(String text) {
      if (tokens.isNotEmpty && tokens.last.type == _T.literal) {
        final merged = _Tok(_T.literal, tokens.last.text + text);
        tokens[tokens.length - 1] = merged;
      } else {
        tokens.add(_Tok(_T.literal, text));
      }
    }

    final lower = part.toLowerCase();
    var i = 0;
    while (i < part.length) {
      final ch = part[i];
      final lc = lower[i];

      if (ch == '"') {
        final end = part.indexOf('"', i + 1);
        final stop = end < 0 ? part.length : end;
        literal(part.substring(i + 1, stop));
        i = stop + 1;
      } else if (ch == r'\') {
        if (i + 1 < part.length) literal(part[i + 1]);
        i += 2;
      } else if (ch == '_') {
        literal(' '); // "leave the width of the next character"
        i += 2;
      } else if (ch == '*') {
        i += 2; // repeat-to-fill: no meaning without a fixed cell width
      } else if (ch == '[') {
        final end = part.indexOf(']', i);
        if (end < 0) {
          i++;
          continue;
        }
        final inner = part.substring(i + 1, end);
        final innerLower = inner.toLowerCase();
        if (innerLower.isNotEmpty && RegExp(r'^h+$').hasMatch(innerLower)) {
          tokens.add(_Tok(_T.elapsedH, inner));
        } else if (innerLower.isNotEmpty &&
            RegExp(r'^m+$').hasMatch(innerLower)) {
          tokens.add(_Tok(_T.elapsedM, inner));
        } else if (innerLower.isNotEmpty &&
            RegExp(r'^s+$').hasMatch(innerLower)) {
          tokens.add(_Tok(_T.elapsedS, inner));
        } else if (inner.startsWith(r'$')) {
          // [$€-407]: currency symbol, then an ignored locale id.
          final dash = inner.indexOf('-');
          final symbol = inner.substring(1, dash < 0 ? inner.length : dash);
          if (symbol.isNotEmpty) literal(symbol);
        }
        // Colours ([Red]) and conditions ([>100]) are ignored.
        i = end + 1;
      } else if (ch == '0' || ch == '#' || ch == '?') {
        tokens.add(_Tok(_T.digit, ch));
        i++;
      } else if (ch == '.') {
        // ".0" straight after seconds means fractions of a second.
        if (tokens.isNotEmpty &&
            tokens.last.type == _T.second &&
            i + 1 < part.length &&
            part[i + 1] == '0') {
          var j = i + 1;
          while (j < part.length && part[j] == '0') {
            j++;
          }
          tokens.add(_Tok(_T.subSecond, part.substring(i + 1, j)));
          i = j;
        } else {
          tokens.add(_Tok(_T.point, ch));
          i++;
        }
      } else if (ch == ',') {
        tokens.add(_Tok(_T.comma, ch));
        i++;
      } else if (ch == '%') {
        tokens.add(_Tok(_T.percent, ch));
        literal('%');
        i++;
      } else if (ch == '@') {
        tokens.add(_Tok(_T.text, ch));
        i++;
      } else if (lc == 'e' &&
          i + 1 < part.length &&
          (part[i + 1] == '+' || part[i + 1] == '-') &&
          tokens.any((t) => t.type == _T.digit)) {
        tokens.add(_Tok(_T.exponent, part.substring(i, i + 2)));
        i += 2;
      } else if (lower.startsWith('am/pm', i)) {
        tokens.add(_Tok(_T.ampm, part.substring(i, i + 5)));
        i += 5;
      } else if (lower.startsWith('a/p', i)) {
        tokens.add(_Tok(_T.ampm, part.substring(i, i + 3)));
        i += 3;
      } else if (lc == 'y' ||
          lc == 'm' ||
          lc == 'd' ||
          lc == 'h' ||
          lc == 's') {
        var j = i;
        while (j < part.length && lower[j] == lc) {
          j++;
        }
        final run = lower.substring(i, j);
        tokens.add(
          _Tok(switch (lc) {
            'y' => _T.year,
            'm' => _T.month,
            'd' => _T.day,
            'h' => _T.hour,
            _ => _T.second,
          }, run),
        );
        i = j;
      } else {
        literal(ch);
        i++;
      }
    }

    // "m" means minutes right after hours or right before seconds.
    final dateIndexes = [
      for (var k = 0; k < tokens.length; k++)
        if (tokens[k].type.index >= _T.year.index) k,
    ];
    for (var n = 0; n < dateIndexes.length; n++) {
      final token = tokens[dateIndexes[n]];
      if (token.type != _T.month || token.text.length > 2) continue;
      final previous = n > 0 ? tokens[dateIndexes[n - 1]].type : null;
      final next = n + 1 < dateIndexes.length
          ? tokens[dateIndexes[n + 1]].type
          : null;
      if (previous == _T.hour ||
          previous == _T.elapsedH ||
          next == _T.second ||
          next == _T.subSecond) {
        token.type = _T.minute;
      }
    }
    return tokens;
  }

  String formatText(String text) {
    if (isGeneral) return text;
    // A fourth section, or any section containing "@", formats text.
    final section = sections.length >= 4
        ? sections[3]
        : (sections.length == 1 && sections.first.hasText
              ? sections.first
              : null);
    if (section == null) return text;
    final out = StringBuffer();
    for (final token in section.tokens) {
      if (token.type == _T.literal) out.write(token.text);
      if (token.type == _T.text) out.write(text);
    }
    return out.toString();
  }

  String formatNumber(double value, bool date1904) {
    if (isGeneral) return NumberFormatter.general(value);

    _Section section;
    var magnitude = value;
    var autoMinus = false;
    if (sections.length == 1) {
      section = sections[0];
      if (value < 0) {
        autoMinus = true;
        magnitude = -value;
      }
    } else if (value > 0) {
      section = sections[0];
    } else if (value < 0) {
      section = sections[1];
      magnitude = -value;
    } else {
      section = sections.length > 2 ? sections[2] : sections[0];
    }

    if (section.isDate) {
      // Negative dates cannot be shown; Excel prints hashes.
      if (value < 0) return '########';
      return _formatDate(section, value, date1904);
    }
    if (!section.hasDigits) {
      // Literal-only section, e.g. "-" for zero, or "@" applied to a number.
      final out = StringBuffer();
      for (final token in section.tokens) {
        if (token.type == _T.literal) out.write(token.text);
        if (token.type == _T.text) out.write(NumberFormatter.general(value));
      }
      return out.toString();
    }
    if (section.isFraction) {
      return (autoMinus ? '-' : '') + NumberFormatter.general(magnitude);
    }

    final String digits;
    if (section.isScientific) {
      digits = _scientific(section, magnitude);
    } else {
      var scaled = magnitude;
      for (var i = 0; i < section.percents; i++) {
        scaled *= 100;
      }
      for (var i = 0; i < section.scaleThousands; i++) {
        scaled /= 1000;
      }
      digits = _fixed(section, scaled);
    }

    final out = StringBuffer();
    if (autoMinus && _isNonZero(digits)) out.write('-');
    for (var i = 0; i < section.tokens.length; i++) {
      final token = section.tokens[i];
      if (i == section.firstNumberToken) out.write(digits);
      if (i >= section.firstNumberToken && i <= section.lastNumberToken) {
        // Literals inside the number span (rare) are kept after the digits.
        if (token.type == _T.literal) out.write(token.text);
        continue;
      }
      if (token.type == _T.literal) out.write(token.text);
    }
    return out.toString();
  }

  static bool _isNonZero(String digits) {
    for (var i = 0; i < digits.length; i++) {
      final c = digits.codeUnitAt(i);
      if (c >= 0x31 && c <= 0x39) return true;
    }
    return false;
  }

  static String _fixed(_Section s, double value) {
    final text = value.toStringAsFixed(s.maxDecimals > 20 ? 20 : s.maxDecimals);
    final dot = text.indexOf('.');
    var integer = dot < 0 ? text : text.substring(0, dot);
    var fraction = dot < 0 ? '' : text.substring(dot + 1);

    // Optional decimals (#) drop trailing zeros down to the required count.
    var end = fraction.length;
    while (end > s.minDecimals && fraction.codeUnitAt(end - 1) == 0x30) {
      end--;
    }
    fraction = fraction.substring(0, end);

    if (integer == '0' && s.minIntegers == 0) integer = '';
    if (integer.length < s.minIntegers) {
      integer = integer.padLeft(s.minIntegers, '0');
    }
    if (s.grouping && integer.length > 3) {
      final grouped = StringBuffer();
      final lead = integer.length % 3;
      if (lead > 0) grouped.write(integer.substring(0, lead));
      for (var i = lead; i < integer.length; i += 3) {
        if (grouped.isNotEmpty) grouped.write(',');
        grouped.write(integer.substring(i, i + 3));
      }
      integer = grouped.toString();
    }
    return fraction.isEmpty ? integer : '$integer.$fraction';
  }

  static String _scientific(_Section s, double value) {
    final parts = value.toStringAsExponential(s.maxDecimals).split('e');
    final exponent = int.parse(parts[1]);
    final exponentToken = s.tokens.firstWhere((t) => t.type == _T.exponent);
    final sign = exponent < 0
        ? '-'
        : (exponentToken.text.endsWith('+') ? '+' : '');
    return '${parts[0]}E$sign${exponent.abs().toString().padLeft(2, '0')}';
  }

  static String _formatDate(_Section s, double serial, bool date1904) {
    // Round to the precision the format shows, so 0.99999 s is not "59".
    final subDigits = s.tokens
        .where((t) => t.type == _T.subSecond)
        .fold(0, (max, t) => t.text.length > max ? t.text.length : max);
    final hasSeconds = s.tokens.any(
      (t) => t.type == _T.second || t.type == _T.elapsedS,
    );
    var unitMs = hasSeconds ? 1000.0 : 60000.0;
    for (var i = 0; i < subDigits && i < 3; i++) {
      unitMs /= 10;
    }
    final totalMs = ((serial * 86400000) / unitMs).round() * unitMs;
    final roundedSerial = totalMs / 86400000;
    final date = NumberFormatter.serialToDate(
      roundedSerial,
      date1904: date1904,
    );

    final out = StringBuffer();
    for (final token in s.tokens) {
      final n = token.text.length;
      switch (token.type) {
        case _T.literal:
          out.write(token.text);
        case _T.year:
          out.write(
            n <= 2
                ? (date.year % 100).toString().padLeft(2, '0')
                : '${date.year}',
          );
        case _T.month:
          out.write(switch (n) {
            1 => '${date.month}',
            2 => date.month.toString().padLeft(2, '0'),
            3 => _months[date.month - 1].substring(0, 3),
            5 => _months[date.month - 1].substring(0, 1),
            _ => _months[date.month - 1],
          });
        case _T.day:
          out.write(switch (n) {
            1 => '${date.day}',
            2 => date.day.toString().padLeft(2, '0'),
            3 => _days[date.weekday - 1].substring(0, 3),
            _ => _days[date.weekday - 1],
          });
        case _T.hour:
          var hour = date.hour;
          if (s.twelveHour) hour = hour % 12 == 0 ? 12 : hour % 12;
          out.write(n >= 2 ? hour.toString().padLeft(2, '0') : '$hour');
        case _T.minute:
          out.write(
            n >= 2 ? date.minute.toString().padLeft(2, '0') : '${date.minute}',
          );
        case _T.second:
          out.write(
            n >= 2 ? date.second.toString().padLeft(2, '0') : '${date.second}',
          );
        case _T.subSecond:
          final fraction = date.millisecond.toString().padLeft(3, '0');
          out.write('.${fraction.substring(0, n > 3 ? 3 : n)}');
        case _T.ampm:
          final pm = date.hour >= 12;
          out.write(
            token.text.length == 3 ? (pm ? 'P' : 'A') : (pm ? 'PM' : 'AM'),
          );
        case _T.elapsedH:
          out.write((totalMs / 3600000).floor().toString().padLeft(n, '0'));
        case _T.elapsedM:
          out.write((totalMs / 60000).floor().toString().padLeft(n, '0'));
        case _T.elapsedS:
          out.write((totalMs / 1000).floor().toString().padLeft(n, '0'));
        case _T.digit ||
            _T.point ||
            _T.comma ||
            _T.percent ||
            _T.exponent ||
            _T.text:
          if (token.type == _T.point || token.type == _T.comma)
            out.write(token.text);
      }
    }
    return out.toString();
  }
}

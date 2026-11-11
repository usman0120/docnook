import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/engines/office/xml_events.dart';

final class _Level {
  int start = 1;
  String format = 'decimal';
  String text = '%1.';
}

/// List definitions (`word/numbering.xml`) and the running counters that
/// turn them into marker text such as "•", "3." or "2.1.a)".
final class DocxNumbering {
  DocxNumbering._();

  factory DocxNumbering.parse(String? xml) {
    final numbering = DocxNumbering._();
    if (xml == null) return numbering;
    final pull = XmlPull(xml);
    final root = pull.find('numbering');
    if (root == null) return numbering;

    pull.children(root, (child) {
      if (child.localName == 'abstractNum') {
        final id = child.attr('w:abstractNumId');
        if (id == null) return;
        final levels = <int, _Level>{};
        pull.children(child, (lvl) {
          if (lvl.localName != 'lvl') return;
          final index = int.tryParse(lvl.attr('w:ilvl') ?? '') ?? 0;
          final level = _Level();
          pull.children(lvl, (p) {
            switch (p.localName) {
              case 'start':
                level.start = int.tryParse(p.attr('w:val') ?? '') ?? 1;
              case 'numFmt':
                level.format = p.attr('w:val') ?? 'decimal';
              case 'lvlText':
                level.text = p.attr('w:val') ?? '';
            }
          });
          levels[index] = level;
        });
        numbering._abstract[id] = levels;
      } else if (child.localName == 'num') {
        final id = child.attr('w:numId');
        if (id == null) return;
        final overrides = <int, int>{};
        pull.children(child, (n) {
          if (n.localName == 'abstractNumId') {
            numbering._numToAbstract[id] = n.attr('w:val') ?? '';
          } else if (n.localName == 'lvlOverride') {
            final index = int.tryParse(n.attr('w:ilvl') ?? '') ?? 0;
            pull.children(n, (o) {
              if (o.localName == 'startOverride') {
                final start = int.tryParse(o.attr('w:val') ?? '');
                if (start != null) overrides[index] = start;
              }
            });
          }
        });
        if (overrides.isNotEmpty) numbering._overrides[id] = overrides;
      }
    });
    return numbering;
  }

  final Map<String, Map<int, _Level>> _abstract = {};
  final Map<String, String> _numToAbstract = {};
  final Map<String, Map<int, int>> _overrides = {};

  /// Current value per level, keyed by abstract list so that lists sharing a
  /// definition continue each other, as Word does.
  final Map<String, List<int?>> _counters = {};
  final Set<String> _restarted = {};

  /// Advances the list and returns the marker for its next item, or null
  /// when the list is unknown.
  ListInfo? next(String numId, int level) {
    final abstractId = _numToAbstract[numId];
    final levels = abstractId == null ? null : _abstract[abstractId];
    if (levels == null) return null;
    final lvl = level.clamp(0, 8);
    final def = levels[lvl] ?? _Level();

    final counters = _counters.putIfAbsent(abstractId!, () => List.filled(9, null));
    // A list instance with a start override restarts the shared counter the
    // first time it appears.
    final override = _overrides[numId]?[lvl];
    if (override != null && _restarted.add('$numId/$lvl')) {
      counters[lvl] = override - 1;
    }
    counters[lvl] = (counters[lvl] ?? def.start - 1) + 1;
    for (var deeper = lvl + 1; deeper < 9; deeper++) {
      counters[deeper] = null;
    }

    if (def.format == 'bullet') {
      return ListInfo(level: lvl, marker: _bullet(def.text));
    }
    if (def.format == 'none') {
      return ListInfo(level: lvl, marker: '');
    }

    final marker = def.text.replaceAllMapped(RegExp('%([1-9])'), (match) {
      final index = int.parse(match.group(1)!) - 1;
      final value = counters[index] ?? (levels[index]?.start ?? 1);
      return formatCounter(value, levels[index]?.format ?? 'decimal');
    });
    return ListInfo(level: lvl, marker: marker, ordered: true);
  }

  static String _bullet(String text) {
    if (text.isEmpty) return '•';
    final code = text.runes.first;
    return switch (code) {
      0xF0B7 || 0x00B7 || 0x2022 => '•',
      0x6F => '◦', // "o" in Courier New is Word's hollow bullet
      0xF0A7 || 0x25AA => '▪',
      0xF0FC || 0x2713 => '✓',
      0xF0D8 => '➢',
      0x2D || 0x2013 || 0x2014 => '–',
      _ => code >= 0xE000 && code <= 0xF8FF ? '•' : String.fromCharCode(code),
    };
  }

  /// Formats a counter in a WordprocessingML number format.
  static String formatCounter(int value, String format) => switch (format) {
    'lowerLetter' => _letters(value).toLowerCase(),
    'upperLetter' => _letters(value),
    'lowerRoman' => _roman(value).toLowerCase(),
    'upperRoman' => _roman(value),
    'decimalZero' => value.toString().padLeft(2, '0'),
    'none' => '',
    _ => '$value',
  };

  /// 1 → A, 26 → Z, 27 → AA, 28 → BB (Word repeats the letter).
  static String _letters(int value) {
    if (value < 1) return '$value';
    final letter = String.fromCharCode(0x41 + (value - 1) % 26);
    return letter * ((value - 1) ~/ 26 + 1);
  }

  static String _roman(int value) {
    if (value < 1 || value > 3999) return '$value';
    const numerals = [
      (1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'), (100, 'C'), (90, 'XC'),
      (50, 'L'), (40, 'XL'), (10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I'), //
    ];
    final out = StringBuffer();
    var rest = value;
    for (final (amount, numeral) in numerals) {
      while (rest >= amount) {
        out.write(numeral);
        rest -= amount;
      }
    }
    return out.toString();
  }
}

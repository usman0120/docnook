import 'dart:async';

import 'package:docnook/data/platform/tts_engine.dart';
import 'package:docnook/domain/read_aloud/read_aloud_source.dart';
import 'package:docnook/domain/read_aloud/sentences.dart';
import 'package:docnook/features/viewer/read_aloud/read_aloud_controller.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _split(String text) => [
  for (final s in splitSentences(text)) text.substring(s.start, s.end),
];

/// Speaks instantly unless [hold] is set; records what was spoken.
class _FakeEngine implements TtsEngine {
  _FakeEngine({this.problem});
  final TtsProblem? problem;
  final spoken = <String>[];
  final speeds = <double>[];
  bool hold = false;
  Completer<bool>? _current;

  @override
  Future<TtsProblem?> prepare() async => problem;

  @override
  Future<bool> speak(String text, {required double speed}) {
    spoken.add(text);
    speeds.add(speed);
    if (!hold) return Future.value(true);
    return (_current = Completer<bool>()).future;
  }

  /// Finishes the sentence being held.
  void finish() => _current?.complete(true);

  @override
  Future<void> stop() async {
    final c = _current;
    _current = null;
    if (c != null && !c.isCompleted) c.complete(true);
  }
}

class _Source implements ReadAloudSource {
  _Source(this.units);
  final List<String> units;

  @override
  int get unitCount => units.length;

  @override
  Future<String> unitText(int unit) async => units[unit];
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('sentences', () {
    test('split at end punctuation and keep closing quotes', () {
      expect(_split('One. Two! "Three?" Four'), [
        'One.',
        'Two!',
        '"Three?"',
        'Four',
      ]);
    });

    test('abbreviations, initials and decimals do not end a sentence', () {
      expect(
        _split(
          'Dr. Khan paid 3.50 to J. Smith, e.g. for tea. Next one starts.',
        ),
        ['Dr. Khan paid 3.50 to J. Smith, e.g. for tea.', 'Next one starts.'],
      );
    });

    test('blank lines and list items break; wrapped lines do not', () {
      expect(
        _split(
          'A wrapped\nline continues\n\nNew paragraph\n- item one\n2. two',
        ),
        ['A wrapped\nline continues', 'New paragraph', '- item one', '2. two'],
      );
    });

    test('very long sentences are cut at a comma or space', () {
      final long = List.filled(80, 'word, more').join(' ');
      final spans = splitSentences(long);
      expect(spans.length, greaterThan(1));
      for (final s in spans) {
        expect(s.end - s.start, lessThanOrEqualTo(maxSentenceChars));
      }
      expect(spans.last.end, long.length);
    });

    test('pieces without letters are skipped and offsets are exact', () {
      const text = '  ---  \n\nHello there.   ';
      final spans = splitSentences(text);
      expect(spans, hasLength(1));
      expect(
        text.substring(spans.single.start, spans.single.end),
        'Hello there.',
      );
    });

    test('speakable joins hyphenated line ends and line breaks', () {
      expect(speakable('docu-\nment is\nhere'), 'document is here');
    });
  });

  group('controller', () {
    test(
      'reads every sentence of every unit in order, then finishes',
      () async {
        final engine = _FakeEngine();
        final rc = ReadAloudController(engine);
        await rc.start(_Source(['One. Two.', '', 'Three.']));
        await _settle();
        expect(engine.spoken, ['One.', 'Two.', 'Three.']);
        expect(rc.finished, isTrue);
        expect(rc.playing, isFalse);
        rc.dispose();
      },
    );

    test('highlights the sentence being read and can skip and pause', () async {
      final engine = _FakeEngine()..hold = true;
      final rc = ReadAloudController(engine);
      await rc.start(_Source(['Alpha one. Beta two.', 'Gamma three.']));
      await _settle();
      expect(rc.spot, const ReadAloudSpot(0, 0, 10));
      await rc.next();
      await _settle();
      expect(rc.spot, const ReadAloudSpot(0, 11, 20));
      await rc.next();
      await _settle();
      expect(rc.spot, const ReadAloudSpot(1, 0, 12));
      await rc.previous();
      await _settle();
      expect(rc.spot, const ReadAloudSpot(0, 11, 20));
      await rc.pause();
      expect(rc.playing, isFalse);
      final count = engine.spoken.length;
      await _settle();
      expect(engine.spoken.length, count);
      rc.dispose();
    });

    test('speed changes restart the sentence and are remembered', () async {
      final engine = _FakeEngine()..hold = true;
      double? saved;
      final rc = ReadAloudController(engine, onSpeedChanged: (s) => saved = s);
      await rc.start(_Source(['Only sentence.']));
      await _settle();
      await rc.setSpeed(1.5);
      await _settle();
      expect(saved, 1.5);
      expect(engine.spoken, ['Only sentence.', 'Only sentence.']);
      expect(engine.speeds.last, 1.5);
      engine.finish();
      await _settle();
      expect(rc.finished, isTrue);
      rc.dispose();
    });

    test('no voice installed is reported instead of playing', () async {
      final engine = _FakeEngine(problem: TtsProblem.noVoice);
      final rc = ReadAloudController(engine);
      await rc.start(_Source(['Text.']));
      expect(rc.problem, TtsProblem.noVoice);
      expect(rc.playing, isFalse);
      expect(engine.spoken, isEmpty);
      rc.dispose();
    });

    test('close stops and clears the highlight', () async {
      final engine = _FakeEngine()..hold = true;
      final rc = ReadAloudController(engine);
      await rc.start(_Source(['One. Two.']));
      await _settle();
      await rc.close();
      expect(rc.active, isFalse);
      expect(rc.spot, isNull);
      rc.dispose();
    });
  });
}

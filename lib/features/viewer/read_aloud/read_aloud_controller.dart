import 'dart:async';

import 'package:docnook/data/platform/tts_engine.dart';
import 'package:docnook/domain/read_aloud/read_aloud_source.dart';
import 'package:docnook/domain/read_aloud/sentences.dart';
import 'package:flutter/foundation.dart';

/// Speeds offered on the Read Aloud bar (S35).
const readAloudSpeeds = [0.75, 1.0, 1.25, 1.5, 2.0];

/// Read Aloud (FR-READ-06, S35): speaks a [ReadAloudSource] one sentence at
/// a time and reports the sentence being read so the viewer can highlight it
/// and scroll to it. One controller per open viewer.
class ReadAloudController extends ChangeNotifier {
  ReadAloudController(this._engine, {double speed = 1.0, this.onSpeedChanged})
    : _speed = speed;

  final TtsEngine _engine;

  /// Called when the user picks another speed, to remember it.
  final void Function(double speed)? onSpeedChanged;

  ReadAloudSource? _source;
  int _unit = 0;
  String _text = '';
  List<SentenceSpan>? _sentences;
  int _index = 0;
  int _run = 0;
  bool _disposed = false;

  bool _active = false;
  bool _playing = false;
  bool _preparing = false;
  bool _finished = false;
  double _speed;
  ReadAloudSpot? _spot;
  TtsProblem? _problem;

  /// The bar is showing.
  bool get active => _active;
  bool get playing => _playing;

  /// Waiting for the speech engine or the first text.
  bool get preparing => _preparing;

  /// Reached the end of the document.
  bool get finished => _finished;
  double get speed => _speed;

  /// The sentence being read, for highlighting.
  ReadAloudSpot? get spot => _spot;
  TtsProblem? get problem => _problem;

  /// Opens the bar and starts reading [source] at unit [fromUnit].
  Future<void> start(ReadAloudSource source, {int fromUnit = 0}) async {
    _stopRun();
    _source = source;
    _active = true;
    _finished = false;
    _problem = null;
    _preparing = true;
    _notify();
    final problem = await _engine.prepare();
    if (_disposed || !_active) return;
    _preparing = false;
    if (problem != null) {
      _problem = problem;
      _notify();
      return;
    }
    await _moveTo(fromUnit.clamp(0, source.unitCount), 0);
    await play();
  }

  Future<void> play() async {
    if (_source == null || _playing || _problem != null) return;
    if (_finished) {
      _finished = false;
      await _moveTo(0, 0);
    }
    _playing = true;
    _notify();
    unawaited(_loop(++_run));
  }

  Future<void> pause() async {
    if (!_playing) return;
    _stopRun();
    _playing = false;
    _notify();
    await _engine.stop();
  }

  Future<void> next() => _skip(1);

  Future<void> previous() => _skip(-1);

  Future<void> setSpeed(double speed) async {
    if (speed == _speed) return;
    _speed = speed;
    onSpeedChanged?.call(speed);
    _notify();
    // Restart the current sentence at the new speed.
    if (_playing) {
      _stopRun();
      await _engine.stop();
      unawaited(_loop(++_run));
    }
  }

  /// Hides the bar and stops speaking.
  Future<void> close() async {
    _stopRun();
    _active = false;
    _playing = false;
    _preparing = false;
    _spot = null;
    _problem = null;
    _source = null;
    _notify();
    await _engine.stop();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopRun();
    unawaited(_engine.stop());
    super.dispose();
  }

  // ------------------------------------------------------------- internals

  void _stopRun() => _run++;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Loads unit [unit] and points at sentence [index] (negative counts from
  /// the end). Skips units without sentences in the direction of travel.
  Future<bool> _moveTo(int unit, int at, {int direction = 1}) async {
    final source = _source;
    if (source == null) return false;
    var u = unit;
    var index = at;
    while (u >= 0 && u < source.unitCount) {
      final text = await source.unitText(u);
      if (_disposed) return false;
      final sentences = splitSentences(text);
      if (sentences.isNotEmpty) {
        _unit = u;
        _text = text;
        _sentences = sentences;
        _index = index < 0
            ? sentences.length + index
            : index.clamp(0, sentences.length - 1);
        return true;
      }
      u += direction;
      index = direction > 0 ? 0 : -1;
    }
    return false;
  }

  Future<void> _skip(int delta) async {
    if (_source == null || _sentences == null) return;
    final wasPlaying = _playing;
    _stopRun();
    if (wasPlaying) await _engine.stop();
    final target = _index + delta;
    var moved = true;
    if (target >= 0 && target < _sentences!.length) {
      _index = target;
    } else if (delta > 0) {
      moved = await _moveTo(_unit + 1, 0);
    } else {
      moved = await _moveTo(_unit - 1, -1, direction: -1);
    }
    if (!moved) {
      // Past either end: stay on the current sentence.
      if (delta > 0 && wasPlaying) {
        _finish();
        return;
      }
    }
    _finished = false;
    _showCurrent();
    if (wasPlaying) unawaited(_loop(++_run));
  }

  void _showCurrent() {
    final sentences = _sentences;
    if (sentences == null || sentences.isEmpty) return;
    final s = sentences[_index];
    _spot = ReadAloudSpot(_unit, s.start, s.end);
    _notify();
  }

  void _finish() {
    _playing = false;
    _finished = true;
    _notify();
  }

  Future<void> _loop(int run) async {
    while (run == _run && _playing) {
      final sentences = _sentences;
      if (sentences == null) {
        _finish();
        return;
      }
      if (_index >= sentences.length) {
        if (!await _moveTo(_unit + 1, 0)) {
          if (run == _run) _finish();
          return;
        }
        if (run != _run) return;
        continue;
      }
      _showCurrent();
      final s = sentences[_index];
      final ok = await _engine.speak(
        speakable(_text.substring(s.start, s.end)),
        speed: _speed,
      );
      if (run != _run) return;
      if (!ok) {
        _problem = TtsProblem.failed;
        _playing = false;
        _notify();
        return;
      }
      _index++;
    }
  }
}

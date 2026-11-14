import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Why speech can't start.
enum TtsProblem {
  /// No text-to-speech engine, or no voice that works offline.
  noVoice,

  /// The engine refused or failed to speak.
  failed,
}

/// The phone's text-to-speech engine (FR-READ-06). Only offline voices are
/// used, so Read Aloud never needs the internet.
abstract class TtsEngine {
  /// Prepares an offline voice. Returns null when ready, else the problem.
  Future<TtsProblem?> prepare();

  /// Speaks [text] at [speed] (1.0 = normal) and completes when it has been
  /// spoken (true), stopped (true) or failed (false).
  Future<bool> speak(String text, {required double speed});

  /// Stops speaking at once; a pending [speak] completes.
  Future<void> stop();
}

final ttsEngineProvider = Provider<TtsEngine>((ref) => FlutterTtsEngine());

class FlutterTtsEngine implements TtsEngine {
  FlutterTts? _tts;
  Completer<bool>? _pending;
  bool _ready = false;

  /// The current utterance has started. A late "stopped" or "done" signal
  /// from the previous utterance arrives before this turns true and is
  /// ignored, so it can't end the next sentence early.
  bool _started = false;

  FlutterTts get _engine {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = FlutterTts();
    void done(bool ok, {bool always = false}) {
      if (!_started && !always) return;
      final pending = _pending;
      _pending = null;
      if (pending != null && !pending.isCompleted) pending.complete(ok);
    }

    tts
      ..setStartHandler(() => _started = true)
      ..setCompletionHandler(() => done(true))
      ..setCancelHandler(() => done(true))
      ..setErrorHandler((_) => done(false, always: true));
    return _tts = tts;
  }

  @override
  Future<TtsProblem?> prepare() async {
    if (_ready) return null;
    final tts = _engine;
    try {
      final engines = await tts.getEngines;
      if (engines is List && engines.isEmpty) return TtsProblem.noVoice;
      final voices = await tts.getVoices;
      final offline = <Map<Object?, Object?>>[
        if (voices is List)
          for (final v in voices)
            if (v is Map && v['network_required'] != '1') v,
      ];
      if (offline.isEmpty) return TtsProblem.noVoice;
      // DocNook is English; prefer the engine's default voice when it works
      // offline, else any offline English voice.
      final current = await tts.getDefaultVoice;
      final currentOk =
          current is Map &&
          offline.any((v) => v['name'] == current['name']) &&
          '${current['locale']}'.toLowerCase().startsWith('en');
      if (!currentOk) {
        final english = offline.where(
          (v) => '${v['locale']}'.toLowerCase().startsWith('en'),
        );
        if (english.isEmpty) return TtsProblem.noVoice;
        final pick = english.firstWhere(
          (v) => '${v['locale']}'.toLowerCase() == 'en-us',
          orElse: () => english.first,
        );
        await tts.setVoice({
          'name': '${pick['name']}',
          'locale': '${pick['locale']}',
        });
      }
      await tts.awaitSpeakCompletion(false);
      _ready = true;
      return null;
    } on Object {
      return TtsProblem.failed;
    }
  }

  @override
  Future<bool> speak(String text, {required double speed}) async {
    final tts = _engine;
    final previous = _pending;
    if (previous != null && !previous.isCompleted) previous.complete(true);
    final pending = _pending = Completer<bool>();
    _started = false;
    try {
      // flutter_tts doubles the rate on Android: 0.5 is normal speed.
      await tts.setSpeechRate((speed / 2).clamp(0.1, 1.0));
      final queued = await tts.speak(text);
      if (queued != 1 && !pending.isCompleted) pending.complete(false);
    } on Object {
      if (!pending.isCompleted) pending.complete(false);
    }
    return await pending.future;
  }

  @override
  Future<void> stop() async {
    final pending = _pending;
    _pending = null;
    try {
      await _tts?.stop();
    } on Object {
      // Nothing to stop.
    }
    if (pending != null && !pending.isCompleted) pending.complete(true);
  }
}

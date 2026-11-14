import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Timing marks for the Phase 9 performance pass (NFR-PERF-02..04).
///
/// Active only in profile builds (`flutter run --profile`); release and debug
/// builds do nothing. Lines carry a label and milliseconds only: never a file
/// name, path or content (CLAUDE.md rule 11).
abstract final class Perf {
  static Stopwatch? _open;

  /// A document open started (the viewer host received the request).
  static void openStarted() {
    if (kProfileMode) _open = Stopwatch()..start();
  }

  /// The viewer has its content; logs once the next frame is on screen.
  static void contentShown(String kind) {
    if (!kProfileMode) return;
    final watch = _open;
    _open = null;
    if (watch == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      debugPrint('DocNookPerf open $kind ${watch.elapsedMilliseconds} ms');
    });
  }
}

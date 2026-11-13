import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:docnook/core/failures.dart';
import 'package:docnook/core/result.dart';

/// Progress of a running job: 0–1 and an optional step label.
final class JobProgress {
  const JobProgress(this.value, [this.label]);
  final double value;
  final String? label;
}

/// What a job body can do from inside its isolate.
final class JobContext {
  JobContext._(this._port);

  final SendPort? _port;
  final _clock = Stopwatch()..start();
  int _lastSentMs = -1000;

  /// Reports progress. Calls are throttled to one message per 60 ms, except
  /// the first and the final (1.0) one.
  void progress(double value, [String? label]) {
    final port = _port;
    if (port == null) return;
    final now = _clock.elapsedMilliseconds;
    if (value < 1 && now - _lastSentMs < 60) return;
    _lastSentMs = now;
    port.send(_ProgressMessage(value.clamp(0, 1).toDouble(), label));
  }

  /// A context that reports nowhere, for running a body inline in tests.
  static JobContext detached() => JobContext._(null);
}

/// Work that runs in an isolate. Must be a top-level or static function, and
/// [A] and [R] must be sendable between isolates (plain data).
typedef JobBody<A, R> = FutureOr<R> Function(A args, JobContext context);

/// A started job. [cancel] stops it at once: the isolate is killed, so a body
/// must write to a temporary file and move it into place only when done.
final class JobHandle<R> {
  JobHandle._(this.result, this.progress, this._cancel);

  /// Completes with the value, or the failure (including `cancelled`).
  final Future<Result<R>> result;
  final Stream<JobProgress> progress;
  final void Function() _cancel;

  void cancel() => _cancel();
}

final class _ProgressMessage {
  const _ProgressMessage(this.value, this.label);
  final double value;
  final String? label;
}

final class _DoneMessage {
  const _DoneMessage(this.value);
  final Object? value;
}

final class _FailMessage {
  const _FailMessage(this.kind, this.detail);
  final FailureKind kind;
  final String? detail;
}

final class _Start<A, R> {
  const _Start(this.body, this.args, this.port);
  final JobBody<A, R> body;
  final A args;
  final SendPort port;
}

Future<void> _entry<A, R>(_Start<A, R> start) async {
  final context = JobContext._(start.port);
  try {
    final value = await start.body(start.args, context);
    start.port.send(_DoneMessage(value));
  } on Object catch (error) {
    final failure = DocNookFailure.from(error);
    start.port.send(_FailMessage(failure.kind, failure.debugDetail));
  }
}

/// Runs jobs in background isolates, at most [workers] at a time
/// (BLUEPRINT 5.3: one on phones with ≤ 3 GB RAM, two otherwise). Extra jobs
/// wait in order. Keeps parsing and conversion off the UI thread.
class JobRunner {
  JobRunner({this.workers = 1});

  /// Worker count for a phone with [totalMemoryMb] of RAM.
  static int workersFor(int totalMemoryMb) =>
      totalMemoryMb > 0 && totalMemoryMb <= 3 * 1024 ? 1 : 2;

  final int workers;
  int _running = 0;
  final Queue<void Function()> _waiting = Queue();

  /// Starts [body] with [args]. A [timeout] kills the job and reports it as
  /// `corrupt`, because a parse that never ends means a hostile or damaged
  /// file (BLUEPRINT 8.1).
  JobHandle<R> run<A, R>(
    JobBody<A, R> body,
    A args, {
    Duration? timeout = const Duration(seconds: 60),
    String? debugName,
  }) {
    final completer = Completer<Result<R>>();
    final progress = StreamController<JobProgress>.broadcast();
    var cancelled = false;
    Isolate? isolate;
    ReceivePort? port;
    Timer? timer;

    void finish(Result<R> result) {
      if (completer.isCompleted) return;
      timer?.cancel();
      port?.close();
      isolate?.kill(priority: Isolate.immediate);
      unawaited(progress.close());
      completer.complete(result);
      _running--;
      if (_waiting.isNotEmpty) _waiting.removeFirst()();
    }

    Future<void> start() async {
      _running++;
      if (cancelled) {
        finish(const Err(DocNookFailure.cancelled()));
        return;
      }
      final receive = port = ReceivePort();
      receive.listen((message) {
        switch (message) {
          case _ProgressMessage(:final value, :final label):
            if (!progress.isClosed) progress.add(JobProgress(value, label));
          case _DoneMessage(:final value):
            finish(Ok(value as R));
          case _FailMessage(:final kind, :final detail):
            finish(Err(DocNookFailure(kind, debugDetail: detail)));
          case null:
            // Exit without a result: the isolate crashed or ran out of memory.
            finish(const Err(DocNookFailure.unknown(detail: 'isolate exited')));
        }
      });
      try {
        isolate = await Isolate.spawn<_Start<A, R>>(
          _entry<A, R>,
          _Start<A, R>(body, args, receive.sendPort),
          onExit: receive.sendPort,
          debugName: debugName,
        );
        if (cancelled || completer.isCompleted) {
          isolate?.kill(priority: Isolate.immediate);
          finish(const Err(DocNookFailure.cancelled()));
          return;
        }
        if (timeout != null) {
          timer = Timer(
            timeout,
            () => finish(const Err(DocNookFailure.corrupt(detail: 'timeout'))),
          );
        }
      } on Object catch (error) {
        finish(Err(DocNookFailure.from(error)));
      }
    }

    if (_running < workers) {
      unawaited(start());
    } else {
      _waiting.add(() => unawaited(start()));
    }

    return JobHandle._(completer.future, progress.stream, () {
      cancelled = true;
      finish(const Err(DocNookFailure.cancelled()));
    });
  }
}

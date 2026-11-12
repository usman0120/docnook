import 'dart:async';
import 'dart:io';

import 'package:docnook/core/failures.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:flutter_test/flutter_test.dart';

int _sum(int n, JobContext context) {
  var total = 0;
  for (var i = 1; i <= n; i++) {
    total += i;
    if (i % 1000 == 0) context.progress(i / n, 'step $i');
  }
  context.progress(1);
  return total;
}

Never _fails(String kind, JobContext context) => switch (kind) {
  'corrupt' => throw const DocNookFailure.corrupt(),
  'format' => throw const FormatException('bad'),
  _ => throw StateError('boom'),
};

int _forever(int _, JobContext context) {
  while (true) {
    sleep(const Duration(milliseconds: 5));
  }
}

Future<int> _slow(int ms, JobContext context) async {
  await Future<void>.delayed(Duration(milliseconds: ms));
  return ms;
}

void main() {
  test('runs a job in an isolate and reports progress', () async {
    final runner = JobRunner();
    final handle = runner.run(_sum, 100000);
    final updates = <JobProgress>[];
    final sub = handle.progress.listen(updates.add);
    final result = await handle.result;
    await sub.cancel();
    expect(result.valueOrNull, 5000050000);
    expect(updates, isNotEmpty);
    expect(updates.last.value, 1);
  });

  test('failures come back as DocNookFailure kinds', () async {
    final runner = JobRunner(workers: 3);
    final corrupt = await runner.run(_fails, 'corrupt').result;
    final format = await runner.run(_fails, 'format').result;
    final other = await runner.run(_fails, 'other').result;
    expect(corrupt.failureOrNull?.kind, FailureKind.corrupt);
    expect(format.failureOrNull?.kind, FailureKind.corrupt);
    expect(other.failureOrNull?.kind, FailureKind.unknown);
  });

  test('cancel stops a job that never yields', () async {
    final runner = JobRunner();
    final handle = runner.run(_forever, 0, timeout: null);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    handle.cancel();
    final result = await handle.result.timeout(const Duration(seconds: 2));
    expect(result.failureOrNull?.kind, FailureKind.cancelled);

    // The worker slot is free again.
    expect((await runner.run(_slow, 10).result).valueOrNull, 10);
  });

  test('a job that runs past its timeout is reported as corrupt', () async {
    final runner = JobRunner();
    final result = await runner
        .run(_forever, 0, timeout: const Duration(milliseconds: 200))
        .result
        .timeout(const Duration(seconds: 3));
    expect(result.failureOrNull?.kind, FailureKind.corrupt);
  });

  test('extra jobs wait for a free worker, in order', () async {
    final runner = JobRunner();
    final order = <int>[];
    final a = runner.run(_slow, 150);
    final b = runner.run(_slow, 10);
    unawaited(a.result.then((r) => order.add(r.valueOrNull!)));
    await b.result.then((r) => order.add(r.valueOrNull!));
    expect(order, [150, 10]);
  });

  test('a queued job can be cancelled before it starts', () async {
    final runner = JobRunner();
    final first = runner.run(_slow, 100);
    final second = runner.run(_slow, 100)..cancel();
    expect((await second.result).failureOrNull?.kind, FailureKind.cancelled);
    expect((await first.result).valueOrNull, 100);
  });

  test('worker count follows device memory', () {
    expect(JobRunner.workersFor(3 * 1024), 1);
    expect(JobRunner.workersFor(2048), 1);
    expect(JobRunner.workersFor(4 * 1024), 2);
    expect(JobRunner.workersFor(0), 2);
  });
}

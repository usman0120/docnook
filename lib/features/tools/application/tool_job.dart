import 'dart:async';

import 'package:docnook/core/failures.dart';
import 'package:docnook/engines/pdf/pdfium_editor.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tool job in flight or just finished. One at a time: tools write big
/// files and phones have little memory.
@immutable
final class ToolJobState {
  const ToolJobState({
    required this.tool,
    this.progress = 0,
    this.page,
    this.of,
    this.result,
    this.failure,
    this.watched = true,
  });

  final ToolId tool;
  final double progress;
  final int? page;
  final int? of;
  final ToolResult? result;
  final DocNookFailure? failure;

  /// False once the user dismissed the progress sheet: the Tools tab shows
  /// a chip instead (S10).
  final bool watched;

  bool get running => result == null && failure == null;

  ToolJobState copyWith({
    double? progress,
    int? page,
    int? of,
    ToolResult? result,
    DocNookFailure? failure,
    bool? watched,
  }) => ToolJobState(
    tool: tool,
    progress: progress ?? this.progress,
    page: page ?? this.page,
    of: of ?? this.of,
    result: result ?? this.result,
    failure: failure ?? this.failure,
    watched: watched ?? this.watched,
  );
}

final toolJobProvider = NotifierProvider<ToolJobController, ToolJobState?>(
  ToolJobController.new,
);

class ToolJobController extends Notifier<ToolJobState?> {
  bool _cancelled = false;

  @override
  ToolJobState? build() => null;

  bool get busy => state?.running ?? false;

  /// Starts [body] unless another job is running. Completes when it ends.
  Future<void> start(
    ToolId tool,
    Future<ToolResult> Function(EditControl control) body,
  ) async {
    if (busy) return;
    _cancelled = false;
    state = ToolJobState(tool: tool);
    final control = EditControl(
      onProgress: (value, {page, of}) {
        final s = state;
        if (s == null || !s.running) return;
        state = s.copyWith(progress: value, page: page, of: of);
      },
      isCancelled: () => _cancelled,
    );
    try {
      final result = await body(control);
      state = state?.copyWith(result: result, progress: 1);
    } on Object catch (e) {
      state = state?.copyWith(failure: DocNookFailure.from(e));
    }
  }

  void cancel() => _cancelled = true;

  void setWatched({required bool watched}) {
    final s = state;
    if (s != null) state = s.copyWith(watched: watched);
  }

  /// Forgets a finished job (after its result was shown).
  void clear() {
    if (!busy) state = null;
  }
}

import 'dart:async';

import 'package:docnook/domain/read_aloud/read_aloud_source.dart';
import 'package:docnook/features/viewer/read_aloud/read_aloud_bar.dart';
import 'package:docnook/features/viewer/read_aloud/read_aloud_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read Aloud plumbing shared by the viewers (S35): owns the controller,
/// rebuilds the viewer when the sentence changes and asks it to follow.
mixin ReadAloudHost<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  ReadAloudController? _readAloud;
  ReadAloudSpot? _lastSpot;

  /// The sentence being read, while the bar is open.
  ReadAloudSpot? get readAloudSpot =>
      _readAloud?.active == true ? _readAloud?.spot : null;

  bool get readAloudActive => _readAloud?.active ?? false;

  /// Called when Read Aloud moves to another sentence; the viewer brings
  /// [spot] into view.
  void followReadAloud(ReadAloudSpot spot);

  /// Opens the bar and starts reading [source] from unit [fromUnit].
  Future<void> startReadAloud(
    ReadAloudSource source, {
    int fromUnit = 0,
  }) async {
    final controller = _readAloud ??= await createReadAloud(ref)
      ..addListener(_onReadAloud);
    if (!mounted) return;
    await controller.start(source, fromUnit: fromUnit);
  }

  void _onReadAloud() {
    if (!mounted) return;
    final spot = readAloudSpot;
    setState(() {});
    if (spot != null && spot != _lastSpot) {
      _lastSpot = spot;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) followReadAloud(spot);
      });
    }
    if (spot == null) _lastSpot = null;
  }

  /// Stops reading when the viewer closes.
  void disposeReadAloud() {
    _readAloud
      ?..removeListener(_onReadAloud)
      ..dispose();
    _readAloud = null;
  }

  /// The bar, or nothing when Read Aloud is closed.
  Widget readAloudBar({bool night = false}) {
    final controller = _readAloud;
    if (controller == null || !controller.active) {
      return const SizedBox.shrink();
    }
    return ReadAloudBar(controller: controller, night: night);
  }
}

/// Scrolls so the sentence being read is on screen. [fraction] is how far
/// into [target] the sentence starts (0 = top, 1 = bottom), estimated from
/// its character offset; nothing moves while that spot is visible.
Future<void> revealIfOffscreen(
  BuildContext target, {
  double fraction = 0,
}) async {
  final box = target.findRenderObject();
  final scrollable = Scrollable.maybeOf(target);
  if (box is! RenderBox || !box.attached || scrollable == null) return;
  final viewport = scrollable.context.findRenderObject();
  if (viewport is! RenderBox) return;
  final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
  final spot = top + box.size.height * fraction.clamp(0.0, 1.0);
  final height = viewport.size.height;
  if (spot > 24 && spot < height - 96) return;
  final position = scrollable.position;
  final target0 = (position.pixels + spot - height * 0.25).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  await position.animateTo(
    target0,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOutCubic,
  );
}

/// Read Aloud over unit texts already in memory.
class TextListSource implements ReadAloudSource {
  TextListSource(this.texts);
  final List<String> texts;

  @override
  int get unitCount => texts.length;

  @override
  Future<String> unitText(int unit) async => texts[unit];
}

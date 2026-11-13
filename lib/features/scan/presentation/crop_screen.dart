import 'dart:async';
import 'dart:io';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:docnook/features/scan/application/scan_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The crop editor always draws on a dark surface, like a camera, so the
/// page's edges stand out whatever the app theme.
const _stage = Color(0xFF141413);
const _stageInk = Color(0xFFECE9E2);

/// Manual crop (FR-SCAN-02): four corner handles over the original photo, a
/// magnifier above the finger while dragging. Pops with the new
/// [PageGeometry], or null when cancelled.
class CropScreen extends ConsumerStatefulWidget {
  const CropScreen({required this.page, super.key});

  final ScanPage page;

  @override
  ConsumerState<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends ConsumerState<CropScreen> {
  late Quad _quad = widget.page.geometry.quad;
  int? _dragging;
  Offset? _finger;
  double? _aspect;
  bool _detecting = false;
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    if (mounted) {
      setState(() => _aspect = info.image.width / info.image.height);
    }
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream?.removeListener(_listener);
    _stream = FileImage(
      File(widget.page.originalPath),
    ).resolve(createLocalImageConfiguration(context))..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  Future<void> _auto() async {
    setState(() => _detecting = true);
    final quad = await ref.read(scanServiceProvider).detectQuad(widget.page);
    if (!mounted) return;
    setState(() {
      _detecting = false;
      _quad = quad;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final aspect = _aspect;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _stage,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: Space.x1),
                    IconAction(
                      icon: PhosphorIconsRegular.x,
                      label: l.actionCancel,
                      color: _stageInk,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        l.scanCrop,
                        style: DocNookText.bodyStrong.copyWith(
                          color: _stageInk,
                        ),
                      ),
                    ),
                    QuietButton(
                      label: l.actionDone,
                      color: _stageInk,
                      onPressed: _quad.isConvex
                          ? () => Navigator.of(
                              context,
                            ).pop(widget.page.geometry.copyWith(quad: _quad))
                          : null,
                    ),
                    const SizedBox(width: Space.x2),
                  ],
                ),
              ),
              Expanded(
                // With the editor's own 24 dp margin, the photo sits 48 dp
                // from the screen sides, clear of Android's back-gesture zone.
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.x6,
                    vertical: Space.x2,
                  ),
                  child: aspect == null
                      ? const Center(child: CircularProgressIndicator())
                      : _editor(context, aspect),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.screen,
                  0,
                  Space.screen,
                  Space.x4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StageButton(
                        icon: PhosphorIconsRegular.magicWand,
                        label: l.scanCropAuto,
                        busy: _detecting,
                        onPressed: _detecting ? null : () => unawaited(_auto()),
                      ),
                    ),
                    const SizedBox(width: Space.x3),
                    Expanded(
                      child: _StageButton(
                        icon: PhosphorIconsRegular.cornersOut,
                        label: l.scanCropFull,
                        onPressed: () => setState(() => _quad = Quad.full),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The photo with a margin of half a handle on every side, so each handle
  /// is touchable all round (a Stack ignores touches outside its own box).
  Widget _editor(BuildContext context, double aspect) {
    final l = AppLocalizations.of(context);
    final labels = [
      l.scanCornerTopLeft,
      l.scanCornerTopRight,
      l.scanCornerBottomRight,
      l.scanCornerBottomLeft,
    ];
    const margin = Sizes.touch / 2;
    return LayoutBuilder(
      builder: (context, box) {
        final room = Size(
          box.maxWidth - margin * 2,
          box.maxHeight - margin * 2,
        );
        final size = room.width / room.height > aspect
            ? Size(room.height * aspect, room.height)
            : Size(room.width, room.width / aspect);
        Offset at(NPoint p) =>
            Offset(margin + p.x * size.width, margin + p.y * size.height);
        final finger = _finger;
        return Center(
          child: SizedBox(
            width: size.width + margin * 2,
            height: size.height + margin * 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: margin,
                  top: margin,
                  width: size.width,
                  height: size.height,
                  child: Image.file(
                    File(widget.page.originalPath),
                    fit: BoxFit.fill,
                    cacheWidth: 1400,
                    semanticLabel: l.scanPageLabel(widget.page.position + 1),
                  ),
                ),
                Positioned(
                  left: margin,
                  top: margin,
                  width: size.width,
                  height: size.height,
                  child: CustomPaint(
                    painter: _QuadPainter([
                      for (final p in _quad.points)
                        at(p) - const Offset(margin, margin),
                    ], valid: _quad.isConvex),
                  ),
                ),
                for (var i = 0; i < 4; i++)
                  Positioned(
                    left: at(_quad.points[i]).dx - Sizes.touch / 2,
                    top: at(_quad.points[i]).dy - Sizes.touch / 2,
                    width: Sizes.touch,
                    height: Sizes.touch,
                    child: Semantics(
                      label: labels[i],
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (_) => setState(() {
                          _dragging = i;
                          _finger = at(_quad.points[i]);
                        }),
                        onPanUpdate: (d) {
                          final p = _quad.points[i];
                          final next = NPoint(
                            p.x + d.delta.dx / size.width,
                            p.y + d.delta.dy / size.height,
                          );
                          setState(() {
                            _quad = _quad.withPoint(i, next);
                            _finger = at(_quad.points[i]);
                          });
                        },
                        onPanEnd: (_) => setState(() {
                          _dragging = null;
                          _finger = null;
                        }),
                        // The dragged handle hides itself, so the magnifier
                        // shows the page edge under the finger, not the dot.
                        child: Center(
                          child: Opacity(
                            opacity: _dragging == i ? 0 : 1,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _stageInk,
                                border: Border.all(color: _stage, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (finger != null) _loupe(finger),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Magnifier centred 96 px above the finger, showing what is under it.
  Widget _loupe(Offset finger) {
    const diameter = 104.0;
    const lift = 96.0;
    final center = finger - const Offset(0, lift);
    return Positioned(
      left: center.dx - diameter / 2,
      top: center.dy - diameter / 2,
      child: IgnorePointer(
        child: RawMagnifier(
          size: const Size.square(diameter),
          magnificationScale: 2.2,
          focalPointOffset: const Offset(0, lift),
          decoration: const MagnifierDecoration(
            shape: CircleBorder(side: BorderSide(color: _stageInk, width: 2)),
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: context.colors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  _QuadPainter(this.points, {required this.valid});

  final List<Offset> points;
  final bool valid;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addPolygon(points, true);
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      path,
    );
    canvas
      ..drawPath(outside, Paint()..color = _stage.withValues(alpha: 0.55))
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = valid ? _stageInk : const Color(0xFFF2B8B5),
      );
  }

  @override
  bool shouldRepaint(_QuadPainter old) =>
      old.valid != valid || !_same(old.points, points);

  static bool _same(List<Offset> a, List<Offset> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _StageButton extends StatelessWidget {
  const _StageButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: _stageInk,
      minimumSize: const Size.fromHeight(Sizes.buttonHeight),
      side: const BorderSide(color: Color(0x33ECE9E2)),
      shape: const RoundedRectangleBorder(borderRadius: Radii.chipAll),
    ),
    icon: busy
        ? const SizedBox.square(
            dimension: Sizes.iconSmall,
            child: CircularProgressIndicator(strokeWidth: 2, color: _stageInk),
          )
        : Icon(icon, size: Sizes.iconSmall),
    label: Text(label, style: DocNookText.label.copyWith(color: _stageInk)),
  );
}

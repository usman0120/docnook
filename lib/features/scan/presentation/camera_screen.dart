import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:docnook/features/scan/application/scan_service.dart';
import 'package:docnook/features/scan/presentation/scan_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _stage = Color(0xFF000000);
const _stageInk = Color(0xFFECE9E2);
const _stageMuted = Color(0xFFA8A398);

/// S23 fallback for phones without Google's scanner: live preview, shutter,
/// flash, mode switch, batch counter and Done. Every photo is saved to the
/// draft at once (FR-SCAN-01); edges are found automatically and can be
/// fixed in Crop.
class ScanCameraScreen extends ConsumerStatefulWidget {
  const ScanCameraScreen({required this.args, super.key});

  final ScanCameraArgs args;

  @override
  ConsumerState<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

enum _CameraState { starting, ready, denied, missing, failed }

class _ScanCameraScreenState extends ConsumerState<ScanCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  _CameraState _state = _CameraState.starting;
  late ScanMode _mode = widget.args.mode;
  late int? _sessionId = widget.args.sessionId;
  int _taken = 0;
  String? _lastShot;
  bool _flash = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      unawaited(controller?.dispose());
      if (mounted) setState(() => _state = _CameraState.starting);
    } else if (state == AppLifecycleState.resumed && controller == null) {
      unawaited(_start());
    }
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      final back = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .firstOrNull;
      final camera = back ?? cameras.firstOrNull;
      if (camera == null) {
        if (mounted) setState(() => _state = _CameraState.missing);
        return;
      }
      final controller = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.setFlashMode(_flash ? FlashMode.torch : FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _state = _CameraState.ready;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(
        () => _state = e.code.contains('Access') || e.code.contains('ermission')
            ? _CameraState.denied
            : _CameraState.failed,
      );
    }
  }

  int get _limit => switch (_mode) {
    ScanMode.idCard => 2,
    _ => 50,
  };

  Future<void> _shoot() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    setState(() => _busy = true);
    final service = ref.read(scanServiceProvider);
    try {
      final shot = await controller.takePicture();
      final retake = widget.args.retakePageId;
      var id = _sessionId;
      if (id == null) {
        id = await service.createSession(_mode);
        if (widget.args.ocr) {
          await ref.read(scanRepositoryProvider).updateSettings(id, ocr: true);
        }
        _sessionId = id;
      }
      if (retake != null) {
        final session = await ref.read(scanRepositoryProvider).load(id);
        final page = session?.pages.where((p) => p.id == retake).firstOrNull;
        if (page != null) {
          await service.retake(
            id,
            page,
            shot.path,
            mode: _mode,
            detectEdges: true,
          );
        }
        if (mounted) Navigator.of(context).pop();
        return;
      }
      await service.addImages(id, [shot.path], mode: _mode, detectEdges: true);
      if (!mounted) return;
      setState(() {
        _taken++;
        _lastShot = shot.path;
      });
      final existing =
          (await ref.read(scanRepositoryProvider).load(id))?.pages.length;
      if (_mode == ScanMode.idCard && _taken >= 2 && mounted) {
        _done();
      } else if ((existing ?? 0) >= 50 && mounted) {
        _done();
      }
    } on CameraException {
      if (mounted) _snack(AppLocalizations.of(context).scanCameraFailed);
    } on Object {
      if (mounted) _snack(AppLocalizations.of(context).scanAddFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _done() {
    final id = _sessionId;
    if (id == null) {
      Navigator.of(context).maybePop();
      return;
    }
    if (widget.args.sessionId != null) {
      // Came from Review: go back to it.
      Navigator.of(context).maybePop();
    } else {
      context.pushReplacement('/scan/$id');
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = !_flash;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _flash = next);
    } on CameraException {
      // No flash on this camera.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = _controller;
    final hint = switch (_mode) {
      ScanMode.idCard => _taken == 0 ? l.scanIdFront : l.scanIdBack,
      ScanMode.book => l.scanBookHint,
      ScanMode.document => null,
    };
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
                      label: l.actionClose,
                      color: _stageInk,
                      onPressed: _done,
                    ),
                    const Spacer(),
                    IconAction(
                      icon: _flash
                          ? PhosphorIconsRegular.lightning
                          : PhosphorIconsRegular.lightningSlash,
                      label: _flash ? l.scanFlashOff : l.scanFlashOn,
                      color: _stageInk,
                      onPressed: controller == null
                          ? null
                          : () => unawaited(_toggleFlash()),
                    ),
                    const SizedBox(width: Space.x1),
                  ],
                ),
              ),
              Expanded(child: _preview(context, controller)),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: Space.x3),
                  child: Text(
                    hint,
                    style: DocNookText.label.copyWith(color: _stageInk),
                  ),
                ),
              if (_taken == 0 &&
                  widget.args.sessionId == null &&
                  widget.args.retakePageId == null)
                Padding(
                  padding: const EdgeInsets.only(top: Space.x3),
                  child: _ModeSwitch(
                    mode: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.screen,
                  vertical: Space.x4,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _Counter(path: _lastShot, count: _taken),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _Shutter(
                          label: l.scanShutter,
                          busy: _busy,
                          onPressed:
                              _state == _CameraState.ready && _taken < _limit
                              ? () => unawaited(_shoot())
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: QuietButton(
                          label: l.actionDone,
                          color: _stageInk,
                          onPressed: _taken > 0 ? _done : null,
                        ),
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

  Widget _preview(BuildContext context, CameraController? controller) {
    final l = AppLocalizations.of(context);
    String? message;
    switch (_state) {
      case _CameraState.starting:
        return const Center(child: CircularProgressIndicator(color: _stageInk));
      case _CameraState.denied:
        message = l.scanCameraDenied;
      case _CameraState.missing:
        message = l.scanCameraMissing;
      case _CameraState.failed:
        message = l.scanCameraFailed;
      case _CameraState.ready:
        break;
    }
    if (message != null || controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.x8),
          child: Text(
            message ?? l.scanCameraFailed,
            textAlign: TextAlign.center,
            style: DocNookText.body.copyWith(color: _stageMuted),
          ),
        ),
      );
    }
    return Center(
      child: AspectRatio(
        // The plugin reports landscape sensor size; the phone is portrait.
        aspectRatio: 1 / controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final ScanMode mode;
  final ValueChanged<ScanMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String label(ScanMode m) => switch (m) {
      ScanMode.document => l.scanModeDocument,
      ScanMode.idCard => l.scanModeIdCard,
      ScanMode.book => l.scanModeBook,
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final m in ScanMode.values)
          Semantics(
            button: true,
            selected: m == mode,
            child: InkWell(
              onTap: () => onChanged(m),
              borderRadius: Radii.chipAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.x3,
                  vertical: Space.x2,
                ),
                child: Text(
                  label(m),
                  style: DocNookText.label.copyWith(
                    color: m == mode ? context.colors.accent : _stageMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    enabled: onPressed != null,
    child: GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _stageInk, width: 3),
        ),
        padding: const EdgeInsets.all(5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onPressed == null ? _stageMuted : _stageInk,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(Space.x4),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _stage,
                  ),
                )
              : null,
        ),
      ),
    ),
  );
}

class _Counter extends StatelessWidget {
  const _Counter({required this.path, required this.count});

  final String? path;
  final int count;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    if (path == null) return const SizedBox.shrink();
    return Semantics(
      label: AppLocalizations.of(context).scanPagesCount(count),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 58,
            decoration: BoxDecoration(
              border: Border.all(color: _stageInk, width: 1.5),
            ),
            child: Image.file(File(path), fit: BoxFit.cover, cacheWidth: 120),
          ),
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: context.colors.accent,
                borderRadius: Radii.chipAll,
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: DocNookText.caption.copyWith(color: _stage),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

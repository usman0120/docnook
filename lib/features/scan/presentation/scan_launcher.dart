import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:docnook/features/scan/application/scan_capture.dart';
import 'package:docnook/features/scan/application/scan_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Arguments for DocNook's own camera screen (the fallback scanner).
final class ScanCameraArgs {
  const ScanCameraArgs({
    required this.mode,
    this.sessionId,
    this.retakePageId,
    this.ocr = false,
  });

  final ScanMode mode;

  /// Adds to this session instead of starting a new one.
  final int? sessionId;

  /// Replaces this page with the next photo.
  final int? retakePageId;
  final bool ocr;
}

/// Starts a new scan (S23): Google's scanner when available, otherwise
/// DocNook's camera screen.
Future<void> startScan(
  BuildContext context,
  WidgetRef ref,
  ScanMode mode, {
  bool ocr = false,
}) async {
  if (mode == ScanMode.idCard && !await _idCardHint(context)) return;
  final outcome = await MlKitCapture.scan(
    pageLimit: mode == ScanMode.idCard ? 2 : 50,
  );
  if (!context.mounted) return;
  switch (outcome) {
    case Captured(:final paths):
      final service = ref.read(scanServiceProvider);
      final id = await service.createSession(mode);
      if (ocr) {
        await ref.read(scanRepositoryProvider).updateSettings(id, ocr: true);
      }
      if (!context.mounted) return;
      unawaited(context.push('/scan/$id'));
      await _addQuietly(context, ref, id, paths, mode);
    case CaptureUnavailable():
      unawaited(
        context.push(
          '/scan-camera',
          extra: ScanCameraArgs(mode: mode, ocr: ocr),
        ),
      );
    case CaptureCancelled():
      break;
  }
}

/// "Add page" in S24.
Future<void> addPages(
  BuildContext context,
  WidgetRef ref,
  ScanSession session,
) async {
  final room = 50 - session.pages.length;
  if (room <= 0) {
    _snack(context, AppLocalizations.of(context).scanPageLimit);
    return;
  }
  final outcome = await MlKitCapture.scan(pageLimit: room);
  if (!context.mounted) return;
  switch (outcome) {
    case Captured(:final paths):
      await _addQuietly(
        context,
        ref,
        session.id,
        paths.take(room).toList(),
        session.mode,
      );
    case CaptureUnavailable():
      unawaited(
        context.push(
          '/scan-camera',
          extra: ScanCameraArgs(mode: session.mode, sessionId: session.id),
        ),
      );
    case CaptureCancelled():
      break;
  }
}

/// "Retake" in S24.
Future<void> retakePage(
  BuildContext context,
  WidgetRef ref,
  ScanSession session,
  ScanPage page,
) async {
  final outcome = await MlKitCapture.scan(pageLimit: 1);
  if (!context.mounted) return;
  switch (outcome) {
    case Captured(:final paths):
      try {
        await ref
            .read(scanServiceProvider)
            .retake(session.id, page, paths.first, mode: session.mode);
      } on Object {
        if (context.mounted) {
          _snack(context, AppLocalizations.of(context).scanAddFailed);
        }
      }
    case CaptureUnavailable():
      unawaited(
        context.push(
          '/scan-camera',
          extra: ScanCameraArgs(
            mode: session.mode,
            sessionId: session.id,
            retakePageId: page.id,
          ),
        ),
      );
    case CaptureCancelled():
      break;
  }
}

Future<void> _addQuietly(
  BuildContext context,
  WidgetRef ref,
  int sessionId,
  List<String> paths,
  ScanMode mode,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(scanServiceProvider).addImages(sessionId, paths, mode: mode);
  } on Object {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.scanAddFailed)));
  }
}

void _snack(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// ID card mode: tell the user to scan the front, then the back.
Future<bool> _idCardHint(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final go = await showDocNookSheet<bool>(
    context,
    title: l.toolScanId,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        0,
        Space.screen,
        Space.x4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.scanIdHint,
            style: DocNookText.body.copyWith(color: context.colors.inkMuted),
          ),
          const SizedBox(height: Space.x4),
          PrimaryButton(
            label: l.actionContinue,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ),
  );
  return go ?? false;
}

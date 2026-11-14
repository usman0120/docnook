import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/data/platform/tts_engine.dart';
import 'package:docnook/data/repositories/settings_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/features/viewer/presentation/viewer_chrome.dart';
import 'package:docnook/features/viewer/read_aloud/read_aloud_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A [ReadAloudController] for a viewer, with the speed the user picked
/// last time. The viewer owns and disposes it.
Future<ReadAloudController> createReadAloud(WidgetRef ref) async {
  final settings = ref.read(settingsRepositoryProvider);
  final saved = double.tryParse(
    await settings.get(SettingsRepository.keyReadAloudRate) ?? '',
  );
  return ReadAloudController(
    ref.read(ttsEngineProvider),
    speed: readAloudSpeeds.contains(saved) ? saved! : 1.0,
    onSpeedChanged: (s) =>
        unawaited(settings.set(SettingsRepository.keyReadAloudRate, '$s')),
  );
}

/// S35: the slim Read Aloud bar at the bottom of a viewer.
class ReadAloudBar extends StatelessWidget {
  const ReadAloudBar({required this.controller, this.night = false, super.key});

  final ReadAloudController controller;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final ink = night ? viewerNightInk : c.ink;
    final muted = night ? viewerNightMuted : c.inkMuted;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final rc = controller;
        final problem = rc.problem;
        final busy = rc.preparing;
        Widget button(IconData icon, String label, VoidCallback? onTap) =>
            IconAction(
              icon: icon,
              label: label,
              color: onTap == null ? muted : ink,
              onPressed: onTap,
            );

        return Material(
          color: night ? viewerNightBar : c.paper,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: night ? Colors.white10 : c.hairline),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x2),
                child: SizedBox(
                  height: 56,
                  child: problem != null
                      ? Row(
                          children: [
                            const SizedBox(width: Space.x2),
                            Expanded(
                              child: Text(
                                problem == TtsProblem.noVoice
                                    ? l.readAloudNoVoiceShort
                                    : l.readAloudFailed,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: DocNookText.caption.copyWith(color: ink),
                              ),
                            ),
                            if (problem == TtsProblem.noVoice)
                              QuietButton(
                                label: l.readAloudHowTo,
                                onPressed: () =>
                                    unawaited(showNoVoiceSheet(context)),
                              ),
                            button(
                              PhosphorIconsRegular.x,
                              l.actionClose,
                              () => unawaited(rc.close()),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Semantics(
                              liveRegion: true,
                              child: Padding(
                                padding: const EdgeInsets.only(left: Space.x2),
                                child: Text(
                                  l.readAloudTitle,
                                  style: DocNookText.label.copyWith(
                                    color: muted,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            button(
                              PhosphorIconsRegular.skipBack,
                              l.readAloudPrevious,
                              busy ? null : () => unawaited(rc.previous()),
                            ),
                            if (busy)
                              SizedBox(
                                width: Sizes.touch,
                                height: Sizes.touch,
                                child: Center(
                                  child: SizedBox(
                                    width: Sizes.iconSmall,
                                    height: Sizes.iconSmall,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ink,
                                    ),
                                  ),
                                ),
                              )
                            else
                              button(
                                rc.playing
                                    ? PhosphorIconsFill.pause
                                    : rc.finished
                                    ? PhosphorIconsRegular.arrowCounterClockwise
                                    : PhosphorIconsFill.play,
                                rc.playing
                                    ? l.readAloudPause
                                    : rc.finished
                                    ? l.readAloudAgain
                                    : l.readAloudPlay,
                                () => unawaited(
                                  rc.playing ? rc.pause() : rc.play(),
                                ),
                              ),
                            button(
                              PhosphorIconsRegular.skipForward,
                              l.readAloudNext,
                              busy ? null : () => unawaited(rc.next()),
                            ),
                            _SpeedChip(
                              speed: rc.speed,
                              ink: ink,
                              onTap: () {
                                final i = readAloudSpeeds.indexOf(rc.speed);
                                unawaited(
                                  rc.setSpeed(
                                    readAloudSpeeds[(i + 1) %
                                        readAloudSpeeds.length],
                                  ),
                                );
                              },
                            ),
                            button(
                              PhosphorIconsRegular.x,
                              l.actionClose,
                              () => unawaited(rc.close()),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.speed,
    required this.ink,
    required this.onTap,
  });

  final double speed;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = '${speed.toString().replaceFirst(RegExp(r'\.0$'), '')}×';
    return Semantics(
      button: true,
      label: l.readAloudSpeed(text),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.chipAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Sizes.touch,
            minHeight: Sizes.touch,
          ),
          child: Center(
            child: Text(
              text,
              textScaler: TextScaler.noScaling,
              style: DocNookText.label.copyWith(color: ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// FR-READ-06: no offline voice is installed; explains how to add one.
Future<void> showNoVoiceSheet(BuildContext context) => showDocNookSheet<void>(
  context,
  title: AppLocalizations.of(context).readAloudNoVoiceTitle,
  builder: (context, _) => Consumer(
    builder: (context, ref, _) {
      final l = AppLocalizations.of(context);
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          0,
          Space.screen,
          Space.x6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.readAloudNoVoiceBody,
              style: DocNookText.body.copyWith(color: context.colors.ink),
            ),
            const SizedBox(height: Space.x6),
            PrimaryButton(
              label: l.readAloudOpenVoiceSettings,
              onPressed: () {
                Navigator.of(context).pop();
                unawaited(ref.read(platformProvider).openTtsSettings());
              },
            ),
          ],
        ),
      );
    },
  ),
);

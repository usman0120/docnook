import 'dart:async';

import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/app/version.dart';
import 'package:docnook/data/files/app_paths.dart';
import 'package:docnook/data/repositories/settings_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _cacheSizeProvider = FutureProvider.autoDispose<int>((ref) async {
  final paths = ref.watch(appPathsProvider);
  return await AppPaths.sizeOf(paths.opened) +
      await AppPaths.sizeOf(paths.thumbs);
});

final _settingProvider = StreamProvider.autoDispose.family<String?, String>(
  (ref, key) => ref.watch(settingsRepositoryProvider).watch(key),
);

/// S30 Settings: a grouped list, plain labels, current value on the right.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.read(settingsRepositoryProvider);
    String? value(String key) => ref.watch(_settingProvider(key)).value;
    bool flag(String key) => value(key) == 'true';

    final theme = SettingsRepository.enumOf(
      ThemePreference.values,
      value(SettingsRepository.keyTheme),
      ThemePreference.system,
    );
    final scroll = SettingsRepository.enumOf(
      PdfScrollMode.values,
      value(SettingsRepository.keyPdfScroll),
      PdfScrollMode.vertical,
    );
    final quality = SettingsRepository.enumOf(
      OutputQuality.values,
      value(SettingsRepository.keyQuality),
      OutputQuality.balanced,
    );
    final cache = ref.watch(_cacheSizeProvider);

    String themeLabel(ThemePreference t) => switch (t) {
      ThemePreference.system => l.themeSystem,
      ThemePreference.light => l.themeLight,
      ThemePreference.dark => l.themeDark,
    };
    String scrollLabel(PdfScrollMode m) => switch (m) {
      PdfScrollMode.vertical => l.pdfScrollVertical,
      PdfScrollMode.horizontal => l.pdfScrollHorizontal,
    };
    String qualityLabel(OutputQuality q) => switch (q) {
      OutputQuality.small => l.qualitySmall,
      OutputQuality.balanced => l.qualityBalanced,
      OutputQuality.best => l.qualityBest,
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconAction(
          icon: PhosphorIconsRegular.arrowLeft,
          label: l.actionBack,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.x12),
        children: [
          _Group(l.settingsAppearance),
          _ChoiceTile<ThemePreference>(
            title: l.settingsTheme,
            value: theme,
            values: ThemePreference.values,
            label: themeLabel,
            onChanged: (t) => settings.set(SettingsRepository.keyTheme, t.name),
          ),
          _Group(l.settingsReading),
          _ChoiceTile<PdfScrollMode>(
            title: l.settingsPdfScroll,
            value: scroll,
            values: PdfScrollMode.values,
            label: scrollLabel,
            onChanged: (m) =>
                settings.set(SettingsRepository.keyPdfScroll, m.name),
          ),
          const Hairline(indent: Space.screen),
          _SwitchTile(
            title: l.settingsNightDefault,
            value: flag(SettingsRepository.keyNightDefault),
            onChanged: (v) =>
                settings.setBool(SettingsRepository.keyNightDefault, value: v),
          ),
          _Group(l.settingsOutput),
          _ChoiceTile<OutputQuality>(
            title: l.settingsQuality,
            value: quality,
            values: OutputQuality.values,
            label: qualityLabel,
            onChanged: (q) =>
                settings.set(SettingsRepository.keyQuality, q.name),
          ),
          const Hairline(indent: Space.screen),
          _InfoTile(
            title: l.settingsSaveLocation,
            value: l.settingsSaveLocationValue,
          ),
          _Group(l.settingsPrivacy),
          _SwitchTile(
            title: l.settingsBlockScreenshots,
            subtitle: l.settingsBlockScreenshotsBody,
            value: flag(SettingsRepository.keyBlockScreenshots),
            onChanged: (v) async {
              await settings.setBool(
                SettingsRepository.keyBlockScreenshots,
                value: v,
              );
              await ref.read(platformProvider).setSecure(on: v);
            },
          ),
          _Group(l.settingsStorage),
          ListTile(
            title: Text(l.settingsCache),
            subtitle: Text(
              cache.value == null ? '…' : l.fileSize(cache.value!),
            ),
            trailing: QuietButton(
              label: l.settingsClearCache,
              onPressed: (cache.value ?? 0) == 0
                  ? null
                  : () async {
                      final paths = ref.read(appPathsProvider);
                      await AppPaths.trim(paths.opened, 0);
                      await ref.read(thumbnailCacheProvider).clear();
                      ref.invalidate(_cacheSizeProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.settingsCacheCleared)),
                        );
                      }
                    },
            ),
          ),
          _Group(l.settingsAbout),
          _InfoTile(title: l.settingsVersion, value: appVersion),
          const Hairline(indent: Space.screen),
          ListTile(
            title: Text(l.settingsPrivacyPromise),
            trailing: const Icon(
              PhosphorIconsRegular.caretRight,
              size: Sizes.iconSmall,
            ),
            onTap: () => unawaited(
              showDocNookSheet<void>(
                context,
                title: l.settingsPrivacyPromise,
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.screen,
                    0,
                    Space.screen,
                    Space.x8,
                  ),
                  child: Text(
                    l.privacyPromise,
                    style: DocNookText.body.copyWith(color: context.colors.ink),
                  ),
                ),
              ),
            ),
          ),
          const Hairline(indent: Space.screen),
          ListTile(
            title: Text(l.settingsLicenses),
            trailing: const Icon(
              PhosphorIconsRegular.caretRight,
              size: Sizes.iconSmall,
            ),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l.appName,
              applicationVersion: appVersion,
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Space.screen,
      Space.x6,
      Space.screen,
      Space.x2,
    ),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: DocNookText.label.copyWith(color: context.colors.inkMuted),
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    trailing: Text(
      value,
      style: DocNookText.body.copyWith(color: context.colors.inkMuted),
    ),
  );
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    onChanged: onChanged,
  );
}

/// A setting with a few named choices, picked from a bottom sheet.
class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<T> values;
  final String Function(T) label;
  final FutureOr<void> Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      title: Text(title),
      subtitle: Text(label(value)),
      trailing: const Icon(
        PhosphorIconsRegular.caretRight,
        size: Sizes.iconSmall,
      ),
      onTap: () async {
        final chosen = await showDocNookSheet<T>(
          context,
          title: title,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in values)
                ListTile(
                  title: Text(label(option)),
                  trailing: option == value
                      ? Icon(
                          PhosphorIconsBold.check,
                          size: Sizes.iconSmall,
                          color: c.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
              const SizedBox(height: Space.x4),
            ],
          ),
        );
        if (chosen != null) await onChanged(chosen);
      },
    );
  }
}

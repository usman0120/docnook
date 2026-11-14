import 'dart:async';

import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/app/version.dart';
import 'package:docnook/data/repositories/settings_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/features/library/application/library_controller.dart';
import 'package:docnook/features/settings/application/settings_controller.dart';
import 'package:docnook/features/tools/application/tool_naming.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// S30 Settings (FR-SET-01): a grouped list, plain labels, current value on
/// the right. No security group: the vault and app lock were removed
/// (docs/decisions.md, 2026-11-14).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final controller = ref.read(settingsControllerProvider);
    final platform = ref.read(platformProvider);
    String? value(String key) => ref.watch(settingProvider(key)).value;
    bool flag(String key) => value(key) == 'true';
    void snack(String text) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

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
    final naming = SettingsRepository.enumOf(
      FileNaming.values,
      value(SettingsRepository.keyFileNaming),
      FileNaming.suffix,
    );
    final cache = ref.watch(cacheSizeProvider);
    final discovery = ref.watch(discoveryProvider);
    const playBuild = appFlavor == 'play';

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
    String namingLabel(FileNaming n) => switch (n) {
      FileNaming.suffix => l.namingSuffix,
      FileNaming.dated => l.namingDated,
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + Space.x12,
        ),
        children: [
          _Group(l.settingsAppearance),
          _ChoiceTile<ThemePreference>(
            title: l.settingsTheme,
            value: theme,
            values: ThemePreference.values,
            label: themeLabel,
            onChanged: (t) =>
                controller.set(SettingsRepository.keyTheme, t.name),
          ),
          _Group(l.settingsReading),
          _ChoiceTile<PdfScrollMode>(
            title: l.settingsPdfScroll,
            value: scroll,
            values: PdfScrollMode.values,
            label: scrollLabel,
            onChanged: (m) =>
                controller.set(SettingsRepository.keyPdfScroll, m.name),
          ),
          const Hairline(indent: Space.screen),
          _SwitchTile(
            title: l.settingsNightDefault,
            value: flag(SettingsRepository.keyNightDefault),
            onChanged: (v) => unawaited(
              controller.setBool(SettingsRepository.keyNightDefault, value: v),
            ),
          ),
          const Hairline(indent: Space.screen),
          _SwitchTile(
            title: l.settingsKeepScreenOn,
            value: flag(SettingsRepository.keyKeepScreenOn),
            onChanged: (v) => unawaited(
              controller.setBool(SettingsRepository.keyKeepScreenOn, value: v),
            ),
          ),
          const Hairline(indent: Space.screen),
          _NavTile(
            title: l.settingsReadAloudVoice,
            subtitle: l.settingsReadAloudVoiceBody,
            icon: PhosphorIconsRegular.arrowSquareOut,
            onTap: () => unawaited(platform.openTtsSettings()),
          ),
          _Group(l.settingsOutput),
          _ChoiceTile<OutputQuality>(
            title: l.settingsQuality,
            value: quality,
            values: OutputQuality.values,
            label: qualityLabel,
            onChanged: (q) =>
                controller.set(SettingsRepository.keyQuality, q.name),
          ),
          const Hairline(indent: Space.screen),
          _ChoiceTile<FileNaming>(
            title: l.settingsFileNaming,
            value: naming,
            values: FileNaming.values,
            label: namingLabel,
            onChanged: (n) =>
                controller.set(SettingsRepository.keyFileNaming, n.name),
          ),
          const Hairline(indent: Space.screen),
          _InfoTile(
            title: l.settingsSaveLocation,
            value: l.settingsSaveLocationValue,
          ),
          _Group(l.settingsLibrary),
          _NavTile(
            title: l.settingsFindDocs,
            subtitle: discovery.hasAccess
                ? l.settingsFindDocsOn
                : l.settingsFindDocsOff,
            onTap: discovery.hasAccess
                ? null
                : () => unawaited(controller.requestAccess()),
          ),
          const Hairline(indent: Space.screen),
          ListTile(
            title: Text(l.settingsFolders),
            subtitle: Text(l.settingsFoldersCount(discovery.folderCount)),
            trailing: QuietButton(
              label: l.settingsAddFolder,
              onPressed: () => unawaited(controller.addFolder()),
            ),
          ),
          const Hairline(indent: Space.screen),
          _NavTile(
            title: l.settingsRescan,
            subtitle: discovery.running
                ? l.settingsRescanRunning(discovery.found)
                : l.settingsRescanBody,
            onTap: !discovery.canDiscover || discovery.running
                ? null
                : () => unawaited(controller.rescan()),
          ),
          const Hairline(indent: Space.screen),
          _SwitchTile(
            title: l.settingsShowHidden,
            subtitle: l.settingsShowHiddenBody,
            value: flag(SettingsRepository.keyShowHidden),
            onChanged: (v) => unawaited(controller.setShowHidden(value: v)),
          ),
          const Hairline(indent: Space.screen),
          _NavTile(
            title: l.settingsRebuildIndex,
            subtitle: l.settingsRebuildIndexBody,
            onTap: () async {
              await controller.rebuildIndex();
              snack(l.settingsRebuildIndexDone);
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
                      await controller.clearCache();
                      snack(l.settingsCacheCleared);
                    },
            ),
          ),
          _Group(l.settingsAbout),
          _InfoTile(title: l.settingsVersion, value: appVersion),
          const Hairline(indent: Space.screen),
          _NavTile(
            title: l.settingsPrivacyPromise,
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
          _NavTile(
            title: l.settingsPrivacyPolicy,
            onTap: () => unawaited(context.push('/settings/privacy')),
          ),
          const Hairline(indent: Space.screen),
          _NavTile(
            title: l.settingsTerms,
            onTap: () => unawaited(context.push('/settings/terms')),
          ),
          if (playBuild) ...[
            const Hairline(indent: Space.screen),
            _NavTile(
              title: l.settingsRate,
              icon: PhosphorIconsRegular.arrowSquareOut,
              onTap: () => unawaited(platform.openStore()),
            ),
          ],
          if (supportEmail.isNotEmpty) ...[
            const Hairline(indent: Space.screen),
            _NavTile(
              title: l.settingsFeedback,
              icon: PhosphorIconsRegular.arrowSquareOut,
              onTap: () => unawaited(
                platform.sendEmail(
                  to: supportEmail,
                  subject: '${l.appName} $appVersion',
                ),
              ),
            ),
          ],
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

/// A row that opens something; disabled (no chevron) when [onTap] is null.
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon = PhosphorIconsRegular.caretRight,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    enabled: onTap != null,
    trailing: onTap == null ? null : Icon(icon, size: Sizes.iconSmall),
    onTap: onTap,
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

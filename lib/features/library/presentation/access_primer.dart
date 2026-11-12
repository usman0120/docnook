import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/features/library/application/library_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// S02: why storage access helps, with three honest choices. Never shown at
/// launch; only when the user asks DocNook to find documents.
Future<void> showAccessPrimer(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final choice = await showDocNookSheet<int>(
    context,
    builder: (context, _) {
      final c = context.colors;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.x6,
          Space.x2,
          Space.x6,
          Space.x6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(PhosphorIconsRegular.folderOpen, size: 36, color: c.primary),
            const SizedBox(height: Space.x4),
            Text(
              l.primerTitle,
              style: DocNookText.sectionTitle.copyWith(
                color: c.ink,
                fontSize: 19,
                height: 26 / 19,
              ),
            ),
            const SizedBox(height: Space.x2),
            Text(
              l.primerBody,
              style: DocNookText.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Space.x2),
            Text(
              l.primerSettingsHint,
              style: DocNookText.caption.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Space.x6),
            PrimaryButton(
              label: l.primerAllow,
              onPressed: () => Navigator.of(context).pop(0),
            ),
            const SizedBox(height: Space.x3),
            SecondaryButton(
              label: l.primerFolders,
              onPressed: () => Navigator.of(context).pop(1),
            ),
            const SizedBox(height: Space.x2),
            Center(
              child: QuietButton(
                label: l.primerNotNow,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      );
    },
  );
  final discovery = ref.read(discoveryProvider.notifier);
  switch (choice) {
    case 0:
      await discovery.requestAccess();
    case 1:
      await discovery.addFolder();
  }
}

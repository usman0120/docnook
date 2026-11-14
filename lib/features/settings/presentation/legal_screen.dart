import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/version.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';

enum LegalPage { privacy, terms }

/// S31: the Privacy policy and Terms of use, bundled in the app so they
/// read offline. The Terms end with the open-source notices the licences
/// require (docs/decisions.md, 2026-11-14).
class LegalScreen extends StatelessWidget {
  const LegalScreen(this.page, {super.key});

  final LegalPage page;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final email = supportEmail.isEmpty
        ? l.legalContactPlaceholder
        : supportEmail;
    final sections = switch (page) {
      LegalPage.privacy => [
        (l.privacyH1, l.privacyB1),
        (l.privacyH2, l.privacyB2),
        (l.privacyH3, l.privacyB3),
        (l.privacyH4, l.privacyB4),
        (l.privacyH5, l.privacyB5),
        (l.privacyH6, l.privacyB6),
        (l.privacyH7, l.privacyB7),
        (l.privacyH8, l.privacyB8(publisherName, email)),
      ],
      LegalPage.terms => [
        (l.termsH1, l.termsB1(publisherName)),
        (l.termsH2, l.termsB2),
        (l.termsH3, l.termsB3),
        (l.termsH4, l.termsB4(publisherName)),
        (l.termsH5, l.termsB5),
        (l.termsH6, l.termsB6(email)),
      ],
    };
    final title = page == LegalPage.privacy
        ? l.settingsPrivacyPolicy
        : l.settingsTerms;

    return Scaffold(
      appBar: AppBar(
        leading: IconAction(
          icon: PhosphorIconsRegular.arrowLeft,
          label: l.actionBack,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(title),
      ),
      body: SelectionArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Space.screen,
            Space.x2,
            Space.screen,
            MediaQuery.paddingOf(context).bottom + Space.x12,
          ),
          children: [
            Text(
              l.legalUpdated(legalUpdated),
              style: DocNookText.caption.copyWith(color: c.inkMuted),
            ),
            for (final (heading, body) in sections) ...[
              const SizedBox(height: Space.x6),
              Semantics(
                header: true,
                child: Text(
                  heading,
                  style: DocNookText.sectionTitle.copyWith(color: c.ink),
                ),
              ),
              const SizedBox(height: Space.x2),
              Text(body, style: DocNookText.body.copyWith(color: c.ink)),
            ],
            if (page == LegalPage.terms) ...[
              const SizedBox(height: Space.x6),
              Align(
                alignment: Alignment.centerLeft,
                child: QuietButton(
                  label: l.legalNotices,
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: l.appName,
                    applicationVersion: appVersion,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/data/repositories/settings_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// S01: two quiet pages, shown once, skippable.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref
        .read(settingsRepositoryProvider)
        .setBool(SettingsRepository.keyOnboarded, value: true);
    if (mounted) context.go('/home');
  }

  void _next() {
    if (_page == 0) {
      unawaited(
        _pages.nextPage(duration: Motion.of(context), curve: Motion.curve),
      );
    } else {
      unawaited(_finish());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.all(Space.x2),
                child: QuietButton(
                  label: l.actionSkip,
                  onPressed: () => unawaited(_finish()),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Page(
                    art: const _DocumentFan(),
                    title: l.onboardingTitle1,
                    body: l.onboardingBody1,
                  ),
                  _Page(
                    art: _OfflineBadge(label: l.onboardingBadge),
                    title: l.onboardingTitle2,
                    body: l.onboardingBody2,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 2; i++)
                  AnimatedContainer(
                    duration: Motion.of(context, Motion.fast),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? c.accent : c.hairline,
                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(Space.x6),
              child: PrimaryButton(
                label: _page == 0 ? l.actionContinue : l.actionGetStarted,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.art, required this.title, required this.body});

  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Space.x8),
      child: Column(
        children: [
          const SizedBox(height: Space.x8),
          SizedBox(height: 220, child: Center(child: art)),
          const SizedBox(height: Space.x8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DocNookText.screenTitle.copyWith(color: c.ink),
          ),
          const SizedBox(height: Space.x3),
          Text(
            body,
            textAlign: TextAlign.center,
            style: DocNookText.body.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Three paper sheets standing for a PDF, a sheet and a scan.
class _DocumentFan extends StatelessWidget {
  const _DocumentFan();

  @override
  Widget build(BuildContext context) {
    Widget sheet(DocType type, double angle, Offset offset) =>
        Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: angle,
            child: _MiniPage(type: type),
          ),
        );
    return ExcludeSemantics(
      child: SizedBox(
        width: 260,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            sheet(DocType.sheet, -0.16, const Offset(-62, 10)),
            sheet(DocType.image, 0.16, const Offset(62, 10)),
            sheet(DocType.pdf, 0, Offset.zero),
          ],
        ),
      ),
    );
  }
}

/// A small drawn page whose content hints at its type.
class _MiniPage extends StatelessWidget {
  const _MiniPage({required this.type});
  final DocType type;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = c.fileType(type);
    final line = c.inkMuted.withValues(alpha: 0.35);
    Widget bar(double width) => Container(
      width: width,
      height: 4,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: line,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    final content = switch (type) {
      DocType.sheet => Column(
        children: [
          for (var r = 0; r < 6; r++)
            Row(
              children: [
                for (var col = 0; col < 3; col++)
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: r == 0 ? color.withValues(alpha: 0.15) : null,
                        border: Border.all(color: line, width: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      DocType.image => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          bar(70),
          bar(50),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 48, height: 6, color: c.ink.withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          bar(84),
          bar(84),
          bar(72),
          bar(84),
          bar(40),
        ],
      ),
    };

    return Container(
      width: 108,
      height: 144,
      padding: const EdgeInsets.all(Space.x3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.hairline),
        boxShadow: [
          BoxShadow(
            color: c.ink.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: content),
          TypeBadge(type),
        ],
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
              border: Border.all(color: c.hairline),
            ),
            child: Icon(
              PhosphorIconsRegular.wifiSlash,
              size: 44,
              color: c.primary,
            ),
          ),
        ),
        const SizedBox(height: Space.x6),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.x3,
            vertical: Space.x2,
          ),
          decoration: BoxDecoration(
            borderRadius: Radii.chipAll,
            border: Border.all(color: c.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsRegular.shieldCheck,
                size: Sizes.iconSmall,
                color: c.success,
              ),
              const SizedBox(width: Space.x2),
              Text(label, style: DocNookText.label.copyWith(color: c.ink)),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/tab_bar.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:docnook/features/library/presentation/files_screen.dart';
import 'package:docnook/features/scan/presentation/scan_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Three-tab shell (Home, Files, Tools) with the raised Scan button on Home
/// and Files (BLUEPRINT 10).
class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final selecting = ref.watch(selectionActiveProvider);
    final showScan = shell.currentIndex != 2 && !selecting;

    return Scaffold(
      // Tabs scroll edge to edge; a paper strip keeps content from showing
      // through the status bar.
      body: Stack(
        children: [
          shell,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top,
            child: ColoredBox(color: context.colors.paper),
          ),
        ],
      ),
      floatingActionButton: showScan
          ? _ScanButton(
              label: l.actionScan,
              onPressed: () =>
                  unawaited(startScan(context, ref, ScanMode.document)),
            )
          : null,
      bottomNavigationBar: DocNookTabBar(
        currentIndex: shell.currentIndex,
        onSelect: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          TabItem(
            icon: PhosphorIconsRegular.house,
            activeIcon: PhosphorIconsFill.house,
            label: l.tabHome,
          ),
          TabItem(
            icon: PhosphorIconsRegular.folder,
            activeIcon: PhosphorIconsFill.folder,
            label: l.tabFiles,
          ),
          TabItem(
            icon: PhosphorIconsRegular.wrench,
            activeIcon: PhosphorIconsFill.wrench,
            label: l.tabTools,
          ),
        ],
      ),
    );
  }
}

/// The one elevated control in the app besides sheets (BLUEPRINT 9.3).
class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: c.primary,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.x4 + 2,
              vertical: Space.x3 + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.scan,
                  size: Sizes.icon,
                  color: c.onPrimary,
                ),
                const SizedBox(width: Space.x2),
                Text(
                  label,
                  style: DocNookText.label.copyWith(
                    color: c.onPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

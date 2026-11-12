import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/components/tool_tile.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// S03 Home. In this build it shows the shell, quick actions and the empty
/// state; Recents and Continue reading are wired in Phase 2.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    void later() => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.comingInPhase)));

    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverToBoxAdapter(
            child: LargeTitle(
              l.appName,
              actions: [
                IconAction(
                  icon: PhosphorIconsRegular.gear,
                  label: l.actionSettings,
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SearchField(
            hint: l.searchHint,
            icon: PhosphorIconsRegular.magnifyingGlass,
            onTap: later,
          ),
        ),
        SliverToBoxAdapter(child: SectionHeader(l.homeQuickActions)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x2),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: QuickAction(
                    icon: PhosphorIconsRegular.scan,
                    label: l.quickScan,
                    onTap: later,
                  ),
                ),
                Expanded(
                  child: QuickAction(
                    icon: PhosphorIconsRegular.folderOpen,
                    label: l.quickOpenFile,
                    onTap: later,
                  ),
                ),
                Expanded(
                  child: QuickAction(
                    icon: PhosphorIconsRegular.stack,
                    label: l.quickMerge,
                    onTap: later,
                  ),
                ),
                Expanded(
                  child: QuickAction(
                    icon: PhosphorIconsRegular.arrowsLeftRight,
                    label: l.quickConvert,
                    onTap: later,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: EmptyState(
              art: EmptyArt.paperStack,
              title: l.homeEmptyTitle,
              primaryLabel: l.actionOpenFile,
              onPrimary: later,
              secondaryLabel: l.actionFindDocuments,
              onSecondary: later,
            ),
          ),
        ),
      ],
    );
  }
}

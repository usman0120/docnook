import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:flutter/material.dart';

/// S04 Files. The library arrives in Phase 3; this build shows its empty
/// state.
class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

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
          sliver: SliverToBoxAdapter(child: LargeTitle(l.filesTitle)),
        ),
        SliverToBoxAdapter(
          child: SearchField(
            hint: l.searchHint,
            icon: PhosphorIconsRegular.magnifyingGlass,
            onTap: later,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: EmptyState(
              art: EmptyArt.openFolder,
              title: l.filesEmptyTitle,
              body: l.filesEmptyBody,
              primaryLabel: l.actionFindDocuments,
              onPrimary: later,
              secondaryLabel: l.actionOpenFile,
              onSecondary: later,
            ),
          ),
        ),
      ],
    );
  }
}

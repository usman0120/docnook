import 'dart:async';

import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/components/tool_tile.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/features/home/application/open_actions.dart';
import 'package:docnook/features/library/presentation/access_primer.dart';
import 'package:docnook/features/library/presentation/file_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// S03 Home: search, Continue reading, quick actions, Recent.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final recent = ref.watch(recentDocumentsProvider);
    void later() => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.comingInPhase)));
    void open() => unawaited(pickAndOpen(context, ref));

    final docs = recent.value ?? const <DocumentInfo>[];
    final continuing = [
      for (final d in docs)
        if ((d.progress ?? 0) > 0 && (d.progress ?? 0) < 0.98) d,
    ].take(6).toList();

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
            onTap: () => context.push('/search'),
          ),
        ),
        if (continuing.isNotEmpty) ...[
          SliverToBoxAdapter(child: SectionHeader(l.homeContinueReading)),
          SliverToBoxAdapter(child: _ContinueRow(docs: continuing)),
        ],
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
                    onTap: open,
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
                    onTap: () => context.go('/tools'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (recent.isLoading && docs.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: LoadingState())
        else if (docs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(
                art: EmptyArt.paperStack,
                title: l.homeEmptyTitle,
                primaryLabel: l.actionOpenFile,
                onPrimary: open,
                secondaryLabel: l.actionFindDocuments,
                onSecondary: () => unawaited(showAccessPrimer(context, ref)),
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(child: SectionHeader(l.homeRecent)),
          SliverList.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Hairline(indent: 76),
            itemBuilder: (context, i) => _RecentRow(doc: docs[i]),
          ),
          // Room above the Scan button.
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ],
    );
  }
}

class _RecentRow extends ConsumerWidget {
  const _RecentRow({required this.doc});
  final DocumentInfo doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final thumbs = ref.watch(thumbnailCacheProvider);
    return FileRow(
      type: doc.type,
      name: doc.name,
      details: l.documentDetails(doc),
      thumbnail: thumbs.imageFor(doc.thumbKey),
      starred: doc.starred,
      missing: doc.missing,
      onTap: () => unawaited(openDocument(context, doc)),
      onMore: () =>
          unawaited(showFileActions(context, ref, doc, inRecents: true)),
      moreLabel: l.actionMore,
    );
  }
}

/// Horizontal row of documents in progress, largest thumbnails on Home.
class _ContinueRow extends ConsumerWidget {
  const _ContinueRow({required this.docs});
  final List<DocumentInfo> docs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final thumbs = ref.watch(thumbnailCacheProvider);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: 196 + (scale - 1) * 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.screen),
        itemCount: docs.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.x3),
        itemBuilder: (context, i) {
          final doc = docs[i];
          return SizedBox(
            width: 104,
            child: Semantics(
              button: true,
              label: doc.name,
              excludeSemantics: true,
              child: InkWell(
                onTap: () => unawaited(openDocument(context, doc)),
                borderRadius: Radii.chipAll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PaperThumb(
                      type: doc.type,
                      image: thumbs.imageFor(doc.thumbKey),
                      width: 104,
                    ),
                    const SizedBox(height: Space.x2),
                    ThinProgress(doc.progress ?? 0),
                    const SizedBox(height: Space.x2),
                    Text(
                      doc.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DocNookText.caption.copyWith(
                        color: c.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

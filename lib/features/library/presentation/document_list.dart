import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Documents as a sliver list or grid, with multi-select support. Shared by
/// Files, Collection detail and Search.
class DocumentSliver extends ConsumerWidget {
  const DocumentSliver({
    required this.docs,
    required this.grid,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onMore,
    super.key,
  });

  final List<DocumentInfo> docs;
  final bool grid;
  final Set<int> selected;
  final void Function(DocumentInfo) onTap;
  final void Function(DocumentInfo) onLongPress;
  final void Function(DocumentInfo) onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final thumbs = ref.watch(thumbnailCacheProvider);
    final selecting = selected.isNotEmpty;

    if (grid) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      return SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.screen - Space.x1,
        ),
        sliver: SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 128,
            mainAxisSpacing: Space.x3,
            crossAxisSpacing: Space.x2,
            // Thumb (3:4) plus two name lines and one detail line.
            childAspectRatio: 0.52 / (scale > 1.3 ? 1.25 : 1),
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            return FileTile(
              type: doc.type,
              name: doc.name,
              details: l.documentDetails(doc),
              thumbnail: thumbs.imageFor(doc.thumbKey),
              progress: doc.progress,
              selected: selected.contains(doc.id),
              onTap: () => selecting ? onLongPress(doc) : onTap(doc),
              onLongPress: () => onLongPress(doc),
            );
          },
        ),
      );
    }

    return SliverList.separated(
      itemCount: docs.length,
      separatorBuilder: (_, _) => const Hairline(indent: 76),
      itemBuilder: (context, i) {
        final doc = docs[i];
        return FileRow(
          type: doc.type,
          name: doc.name,
          details: l.documentDetails(doc),
          thumbnail: thumbs.imageFor(doc.thumbKey),
          starred: doc.starred,
          missing: doc.missing,
          selected: selected.contains(doc.id),
          selecting: selecting,
          onTap: () => selecting ? onLongPress(doc) : onTap(doc),
          onLongPress: () => onLongPress(doc),
          onMore: () => onMore(doc),
          moreLabel: l.actionMore,
        );
      },
    );
  }
}

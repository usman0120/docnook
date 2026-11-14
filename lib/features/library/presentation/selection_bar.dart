import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/features/library/presentation/file_sheets.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Replaces the large title while documents are selected.
class SelectionHeader extends StatelessWidget {
  const SelectionHeader({
    required this.count,
    required this.onClose,
    required this.onSelectAll,
    super.key,
  });

  final int count;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.x1,
        Space.x3,
        Space.x2,
        Space.x2,
      ),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            IconAction(
              icon: PhosphorIconsRegular.x,
              label: l.actionDeselect,
              onPressed: onClose,
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l.selectedCount(count),
                  style: DocNookText.sectionTitle.copyWith(color: c.ink),
                ),
              ),
            ),
            QuietButton(label: l.actionSelectAllItems, onPressed: onSelectAll),
          ],
        ),
      ),
    );
  }
}

/// Bottom bar of actions for selected documents (BLUEPRINT S04).
class SelectionActionBar extends ConsumerWidget {
  const SelectionActionBar({
    required this.docs,
    required this.onDone,
    this.collectionId,
    super.key,
  });

  final List<DocumentInfo> docs;
  final VoidCallback onDone;
  final int? collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final allStarred = docs.every((d) => d.starred);
    final mergeable =
        docs.length > 1 &&
        docs.every((d) => d.type == DocType.pdf || d.type == DocType.image);

    final items = <(String, IconData, VoidCallback)>[
      (
        l.actionShare,
        PhosphorIconsRegular.shareNetwork,
        () => unawaited(shareDocuments(context, ref, docs)),
      ),
      (
        allStarred ? l.actionUnstar : l.actionStar,
        allStarred ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
        () async {
          await setStarred(context, ref, docs, starred: !allStarred);
          onDone();
        },
      ),
      (
        l.actionAddToCollection,
        PhosphorIconsRegular.folderPlus,
        () async {
          await addToCollection(context, ref, docs);
          onDone();
        },
      ),
      if (mergeable)
        (
          l.actionMerge,
          PhosphorIconsRegular.stack,
          () {
            onDone();
            unawaited(
              context.push(
                '/tool/merge',
                extra: [
                  for (final d in docs)
                    ToolInput(
                      uri: d.uri,
                      name: d.name,
                      mime: d.mime,
                      size: d.sizeBytes,
                      documentId: d.id,
                    ),
                ],
              ),
            );
          },
        ),
      if (_converter(docs) case final convert?)
        (
          l.actionConvert,
          PhosphorIconsRegular.arrowsLeftRight,
          () {
            onDone();
            unawaited(
              context.push(
                '/tool/${convert.name}',
                extra: [for (final d in docs) _input(d)],
              ),
            );
          },
        ),
      (
        l.actionDelete,
        PhosphorIconsRegular.trash,
        () async {
          if (await deleteDocuments(context, ref, docs)) onDone();
        },
      ),
    ];

    return Material(
      color: c.paper,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.hairline)),
        ),
        child: Row(
          children: [
            for (final (label, icon, onTap) in items)
              Expanded(
                child: Semantics(
                  button: true,
                  label: label,
                  onTap: onTap,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 64),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: Sizes.icon,
                            color: icon == PhosphorIconsRegular.trash
                                ? c.danger
                                : c.ink,
                          ),
                          const SizedBox(height: Space.x1),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DocNookText.caption.copyWith(
                              color: c.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

ToolInput _input(DocumentInfo d) => ToolInput(
  uri: d.uri,
  name: d.name,
  mime: d.mime,
  size: d.sizeBytes,
  documentId: d.id,
);

/// The batch converter that takes every selected file, if there is one:
/// pictures → one PDF, Word / Excel / PowerPoint → PDFs.
ToolId? _converter(List<DocumentInfo> docs) {
  for (final tool in const [
    ToolId.imagesToPdf,
    ToolId.wordToPdf,
    ToolId.excelToPdf,
    ToolId.pptToPdf,
    ToolId.pdfToImages,
  ]) {
    if (docs.every((d) => tool.accepts.contains(_input(d).format))) return tool;
  }
  return null;
}

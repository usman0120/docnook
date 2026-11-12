import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/data/db/app_database.dart';
import 'package:docnook/data/repositories/document_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Asks for a page number; returns null when cancelled.
Future<int?> askPageNumber(
  BuildContext context, {
  required int current,
  required int total,
}) => showDialog<int>(
  context: context,
  builder: (context) {
    final l = AppLocalizations.of(context);
    final field = TextEditingController(text: '$current')
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: '$current'.length,
      );
    void submit() {
      final page = int.tryParse(field.text.trim());
      if (page != null && page >= 1 && page <= total)
        Navigator.of(context).pop(page);
    }

    return AlertDialog(
      title: Text(l.pdfGoToPage),
      content: TextField(
        controller: field,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: l.pdfPageNumberHint(total)),
        onSubmitted: (_) => submit(),
      ),
      actions: [
        QuietButton(
          label: l.actionCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        QuietButton(label: l.actionGo, onPressed: submit),
      ],
    );
  },
);

/// Grid of real page thumbnails; returns the tapped page.
Future<int?> showPageThumbnails(
  BuildContext context, {
  required PdfDocument document,
  required int current,
}) {
  final l = AppLocalizations.of(context);
  return showDocNookSheet<int>(
    context,
    title: l.pdfThumbnails,
    expand: true,
    builder: (context, scroll) {
      final c = context.colors;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      return GridView.builder(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          Space.x2,
          Space.screen,
          Space.x8,
        ),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 120,
          mainAxisSpacing: Space.x4,
          crossAxisSpacing: Space.x3,
          childAspectRatio: 0.62 / (scale > 1.4 ? 1.15 : 1),
        ),
        itemCount: document.pages.length,
        itemBuilder: (context, i) {
          final page = i + 1;
          final selected = page == current;
          return Semantics(
            button: true,
            selected: selected,
            label: l.pdfBookmarkLabel(page),
            excludeSemantics: true,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(page),
              borderRadius: Radii.chipAll,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: selected ? c.primary : c.hairline,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: PdfPageView(document: document, pageNumber: page),
                    ),
                  ),
                  const SizedBox(height: Space.x1),
                  Text(
                    '$page',
                    style: DocNookText.caption.copyWith(
                      color: selected ? c.primary : c.inkMuted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// The PDF's table of contents; returns the chosen destination.
Future<PdfDest?> showOutline(
  BuildContext context,
  List<PdfOutlineNode> outline,
) {
  final l = AppLocalizations.of(context);
  final flat = <(PdfOutlineNode, int)>[];
  void walk(List<PdfOutlineNode> nodes, int depth) {
    for (final node in nodes) {
      flat.add((node, depth));
      if (depth < 6) walk(node.children, depth + 1);
    }
  }

  walk(outline, 0);
  return showDocNookSheet<PdfDest>(
    context,
    title: l.pdfOutline,
    expand: flat.length > 8,
    builder: (context, scroll) {
      final c = context.colors;
      if (flat.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.x4,
            Space.screen,
            Space.x8,
          ),
          child: Text(
            l.pdfNoOutline,
            style: DocNookText.body.copyWith(color: c.inkMuted),
          ),
        );
      }
      return ListView.builder(
        controller: scroll,
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: Space.x8),
        itemCount: flat.length,
        itemBuilder: (context, i) {
          final (node, depth) = flat[i];
          final page = node.dest?.pageNumber;
          return InkWell(
            onTap: node.dest == null
                ? null
                : () => Navigator.of(context).pop(node.dest),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Sizes.touch),
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: Space.screen + depth * Space.x4,
                  end: Space.screen,
                  top: Space.x2,
                  bottom: Space.x2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        node.title.trim(),
                        style:
                            (depth == 0
                                    ? DocNookText.bodyStrong
                                    : DocNookText.body)
                                .copyWith(
                                  color: depth == 0 ? c.ink : c.inkMuted,
                                ),
                      ),
                    ),
                    if (page != null) ...[
                      const SizedBox(width: Space.x3),
                      Text(
                        '$page',
                        style: DocNookText.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Bookmarks for this document, with add/remove; returns the chosen page.
Future<int?> showBookmarks(
  BuildContext context, {
  required DocumentRepository repository,
  required int documentId,
  required int currentPage,
}) {
  final l = AppLocalizations.of(context);
  return showDocNookSheet<int>(
    context,
    title: l.pdfBookmarks,
    builder: (context, scroll) {
      final c = context.colors;
      return StreamBuilder<List<BookmarkRow>>(
        stream: repository.watchBookmarks(documentId),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <BookmarkRow>[];
          final pages = {
            for (final r in rows) DocumentRepository.bookmarkPage(r),
          };
          final hasCurrent = pages.contains(currentPage);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.screen,
                  vertical: Space.x2,
                ),
                child: SecondaryButton(
                  label: hasCurrent ? l.pdfRemoveBookmark : l.pdfAddBookmark,
                  icon: hasCurrent
                      ? PhosphorIconsFill.bookmarkSimple
                      : PhosphorIconsRegular.bookmarkSimple,
                  onPressed: () async {
                    if (hasCurrent) {
                      final row = rows.firstWhere(
                        (r) =>
                            DocumentRepository.bookmarkPage(r) == currentPage,
                      );
                      await repository.removeBookmark(row.id);
                    } else {
                      await repository.addBookmark(
                        documentId,
                        page: currentPage,
                        label: l.pdfBookmarkLabel(currentPage),
                      );
                    }
                  },
                ),
              ),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.screen,
                    Space.x2,
                    Space.screen,
                    Space.x8,
                  ),
                  child: Text(
                    l.pdfNoBookmarks,
                    style: DocNookText.body.copyWith(color: c.inkMuted),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    controller: scroll,
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: Space.x8),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) =>
                        const Hairline(indent: Space.screen),
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      final page = DocumentRepository.bookmarkPage(row);
                      return ListTile(
                        leading: Icon(
                          PhosphorIconsFill.bookmarkSimple,
                          size: Sizes.iconSmall,
                          color: c.accent,
                        ),
                        title: Text(row.label),
                        onTap: page == null
                            ? null
                            : () => Navigator.of(context).pop(page),
                        trailing: IconAction(
                          icon: PhosphorIconsRegular.trash,
                          label: l.pdfRemoveBookmark,
                          color: c.inkMuted,
                          onPressed: () =>
                              unawaited(repository.removeBookmark(row.id)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}

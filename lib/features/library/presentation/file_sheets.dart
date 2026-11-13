import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/data/files/file_type_detector.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/features/library/application/library_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

void _snack(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// S27: everything you can do with one document.
Future<void> showFileActions(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo doc, {
  int? collectionId,
  bool inRecents = false,
}) async {
  final l = AppLocalizations.of(context);
  final actions = <(IconData, String, Future<void> Function(), bool)>[
    (
      PhosphorIconsRegular.arrowSquareOut,
      l.actionOpenWith,
      () => _openWith(context, ref, doc),
      false,
    ),
    (
      PhosphorIconsRegular.shareNetwork,
      l.actionShare,
      () => shareDocuments(context, ref, [doc]),
      false,
    ),
    (
      PhosphorIconsRegular.pencilSimple,
      l.actionRename,
      () => renameDocument(context, ref, doc),
      false,
    ),
    (
      doc.starred ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
      doc.starred ? l.actionUnstar : l.actionStar,
      () => setStarred(context, ref, [doc], starred: !doc.starred),
      false,
    ),
    (
      PhosphorIconsRegular.folderPlus,
      l.actionAddToCollection,
      () => addToCollection(context, ref, [doc]),
      false,
    ),
    if (collectionId != null)
      (
        PhosphorIconsRegular.folderMinus,
        l.actionRemoveFromCollection,
        () => ref.read(libraryRepositoryProvider).removeFromCollection(
          collectionId,
          [doc.id],
        ),
        false,
      ),
    if (inRecents)
      (
        PhosphorIconsRegular.clockCounterClockwise,
        l.actionRemoveFromRecents,
        () => ref.read(documentRepositoryProvider).clearRecent(doc.id),
        false,
      ),
    (
      PhosphorIconsRegular.info,
      l.actionInfo,
      () => showDocumentInfo(context, ref, doc),
      false,
    ),
    (
      PhosphorIconsRegular.trash,
      l.actionDelete,
      () => deleteDocuments(context, ref, [doc]),
      true,
    ),
  ];

  final chosen = await showDocNookSheet<int>(
    context,
    builder: (context, _) {
      final c = context.colors;
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                0,
                Space.screen,
                Space.x3,
              ),
              child: Row(
                children: [
                  PaperThumb(
                    type: doc.type,
                    image: ref
                        .read(thumbnailCacheProvider)
                        .imageFor(doc.thumbKey),
                    width: 36,
                  ),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DocNookText.bodyStrong.copyWith(color: c.ink),
                        ),
                        Text(
                          l.documentDetails(doc),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DocNookText.caption.copyWith(
                            color: c.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Hairline(),
            for (var i = 0; i < actions.length; i++)
              ListTile(
                leading: Icon(
                  actions[i].$1,
                  size: Sizes.icon,
                  color: actions[i].$4 ? c.danger : c.ink,
                ),
                title: Text(
                  actions[i].$2,
                  style: actions[i].$4
                      ? DocNookText.body.copyWith(color: c.danger)
                      : null,
                ),
                onTap: () => Navigator.of(context).pop(i),
              ),
            const SizedBox(height: Space.x2),
          ],
        ),
      );
    },
  );
  if (chosen != null && context.mounted) await actions[chosen].$3();
}

Future<void> _openWith(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo doc,
) async {
  final ok = await ref.read(platformProvider).openWith(doc.uri, mime: doc.mime);
  if (!ok && context.mounted) {
    _snack(context, AppLocalizations.of(context).errNoAppToOpen);
  }
}

Future<void> shareDocuments(
  BuildContext context,
  WidgetRef ref,
  List<DocumentInfo> docs,
) async {
  final mimes = {for (final d in docs) d.mime ?? '*/*'};
  await ref.read(platformProvider).share([
    for (final d in docs) d.uri,
  ], mime: mimes.length == 1 ? mimes.first : '*/*');
}

Future<void> setStarred(
  BuildContext context,
  WidgetRef ref,
  List<DocumentInfo> docs, {
  required bool starred,
}) async {
  final repo = ref.read(documentRepositoryProvider);
  for (final d in docs) {
    await repo.setStarred(d.id, starred: starred);
  }
  if (context.mounted) {
    final l = AppLocalizations.of(context);
    _snack(context, starred ? l.starredDone : l.unstarredDone);
  }
}

/// Asks for a single line of text; returns null when cancelled.
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  String initial = '',
  bool selectStem = false,
}) => showDialog<String>(
  context: context,
  builder: (context) {
    final l = AppLocalizations.of(context);
    final dot = initial.lastIndexOf('.');
    final field = TextEditingController(text: initial)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: selectStem && dot > 0 ? dot : initial.length,
      );
    void submit() {
      final text = field.text.trim();
      if (text.isNotEmpty) Navigator.of(context).pop(text);
    }

    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: field,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (_) => submit(),
      ),
      actions: [
        QuietButton(
          label: l.actionCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        QuietButton(label: action, onPressed: submit),
      ],
    );
  },
);

Future<void> renameDocument(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo doc,
) async {
  final l = AppLocalizations.of(context);
  var name = await askText(
    context,
    title: l.renameTitle,
    label: l.renameLabel,
    action: l.actionRename,
    initial: doc.name,
    selectStem: true,
  );
  if (name == null || name == doc.name || !context.mounted) return;
  name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  // Keep the extension if the user removed it.
  final ext = FileTypeDetector.extensionOf(doc.name);
  if (ext.isNotEmpty && FileTypeDetector.extensionOf(name) != ext) {
    name = '$name.$ext';
  }

  final newUri = await ref.read(platformProvider).renameDocument(doc.uri, name);
  if (!context.mounted) return;
  if (newUri == null) {
    _snack(context, l.renameFailed);
    return;
  }
  await ref
      .read(documentRepositoryProvider)
      .rename(doc.id, uri: newUri, name: name);
  if (context.mounted) _snack(context, l.renamed);
}

Future<bool> deleteDocuments(
  BuildContext context,
  WidgetRef ref,
  List<DocumentInfo> docs,
) async {
  final l = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.deleteTitle(docs.length)),
      content: Text(l.deleteBody),
      actions: [
        QuietButton(
          label: l.actionCancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        QuietButton(
          label: l.actionDelete,
          color: context.colors.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final platform = ref.read(platformProvider);
  final repo = ref.read(documentRepositoryProvider);
  var deleted = 0;
  for (final d in docs) {
    if (await platform.deleteDocument(d.uri)) {
      await repo.remove(d.id);
      deleted++;
    }
  }
  if (context.mounted) {
    _snack(
      context,
      deleted == docs.length ? l.deleted(deleted) : l.deleteFailed,
    );
  }
  return deleted > 0;
}

Future<void> addToCollection(
  BuildContext context,
  WidgetRef ref,
  List<DocumentInfo> docs,
) async {
  final l = AppLocalizations.of(context);
  final library = ref.read(libraryRepositoryProvider);
  final collections = await library.watchCollections().first;
  if (!context.mounted) return;
  final chosen = await showDocNookSheet<int>(
    context,
    title: l.actionAddToCollection,
    builder: (context, _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(
            PhosphorIconsRegular.plus,
            size: Sizes.icon,
            color: context.colors.primary,
          ),
          title: Text(
            l.newCollection,
            style: DocNookText.body.copyWith(color: context.colors.primary),
          ),
          onTap: () => Navigator.of(context).pop(-1),
        ),
        for (final col in collections)
          ListTile(
            leading: const Icon(
              PhosphorIconsRegular.folderSimple,
              size: Sizes.icon,
            ),
            title: Text(col.name),
            trailing: Text(
              '${col.count}',
              style: DocNookText.caption.copyWith(
                color: context.colors.inkMuted,
              ),
            ),
            onTap: () => Navigator.of(context).pop(col.id),
          ),
        const SizedBox(height: Space.x4),
      ],
    ),
  );
  if (chosen == null || !context.mounted) return;

  var id = chosen;
  var name = collections.where((c) => c.id == chosen).firstOrNull?.name;
  if (chosen == -1) {
    name = await askText(
      context,
      title: l.newCollection,
      label: l.collectionName,
      action: l.collectionCreate,
    );
    if (name == null) return;
    id = await library.createCollection(name);
  }
  await library.addToCollection(id, [for (final d in docs) d.id]);
  if (context.mounted && name != null) {
    _snack(context, l.addedToCollection(name));
  }
}

/// S26: document facts in a bottom sheet.
Future<void> showDocumentInfo(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo doc,
) async {
  final l = AppLocalizations.of(context);
  final collections = await ref
      .read(libraryRepositoryProvider)
      .collectionsOf(doc.id);
  if (!context.mounted) return;
  final date = DateFormat('d MMM y, HH:mm');
  final rows = <(String, String)>[
    (
      l.infoType,
      '${docTypeMark(doc.type)}${doc.extension != null ? ' (.${doc.extension})' : ''}',
    ),
    if (doc.sizeBytes != null) (l.infoSize, l.fileSize(doc.sizeBytes!)),
    if (doc.pageCount != null && doc.type == DocType.pdf)
      (l.infoPages, '${doc.pageCount}'),
    if (doc.modifiedAt != null) (l.infoModified, date.format(doc.modifiedAt!)),
    if (doc.lastOpenedAt != null)
      (l.infoLastOpened, date.format(doc.lastOpenedAt!)),
    (l.infoLocation, _readableLocation(doc.uri)),
    if (collections.isNotEmpty) (l.infoCollections, collections.join(', ')),
    (l.infoIndexed, doc.indexed ? l.yes : l.no),
  ];
  await showDocNookSheet<void>(
    context,
    builder: (context, _) {
      final c = context.colors;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          0,
          Space.screen,
          Space.x6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PaperThumb(
                  type: doc.type,
                  image: ref
                      .read(thumbnailCacheProvider)
                      .imageFor(doc.thumbKey),
                  width: 64,
                ),
                const SizedBox(width: Space.x4),
                Expanded(
                  child: Text(
                    doc.name,
                    style: DocNookText.sectionTitle.copyWith(color: c.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.x4),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.x2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        label,
                        style: DocNookText.body.copyWith(color: c.inkMuted),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        value,
                        style: DocNookText.body.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

String _readableLocation(String uri) {
  if (!uri.startsWith('content://')) {
    return uri.replaceFirst(RegExp('^/storage/emulated/0/'), '');
  }
  final decoded = Uri.decodeComponent(uri);
  final colon = decoded.lastIndexOf(':');
  return colon > 0 ? decoded.substring(colon + 1) : decoded;
}

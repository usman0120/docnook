import 'dart:async';
import 'dart:io';

import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/data/files/file_type_detector.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/engines/archive/safe_zip.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/presentation/cant_open_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

/// One file or folder inside an archive.
final class ArchiveItem {
  const ArchiveItem(this.path, this.size, {required this.isDir});
  final String path;
  final int size;
  final bool isDir;
}

/// Lists a ZIP's entries without extracting anything. A [JobBody].
List<ArchiveItem> listArchive(String path, JobContext context) {
  final zip = SafeZip.open(path);
  try {
    return [
      for (final e in zip.entries)
        ArchiveItem(e.name.replaceAll(r'\', '/'), e.size, isDir: !e.isFile),
    ];
  } finally {
    zip.close();
  }
}

final class ExtractRequest {
  const ExtractRequest(this.zipPath, this.entries, this.destination);
  final String zipPath;
  final List<String> entries;
  final String destination;
}

/// Extracts [ExtractRequest.entries] into the destination folder, refusing
/// any entry whose name would escape it (zip-slip, BLUEPRINT 8.1). Returns
/// the written paths. A [JobBody].
List<String> extractEntries(ExtractRequest request, JobContext context) {
  final zip = SafeZip.open(request.zipPath);
  final written = <String>[];
  try {
    for (var i = 0; i < request.entries.length; i++) {
      final name = request.entries[i];
      final safe = SafeZip.safeRelativePath(name);
      if (safe == null) continue;
      final bytes = zip.bytes(name);
      if (bytes == null) continue;
      final out = File(p.join(request.destination, safe));
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes, flush: true);
      written.add(out.path);
      context.progress((i + 1) / request.entries.length);
    }
    return written;
  } finally {
    zip.close();
  }
}

/// S22 archive browser.
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({required this.document, super.key});

  final OpenedDocument document;

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  Result<List<ArchiveItem>>? _items;
  String _folder = '';
  final _selected = <String>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result = await ref
        .read(jobRunnerProvider)
        .run(listArchive, widget.document.path)
        .result;
    if (mounted) setState(() => _items = result);
  }

  /// Direct children of the current folder, folders first.
  List<ArchiveItem> _children(List<ArchiveItem> all) {
    final out = <String, ArchiveItem>{};
    final prefix = _folder;
    for (final item in all) {
      if (!item.path.startsWith(prefix)) continue;
      final rest = item.path.substring(prefix.length);
      if (rest.isEmpty) continue;
      final slash = rest.indexOf('/');
      if (slash >= 0 && slash < rest.length - 1) {
        final dir = '$prefix${rest.substring(0, slash + 1)}';
        out.putIfAbsent(dir, () => ArchiveItem(dir, 0, isDir: true));
      } else if (!item.isDir) {
        out[item.path] = item;
      } else {
        out.putIfAbsent(
          item.path.endsWith('/') ? item.path : '${item.path}/',
          () => item,
        );
      }
    }
    final list = out.values.toList()
      ..sort((a, b) {
        if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
    return list;
  }

  String _name(ArchiveItem item) {
    final path = item.path.endsWith('/')
        ? item.path.substring(0, item.path.length - 1)
        : item.path;
    return path.split('/').last;
  }

  Future<void> _open(ArchiveItem item) async {
    final paths = ref.read(appPathsProvider);
    final dest = p.join(paths.tmp, 'zip_${widget.document.documentId}');
    setState(() => _busy = true);
    final result = await ref
        .read(jobRunnerProvider)
        .run(
          extractEntries,
          ExtractRequest(widget.document.path, [item.path], dest),
        )
        .result;
    if (!mounted) return;
    setState(() => _busy = false);
    final written = result.valueOrNull;
    if (written == null || written.isEmpty) {
      _snack(AppLocalizations.of(context).errCorruptTitle);
      return;
    }
    await context.push(
      '/view',
      extra: OpenRequest(
        uri: written.first,
        name: _name(item),
        source: DocSource.created,
      ),
    );
  }

  Future<void> _extractSelected(List<ArchiveItem> all) async {
    final l = AppLocalizations.of(context);
    final names = _selected.isEmpty
        ? [
            for (final i in all)
              if (!i.isDir) i.path,
          ]
        : _selected.toList();
    final unsafe = names
        .where((n) => SafeZip.safeRelativePath(n) == null)
        .length;
    final tmp = p.join(
      ref.read(appPathsProvider).tmp,
      'extract_${DateTime.now().millisecondsSinceEpoch}',
    );
    setState(() => _busy = true);
    final result = await ref
        .read(jobRunnerProvider)
        .run(
          extractEntries,
          ExtractRequest(widget.document.path, names, tmp),
          timeout: const Duration(minutes: 5),
        )
        .result;
    var saved = 0;
    final platform = ref.read(platformProvider);
    final base = p.basenameWithoutExtension(widget.document.name);
    for (final path in result.valueOrNull ?? const <String>[]) {
      final rel = p.relative(path, from: tmp).replaceAll(r'\', '/');
      final sub = p.dirname(rel) == '.' ? '' : '/${p.dirname(rel)}';
      final format = FileTypeDetector.formatForExtension(
        FileTypeDetector.extensionOf(rel),
      );
      final r = await platform.saveToDocuments(
        source: path,
        subdir: 'Extracted/$base$sub',
        name: p.basename(rel),
        mime: format?.mime ?? 'application/octet-stream',
      );
      if (r.isOk) saved++;
    }
    try {
      await Directory(tmp).delete(recursive: true);
    } on FileSystemException {
      // Swept on next start.
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _selected.clear();
    });
    _snack(
      unsafe > 0
          ? '${l.zipExtracted(saved)}. ${l.zipUnsafe(unsafe)}'
          : l.zipExtracted(saved),
    );
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final items = _items;
    if (items case Err(:final failure)) {
      return CantOpenScreen(
        failure: failure,
        onOpenWith: () => unawaited(
          ref
              .read(platformProvider)
              .openWith(widget.document.request.uri, mime: 'application/zip'),
        ),
      );
    }
    final all = items?.valueOrNull;
    final children = all == null ? const <ArchiveItem>[] : _children(all);
    final selecting = _selected.isNotEmpty;

    return PopScope(
      canPop: _folder.isEmpty && !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          if (selecting) {
            _selected.clear();
          } else {
            final trimmed = _folder.substring(0, _folder.length - 1);
            _folder = trimmed.contains('/')
                ? trimmed.substring(0, trimmed.lastIndexOf('/') + 1)
                : '';
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconAction(
            icon: selecting
                ? PhosphorIconsRegular.x
                : PhosphorIconsRegular.arrowLeft,
            label: selecting ? l.actionDeselect : l.actionBack,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            selecting
                ? l.selectedCount(_selected.length)
                : widget.document.name,
          ),
          bottom: _folder.isEmpty
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(28),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.screen,
                      0,
                      Space.screen,
                      Space.x2,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '/$_folder',
                        style: DocNookText.caption.copyWith(color: c.inkMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: all == null || all.isEmpty
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(Space.screen),
                  child: PrimaryButton(
                    label: selecting
                        ? '${l.zipExtract} (${_selected.length})'
                        : l.zipExtract,
                    icon: PhosphorIconsRegular.export,
                    busy: _busy,
                    onPressed: () => unawaited(_extractSelected(all)),
                  ),
                ),
              ),
        body: all == null
            ? const LoadingState()
            : all.isEmpty
            ? Center(
                child: EmptyState(art: EmptyArt.openFolder, title: l.zipEmpty),
              )
            : ListView.separated(
                itemCount: children.length + 1,
                separatorBuilder: (_, i) => i == 0
                    ? const SizedBox.shrink()
                    : const Hairline(indent: 60),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Space.screen,
                        Space.x2,
                        Space.screen,
                        Space.x2,
                      ),
                      child: Text(
                        l.zipEntries(all.where((e) => !e.isDir).length),
                        style: DocNookText.caption.copyWith(color: c.inkMuted),
                      ),
                    );
                  }
                  final item = children[i - 1];
                  final format = item.isDir
                      ? null
                      : FileTypeDetector.formatForExtension(
                          FileTypeDetector.extensionOf(item.path),
                        );
                  final selected = _selected.contains(item.path);
                  return ListTile(
                    selected: selected,
                    selectedTileColor: c.selection,
                    leading: item.isDir
                        ? Icon(
                            PhosphorIconsRegular.folder,
                            size: Sizes.icon,
                            color: c.inkMuted,
                          )
                        : TypeBadge(format?.docType ?? DocType.other),
                    title: Text(
                      _name(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: item.isDir ? null : Text(l.fileSize(item.size)),
                    trailing: selecting && !item.isDir
                        ? Icon(
                            selected
                                ? PhosphorIconsFill.checkCircle
                                : PhosphorIconsRegular.circle,
                            size: Sizes.icon,
                            color: selected ? c.primary : c.inkMuted,
                          )
                        : (item.isDir
                              ? Icon(
                                  PhosphorIconsRegular.caretRight,
                                  size: Sizes.iconSmall,
                                  color: c.inkMuted,
                                )
                              : null),
                    onTap: () {
                      if (item.isDir) {
                        setState(() => _folder = item.path);
                      } else if (selecting) {
                        setState(
                          () => selected
                              ? _selected.remove(item.path)
                              : _selected.add(item.path),
                        );
                      } else if (format != null && format.isSupported) {
                        unawaited(_open(item));
                      } else {
                        setState(() => _selected.add(item.path));
                      }
                    },
                    onLongPress: item.isDir
                        ? null
                        : () => setState(() => _selected.add(item.path)),
                  );
                },
              ),
      ),
    );
  }
}

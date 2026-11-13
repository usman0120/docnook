import 'dart:async';

import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/data/repositories/library_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/choice.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:docnook/features/library/presentation/files_screen.dart';
import 'package:docnook/features/scan/application/scan_service.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/presentation/viewer_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// S25 Export: name, format, page size, quality, OCR, collection.
class ScanExportScreen extends ConsumerStatefulWidget {
  const ScanExportScreen({required this.sessionId, super.key});

  final int sessionId;

  @override
  ConsumerState<ScanExportScreen> createState() => _ScanExportScreenState();
}

class _ScanExportScreenState extends ConsumerState<ScanExportScreen> {
  final _name = TextEditingController();
  bool _loaded = false;
  bool _asPdf = true;
  ScanPageSize _size = ScanPageSize.a4;
  ScanQuality _quality = ScanQuality.balanced;
  bool _ocr = false;
  int? _collection;
  bool _saving = false;

  /// Set once the scan is saved: the draft is gone, but the form stays on
  /// screen behind the result sheet.
  bool _finished = false;
  ScanSession? _last;
  List<(int, int)?>? _dims;
  bool _cancelled = false;
  double _progress = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _load(ScanSession s) {
    if (s.pages.isNotEmpty) _last = s;
    if (_loaded) return;
    _loaded = true;
    _dims = ScanService.pageDimensions(s);
    _name.text = s.title;
    _size = s.pageSize;
    _quality = s.quality;
    _ocr = s.ocrEnabled;
  }

  Future<void> _remember() => ref
      .read(scanRepositoryProvider)
      .updateSettings(
        widget.sessionId,
        title: _name.text.trim().isEmpty ? null : _name.text.trim(),
        pageSize: _size,
        quality: _quality,
        ocr: _ocr,
      );

  Future<void> _save(ScanSession session) async {
    FocusScope.of(context).unfocus();
    await _remember();
    setState(() {
      _saving = true;
      _cancelled = false;
      _progress = 0;
    });
    final result = await ref
        .read(scanServiceProvider)
        .export(
          session,
          ScanExportOptions(
            name: _name.text.trim().isEmpty ? session.title : _name.text.trim(),
            asPdf: _asPdf,
            pageSize: _size,
            quality: _quality,
            ocr: _ocr,
            collectionId: _collection,
          ),
          onProgress: (v) {
            if (mounted) setState(() => _progress = v);
          },
          isCancelled: () => _cancelled,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok(:final value):
        setState(() => _finished = true);
        await _showResult(value);
      case Err(:final failure):
        if (failure.kind == FailureKind.cancelled) return;
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                failure.kind == FailureKind.outOfSpace
                    ? l.scanSaveNoSpace
                    : l.scanSaveFailed,
              ),
            ),
          );
    }
  }

  /// S11-style result: what was saved, where, and what to do next.
  Future<void> _showResult(ScanExportResult r) async {
    final l = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final platform = ref.read(platformProvider);
    final type = r.mime == DocFormat.pdf.mime ? DocType.pdf : DocType.image;
    final action = await showDocNookSheet<String>(
      context,
      title: l.scanSavedTitle,
      builder: (context, _) {
        final c = context.colors;
        final details = [
          if (type == DocType.pdf) l.pagesCount(r.pageCount),
          if (type == DocType.image && r.names.length > 1)
            l.scanImagesCount(r.names.length),
          l.fileSize(r.totalBytes),
        ].join(' · ');
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            Space.x4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TypeSpine(type),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.names.first,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DocNookText.bodyStrong,
                        ),
                        const SizedBox(height: Space.x1),
                        Text(
                          details,
                          style: DocNookText.caption.copyWith(
                            color: c.inkMuted,
                          ),
                        ),
                        Text(
                          l.scanSavedLocation,
                          style: DocNookText.caption.copyWith(
                            color: c.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.x6),
              PrimaryButton(
                label: l.actionOpen,
                onPressed: () => Navigator.of(context).pop('open'),
              ),
              const SizedBox(height: Space.x2),
              SecondaryButton(
                label: l.actionShare,
                onPressed: () => Navigator.of(context).pop('share'),
              ),
            ],
          ),
        );
      },
    );
    router.go('/home');
    switch (action) {
      case 'open':
        unawaited(
          router.push(
            '/view',
            extra: OpenRequest(
              uri: r.paths.first,
              name: r.names.first,
              mime: r.mime,
              source: DocSource.scanned,
            ),
          ),
        );
      case 'share':
        unawaited(platform.share(r.paths, mime: r.mime));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final async = ref.watch(scanSessionProvider(widget.sessionId));
    final live = async.value;
    if (live != null) _load(live);
    final session = _finished ? _last : live;
    final collections = ref.watch(collectionsProvider).value ?? const [];

    return PopScope(
      canPop: !_saving && !_finished,
      child: Scaffold(
        backgroundColor: c.paper,
        body: Column(
          children: [
            ViewerTopBar(
              visible: true,
              title: l.scanSaveTitle,
              actions: const [],
            ),
            Expanded(
              child: switch (async) {
                AsyncError() => ErrorState(
                  title: l.scanLoadErrorTitle,
                  body: l.scanLoadErrorBody,
                ),
                _ when session == null && async.isLoading => const Center(
                  child: CircularProgressIndicator(),
                ),
                _ when session == null || session.pages.isEmpty => EmptyState(
                  art: EmptyArt.scannerFrame,
                  title: l.scanGoneTitle,
                  primaryLabel: l.actionBack,
                  onPrimary: () => context.go('/home'),
                ),
                _ => _form(context, session, collections),
              },
            ),
            if (session != null && session.pages.isNotEmpty)
              _bottom(context, session),
          ],
        ),
      ),
    );
  }

  Widget _form(
    BuildContext context,
    ScanSession session,
    List<CollectionInfo> collections,
  ) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final estimate = ScanService.estimateBytes(session, _quality, _dims);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.x6,
        Space.screen,
        Space.x2,
      ),
      child: Text(text, style: DocNookText.label.copyWith(color: c.inkMuted)),
    );
    return AbsorbPointer(
      absorbing: _saving || _finished,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Space.x6),
        children: [
          label(l.scanFieldName),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.screen),
            child: TextField(
              controller: _name,
              textInputAction: TextInputAction.done,
              style: DocNookText.body,
              onSubmitted: (_) => unawaited(_remember()),
            ),
          ),
          label(l.scanFieldFormat),
          _padded(
            SegmentedChoice<bool>(
              values: const [true, false],
              selected: _asPdf,
              label: (pdf) => pdf ? 'PDF' : 'JPG',
              onSelected: (v) => setState(() => _asPdf = v),
            ),
          ),
          if (_asPdf) ...[
            label(l.scanFieldPageSize),
            _padded(
              SegmentedChoice<ScanPageSize>(
                values: ScanPageSize.values,
                selected: _size,
                label: (s) => switch (s) {
                  ScanPageSize.a4 => 'A4',
                  ScanPageSize.letter => l.scanSizeLetter,
                  ScanPageSize.fit => l.scanSizeFit,
                },
                onSelected: (v) => setState(() => _size = v),
              ),
            ),
          ],
          label(l.scanFieldQuality),
          _padded(
            SegmentedChoice<ScanQuality>(
              values: ScanQuality.values,
              selected: _quality,
              label: (q) => switch (q) {
                ScanQuality.small => l.scanQualitySmall,
                ScanQuality.balanced => l.scanQualityBalanced,
                ScanQuality.best => l.scanQualityBest,
              },
              onSelected: (v) => setState(() => _quality = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.x2,
              Space.screen,
              0,
            ),
            child: Text(
              l.scanEstimate(l.fileSize(estimate)),
              style: DocNookText.caption.copyWith(color: c.inkMuted),
            ),
          ),
          const SizedBox(height: Space.x4),
          SwitchListTile(
            value: _ocr,
            onChanged: (v) => setState(() => _ocr = v),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Space.screen,
            ),
            title: Text(l.scanOcrToggle, style: DocNookText.body),
            subtitle: Text(
              l.scanOcrHelp,
              style: DocNookText.caption.copyWith(color: c.inkMuted),
            ),
          ),
          if (collections.isNotEmpty) ...[
            label(l.scanFieldCollection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.screen),
              child: DropdownButtonFormField<int?>(
                initialValue: _collection,
                isExpanded: true,
                decoration: const InputDecoration(),
                items: [
                  DropdownMenuItem<int?>(
                    child: Text(l.scanNoCollection, style: DocNookText.body),
                  ),
                  for (final col in collections)
                    DropdownMenuItem<int?>(
                      value: col.id,
                      child: Text(col.name, style: DocNookText.body),
                    ),
                ],
                onChanged: (v) => setState(() => _collection = v),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.screen),
    child: child,
  );

  Widget _bottom(BuildContext context, ScanSession session) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Space.screen),
          child: _saving
              ? Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.scanSaving((_progress * 100).round()),
                            style: DocNookText.label,
                          ),
                          const SizedBox(height: Space.x2),
                          ThinProgress(_progress),
                        ],
                      ),
                    ),
                    const SizedBox(width: Space.x3),
                    QuietButton(
                      label: l.actionCancel,
                      onPressed: _cancelled
                          ? null
                          : () => setState(() => _cancelled = true),
                    ),
                  ],
                )
              : PrimaryButton(
                  label: l.actionSave,
                  onPressed: _finished ? null : () => unawaited(_save(session)),
                ),
        ),
      ),
    );
  }
}

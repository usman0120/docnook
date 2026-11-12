import 'dart:async';

import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/archive/archive_screen.dart';
import 'package:docnook/features/viewer/docmodel/document_viewer_screen.dart';
import 'package:docnook/features/viewer/epub/epub_reader_screen.dart';
import 'package:docnook/features/viewer/image/image_viewer_screen.dart';
import 'package:docnook/features/viewer/pdf/pdf_viewer_screen.dart';
import 'package:docnook/features/viewer/sheet/sheet_viewer_screen.dart';
import 'package:docnook/features/viewer/slides/slides_viewer_screen.dart';
import 'package:docnook/features/viewer/text/markdown_viewer.dart';
import 'package:docnook/features/viewer/text/text_viewer_screen.dart';
import 'package:docnook/features/viewer/presentation/cant_open_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens a document and shows the viewer for its real type. Handles the
/// loading, too-large and error states shared by every viewer.
class ViewerHost extends ConsumerStatefulWidget {
  const ViewerHost({required this.request, super.key});

  final OpenRequest request;

  @override
  ConsumerState<ViewerHost> createState() => _ViewerHostState();
}

class _ViewerHostState extends ConsumerState<ViewerHost> {
  Result<OpenedDocument>? _result;
  bool _sizeAccepted = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    final result = await ref.read(openDocumentProvider).call(widget.request);
    if (mounted) setState(() => _result = result);
  }

  void _leave() {
    // Opened from another app: Back returns to it (BLUEPRINT 10.1).
    if (widget.request.fromIntent && !Navigator.of(context).canPop()) {
      unawaited(SystemNavigator.pop());
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final platform = ref.read(platformProvider);
    void openWith() => unawaited(
      platform.openWith(widget.request.uri, mime: widget.request.mime).then((
        ok,
      ) {
        if (!ok && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.errNoAppToOpen)));
        }
      }),
    );

    final result = _result;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconAction(
            icon: PhosphorIconsRegular.arrowLeft,
            label: l.actionBack,
            onPressed: _leave,
          ),
        ),
        body: LoadingState(label: l.openingFile),
      );
    }

    return switch (result) {
      Err(:final failure) => CantOpenScreen(
        failure: failure,
        onOpenWith: openWith,
      ),
      Ok(value: final doc) => _viewerFor(doc, l, openWith),
    };
  }

  Widget _viewerFor(
    OpenedDocument doc,
    AppLocalizations l,
    VoidCallback openWith,
  ) {
    final limit = safeLimitFor(doc.format);
    if (!_sizeAccepted && limit != null && (doc.sizeBytes ?? 0) > limit) {
      return CantOpenScreen(
        failure: const DocNookFailure.tooLarge(),
        body: l.errTooLargeBody(l.fileSize(doc.sizeBytes!)),
        retryLabel: l.actionTryAnyway,
        onRetry: () => setState(() => _sizeAccepted = true),
        onOpenWith: openWith,
      );
    }

    final Widget? viewer = switch (doc.format) {
      DocFormat.pdf => PdfViewerScreen(document: doc),
      DocFormat.docx ||
      DocFormat.dotx ||
      DocFormat.odt ||
      DocFormat.rtf => DocumentViewerScreen(document: doc),
      DocFormat.doc || DocFormat.xls || DocFormat.ppt => DocumentViewerScreen(
        document: doc,
        banner: l.docLegacyBanner,
      ),
      DocFormat.xlsx ||
      DocFormat.xlsm ||
      DocFormat.ods ||
      DocFormat.csv ||
      DocFormat.tsv => SheetViewerScreen(document: doc),
      DocFormat.pptx => SlidesViewerScreen(document: doc),
      DocFormat.markdown => MarkdownViewer(document: doc),
      DocFormat.plainText || DocFormat.code => TextViewerScreen(document: doc),
      DocFormat.epub => EpubReaderScreen(document: doc),
      DocFormat.jpeg ||
      DocFormat.png ||
      DocFormat.webp ||
      DocFormat.gif ||
      DocFormat.bmp ||
      DocFormat.heic => ImageViewerScreen(document: doc),
      DocFormat.zip => ArchiveScreen(document: doc),
      DocFormat.unknown => null,
    };
    if (viewer != null) {
      return PopScope(
        canPop: !widget.request.fromIntent || Navigator.of(context).canPop(),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: viewer,
      );
    }

    if (!doc.format.isSupported) {
      return CantOpenScreen(
        failure: const DocNookFailure.unsupported(),
        onOpenWith: openWith,
      );
    }
    // Viewers for the remaining formats arrive in Phase 4.
    return CantOpenScreen(
      failure: const DocNookFailure.unsupported(),
      title: doc.name,
      body: l.comingInPhase,
      onOpenWith: openWith,
    );
  }
}

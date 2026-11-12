import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/docmodel/document_viewer_screen.dart';
import 'package:docnook/features/viewer/text/text_viewer_screen.dart';
import 'package:flutter/material.dart';

/// S19: Markdown rendered by default, with a toggle to the raw source.
class MarkdownViewer extends StatefulWidget {
  const MarkdownViewer({required this.document, super.key});

  final OpenedDocument document;

  @override
  State<MarkdownViewer> createState() => _MarkdownViewerState();
}

class _MarkdownViewerState extends State<MarkdownViewer> {
  bool _source = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_source) {
      return TextViewerScreen(
        document: widget.document,
        extraActions: [
          (
            l.mdRendered,
            PhosphorIconsRegular.article,
            () => setState(() => _source = false),
          ),
        ],
      );
    }
    return DocumentViewerScreen(
      document: widget.document,
      extraActions: [
        (
          l.mdSource,
          PhosphorIconsRegular.code,
          () => setState(() => _source = true),
        ),
      ],
    );
  }
}

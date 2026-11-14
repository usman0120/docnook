import 'dart:async';
import 'dart:io';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/data/files/file_type_detector.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:docnook/features/viewer/presentation/viewer_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

/// S21 image viewer: pinch zoom, swipe through the folder, rotate.
class ImageViewerScreen extends ConsumerStatefulWidget {
  const ImageViewerScreen({required this.document, super.key});

  final OpenedDocument document;

  @override
  ConsumerState<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends ConsumerState<ImageViewerScreen> {
  late List<String> _images = [widget.document.path];
  late final PageController _pages = PageController();
  int _index = 0;
  final _turns = <int, int>{};
  bool _chrome = true;

  @override
  void initState() {
    super.initState();
    unawaited(_siblings());
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Other images in the same folder, when the file is a real path (the
  /// cache copy of a shared file has no meaningful siblings).
  Future<void> _siblings() async {
    final uri = widget.document.request.uri;
    if (uri.startsWith('content://')) return;
    final dir = Directory(p.dirname(widget.document.path));
    try {
      final files = <String>[];
      await for (final e in dir.list()) {
        if (e is! File) continue;
        final name = p.basename(e.path);
        if (name.startsWith('.')) continue;
        final format = FileTypeDetector.formatForExtension(
          FileTypeDetector.extensionOf(name),
        );
        if (format?.docType == DocType.image) files.add(e.path);
        if (files.length > 2000) break;
      }
      files.sort(
        (a, b) =>
            p.basename(a).toLowerCase().compareTo(p.basename(b).toLowerCase()),
      );
      final at = files.indexOf(widget.document.path);
      if (at < 0 || !mounted) return;
      setState(() {
        _images = files;
        _index = at;
      });
      _pages.jumpToPage(at);
    } on FileSystemException {
      // Folder not readable: keep the single image.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final platform = ref.read(platformProvider);
    final current = _images[_index];
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screen = MediaQuery.sizeOf(context);
    // Decode at most ~3× the screen so huge photos stay inside memory limits.
    final cacheWidth = (screen.longestSide * dpr * 1.5).round().clamp(
      512,
      4096,
    );
    // The picture on screen as a tool input (a local path).
    void tool(ToolId id) => unawaited(
      context.push(
        '/tool/${id.name}',
        extra: [ToolInput(uri: current, name: p.basename(current))],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0E),
      body: Column(
        children: [
          ViewerTopBar(
            visible: _chrome,
            night: true,
            title: p.basename(
              _index == 0 && _images.length == 1
                  ? widget.document.name
                  : current,
            ),
            actions: [
              IconAction(
                icon: PhosphorIconsRegular.arrowClockwise,
                label: l.imageRotate,
                color: Colors.white,
                onPressed: () => setState(
                  () => _turns[_index] = ((_turns[_index] ?? 0) + 1) % 4,
                ),
              ),
              ViewerOverflowMenu(
                night: true,
                items: [
                  (
                    l.imageMakePdf,
                    PhosphorIconsRegular.filePdf,
                    () => tool(ToolId.imagesToPdf),
                  ),
                  (
                    l.imageExtractText,
                    PhosphorIconsRegular.textT,
                    () => tool(ToolId.extractText),
                  ),
                  (
                    l.actionShare,
                    PhosphorIconsRegular.shareNetwork,
                    () => platform.share([current], mime: 'image/*'),
                  ),
                  (
                    l.actionOpenWith,
                    PhosphorIconsRegular.arrowSquareOut,
                    () => platform.openWith(
                      _index == 0 && _images.length == 1
                          ? widget.document.request.uri
                          : current,
                      mime: 'image/*',
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _chrome = !_chrome),
              child: PageView.builder(
                controller: _pages,
                itemCount: _images.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => InteractiveViewer(
                  maxScale: 8,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: _turns[i] ?? 0,
                      child: Image.file(
                        File(_images[i]),
                        fit: BoxFit.contain,
                        cacheWidth: cacheWidth,
                        gaplessPlayback: true,
                        semanticLabel: p.basename(_images[i]),
                        errorBuilder: (_, _, _) => Padding(
                          padding: const EdgeInsets.all(Space.x8),
                          child: Text(
                            l.errCorruptTitle,
                            style: DocNookText.body.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_images.length > 1 && _chrome)
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + Space.x3,
                top: Space.x2,
              ),
              child: Text(
                l.imageOf(_index + 1, _images.length),
                style: DocNookText.caption.copyWith(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}

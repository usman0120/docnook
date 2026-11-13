import 'dart:async';
import 'dart:math' as math;

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/choice.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/features/tools/application/editor_marks.dart';
import 'package:docnook/features/tools/application/pdf_tools_service.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:docnook/features/tools/presentation/edit_pages.dart';
import 'package:docnook/features/tools/presentation/tool_flow_screen.dart';
import 'package:docnook/features/tools/presentation/tool_scaffold.dart';
import 'package:docnook/features/tools/presentation/tool_sheets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

enum _Mode { area, text }

/// S34 Redact: mark areas (drag a box, or drag across text); the saved copy
/// has those pages rebuilt as pictures with the areas burnt in black.
class RedactScreen extends ConsumerStatefulWidget {
  const RedactScreen({required this.input, super.key});

  final PreparedInput input;

  @override
  ConsumerState<RedactScreen> createState() => _RedactScreenState();
}

class _RedactScreenState extends ConsumerState<RedactScreen> {
  final _pages = PageController();
  var _page = 0;
  var _mode = _Mode.area;
  String? _path;
  final _boxes = <RedactBox>[];
  final _chars = <int, List<Rect>>{};
  Offset? _start;
  List<Rect> _preview = const [];

  PdfInfo get _info => widget.input.info!;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final path = await ref
        .read(pdfToolsServiceProvider)
        .localPath(widget.input.input);
    if (mounted) setState(() => _path = path);
  }

  Future<void> _loadChars(PdfDocument doc, int index) async {
    if (_chars.containsKey(index)) return;
    final page = _info.pages[index];
    final out = <Rect>[];
    try {
      final text = await doc.pages[index].loadStructuredText();
      for (final r in text.charRects) {
        final (l, t) = page.toVisible(r.left, r.top);
        final (rr, b) = page.toVisible(r.right, r.bottom);
        out.add(
          Rect.fromLTRB(
            math.min(l, rr),
            math.min(t, b),
            math.max(l, rr),
            math.max(t, b),
          ),
        );
      }
    } on Object {
      // No text layer: only area boxes work on this page.
    }
    _chars[index] = out;
  }

  void _update(int page, Offset f) {
    final start = _start;
    if (start == null) return;
    final chars = _chars[page] ?? const [];
    setState(() {
      _preview = _mode == _Mode.text && chars.isNotEmpty
          ? [for (final r in selectTextLines(chars, start, f)) r.inflate(0.002)]
          : [Rect.fromPoints(start, f)];
    });
  }

  void _end(int page) {
    final boxes = [
      for (final r in _preview)
        if (r.width > 0.005 && r.height > 0.003)
          RedactBox(
            page,
            r.left.clamp(0, 1),
            r.top.clamp(0, 1),
            r.right.clamp(0, 1),
            r.bottom.clamp(0, 1),
          ),
    ];
    setState(() {
      _boxes.addAll(boxes);
      _start = null;
      _preview = const [];
    });
  }

  Future<void> _showList() async {
    final l = AppLocalizations.of(context);
    await showDocNookSheet<void>(
      context,
      title: l.redactMarked,
      expand: true,
      builder: (context, scroll) => StatefulBuilder(
        builder: (context, setSheet) {
          final pages = {for (final b in _boxes) b.page}.toList()..sort();
          if (pages.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(Space.screen),
              child: Text(l.redactNone, style: DocNookText.body),
            );
          }
          return ListView(
            controller: scroll,
            children: [
              for (final p in pages)
                ListTile(
                  title: Text(l.pageLabel(p + 1), style: DocNookText.body),
                  subtitle: Text(
                    l.redactAreas(_boxes.where((b) => b.page == p).length),
                    style: DocNookText.caption,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pages.jumpToPage(p);
                  },
                  trailing: IconAction(
                    icon: PhosphorIconsRegular.trash,
                    label: l.redactClearPage,
                    onPressed: () {
                      setState(() => _boxes.removeWhere((b) => b.page == p));
                      setSheet(() {});
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.redactConfirmTitle),
        content: Text(l.redactConfirmBody),
        actions: [
          QuietButton(
            label: l.actionCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          QuietButton(
            label: l.redactConfirmAction,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final service = ref.read(pdfToolsServiceProvider);
    final boxes = [..._boxes];
    await runToolJob(
      context,
      ref,
      ToolId.redact,
      (control) => service.redact(
        input: widget.input.input,
        password: widget.input.password,
        boxes: boxes,
        ocr: true,
        name: PdfToolsService.defaultName(
          ToolId.redact,
          widget.input.input.name,
          DateTime.now(),
        ),
        control: control,
      ),
    );
  }

  Future<bool> _confirmLeave() async {
    if (_boxes.isEmpty) return true;
    final l = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.editDiscardTitle),
        content: Text(l.editDiscardBody),
        actions: [
          QuietButton(
            label: l.actionCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          QuietButton(
            label: l.actionDiscard,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final path = _path;
    return ToolScaffold(
      title: toolTitle(l, ToolId.redact),
      subtitle: widget.input.input.name,
      actionLabel: l.redactSave(_boxes.length),
      onAction: _boxes.isEmpty ? null : () => unawaited(_save()),
      onBack: _confirmLeave,
      actions: [
        IconAction(
          icon: PhosphorIconsRegular.arrowCounterClockwise,
          label: l.actionUndo,
          onPressed: _boxes.isEmpty ? null : () => setState(_boxes.removeLast),
        ),
        IconAction(
          icon: PhosphorIconsRegular.listBullets,
          label: l.redactMarked,
          onPressed: () => unawaited(_showList()),
        ),
      ],
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditPageBar(controller: _pages, page: _page, count: _info.pageCount),
          Padding(
            padding: const EdgeInsets.only(top: Space.x2),
            child: SegmentedChoice<_Mode>(
              values: _Mode.values,
              selected: _mode,
              label: (m) => m == _Mode.area ? l.redactArea : l.redactText,
              onSelected: (m) => setState(() => _mode = m),
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
              _mode == _Mode.area ? l.redactAreaHint : l.redactTextHint,
              style: DocNookText.caption.copyWith(color: c.inkMuted),
            ),
          ),
        ],
      ),
      body: path == null
          ? const LoadingState()
          : EditPages(
              path: path,
              password: widget.input.password,
              info: _info,
              controller: _pages,
              swipe: false,
              onPageChanged: (p) => setState(() => _page = p),
              overlay: (context, index, size, doc) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onPanStart: (d) {
                  unawaited(_loadChars(doc, index));
                  _start = size.toFraction(d.localPosition);
                },
                onPanUpdate: (d) =>
                    _update(index, size.toFraction(d.localPosition)),
                onPanEnd: (_) => _end(index),
                child: CustomPaint(
                  painter: _BoxesPainter(
                    boxes: [
                      for (final b in _boxes)
                        if (b.page == index)
                          Rect.fromLTRB(b.left, b.top, b.right, b.bottom),
                    ],
                    preview: _preview,
                    previewColor: c.danger,
                  ),
                ),
              ),
            ),
    );
  }
}

class _BoxesPainter extends CustomPainter {
  _BoxesPainter({
    required this.boxes,
    required this.preview,
    required this.previewColor,
  });

  final List<Rect> boxes;
  final List<Rect> preview;
  final Color previewColor;

  Rect _scale(Rect r, Size s) => Rect.fromLTRB(
    r.left * s.width,
    r.top * s.height,
    r.right * s.width,
    r.bottom * s.height,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xE6000000);
    for (final r in boxes) {
      canvas.drawRect(_scale(r, size), fill);
    }
    final outline = Paint()
      ..color = previewColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final tint = Paint()..color = previewColor.withValues(alpha: 0.18);
    for (final r in preview) {
      final rect = _scale(r, size);
      canvas
        ..drawRect(rect, tint)
        ..drawRect(rect, outline);
    }
  }

  @override
  bool shouldRepaint(_BoxesPainter old) => true;
}

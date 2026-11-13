import 'dart:async';
import 'dart:math' as math;

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/features/library/presentation/file_sheets.dart';
import 'package:docnook/features/tools/application/editor_marks.dart';
import 'package:docnook/features/tools/application/pdf_tools_service.dart';
import 'package:docnook/features/tools/application/signature_store.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:docnook/features/tools/presentation/edit_pages.dart';
import 'package:docnook/features/tools/presentation/signature_pad.dart';
import 'package:docnook/features/tools/presentation/tool_flow_screen.dart';
import 'package:docnook/features/tools/presentation/tool_scaffold.dart';
import 'package:docnook/features/tools/presentation/tool_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

enum _Tool { none, highlight, underline, strike, pen, note, eraser }

/// S14 Annotate and sign. In [signMode] only signatures are offered.
class AnnotateScreen extends ConsumerStatefulWidget {
  const AnnotateScreen({required this.input, this.signMode = false, super.key});

  final PreparedInput input;
  final bool signMode;

  @override
  ConsumerState<AnnotateScreen> createState() => _AnnotateScreenState();
}

class _AnnotateScreenState extends ConsumerState<AnnotateScreen> {
  final _pages = PageController();
  var _page = 0;
  var _tool = _Tool.none;
  var _penColor = penColors.first;
  var _markColor = markupColors.first;
  var _penWidth = penWidths[1];
  var _marks = <EditorMark>[];
  final _undo = <List<EditorMark>>[];
  final _redo = <List<EditorMark>>[];
  String? _path;

  /// Character boxes per page (visible fractions), loaded on first use.
  final _chars = <int, List<Rect>>{};

  // The gesture in progress.
  Offset? _dragStart;
  List<Offset>? _stroke;
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

  void _commit(List<EditorMark> next) => setState(() {
    _undo.add(_marks);
    _redo.clear();
    _marks = next;
  });

  void _doUndo() => setState(() {
    if (_undo.isEmpty) return;
    _redo.add(_marks);
    _marks = _undo.removeLast();
  });

  void _doRedo() => setState(() {
    if (_redo.isEmpty) return;
    _undo.add(_marks);
    _marks = _redo.removeLast();
  });

  Future<List<Rect>> _charsOf(PdfDocument doc, int index) async {
    final cached = _chars[index];
    if (cached != null) return cached;
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
      // No text layer: markup falls back to the dragged area.
    }
    _chars[index] = out;
    return out;
  }

  MarkupKind? get _markupKind => switch (_tool) {
    _Tool.highlight => MarkupKind.highlight,
    _Tool.underline => MarkupKind.underline,
    _Tool.strike => MarkupKind.strikeOut,
    _ => null,
  };

  // Gestures (positions are fractions of the page) -------------------------

  void _panStart(PdfDocument doc, int page, Offset f) {
    _dragStart = f;
    if (_tool == _Tool.pen) {
      setState(() => _stroke = [f]);
    } else if (_markupKind != null) {
      unawaited(_charsOf(doc, page));
    }
  }

  void _panUpdate(int page, Offset f) {
    final start = _dragStart;
    if (start == null) return;
    if (_tool == _Tool.pen) {
      setState(() => _stroke?.add(f));
      return;
    }
    if (_markupKind == null) return;
    final chars = _chars[page] ?? const [];
    final lines = selectTextLines(chars, start, f);
    setState(
      () => _preview = lines.isNotEmpty
          ? lines
          : [Rect.fromPoints(start, f).inflate(0.004)],
    );
  }

  void _panEnd(int page) {
    final kind = _markupKind;
    if (_tool == _Tool.pen && (_stroke?.length ?? 0) > 0) {
      _commit([
        ..._marks,
        PenMark(page, _penColor, _penWidth, [_stroke!]),
      ]);
    } else if (kind != null && _preview.isNotEmpty) {
      _commit([..._marks, MarkupMark(page, kind, _markColor, _preview)]);
    }
    setState(() {
      _dragStart = null;
      _stroke = null;
      _preview = const [];
    });
  }

  Future<void> _tap(int page, Offset f) async {
    if (_tool == _Tool.eraser) {
      final hit = _marks.lastIndexWhere(
        (m) => m.page == page && m.bounds.inflate(0.02).contains(f),
      );
      if (hit >= 0) _commit([..._marks]..removeAt(hit));
      return;
    }
    if (_tool != _Tool.note) return;
    final l = AppLocalizations.of(context);
    final text = await askText(
      context,
      title: l.annotNoteTitle,
      label: l.annotNoteLabel,
      action: l.actionAdd,
    );
    if (text == null || !mounted) return;
    _commit([..._marks, NoteEditorMark(page, f, text)]);
  }

  // Signatures ---------------------------------------------------------------

  Future<void> _addSignature() async {
    final l = AppLocalizations.of(context);
    final store = ref.read(signatureStoreProvider);
    final saved = await store.list();
    if (!mounted) return;
    Signature? picked;
    if (saved.isNotEmpty) {
      final choice = await showDocNookSheet<Object>(
        context,
        title: l.signChoose,
        builder: (context, _) => _SignatureChoices(
          signatures: saved,
          onDelete: (s) async {
            await store.delete(s.id);
            ref.invalidate(signaturesProvider);
          },
        ),
      );
      if (!mounted || choice == null) return;
      if (choice is Signature) picked = choice;
    }
    if (picked == null) {
      final drawn = await Navigator.of(context).push<DrawnSignature>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const SignaturePad(),
        ),
      );
      if (drawn == null || !mounted) return;
      picked = drawn.signature;
      if (drawn.keep) await store.save(drawn.signature);
    }
    final page = _info.pages[_page];
    const width = 0.36;
    final height = math.min(
      0.3,
      width * page.visibleWidth / picked.aspect / page.visibleHeight,
    );
    final w = height * picked.aspect * page.visibleHeight / page.visibleWidth;
    _commit([
      ..._marks,
      SignatureMark(
        _page,
        picked,
        Rect.fromLTWH(0.92 - w, 0.78 - height, w, height),
      ),
    ]);
    setState(() => _tool = _Tool.none);
  }

  void _moveSignature(SignatureMark mark, Rect next, {required bool done}) {
    final i = _marks.indexOf(mark);
    if (i < 0) return;
    final clamped = Rect.fromLTWH(
      next.left.clamp(0, 1 - next.width),
      next.top.clamp(0, 1 - next.height),
      next.width,
      next.height,
    );
    final updated = [..._marks]..[i] = mark.withBox(clamped);
    if (done) {
      _commit(updated);
    } else {
      setState(() => _marks = updated);
    }
  }

  // Saving -------------------------------------------------------------------

  Future<void> _save() async {
    final service = ref.read(pdfToolsServiceProvider);
    final tool = widget.signMode ? ToolId.sign : ToolId.annotate;
    final marks = toPdfMarks(_marks, _info);
    final done = await runToolJob(
      context,
      ref,
      tool,
      (control) => service.annotate(
        tool: tool,
        input: widget.input.input,
        password: widget.input.password,
        marks: marks,
        name: PdfToolsService.defaultName(
          tool,
          widget.input.input.name,
          DateTime.now(),
        ),
        control: control,
      ),
    );
    if (done && mounted) Navigator.of(context).maybePop();
  }

  Future<bool> _confirmLeave() async {
    if (_marks.isEmpty) return true;
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

  // Building -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final path = _path;
    final drawing = _tool != _Tool.none;
    return ToolScaffold(
      title: toolTitle(l, widget.signMode ? ToolId.sign : ToolId.annotate),
      subtitle: widget.input.input.name,
      actionLabel: l.annotSave,
      onAction: _marks.isEmpty ? null : () => unawaited(_save()),
      onBack: _confirmLeave,
      actions: [
        IconAction(
          icon: PhosphorIconsRegular.arrowCounterClockwise,
          label: l.actionUndo,
          onPressed: _undo.isEmpty ? null : _doUndo,
        ),
        IconAction(
          icon: PhosphorIconsRegular.arrowClockwise,
          label: l.actionRedo,
          onPressed: _redo.isEmpty ? null : _doRedo,
        ),
      ],
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EditPageBar(controller: _pages, page: _page, count: _info.pageCount),
          if (widget.signMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.x2,
                Space.screen,
                0,
              ),
              child: SecondaryButton(
                icon: PhosphorIconsRegular.signature,
                label: l.signAdd,
                onPressed: () => unawaited(_addSignature()),
              ),
            )
          else
            _palette(context),
        ],
      ),
      body: path == null
          ? const LoadingState()
          : EditPages(
              path: path,
              password: widget.input.password,
              info: _info,
              controller: _pages,
              swipe: !drawing,
              onPageChanged: (p) => setState(() => _page = p),
              overlay: _overlay,
            ),
    );
  }

  Widget _overlay(BuildContext context, int index, Size size, PdfDocument doc) {
    final l = AppLocalizations.of(context);
    final page = _info.pages[index];
    final pxPerPt = size.width / page.visibleWidth;
    final mine = [
      for (final m in _marks)
        if (m.page == index) m,
    ];
    final drawing = _tool != _Tool.none;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: !drawing,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) =>
                _panStart(doc, index, size.toFraction(d.localPosition)),
            onPanUpdate: (d) =>
                _panUpdate(index, size.toFraction(d.localPosition)),
            onPanEnd: (_) => _panEnd(index),
            onTapUp: (d) =>
                unawaited(_tap(index, size.toFraction(d.localPosition))),
            child: CustomPaint(
              painter: _MarksPainter(
                marks: mine,
                pxPerPt: pxPerPt,
                stroke: _stroke,
                strokeColor: _penColor,
                strokeWidth: _penWidth,
                preview: _preview,
                previewColor: _markColor,
                previewKind: _markupKind,
              ),
            ),
          ),
        ),
        for (final m in mine)
          if (m is NoteEditorMark)
            Positioned(
              left: m.at.dx * size.width,
              top: m.at.dy * size.height - Sizes.iconSmall,
              child: IgnorePointer(
                child: Icon(
                  PhosphorIconsFill.note,
                  size: Sizes.iconSmall,
                  color: const Color(0xFFF2B807),
                  semanticLabel: l.annotNoteLabel,
                ),
              ),
            )
          else if (m is SignatureMark)
            _PlacedSignature(
              mark: m,
              size: size,
              enabled: !drawing,
              onMove: (r, {required done}) => _moveSignature(m, r, done: done),
              onRemove: () => _commit([..._marks]..remove(m)),
            ),
      ],
    );
  }

  Widget _palette(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    Widget tool(_Tool t, IconData icon, String label) => Padding(
      padding: const EdgeInsets.only(right: Space.x2),
      child: ChoiceChip(
        avatar: Icon(icon, size: Sizes.iconSmall),
        label: Text(label),
        selected: _tool == t,
        showCheckmark: false,
        onSelected: (on) => setState(() => _tool = on ? t : _Tool.none),
      ),
    );
    Widget swatch(int rgb, bool selected, VoidCallback onTap, String label) =>
        Semantics(
          selected: selected,
          button: true,
          label: label,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: Sizes.touch,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(0xFF000000 | rgb),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? c.ink : c.hairline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    final showPen = _tool == _Tool.pen;
    final showMarkup = _markupKind != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPen || showMarkup)
          SizedBox(
            height: Sizes.touch,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.x2),
              children: [
                if (showPen)
                  for (final w in penWidths)
                    Semantics(
                      selected: _penWidth == w,
                      button: true,
                      label: l.annotWidth(w.toString()),
                      child: InkWell(
                        onTap: () => setState(() => _penWidth = w),
                        child: SizedBox.square(
                          dimension: Sizes.touch,
                          child: Center(
                            child: Container(
                              width: 22,
                              height: w * 1.6,
                              decoration: BoxDecoration(
                                color: _penWidth == w ? c.ink : c.inkMuted,
                                borderRadius: Radii.chipAll,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                for (final rgb in showPen ? penColors : markupColors)
                  swatch(
                    rgb,
                    showPen ? _penColor == rgb : _markColor == rgb,
                    () => setState(() {
                      if (showPen) {
                        _penColor = rgb;
                      } else {
                        _markColor = rgb;
                      }
                    }),
                    l.annotColor,
                  ),
              ],
            ),
          ),
        SizedBox(
          height: Sizes.touch + Space.x2,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.x1,
              Space.screen,
              0,
            ),
            children: [
              tool(
                _Tool.highlight,
                PhosphorIconsRegular.highlighterCircle,
                l.annotHighlight,
              ),
              tool(
                _Tool.underline,
                PhosphorIconsRegular.textUnderline,
                l.annotUnderline,
              ),
              tool(
                _Tool.strike,
                PhosphorIconsRegular.textStrikethrough,
                l.annotStrike,
              ),
              tool(_Tool.pen, PhosphorIconsRegular.pencilSimple, l.annotPen),
              tool(_Tool.note, PhosphorIconsRegular.note, l.annotNote),
              Padding(
                padding: const EdgeInsets.only(right: Space.x2),
                child: ActionChip(
                  avatar: const Icon(
                    PhosphorIconsRegular.signature,
                    size: Sizes.iconSmall,
                  ),
                  label: Text(l.annotSignature),
                  onPressed: () => unawaited(_addSignature()),
                ),
              ),
              tool(_Tool.eraser, PhosphorIconsRegular.eraser, l.annotEraser),
            ],
          ),
        ),
      ],
    );
  }
}

class _MarksPainter extends CustomPainter {
  _MarksPainter({
    required this.marks,
    required this.pxPerPt,
    required this.stroke,
    required this.strokeColor,
    required this.strokeWidth,
    required this.preview,
    required this.previewColor,
    required this.previewKind,
  });

  final List<EditorMark> marks;
  final double pxPerPt;
  final List<Offset>? stroke;
  final int strokeColor;
  final double strokeWidth;
  final List<Rect> preview;
  final int previewColor;
  final MarkupKind? previewKind;

  static Color _c(int rgb, [double alpha = 1]) =>
      Color(0xFF000000 | rgb).withValues(alpha: alpha);

  void _line(
    Canvas canvas,
    Size size,
    List<Offset> pts,
    Color color,
    double w,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1, w * pxPerPt)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()..addPolygon([for (final p in pts) size.fromFraction(p)], false),
      paint,
    );
  }

  void _markup(
    Canvas canvas,
    Size size,
    MarkupKind kind,
    List<Rect> lines,
    int rgb,
  ) {
    for (final r in lines) {
      final rect = Rect.fromLTRB(
        r.left * size.width,
        r.top * size.height,
        r.right * size.width,
        r.bottom * size.height,
      );
      final paint = Paint()
        ..color = _c(rgb, kind == MarkupKind.highlight ? 0.4 : 1);
      switch (kind) {
        case MarkupKind.highlight:
          canvas.drawRect(rect, paint..blendMode = BlendMode.multiply);
        case MarkupKind.underline:
          canvas.drawRect(
            Rect.fromLTRB(
              rect.left,
              rect.bottom - 1.5,
              rect.right,
              rect.bottom,
            ),
            paint,
          );
        case MarkupKind.strikeOut:
          canvas.drawRect(
            Rect.fromLTRB(
              rect.left,
              rect.center.dy - 0.75,
              rect.right,
              rect.center.dy + 0.75,
            ),
            paint,
          );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in marks) {
      switch (m) {
        case MarkupMark(:final kind, :final lines, :final colorRgb):
          _markup(canvas, size, kind, lines, colorRgb);
        case PenMark(:final strokes, :final colorRgb, :final widthPt):
          for (final s in strokes) {
            _line(canvas, size, s, _c(colorRgb), widthPt);
          }
        case NoteEditorMark() || SignatureMark():
          break;
      }
    }
    final s = stroke;
    if (s != null) _line(canvas, size, s, _c(strokeColor), strokeWidth);
    final kind = previewKind;
    if (kind != null && preview.isNotEmpty) {
      _markup(canvas, size, kind, preview, previewColor);
    }
  }

  @override
  bool shouldRepaint(_MarksPainter old) => true;
}

/// A signature that can still be moved (drag) and resized (corner handle).
class _PlacedSignature extends StatelessWidget {
  const _PlacedSignature({
    required this.mark,
    required this.size,
    required this.enabled,
    required this.onMove,
    required this.onRemove,
  });

  final SignatureMark mark;
  final Size size;
  final bool enabled;
  final void Function(Rect box, {required bool done}) onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final box = mark.box;
    final rect = Rect.fromLTRB(
      box.left * size.width,
      box.top * size.height,
      box.right * size.width,
      box.bottom * size.height,
    );
    const handle = Sizes.touch;
    return Positioned(
      left: rect.left - handle / 2,
      top: rect.top - handle / 2,
      width: rect.width + handle,
      height: rect.height + handle,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Stack(
          children: [
            Positioned.fill(
              left: handle / 2,
              top: handle / 2,
              right: handle / 2,
              bottom: handle / 2,
              child: Semantics(
                label: l.signPlaced,
                child: GestureDetector(
                  onPanUpdate: (d) => onMove(
                    box.shift(
                      Offset(d.delta.dx / size.width, d.delta.dy / size.height),
                    ),
                    done: false,
                  ),
                  onPanEnd: (_) => onMove(mark.box, done: true),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: c.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    child: CustomPaint(
                      painter: _SignaturePainter(mark.signature),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              width: handle,
              height: handle,
              child: Semantics(
                label: l.signResize,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (d) {
                    final w = (box.width + d.delta.dx / size.width).clamp(
                      0.08,
                      1.0,
                    );
                    final h = w * box.height / box.width;
                    onMove(Rect.fromLTWH(box.left, box.top, w, h), done: false);
                  },
                  onPanEnd: (_) => onMove(mark.box, done: true),
                  child: Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.paper, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              width: handle,
              height: handle,
              child: IconAction(
                icon: PhosphorIconsRegular.x,
                label: l.actionRemove,
                onPressed: onRemove,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.signature);
  final Signature signature;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B1B1F)
      ..strokeWidth = math.max(1.2, size.height * 0.035)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in signature.strokes) {
      final pts = [
        for (var i = 0; i + 1 < s.length; i += 2)
          Offset(s[i] * size.width, s[i + 1] * size.height),
      ];
      if (pts.length == 1) {
        canvas.drawCircle(pts.first, paint.strokeWidth / 2, paint);
      } else {
        canvas.drawPath(Path()..addPolygon(pts, false), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => old.signature != signature;
}

/// Saved signatures to pick from, plus "New signature".
class _SignatureChoices extends StatefulWidget {
  const _SignatureChoices({required this.signatures, required this.onDelete});

  final List<Signature> signatures;
  final Future<void> Function(Signature) onDelete;

  @override
  State<_SignatureChoices> createState() => _SignatureChoicesState();
}

class _SignatureChoicesState extends State<_SignatureChoices> {
  late final _list = [...widget.signatures];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
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
          for (final s in _list)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.x2),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: Radii.cardAll,
                      onTap: () => Navigator.of(context).pop(s),
                      child: Container(
                        height: 72,
                        padding: const EdgeInsets.all(Space.x3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: Radii.cardAll,
                          border: Border.all(color: c.hairline),
                        ),
                        child: Semantics(
                          label: l.signSaved,
                          child: AspectRatio(
                            aspectRatio: s.aspect,
                            child: CustomPaint(painter: _SignaturePainter(s)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconAction(
                    icon: PhosphorIconsRegular.trash,
                    label: l.actionDelete,
                    onPressed: () async {
                      await widget.onDelete(s);
                      setState(() => _list.remove(s));
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: Space.x2),
          SecondaryButton(
            icon: PhosphorIconsRegular.plus,
            label: l.signNew,
            onPressed: () => Navigator.of(context).pop('new'),
          ),
        ],
      ),
    );
  }
}

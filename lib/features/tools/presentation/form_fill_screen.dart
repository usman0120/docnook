import 'dart:async';
import 'dart:math' as math;

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/engines/pdf/pdfium_editor.dart';
import 'package:docnook/features/tools/application/pdf_tools_service.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:docnook/features/tools/presentation/edit_pages.dart';
import 'package:docnook/features/tools/presentation/tool_flow_screen.dart';
import 'package:docnook/features/tools/presentation/tool_scaffold.dart';
import 'package:docnook/features/tools/presentation/tool_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

/// The value a widget shows in the editor.
final class _Value {
  const _Value({this.text, this.checked, this.choice});
  final String? text;
  final bool? checked;
  final int? choice;
}

/// S33 Fill forms.
class FormFillScreen extends ConsumerStatefulWidget {
  const FormFillScreen({required this.input, super.key});

  final PreparedInput input;

  @override
  ConsumerState<FormFillScreen> createState() => _FormFillScreenState();
}

class _FormFillScreenState extends ConsumerState<FormFillScreen> {
  final _pages = PageController();
  var _page = 0;
  String? _path;
  List<FormFieldInfo>? _fields;
  DocNookFailure? _failure;

  /// Edits by field key.
  final _values = <String, _Value>{};

  PdfInfo get _info => widget.input.info!;

  List<FormFieldInfo> get _editable => [
    for (final f in _fields ?? const <FormFieldInfo>[])
      if (f.editable) f,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final path = await ref
          .read(pdfToolsServiceProvider)
          .localPath(widget.input.input);
      final fields = await PdfiumEditor.readForm(
        PdfSource(path, password: widget.input.password),
      );
      if (mounted) {
        setState(() {
          _path = path;
          _fields = fields;
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => _failure = DocNookFailure.from(e));
    }
  }

  String _textOf(FormFieldInfo f) => _values[f.key]?.text ?? f.value;
  bool _checkedOf(FormFieldInfo f) => _values[f.key]?.checked ?? f.checked;
  int? _choiceOf(FormFieldInfo f) =>
      _values[f.key]?.choice ?? (f.selected.isEmpty ? null : f.selected.first);

  void _toggle(FormFieldInfo f) {
    final on = !_checkedOf(f);
    setState(() {
      if (f.kind == FormFieldKind.radio) {
        if (!on) return; // A radio button turns off by picking another.
        for (final other in _fields!) {
          if (other.kind == FormFieldKind.radio &&
              other.name == f.name &&
              other.key != f.key) {
            _values[other.key] = const _Value(checked: false);
          }
        }
      }
      _values[f.key] = _Value(checked: on);
    });
  }

  Future<void> _edit(FormFieldInfo f) async {
    switch (f.kind) {
      case FormFieldKind.checkbox || FormFieldKind.radio:
        _toggle(f);
      case FormFieldKind.combo || FormFieldKind.list:
        final l = AppLocalizations.of(context);
        final picked = await showDocNookSheet<int>(
          context,
          title: f.name.isEmpty ? l.formChoose : f.name,
          expand: f.options.length > 6,
          builder: (context, scroll) => ListView(
            controller: scroll,
            shrinkWrap: scroll == null,
            children: [
              for (var i = 0; i < f.options.length; i++)
                ListTile(
                  title: Text(f.options[i], style: DocNookText.body),
                  trailing: _choiceOf(f) == i
                      ? const Icon(PhosphorIconsRegular.check, size: Sizes.icon)
                      : null,
                  onTap: () => Navigator.of(context).pop(i),
                ),
            ],
          ),
        );
        if (picked != null) {
          setState(() => _values[f.key] = _Value(choice: picked));
        }
      case FormFieldKind.text:
        await _editText(f);
      case FormFieldKind.button || FormFieldKind.signature:
        break;
    }
  }

  /// Text entry with Previous / Next above the keyboard.
  Future<void> _editText(FormFieldInfo start) async {
    var field = start;
    while (mounted) {
      final fields = _editable;
      final index = fields.indexWhere((f) => f.key == field.key);
      final controller = TextEditingController(text: _textOf(field));
      final move = await showDocNookSheet<int>(
        context,
        title: field.name,
        builder: (context, _) => _TextEditor(
          controller: controller,
          multiline: field.multiline,
          hasPrevious: index > 0,
          hasNext: index < fields.length - 1,
        ),
      );
      final text = controller.text;
      controller.dispose();
      if (!mounted) return;
      if (text != _textOf(field)) {
        setState(() => _values[field.key] = _Value(text: text));
      }
      if (move == null || move == 0) return;
      final next = index + move;
      if (next < 0 || next >= fields.length) return;
      field = fields[next];
      if (field.page != _page) _pages.jumpToPage(field.page);
      if (field.kind != FormFieldKind.text) {
        await _edit(field);
        return;
      }
    }
  }

  List<FormFieldValue> get _changes => [
    for (final f in _fields ?? const <FormFieldInfo>[])
      if (_values[f.key] case final v?)
        if (v.text != null)
          FormFieldValue.text(f.page, f.annotIndex, v.text!)
        else if (v.checked != null &&
            (v.checked! || f.kind == FormFieldKind.checkbox))
          FormFieldValue.checked(f.page, f.annotIndex, v.checked!)
        else if (v.choice != null)
          FormFieldValue.choice(f.page, f.annotIndex, v.choice!),
  ];

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final flatten = await showDocNookSheet<bool>(
      context,
      title: l.formSaveTitle,
      builder: (context, _) => Padding(
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
            PrimaryButton(
              label: l.formSaveEditable,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: Space.x2),
            SecondaryButton(
              label: l.formSaveFlat,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: Space.x2),
            Text(
              l.formSaveHelp,
              style: DocNookText.caption.copyWith(
                color: context.colors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
    if (flatten == null || !mounted) return;
    final service = ref.read(pdfToolsServiceProvider);
    final values = _changes;
    await runToolJob(
      context,
      ref,
      ToolId.fillForms,
      (control) => service.fillForm(
        input: widget.input.input,
        password: widget.input.password,
        values: values,
        flatten: flatten,
        name: PdfToolsService.defaultName(
          ToolId.fillForms,
          widget.input.input.name,
          DateTime.now(),
        ),
        control: control,
      ),
    );
  }

  Future<bool> _confirmLeave() async {
    if (_values.isEmpty) return true;
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
    final fields = _fields;
    final path = _path;
    final failure = _failure;
    final Widget body;
    if (failure != null) {
      final (title, text) = (l.formLoadFailed, l.errCorruptBody);
      body = ErrorState(title: title, body: text);
    } else if (fields == null || path == null) {
      body = const LoadingState();
    } else if (_editable.isEmpty) {
      body = EmptyState(
        art: EmptyArt.paperStack,
        title: l.formNoFields,
        body: l.formNoFieldsBody,
        primaryLabel: toolTitle(l, ToolId.annotate),
        onPrimary: () => context.pushReplacement(
          '/tool/${ToolId.annotate.name}',
          extra: [widget.input.input],
        ),
      );
    } else {
      body = EditPages(
        path: path,
        password: widget.input.password,
        info: _info,
        controller: _pages,
        onPageChanged: (p) => setState(() => _page = p),
        overlay: _overlay,
      );
    }
    final ready = fields != null && _editable.isNotEmpty;
    return ToolScaffold(
      title: toolTitle(l, ToolId.fillForms),
      subtitle: widget.input.input.name,
      actionLabel: l.formSave,
      onAction: ready && _values.isNotEmpty ? () => unawaited(_save()) : null,
      onBack: _confirmLeave,
      bottom: ready
          ? EditPageBar(
              controller: _pages,
              page: _page,
              count: _info.pageCount,
              trailing: Padding(
                padding: const EdgeInsets.only(right: Space.screen),
                child: Text(
                  l.formFieldsCount(_editable.length),
                  style: DocNookText.caption.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
              ),
            )
          : null,
      body: body,
    );
  }

  Widget _overlay(BuildContext context, int index, Size size, PdfDocument _) {
    final c = context.colors;
    final page = _info.pages[index];
    final children = <Widget>[];
    for (final f in _fields!) {
      if (f.page != index || !f.editable) continue;
      final (l1, t1) = page.toVisible(f.left - page.x0, f.top - page.y0);
      final (r1, b1) = page.toVisible(f.right - page.x0, f.bottom - page.y0);
      final rect = Rect.fromLTRB(
        math.min(l1, r1) * size.width,
        math.min(t1, b1) * size.height,
        math.max(l1, r1) * size.width,
        math.max(t1, b1) * size.height,
      );
      final changed = _values.containsKey(f.key);
      final isCheck =
          f.kind == FormFieldKind.checkbox || f.kind == FormFieldKind.radio;
      final shown = switch (f.kind) {
        FormFieldKind.text => _textOf(f),
        FormFieldKind.combo || FormFieldKind.list => switch (_choiceOf(f)) {
          final i? when i < f.options.length => f.options[i],
          _ => '',
        },
        _ => '',
      };
      children.add(
        Positioned.fromRect(
          rect: rect.inflate(2),
          child: Semantics(
            button: true,
            label: f.name,
            value: isCheck ? (_checkedOf(f) ? '✓' : '') : shown,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(_edit(f)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                alignment: f.multiline
                    ? Alignment.topLeft
                    : Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: changed
                      ? const Color(0xF2FFFFFF)
                      : c.primary.withValues(alpha: 0.08),
                  border: Border.all(color: c.primary.withValues(alpha: 0.35)),
                ),
                child: !changed
                    ? null
                    : isCheck
                    ? Center(
                        child: _checkedOf(f)
                            ? Icon(
                                PhosphorIconsBold.check,
                                size: math.min(rect.height, rect.width) * 0.8,
                                color: const Color(0xFF1B1B1F),
                              )
                            : null,
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          shown,
                          style: DocNookText.body.copyWith(
                            color: const Color(0xFF1B1B1F),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: children);
  }
}

class _TextEditor extends StatelessWidget {
  const _TextEditor({
    required this.controller,
    required this.multiline,
    required this.hasPrevious,
    required this.hasNext,
  });

  final TextEditingController controller;
  final bool multiline;
  final bool hasPrevious;
  final bool hasNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.screen,
        0,
        Space.screen,
        Space.x3 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            minLines: multiline ? 3 : 1,
            maxLines: multiline ? 6 : 1,
            textInputAction: hasNext
                ? TextInputAction.next
                : TextInputAction.done,
            style: DocNookText.body,
            onSubmitted: (_) => Navigator.of(context).pop(hasNext ? 1 : 0),
          ),
          const SizedBox(height: Space.x2),
          Row(
            children: [
              QuietButton(
                label: l.formPrevious,
                onPressed: hasPrevious
                    ? () => Navigator.of(context).pop(-1)
                    : null,
              ),
              QuietButton(
                label: l.formNext,
                onPressed: hasNext ? () => Navigator.of(context).pop(1) : null,
              ),
              const Spacer(),
              QuietButton(
                label: l.actionDone,
                onPressed: () => Navigator.of(context).pop(0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

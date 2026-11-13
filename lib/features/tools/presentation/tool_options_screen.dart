import 'dart:async';

import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/choice.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/features/tools/application/pdf_tools_service.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:docnook/features/tools/presentation/tool_flow_screen.dart';
import 'package:docnook/features/tools/presentation/tool_scaffold.dart';
import 'package:docnook/features/tools/presentation/tool_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _SplitMode { ranges, every, extract }

enum _NumberFormat { plain, pageOfTotal, slash }

enum _WatermarkKind { text, image }

enum _StampSize { small, medium, large }

/// S09: options for the form-based tools, built from one template: inputs
/// summary, simple controls, output name, and a button naming the action.
class ToolOptionsScreen extends ConsumerStatefulWidget {
  const ToolOptionsScreen({
    required this.tool,
    required this.inputs,
    super.key,
  });

  final ToolId tool;
  final List<PreparedInput> inputs;

  @override
  ConsumerState<ToolOptionsScreen> createState() => _ToolOptionsScreenState();
}

class _ToolOptionsScreenState extends ConsumerState<ToolOptionsScreen> {
  late final List<PreparedInput> _inputs = [...widget.inputs];
  late final _name = TextEditingController(
    text: PdfToolsService.defaultName(
      widget.tool,
      widget.inputs.first.input.name,
      DateTime.now(),
    ),
  );

  // Split.
  var _splitMode = _SplitMode.ranges;
  final _ranges = TextEditingController();
  var _every = 1;

  // Compress.
  var _level = CompressLevel.balanced;
  var _ocr = true;

  // Protect.
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _showPassword = false;

  // Watermark and page numbers.
  var _wmKind = _WatermarkKind.text;
  final _wmText = TextEditingController();
  ToolInput? _wmImage;
  var _opacity = 0.25;
  var _angle = 45.0;
  var _size = _StampSize.medium;
  var _color = 0x808080;
  var _allPages = true;
  final _pages = TextEditingController();
  var _position = StampPosition.bottomCenter;
  var _format = _NumberFormat.pageOfTotal;
  var _skipFirst = false;
  final _start = TextEditingController(text: '1');

  PreparedInput get _first => _inputs.first;
  int get _pageCount => _first.info?.pageCount ?? 0;

  @override
  void initState() {
    super.initState();
    for (final c in [_ranges, _password, _confirm, _wmText, _pages, _start]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _ranges,
      _password,
      _confirm,
      _wmText,
      _pages,
      _start,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Validation -------------------------------------------------------------

  List<int>? get _pageSelection =>
      _allPages ? null : parsePageRanges(_pages.text, _pageCount);

  List<List<int>>? get _splitGroups => switch (_splitMode) {
    _SplitMode.ranges => parseRangeGroups(_ranges.text, _pageCount),
    _SplitMode.every => splitEvery(_pageCount, _every),
    _SplitMode.extract => switch (parsePageRanges(_ranges.text, _pageCount)) {
      final pages? => [pages],
      null => null,
    },
  };

  bool get _valid {
    if (_name.text.trim().isEmpty) return false;
    return switch (widget.tool) {
      ToolId.merge => _inputs.length >= 2,
      ToolId.split => _splitGroups != null,
      ToolId.protect =>
        _password.text.length >= 4 && _password.text == _confirm.text,
      ToolId.unlock => _first.info?.encrypted ?? false,
      ToolId.watermark =>
        (_wmKind == _WatermarkKind.text
                ? _wmText.text.trim().isNotEmpty
                : _wmImage != null) &&
            (_allPages || _pageSelection != null),
      ToolId.pageNumbers =>
        int.tryParse(_start.text) != null && (!_skipFirst || _pageCount > 1),
      _ => true,
    };
  }

  String _actionLabel(AppLocalizations l) => switch (widget.tool) {
    ToolId.merge => l.toolMergeAction(_inputs.length),
    ToolId.split => switch (_splitGroups?.length) {
      final n? when n > 1 => l.toolSplitActionMany(n),
      _ => l.toolSplitAction,
    },
    ToolId.compress => l.toolCompressAction,
    ToolId.protect => l.toolProtectAction,
    ToolId.unlock => l.toolUnlockAction,
    ToolId.watermark => l.toolWatermarkAction,
    ToolId.pageNumbers => l.toolPageNumbersAction,
    _ => l.actionSave,
  };

  // Running ----------------------------------------------------------------

  Future<void> _run() async {
    FocusScope.of(context).unfocus();
    final service = ref.read(pdfToolsServiceProvider);
    final name = _name.text.trim();
    final first = _first;
    final tool = widget.tool;
    await runToolJob(context, ref, tool, (control) {
      switch (tool) {
        case ToolId.merge:
          return service.merge(
            inputs: [for (final i in _inputs) i.input],
            passwords: {
              for (var i = 0; i < _inputs.length; i++)
                if (_inputs[i].password != null) i: _inputs[i].password!,
            },
            name: name,
            control: control,
          );
        case ToolId.split:
          return service.split(
            input: first.input,
            password: first.password,
            groups: _splitGroups!,
            name: name,
            control: control,
          );
        case ToolId.compress:
          return service.compress(
            input: first.input,
            password: first.password,
            level: _level,
            ocr: _ocr,
            name: name,
            control: control,
          );
        case ToolId.protect:
          return service.protect(
            input: first.input,
            currentPassword: first.password,
            password: _password.text,
            name: name,
            control: control,
          );
        case ToolId.unlock:
          return service.unlock(
            input: first.input,
            password: first.password ?? '',
            name: name,
            control: control,
          );
        case ToolId.watermark:
          return service.stamp(
            tool: tool,
            input: first.input,
            password: first.password,
            stamp: _watermarkSpec(),
            image: _wmKind == _WatermarkKind.image ? _wmImage : null,
            pages: _pageSelection,
            name: name,
            control: control,
          );
        case ToolId.pageNumbers:
          final start = int.parse(_start.text);
          return service.stamp(
            tool: tool,
            input: first.input,
            password: first.password,
            stamp: StampSpec.text(
              switch (_format) {
                _NumberFormat.plain => '{n}',
                _NumberFormat.pageOfTotal => 'Page {n} of {total}',
                _NumberFormat.slash => '{n} / {total}',
              },
              fontSize: 10,
              colorRgb: 0x333333,
              position: _position,
              margin: 24,
            ),
            pages: _skipFirst ? [for (var i = 1; i < _pageCount; i++) i] : null,
            firstNumber: start,
            name: name,
            control: control,
          );
        case ToolId.organize ||
            ToolId.sign ||
            ToolId.annotate ||
            ToolId.fillForms ||
            ToolId.redact:
          throw StateError('not an options tool');
      }
    });
  }

  StampSpec _watermarkSpec() {
    final size = switch (_size) {
      _StampSize.small => 0,
      _StampSize.medium => 1,
      _StampSize.large => 2,
    };
    if (_wmKind == _WatermarkKind.image) {
      return StampSpec.image(
        const [],
        imageWidth: 1,
        imageHeight: 1,
        imageWidthPt: const [140.0, 240.0, 380.0][size],
        opacity: _opacity,
        angle: _angle,
      );
    }
    return StampSpec.text(
      _wmText.text.trim(),
      fontSize: const [36.0, 60.0, 92.0][size],
      bold: true,
      colorRgb: _color,
      opacity: _opacity,
      angle: _angle,
    );
  }

  Future<void> _addFiles() async {
    final picked = await Navigator.of(context).push<List<ToolInput>>(
      MaterialPageRoute(
        builder: (context) => ToolPicker(
          tool: ToolId.merge,
          onPicked: (inputs) => Navigator.of(context).pop(inputs),
        ),
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    final prepared = await prepareInputs(context, ref, picked);
    if (prepared == null || !mounted) return;
    setState(() => _inputs.addAll(prepared));
  }

  Future<void> _pickWatermarkImage() async {
    final files = await ref
        .read(platformProvider)
        .pickFiles(mimes: const ['image/*']);
    if (files.isEmpty || !mounted) return;
    final f = files.first;
    setState(
      () => _wmImage = ToolInput(
        uri: f.uri,
        name: f.name ?? 'image',
        mime: f.mime,
        size: f.size,
      ),
    );
  }

  // Building ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ToolScaffold(
      title: toolTitle(l, widget.tool),
      subtitle: widget.tool == ToolId.merge ? null : _first.input.name,
      actionLabel: _actionLabel(l),
      onAction: _valid ? () => unawaited(_run()) : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.x6),
        children: [
          if (widget.tool == ToolId.merge)
            ..._mergeInputs(context)
          else
            _summary(context),
          ..._options(context),
          OptionLabel(l.toolOutputName),
          OptionPad(
            TextField(
              controller: _name,
              textInputAction: TextInputAction.done,
              style: DocNookText.body,
              decoration: const InputDecoration(suffixText: '.pdf'),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final l = AppLocalizations.of(context);
    final info = _first.info;
    final size = _first.input.size;
    return FileRow(
      type: DocType.pdf,
      name: _first.input.name,
      details: [
        if (info != null) l.pagesCount(info.pageCount),
        if (size != null) l.fileSize(size),
      ].join(' · '),
    );
  }

  List<Widget> _mergeInputs(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return [
      OptionLabel(l.toolMergeOrder),
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _inputs.length,
        onReorderItem: (from, to) => setState(() {
          _inputs.insert(to, _inputs.removeAt(from));
        }),
        itemBuilder: (context, i) {
          final p = _inputs[i];
          return Row(
            key: ValueKey(p),
            children: [
              ReorderableDragStartListener(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.all(Space.x3),
                  child: Icon(
                    PhosphorIconsRegular.dotsSixVertical,
                    size: Sizes.icon,
                    color: c.inkMuted,
                    semanticLabel: l.toolDragToReorder,
                  ),
                ),
              ),
              Expanded(
                child: FileRow(
                  type: p.input.type,
                  name: p.input.name,
                  details: p.info == null
                      ? l.toolImagePage
                      : l.pagesCount(p.info!.pageCount),
                ),
              ),
              IconAction(
                icon: PhosphorIconsRegular.x,
                label: l.actionRemove,
                onPressed: () => setState(() => _inputs.removeAt(i)),
              ),
            ],
          );
        },
      ),
      OptionPad(
        Align(
          alignment: Alignment.centerLeft,
          child: QuietButton(label: l.toolAddFiles, onPressed: _addFiles),
        ),
      ),
      if (_inputs.length < 2)
        OptionPad(
          Text(
            l.toolMergeNeedTwo,
            style: DocNookText.caption.copyWith(color: c.inkMuted),
          ),
        ),
    ];
  }

  List<Widget> _options(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    Widget hint(String text, {bool error = false}) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.x2,
        Space.screen,
        0,
      ),
      child: Text(
        text,
        style: DocNookText.caption.copyWith(
          color: error ? c.danger : c.inkMuted,
        ),
      ),
    );

    switch (widget.tool) {
      case ToolId.split:
        final groups = _splitGroups;
        return [
          OptionLabel(l.toolSplitHow),
          SegmentedChoice<_SplitMode>(
            values: _SplitMode.values,
            selected: _splitMode,
            label: (m) => switch (m) {
              _SplitMode.ranges => l.toolSplitRanges,
              _SplitMode.every => l.toolSplitEvery,
              _SplitMode.extract => l.toolSplitExtract,
            },
            onSelected: (m) => setState(() => _splitMode = m),
          ),
          if (_splitMode == _SplitMode.every) ...[
            OptionLabel(l.toolSplitEveryLabel),
            OptionPad(
              _Stepper(
                value: _every,
                min: 1,
                max: _pageCount < 1 ? 1 : _pageCount,
                onChanged: (v) => setState(() => _every = v),
              ),
            ),
          ] else ...[
            OptionLabel(
              _splitMode == _SplitMode.ranges
                  ? l.toolSplitRangesLabel
                  : l.toolSplitExtractLabel,
            ),
            OptionPad(
              TextField(
                controller: _ranges,
                keyboardType: TextInputType.text,
                style: DocNookText.body,
                decoration: InputDecoration(hintText: l.toolRangesHint),
              ),
            ),
          ],
          if (_ranges.text.isNotEmpty || _splitMode == _SplitMode.every)
            hint(
              groups == null
                  ? l.toolRangesInvalid(_pageCount)
                  : l.toolSplitResult(groups.length),
              error: groups == null,
            )
          else
            hint(l.toolRangesHelp(_pageCount)),
        ];
      case ToolId.compress:
        String title(CompressLevel v) => switch (v) {
          CompressLevel.light => l.toolCompressLight,
          CompressLevel.balanced => l.toolCompressBalanced,
          CompressLevel.strong => l.toolCompressStrong,
        };
        String body(CompressLevel v) => switch (v) {
          CompressLevel.light => l.toolCompressLightDesc,
          CompressLevel.balanced => l.toolCompressBalancedDesc,
          CompressLevel.strong => l.toolCompressStrongDesc,
        };
        return [
          OptionLabel(l.toolCompressLevel),
          RadioGroup<CompressLevel>(
            groupValue: _level,
            onChanged: (v) => setState(() => _level = v ?? _level),
            child: Column(
              children: [
                for (final v in CompressLevel.values)
                  RadioListTile<CompressLevel>(
                    value: v,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Space.x2,
                    ),
                    title: Text(title(v), style: DocNookText.body),
                    subtitle: Text(
                      body(v),
                      style: DocNookText.caption.copyWith(color: c.inkMuted),
                    ),
                  ),
              ],
            ),
          ),
          if (_level == CompressLevel.strong)
            SwitchListTile(
              value: _ocr,
              onChanged: (v) => setState(() => _ocr = v),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Space.screen,
              ),
              title: Text(l.scanOcrToggle, style: DocNookText.body),
              subtitle: Text(
                l.toolCompressOcrHelp,
                style: DocNookText.caption.copyWith(color: c.inkMuted),
              ),
            ),
        ];
      case ToolId.protect:
        final mismatch =
            _confirm.text.isNotEmpty && _confirm.text != _password.text;
        InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          suffixIcon: IconAction(
            icon: _showPassword
                ? PhosphorIconsRegular.eyeSlash
                : PhosphorIconsRegular.eye,
            label: _showPassword ? l.passwordHide : l.passwordShow,
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        );
        return [
          OptionLabel(l.toolProtectPassword),
          OptionPad(
            TextField(
              controller: _password,
              obscureText: !_showPassword,
              autocorrect: false,
              enableSuggestions: false,
              style: DocNookText.body,
              decoration: deco(l.toolPasswordNew),
            ),
          ),
          const SizedBox(height: Space.x3),
          OptionPad(
            TextField(
              controller: _confirm,
              obscureText: !_showPassword,
              autocorrect: false,
              enableSuggestions: false,
              style: DocNookText.body,
              decoration: deco(l.toolPasswordConfirm),
            ),
          ),
          if (mismatch)
            hint(l.toolPasswordMismatch, error: true)
          else if (_password.text.isNotEmpty && _password.text.length < 4)
            hint(l.toolPasswordShort, error: true)
          else
            hint(l.toolProtectWarning),
        ];
      case ToolId.unlock:
        return [
          hint(
            (_first.info?.encrypted ?? false)
                ? l.toolUnlockHelp
                : l.toolUnlockNotLocked,
          ),
        ];
      case ToolId.watermark:
        return [
          OptionLabel(l.toolWatermarkKind),
          SegmentedChoice<_WatermarkKind>(
            values: _WatermarkKind.values,
            selected: _wmKind,
            label: (k) => k == _WatermarkKind.text
                ? l.toolWatermarkText
                : l.toolWatermarkImage,
            onSelected: (k) => setState(() => _wmKind = k),
          ),
          const SizedBox(height: Space.x3),
          if (_wmKind == _WatermarkKind.text) ...[
            OptionPad(
              TextField(
                controller: _wmText,
                style: DocNookText.body,
                decoration: InputDecoration(hintText: l.toolWatermarkHint),
              ),
            ),
            OptionLabel(l.toolWatermarkColor),
            SegmentedChoice<int>(
              values: const [0x808080, 0xC0392B, 0x1A3A8F],
              selected: _color,
              label: (v) => switch (v) {
                0xC0392B => l.colorRed,
                0x1A3A8F => l.colorBlue,
                _ => l.colorGrey,
              },
              onSelected: (v) => setState(() => _color = v),
            ),
          ] else
            OptionPad(
              Align(
                alignment: Alignment.centerLeft,
                child: SecondaryButton(
                  expand: false,
                  icon: PhosphorIconsRegular.image,
                  label: _wmImage?.name ?? l.toolWatermarkPickImage,
                  onPressed: _pickWatermarkImage,
                ),
              ),
            ),
          OptionLabel(l.toolWatermarkSize),
          SegmentedChoice<_StampSize>(
            values: _StampSize.values,
            selected: _size,
            label: (s) => switch (s) {
              _StampSize.small => l.sizeSmall,
              _StampSize.medium => l.sizeMedium,
              _StampSize.large => l.sizeLarge,
            },
            onSelected: (s) => setState(() => _size = s),
          ),
          OptionLabel(l.toolWatermarkAngle),
          SegmentedChoice<double>(
            values: const [0, 45, 90],
            selected: _angle,
            label: (a) => '${a.round()}°',
            onSelected: (a) => setState(() => _angle = a),
          ),
          OptionLabel(l.toolWatermarkOpacity((_opacity * 100).round())),
          Slider(
            value: _opacity,
            min: 0.1,
            divisions: 9,
            label: '${(_opacity * 100).round()}%',
            onChanged: (v) => setState(() => _opacity = v),
          ),
          ..._pagesChoice(context, hint),
        ];
      case ToolId.pageNumbers:
        return [
          OptionLabel(l.toolNumbersPosition),
          FilterChips<StampPosition>(
            values: const [
              StampPosition.bottomCenter,
              StampPosition.bottomRight,
              StampPosition.bottomLeft,
              StampPosition.topCenter,
              StampPosition.topRight,
              StampPosition.topLeft,
            ],
            selected: _position,
            label: (pos) => _positionLabel(l, pos),
            onSelected: (pos) => setState(() => _position = pos),
          ),
          OptionLabel(l.toolNumbersFormat),
          SegmentedChoice<_NumberFormat>(
            values: _NumberFormat.values,
            selected: _format,
            label: (f) => switch (f) {
              _NumberFormat.plain => '1',
              _NumberFormat.pageOfTotal => l.toolNumbersPageOf,
              _NumberFormat.slash => '1 / N',
            },
            onSelected: (f) => setState(() => _format = f),
          ),
          OptionLabel(l.toolNumbersStart),
          OptionPad(
            TextField(
              controller: _start,
              keyboardType: TextInputType.number,
              style: DocNookText.body,
            ),
          ),
          SwitchListTile(
            value: _skipFirst,
            onChanged: (v) => setState(() => _skipFirst = v),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Space.screen,
            ),
            title: Text(l.toolNumbersSkipFirst, style: DocNookText.body),
          ),
        ];
      case ToolId.merge ||
          ToolId.organize ||
          ToolId.sign ||
          ToolId.annotate ||
          ToolId.fillForms ||
          ToolId.redact:
        return const [];
    }
  }

  List<Widget> _pagesChoice(
    BuildContext context,
    Widget Function(String, {bool error}) hint,
  ) {
    final l = AppLocalizations.of(context);
    return [
      OptionLabel(l.toolPages),
      SegmentedChoice<bool>(
        values: const [true, false],
        selected: _allPages,
        label: (all) => all ? l.toolPagesAll : l.toolPagesSome,
        onSelected: (all) => setState(() => _allPages = all),
      ),
      if (!_allPages) ...[
        const SizedBox(height: Space.x3),
        OptionPad(
          TextField(
            controller: _pages,
            style: DocNookText.body,
            decoration: InputDecoration(hintText: l.toolRangesHint),
          ),
        ),
        if (_pages.text.isNotEmpty && _pageSelection == null)
          hint(l.toolRangesInvalid(_pageCount), error: true)
        else
          hint(l.toolRangesHelp(_pageCount)),
      ],
    ];
  }

  static String _positionLabel(AppLocalizations l, StampPosition p) =>
      switch (p) {
        StampPosition.bottomCenter => l.posBottomCenter,
        StampPosition.bottomRight => l.posBottomRight,
        StampPosition.bottomLeft => l.posBottomLeft,
        StampPosition.topCenter => l.posTopCenter,
        StampPosition.topRight => l.posTopRight,
        StampPosition.topLeft => l.posTopLeft,
        StampPosition.center => l.posCenter,
      };
}

/// − value + with the value in the middle.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        IconAction(
          icon: PhosphorIconsRegular.minus,
          label: l.actionDecrease,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: Space.x12,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: DocNookText.bodyStrong,
          ),
        ),
        IconAction(
          icon: PhosphorIconsRegular.plus,
          label: l.actionIncrease,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

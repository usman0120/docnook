import 'dart:async';

import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/data/repositories/library_repository.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/features/library/presentation/files_screen.dart';
import 'package:docnook/features/tools/application/pdf_tools_service.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:docnook/features/tools/presentation/annotate_screen.dart';
import 'package:docnook/features/tools/presentation/form_fill_screen.dart';
import 'package:docnook/features/tools/presentation/organize_screen.dart';
import 'package:docnook/features/tools/presentation/redact_screen.dart';
import 'package:docnook/features/tools/presentation/tool_options_screen.dart';
import 'package:docnook/features/tools/presentation/tool_sheets.dart';
import 'package:docnook/features/viewer/presentation/password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A PDF ready for a tool: where it is, its password and its pages.
final class PreparedInput {
  const PreparedInput(this.input, this.password, this.info);
  final ToolInput input;
  final String? password;

  /// Null for pictures.
  final PdfInfo? info;
}

/// Opens each PDF once: asks for its password when needed and reads its
/// pages. Null when the user backed out of a password or a file failed
/// (a message says which).
Future<List<PreparedInput>?> prepareInputs(
  BuildContext context,
  WidgetRef ref,
  List<ToolInput> inputs,
) async {
  final service = ref.read(pdfToolsServiceProvider);
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final out = <PreparedInput>[];
  for (final input in inputs) {
    if (input.type == DocType.image) {
      out.add(PreparedInput(input, null, null));
      continue;
    }
    String? password;
    var wrong = false;
    while (true) {
      try {
        final info = await service.inspect(input, password: password);
        out.add(PreparedInput(input, password, info));
        break;
      } on DocNookFailure catch (f) {
        if (!context.mounted) return null;
        if (f.kind == FailureKind.passwordRequired ||
            f.kind == FailureKind.wrongPassword) {
          password = await askPassword(context, wrongBefore: wrong);
          wrong = true;
          if (password == null) return null;
          continue;
        }
        final (title, _) = l.failureText(f);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('${input.name}: $title')));
        return null;
      }
    }
  }
  return out;
}

/// The shared tool flow (BLUEPRINT 10.4): S08 select files, then the tool's
/// S09 options or its own editor. [initial] skips the picker ("Do more",
/// viewer and file-sheet shortcuts).
class ToolFlowScreen extends ConsumerStatefulWidget {
  const ToolFlowScreen({
    required this.tool,
    this.initial = const [],
    super.key,
  });

  final ToolId tool;
  final List<ToolInput> initial;

  @override
  ConsumerState<ToolFlowScreen> createState() => _ToolFlowScreenState();
}

class _ToolFlowScreenState extends ConsumerState<ToolFlowScreen> {
  List<PreparedInput>? _prepared;
  bool _preparing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_prepare(widget.initial)),
      );
    }
  }

  Future<void> _prepare(List<ToolInput> inputs) async {
    setState(() => _preparing = true);
    final prepared = await prepareInputs(context, ref, inputs);
    if (!mounted) return;
    if (prepared == null && widget.initial.isNotEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _preparing = false;
      _prepared = prepared;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prepared = _prepared;
    if (_preparing || (prepared == null && widget.initial.isNotEmpty)) {
      return Scaffold(
        backgroundColor: context.colors.paper,
        body: LoadingState(label: l.toolOpening),
      );
    }
    if (prepared == null) {
      return ToolPicker(
        tool: widget.tool,
        onPicked: (inputs) => unawaited(_prepare(inputs)),
      );
    }
    final first = prepared.first;
    return switch (widget.tool) {
      ToolId.organize => OrganizeScreen(input: first),
      ToolId.sign || ToolId.annotate => AnnotateScreen(
        input: first,
        signMode: widget.tool == ToolId.sign,
      ),
      ToolId.fillForms => FormFillScreen(input: first),
      ToolId.redact => RedactScreen(input: first),
      _ => ToolOptionsScreen(tool: widget.tool, inputs: prepared),
    };
  }
}

/// S08 Select files: DocNook's library filtered to what the tool accepts,
/// plus "Browse device".
class ToolPicker extends ConsumerStatefulWidget {
  const ToolPicker({required this.tool, required this.onPicked, super.key});

  final ToolId tool;
  final ValueChanged<List<ToolInput>> onPicked;

  @override
  ConsumerState<ToolPicker> createState() => _ToolPickerState();
}

class _ToolPickerState extends ConsumerState<ToolPicker> {
  final _selected = <int, DocumentInfo>{};

  ToolInput _input(DocumentInfo d) => ToolInput(
    uri: d.uri,
    name: d.name,
    mime: d.mime,
    size: d.sizeBytes,
    documentId: d.id,
  );

  Future<void> _browse() async {
    final files = await ref
        .read(platformProvider)
        .pickFiles(
          mimes: ['application/pdf', if (widget.tool.acceptsImages) 'image/*'],
          multiple: widget.tool.multiple,
        );
    if (files.isEmpty || !mounted) return;
    widget.onPicked([
      for (final f in files)
        ToolInput(
          uri: f.uri,
          name: f.name ?? 'file.pdf',
          mime: f.mime,
          size: f.size,
        ),
    ]);
  }

  void _tap(DocumentInfo d) {
    if (!widget.tool.multiple) {
      widget.onPicked([_input(d)]);
      return;
    }
    setState(() {
      if (_selected.remove(d.id) == null) _selected[d.id] = d;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final query = (
      filter: widget.tool.acceptsImages ? LibraryFilter.all : LibraryFilter.pdf,
      sort: LibrarySort.recent,
      collection: null,
    );
    final async = ref.watch(libraryDocsProvider(query));
    final docs = [
      for (final d in async.value ?? const <DocumentInfo>[])
        if (d.type == DocType.pdf ||
            (widget.tool.acceptsImages && d.type == DocType.image))
          d,
    ];
    final count = _selected.length;
    return Scaffold(
      backgroundColor: c.paper,
      appBar: AppBar(
        backgroundColor: c.paper,
        surfaceTintColor: Colors.transparent,
        title: Text(toolTitle(l, widget.tool), style: DocNookText.sectionTitle),
        actions: [
          QuietButton(label: l.toolBrowseDevice, onPressed: _browse),
          const SizedBox(width: Space.x2),
        ],
      ),
      body: switch (async) {
        AsyncError() => ErrorState(
          title: l.toolPickErrorTitle,
          body: l.toolPickErrorBody,
          actionLabel: l.toolBrowseDevice,
          onAction: _browse,
        ),
        _ when async.isLoading && docs.isEmpty => const LoadingState(),
        _ when docs.isEmpty => EmptyState(
          art: EmptyArt.openFolder,
          title: widget.tool.acceptsImages
              ? l.toolPickEmptyAny
              : l.toolPickEmptyPdf,
          body: l.toolPickEmptyBody,
          primaryLabel: l.toolBrowseDevice,
          onPrimary: _browse,
        ),
        _ => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                0,
                Space.screen,
                Space.x2,
              ),
              child: Text(
                widget.tool.multiple ? l.toolPickMany : l.toolPickOne,
                style: DocNookText.caption.copyWith(color: c.inkMuted),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i];
                  return FileRow(
                    type: d.type,
                    name: d.name,
                    details: l.documentDetails(d),
                    selecting: widget.tool.multiple,
                    selected: _selected.containsKey(d.id),
                    onTap: () => _tap(d),
                  );
                },
              ),
            ),
            if (widget.tool.multiple)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.screen,
                    Space.x2,
                    Space.screen,
                    Space.x3,
                  ),
                  child: PrimaryButton(
                    label: count == 0
                        ? l.toolPickNone
                        : l.toolContinueWith(count),
                    icon: PhosphorIconsRegular.check,
                    onPressed: count == 0
                        ? null
                        : () => widget.onPicked([
                            for (final d in _selected.values) _input(d),
                          ]),
                  ),
                ),
              ),
          ],
        ),
      },
    );
  }
}

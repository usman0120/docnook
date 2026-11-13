import 'dart:async';

import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/app/providers.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/components/sheets.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/domain/entities/document_info.dart';
import 'package:docnook/engines/pdf/pdfium_editor.dart';
import 'package:docnook/features/library/presentation/file_sheets.dart';
import 'package:docnook/features/tools/application/pdf_tools_service.dart';
import 'package:docnook/features/tools/application/tool_job.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:docnook/features/viewer/application/open_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The tool's name as shown in the hub.
String toolTitle(AppLocalizations l, ToolId tool) => switch (tool) {
  ToolId.merge => l.toolMerge,
  ToolId.split => l.toolSplit,
  ToolId.organize => l.toolOrganize,
  ToolId.compress => l.toolCompress,
  ToolId.protect => l.toolProtect,
  ToolId.unlock => l.toolUnlock,
  ToolId.watermark => l.toolWatermark,
  ToolId.pageNumbers => l.toolPageNumbers,
  ToolId.sign => l.toolSign,
  ToolId.annotate => l.toolAnnotate,
  ToolId.fillForms => l.toolFillForms,
  ToolId.redact => l.toolRedact,
};

IconData toolIcon(ToolId tool) => switch (tool) {
  ToolId.merge => PhosphorIconsRegular.stack,
  ToolId.split => PhosphorIconsRegular.scissors,
  ToolId.organize => PhosphorIconsRegular.squaresFour,
  ToolId.compress => PhosphorIconsRegular.arrowsIn,
  ToolId.protect => PhosphorIconsRegular.lockSimple,
  ToolId.unlock => PhosphorIconsRegular.lockSimpleOpen,
  ToolId.watermark => PhosphorIconsRegular.drop,
  ToolId.pageNumbers => PhosphorIconsRegular.listNumbers,
  ToolId.sign => PhosphorIconsRegular.signature,
  ToolId.annotate => PhosphorIconsRegular.highlighterCircle,
  ToolId.fillForms => PhosphorIconsRegular.textbox,
  ToolId.redact => PhosphorIconsRegular.rectangle,
};

/// Runs a tool job with the S10 progress sheet, then shows S11. Returns
/// true when the job produced a result (so the caller can close its
/// screen).
///
/// With [closeTools] (the default) the tool screens close once the result
/// is shown, so Open or Do more lands on top of the app, not the editor.
Future<bool> runToolJob(
  BuildContext context,
  WidgetRef ref,
  ToolId tool,
  Future<ToolResult> Function(EditControl control) body, {
  bool closeTools = true,
}) async {
  final l = AppLocalizations.of(context);
  final jobs = ref.read(toolJobProvider.notifier);
  if (jobs.busy) {
    _snack(context, l.toolBusy);
    return false;
  }
  unawaited(jobs.start(tool, body));
  await showToolProgress(context, ref);
  if (!context.mounted) return false;
  final state = ref.read(toolJobProvider);
  if (state == null || state.running || !state.watched) return false;
  return await showToolOutcome(context, ref, closeTools: closeTools);
}

/// Shows the finished job's result or failure, then forgets the job.
Future<bool> showToolOutcome(
  BuildContext context,
  WidgetRef ref, {
  bool closeTools = true,
}) async {
  final l = AppLocalizations.of(context);
  final state = ref.read(toolJobProvider);
  if (state == null || state.running) return false;
  ref.read(toolJobProvider.notifier).clear();
  final failure = state.failure;
  if (failure != null) {
    if (failure.kind == FailureKind.cancelled) {
      _snack(context, l.toolCancelled);
    } else {
      final (title, body) = l.failureText(failure);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            QuietButton(
              label: l.actionOk,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
    return false;
  }
  await showToolResult(context, ref, state.result!, closeTools: closeTools);
  return true;
}

/// S10: determinate progress, a step label and Cancel. Dismissing it lets
/// the job carry on behind a chip on the Tools tab.
Future<void> showToolProgress(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final jobs = ref.read(toolJobProvider.notifier);
  final tool = ref.read(toolJobProvider)?.tool;
  if (tool == null) return;
  jobs.setWatched(watched: true);
  final finished = await showDocNookSheet<bool>(
    context,
    title: toolTitle(l, tool),
    builder: (context, _) => const _ProgressBody(),
  );
  if (finished != true) jobs.setWatched(watched: false);
}

class _ProgressBody extends ConsumerWidget {
  const _ProgressBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    ref.listen(toolJobProvider, (_, next) {
      if (next != null && !next.running && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    });
    final s = ref.watch(toolJobProvider);
    final value = s?.progress ?? 0;
    final step = s?.page != null && s?.of != null
        ? l.toolStepPage(s!.page!, s.of!)
        : l.toolStepWorking;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.x2,
        Space.screen,
        Space.x4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: step,
            value: '${(value * 100).round()}%',
            child: ClipRRect(
              borderRadius: Radii.chipAll,
              child: LinearProgressIndicator(
                value: value <= 0 ? null : value,
                minHeight: 6,
                backgroundColor: c.surfaceSunken,
                color: c.primary,
              ),
            ),
          ),
          const SizedBox(height: Space.x3),
          Row(
            children: [
              Expanded(
                child: Text(
                  step,
                  style: DocNookText.caption.copyWith(color: c.inkMuted),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: DocNookText.caption.copyWith(color: c.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: Space.x4),
          Text(
            l.toolKeepsRunning,
            style: DocNookText.caption.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.x4),
          SecondaryButton(
            label: l.actionCancel,
            onPressed: () => ref.read(toolJobProvider.notifier).cancel(),
          ),
        ],
      ),
    );
  }
}

/// S11: what was written, where, and what to do next.
Future<void> showToolResult(
  BuildContext context,
  WidgetRef ref,
  ToolResult result, {
  bool closeTools = true,
}) async {
  final l = AppLocalizations.of(context);
  final router = GoRouter.of(context);
  final platform = ref.read(platformProvider);
  final first = result.outputs.first;
  final action = await showDocNookSheet<String>(
    context,
    title: l.toolDoneTitle,
    builder: (context, _) => _ResultBody(result: result),
  );
  if (!context.mounted) return;
  // Tool screens sit on the root navigator above the tabs.
  final nav = Navigator.of(context, rootNavigator: true);
  if (closeTools) nav.popUntil((route) => route.isFirst);
  final here = closeTools ? nav.context : context;
  if (!here.mounted) return;
  switch (action) {
    case 'open':
      unawaited(
        router.push(
          '/view',
          extra: OpenRequest(
            uri: first.uri,
            name: first.name,
            mime: 'application/pdf',
            source: DocSource.created,
          ),
        ),
      );
    case 'share':
      unawaited(
        platform.share([
          for (final o in result.outputs) o.uri,
        ], mime: 'application/pdf'),
      );
    case 'rename':
      final id = first.documentId;
      final doc = id == null
          ? null
          : await ref.read(documentRepositoryProvider).byId(id);
      if (doc != null && here.mounted) {
        await renameDocument(here, ref, doc);
      }
    case 'folder':
      final shown = await platform.openFolder(
        'Documents/DocNook/${PdfToolsService.subdir}',
      );
      if (!shown && here.mounted) {
        _snack(here, l.toolFolderHint(PdfToolsService.subdir));
      }
    case 'more':
      final next = await pickNextTool(here);
      if (next != null && here.mounted) {
        unawaited(router.push('/tool/${next.name}', extra: [first.asInput]));
      }
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});

  final ToolResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final first = result.outputs.first;
    final count = result.outputs.length;
    final before = result.inputBytes;
    final details = [
      if (count > 1) l.toolFilesCount(count),
      if (count == 1 && first.pages != null) l.pagesCount(first.pages!),
      if (before != null)
        l.toolSizeChange(
          l.fileSize(before),
          l.fileSize(result.totalBytes),
          _percent(before, result.totalBytes),
        )
      else
        l.fileSize(result.totalBytes),
    ].join(' · ');
    Widget quiet(String label, String value) => QuietButton(
      label: label,
      onPressed: () => Navigator.of(context).pop(value),
    );
    return SingleChildScrollView(
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TypeSpine(DocType.pdf),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count > 1
                            ? l.toolFilesNamed(first.name, count - 1)
                            : first.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DocNookText.bodyStrong,
                      ),
                      const SizedBox(height: Space.x1),
                      Text(
                        details,
                        style: DocNookText.caption.copyWith(color: c.inkMuted),
                      ),
                      Text(
                        result.overwritten
                            ? l.toolOverwritten
                            : l.toolSavedIn(PdfToolsService.subdir),
                        style: DocNookText.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (result.failures.isNotEmpty) ...[
            const SizedBox(height: Space.x4),
            Text(l.toolSomeFailed, style: DocNookText.label),
            for (final (name, failure) in result.failures)
              Padding(
                padding: const EdgeInsets.only(top: Space.x1),
                child: Text(
                  '$name: ${l.failureText(failure).$1}',
                  style: DocNookText.caption.copyWith(color: c.danger),
                ),
              ),
          ],
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
          const SizedBox(height: Space.x2),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Space.x2,
            children: [
              if (count == 1 && !result.overwritten)
                quiet(l.actionRename, 'rename'),
              if (!result.overwritten) quiet(l.toolShowInFolder, 'folder'),
              if (count == 1) quiet(l.toolDoMore, 'more'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lets the user pick a PDF tool for [doc], then opens it with the file.
Future<void> openPdfTools(BuildContext context, DocumentInfo doc) async {
  final router = GoRouter.of(context);
  final tool = await pickNextTool(context, includeMerge: true);
  if (tool == null) return;
  await router.push(
    '/tool/${tool.name}',
    extra: [
      ToolInput(
        uri: doc.uri,
        name: doc.name,
        mime: doc.mime,
        size: doc.sizeBytes,
        documentId: doc.id,
      ),
    ],
  );
}

/// "−73%" / "+4%": a typographic minus, as on S11.
String _percent(int before, int after) {
  final change = before == 0 ? 0 : ((after - before) * 100 / before).round();
  return change < 0 ? '−${-change}%' : '+$change%';
}

/// "Do more": the PDF tools, to chain the output into the next one.
Future<ToolId?> pickNextTool(
  BuildContext context, {
  bool includeMerge = false,
}) {
  final l = AppLocalizations.of(context);
  return showDocNookSheet<ToolId>(
    context,
    title: includeMerge ? l.actionPdfTools : l.toolDoMore,
    expand: true,
    builder: (context, scroll) => ListView(
      controller: scroll,
      children: [
        for (final tool in ToolId.values)
          if (includeMerge || tool != ToolId.merge)
            ListTile(
              leading: Icon(toolIcon(tool), size: Sizes.icon),
              title: Text(toolTitle(l, tool), style: DocNookText.body),
              onTap: () => Navigator.of(context).pop(tool),
            ),
      ],
    ),
  );
}

/// The Tools-tab chip for a job running behind a dismissed sheet.
class ToolJobChip extends ConsumerWidget {
  const ToolJobChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final s = ref.watch(toolJobProvider);
    if (s == null || s.watched) return const SizedBox.shrink();
    final label = s.running
        ? l.toolChipRunning(toolTitle(l, s.tool), (s.progress * 100).round())
        : s.failure != null
        ? l.toolChipFailed(toolTitle(l, s.tool))
        : l.toolChipDone(toolTitle(l, s.tool));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        0,
        Space.screen,
        Space.x3,
      ),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardAll,
          side: BorderSide(color: c.hairline),
        ),
        child: InkWell(
          borderRadius: Radii.cardAll,
          onTap: () async {
            if (s.running) {
              await showToolProgress(context, ref);
              if (!context.mounted) return;
              final now = ref.read(toolJobProvider);
              if (now != null && !now.running && now.watched) {
                await showToolOutcome(context, ref);
              }
            } else {
              ref.read(toolJobProvider.notifier).setWatched(watched: true);
              await showToolOutcome(context, ref);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(Space.x3),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: Sizes.iconSmall,
                  child: s.running
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          value: s.progress <= 0 ? null : s.progress,
                          color: c.primary,
                        )
                      : Icon(
                          s.failure != null
                              ? PhosphorIconsRegular.warningCircle
                              : PhosphorIconsRegular.checkCircle,
                          size: Sizes.iconSmall,
                          color: s.failure != null ? c.danger : c.success,
                        ),
                ),
                const SizedBox(width: Space.x3),
                Expanded(child: Text(label, style: DocNookText.label)),
                Icon(
                  PhosphorIconsRegular.caretRight,
                  size: Sizes.iconSmall,
                  color: c.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

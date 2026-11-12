import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/tool_tile.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:flutter/material.dart';

/// One entry of the Tools hub.
final class ToolEntry {
  const ToolEntry(
    this.id,
    this.icon,
    this.title,
    this.description, {
    this.input,
  });
  final String id;
  final IconData icon;
  final String title;
  final String description;

  /// Main input type, used to tint the icon.
  final DocType? input;
}

/// S07 Tools hub: three groups of tool tiles.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static List<(String, List<ToolEntry>)> groups(AppLocalizations l) => [
    (
      l.toolsGroupPdf,
      [
        ToolEntry(
          'merge',
          PhosphorIconsRegular.stack,
          l.toolMerge,
          l.toolMergeDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'split',
          PhosphorIconsRegular.scissors,
          l.toolSplit,
          l.toolSplitDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'organize',
          PhosphorIconsRegular.squaresFour,
          l.toolOrganize,
          l.toolOrganizeDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'compress',
          PhosphorIconsRegular.arrowsIn,
          l.toolCompress,
          l.toolCompressDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'protect',
          PhosphorIconsRegular.lockSimple,
          l.toolProtect,
          l.toolProtectDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'unlock',
          PhosphorIconsRegular.lockSimpleOpen,
          l.toolUnlock,
          l.toolUnlockDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'watermark',
          PhosphorIconsRegular.drop,
          l.toolWatermark,
          l.toolWatermarkDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'pageNumbers',
          PhosphorIconsRegular.listNumbers,
          l.toolPageNumbers,
          l.toolPageNumbersDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'sign',
          PhosphorIconsRegular.signature,
          l.toolSign,
          l.toolSignDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'annotate',
          PhosphorIconsRegular.highlighterCircle,
          l.toolAnnotate,
          l.toolAnnotateDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'fillForms',
          PhosphorIconsRegular.textbox,
          l.toolFillForms,
          l.toolFillFormsDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'redact',
          PhosphorIconsRegular.rectangle,
          l.toolRedact,
          l.toolRedactDesc,
          input: DocType.pdf,
        ),
      ],
    ),
    (
      l.toolsGroupConvert,
      [
        ToolEntry(
          'imagesToPdf',
          PhosphorIconsRegular.images,
          l.toolImagesToPdf,
          l.toolImagesToPdfDesc,
          input: DocType.image,
        ),
        ToolEntry(
          'pdfToImages',
          PhosphorIconsRegular.image,
          l.toolPdfToImages,
          l.toolPdfToImagesDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'wordToPdf',
          PhosphorIconsRegular.fileDoc,
          l.toolWordToPdf,
          l.toolWordToPdfDesc,
          input: DocType.word,
        ),
        ToolEntry(
          'excelToPdf',
          PhosphorIconsRegular.fileXls,
          l.toolExcelToPdf,
          l.toolExcelToPdfDesc,
          input: DocType.sheet,
        ),
        ToolEntry(
          'pptToPdf',
          PhosphorIconsRegular.filePpt,
          l.toolPptToPdf,
          l.toolPptToPdfDesc,
          input: DocType.slides,
        ),
        ToolEntry(
          'pdfToWord',
          PhosphorIconsRegular.fileText,
          l.toolPdfToWord,
          l.toolPdfToWordDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'pdfToText',
          PhosphorIconsRegular.textAa,
          l.toolPdfToText,
          l.toolPdfToTextDesc,
          input: DocType.pdf,
        ),
        ToolEntry(
          'textToPdf',
          PhosphorIconsRegular.fileTxt,
          l.toolTextToPdf,
          l.toolTextToPdfDesc,
          input: DocType.text,
        ),
        ToolEntry(
          'csvExcel',
          PhosphorIconsRegular.table,
          l.toolCsvExcel,
          l.toolCsvExcelDesc,
          input: DocType.sheet,
        ),
      ],
    ),
    (
      l.toolsGroupScan,
      [
        ToolEntry(
          'scanDoc',
          PhosphorIconsRegular.scan,
          l.toolScanDoc,
          l.toolScanDocDesc,
        ),
        ToolEntry(
          'scanId',
          PhosphorIconsRegular.identificationCard,
          l.toolScanId,
          l.toolScanIdDesc,
        ),
        ToolEntry(
          'scanBook',
          PhosphorIconsRegular.bookOpen,
          l.toolScanBook,
          l.toolScanBookDesc,
        ),
        ToolEntry(
          'scanOcr',
          PhosphorIconsRegular.textT,
          l.toolScanOcr,
          l.toolScanOcrDesc,
        ),
        ToolEntry(
          'extractText',
          PhosphorIconsRegular.copy,
          l.toolExtractText,
          l.toolExtractTextDesc,
          input: DocType.image,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    void later() => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.comingInPhase)));

    // Wider tiles at large text sizes so two lines of description still fit.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    // Fits icon + title + two caption lines exactly; grows with text size.
    final extent = 56 + 54 * scale;

    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverToBoxAdapter(child: LargeTitle(l.toolsTitle)),
        ),
        for (final (title, tools) in groups(l)) ...[
          SliverToBoxAdapter(child: SectionHeader(title)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Space.screen),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: scale > 1.6 ? 1 : 2,
                mainAxisSpacing: Space.x3,
                crossAxisSpacing: Space.x3,
                mainAxisExtent: extent,
              ),
              itemCount: tools.length,
              itemBuilder: (context, i) => ToolTile(
                icon: tools[i].icon,
                title: tools[i].title,
                description: tools[i].description,
                tint: tools[i].input == null
                    ? null
                    : c.fileType(tools[i].input!),
                onTap: later,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: Space.x8)),
      ],
    );
  }
}

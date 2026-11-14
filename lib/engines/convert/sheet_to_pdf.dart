import 'dart:io';
import 'dart:math' as math;

import 'package:docnook/domain/sheetmodel/number_format.dart';
import 'package:docnook/domain/sheetmodel/sheet_model.dart';
import 'package:docnook/engines/convert/doc_fonts.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final class SheetToPdfRequest {
  const SheetToPdfRequest({
    required this.workbook,
    required this.fonts,
    required this.output,
    this.fitToWidth = true,
    this.systemFontDir = '/system/fonts',
  });

  final Workbook workbook;
  final DocFontBytes fonts;
  final String output;

  /// Shrink each sheet to the page width (down to 40 %); wider sheets then
  /// continue on extra pages, a block of columns at a time.
  final bool fitToWidth;
  final String systemFontDir;
}

/// SheetModel → PDF (BLUEPRINT 2.3): each visible sheet on its own pages,
/// header row repeated, columns split across pages when they do not fit.
/// Runs in a JobRunner isolate. Returns the page count.
Future<int> sheetToPdf(SheetToPdfRequest request, JobContext context) async {
  final wb = request.workbook;
  final sample = StringBuffer();
  for (final sheet in wb.sheets) {
    for (final row in sheet.rows.take(200)) {
      for (final v in row.values) {
        if (v is String) sample.write(v);
      }
    }
  }
  final fonts = DocFonts.load(
    request.fonts,
    text: sample.toString(),
    systemDir: request.systemFontDir,
  );
  final doc = pw.Document(creator: 'DocNook');
  final sheets = [
    for (final s in wb.sheets)
      if (!s.hidden && s.rowCount > 0 && s.colCount > 0) s,
  ];
  for (var i = 0; i < sheets.length; i++) {
    _addSheet(doc, wb, sheets[i], fonts, request.fitToWidth);
    context.progress(0.8 * (i + 1) / sheets.length);
  }
  if (sheets.isEmpty) doc.addPage(pw.Page(build: (_) => pw.SizedBox()));
  File(request.output).writeAsBytesSync(await doc.save(), flush: true);
  context.progress(1);
  return doc.document.pdfPageList.pages.length;
}

const _ink = PdfColor.fromInt(0xFF1B1B1F);
const _grid = PdfColor.fromInt(0xFFD6D6D6);
const _muted = PdfColor.fromInt(0xFF6B6B6B);

/// Width in points of a column set to [chars] Excel character units.
double _colPoints(double chars) => math.max(18, chars * 5.6 + 6);

void _addSheet(
  pw.Document doc,
  Workbook wb,
  Sheet sheet,
  DocFonts fonts,
  bool fit,
) {
  final colCount = math.min(sheet.colCount, 200);
  final widths = [
    for (var c = 0; c < colCount; c++)
      _colPoints(sheet.colWidths[c] ?? sheet.defaultColWidth ?? 8.43),
  ];
  final total = widths.fold<double>(0, (a, b) => a + b);
  const margin = 28.0;
  final landscape = total > PdfPageFormat.a4.width - margin * 2;
  final format = (landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4)
      .copyWith(
        marginLeft: margin,
        marginRight: margin,
        marginTop: margin,
        marginBottom: margin,
      );
  final available = format.availableWidth;
  final scale = fit ? (available / total).clamp(0.4, 1.0) : 1.0;

  // Blocks of columns that fit across one page at this scale.
  final groups = <List<int>>[];
  var current = <int>[];
  var used = 0.0;
  for (var c = 0; c < colCount; c++) {
    final w = widths[c] * scale;
    if (current.isNotEmpty && used + w > available) {
      groups.add(current);
      current = [];
      used = 0;
    }
    current.add(c);
    used += w;
  }
  if (current.isNotEmpty) groups.add(current);

  final rowLimit = math.min(sheet.rowCount, 20000);
  final fontSize = 9 * scale;
  final headerRows = sheet.frozenRows.clamp(0, 3);

  pw.Widget cell(int r, int c) {
    final value = sheet.valueAt(r, c);
    final merge = sheet.mergeAt(r, c);
    if (merge != null && (merge.top != r || merge.left != c)) {
      return pw.SizedBox();
    }
    final style = wb.styleAt(sheet.styleIdAt(r, c));
    final text = value == null
        ? ''
        : NumberFormatter.format(
            value,
            style.formatCode,
            date1904: wb.date1904,
          );
    final numeric = value is num;
    final align = switch (style.hAlign) {
      HAlign.left => pw.TextAlign.left,
      HAlign.center => pw.TextAlign.center,
      HAlign.right => pw.TextAlign.right,
      HAlign.general => numeric ? pw.TextAlign.right : pw.TextAlign.left,
    };
    return pw.Container(
      // Empty rows keep a normal row height, as in Excel.
      constraints: pw.BoxConstraints(minHeight: fontSize * 1.7),
      color: style.fill == null ? null : pdfColor(style.fill!),
      padding: pw.EdgeInsets.symmetric(
        horizontal: 2 * scale,
        vertical: 1.5 * scale,
      ),
      child: pw.Text(
        text,
        textAlign: align,
        softWrap: style.wrap,
        maxLines: style.wrap ? null : 1,
        overflow: style.wrap ? null : pw.TextOverflow.clip,
        style: pw.TextStyle(
          font: fonts.font(
            FontFamily.sans,
            bold: style.bold,
            italic: style.italic,
          ),
          fontFallback: fonts.fallback,
          fontSize: (style.fontSize ?? 11) / 11 * fontSize,
          color: style.color == null ? _ink : pdfColor(style.color!),
          decoration: style.underline ? pw.TextDecoration.underline : null,
        ),
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(pageFormat: format, theme: fonts.theme()),
      maxPages: 5000,
      header: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          sheet.name,
          style: pw.TextStyle(
            font: fonts.font(FontFamily.sans, bold: true),
            fontSize: 10,
            color: _muted,
          ),
        ),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber}',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ),
      build: (context) => [
        for (var g = 0; g < groups.length; g++) ...[
          if (g > 0) pw.NewPage(),
          pw.Table(
            border: pw.TableBorder.all(width: 0.4, color: _grid),
            columnWidths: {
              for (var k = 0; k < groups[g].length; k++)
                k: pw.FixedColumnWidth(widths[groups[g][k]] * scale),
            },
            tableWidth: pw.TableWidth.min,
            children: [
              for (var r = 0; r < rowLimit; r++)
                pw.TableRow(
                  repeat: r < headerRows,
                  children: [for (final c in groups[g]) cell(r, c)],
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

import 'dart:ui';

import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:docnook/features/tools/application/editor_marks.dart';
import 'package:docnook/features/tools/application/pdf_tools_service.dart';
import 'package:docnook/features/tools/application/signature_store.dart';
import 'package:docnook/features/tools/application/tool_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('page fractions', () {
    for (final rotation in [0, 1, 2, 3]) {
      test('round trip at rotation $rotation', () {
        final page = PdfPageInfo(600, 800, rotation);
        for (final f in const [
          Offset.zero,
          Offset(1, 1),
          Offset(0.25, 0.75),
          Offset(0.9, 0.1),
        ]) {
          final (x, y) = page.fromVisible(f.dx, f.dy);
          expect(x, inInclusiveRange(-1e-9, 600 + 1e-9));
          expect(y, inInclusiveRange(-1e-9, 800 + 1e-9));
          final (fx, fy) = page.toVisible(x, y);
          expect(fx, closeTo(f.dx, 1e-9));
          expect(fy, closeTo(f.dy, 1e-9));
        }
      });
    }

    test('top-left of the screen is the top-left of an upright page', () {
      const page = PdfPageInfo(600, 800, 0);
      expect(page.fromVisible(0, 0), (0.0, 800.0));
    });

    test('a page turned a quarter shows its bottom-left at top-left', () {
      // /Rotate 90: the stored page turns clockwise on screen.
      const page = PdfPageInfo(600, 800, 1);
      expect(page.visibleWidth, 800);
      expect(page.fromVisible(0, 0), (0.0, 0.0));
      expect(page.fromVisible(1, 0), (0.0, 800.0));
    });
  });

  test('marks convert to page space with the box origin', () {
    const info = PdfInfo(
      pages: [PdfPageInfo(600, 800, 0, x0: 10, y0: 20)],
      encrypted: false,
      hasForm: false,
    );
    final marks = toPdfMarks([
      const PenMark(0, 0x000000, 2, [
        [Offset.zero, Offset(0.5, 0.5)],
      ]),
      const MarkupMark(0, MarkupKind.highlight, 0xFFE066, [
        Rect.fromLTRB(0.1, 0.1, 0.2, 0.15),
      ]),
    ], info);
    final ink = marks[0] as InkMark;
    expect(ink.strokes.single, [10.0, 820.0, 310.0, 420.0]);
    final quads = (marks[1] as TextMarkup).quads;
    // Top-left, top-right, bottom-left, bottom-right.
    expect(quads.sublist(0, 2), [70.0, 740.0]);
    expect(quads.sublist(6, 8), [130.0, 700.0]);
  });

  test('text selection joins characters into one box per line', () {
    final chars = [
      for (var i = 0; i < 5; i++)
        Rect.fromLTWH(0.1 + i * 0.05, 0.1, 0.04, 0.02),
      for (var i = 0; i < 5; i++)
        Rect.fromLTWH(0.1 + i * 0.05, 0.2, 0.04, 0.02),
    ];
    final lines = selectTextLines(
      chars,
      const Offset(0.21, 0.11),
      const Offset(0.16, 0.21),
    );
    expect(lines, hasLength(2));
    expect(lines.first.left, closeTo(0.2, 1e-9));
    expect(lines.last.right, closeTo(0.19, 1e-9));
    expect(selectTextLines(const [], Offset.zero, Offset.zero), isEmpty);
  });

  test('signatures are normalised to their own box', () {
    final s = Signature.normalize('a', [
      [10, 10, 110, 60],
    ])!;
    expect(s.aspect, 2);
    expect(s.strokes.single, [0.0, 0.0, 1.0, 1.0]);
    expect(
      Signature.normalize('b', [
        [5, 5],
      ]),
      isNull,
    );
  });

  test('default names follow FR-CORE-03', () {
    final now = DateTime(2026, 11, 11, 14, 32);
    expect(
      PdfToolsService.defaultName(ToolId.merge, 'a.pdf', now),
      'Merged_2026-11-11_1432',
    );
    expect(
      PdfToolsService.defaultName(ToolId.compress, 'Report.pdf', now),
      'Report_compressed',
    );
  });

  test('dated names add the day once, also when chained', () {
    final now = DateTime(2026, 11, 14, 9, 5);
    final signed = PdfToolsService.defaultName(
      ToolId.sign,
      'Report.pdf',
      now,
      dated: true,
    );
    expect(signed, 'Report_signed_2026-11-14');
    expect(
      PdfToolsService.defaultName(
        ToolId.compress,
        '$signed.pdf',
        now,
        dated: true,
      ),
      'Report_compressed_2026-11-14',
    );
    expect(
      PdfToolsService.defaultName(ToolId.wordToPdf, 'Notes.docx', now),
      'Notes',
    );
  });
}

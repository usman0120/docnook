import 'package:docnook/app/theme/app_theme.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/engines/office/docx/docx_parser.dart';
import 'package:docnook/engines/office/parse_document.dart';
import 'package:docnook/engines/office/pptx/pptx_parser.dart';
import 'package:docnook/features/viewer/docmodel/docmodel_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lays out every block of each fixture at phone width, in both themes and
/// at 1× and 2× text, so layout errors surface on the computer first.
void main() {
  final docs = <String, DocModel Function()>{
    'docx': () => DocxParser.parseFile('test/fixtures/handbook_30p.docx'),
    'pptx': () => PptxParser.parseFile('test/fixtures/office/deck.pptx'),
    'odt': () => parseToDocModelSync('test/fixtures/office/minutes.odt'),
    'rtf': () => parseToDocModelSync('test/fixtures/office/letter.rtf'),
    'md': () => parseToDocModelSync('test/fixtures/office/readme.md'),
    'epub': () => parseToDocModelSync('test/fixtures/office/story.epub'),
    'xls': () => parseToDocModelSync('test/fixtures/office/legacy.xls'),
  };

  for (final entry in docs.entries) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${entry.key} renders (dark: $dark, text ×$scale)', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(720, 1600);
          tester.view.devicePixelRatio = 1.875;
          addTearDown(tester.view.reset);

          final doc = entry.value();
          final blocks = doc.blocks.toList();
          // Render a slice for large documents: enough to cover every block
          // kind without a very slow test.
          final shown = blocks.length > 120 ? blocks.sublist(0, 120) : blocks;

          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              home: Builder(
                builder: (context) {
                  final c = context.colors;
                  final style = DocRenderStyle(
                    ink: c.ink,
                    inkMuted: c.inkMuted,
                    page: c.surface,
                    hairline: c.hairline,
                    link: c.primary,
                    highlight: c.accent,
                    activeHighlight: c.accent,
                    textScale: scale,
                    baseFontSize: DocRenderStyle.detectBaseSize(doc),
                  );
                  return Scaffold(
                    body: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        for (final b in shown)
                          DocBlockView(block: b, doc: doc, style: style),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
          // Scroll through so every lazily built block is laid out.
          for (var i = 0; i < 40; i++) {
            await tester.drag(find.byType(ListView), const Offset(0, -1200));
            await tester.pump();
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}

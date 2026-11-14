import 'package:docnook/app/theme/app_theme.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/choice.dart';
import 'package:docnook/design_system/components/file_row.dart';
import 'package:docnook/design_system/components/layout.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/components/tab_bar.dart';
import 'package:docnook/design_system/components/tool_tile.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Accessibility pass for the design system (NFR-A11Y-01): every control has
/// a spoken label and a 48 dp touch target, text meets WCAG AA contrast, and
/// nothing overflows at 200% text, in both themes.
void main() {
  void noop() {}
  const icon = PhosphorIconsRegular.arrowLeft;

  final components = <String, Widget>{
    'buttons': Column(
      children: [
        PrimaryButton(label: 'Save copy', onPressed: noop, icon: icon),
        SecondaryButton(label: 'Share', onPressed: noop),
        QuietButton(label: 'Cancel', onPressed: noop),
        PrimaryButton(label: 'Delete', onPressed: noop, destructive: true),
        Row(
          children: [
            IconAction(icon: icon, label: 'Back', onPressed: noop),
            IconAction(
              icon: icon,
              label: 'Undo',
              onPressed: noop,
              selected: true,
            ),
          ],
        ),
      ],
    ),
    'choices': Column(
      children: [
        FilterChips<int>(
          values: const [0, 1, 2],
          selected: 1,
          label: (v) => 'Filter $v',
          onSelected: (_) {},
        ),
        SegmentedChoice<int>(
          values: const [0, 1],
          selected: 0,
          label: (v) => v == 0 ? 'List' : 'Grid',
          onSelected: (_) {},
        ),
      ],
    ),
    'file rows': Column(
      children: [
        FileRow(
          type: DocType.pdf,
          name: 'Annual report with a very long name that wraps.pdf',
          details: '2.4 MB · Yesterday',
          onTap: noop,
          onMore: noop,
          moreLabel: 'More options',
        ),
        FileRow(
          type: DocType.sheet,
          name: 'Budget.xlsx',
          details: 'Missing',
          onTap: noop,
          missing: true,
        ),
        SizedBox(
          width: 160,
          child: FileTile(
            type: DocType.word,
            name: 'Letter.docx',
            details: '18 KB',
            onTap: noop,
          ),
        ),
      ],
    ),
    'layout': Column(
      children: [
        const LargeTitle('Files'),
        SectionHeader('Recent', action: 'See all', onAction: noop),
        SearchField(hint: 'Search documents', onTap: noop),
      ],
    ),
    'tools': Column(
      children: [
        ToolTile(
          icon: icon,
          title: 'Merge PDF',
          description: 'Combine files into one PDF',
          onTap: noop,
        ),
        QuickAction(icon: icon, label: 'Scan', onTap: noop),
      ],
    ),
    'states': Column(
      children: [
        EmptyState(
          art: EmptyArt.openFolder,
          title: 'No documents yet',
          body: 'Open a file to see it here.',
          primaryLabel: 'Open file',
          onPrimary: noop,
        ),
        ErrorState(
          title: 'Can’t open this file',
          body: 'It may be damaged.',
          actionLabel: 'Try again',
          onAction: noop,
        ),
      ],
    ),
    'tab bar': DocNookTabBar(
      items: const [
        TabItem(icon: icon, activeIcon: icon, label: 'Home'),
        TabItem(icon: icon, activeIcon: icon, label: 'Files'),
        TabItem(icon: icon, activeIcon: icon, label: 'Tools'),
      ],
      currentIndex: 0,
      onSelect: (_) {},
    ),
  };

  for (final MapEntry(key: name, value: widget) in components.entries) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        final label = '$name, ${dark ? 'dark' : 'light'}, ${scale}x text';
        testWidgets(label, (tester) async {
          final semantics = tester.ensureSemantics();
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(360, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(body: SingleChildScrollView(child: widget)),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull, reason: 'overflow: $label');
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          if (scale == 1.0) {
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }
          semantics.dispose();
        });
      }
    }
  }
}

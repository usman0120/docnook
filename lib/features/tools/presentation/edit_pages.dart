import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/domain/pdf/pdf_edit_models.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Draws the editor layer for page [index], laid over the page at [size].
typedef PageOverlayBuilder =
    Widget Function(
      BuildContext context,
      int index,
      Size size,
      PdfDocument document,
    );

/// One page at a time, fitted to the screen, with an editing layer on top.
/// Swiping turns pages unless [swipe] is off (while a drawing tool is
/// active); [EditPageBar] turns them in every mode.
class EditPages extends StatefulWidget {
  const EditPages({
    required this.path,
    required this.password,
    required this.info,
    required this.controller,
    required this.overlay,
    this.swipe = true,
    this.onPageChanged,
    super.key,
  });

  final String path;
  final String? password;
  final PdfInfo info;
  final PageController controller;
  final PageOverlayBuilder overlay;
  final bool swipe;
  final ValueChanged<int>? onPageChanged;

  @override
  State<EditPages> createState() => _EditPagesState();
}

class _EditPagesState extends State<EditPages> {
  /// One reference for the screen's life: a new one on every rebuild would
  /// make pdfrx reload the document and cancel the gesture in progress.
  late final PdfDocumentRef _doc = PdfDocumentRefFile(
    widget.path,
    passwordProvider: widget.password == null ? null : () => widget.password,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final info = widget.info;
    return ColoredBox(
      color: c.surfaceSunken,
      child: PdfDocumentViewBuilder(
        documentRef: _doc,
        loadingBuilder: (_) => const LoadingState(),
        errorBuilder: (_, _, _) =>
            ErrorState(title: l.toolPickErrorTitle, body: l.errCorruptBody),
        builder: (context, document) {
          if (document == null) return const LoadingState();
          return PageView.builder(
            controller: widget.controller,
            physics: widget.swipe
                ? const PageScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            onPageChanged: widget.onPageChanged,
            itemCount: info.pageCount,
            itemBuilder: (context, i) {
              final page = info.pages[i];
              return LayoutBuilder(
                builder: (context, box) {
                  const pad = Space.x4;
                  final room = Size(
                    box.maxWidth - pad * 2,
                    box.maxHeight - pad * 2,
                  );
                  final aspect = page.visibleWidth / page.visibleHeight;
                  final size = room.width / room.height > aspect
                      ? Size(room.height * aspect, room.height)
                      : Size(room.width, room.width / aspect);
                  return Center(
                    child: Container(
                      width: size.width,
                      height: size.height,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        border: Border.all(color: c.hairline),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PdfPageView(
                            document: document,
                            pageNumber: i + 1,
                            maximumDpi: 200,
                            decoration: const BoxDecoration(),
                          ),
                          widget.overlay(context, i, size, document),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// "‹ 3 / 12 ›": turns pages when swiping is taken by a drawing tool.
class EditPageBar extends StatelessWidget {
  const EditPageBar({
    required this.controller,
    required this.page,
    required this.count,
    this.trailing,
    super.key,
  });

  final PageController controller;
  final int page;
  final int count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    void go(int to) => controller.animateToPage(
      to,
      duration: Motion.standard,
      curve: Motion.curve,
    );
    return Container(
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: Row(
        children: [
          IconAction(
            icon: PhosphorIconsRegular.caretLeft,
            label: l.toolPrevPage,
            onPressed: page > 0 ? () => go(page - 1) : null,
          ),
          Text(
            l.pageOf(page + 1, count),
            style: DocNookText.caption.copyWith(color: c.inkMuted),
          ),
          IconAction(
            icon: PhosphorIconsRegular.caretRight,
            label: l.toolNextPage,
            onPressed: page < count - 1 ? () => go(page + 1) : null,
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Converts between a page's on-screen box and fractions of the visible
/// page (top-left origin), the unit every editor stores marks in.
extension PageFractions on Size {
  Offset toFraction(Offset local) =>
      Offset(local.dx / width, local.dy / height);
  Offset fromFraction(Offset f) => Offset(f.dx * width, f.dy * height);
}

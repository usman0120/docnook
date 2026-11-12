import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';

/// Bottom sheet with DocNook's shape: 20 dp top corners, a grab handle and
/// an optional title. [expand] makes it draggable up to near full height.
Future<T?> showDocNookSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, ScrollController? scroll)
  builder,
  String? title,
  bool expand = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) {
    Widget header() => _SheetHeader(title: title);
    if (!expand) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header(),
            Flexible(child: builder(context, null)),
          ],
        ),
      );
    }
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(),
          Expanded(child: builder(context, scroll)),
        ],
      ),
    );
  },
);

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({this.title});
  final String? title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.x2),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.hairline,
              borderRadius: const BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.x4,
              Space.screen,
              Space.x2,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title!,
                style: DocNookText.sectionTitle.copyWith(color: c.ink),
              ),
            ),
          )
        else
          const SizedBox(height: Space.x2),
      ],
    );
  }
}

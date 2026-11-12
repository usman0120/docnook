import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';

/// Large serif title used only on Home, Files and Tools (BLUEPRINT 9.2),
/// with trailing actions on the same baseline.
class LargeTitle extends StatelessWidget {
  const LargeTitle(this.title, {this.actions = const [], super.key});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.x3,
        Space.x1,
        Space.x2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: DocNookText.screenTitle.copyWith(color: c.ink),
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Section header: title on the left, an optional quiet action on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.action, this.onAction, super.key});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.x6,
        Space.x2,
        Space.x2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: DocNookText.sectionTitle.copyWith(color: c.ink),
              ),
            ),
          ),
          if (action != null)
            Semantics(
              button: true,
              child: InkWell(
                onTap: onAction,
                borderRadius: Radii.chipAll,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: Sizes.touch),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.x2),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        action!,
                        style: DocNookText.label.copyWith(color: c.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-width 1 px divider, optionally inset to align with row text.
class Hairline extends StatelessWidget {
  const Hairline({this.indent = 0, super.key});
  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(start: indent),
    child: SizedBox(
      height: Sizes.hairline,
      child: ColoredBox(color: context.colors.hairline),
    ),
  );
}

/// Tappable search field that opens the search screen. Looks like a field,
/// behaves like a button, so the keyboard does not pop up on Home.
class SearchField extends StatelessWidget {
  const SearchField({
    required this.hint,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String hint;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.screen),
      child: Semantics(
        button: true,
        label: hint,
        excludeSemantics: true,
        child: Material(
          color: c.surfaceSunken,
          borderRadius: Radii.cardAll,
          child: InkWell(
            onTap: onTap,
            borderRadius: Radii.cardAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Sizes.touch),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: Sizes.iconSmall, color: c.inkMuted),
                      const SizedBox(width: Space.x2),
                    ],
                    Expanded(
                      child: Text(
                        hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DocNookText.body.copyWith(color: c.inkMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

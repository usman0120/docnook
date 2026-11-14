import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';

/// Horizontally scrolling single-choice chips (Files filters).
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.icon,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  /// Optional leading icon per chip (editor tool palettes).
  final IconData? Function(T)? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: Sizes.touch,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.screen),
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.x2),
        itemBuilder: (context, i) {
          final value = values[i];
          final active = value == selected;
          return Center(
            child: Semantics(
              button: true,
              selected: active,
              child: Material(
                color: active ? c.ink : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: Radii.chipAll,
                  side: BorderSide(color: active ? c.ink : c.hairline),
                ),
                child: InkWell(
                  onTap: () => onSelected(value),
                  borderRadius: Radii.chipAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.x3,
                      vertical: Space.x2 - 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon?.call(value) case final glyph?) ...[
                          Icon(
                            glyph,
                            size: Sizes.iconSmall,
                            color: active ? c.paper : c.ink,
                          ),
                          const SizedBox(width: Space.x1 + 2),
                        ],
                        Text(
                          label(value),
                          style: DocNookText.label.copyWith(
                            color: active ? c.paper : c.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Two to four equal segments, one selected (Documents | Collections |
/// Folders).
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.screen),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius:
              Radii.chipAll + const BorderRadius.all(Radius.circular(2)),
        ),
        child: Row(
          children: [
            for (final value in values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: value == selected,
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.fast),
                    decoration: BoxDecoration(
                      color: value == selected ? c.surface : Colors.transparent,
                      borderRadius: Radii.chipAll,
                      border: value == selected
                          ? Border.all(color: c.hairline)
                          : null,
                    ),
                    child: InkWell(
                      onTap: () => onSelected(value),
                      borderRadius: Radii.chipAll,
                      child: ConstrainedBox(
                        // Full 48 dp touch target (NFR-A11Y-01).
                        constraints: const BoxConstraints(
                          minHeight: Sizes.touch,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.x1,
                            ),
                            child: Text(
                              label(value),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DocNookText.label.copyWith(
                                color: value == selected ? c.ink : c.inkMuted,
                                fontWeight: value == selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

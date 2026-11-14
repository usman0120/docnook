import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';

/// One destination of [DocNookTabBar].
final class TabItem {
  const TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Bottom tabs: a hairline on top, plain icons and labels, and a short
/// accent marker above the active tab (BLUEPRINT 9.1). No pill, no shadow.
class DocNookTabBar extends StatelessWidget {
  const DocNookTabBar({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    super.key,
  });

  final List<TabItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _Tab(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});

  final TabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.ink : c.inkMuted;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Motion.of(context, Motion.fast),
                curve: Motion.curve,
                height: 2,
                width: active ? 24 : 0,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: Space.x2),
              Icon(
                active ? item.activeIcon : item.icon,
                size: Sizes.icon,
                color: color,
              ),
              const SizedBox(height: Space.x1),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DocNookText.caption.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: Space.x2),
            ],
          ),
        ),
      ),
    );
  }
}

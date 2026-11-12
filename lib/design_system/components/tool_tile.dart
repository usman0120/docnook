import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';

/// A tool in the Tools hub: icon, name, one-line description. Bordered by a
/// hairline because the grid groups related tools.
class ToolTile extends StatelessWidget {
  const ToolTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.tint,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  /// File-type colour of the tool's main input, as a small icon tint.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$title. $description',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardAll,
          side: BorderSide(color: c.hairline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.cardAll,
          child: Padding(
            padding: const EdgeInsets.all(Space.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: Sizes.icon, color: tint ?? c.primary),
                const SizedBox(height: Space.x3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DocNookText.label.copyWith(
                    color: c.ink,
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DocNookText.caption.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A Home quick action: compact, icon above label, four in a row.
class QuickAction extends StatelessWidget {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.cardAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x2),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: Radii.cardAll,
                  border: Border.all(color: c.hairline),
                ),
                child: Icon(icon, size: Sizes.icon, color: c.primary),
              ),
              const SizedBox(height: Space.x2),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: DocNookText.caption.copyWith(
                  color: c.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';

/// The one filled button per screen region: names the action it performs
/// ("Merge 3 files"), never "OK".
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expand = true,
    this.destructive = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Shows a spinner and ignores taps while work is starting.
  final bool busy;
  final bool expand;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final background = destructive ? c.danger : c.primary;
    final foreground = destructive
        ? (c.isDark ? c.paper : c.surface)
        : c.onPrimary;
    final enabled = onPressed != null && !busy;

    return Semantics(
      button: true,
      enabled: enabled,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: Sizes.buttonHeight,
          minWidth: expand ? double.infinity : Sizes.touch,
        ),
        child: Material(
          color: enabled || busy ? background : c.surfaceSunken,
          borderRadius: Radii.cardAll,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: Radii.cardAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.x6,
                vertical: Space.x3,
              ),
              child: _ButtonContent(
                label: label,
                icon: icon,
                busy: busy,
                color: enabled || busy ? foreground : c.inkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined companion to [PrimaryButton] for the second choice.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: Sizes.buttonHeight,
          minWidth: expand ? double.infinity : Sizes.touch,
        ),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: Radii.cardAll,
            side: BorderSide(color: c.hairline),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: Radii.cardAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.x6,
                vertical: Space.x3,
              ),
              child: _ButtonContent(
                label: label,
                icon: icon,
                busy: false,
                color: enabled ? c.ink : c.inkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text-only action for the least important choice ("Not now").
class QuietButton extends StatelessWidget {
  const QuietButton({
    required this.label,
    required this.onPressed,
    this.color,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: InkWell(
        onTap: onPressed,
        borderRadius: Radii.chipAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: Sizes.touch,
            minWidth: Sizes.touch,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x3),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: DocNookText.label.copyWith(
                  fontSize: 14,
                  color: onPressed == null ? c.inkMuted : (color ?? c.primary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A bare icon with a 48 dp touch target and a required spoken label.
class IconAction extends StatelessWidget {
  const IconAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.selected = false,
    super.key,
  });

  final IconData icon;

  /// Read by TalkBack and shown as a tooltip.
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        selected: selected,
        enabled: onPressed != null,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onPressed,
          radius: Sizes.touch / 2,
          child: SizedBox(
            width: Sizes.touch,
            height: Sizes.touch,
            child: Icon(
              icon,
              size: Sizes.icon,
              color: onPressed == null
                  ? c.inkMuted.withValues(alpha: 0.5)
                  : (color ?? c.ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.busy,
    required this.color,
  });

  final String label;
  final IconData? icon;
  final bool busy;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy) ...[
          SizedBox.square(
            dimension: Sizes.iconSmall,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          const SizedBox(width: Space.x2),
        ] else if (icon != null) ...[
          Icon(icon, size: Sizes.iconSmall, color: color),
          const SizedBox(width: Space.x2),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: DocNookText.label.copyWith(
              fontSize: 15,
              height: 20 / 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

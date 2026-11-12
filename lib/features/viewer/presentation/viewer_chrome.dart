import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Night viewers draw their chrome on near-black regardless of app theme.
const _nightBar = Color(0xF21A1A19);
const _nightInk = Color(0xFFECE9E2);
const _nightMuted = Color(0xFFA8A398);

/// ViewerToolbar (BLUEPRINT 10.5): Back, file name, actions. Slides away
/// when [visible] is false.
class ViewerTopBar extends StatelessWidget {
  const ViewerTopBar({
    required this.visible,
    required this.title,
    required this.actions,
    this.search,
    this.night = false,
    this.onTitleTap,
    super.key,
  });

  final bool visible;
  final String title;
  final List<Widget> actions;

  /// Replaces the title row while searching.
  final Widget? search;
  final bool night;
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final ink = night ? _nightInk : c.ink;
    return AnimatedPositioned(
      duration: Motion.of(context, Motion.fast),
      curve: Motion.curve,
      left: 0,
      right: 0,
      top: visible ? 0 : -(MediaQuery.paddingOf(context).top + 64),
      child: Material(
        color: night ? _nightBar : c.paper.withValues(alpha: 0.97),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: night ? Colors.white10 : c.hairline),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child:
                  search ??
                  Row(
                    children: [
                      const SizedBox(width: Space.x1),
                      IconAction(
                        icon: PhosphorIconsRegular.arrowLeft,
                        label: l.actionBack,
                        color: ink,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: onTitleTap,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DocNookText.bodyStrong.copyWith(color: ink),
                          ),
                        ),
                      ),
                      ...actions,
                      const SizedBox(width: Space.x1),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom bar of viewer tools: icon over a short label, evenly spaced.
class ViewerBottomBar extends StatelessWidget {
  const ViewerBottomBar({
    required this.visible,
    required this.items,
    this.night = false,
    super.key,
  });

  final bool visible;
  final List<(String, IconData, VoidCallback?)> items;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = night ? _nightInk : c.ink;
    final muted = night ? _nightMuted : c.inkMuted;
    return AnimatedPositioned(
      duration: Motion.of(context, Motion.fast),
      curve: Motion.curve,
      left: 0,
      right: 0,
      bottom: visible ? 0 : -(MediaQuery.paddingOf(context).bottom + 80),
      child: Material(
        color: night ? _nightBar : c.paper.withValues(alpha: 0.97),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: night ? Colors.white10 : c.hairline),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                for (final (label, icon, onTap) in items)
                  Expanded(
                    child: Semantics(
                      button: true,
                      enabled: onTap != null,
                      label: label,
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: onTap,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 60),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: Sizes.icon,
                                color: onTap == null ? muted : ink,
                              ),
                              const SizedBox(height: Space.x1),
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DocNookText.caption.copyWith(
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// In-document search: field, match count, previous/next, close.
class SearchBarContent extends StatelessWidget {
  const SearchBarContent({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onClose,
    this.status,
    this.onPrevious,
    this.onNext,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String? status;
  final ValueChanged<String> onChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Row(
      children: [
        const SizedBox(width: Space.x1),
        IconAction(
          icon: PhosphorIconsRegular.x,
          label: l.actionClose,
          onPressed: onClose,
        ),
        Expanded(
          child: _DebouncedField(
            controller: controller,
            focusNode: focusNode,
            hint: hint,
            onChanged: onChanged,
          ),
        ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x2),
            child: Semantics(
              liveRegion: true,
              child: Text(
                status!,
                style: DocNookText.caption.copyWith(color: c.inkMuted),
              ),
            ),
          ),
        IconAction(
          icon: PhosphorIconsRegular.caretUp,
          label: l.searchPrevious,
          onPressed: onPrevious,
        ),
        IconAction(
          icon: PhosphorIconsRegular.caretDown,
          label: l.searchNext,
          onPressed: onNext,
        ),
        const SizedBox(width: Space.x1),
      ],
    );
  }
}

/// Text field that reports changes after the user pauses typing (200 ms).
class _DebouncedField extends StatefulWidget {
  const _DebouncedField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_DebouncedField> createState() => _DebouncedFieldState();
}

class _DebouncedFieldState extends State<_DebouncedField> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      textInputAction: TextInputAction.search,
      style: DocNookText.body.copyWith(color: c.ink),
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
      ),
      onChanged: (text) {
        _timer?.cancel();
        _timer = Timer(
          const Duration(milliseconds: 200),
          () => widget.onChanged(text),
        );
      },
      onSubmitted: (text) {
        _timer?.cancel();
        widget.onChanged(text);
      },
    );
  }
}

/// Overflow menu for viewer actions.
class ViewerOverflowMenu extends StatelessWidget {
  const ViewerOverflowMenu({
    required this.items,
    this.night = false,
    super.key,
  });

  final List<(String, IconData, FutureOr<void> Function())> items;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return PopupMenuButton<int>(
      tooltip: l.actionMore,
      icon: Icon(
        PhosphorIconsRegular.dotsThreeVertical,
        size: Sizes.icon,
        color: night ? _nightInk : c.ink,
      ),
      position: PopupMenuPosition.under,
      onSelected: (i) => unawaited(Future.sync(items[i].$3)),
      itemBuilder: (context) => [
        for (var i = 0; i < items.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Icon(items[i].$2, size: Sizes.iconSmall, color: c.inkMuted),
                const SizedBox(width: Space.x3),
                Expanded(child: Text(items[i].$1)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Page indicator on the fast-scroll thumb: "12 / 48".
class PageThumbChip extends StatelessWidget {
  const PageThumbChip({required this.label, required this.visible, super.key});

  final String label;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedOpacity(
      duration: Motion.of(context, Motion.fast),
      opacity: visible ? 1 : 0.35,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.ink.withValues(alpha: 0.82),
          borderRadius: Radii.chipAll,
        ),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x1),
            child: Text(
              label,
              textScaler: TextScaler.noScaling,
              style: DocNookText.caption.copyWith(
                color: c.paper,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

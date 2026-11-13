import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';

/// Shared frame of every tool screen (S09 and the editors): back, title,
/// optional actions, the body and one primary button naming the action
/// ("Merge 3 files").
class ToolScaffold extends StatelessWidget {
  const ToolScaffold({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.actions = const [],
    this.subtitle,
    this.bottom,
    this.onBack,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final String actionLabel;
  final VoidCallback? onAction;
  final List<Widget> actions;

  /// Extra controls above the primary button (editor tool palettes).
  final Widget? bottom;

  /// Asked before leaving (unsaved edits); null pops straight away.
  final Future<bool> Function()? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Future<void> back() async {
      final leave = onBack == null || await onBack!();
      // pop, not maybePop: the PopScope below would block it again.
      if (leave && context.mounted) Navigator.of(context).pop();
    }

    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await back();
      },
      child: Scaffold(
        backgroundColor: c.paper,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: Space.x1),
                    IconAction(
                      icon: PhosphorIconsRegular.arrowLeft,
                      label: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () async {
                        if (onBack == null) {
                          Navigator.of(context).maybePop();
                        } else {
                          await back();
                        }
                      },
                    ),
                    const SizedBox(width: Space.x1),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DocNookText.bodyStrong,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DocNookText.caption.copyWith(
                                color: c.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...actions,
                    const SizedBox(width: Space.x1),
                  ],
                ),
              ),
              Expanded(child: body),
              ?bottom,
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.screen,
                  Space.x2,
                  Space.screen,
                  Space.x3,
                ),
                child: PrimaryButton(label: actionLabel, onPressed: onAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small muted label above a group of options.
class OptionLabel extends StatelessWidget {
  const OptionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Space.screen,
      Space.x6,
      Space.screen,
      Space.x2,
    ),
    child: Text(
      text,
      style: DocNookText.label.copyWith(color: context.colors.inkMuted),
    ),
  );
}

/// Horizontal screen padding for an option control.
class OptionPad extends StatelessWidget {
  const OptionPad(this.child, {super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.screen),
    child: child,
  );
}

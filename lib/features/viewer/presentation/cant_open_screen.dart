import 'package:docnook/app/formatters.dart';
import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/core/failures.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/components/states.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// S32: the shared "can't open this file" screen. Plain reason, then the
/// most useful next steps (BLUEPRINT principle 4).
class CantOpenScreen extends StatelessWidget {
  const CantOpenScreen({
    required this.failure,
    this.title,
    this.body,
    this.onOpenWith,
    this.onShare,
    this.onTryText,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  final DocNookFailure failure;

  /// Overrides the standard wording for this failure.
  final String? title;
  final String? body;
  final VoidCallback? onOpenWith;
  final VoidCallback? onShare;
  final VoidCallback? onTryText;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (defaultTitle, defaultBody) = l.failureText(failure);
    final secondary = <(String, VoidCallback)>[
      if (onTryText != null) (l.actionTryText, onTryText!),
      if (onShare != null) (l.actionShare, onShare!),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconAction(
          icon: PhosphorIconsRegular.arrowLeft,
          label: l.actionBack,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ErrorState(
                  title: title ?? defaultTitle,
                  body: body ?? defaultBody,
                  actionLabel: onRetry != null
                      ? retryLabel
                      : (onOpenWith != null ? l.actionOpenWith : null),
                  onAction: onRetry ?? onOpenWith,
                  secondaryLabel: onRetry != null && onOpenWith != null
                      ? l.actionOpenWith
                      : null,
                  onSecondary: onRetry != null ? onOpenWith : null,
                ),
                for (final (label, action) in secondary)
                  QuietButton(label: label, onPressed: action),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

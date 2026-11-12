import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/icons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';

/// Asks for a document password (FR-READ-02). Returns null when cancelled.
/// The password lives only in this dialog's field and the caller's memory;
/// it is never stored or logged.
Future<String?> askPassword(
  BuildContext context, {
  required bool wrongBefore,
}) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _PasswordDialog(wrongBefore: wrongBefore),
);

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.wrongBefore});
  final bool wrongBefore;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  var _obscure = true;

  @override
  void dispose() {
    _controller
      ..clear()
      ..dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.isEmpty) return;
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return AlertDialog(
      title: Text(l.passwordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.errPasswordBody,
            style: DocNookText.body.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: Space.x4),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l.passwordLabel,
              errorText: widget.wrongBefore ? l.passwordWrong : null,
              errorMaxLines: 3,
              suffixIcon: IconAction(
                icon: _obscure
                    ? PhosphorIconsRegular.eye
                    : PhosphorIconsRegular.eyeSlash,
                label: l.passwordLabel,
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        QuietButton(
          label: l.actionCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        QuietButton(label: l.passwordOpen, onPressed: _submit),
      ],
    );
  }
}

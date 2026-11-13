import 'dart:async';

import 'package:docnook/app/l10n/generated/app_localizations.dart';
import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:docnook/features/tools/application/signature_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// What the pad returns: the signature, and whether to keep it for later.
typedef DrawnSignature = ({Signature signature, bool keep});

/// Full-screen landscape draw pad (S14 "New signature"): Clear and Save.
class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final _strokes = <List<Offset>>[];
  var _keep = true;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations(const []));
    super.dispose();
  }

  void _save() {
    final signature = Signature.normalize(
      DateTime.now().microsecondsSinceEpoch.toString(),
      [
        for (final s in _strokes)
          [
            for (final o in s) ...[o.dx, o.dy],
          ],
      ],
    );
    if (signature == null) return;
    Navigator.of(
      context,
    ).pop<DrawnSignature>((signature: signature, keep: _keep));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: Space.x2),
                QuietButton(
                  label: l.actionCancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    l.signDrawTitle,
                    textAlign: TextAlign.center,
                    style: DocNookText.bodyStrong,
                  ),
                ),
                QuietButton(
                  label: l.actionClear,
                  onPressed: _strokes.isEmpty
                      ? null
                      : () => setState(_strokes.clear),
                ),
                QuietButton(
                  label: l.actionDone,
                  onPressed: _strokes.isEmpty ? null : _save,
                ),
                const SizedBox(width: Space.x2),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.screen),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: Radii.cardAll,
                    border: Border.all(color: c.hairline),
                  ),
                  child: ClipRRect(
                    borderRadius: Radii.cardAll,
                    child: Semantics(
                      label: l.signDrawArea,
                      child: GestureDetector(
                        onPanStart: (d) =>
                            setState(() => _strokes.add([d.localPosition])),
                        onPanUpdate: (d) =>
                            setState(() => _strokes.last.add(d.localPosition)),
                        child: CustomPaint(
                          painter: _InkPainter(_strokes),
                          child: Align(
                            alignment: const Alignment(0, 0.6),
                            child: FractionallySizedBox(
                              widthFactor: 0.7,
                              child: Container(
                                height: 1,
                                color: const Color(0x33000000),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            CheckboxListTile(
              value: _keep,
              onChanged: (v) => setState(() => _keep = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: Text(l.signKeep, style: DocNookText.body),
            ),
          ],
        ),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B1B1F)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, 1.5, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      canvas.drawPath(Path()..addPolygon(s, false), paint);
    }
  }

  @override
  bool shouldRepaint(_InkPainter old) => true;
}

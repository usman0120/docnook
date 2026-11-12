import 'package:docnook/design_system/components/buttons.dart';
import 'package:docnook/design_system/tokens.dart';
import 'package:docnook/design_system/typography.dart';
import 'package:flutter/material.dart';

/// The three in-house line drawings used by empty states (BLUEPRINT 9.5).
enum EmptyArt { paperStack, openFolder, scannerFrame }

/// Empty state: a quiet line drawing, one sentence, up to two actions.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.art,
    required this.title,
    this.body,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final EmptyArt art;
  final String title;
  final String? body;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x8,
        vertical: Space.x8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: CustomPaint(
              size: const Size(120, 96),
              painter: _ArtPainter(art, c.inkMuted, c.hairline),
            ),
          ),
          const SizedBox(height: Space.x6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DocNookText.sectionTitle.copyWith(color: c.ink),
          ),
          if (body != null) ...[
            const SizedBox(height: Space.x2),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: DocNookText.body.copyWith(color: c.inkMuted),
            ),
          ],
          if (primaryLabel != null) ...[
            const SizedBox(height: Space.x6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: PrimaryButton(label: primaryLabel!, onPressed: onPrimary),
            ),
          ],
          if (secondaryLabel != null) ...[
            const SizedBox(height: Space.x3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: SecondaryButton(
                label: secondaryLabel!,
                onPressed: onSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state: plain reason, one next step (BLUEPRINT principle 4).
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(Space.x8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: CustomPaint(
              size: const Size(120, 96),
              painter: _ArtPainter(
                EmptyArt.paperStack,
                c.inkMuted,
                c.hairline,
                torn: true,
              ),
            ),
          ),
          const SizedBox(height: Space.x6),
          Semantics(
            liveRegion: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: DocNookText.sectionTitle.copyWith(color: c.ink),
            ),
          ),
          const SizedBox(height: Space.x2),
          Text(
            body,
            textAlign: TextAlign.center,
            style: DocNookText.body.copyWith(color: c.inkMuted),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: Space.x6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: PrimaryButton(label: actionLabel!, onPressed: onAction),
            ),
          ],
          if (secondaryLabel != null) ...[
            const SizedBox(height: Space.x3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: SecondaryButton(
                label: secondaryLabel!,
                onPressed: onSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Centered spinner for loading states, with an optional caption.
class LoadingState extends StatelessWidget {
  const LoadingState({this.label, super.key});
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Semantics(
        label: label,
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: c.accent,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: Space.x4),
              Text(
                label!,
                style: DocNookText.caption.copyWith(color: c.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.art, this.ink, this.fill, {this.torn = false});

  final EmptyArt art;
  final Color ink;
  final Color fill;
  final bool torn;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final paper = Paint()..color = fill.withValues(alpha: 0.35);

    switch (art) {
      case EmptyArt.paperStack:
        _paperStack(canvas, size, line, paper);
      case EmptyArt.openFolder:
        _folder(canvas, size, line, paper);
      case EmptyArt.scannerFrame:
        _scanner(canvas, size, line);
    }
  }

  void _sheet(Canvas canvas, Rect rect, double angle, Paint line, Paint paper) {
    canvas
      ..save()
      ..translate(rect.center.dx, rect.center.dy)
      ..rotate(angle);
    final local = Rect.fromCenter(
      center: Offset.zero,
      width: rect.width,
      height: rect.height,
    );
    final r = RRect.fromRectAndRadius(local, const Radius.circular(3));
    canvas
      ..drawRRect(r, paper)
      ..drawRRect(r, line)
      ..restore();
  }

  void _paperStack(Canvas canvas, Size size, Paint line, Paint paper) {
    final w = size.width * 0.46;
    final h = size.height * 0.78;
    final center = Offset(size.width / 2, size.height / 2);
    _sheet(
      canvas,
      Rect.fromCenter(center: center.translate(-14, 4), width: w, height: h),
      -0.14,
      line,
      paper,
    );
    _sheet(
      canvas,
      Rect.fromCenter(center: center.translate(12, 2), width: w, height: h),
      0.10,
      line,
      paper,
    );
    final front = Rect.fromCenter(center: center, width: w, height: h);
    _sheet(canvas, front, 0, line, paper);

    // Text lines on the front sheet.
    final text = Paint()
      ..color = ink.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final left = front.left + 9;
    for (var i = 0; i < 5; i++) {
      final y = front.top + 14 + i * 9.0;
      final right = front.right - 9 - (i == 4 ? 14 : (i.isOdd ? 5 : 0));
      canvas.drawLine(Offset(left, y), Offset(right, y), text);
    }
    if (torn) {
      final path = Path()..moveTo(front.left + 6, front.bottom - 14);
      for (var i = 1; i <= 6; i++) {
        path.lineTo(
          front.left + 6 + i * (front.width - 12) / 6,
          front.bottom - (i.isOdd ? 9 : 14),
        );
      }
      canvas.drawPath(path, line);
    }
  }

  void _folder(Canvas canvas, Size size, Paint line, Paint paper) {
    final left = size.width * 0.16;
    final right = size.width * 0.84;
    final top = size.height * 0.22;
    final bottom = size.height * 0.84;
    final back = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top + 4)
      ..quadraticBezierTo(left, top, left + 4, top)
      ..lineTo(left + 26, top)
      ..lineTo(left + 32, top + 8)
      ..lineTo(right - 4, top + 8)
      ..quadraticBezierTo(right, top + 8, right, top + 12)
      ..lineTo(right, bottom);
    canvas
      ..drawPath(back, paper)
      ..drawPath(back, line);
    // A sheet peeking out.
    _sheet(
      canvas,
      Rect.fromLTRB(left + 14, top + 14, right - 14, bottom - 6),
      -0.04,
      line,
      paper,
    );
    final front = Path()
      ..moveTo(left - 4, top + 26)
      ..lineTo(right + 4, top + 26)
      ..lineTo(right, bottom)
      ..lineTo(left, bottom)
      ..close();
    canvas
      ..drawPath(front, paper)
      ..drawPath(front, line);
  }

  void _scanner(Canvas canvas, Size size, Paint line) {
    final rect = Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.06,
      size.width * 0.6,
      size.height * 0.88,
    );
    const corner = 14.0;
    for (final (origin, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(origin, origin.translate(corner * dx, 0), line)
        ..drawLine(origin, origin.translate(0, corner * dy), line);
    }
    final inner = rect.deflate(12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(2)),
      line,
    );
    final beam = Paint()
      ..color = ink.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    final y = inner.top + inner.height * 0.45;
    canvas.drawLine(Offset(rect.left + 4, y), Offset(rect.right - 4, y), beam);
  }

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.art != art || old.ink != ink || old.fill != fill || old.torn != torn;
}

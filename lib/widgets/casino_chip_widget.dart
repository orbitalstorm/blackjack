import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/blackjack_models.dart';

class CasinoChipButton extends StatelessWidget {
  const CasinoChipButton({
    super.key,
    required this.chip,
    required this.enabled,
    required this.onTap,
    this.size = 54,
  });

  final CasinoChip chip;
  final bool enabled;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1.0 : 0.38,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
              if (enabled)
                BoxShadow(
                  color: chip.primaryColor.withValues(alpha: 0.45),
                  blurRadius: 8,
                ),
            ],
          ),
          child: CustomPaint(
            painter: _CasinoChipPainter(chip: chip),
            child: Center(
              child: Text(
                '${chip.label}\$',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CasinoChipPainter extends CustomPainter {
  const _CasinoChipPainter({required this.chip});

  final CasinoChip chip;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    // Outer base
    final Paint basePaint = Paint()
      ..color = chip.primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, basePaint);

    // 8 Casino edge stripes
    final Paint stripePaint = Paint()
      ..color = chip.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.22
      ..strokeCap = StrokeCap.butt;

    final Rect stripeRect = Rect.fromCircle(
      center: center,
      radius: radius * 0.88,
    );
    for (int i = 0; i < 8; i++) {
      final double startAngle = (i * math.pi / 4) - 0.14;
      canvas.drawArc(stripeRect, startAngle, 0.28, false, stripePaint);
    }

    // Inner medallion circle
    final Paint innerFill = Paint()
      ..color = Color.lerp(chip.primaryColor, Colors.black, 0.28)!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.68, innerFill);

    // Gold inner ring
    final Paint goldRing = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.68, goldRing);
  }

  @override
  bool shouldRepaint(covariant _CasinoChipPainter oldDelegate) {
    return oldDelegate.chip != chip;
  }
}

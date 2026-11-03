import 'dart:math' as math;
import 'package:flutter/material.dart';

class CasinoFeltBackground extends StatelessWidget {
  const CasinoFeltBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.15),
          radius: 1.15,
          colors: <Color>[
            Color(0xFF0E4D31),
            Color(0xFF072E1C),
            Color(0xFF041A10),
          ],
          stops: <double>[0.0, 0.65, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: const _CasinoTableArcsPainter(),
        child: child,
      ),
    );
  }
}

class _CasinoTableArcsPainter extends CustomPainter {
  const _CasinoTableArcsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint goldArcPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final Paint subtleArcPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Rect outerArcRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, -size.height * 0.12),
      width: size.width * 1.45,
      height: size.height * 0.92,
    );

    final Rect innerArcRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, -size.height * 0.12),
      width: size.width * 1.30,
      height: size.height * 0.80,
    );

    canvas.drawArc(
      outerArcRect,
      math.pi * 0.15,
      math.pi * 0.70,
      false,
      goldArcPaint,
    );
    canvas.drawArc(
      innerArcRect,
      math.pi * 0.15,
      math.pi * 0.70,
      false,
      subtleArcPaint,
    );

    // Betting circle emblem in the lower-middle felt
    final Offset betCenter = Offset(size.width * 0.5, size.height * 0.54);
    canvas.drawCircle(
      betCenter,
      36,
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      betCenter,
      30,
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

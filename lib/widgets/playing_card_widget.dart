import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/blackjack_models.dart';

class CardSuitVector extends StatelessWidget {
  const CardSuitVector({
    super.key,
    required this.suit,
    required this.size,
    this.colorOverride,
  });

  final CardSuit suit;
  final double size;
  final Color? colorOverride;

  @override
  Widget build(BuildContext context) {
    final Color color = colorOverride ??
        (suit.isRed ? const Color(0xFFC81E32) : const Color(0xFF111827));
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SuitShapePainter(suit: suit, color: color),
      ),
    );
  }
}

class _SuitShapePainter extends CustomPainter {
  const _SuitShapePainter({
    required this.suit,
    required this.color,
  });

  final CardSuit suit;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;

    switch (suit) {
      case CardSuit.diamonds:
        final Path p = Path()
          ..moveTo(w * 0.50, h * 0.06)
          ..quadraticBezierTo(w * 0.62, h * 0.38, w * 0.90, h * 0.50)
          ..quadraticBezierTo(w * 0.62, h * 0.62, w * 0.50, h * 0.94)
          ..quadraticBezierTo(w * 0.38, h * 0.62, w * 0.10, h * 0.50)
          ..quadraticBezierTo(w * 0.38, h * 0.38, w * 0.50, h * 0.06)
          ..close();
        canvas.drawPath(p, paint);

      case CardSuit.hearts:
        final Path p = Path()
          ..moveTo(w * 0.50, h * 0.90)
          ..cubicTo(w * 0.12, h * 0.64, w * 0.04, h * 0.34, w * 0.27, h * 0.14)
          ..cubicTo(w * 0.40, h * 0.05, w * 0.50, h * 0.18, w * 0.50, h * 0.28)
          ..cubicTo(w * 0.50, h * 0.18, w * 0.60, h * 0.05, w * 0.73, h * 0.14)
          ..cubicTo(w * 0.96, h * 0.34, w * 0.88, h * 0.64, w * 0.50, h * 0.90)
          ..close();
        canvas.drawPath(p, paint);

      case CardSuit.spades:
        final Path head = Path()
          ..moveTo(w * 0.50, h * 0.06)
          ..cubicTo(w * 0.88, h * 0.34, w * 0.95, h * 0.64, w * 0.72, h * 0.74)
          ..cubicTo(w * 0.60, h * 0.78, w * 0.53, h * 0.70, w * 0.50, h * 0.64)
          ..cubicTo(w * 0.47, h * 0.70, w * 0.40, h * 0.78, w * 0.28, h * 0.74)
          ..cubicTo(w * 0.05, h * 0.64, w * 0.12, h * 0.34, w * 0.50, h * 0.06)
          ..close();
        canvas.drawPath(head, paint);

        final Path stem = Path()
          ..moveTo(w * 0.45, h * 0.62)
          ..lineTo(w * 0.55, h * 0.62)
          ..quadraticBezierTo(w * 0.58, h * 0.84, w * 0.70, h * 0.93)
          ..lineTo(w * 0.30, h * 0.93)
          ..quadraticBezierTo(w * 0.42, h * 0.84, w * 0.45, h * 0.62)
          ..close();
        canvas.drawPath(stem, paint);

      case CardSuit.clubs:
        final double r = w * 0.20;
        canvas.drawCircle(Offset(w * 0.50, h * 0.27), r, paint);
        canvas.drawCircle(Offset(w * 0.28, h * 0.54), r, paint);
        canvas.drawCircle(Offset(w * 0.72, h * 0.54), r, paint);
        canvas.drawCircle(Offset(w * 0.50, h * 0.48), r * 0.70, paint);

        final Path stem = Path()
          ..moveTo(w * 0.45, h * 0.54)
          ..lineTo(w * 0.55, h * 0.54)
          ..quadraticBezierTo(w * 0.58, h * 0.82, w * 0.70, h * 0.93)
          ..lineTo(w * 0.30, h * 0.93)
          ..quadraticBezierTo(w * 0.42, h * 0.82, w * 0.45, h * 0.54)
          ..close();
        canvas.drawPath(stem, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SuitShapePainter oldDelegate) {
    return oldDelegate.suit != suit || oldDelegate.color != color;
  }
}

class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget({
    super.key,
    required this.card,
    this.width = 76,
    this.height = 108,
    this.isHighlighted = false,
  });

  final PlayingCard card;
  final double width;
  final double height;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(width * 0.11);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.48),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
          if (isHighlighted)
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.55),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: card.faceUp
            ? _CardFrontView(
                card: card,
                width: width,
                height: height,
                isHighlighted: isHighlighted,
              )
            : _CardBackView(width: width, height: height),
      ),
    );
  }
}

class _CardFrontView extends StatelessWidget {
  const _CardFrontView({
    required this.card,
    required this.width,
    required this.height,
    required this.isHighlighted,
  });

  final PlayingCard card;
  final double width;
  final double height;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final Color inkColor =
        card.suit.isRed ? const Color(0xFFC81E32) : const Color(0xFF111827);
    final double rankFontSize = (width * 0.21).clamp(11.0, 19.0);
    final double cornerSuitSize = (width * 0.17).clamp(9.0, 15.0);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFDF9),
            Color(0xFFF5EFE2),
          ],
        ),
        borderRadius: BorderRadius.circular(width * 0.11),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFFFD700)
              : const Color(0xFFD6CFC0),
          width: isHighlighted ? 2.0 : 1.2,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _CardCenterArtworkPainter(
                card: card,
                inkColor: inkColor,
              ),
            ),
          ),
          Positioned(
            top: width * 0.06,
            left: width * 0.07,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  card.rank.symbol,
                  style: TextStyle(
                    color: inkColor,
                    fontSize: rankFontSize,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 1),
                CardSuitVector(
                  suit: card.suit,
                  size: cornerSuitSize,
                  colorOverride: inkColor,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: width * 0.06,
            right: width * 0.07,
            child: Transform.rotate(
              angle: math.pi,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    card.rank.symbol,
                    style: TextStyle(
                      color: inkColor,
                      fontSize: rankFontSize,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  CardSuitVector(
                    suit: card.suit,
                    size: cornerSuitSize,
                    colorOverride: inkColor,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: _buildCenterEmblem(inkColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterEmblem(Color inkColor) {
    if (card.rank.isFaceCard) {
      return Container(
        width: width * 0.54,
        height: height * 0.52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              const Color(0xFFD4AF37).withValues(alpha: 0.22),
              inkColor.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.75),
            width: 1.1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              card.rank == CardRank.king
                  ? Icons.workspace_premium
                  : card.rank == CardRank.queen
                      ? Icons.auto_awesome
                      : Icons.shield,
              size: width * 0.19,
              color: const Color(0xFFB4831E),
            ),
            Text(
              card.rank.symbol,
              style: TextStyle(
                color: inkColor,
                fontSize: width * 0.24,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 1),
            CardSuitVector(
              suit: card.suit,
              size: width * 0.16,
              colorOverride: inkColor,
            ),
          ],
        ),
      );
    }

    if (card.rank == CardRank.ace) {
      return Container(
        width: width * 0.52,
        height: width * 0.52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              const Color(0xFFD4AF37).withValues(alpha: 0.26),
              Colors.transparent,
            ],
          ),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: CardSuitVector(
          suit: card.suit,
          size: width * 0.34,
          colorOverride: inkColor,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CardSuitVector(
          suit: card.suit,
          size: width * 0.32,
          colorOverride: inkColor,
        ),
        const SizedBox(height: 2),
        Text(
          '${card.rank.blackjackValue}',
          style: TextStyle(
            color: inkColor.withValues(alpha: 0.55),
            fontSize: width * 0.13,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _CardCenterArtworkPainter extends CustomPainter {
  const _CardCenterArtworkPainter({
    required this.card,
    required this.inkColor,
  });

  final PlayingCard card;
  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint framePaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final Rect innerRect = Rect.fromLTWH(
      size.width * 0.16,
      size.height * 0.15,
      size.width * 0.68,
      size.height * 0.70,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(5)),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CardCenterArtworkPainter oldDelegate) {
    return oldDelegate.card != card || oldDelegate.inkColor != inkColor;
  }
}

class _CardBackView extends StatelessWidget {
  const _CardBackView({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF7F1D1D),
            Color(0xFF3B0A0A),
          ],
        ),
        borderRadius: BorderRadius.circular(width * 0.11),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 1.6,
        ),
      ),
      child: CustomPaint(
        painter: const _CardBackPainter(),
        child: Center(
          child: Container(
            width: width * 0.44,
            height: width * 0.44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1F0707),
              border: Border.all(
                color: const Color(0xFFD4AF37),
                width: 1.3,
              ),
            ),
            alignment: Alignment.center,
            child: CardSuitVector(
              suit: CardSuit.spades,
              size: width * 0.24,
              colorOverride: const Color(0xFFFFD700),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBackPainter extends CustomPainter {
  const _CardBackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint goldPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Rect inner = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(5)),
      goldPaint,
    );

    const double step = 10.0;
    for (double x = 6; x < size.width - 6; x += step) {
      for (double y = 6; y < size.height - 6; y += step) {
        final Path diamond = Path()
          ..moveTo(x, y - 3)
          ..lineTo(x + 3, y)
          ..lineTo(x, y + 3)
          ..lineTo(x - 3, y)
          ..close();
        canvas.drawPath(diamond, goldPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

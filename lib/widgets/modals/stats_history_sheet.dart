import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/blackjack_models.dart';

class StatsHistorySheet extends StatelessWidget {
  const StatsHistorySheet({
    super.key,
    required this.stats,
    required this.history,
    required this.bankroll,
    required this.runningCount,
    required this.trueCount,
    required this.remainingCards,
    required this.totalShoeCards,
    required this.onTopUpBankroll,
    required this.onResetStats,
  });

  final SessionStats stats;
  final List<RoundHistoryEntry> history;
  final int bankroll;
  final int runningCount;
  final double trueCount;
  final int remainingCards;
  final int totalShoeCards;
  final VoidCallback onTopUpBankroll;
  final VoidCallback onResetStats;

  @override
  Widget build(BuildContext context) {
    final Color profitColor = stats.netProfit >= 0
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final String profitPrefix = stats.netProfit >= 0 ? '+' : '';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.84,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1912),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'STATISTIQUES & JOURNAL DU SABOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        'Suivi de Bankroll, Comptage Hi-Lo & Historique des mains',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // KPI Grid
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _KpiCard(
                          label: 'BANKROLL',
                          value: '$bankroll \$',
                          sublabel: 'Bilan : $profitPrefix${stats.netProfit} \$',
                          accentColor: profitColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KpiCard(
                          label: 'TAUX VICTOIRE',
                          value: '${stats.winRate.toStringAsFixed(1)} %',
                          sublabel:
                              '${stats.handsWon}G • ${stats.handsLost}P • ${stats.handsPushed}N',
                          accentColor: const Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _KpiCard(
                          label: 'BLACKJACKS 3:2',
                          value: '${stats.blackjacks}',
                          sublabel: '${stats.roundsPlayed} donnes jouées',
                          accentColor: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KpiCard(
                          label: 'COMPTAGE HI-LO',
                          value:
                              'RC ${runningCount >= 0 ? '+$runningCount' : '$runningCount'} • TC ${trueCount >= 0 ? '+${trueCount.toStringAsFixed(1)}' : trueCount.toStringAsFixed(1)}',
                          sublabel:
                              'Sabot : $remainingCards / $totalShoeCards cartes',
                          accentColor: const Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Bankroll Evolution Chart
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F261B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text(
                              'ÉVOLUTION DE LA BANKROLL',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              'Plus gros gain : +${stats.biggestWin} \$',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 92,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _BankrollChartPainter(
                              values: stats.bankrollHistory,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            onTopUpBankroll();
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD700),
                            side: const BorderSide(color: Color(0xFFD4AF37)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.add_card, size: 16),
                          label: const Text(
                            'RECHARGER +1 000 \$',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            onResetStats();
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.restart_alt, size: 16),
                          label: const Text(
                            'RÉINITIALISER STATS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'HISTORIQUE DES DERNIÈRES MAINS',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (history.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Aucune main terminée dans cette session. Distribuez une main pour enregistrer vos résultats.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    )
                  else
                    ...history.map((RoundHistoryEntry item) {
                      final bool isPositive = item.netDelta > 0;
                      final bool isZero = item.netDelta == 0;
                      final Color deltaColor = isPositive
                          ? const Color(0xFF10B981)
                          : isZero
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFFEF4444);
                      final String deltaStr = isPositive
                          ? '+${item.netDelta} \$'
                          : '${item.netDelta} \$';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F261B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: deltaColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${item.roundNumber}',
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.headline,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Joueur: ${item.playerSummary}  •  Croupier: ${item.dealerSummary}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  deltaStr,
                                  style: TextStyle(
                                    color: deltaColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Solde: ${item.bankrollAfter} \$',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F261B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _BankrollChartPainter extends CustomPainter {
  const _BankrollChartPainter({required this.values});

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final int minVal = values.reduce(math.min);
    final int maxVal = values.reduce(math.max);
    final double range = math.max(100.0, (maxVal - minVal).toDouble());

    final Paint gridPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      gridPaint,
    );

    if (values.length == 1) {
      final Paint dotPaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        4,
        dotPaint,
      );
      return;
    }

    final Path linePath = Path();
    final Path fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final double x = (i / (values.length - 1)) * size.width;
      final double norm = (values[i] - minVal) / range;
      final double y = size.height - (norm * (size.height - 16)) - 8;

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF10B981).withValues(alpha: 0.35),
            const Color(0xFF10B981).withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _BankrollChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

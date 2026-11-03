import 'package:flutter/material.dart';

class StrategyRulesSheet extends StatelessWidget {
  const StrategyRulesSheet({
    super.key,
    required this.deckCount,
    required this.dealerHitsSoft17,
    required this.showCoach,
    required this.showCardCounter,
    required this.onDeckCountChanged,
    required this.onDealerRuleChanged,
    required this.onToggleCoach,
    required this.onToggleCardCounter,
    required this.onReshuffleNow,
  });

  final int deckCount;
  final bool dealerHitsSoft17;
  final bool showCoach;
  final bool showCardCounter;
  final ValueChanged<int> onDeckCountChanged;
  final ValueChanged<bool> onDealerRuleChanged;
  final ValueChanged<bool> onToggleCoach;
  final ValueChanged<bool> onToggleCardCounter;
  final VoidCallback onReshuffleNow;

  static const List<String> _dealerCols = <String>[
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'A',
  ];

  static const Map<String, List<String>> _hardMatrix = <String, List<String>>{
    '17+': <String>['R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R'],
    '16': <String>['R', 'R', 'R', 'R', 'R', 'T', 'T', 'A', 'A', 'A'],
    '15': <String>['R', 'R', 'R', 'R', 'R', 'T', 'T', 'T', 'A', 'T'],
    '13-14': <String>['R', 'R', 'R', 'R', 'R', 'T', 'T', 'T', 'T', 'T'],
    '12': <String>['T', 'T', 'R', 'R', 'R', 'T', 'T', 'T', 'T', 'T'],
    '11': <String>['D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D'],
    '10': <String>['D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'T', 'T'],
    '9': <String>['T', 'D', 'D', 'D', 'D', 'T', 'T', 'T', 'T', 'T'],
    '≤ 8': <String>['T', 'T', 'T', 'T', 'T', 'T', 'T', 'T', 'T', 'T'],
  };

  static const Map<String, List<String>> _softMatrix = <String, List<String>>{
    'A,9': <String>['R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R'],
    'A,8': <String>['R', 'R', 'R', 'R', 'D', 'R', 'R', 'R', 'R', 'R'],
    'A,7': <String>['D', 'D', 'D', 'D', 'D', 'R', 'R', 'T', 'T', 'T'],
    'A,6': <String>['T', 'D', 'D', 'D', 'D', 'T', 'T', 'T', 'T', 'T'],
    'A,4-5': <String>['T', 'T', 'D', 'D', 'D', 'T', 'T', 'T', 'T', 'T'],
    'A,2-3': <String>['T', 'T', 'T', 'D', 'D', 'T', 'T', 'T', 'T', 'T'],
  };

  static const Map<String, List<String>> _pairMatrix = <String, List<String>>{
    'A-A / 8-8': <String>['P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P'],
    '10-10': <String>['R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'R'],
    '9-9': <String>['P', 'P', 'P', 'P', 'P', 'R', 'P', 'P', 'R', 'R'],
    '7-7': <String>['P', 'P', 'P', 'P', 'P', 'P', 'T', 'T', 'T', 'T'],
    '6-6': <String>['P', 'P', 'P', 'P', 'P', 'T', 'T', 'T', 'T', 'T'],
    '2-2 / 3-3': <String>['P', 'P', 'P', 'P', 'P', 'P', 'T', 'T', 'T', 'T'],
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0A1912),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
        ),
        child: Material(
          color: Colors.transparent,
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
                  Icons.school_outlined,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'STRATÉGIE DE BASE & RÈGLES DU SABOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        'Table mathématique optimale, Side Bets & configuration Casino',
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
                  // Settings Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F261B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'CONFIGURATION DU SABOT & AIDES PRO',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text(
                              'Taille du Sabot (Decks)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: <int>[1, 2, 6, 8].map((int d) {
                                final bool selected = d == deckCount;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: InkWell(
                                    onTap: () => onDeckCountChanged(d),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFFD4AF37)
                                            : Colors.black26,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${d}P',
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.black
                                              : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSettingToggle(
                          title: 'Coach Stratégie de Base en Temps Réel',
                          subtitle:
                              'Affiche le meilleur coup mathématique face au croupier',
                          value: showCoach,
                          activeColor: const Color(0xFFFFD700),
                          onChanged: onToggleCoach,
                        ),
                        _buildSettingToggle(
                          title: 'Compteur de Cartes Hi-Lo (RC & True Count)',
                          subtitle: '+1 (2–6) • 0 (7–9) • -1 (10–As)',
                          value: showCardCounter,
                          activeColor: const Color(0xFF38BDF8),
                          onChanged: onToggleCardCounter,
                        ),
                        _buildSettingToggle(
                          title: 'Croupier tire sur 17 souple (H17)',
                          subtitle: dealerHitsSoft17
                              ? 'Mode H17 actif : le croupier tire sur As-6'
                              : 'Mode S17 actif : le croupier reste sur tous les 17',
                          value: dealerHitsSoft17,
                          activeColor: const Color(0xFFF59E0B),
                          onChanged: onDealerRuleChanged,
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              onReshuffleNow();
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFFD700),
                              side: const BorderSide(color: Color(0xFFD4AF37)),
                            ),
                            icon: const Icon(Icons.shuffle, size: 16),
                            label: const Text(
                              'REMÉLANGER LE SABOT MAINTENANT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Legend
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      _buildLegendBadge('T', 'Tirer', const Color(0xFF10B981)),
                      _buildLegendBadge('R', 'Rester', const Color(0xFFEF4444)),
                      _buildLegendBadge(
                        'D',
                        'Doubler ×2',
                        const Color(0xFFF59E0B),
                      ),
                      _buildLegendBadge(
                        'P',
                        'Séparer',
                        const Color(0xFF8B5CF6),
                      ),
                      _buildLegendBadge(
                        'A',
                        'Abandon',
                        const Color(0xFF64748B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMatrixSection('MAINS DURES (HARD TOTALS)', _hardMatrix),
                  const SizedBox(height: 14),
                  _buildMatrixSection(
                    'MAINS SOUPLES AVEC AS (SOFT TOTALS)',
                    _softMatrix,
                  ),
                  const SizedBox(height: 14),
                  _buildMatrixSection('PAIRES (SPLIT)', _pairMatrix),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildSettingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBadge(String code, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        '$code : $label',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildMatrixSection(String title, Map<String, List<String>> rows) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F261B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const SizedBox(
                width: 58,
                child: Text(
                  'Main \\ Cr.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ..._dealerCols.map(
                (String c) => Expanded(
                  child: Center(
                    child: Text(
                      c,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...rows.entries.map((MapEntry<String, List<String>> entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 58,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...entry.value.map((String code) {
                    final Color cellColor = _colorForCode(code);
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: cellColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: cellColor.withValues(alpha: 0.6),
                            width: 0.7,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _colorForCode(String code) {
    switch (code) {
      case 'T':
        return const Color(0xFF10B981);
      case 'R':
        return const Color(0xFFEF4444);
      case 'D':
        return const Color(0xFFF59E0B);
      case 'P':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }
}

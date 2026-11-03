import 'package:flutter/material.dart';

enum CardSuit {
  spades('♠', 'Pique', false),
  hearts('♥', 'Cœur', true),
  diamonds('♦', 'Carreau', true),
  clubs('♣', 'Trèfle', false);

  const CardSuit(this.symbol, this.frenchName, this.isRed);
  final String symbol;
  final String frenchName;
  final bool isRed;
}

enum CardRank {
  ace('A', 'As', 11, -1, 14),
  two('2', 'Deux', 2, 1, 2),
  three('3', 'Trois', 3, 1, 3),
  four('4', 'Quatre', 4, 1, 4),
  five('5', 'Cinq', 5, 1, 5),
  six('6', 'Six', 6, 1, 6),
  seven('7', 'Sept', 7, 0, 7),
  eight('8', 'Huit', 8, 0, 8),
  nine('9', 'Neuf', 9, 0, 9),
  ten('10', 'Dix', 10, -1, 10),
  jack('J', 'Valet', 10, -1, 11),
  queen('Q', 'Dame', 10, -1, 12),
  king('K', 'Roi', 10, -1, 13);

  const CardRank(
    this.symbol,
    this.frenchName,
    this.blackjackValue,
    this.hiLoValue,
    this.pokerOrder,
  );

  final String symbol;
  final String frenchName;
  final int blackjackValue;
  final int hiLoValue;
  final int pokerOrder;

  bool get isTenValue => blackjackValue == 10;
  bool get isFaceCard =>
      this == CardRank.jack || this == CardRank.queen || this == CardRank.king;
}

@immutable
class PlayingCard {
  const PlayingCard({
    required this.id,
    required this.suit,
    required this.rank,
    this.faceUp = true,
  });

  final String id;
  final CardSuit suit;
  final CardRank rank;
  final bool faceUp;

  PlayingCard copyWith({bool? faceUp}) {
    return PlayingCard(
      id: id,
      suit: suit,
      rank: rank,
      faceUp: faceUp ?? this.faceUp,
    );
  }

  String get shortLabel => '${rank.symbol}${suit.symbol}';
}

@immutable
class HandEvaluation {
  const HandEvaluation({
    required this.hardTotal,
    required this.bestTotal,
    required this.isSoft,
    required this.isBlackjack,
    required this.isBusted,
    required this.isSplittable,
  });

  final int hardTotal;
  final int bestTotal;
  final bool isSoft;
  final bool isBlackjack;
  final bool isBusted;
  final bool isSplittable;

  factory HandEvaluation.fromCards(
    List<PlayingCard> cards, {
    bool isSplitHand = false,
    bool onlyFaceUp = false,
  }) {
    final List<PlayingCard> relevant =
        onlyFaceUp ? cards.where((PlayingCard c) => c.faceUp).toList() : cards;

    int total = 0;
    int aces = 0;

    for (final PlayingCard card in relevant) {
      if (card.rank == CardRank.ace) {
        aces += 1;
        total += 11;
      } else {
        total += card.rank.blackjackValue;
      }
    }

    int softAces = aces;
    while (total > 21 && softAces > 0) {
      total -= 10;
      softAces -= 1;
    }

    final int hardTotal = relevant.fold<int>(
      0,
      (int sum, PlayingCard c) =>
          sum + (c.rank == CardRank.ace ? 1 : c.rank.blackjackValue),
    );

    final bool isSoft = softAces > 0 && total <= 21;
    final bool isBlackjack =
        !onlyFaceUp && !isSplitHand && relevant.length == 2 && total == 21;
    final bool isBusted = total > 21;
    final bool isSplittable = !onlyFaceUp &&
        relevant.length == 2 &&
        relevant[0].rank.blackjackValue == relevant[1].rank.blackjackValue;

    return HandEvaluation(
      hardTotal: hardTotal,
      bestTotal: total,
      isSoft: isSoft,
      isBlackjack: isBlackjack,
      isBusted: isBusted,
      isSplittable: isSplittable,
    );
  }

  String get badgeLabel {
    if (bestTotal == 0) {
      return '0';
    }
    if (isBlackjack) {
      return 'BLACKJACK 21';
    }
    if (isBusted) {
      return 'BUST $bestTotal';
    }
    if (isSoft && hardTotal != bestTotal && bestTotal < 21) {
      return '$hardTotal / $bestTotal';
    }
    return '$bestTotal';
  }
}

enum HandOutcome {
  pending('EN COURS', Color(0xFFD4AF37)),
  blackjack('BLACKJACK 3:2', Color(0xFFFFD700)),
  win('GAGNÉ', Color(0xFF10B981)),
  push('ÉGALITÉ (PUSH)', Color(0xFF38BDF8)),
  surrender('ABANDON (½ MISE)', Color(0xFFF59E0B)),
  lose('PERDU', Color(0xFFEF4444)),
  bust('DÉPASSÉ (BUST)', Color(0xFFEF4444));

  const HandOutcome(this.label, this.color);
  final String label;
  final Color color;
}

@immutable
class PlayerHand {
  const PlayerHand({
    required this.cards,
    required this.bet,
    this.isDoubled = false,
    this.isSplitHand = false,
    this.isStood = false,
    this.isSurrendered = false,
    this.outcome = HandOutcome.pending,
    this.payout = 0,
  });

  final List<PlayingCard> cards;
  final int bet;
  final bool isDoubled;
  final bool isSplitHand;
  final bool isStood;
  final bool isSurrendered;
  final HandOutcome outcome;
  final int payout;

  HandEvaluation get evaluation =>
      HandEvaluation.fromCards(cards, isSplitHand: isSplitHand);

  bool get isFinished =>
      isStood ||
      isSurrendered ||
      evaluation.isBusted ||
      evaluation.isBlackjack ||
      outcome != HandOutcome.pending;

  int get netProfit => payout - bet;

  PlayerHand copyWith({
    List<PlayingCard>? cards,
    int? bet,
    bool? isDoubled,
    bool? isSplitHand,
    bool? isStood,
    bool? isSurrendered,
    HandOutcome? outcome,
    int? payout,
  }) {
    return PlayerHand(
      cards: cards ?? this.cards,
      bet: bet ?? this.bet,
      isDoubled: isDoubled ?? this.isDoubled,
      isSplitHand: isSplitHand ?? this.isSplitHand,
      isStood: isStood ?? this.isStood,
      isSurrendered: isSurrendered ?? this.isSurrendered,
      outcome: outcome ?? this.outcome,
      payout: payout ?? this.payout,
    );
  }
}

@immutable
class SideBetEvaluation {
  const SideBetEvaluation({
    this.perfectPairsBet = 0,
    this.perfectPairsTitle,
    this.perfectPairsMultiplier = 0,
    this.perfectPairsPayout = 0,
    this.twentyOnePlusThreeBet = 0,
    this.twentyOnePlusThreeTitle,
    this.twentyOnePlusThreeMultiplier = 0,
    this.twentyOnePlusThreePayout = 0,
  });

  final int perfectPairsBet;
  final String? perfectPairsTitle;
  final int perfectPairsMultiplier;
  final int perfectPairsPayout;

  final int twentyOnePlusThreeBet;
  final String? twentyOnePlusThreeTitle;
  final int twentyOnePlusThreeMultiplier;
  final int twentyOnePlusThreePayout;

  int get totalBet => perfectPairsBet + twentyOnePlusThreeBet;
  int get totalPayout => perfectPairsPayout + twentyOnePlusThreePayout;
  int get netProfit => totalPayout - totalBet;
  bool get hasAnyBet => totalBet > 0;
  bool get hasAnyWin => totalPayout > 0;
}

enum GamePhase {
  betting,
  insuranceOffer,
  playerTurn,
  dealerTurn,
  roundOver,
}

@immutable
class RoundHistoryEntry {
  const RoundHistoryEntry({
    required this.roundNumber,
    required this.playerSummary,
    required this.dealerSummary,
    required this.netDelta,
    required this.bankrollAfter,
    required this.headline,
  });

  final int roundNumber;
  final String playerSummary;
  final String dealerSummary;
  final int netDelta;
  final int bankrollAfter;
  final String headline;
}

@immutable
class SessionStats {
  const SessionStats({
    this.roundsPlayed = 0,
    this.handsWon = 0,
    this.handsLost = 0,
    this.handsPushed = 0,
    this.blackjacks = 0,
    this.biggestWin = 0,
    this.netProfit = 0,
    this.bankrollHistory = const <int>[2500],
  });

  final int roundsPlayed;
  final int handsWon;
  final int handsLost;
  final int handsPushed;
  final int blackjacks;
  final int biggestWin;
  final int netProfit;
  final List<int> bankrollHistory;

  double get winRate {
    final int decided = handsWon + handsLost;
    if (decided == 0) {
      return 0.0;
    }
    return (handsWon / decided) * 100.0;
  }

  SessionStats copyWith({
    int? roundsPlayed,
    int? handsWon,
    int? handsLost,
    int? handsPushed,
    int? blackjacks,
    int? biggestWin,
    int? netProfit,
    List<int>? bankrollHistory,
  }) {
    return SessionStats(
      roundsPlayed: roundsPlayed ?? this.roundsPlayed,
      handsWon: handsWon ?? this.handsWon,
      handsLost: handsLost ?? this.handsLost,
      handsPushed: handsPushed ?? this.handsPushed,
      blackjacks: blackjacks ?? this.blackjacks,
      biggestWin: biggestWin ?? this.biggestWin,
      netProfit: netProfit ?? this.netProfit,
      bankrollHistory: bankrollHistory ?? this.bankrollHistory,
    );
  }
}

@immutable
class CasinoChip {
  const CasinoChip({
    required this.value,
    required this.label,
    required this.primaryColor,
    required this.accentColor,
  });

  final int value;
  final String label;
  final Color primaryColor;
  final Color accentColor;

  static const List<CasinoChip> standardChips = <CasinoChip>[
    CasinoChip(
      value: 5,
      label: '5',
      primaryColor: Color(0xFFC81E32),
      accentColor: Color(0xFFFEE2E2),
    ),
    CasinoChip(
      value: 25,
      label: '25',
      primaryColor: Color(0xFF0F764A),
      accentColor: Color(0xFFD1FAE5),
    ),
    CasinoChip(
      value: 100,
      label: '100',
      primaryColor: Color(0xFF1E293B),
      accentColor: Color(0xFFFDE68A),
    ),
    CasinoChip(
      value: 500,
      label: '500',
      primaryColor: Color(0xFF6D28D9),
      accentColor: Color(0xFFEDE9FE),
    ),
    CasinoChip(
      value: 1000,
      label: '1K',
      primaryColor: Color(0xFFB45309),
      accentColor: Color(0xFFFEF3C7),
    ),
  ];
}

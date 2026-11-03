import 'package:flutter/material.dart';
import '../models/blackjack_models.dart';

enum StrategyAction {
  hit('TIRER (HIT)', 'T', Color(0xFF10B981)),
  stand('RESTER (STAND)', 'R', Color(0xFFEF4444)),
  doubleDown('DOUBLER (×2)', 'D', Color(0xFFF59E0B)),
  split('SÉPARER (SPLIT)', 'P', Color(0xFF8B5CF6)),
  surrender('ABANDON (SURRENDER)', 'A', Color(0xFF64748B));

  const StrategyAction(this.label, this.shortCode, this.badgeColor);
  final String label;
  final String shortCode;
  final Color badgeColor;
}

@immutable
class StrategyAdvice {
  const StrategyAdvice({
    required this.action,
    required this.headline,
    required this.rationale,
  });

  final StrategyAction action;
  final String headline;
  final String rationale;
}

class StrategyCoach {
  const StrategyCoach._();

  static StrategyAdvice recommend({
    required PlayerHand hand,
    required PlayingCard? dealerUpCard,
    required bool canDouble,
    required bool canSplit,
    required bool canSurrender,
  }) {
    if (dealerUpCard == null || hand.cards.isEmpty) {
      return const StrategyAdvice(
        action: StrategyAction.stand,
        headline: 'Placez votre mise pour démarrer',
        rationale:
            'Sélectionnez vos jetons et appuyez sur DISTRIBUER pour lancer la main.',
      );
    }

    final HandEvaluation eval = hand.evaluation;
    final int dealerVal = dealerUpCard.rank.blackjackValue;
    final String dealerSymbol = dealerUpCard.rank.symbol;

    if (eval.isBlackjack) {
      return const StrategyAdvice(
        action: StrategyAction.stand,
        headline: 'BLACKJACK NATUREL (21) — Paiement 3:2',
        rationale: 'Main maximale dès la distribution.',
      );
    }

    // 1. Pair splitting rules
    if (canSplit && hand.cards.length == 2 && eval.isSplittable) {
      final int pairVal = hand.cards.first.rank.blackjackValue;
      final bool isAcePair = hand.cards.first.rank == CardRank.ace;

      if (isAcePair || pairVal == 8) {
        return StrategyAdvice(
          action: StrategyAction.split,
          headline:
              'Conseil Pro : SÉPARER (${hand.cards[0].rank.symbol}-${hand.cards[1].rank.symbol} vs $dealerSymbol)',
          rationale: isAcePair
              ? 'Toujours séparer une paire d’As pour chercher deux Blackjacks/21.'
              : 'Toujours séparer 8-8 (16 dur est la pire main, deux 8 offrent un bien meilleur potentiel).',
        );
      }

      if (pairVal == 9 &&
          dealerVal != 7 &&
          dealerVal != 10 &&
          dealerVal != 11) {
        return StrategyAdvice(
          action: StrategyAction.split,
          headline: 'Conseil Pro : SÉPARER 9-9 vs $dealerSymbol',
          rationale:
              'Séparez 9-9 contre 2–6 et 8–9 pour maximiser l’espérance de gain.',
        );
      }

      if ((pairVal == 2 || pairVal == 3 || pairVal == 7) && dealerVal <= 7) {
        return StrategyAdvice(
          action: StrategyAction.split,
          headline:
              'Conseil Pro : SÉPARER $pairVal-$pairVal vs $dealerSymbol',
          rationale:
              'Le croupier montre une carte faible ($dealerSymbol) : profitez-en pour jouer deux mains.',
        );
      }

      if (pairVal == 6 && dealerVal >= 2 && dealerVal <= 6) {
        return StrategyAdvice(
          action: StrategyAction.split,
          headline: 'Conseil Pro : SÉPARER 6-6 vs $dealerSymbol',
          rationale:
              'Face à un croupier vulnérable (2–6), séparer 6-6 évite un 12 rigide.',
        );
      }

      if (pairVal == 4 && (dealerVal == 5 || dealerVal == 6)) {
        return StrategyAdvice(
          action: StrategyAction.split,
          headline: 'Conseil Pro : SÉPARER 4-4 vs $dealerSymbol',
          rationale:
              'Face au 5 ou 6 du croupier, séparer 4-4 surpasse le simple tirage.',
        );
      }
    }

    // 2. Soft totals (hand with an Ace counted as 11)
    if (eval.isSoft) {
      final int total = eval.bestTotal;
      if (total >= 19) {
        if (total == 19 && dealerVal == 6 && canDouble) {
          return StrategyAdvice(
            action: StrategyAction.doubleDown,
            headline: 'Conseil Pro : DOUBLER Soft 19 (A-8) vs 6',
            rationale:
                'Le 6 est la carte la plus vulnérable du croupier : doublez sinon restez.',
          );
        }
        return StrategyAdvice(
          action: StrategyAction.stand,
          headline: 'Conseil Pro : RESTER sur Soft $total vs $dealerSymbol',
          rationale:
              'Un total souple de $total est déjà une main très forte.',
        );
      }

      if (total == 18) {
        if (dealerVal >= 2 && dealerVal <= 6 && canDouble) {
          return StrategyAdvice(
            action: StrategyAction.doubleDown,
            headline: 'Conseil Pro : DOUBLER Soft 18 (A-7) vs $dealerSymbol',
            rationale:
                'Doublez A-7 face à une carte basse du croupier (2–6) pour maximiser le profit.',
          );
        }
        if (dealerVal <= 8) {
          return StrategyAdvice(
            action: StrategyAction.stand,
            headline: 'Conseil Pro : RESTER sur Soft 18 vs $dealerSymbol',
            rationale: '18 suffit face à $dealerSymbol.',
          );
        }
        return StrategyAdvice(
          action: StrategyAction.hit,
          headline: 'Conseil Pro : TIRER sur Soft 18 vs $dealerSymbol',
          rationale:
              'Face à 9, 10 ou As, 18 est dominé : utilisez la souplesse de l’As pour améliorer.',
        );
      }

      if (total == 17 && dealerVal >= 3 && dealerVal <= 6 && canDouble) {
        return StrategyAdvice(
          action: StrategyAction.doubleDown,
          headline: 'Conseil Pro : DOUBLER Soft 17 (A-6) vs $dealerSymbol',
          rationale:
              'Soft 17 ne peut pas dépasser 21 en une carte et attaque un croupier faible (3–6).',
        );
      }

      if ((total == 15 || total == 16) &&
          dealerVal >= 4 &&
          dealerVal <= 6 &&
          canDouble) {
        return StrategyAdvice(
          action: StrategyAction.doubleDown,
          headline: 'Conseil Pro : DOUBLER Soft $total vs $dealerSymbol',
          rationale:
              'Misez double contre un croupier exposé (4–6) avec un As protecteur.',
        );
      }

      if ((total == 13 || total == 14) &&
          (dealerVal == 5 || dealerVal == 6) &&
          canDouble) {
        return StrategyAdvice(
          action: StrategyAction.doubleDown,
          headline: 'Conseil Pro : DOUBLER Soft $total vs $dealerSymbol',
          rationale:
              'Face à 5 ou 6, doubler un petit As souple est mathématiquement optimal.',
        );
      }

      return StrategyAdvice(
        action: StrategyAction.hit,
        headline: 'Conseil Pro : TIRER sur Soft $total vs $dealerSymbol',
        rationale:
            'Aucun risque de dépasser 21 (Bust) en tirant sur une main souple ≤ 17.',
      );
    }

    // 3. Hard totals
    final int total = eval.bestTotal;

    if (canSurrender && hand.cards.length == 2) {
      if (total == 16 &&
          (dealerVal == 9 || dealerVal == 10 || dealerVal == 11)) {
        return StrategyAdvice(
          action: StrategyAction.surrender,
          headline: 'Conseil Pro : ABANDON (16 dur vs $dealerSymbol)',
          rationale:
              'Récupérer 50% de la mise sur 16 contre 9/10/As économise sur le long terme.',
        );
      }
      if (total == 15 && dealerVal == 10) {
        return StrategyAdvice(
          action: StrategyAction.surrender,
          headline: 'Conseil Pro : ABANDON (15 dur vs 10)',
          rationale:
              'Face à une bûche (10), abandonner 15 réduit la perte mathématique.',
        );
      }
    }

    if (total >= 17) {
      return StrategyAdvice(
        action: StrategyAction.stand,
        headline: 'Conseil Pro : RESTER sur $total dur vs $dealerSymbol',
        rationale:
            'Risque de Bust trop élevé (${((total - 8) / 13 * 100).clamp(50, 92).toStringAsFixed(0)}%) en tirant au-delà de 17.',
      );
    }

    if (total >= 13 && total <= 16) {
      if (dealerVal >= 2 && dealerVal <= 6) {
        return StrategyAdvice(
          action: StrategyAction.stand,
          headline: 'Conseil Pro : RESTER ($total vs $dealerSymbol)',
          rationale:
              'Le croupier a une forte probabilité de dépasser 21 avec $dealerSymbol (35%–42%).',
        );
      }
      return StrategyAdvice(
        action: StrategyAction.hit,
        headline: 'Conseil Pro : TIRER ($total vs $dealerSymbol)',
        rationale:
            'Face à une carte haute ($dealerSymbol), le croupier atteindra souvent 17–21.',
      );
    }

    if (total == 12) {
      if (dealerVal >= 4 && dealerVal <= 6) {
        return StrategyAdvice(
          action: StrategyAction.stand,
          headline: 'Conseil Pro : RESTER (12 vs $dealerSymbol)',
          rationale:
              'Contre 4, 5 ou 6, laissez le croupier risquer de sauter.',
        );
      }
      return StrategyAdvice(
        action: StrategyAction.hit,
        headline: 'Conseil Pro : TIRER (12 vs $dealerSymbol)',
        rationale:
            'Seules les cartes de valeur 10 font sauter 12 (4/13) : tirez contre $dealerSymbol.',
      );
    }

    if (total == 11) {
      if (canDouble) {
        return StrategyAdvice(
          action: StrategyAction.doubleDown,
          headline: 'Conseil Pro : DOUBLER sur 11 vs $dealerSymbol',
          rationale:
              '11 est le meilleur tremplin du Blackjack pour toucher 20 ou 21 en une carte.',
        );
      }
      return StrategyAdvice(
        action: StrategyAction.hit,
        headline: 'Conseil Pro : TIRER sur 11 vs $dealerSymbol',
        rationale: 'Impossible de sauter sur 11 : tirez pour viser 21.',
      );
    }

    if (total == 10) {
      if (canDouble && dealerVal <= 9) {
        return StrategyAdvice(
          action: StrategyAction.doubleDown,
          headline: 'Conseil Pro : DOUBLER sur 10 vs $dealerSymbol',
          rationale:
              'Fort avantage offensif sur 10 face à une carte du croupier ≤ 9.',
        );
      }
      return StrategyAdvice(
        action: StrategyAction.hit,
        headline: 'Conseil Pro : TIRER sur 10 vs $dealerSymbol',
        rationale: 'Tirez sans aucun risque de dépasser 21.',
      );
    }

    if (total == 9 && canDouble && dealerVal >= 3 && dealerVal <= 6) {
      return StrategyAdvice(
        action: StrategyAction.doubleDown,
        headline: 'Conseil Pro : DOUBLER sur 9 vs $dealerSymbol',
        rationale: 'Doublez 9 contre un croupier faible (3–6).',
      );
    }

    return StrategyAdvice(
      action: StrategyAction.hit,
      headline: 'Conseil Pro : TIRER ($total vs $dealerSymbol)',
      rationale: 'Main basse ($total) : tirez gratuitement sans risque de Bust.',
    );
  }
}

class SideBetEngine {
  const SideBetEngine._();

  static SideBetEvaluation evaluate({
    required List<PlayingCard> playerInitialTwoCards,
    required PlayingCard dealerUpCard,
    required int perfectPairsBet,
    required int twentyOnePlusThreeBet,
  }) {
    String? ppTitle;
    int ppMultiplier = 0;
    int ppPayout = 0;

    if (perfectPairsBet > 0 && playerInitialTwoCards.length == 2) {
      final PlayingCard c1 = playerInitialTwoCards[0];
      final PlayingCard c2 = playerInitialTwoCards[1];
      if (c1.rank == c2.rank) {
        if (c1.suit == c2.suit) {
          ppTitle = 'PAIRE PARFAITE (25:1)';
          ppMultiplier = 25;
        } else if (c1.suit.isRed == c2.suit.isRed) {
          ppTitle = 'PAIRE COLORÉE (12:1)';
          ppMultiplier = 12;
        } else {
          ppTitle = 'PAIRE MIXTE (5:1)';
          ppMultiplier = 5;
        }
        ppPayout = perfectPairsBet * (ppMultiplier + 1);
      }
    }

    String? top3Title;
    int top3Multiplier = 0;
    int top3Payout = 0;

    if (twentyOnePlusThreeBet > 0 && playerInitialTwoCards.length == 2) {
      final List<PlayingCard> three = <PlayingCard>[
        playerInitialTwoCards[0],
        playerInitialTwoCards[1],
        dealerUpCard,
      ];

      final bool allSameSuit =
          three[0].suit == three[1].suit && three[1].suit == three[2].suit;
      final bool allSameRank =
          three[0].rank == three[1].rank && three[1].rank == three[2].rank;
      final bool isStraight = _isThreeCardStraight(three);

      if (allSameSuit && allSameRank) {
        top3Title = '21+3 BRELAN PARFAIT (100:1)';
        top3Multiplier = 100;
      } else if (allSameSuit && isStraight) {
        top3Title = '21+3 QUINTE FLUSH (40:1)';
        top3Multiplier = 40;
      } else if (allSameRank) {
        top3Title = '21+3 BRELAN (30:1)';
        top3Multiplier = 30;
      } else if (isStraight) {
        top3Title = '21+3 SUITE (10:1)';
        top3Multiplier = 10;
      } else if (allSameSuit) {
        top3Title = '21+3 COULEUR / FLUSH (5:1)';
        top3Multiplier = 5;
      }

      if (top3Multiplier > 0) {
        top3Payout = twentyOnePlusThreeBet * (top3Multiplier + 1);
      }
    }

    return SideBetEvaluation(
      perfectPairsBet: perfectPairsBet,
      perfectPairsTitle: ppTitle,
      perfectPairsMultiplier: ppMultiplier,
      perfectPairsPayout: ppPayout,
      twentyOnePlusThreeBet: twentyOnePlusThreeBet,
      twentyOnePlusThreeTitle: top3Title,
      twentyOnePlusThreeMultiplier: top3Multiplier,
      twentyOnePlusThreePayout: top3Payout,
    );
  }

  static bool _isThreeCardStraight(List<PlayingCard> three) {
    final List<int> highAce =
        three.map((PlayingCard c) => c.rank.pokerOrder).toList()..sort();
    if (highAce[1] == highAce[0] + 1 && highAce[2] == highAce[1] + 1) {
      return true;
    }
    // Check A-2-3 low Ace straight
    final List<int> lowAce = three
        .map((PlayingCard c) => c.rank == CardRank.ace ? 1 : c.rank.pokerOrder)
        .toList()
      ..sort();
    return lowAce[1] == lowAce[0] + 1 && lowAce[2] == lowAce[1] + 1;
  }
}

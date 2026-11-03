import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/blackjack_models.dart';
import 'services/strategy_coach.dart';
import 'widgets/casino_chip_widget.dart';
import 'widgets/casino_felt_painter.dart';
import 'widgets/modals/stats_history_sheet.dart';
import 'widgets/modals/strategy_rules_sheet.dart';
import 'widgets/playing_card_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const BlackjackRoyaleApp());
}

enum BettingTarget {
  main('MISE PRINCIPALE'),
  perfectPairs('PERFECT PAIRS (25:1)'),
  twentyOnePlusThree('21+3 POKER (100:1)');

  const BettingTarget(this.label);
  final String label;
}

class BlackjackRoyaleApp extends StatelessWidget {
  const BlackjackRoyaleApp({
    super.key,
    this.initialShoeOverride,
    this.randomSeed,
  });

  final List<PlayingCard>? initialShoeOverride;
  final int? randomSeed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blackjack Royale',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF041A10),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.dark,
        ),
      ),
      home: BlackjackTableScreen(
        initialShoeOverride: initialShoeOverride,
        randomSeed: randomSeed,
      ),
    );
  }
}

class BlackjackTableScreen extends StatefulWidget {
  const BlackjackTableScreen({
    super.key,
    this.initialShoeOverride,
    this.randomSeed,
  });

  final List<PlayingCard>? initialShoeOverride;
  final int? randomSeed;

  @override
  State<BlackjackTableScreen> createState() => BlackjackTableScreenState();
}

class BlackjackTableScreenState extends State<BlackjackTableScreen> {
  late math.Random _random;

  int _deckCount = 6;
  bool _dealerHitsSoft17 = false;
  bool _showCoach = true;
  bool _showCardCounter = true;

  List<PlayingCard> _shoe = <PlayingCard>[];
  int _runningCount = 0;
  int _cardSerial = 0;

  int _bankroll = 2500;
  int _stagedMainBet = 100;
  int _stagedPerfectPairsBet = 0;
  int _staged21Plus3Bet = 0;
  int _lastMainBet = 100;
  int _lastPerfectPairsBet = 0;
  int _last21Plus3Bet = 0;
  BettingTarget _activeBettingTarget = BettingTarget.main;

  GamePhase _phase = GamePhase.betting;
  List<PlayingCard> _dealerCards = <PlayingCard>[];
  List<PlayerHand> _playerHands = <PlayerHand>[];
  int _activeHandIndex = 0;
  int _insuranceBet = 0;
  SideBetEvaluation _lastSideBetResult = const SideBetEvaluation();

  String _statusHeadline = 'FAITES VOS JEUX — TABLE VIP 3:2';
  String _statusSubline =
      'Mise principale + Side Bets optionnels Perfect Pairs & 21+3';

  SessionStats _stats = const SessionStats();
  final List<RoundHistoryEntry> _history = <RoundHistoryEntry>[];
  int _roundCounter = 0;

  @override
  void initState() {
    super.initState();
    _random = math.Random(widget.randomSeed ?? 42);
    _buildAndShuffleShoe(overrideTopCards: widget.initialShoeOverride);
  }

  int get totalShoeCards => _deckCount * 52;
  int get remainingShoeCards => _shoe.length;

  double get trueCount {
    final double remainingDecks = math.max(0.5, _shoe.length / 52.0);
    return _runningCount / remainingDecks;
  }

  PlayerHand? get activeHand {
    if (_playerHands.isEmpty ||
        _activeHandIndex < 0 ||
        _activeHandIndex >= _playerHands.length) {
      return null;
    }
    return _playerHands[_activeHandIndex];
  }

  PlayingCard? get dealerUpCard {
    if (_dealerCards.isEmpty) {
      return null;
    }
    return _dealerCards.first;
  }

  int get totalStagedBet =>
      _stagedMainBet + _stagedPerfectPairsBet + _staged21Plus3Bet;

  bool get canHit =>
      _phase == GamePhase.playerTurn &&
      activeHand != null &&
      !activeHand!.isFinished;

  bool get canStand => canHit;

  bool get canDouble {
    final PlayerHand? hand = activeHand;
    if (!canHit || hand == null) {
      return false;
    }
    return hand.cards.length == 2 && _bankroll >= hand.bet;
  }

  bool get canSplit {
    final PlayerHand? hand = activeHand;
    if (!canHit || hand == null) {
      return false;
    }
    return _playerHands.length < 2 &&
        hand.cards.length == 2 &&
        hand.evaluation.isSplittable &&
        _bankroll >= hand.bet;
  }

  bool get canSurrender {
    final PlayerHand? hand = activeHand;
    if (!canHit || hand == null) {
      return false;
    }
    return !hand.isSplitHand && hand.cards.length == 2;
  }

  void injectShoeTopCardsForTesting(List<PlayingCard> topCards) {
    setState(() {
      _buildAndShuffleShoe(overrideTopCards: topCards);
    });
  }

  void _buildAndShuffleShoe({List<PlayingCard>? overrideTopCards}) {
    final List<PlayingCard> fresh = <PlayingCard>[];
    for (int d = 0; d < _deckCount; d++) {
      for (final CardSuit suit in CardSuit.values) {
        for (final CardRank rank in CardRank.values) {
          _cardSerial += 1;
          fresh.add(
            PlayingCard(
              id: 'card_${d}_${suit.name}_${rank.name}_$_cardSerial',
              suit: suit,
              rank: rank,
            ),
          );
        }
      }
    }
    fresh.shuffle(_random);
    if (overrideTopCards != null && overrideTopCards.isNotEmpty) {
      // Since _drawCard removes from the end of _shoe, put override cards at the end in reverse order
      for (final PlayingCard card in overrideTopCards.reversed) {
        fresh.add(card);
      }
    }
    _shoe = fresh;
    _runningCount = 0;
  }

  PlayingCard _drawCard({bool faceUp = true}) {
    if (_shoe.length < 18) {
      _buildAndShuffleShoe();
    }
    final PlayingCard raw = _shoe.removeLast().copyWith(faceUp: faceUp);
    if (faceUp) {
      _runningCount += raw.rank.hiLoValue;
    }
    return raw;
  }

  void _revealDealerHoleCard() {
    for (int i = 0; i < _dealerCards.length; i++) {
      if (!_dealerCards[i].faceUp) {
        final PlayingCard revealed = _dealerCards[i].copyWith(faceUp: true);
        _dealerCards[i] = revealed;
        _runningCount += revealed.rank.hiLoValue;
      }
    }
  }

  void addChipToBet(int chipValue) {
    if (_phase != GamePhase.betting && _phase != GamePhase.roundOver) {
      return;
    }
    setState(() {
      if (_phase == GamePhase.roundOver) {
        _prepareNextBettingPhase(keepStagedBets: true);
      }
      final int available = _bankroll - totalStagedBet;
      if (available <= 0) {
        return;
      }
      final int addAmount = math.min(chipValue, available);
      switch (_activeBettingTarget) {
        case BettingTarget.main:
          _stagedMainBet += addAmount;
        case BettingTarget.perfectPairs:
          _stagedPerfectPairsBet += addAmount;
        case BettingTarget.twentyOnePlusThree:
          _staged21Plus3Bet += addAmount;
      }
    });
  }

  void clearBets() {
    if (_phase != GamePhase.betting && _phase != GamePhase.roundOver) {
      return;
    }
    setState(() {
      if (_phase == GamePhase.roundOver) {
        _prepareNextBettingPhase(keepStagedBets: false);
      }
      _stagedMainBet = 0;
      _stagedPerfectPairsBet = 0;
      _staged21Plus3Bet = 0;
    });
  }

  void repeatLastBet() {
    if (_phase != GamePhase.betting && _phase != GamePhase.roundOver) {
      return;
    }
    setState(() {
      if (_phase == GamePhase.roundOver) {
        _prepareNextBettingPhase(keepStagedBets: false);
      }
      final int desiredTotal =
          _lastMainBet + _lastPerfectPairsBet + _last21Plus3Bet;
      if (desiredTotal <= _bankroll && _lastMainBet > 0) {
        _stagedMainBet = _lastMainBet;
        _stagedPerfectPairsBet = _lastPerfectPairsBet;
        _staged21Plus3Bet = _last21Plus3Bet;
      } else {
        _stagedMainBet = math.min(100, _bankroll);
        _stagedPerfectPairsBet = 0;
        _staged21Plus3Bet = 0;
      }
    });
  }

  void doubleStagedMainBet() {
    if (_phase != GamePhase.betting && _phase != GamePhase.roundOver) {
      return;
    }
    setState(() {
      if (_phase == GamePhase.roundOver) {
        _prepareNextBettingPhase(keepStagedBets: true);
      }
      if (_stagedMainBet == 0) {
        _stagedMainBet = math.min(25, _bankroll - totalStagedBet);
        return;
      }
      final int extraNeeded = _stagedMainBet;
      final int available = _bankroll - totalStagedBet;
      if (available >= extraNeeded) {
        _stagedMainBet *= 2;
      } else if (available > 0) {
        _stagedMainBet += available;
      }
    });
  }

  void topUpBankroll() {
    setState(() {
      _bankroll += 1000;
      if (_stagedMainBet == 0) {
        _stagedMainBet = 100;
      }
      _statusHeadline = 'CAVE RECHARGÉE (+1 000 \$)';
      _statusSubline = 'Nouveau solde disponible : $_bankroll \$';
    });
  }

  void _prepareNextBettingPhase({required bool keepStagedBets}) {
    _phase = GamePhase.betting;
    _dealerCards = <PlayingCard>[];
    _playerHands = <PlayerHand>[];
    _activeHandIndex = 0;
    _insuranceBet = 0;
    _lastSideBetResult = const SideBetEvaluation();
    if (!keepStagedBets) {
      _stagedMainBet = 0;
      _stagedPerfectPairsBet = 0;
      _staged21Plus3Bet = 0;
    } else if (totalStagedBet > _bankroll) {
      _stagedPerfectPairsBet = 0;
      _staged21Plus3Bet = 0;
      _stagedMainBet = math.min(_stagedMainBet, _bankroll);
    }
  }

  void dealNewRound() {
    if (_phase == GamePhase.roundOver) {
      if (totalStagedBet == 0 || totalStagedBet > _bankroll) {
        repeatLastBet();
      }
    }
    if (_stagedMainBet <= 0 || totalStagedBet > _bankroll) {
      if (_bankroll >= 25) {
        setState(() {
          _stagedMainBet = math.min(100, _bankroll);
          _stagedPerfectPairsBet = 0;
          _staged21Plus3Bet = 0;
        });
      } else {
        return;
      }
    }

    setState(() {
      _lastMainBet = _stagedMainBet;
      _lastPerfectPairsBet = _stagedPerfectPairsBet;
      _last21Plus3Bet = _staged21Plus3Bet;

      _bankroll -= totalStagedBet;
      _insuranceBet = 0;

      final PlayingCard p1 = _drawCard(faceUp: true);
      final PlayingCard d1 = _drawCard(faceUp: true);
      final PlayingCard p2 = _drawCard(faceUp: true);
      final PlayingCard d2 = _drawCard(faceUp: false);

      _dealerCards = <PlayingCard>[d1, d2];
      _playerHands = <PlayerHand>[
        PlayerHand(
          cards: <PlayingCard>[p1, p2],
          bet: _stagedMainBet,
        ),
      ];
      _activeHandIndex = 0;

      // Evaluate Side Bets immediately
      _lastSideBetResult = SideBetEngine.evaluate(
        playerInitialTwoCards: <PlayingCard>[p1, p2],
        dealerUpCard: d1,
        perfectPairsBet: _stagedPerfectPairsBet,
        twentyOnePlusThreeBet: _staged21Plus3Bet,
      );
      if (_lastSideBetResult.totalPayout > 0) {
        _bankroll += _lastSideBetResult.totalPayout;
      }

      // Check Insurance offer if dealer up-card is Ace
      final int maxInsurance = _stagedMainBet ~/ 2;
      if (d1.rank == CardRank.ace &&
          maxInsurance > 0 &&
          _bankroll >= maxInsurance) {
        _phase = GamePhase.insuranceOffer;
        _statusHeadline = 'LE CROUPIER MONTRE UN AS — ASSURANCE ?';
        _statusSubline =
            'Assurez votre main pour $maxInsurance \$ (paiement 2:1 si Blackjack Croupier)';
        return;
      }

      _continueAfterInsuranceCheck();
    });
  }

  void decideInsurance({required bool takeInsurance}) {
    if (_phase != GamePhase.insuranceOffer) {
      return;
    }
    setState(() {
      if (takeInsurance) {
        final int cost = _playerHands.first.bet ~/ 2;
        if (_bankroll >= cost) {
          _bankroll -= cost;
          _insuranceBet = cost;
        }
      }
      _continueAfterInsuranceCheck();
    });
  }

  void _continueAfterInsuranceCheck() {
    final HandEvaluation playerEval = _playerHands.first.evaluation;
    final HandEvaluation dealerFullEval = HandEvaluation.fromCards(
      _dealerCards,
      onlyFaceUp: false,
    );

    if (playerEval.isBlackjack || dealerFullEval.isBlackjack) {
      _revealDealerHoleCard();
      _settleRound();
      return;
    }

    _phase = GamePhase.playerTurn;
    _statusHeadline = 'À VOUS DE JOUER';
    if (_lastSideBetResult.hasAnyWin) {
      _statusSubline =
          'Side Bet gagnant : +${_lastSideBetResult.totalPayout} \$ crédités !';
    } else {
      _statusSubline =
          'Tirez, Restez, Doublez ou Séparez selon la carte du croupier';
    }
  }

  void playerHit() {
    if (!canHit) {
      return;
    }
    setState(() {
      final PlayerHand current = activeHand!;
      final List<PlayingCard> updatedCards = <PlayingCard>[
        ...current.cards,
        _drawCard(faceUp: true),
      ];
      final PlayerHand updatedHand = current.copyWith(cards: updatedCards);
      _playerHands[_activeHandIndex] = updatedHand;

      if (updatedHand.evaluation.isBusted) {
        _playerHands[_activeHandIndex] = updatedHand.copyWith(
          outcome: HandOutcome.bust,
          payout: 0,
        );
        _advanceToNextHandOrDealer();
      } else if (updatedHand.evaluation.bestTotal == 21) {
        _playerHands[_activeHandIndex] = updatedHand.copyWith(isStood: true);
        _advanceToNextHandOrDealer();
      }
    });
  }

  void playerStand() {
    if (!canStand) {
      return;
    }
    setState(() {
      _playerHands[_activeHandIndex] = activeHand!.copyWith(isStood: true);
      _advanceToNextHandOrDealer();
    });
  }

  void playerDoubleDown() {
    if (!canDouble) {
      return;
    }
    setState(() {
      final PlayerHand current = activeHand!;
      _bankroll -= current.bet;
      final List<PlayingCard> updatedCards = <PlayingCard>[
        ...current.cards,
        _drawCard(faceUp: true),
      ];
      PlayerHand doubled = current.copyWith(
        cards: updatedCards,
        bet: current.bet * 2,
        isDoubled: true,
        isStood: true,
      );
      if (doubled.evaluation.isBusted) {
        doubled = doubled.copyWith(
          outcome: HandOutcome.bust,
          payout: 0,
        );
      }
      _playerHands[_activeHandIndex] = doubled;
      _advanceToNextHandOrDealer();
    });
  }

  void playerSplit() {
    if (!canSplit) {
      return;
    }
    setState(() {
      final PlayerHand original = activeHand!;
      _bankroll -= original.bet;

      final PlayingCard firstCard = original.cards[0];
      final PlayingCard secondCard = original.cards[1];

      final PlayerHand hand1 = PlayerHand(
        cards: <PlayingCard>[firstCard, _drawCard(faceUp: true)],
        bet: original.bet,
        isSplitHand: true,
      );
      final PlayerHand hand2 = PlayerHand(
        cards: <PlayingCard>[secondCard, _drawCard(faceUp: true)],
        bet: original.bet,
        isSplitHand: true,
      );

      _playerHands = <PlayerHand>[hand1, hand2];
      _activeHandIndex = 0;
      _statusHeadline = 'MAINS SÉPARÉES (SPLIT) — MAIN 1 ACTIVE';
      _statusSubline = 'Jouez la Main 1 puis la Main 2 séquentiellement';
    });
  }

  void playerSurrender() {
    if (!canSurrender) {
      return;
    }
    setState(() {
      final PlayerHand current = activeHand!;
      final int halfRefund = current.bet ~/ 2;
      _playerHands[_activeHandIndex] = current.copyWith(
        isSurrendered: true,
        isStood: true,
        outcome: HandOutcome.surrender,
        payout: halfRefund,
      );
      _advanceToNextHandOrDealer();
    });
  }

  void _advanceToNextHandOrDealer() {
    if (_activeHandIndex + 1 < _playerHands.length) {
      _activeHandIndex += 1;
      _statusHeadline = 'MAIN 2 ACTIVE';
      _statusSubline = 'Choisissez votre action pour la seconde main';
      return;
    }
    _runDealerAndSettle();
  }

  void _runDealerAndSettle() {
    _phase = GamePhase.dealerTurn;
    _revealDealerHoleCard();

    final bool anyLiveHand = _playerHands.any(
      (PlayerHand h) => !h.evaluation.isBusted && !h.isSurrendered,
    );

    if (anyLiveHand) {
      while (true) {
        final HandEvaluation dealerEval = HandEvaluation.fromCards(
          _dealerCards,
          onlyFaceUp: false,
        );
        if (dealerEval.bestTotal < 17) {
          _dealerCards = <PlayingCard>[
            ..._dealerCards,
            _drawCard(faceUp: true),
          ];
          continue;
        }
        if (dealerEval.bestTotal == 17 &&
            dealerEval.isSoft &&
            _dealerHitsSoft17) {
          _dealerCards = <PlayingCard>[
            ..._dealerCards,
            _drawCard(faceUp: true),
          ];
          continue;
        }
        break;
      }
    }

    _settleRound();
  }

  void _settleRound() {
    final HandEvaluation dealerEval = HandEvaluation.fromCards(
      _dealerCards,
      onlyFaceUp: false,
    );

    int totalMainReturned = 0;
    int totalMainStaked = 0;
    int wonCount = 0;
    int lostCount = 0;
    int pushCount = 0;
    int blackjackCount = 0;

    final List<PlayerHand> settledHands = <PlayerHand>[];

    for (final PlayerHand hand in _playerHands) {
      totalMainStaked += hand.bet;
      final HandEvaluation pEval = hand.evaluation;

      if (hand.isSurrendered) {
        final int refund = hand.bet ~/ 2;
        totalMainReturned += refund;
        lostCount += 1;
        settledHands.add(
          hand.copyWith(outcome: HandOutcome.surrender, payout: refund),
        );
        continue;
      }

      if (pEval.isBusted) {
        lostCount += 1;
        settledHands.add(
          hand.copyWith(outcome: HandOutcome.bust, payout: 0),
        );
        continue;
      }

      if (pEval.isBlackjack && !dealerEval.isBlackjack) {
        // 3:2 Blackjack payout -> stake + 1.5x stake = 2.5x stake
        final int bjPayout = hand.bet + ((hand.bet * 3) ~/ 2);
        totalMainReturned += bjPayout;
        wonCount += 1;
        blackjackCount += 1;
        settledHands.add(
          hand.copyWith(outcome: HandOutcome.blackjack, payout: bjPayout),
        );
        continue;
      }

      if (dealerEval.isBlackjack && !pEval.isBlackjack) {
        lostCount += 1;
        settledHands.add(
          hand.copyWith(outcome: HandOutcome.lose, payout: 0),
        );
        continue;
      }

      if (dealerEval.isBusted || pEval.bestTotal > dealerEval.bestTotal) {
        final int winPayout = hand.bet * 2;
        totalMainReturned += winPayout;
        wonCount += 1;
        settledHands.add(
          hand.copyWith(outcome: HandOutcome.win, payout: winPayout),
        );
      } else if (pEval.bestTotal == dealerEval.bestTotal) {
        totalMainReturned += hand.bet;
        pushCount += 1;
        settledHands.add(
          hand.copyWith(outcome: HandOutcome.push, payout: hand.bet),
        );
      } else {
        lostCount += 1;
        settledHands.add(
          hand.copyWith(outcome: HandOutcome.lose, payout: 0),
        );
      }
    }

    // Settle Insurance if taken
    int insuranceReturned = 0;
    if (_insuranceBet > 0 && dealerEval.isBlackjack) {
      insuranceReturned = _insuranceBet * 3;
    }

    _bankroll += totalMainReturned + insuranceReturned;
    _playerHands = settledHands;
    _phase = GamePhase.roundOver;
    _roundCounter += 1;

    final int netRoundDelta = (totalMainReturned - totalMainStaked) +
        (insuranceReturned - _insuranceBet) +
        _lastSideBetResult.netProfit;

    // Build headline
    if (blackjackCount > 0) {
      _statusHeadline = 'BLACKJACK ROYAL 3:2 ! (+$netRoundDelta \$)';
      _statusSubline = 'Paiement 3 pour 2 crédité sur votre Bankroll';
    } else if (netRoundDelta > 0) {
      _statusHeadline = 'MAIN GAGNANTE ! (+$netRoundDelta \$)';
      _statusSubline = dealerEval.isBusted
          ? 'Le croupier dépasse 21 (${dealerEval.bestTotal}) !'
          : 'Votre main bat le croupier (${dealerEval.bestTotal})';
    } else if (netRoundDelta == 0) {
      _statusHeadline = 'ÉGALITÉ (PUSH) — MISE REMBOURSÉE';
      _statusSubline = 'Même score que le croupier (${dealerEval.bestTotal})';
    } else {
      _statusHeadline = 'LE CROUPIER L’EMPORTE ($netRoundDelta \$)';
      _statusSubline = dealerEval.isBlackjack
          ? 'Blackjack naturel du croupier (21)'
          : 'Score du croupier : ${dealerEval.badgeLabel}';
    }

    final int updatedBiggestWin = math.max(
      _stats.biggestWin,
      netRoundDelta > 0 ? netRoundDelta : 0,
    );
    final List<int> updatedBankrollHistory = <int>[
      ..._stats.bankrollHistory,
      _bankroll,
    ];

    _stats = _stats.copyWith(
      roundsPlayed: _stats.roundsPlayed + 1,
      handsWon: _stats.handsWon + wonCount,
      handsLost: _stats.handsLost + lostCount,
      handsPushed: _stats.handsPushed + pushCount,
      blackjacks: _stats.blackjacks + blackjackCount,
      biggestWin: updatedBiggestWin,
      netProfit: _stats.netProfit + netRoundDelta,
      bankrollHistory: updatedBankrollHistory,
    );

    final String playerSummary = _playerHands
        .map((PlayerHand h) => h.evaluation.badgeLabel)
        .join(' & ');

    _history.insert(
      0,
      RoundHistoryEntry(
        roundNumber: _roundCounter,
        playerSummary: playerSummary,
        dealerSummary: dealerEval.badgeLabel,
        netDelta: netRoundDelta,
        bankrollAfter: _bankroll,
        headline: _statusHeadline,
      ),
    );
    if (_history.length > 30) {
      _history.removeLast();
    }

    // Prepare default rebet if bankroll permits
    if (totalStagedBet > _bankroll) {
      _stagedPerfectPairsBet = 0;
      _staged21Plus3Bet = 0;
      _stagedMainBet = math.min(_lastMainBet, _bankroll);
    }
  }

  void _openStatsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatsHistorySheet(
          stats: _stats,
          history: _history,
          bankroll: _bankroll,
          runningCount: _runningCount,
          trueCount: trueCount,
          remainingCards: remainingShoeCards,
          totalShoeCards: totalShoeCards,
          onTopUpBankroll: topUpBankroll,
          onResetStats: () {
            setState(() {
              _stats = SessionStats(bankrollHistory: <int>[_bankroll]);
              _history.clear();
              _roundCounter = 0;
            });
          },
        );
      },
    );
  }

  void _openStrategySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return StrategyRulesSheet(
              deckCount: _deckCount,
              dealerHitsSoft17: _dealerHitsSoft17,
              showCoach: _showCoach,
              showCardCounter: _showCardCounter,
              onDeckCountChanged: (int newDecks) {
                setState(() {
                  _deckCount = newDecks;
                  _buildAndShuffleShoe();
                });
                setSheetState(() {});
              },
              onDealerRuleChanged: (bool v) {
                setState(() => _dealerHitsSoft17 = v);
                setSheetState(() {});
              },
              onToggleCoach: (bool v) {
                setState(() => _showCoach = v);
                setSheetState(() {});
              },
              onToggleCardCounter: (bool v) {
                setState(() => _showCardCounter = v);
                setSheetState(() {});
              },
              onReshuffleNow: () {
                setState(() {
                  _buildAndShuffleShoe();
                  _statusHeadline = 'SABOT REMÉLANGÉ ($_deckCount PAQUETS)';
                  _statusSubline =
                      '$totalShoeCards cartes prêtes • Compteur Hi-Lo remis à 0';
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final StrategyAdvice advice = StrategyCoach.recommend(
      hand: activeHand ??
          const PlayerHand(cards: <PlayingCard>[], bet: 0),
      dealerUpCard: dealerUpCard,
      canDouble: canDouble,
      canSplit: canSplit,
      canSurrender: canSurrender,
    );

    return Scaffold(
      body: CasinoFeltBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildTopHud(),
                const SizedBox(height: 6),
                _buildTableRulesRibbon(),
                const SizedBox(height: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _buildDealerSection(),
                      _buildCenterBannerAndCoach(advice),
                      _buildPlayerHandsSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _buildBottomControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF06150E).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFFFD700), Color(0xFFB4831E)],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                  blurRadius: 6,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const CardSuitVector(
              suit: CardSuit.spades,
              size: 18,
              colorOverride: Color(0xFF06150E),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'BLACKJACK ROYALE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _showCardCounter
                        ? 'Sabot $remainingShoeCards/$totalShoeCards • RC ${_runningCount >= 0 ? '+$_runningCount' : '$_runningCount'} (TC ${trueCount >= 0 ? '+${trueCount.toStringAsFixed(1)}' : trueCount.toStringAsFixed(1)})'
                        : 'Sabot $remainingShoeCards/$totalShoeCards cartes ($_deckCount P)',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 9.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bankroll Badge
          GestureDetector(
            onTap: _bankroll < 100 ? topUpBankroll : _openStatsSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0E291C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.65),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFFFFD700),
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$_bankroll \$',
                    key: const Key('bankroll_text'),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            key: const Key('open_strategy_button'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _openStrategySheet,
            icon: const Icon(
              Icons.school_outlined,
              color: Color(0xFFFFD700),
              size: 20,
            ),
            tooltip: 'Stratégie & Règles',
          ),
          IconButton(
            key: const Key('open_stats_button'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _openStatsSheet,
            icon: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Statistiques & Historique',
          ),
        ],
      ),
    );
  }

  Widget _buildTableRulesRibbon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildRulePill('BLACKJACK PAIE 3:2'),
        const SizedBox(width: 6),
        _buildRulePill(
          _dealerHitsSoft17 ? 'CROUPIER TIRE SOFT 17' : 'CROUPIER RESTE À 17',
        ),
        const SizedBox(width: 6),
        _buildRulePill('ASSURANCE 2:1'),
      ],
    );
  }

  Widget _buildRulePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE5C158),
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildDealerSection() {
    final bool hideHole = _phase == GamePhase.playerTurn ||
        _phase == GamePhase.insuranceOffer;
    final HandEvaluation dealerEval = HandEvaluation.fromCards(
      _dealerCards,
      onlyFaceUp: hideHole,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'CROUPIER',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: dealerEval.isBusted
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF0A2216),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                _dealerCards.isEmpty ? 'EN ATTENTE' : dealerEval.badgeLabel,
                key: const Key('dealer_score_badge'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 98,
          child: _dealerCards.isEmpty
              ? Center(
                  child: Container(
                    width: 68,
                    height: 94,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'SABOT\nPRÊT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: _buildOverlappingCardRow(
                    cards: _dealerCards,
                    cardWidth: 68,
                    cardHeight: 96,
                    overlap: 26,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCenterBannerAndCoach(StrategyAdvice advice) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Colors.black.withValues(alpha: 0.45),
                const Color(0xFF092518).withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.45),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.40),
            ),
          ),
          child: Column(
            children: <Widget>[
              Text(
                _statusHeadline,
                key: const Key('status_headline'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _statusSubline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              if (_lastSideBetResult.hasAnyWin) ...<Widget>[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Text(
                    <String>[
                      if (_lastSideBetResult.perfectPairsTitle != null)
                        '${_lastSideBetResult.perfectPairsTitle} (+${_lastSideBetResult.perfectPairsPayout}\$)',
                      if (_lastSideBetResult.twentyOnePlusThreeTitle != null)
                        '${_lastSideBetResult.twentyOnePlusThreeTitle} (+${_lastSideBetResult.twentyOnePlusThreePayout}\$)',
                    ].join(' • '),
                    style: const TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_showCoach && _phase == GamePhase.playerTurn) ...<Widget>[
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF06150E).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: advice.action.badgeColor.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: advice.action.badgeColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    advice.action.shortCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        advice.headline,
                        key: const Key('coach_headline'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        advice.rationale,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayerHandsSection() {
    if (_playerHands.isEmpty) {
      return Container(
        height: 128,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                children: <Widget>[
                  const Text(
                    'MISE SUR LE TAPIS',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$_stagedMainBet \$',
                    key: const Key('staged_main_bet_text'),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (_stagedPerfectPairsBet > 0 || _staged21Plus3Bet > 0)
                    Text(
                      'Side Bets : PP $_stagedPerfectPairsBet \$ • 21+3 $_staged21Plus3Bet \$',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final bool isSplit = _playerHands.length > 1;
    final double cardWidth = isSplit ? 58 : 70;
    final double cardHeight = isSplit ? 82 : 98;
    final double overlap = isSplit ? 20 : 26;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(_playerHands.length, (int index) {
        final PlayerHand hand = _playerHands[index];
        final HandEvaluation eval = hand.evaluation;
        final bool isCurrentHand =
            _phase == GamePhase.playerTurn && index == _activeHandIndex;

        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: isSplit ? 4 : 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrentHand
                  ? const Color(0xFF0E3924).withValues(alpha: 0.78)
                  : Colors.black.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrentHand
                    ? const Color(0xFFFFD700)
                    : Colors.white.withValues(alpha: 0.14),
                width: isCurrentHand ? 1.8 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      isSplit ? 'MAIN ${index + 1}' : 'VOTRE MAIN',
                      style: TextStyle(
                        color: isCurrentHand
                            ? const Color(0xFFFFD700)
                            : Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hand.outcome != HandOutcome.pending
                            ? hand.outcome.color
                            : const Color(0xFF06150E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        eval.badgeLabel,
                        key: Key('player_hand_${index}_badge'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: cardHeight + 4,
                  child: Center(
                    child: _buildOverlappingCardRow(
                      cards: hand.cards,
                      cardWidth: cardWidth,
                      cardHeight: cardHeight,
                      overlap: overlap,
                      highlightCards: isCurrentHand,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Mise : ${hand.bet} \$${hand.isDoubled ? ' (×2)' : ''}',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hand.outcome != HandOutcome.pending)
                      Text(
                        hand.outcome.label,
                        style: TextStyle(
                          color: hand.outcome.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOverlappingCardRow({
    required List<PlayingCard> cards,
    required double cardWidth,
    required double cardHeight,
    required double overlap,
    bool highlightCards = false,
  }) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }
    final double totalWidth = cardWidth + ((cards.length - 1) * overlap);

    return SizedBox(
      width: totalWidth,
      height: cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: List<Widget>.generate(cards.length, (int i) {
          return Positioned(
            left: i * overlap,
            top: 0,
            child: PlayingCardWidget(
              card: cards[i],
              width: cardWidth,
              height: cardHeight,
              isHighlighted: highlightCards && i == cards.length - 1,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomControls() {
    if (_phase == GamePhase.insuranceOffer) {
      final int insCost = _playerHands.first.bet ~/ 2;
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF06150E).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'ASSURANCE CONTRE BLACKJACK DU CROUPIER ($insCost \$ — PAIE 2:1)',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('take_insurance_button'),
                    onPressed: () => decideInsurance(takeInsurance: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.verified_user, size: 16),
                    label: Text(
                      'ASSURER ($insCost \$)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('decline_insurance_button'),
                    onPressed: () => decideInsurance(takeInsurance: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text(
                      'REFUSER & JOUER',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_phase == GamePhase.playerTurn) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF06150E).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _ActionButton(
                    buttonKey: const Key('hit_button'),
                    label: 'TIRER',
                    sublabel: 'HIT',
                    icon: Icons.add_circle_outline,
                    color: const Color(0xFF10B981),
                    enabled: canHit,
                    onTap: playerHit,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    buttonKey: const Key('stand_button'),
                    label: 'RESTER',
                    sublabel: 'STAND',
                    icon: Icons.pan_tool_alt_outlined,
                    color: const Color(0xFFEF4444),
                    enabled: canStand,
                    onTap: playerStand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _ActionButton(
                    buttonKey: const Key('double_button'),
                    label: 'DOUBLER',
                    sublabel: '×2 (1 CARTE)',
                    icon: Icons.bolt,
                    color: const Color(0xFFF59E0B),
                    enabled: canDouble,
                    onTap: playerDoubleDown,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionButton(
                    buttonKey: const Key('split_button'),
                    label: 'SÉPARER',
                    sublabel: 'SPLIT PAIRE',
                    icon: Icons.call_split,
                    color: const Color(0xFF8B5CF6),
                    enabled: canSplit,
                    onTap: playerSplit,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionButton(
                    buttonKey: const Key('surrender_button'),
                    label: 'ABANDON',
                    sublabel: '½ MISE',
                    icon: Icons.flag_outlined,
                    color: const Color(0xFF64748B),
                    enabled: canSurrender,
                    onTap: playerSurrender,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Betting / RoundOver Dock
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF06150E).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Target selector (Main Bet, Perfect Pairs, 21+3)
          Row(
            children: <Widget>[
              _buildBetTargetSlot(
                target: BettingTarget.main,
                title: 'MISE',
                amount: _stagedMainBet,
                keyName: 'target_main_bet',
              ),
              const SizedBox(width: 6),
              _buildBetTargetSlot(
                target: BettingTarget.perfectPairs,
                title: 'PAIRS 25:1',
                amount: _stagedPerfectPairsBet,
                keyName: 'target_pp_bet',
              ),
              const SizedBox(width: 6),
              _buildBetTargetSlot(
                target: BettingTarget.twentyOnePlusThree,
                title: '21+3 100:1',
                amount: _staged21Plus3Bet,
                keyName: 'target_21plus3_bet',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Chips Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: CasinoChip.standardChips.map((CasinoChip chip) {
              final bool canAfford = (_bankroll - totalStagedBet) >= chip.value;
              return CasinoChipButton(
                key: Key('chip_${chip.value}'),
                chip: chip,
                size: 46,
                enabled: canAfford || _phase == GamePhase.roundOver,
                onTap: () => addChipToBet(chip.value),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Utility + Deal Row
          Row(
            children: <Widget>[
              OutlinedButton(
                key: const Key('clear_bets_button'),
                onPressed: clearBets,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'EFFACER',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                key: const Key('double_bet_button'),
                onPressed: doubleStagedMainBet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD700),
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'MISE ×2',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('deal_button'),
                  onPressed: dealNewRound,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF041A10),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.style, size: 17),
                  label: Text(
                    _phase == GamePhase.roundOver
                        ? 'NOUVELLE DONNE (${_stagedMainBet > 0 ? _stagedMainBet : _lastMainBet} \$)'
                        : 'DISTRIBUER ($_stagedMainBet \$)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBetTargetSlot({
    required BettingTarget target,
    required String title,
    required int amount,
    required String keyName,
  }) {
    final bool selected = _activeBettingTarget == target;
    return Expanded(
      child: GestureDetector(
        key: Key(keyName),
        onTap: () => setState(() => _activeBettingTarget = target),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF123824)
                : Colors.black.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFD700)
                  : Colors.white.withValues(alpha: 0.14),
              width: selected ? 1.4 : 0.9,
            ),
          ),
          child: Column(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: selected ? const Color(0xFFFFD700) : Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$amount \$',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.buttonKey,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                color.withValues(alpha: 0.88),
                Color.lerp(color, Colors.black, 0.38)!,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 5),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      sublabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

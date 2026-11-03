import 'dart:io';
import 'dart:ui' as ui;

import 'package:blackjack_royale/main.dart';
import 'package:blackjack_royale/models/blackjack_models.dart';
import 'package:blackjack_royale/services/strategy_coach.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadRealFlutterFonts() async {
  final String flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? '/tmp/flutter-sdk/flutter';
  final String fontDir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final Directory dir = Directory(fontDir);
  if (!dir.existsSync()) {
    return;
  }

  final FontLoader robotoLoader = FontLoader('Roboto');
  for (final String file in <String>[
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
    'Roboto-Italic.ttf',
    'Roboto-BoldItalic.ttf',
  ]) {
    final File f = File('$fontDir/$file');
    if (f.existsSync()) {
      final Uint8List bytes = f.readAsBytesSync();
      robotoLoader.addFont(
        Future<ByteData>.value(ByteData.view(bytes.buffer)),
      );
    }
  }
  await robotoLoader.load();

  final File materialIconsFile = File('$fontDir/MaterialIcons-Regular.otf');
  if (materialIconsFile.existsSync()) {
    final FontLoader iconsLoader = FontLoader('MaterialIcons');
    final Uint8List bytes = materialIconsFile.readAsBytesSync();
    iconsLoader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    await iconsLoader.load();
  }
}

Future<void> _captureEmulatorScreenshot(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String outputPath,
) async {
  await tester.pump(const Duration(milliseconds: 250));
  await tester.runAsync(() async {
    final RenderRepaintBoundary boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData != null) {
      final File outFile = File(outputPath);
      outFile.parent.createSync(recursive: true);
      outFile.writeAsBytesSync(byteData.buffer.asUint8List());
    }
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await _loadRealFlutterFonts();
  });

  test('Unit: HandEvaluation Soft/Hard Aces, Blackjack 3:2 & SideBets', () {
    // Natural Blackjack: Ace + King
    final HandEvaluation bj = HandEvaluation.fromCards(const <PlayingCard>[
      PlayingCard(id: '1', suit: CardSuit.spades, rank: CardRank.ace),
      PlayingCard(id: '2', suit: CardSuit.hearts, rank: CardRank.king),
    ]);
    expect(bj.isBlackjack, isTrue);
    expect(bj.bestTotal, 21);
    expect(bj.badgeLabel, 'BLACKJACK 21');

    // Soft 17: Ace + 6 -> 7 / 17
    final HandEvaluation soft17 = HandEvaluation.fromCards(const <PlayingCard>[
      PlayingCard(id: '1', suit: CardSuit.spades, rank: CardRank.ace),
      PlayingCard(id: '2', suit: CardSuit.diamonds, rank: CardRank.six),
    ]);
    expect(soft17.isSoft, isTrue);
    expect(soft17.hardTotal, 7);
    expect(soft17.bestTotal, 17);
    expect(soft17.badgeLabel, '7 / 17');

    // Hard 17 after drawing a 10 on Soft 17: Ace + 6 + 10 = 17 hard
    final HandEvaluation hard17 = HandEvaluation.fromCards(const <PlayingCard>[
      PlayingCard(id: '1', suit: CardSuit.spades, rank: CardRank.ace),
      PlayingCard(id: '2', suit: CardSuit.diamonds, rank: CardRank.six),
      PlayingCard(id: '3', suit: CardSuit.clubs, rank: CardRank.ten),
    ]);
    expect(hard17.isSoft, isFalse);
    expect(hard17.bestTotal, 17);

    // Perfect Pair & 21+3 evaluation
    final SideBetEvaluation sideEval = SideBetEngine.evaluate(
      playerInitialTwoCards: const <PlayingCard>[
        PlayingCard(id: 'p1', suit: CardSuit.spades, rank: CardRank.queen),
        PlayingCard(id: 'p2', suit: CardSuit.spades, rank: CardRank.queen),
      ],
      dealerUpCard: const PlayingCard(
        id: 'd1',
        suit: CardSuit.spades,
        rank: CardRank.king,
      ),
      perfectPairsBet: 25,
      twentyOnePlusThreeBet: 25,
    );
    expect(sideEval.perfectPairsMultiplier, 25); // Perfect Pair 25:1
    expect(sideEval.twentyOnePlusThreeMultiplier, 5); // Flush 5:1
  });

  testWidgets(
      'Portrait 1080x2400 Full Gameplay, Split, Double, Coach & Screenshots',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final GlobalKey boundaryKey = GlobalKey();

    // Prepare deterministic top of shoe for Round 1:
    // p1 = 6♠, d1 = 6♦, p2 = 5♥ (Player has 11 vs Dealer 6 -> Coach recommends DOUBLE),
    // d2 = 10♣ (Dealer has 16), double card = K♠ (Player gets 21!), dealer draws 8♠ (Dealer busts at 24!)
    const List<PlayingCard> round1Cards = <PlayingCard>[
      PlayingCard(id: 'r1_p1', suit: CardSuit.spades, rank: CardRank.six),
      PlayingCard(id: 'r1_d1', suit: CardSuit.diamonds, rank: CardRank.six),
      PlayingCard(id: 'r1_p2', suit: CardSuit.hearts, rank: CardRank.five),
      PlayingCard(id: 'r1_d2', suit: CardSuit.clubs, rank: CardRank.ten),
      PlayingCard(id: 'r1_p3', suit: CardSuit.spades, rank: CardRank.king),
      PlayingCard(id: 'r1_d3', suit: CardSuit.spades, rank: CardRank.eight),
    ];

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: const BlackjackRoyaleApp(
          initialShoeOverride: round1Cards,
          randomSeed: 777,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BLACKJACK ROYALE'), findsOneWidget);
    expect(find.byKey(const Key('bankroll_text')), findsOneWidget);

    // Add a 25$ chip to Perfect Pairs and 25$ chip to 21+3, plus 100$ on Main Bet -> 200$ main bet
    await tester.tap(find.byKey(const Key('chip_100')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('target_pp_bet')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('chip_25')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('target_21plus3_bet')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('chip_25')));
    await tester.pump();

    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/01_betting_table_sidebets.png',
    );

    // Deal Round 1 (11 vs 6)
    await tester.tap(find.byKey(const Key('deal_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('player_hand_0_badge')), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(
      find.textContaining('Conseil Pro : DOUBLER sur 11 vs 6'),
      findsOneWidget,
    );

    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/02_active_hand_coach_double.png',
    );

    // Execute Double Down (player gets King -> 21, dealer busts at 24)
    await tester.tap(find.byKey(const Key('double_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('MAIN GAGNANTE'), findsOneWidget);

    // Round 2: Inject a Natural Blackjack (Ace of Spades + Queen of Hearts) + Perfect Pair / 21+3
    final BlackjackTableScreenState state =
        tester.state<BlackjackTableScreenState>(
      find.byType(BlackjackTableScreen),
    );
    state.injectShoeTopCardsForTesting(const <PlayingCard>[
      PlayingCard(id: 'r2_p1', suit: CardSuit.spades, rank: CardRank.ace),
      PlayingCard(id: 'r2_d1', suit: CardSuit.hearts, rank: CardRank.nine),
      PlayingCard(id: 'r2_p2', suit: CardSuit.spades, rank: CardRank.king),
      PlayingCard(id: 'r2_d2', suit: CardSuit.clubs, rank: CardRank.eight),
    ]);
    await tester.pump();

    await tester.tap(find.byKey(const Key('deal_button')));
    await tester.pumpAndSettle();

    expect(find.text('BLACKJACK 21'), findsOneWidget);
    expect(find.textContaining('BLACKJACK ROYAL 3:2'), findsOneWidget);

    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/03_blackjack_natural_3to2_win.png',
    );

    // Round 3: Inject Pair of 8s (8♠, 8♥) vs Dealer 6♣ -> Test SPLIT into 2 hands
    state.injectShoeTopCardsForTesting(const <PlayingCard>[
      PlayingCard(id: 'r3_p1', suit: CardSuit.spades, rank: CardRank.eight),
      PlayingCard(id: 'r3_d1', suit: CardSuit.clubs, rank: CardRank.six),
      PlayingCard(id: 'r3_p2', suit: CardSuit.hearts, rank: CardRank.eight),
      PlayingCard(id: 'r3_d2', suit: CardSuit.diamonds, rank: CardRank.ten),
      PlayingCard(id: 'r3_s1', suit: CardSuit.spades, rank: CardRank.three),
      PlayingCard(id: 'r3_s2', suit: CardSuit.hearts, rank: CardRank.two),
    ]);
    await tester.pump();

    await tester.tap(find.byKey(const Key('deal_button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Conseil Pro : SÉPARER (8-8 vs 6)'),
      findsOneWidget,
    );

    // Tap SPLIT
    await tester.tap(find.byKey(const Key('split_button')));
    await tester.pumpAndSettle();

    expect(find.text('MAIN 1'), findsOneWidget);
    expect(find.text('MAIN 2'), findsOneWidget);

    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/04_split_hands_88.png',
    );

    // Open Strategy & Rules Sheet and capture screenshot
    await tester.tap(find.byKey(const Key('open_strategy_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('STRATÉGIE DE BASE & RÈGLES DU SABOT'),
      findsOneWidget,
    );

    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/05_strategy_matrix_sheet.png',
    );

    // Close Strategy sheet
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Open Stats & History Sheet and capture screenshot
    await tester.tap(find.byKey(const Key('open_stats_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('STATISTIQUES & JOURNAL DU SABOT'),
      findsOneWidget,
    );

    await _captureEmulatorScreenshot(
      tester,
      boundaryKey,
      'screenshots/06_stats_bankroll_history.png',
    );
  });
}

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/market_haggle/haggle_rubric.dart';
import 'package:lingafriq/games/market_haggle/market_haggle_game.dart';
import 'package:lingafriq/games/market_haggle/market_haggle_screen.dart';
import 'package:lingafriq/games/market_haggle/trader_personalities.dart';

Future<void> pumpMarketHagglePreview(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(390, 640));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: child),
    ),
  );
}

void main() {
  test('price state machine lowers ask after polite greeting', () {
    final trader = kTraderPersonalities.first;
    final state = initialPriceState(
      trader: trader,
      floorPrice: 2000,
      learnerBudget: 2400,
    );
    const polite = HagglePhraseChoice(
      phraseId: 't.polite',
      phraseText: 'Ẹ kú àárọ̀',
      translationEn: 'formal',
      isCorrectRegister: true,
      isPoliteForElder: true,
      isImpoliteForElder: false,
      sourceRef: 'test',
    );
    final after = applyGreetingMove(
      state: state,
      choice: polite,
      trader: trader,
    );
    expect(after.currentAsk, lessThan(state.currentAsk));
  });

  test('impolite greeting raises ask and names phrase in rubric', () {
    final trader = kTraderPersonalities[1];
    final state = initialPriceState(
      trader: trader,
      floorPrice: 2500,
      learnerBudget: 3000,
    );
    const rude = HagglePhraseChoice(
      phraseId: 't.rude',
      phraseText: 'Báwo ni',
      translationEn: 'informal',
      isCorrectRegister: false,
      isPoliteForElder: false,
      isImpoliteForElder: true,
      sourceRef: 'test',
    );
    final afterGreet = applyGreetingMove(
      state: state,
      choice: rude,
      trader: trader,
    );
    expect(afterGreet.currentAsk, greaterThan(state.currentAsk));
    final afterCounter = applyCounterOffer(
      state: afterGreet,
      offerNaira: afterGreet.floorPrice,
    );
    final score = scoreRound(
      finalState: afterCounter,
      greetingChoice: rude,
      counterOffer: afterGreet.floorPrice,
    );
    expect(score.impolitePhraseNamed, 'Báwo ni');
    expect(score.politeness, lessThan(0.5));
  });

  test('parse register yo.json yields choose_register options', () {
    final raw = File('assets/data/units/register/yo.json').readAsStringSync();
    final phrases = parseRegisterPhrasesFromJson(raw);
    expect(phrases.any((p) => p.phraseText.contains('Ẹ kú')), isTrue);
    expect(phrases.any((p) => p.isImpoliteForElder), isTrue);
  });

  test('counter offers stay within budget', () {
    final offers = buildCounterOffers(
      currentAsk: 3200,
      floorPrice: 2000,
      learnerBudget: 2800,
    );
    expect(offers.every((o) => o <= 2800), isTrue);
    expect(offers, isNotEmpty);
  });

  testWidgets('market_haggle_playing golden', (tester) async {
    await pumpMarketHagglePreview(
      tester,
      MarketHagglePreview(
          phaseLabel: 'Playing',
          traderLine: 'Welcome — greet me first.',
          showAi: false,
          ask: 2700,
          body: const Text('Ẹ kú àárọ̀'),
        ),
    );
    await expectLater(
      find.byType(MarketHagglePreview),
      matchesGoldenFile('goldens/market_haggle_playing.png'),
    );
  });

  testWidgets('market_haggle_why_wrong golden', (tester) async {
    await pumpMarketHagglePreview(
      tester,
      MarketHagglePreview(
        phaseLabel: 'Why wrong',
          traderLine: 'That sounded informal.',
          showAi: true,
          ask: 3000,
          body: const Text('Try the honorific greeting before you bargain.'),
        ),
    );
    await expectLater(
      find.byType(MarketHagglePreview),
      matchesGoldenFile('goldens/market_haggle_why_wrong.png'),
    );
  });

  testWidgets('market_haggle_results golden', (tester) async {
    await pumpMarketHagglePreview(
      tester,
      MarketHagglePreview(
        phaseLabel: 'Results',
          traderLine: 'Deal!',
          showAi: false,
          ask: 2200,
          body: Column(
            children: const [
              Text('Goal 100%'),
              Text('Politeness 100%'),
              Text('Correctness 100%'),
            ],
          ),
        ),
    );
    await expectLater(
      find.byType(MarketHagglePreview),
      matchesGoldenFile('goldens/market_haggle_results.png'),
    );
  });

  test('round plan picks two greeting options', () {
    final phrases = kBundledRegisterPhrases['yo']!;
    final plan = buildRoundPlan(
      languageCode: 'yo',
      phrases: phrases,
      rng: Random(1),
    );
    expect(plan.greetingOptions.length, 2);
  });
}

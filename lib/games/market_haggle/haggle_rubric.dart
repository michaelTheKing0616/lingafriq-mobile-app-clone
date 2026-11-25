/// Rubric for Market Haggle rounds (P8-922): goal, politeness, correctness.
library;

import 'market_haggle_game.dart';
import 'trader_personalities.dart';

class HaggleRoundScore {
  const HaggleRoundScore({
    required this.goalAchieved,
    required this.politeness,
    required this.correctness,
    this.impolitePhraseNamed,
  });

  final double goalAchieved;
  final double politeness;
  final double correctness;
  final String? impolitePhraseNamed;

  double get composite =>
      (goalAchieved + politeness + correctness) / 3.0;
}

class PriceHaggleState {
  const PriceHaggleState({
    required this.floorPrice,
    required this.currentAsk,
    required this.learnerBudget,
    required this.dealClosed,
  });

  final int floorPrice;
  final int currentAsk;
  final int learnerBudget;
  final bool dealClosed;

  PriceHaggleState copyWith({
    int? currentAsk,
    bool? dealClosed,
  }) {
    return PriceHaggleState(
      floorPrice: floorPrice,
      currentAsk: currentAsk ?? this.currentAsk,
      learnerBudget: learnerBudget,
      dealClosed: dealClosed ?? this.dealClosed,
    );
  }
}

PriceHaggleState initialPriceState({
  required TraderPersonality trader,
  required int floorPrice,
  required int learnerBudget,
}) {
  return PriceHaggleState(
    floorPrice: floorPrice,
    currentAsk: trader.openingPrice(floorPrice),
    learnerBudget: learnerBudget,
    dealClosed: false,
  );
}

/// After a polite greeting, vendor softens the ask slightly.
PriceHaggleState applyGreetingMove({
  required PriceHaggleState state,
  required HagglePhraseChoice choice,
  required TraderPersonality trader,
}) {
  if (state.dealClosed) return state;
  var ask = state.currentAsk;
  if (choice.isPoliteForElder) {
    ask = (ask * 0.92).round();
  } else if (choice.isImpoliteForElder) {
    ask = (ask * (1 + trader.politenessWeight)).round();
  }
  return state.copyWith(currentAsk: ask);
}

PriceHaggleState applyCounterOffer({
  required PriceHaggleState state,
  required int offerNaira,
}) {
  if (state.dealClosed) return state;
  final closed = offerNaira <= state.currentAsk && offerNaira >= state.floorPrice;
  return state.copyWith(currentAsk: offerNaira, dealClosed: closed);
}

HaggleRoundScore scoreRound({
  required PriceHaggleState finalState,
  required HagglePhraseChoice greetingChoice,
  required int? counterOffer,
}) {
  final goal = finalState.dealClosed && counterOffer != null
      ? (counterOffer <= finalState.learnerBudget ? 1.0 : 0.4)
      : 0.0;

  double politeness = greetingChoice.isPoliteForElder ? 1.0 : 0.35;
  String? impoliteName;
  if (greetingChoice.isImpoliteForElder) {
    politeness = 0.2;
    impoliteName = greetingChoice.phraseText;
  }

  final correctness = greetingChoice.isCorrectRegister ? 1.0 : 0.0;

  return HaggleRoundScore(
    goalAchieved: goal,
    politeness: politeness,
    correctness: correctness,
    impolitePhraseNamed: impoliteName,
  );
}

List<int> buildCounterOffers({
  required int currentAsk,
  required int floorPrice,
  required int learnerBudget,
}) {
  final step = ((currentAsk - floorPrice) / 3).clamp(100, 500).round();
  final offers = <int>[
    (currentAsk - step).clamp(floorPrice, currentAsk),
    (currentAsk - step * 2).clamp(floorPrice, currentAsk),
    floorPrice,
  ];
  return offers
      .where((o) => o <= learnerBudget)
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));
}

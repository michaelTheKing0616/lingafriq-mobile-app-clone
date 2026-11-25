/// Market Haggle flagship logic (P8-922): register phrases, price state, round plan.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'trader_personalities.dart';

/// One learner phrase option sourced from register packs (see [kBundledRegisterPhrases]).
class HagglePhraseChoice {
  const HagglePhraseChoice({
    required this.phraseId,
    required this.phraseText,
    required this.translationEn,
    required this.isCorrectRegister,
    required this.isPoliteForElder,
    required this.isImpoliteForElder,
    required this.sourceRef,
  });

  final String phraseId;
  final String phraseText;
  final String translationEn;
  final bool isCorrectRegister;
  final bool isPoliteForElder;
  final bool isImpoliteForElder;
  final String sourceRef;
}

/// In-app mirror of expert-reviewed register practice rows (assets not in pubspec bundle).
const Map<String, List<HagglePhraseChoice>> kBundledRegisterPhrases = {
  'yo': [
    HagglePhraseChoice(
      phraseId: 'yo.register.greetings_elder#g1.formal',
      phraseText: 'Ẹ kú àárọ̀',
      translationEn: 'Good morning (to elders/group)',
      isCorrectRegister: true,
      isPoliteForElder: true,
      isImpoliteForElder: false,
      sourceRef: 'assets/data/units/register/yo.json#yo.register.greetings_elder',
    ),
    HagglePhraseChoice(
      phraseId: 'yo.register.greetings_elder#g1.informal',
      phraseText: 'Báwo ni',
      translationEn: 'How are you? (informal, peers)',
      isCorrectRegister: false,
      isPoliteForElder: false,
      isImpoliteForElder: true,
      sourceRef: 'assets/data/units/register/yo.json#yo.register.greetings_elder',
    ),
    HagglePhraseChoice(
      phraseId: 'yo.register.honorific_address#h1.formal',
      phraseText: 'Ẹ jọ̀wọ́',
      translationEn: 'Please (honorific)',
      isCorrectRegister: true,
      isPoliteForElder: true,
      isImpoliteForElder: false,
      sourceRef: 'assets/data/units/register/yo.json#yo.register.honorific_address',
    ),
    HagglePhraseChoice(
      phraseId: 'yo.register.honorific_address#h1.informal',
      phraseText: 'Jọ̀wọ́ fún mi',
      translationEn: 'Please (to a peer)',
      isCorrectRegister: false,
      isPoliteForElder: false,
      isImpoliteForElder: true,
      sourceRef: 'assets/data/units/register/yo.json#yo.register.honorific_address',
    ),
  ],
  'ig': [
    HagglePhraseChoice(
      phraseId: 'ig.register.greetings_elder#g1.formal',
      phraseText: 'Ndewo',
      translationEn: 'Formal greeting',
      isCorrectRegister: true,
      isPoliteForElder: true,
      isImpoliteForElder: false,
      sourceRef: 'assets/data/units/register/ig.json',
    ),
    HagglePhraseChoice(
      phraseId: 'ig.register.greetings_elder#g1.informal',
      phraseText: 'Kedu',
      translationEn: 'Informal greeting',
      isCorrectRegister: false,
      isPoliteForElder: false,
      isImpoliteForElder: true,
      sourceRef: 'assets/data/units/register/ig.json',
    ),
  ],
  'ha': [
    HagglePhraseChoice(
      phraseId: 'ha.register.greetings_elder#g1.formal',
      phraseText: 'Sannu da safe',
      translationEn: 'Good morning (respectful)',
      isCorrectRegister: true,
      isPoliteForElder: true,
      isImpoliteForElder: false,
      sourceRef: 'assets/data/units/register/ha.json',
    ),
    HagglePhraseChoice(
      phraseId: 'ha.register.greetings_elder#g1.informal',
      phraseText: 'Ina kwana?',
      translationEn: 'How did you sleep? (informal)',
      isCorrectRegister: false,
      isPoliteForElder: false,
      isImpoliteForElder: true,
      sourceRef: 'assets/data/units/register/ha.json',
    ),
  ],
  'sw': [
    HagglePhraseChoice(
      phraseId: 'sw.register.greetings_elder#g1.formal',
      phraseText: 'Habari za asubuhi',
      translationEn: 'Good morning (formal)',
      isCorrectRegister: true,
      isPoliteForElder: true,
      isImpoliteForElder: false,
      sourceRef: 'assets/data/units/register/sw.json',
    ),
    HagglePhraseChoice(
      phraseId: 'sw.register.greetings_elder#g1.informal',
      phraseText: 'Hujambo',
      translationEn: 'Hello (informal)',
      isCorrectRegister: false,
      isPoliteForElder: false,
      isImpoliteForElder: true,
      sourceRef: 'assets/data/units/register/sw.json',
    ),
  ],
  'pcm': [
    HagglePhraseChoice(
      phraseId: 'pcm.register.greetings_elder#g1.formal',
      phraseText: 'Oga, how you dey?',
      translationEn: 'Polite market greeting',
      isCorrectRegister: true,
      isPoliteForElder: true,
      isImpoliteForElder: false,
      sourceRef: 'assets/data/units/register/pcm.json',
    ),
    HagglePhraseChoice(
      phraseId: 'pcm.register.greetings_elder#g1.informal',
      phraseText: 'How far?',
      translationEn: 'Casual greeting',
      isCorrectRegister: false,
      isPoliteForElder: false,
      isImpoliteForElder: true,
      sourceRef: 'assets/data/units/register/pcm.json',
    ),
  ],
  'zu': [
    HagglePhraseChoice(
      phraseId: 'zu.register.greetings_elder#g1.formal',
      phraseText: 'Sawubona baba',
      translationEn: 'Hello father (respectful)',
      isCorrectRegister: true,
      isPoliteForElder: true,
      isImpoliteForElder: false,
      sourceRef: 'assets/data/units/register/zu.json',
    ),
    HagglePhraseChoice(
      phraseId: 'zu.register.greetings_elder#g1.informal',
      phraseText: 'Unjani?',
      translationEn: 'How are you? (informal)',
      isCorrectRegister: false,
      isPoliteForElder: false,
      isImpoliteForElder: true,
      sourceRef: 'assets/data/units/register/zu.json',
    ),
  ],
  'xh': [
    HagglePhraseChoice(
      phraseId: 'xh.register.greetings_elder#g1.formal',
      phraseText: 'Molo tata',
      translationEn: 'Hello father (respectful)',
      isCorrectRegister: true,
      isPoliteForElder: true,
      isImpoliteForElder: false,
      sourceRef: 'assets/data/units/register/xh.json',
    ),
    HagglePhraseChoice(
      phraseId: 'xh.register.greetings_elder#g1.informal',
      phraseText: 'Unjani?',
      translationEn: 'How are you? (informal)',
      isCorrectRegister: false,
      isPoliteForElder: false,
      isImpoliteForElder: true,
      sourceRef: 'assets/data/units/register/xh.json',
    ),
  ],
};

Future<List<HagglePhraseChoice>> loadHagglePhrasesForLanguage(
  String languageCode,
) async {
  final lang = languageCode.trim().toLowerCase();
  try {
    final raw = await rootBundle.loadString(
      'assets/data/units/register/$lang.json',
    );
    final parsed = parseRegisterPhrasesFromJson(raw);
    if (parsed.isNotEmpty) return parsed;
  } catch (_) {
    // Fall through to bundled mirror.
  }
  return List<HagglePhraseChoice>.from(
    kBundledRegisterPhrases[lang] ?? kBundledRegisterPhrases['yo']!,
  );
}

/// Test hook: parse register JSON from disk in unit tests.
List<HagglePhraseChoice> parseRegisterPhrasesFromJson(String raw) {
  final doc = jsonDecode(raw) as Map<String, dynamic>;
  final units = doc['units'];
  if (units is! List) return const [];
  final out = <HagglePhraseChoice>[];
  for (final unit in units) {
    if (unit is! Map) continue;
    final unitId = unit['id']?.toString() ?? '';
    final items = unit['practice_items'];
    if (items is! List) continue;
    for (final item in items) {
      if (item is! Map) continue;
      if (item['kind'] != 'choose_register') continue;
      final options = item['options'];
      if (options is! List || options.length < 2) continue;
      final correctIndex = item['correct_index'] is int
          ? item['correct_index'] as int
          : 0;
      for (var i = 0; i < options.length; i++) {
        final opt = options[i];
        if (opt is! Map) continue;
        final text = opt['text']?.toString() ?? '';
        if (text.isEmpty) continue;
        final register = opt['register']?.toString() ?? '';
        final isFormal = register == 'formal';
        out.add(
          HagglePhraseChoice(
            phraseId: '$unitId#${item['id']}.$i',
            phraseText: text,
            translationEn: opt['translation_en']?.toString() ?? '',
            isCorrectRegister: i == correctIndex,
            isPoliteForElder: isFormal,
            isImpoliteForElder: !isFormal && i != correctIndex,
            sourceRef: 'assets/data/units/register/$unitId',
          ),
        );
      }
    }
  }
  return out;
}

List<HagglePhraseChoice> pickGreetingOptions({
  required List<HagglePhraseChoice> pool,
  required Random rng,
}) {
  final formal = pool.where((p) => p.isCorrectRegister).toList();
  final informal = pool.where((p) => p.isImpoliteForElder).toList();
  if (formal.isEmpty || informal.isEmpty) {
    return pool.take(2).toList();
  }
  final picks = [formal[rng.nextInt(formal.length)], informal[rng.nextInt(informal.length)]];
  picks.shuffle(rng);
  return picks;
}

class MarketHaggleRoundPlan {
  const MarketHaggleRoundPlan({
    required this.trader,
    required this.floorPrice,
    required this.learnerBudget,
    required this.greetingOptions,
  });

  final TraderPersonality trader;
  final int floorPrice;
  final int learnerBudget;
  final List<HagglePhraseChoice> greetingOptions;
}

MarketHaggleRoundPlan buildRoundPlan({
  required String languageCode,
  required List<HagglePhraseChoice> phrases,
  required Random rng,
  TraderPersonality? trader,
}) {
  final floor = 2000 + rng.nextInt(3) * 500;
  final budget = (floor * 1.15).round();
  final personality = trader ?? kTraderPersonalities[rng.nextInt(kTraderPersonalities.length)];
  return MarketHaggleRoundPlan(
    trader: personality,
    floorPrice: floor,
    learnerBudget: budget,
    greetingOptions: pickGreetingOptions(pool: phrases, rng: rng),
  );
}

/// Scenario lattice for Greeting Gauntlet (P8-928): time × person × setting.
library;

import 'dart:convert';
import 'dart:math';

/// Time-of-day slice for greeting choice.
enum GauntletTimeOfDay {
  morning,
  afternoon,
  evening,
}

/// Who the learner is addressing.
enum GauntletPerson {
  elder,
  peer,
  child,
}

/// Where the encounter happens.
enum GauntletSetting {
  home,
  market,
  street,
}

/// Body-language feedback tied to verified register packs.
enum CulturalGesture {
  kneel,
  bow,
  handshake,
  waveChild,
}

/// One answer line (greeting phrase + optional gesture).
class GauntletChoice {
  const GauntletChoice({
    required this.text,
    required this.translationEn,
    required this.isCorrect,
    required this.gesture,
  });

  final String text;
  final String translationEn;
  final bool isCorrect;
  final CulturalGesture gesture;
}

/// A single timed round.
class GauntletRound {
  const GauntletRound({
    required this.time,
    required this.person,
    required this.setting,
    required this.promptEn,
    required this.choices,
    required this.correctIndex,
    required this.correctGesture,
    required this.whyWrongEn,
    required this.sourceRef,
    required this.culturalReviewFlag,
    required this.correctPhraseForAudio,
  });

  final GauntletTimeOfDay time;
  final GauntletPerson person;
  final GauntletSetting setting;
  final String promptEn;
  final List<GauntletChoice> choices;
  final int correctIndex;
  final CulturalGesture correctGesture;
  final String whyWrongEn;
  final String sourceRef;
  final bool culturalReviewFlag;
  final String correctPhraseForAudio;
}

bool unitIsCulturallyVerified(Map<String, dynamic> unit) {
  if (unit['label']?.toString() != 'expert_reviewed') return false;
  final review = unit['review'];
  if (review is! Map) return false;
  final reviewers = review['reviewers'];
  if (reviewers is! List || reviewers.isEmpty) return false;
  for (final r in reviewers) {
    if (r is Map && r['approved'] == true) return true;
  }
  return false;
}

GauntletPerson personFromAddressee(String? ctx) {
  switch (ctx) {
    case 'peer':
      return GauntletPerson.peer;
    case 'child':
      return GauntletPerson.child;
    default:
      return GauntletPerson.elder;
  }
}

GauntletTimeOfDay timeFromThemes(List<dynamic>? themes, int salt) {
  final t = themes?.map((e) => e.toString()).toList() ?? const [];
  if (t.contains('time_of_day')) {
    return GauntletTimeOfDay.values[salt % GauntletTimeOfDay.values.length];
  }
  return GauntletTimeOfDay.morning;
}

GauntletSetting settingFromThemes(List<dynamic>? themes, int salt) {
  final t = themes?.map((e) => e.toString()).toList() ?? const [];
  if (t.contains('market') || t.contains('commerce')) {
    return GauntletSetting.market;
  }
  if (salt.isEven) return GauntletSetting.home;
  return GauntletSetting.street;
}

/// Language-specific gesture when the learner picks correctly.
CulturalGesture gestureForLanguageAndPerson({
  required String languageCode,
  required GauntletPerson person,
}) {
  final lang = languageCode.trim().toLowerCase();
  if (person == GauntletPerson.child) {
    return CulturalGesture.waveChild;
  }
  if (person == GauntletPerson.peer) {
    return CulturalGesture.handshake;
  }
  switch (lang) {
    case 'yo':
    case 'ig':
      return CulturalGesture.kneel;
    case 'ha':
    case 'sw':
    case 'pcm':
      return CulturalGesture.bow;
    case 'zu':
    case 'xh':
      return CulturalGesture.handshake;
    default:
      return CulturalGesture.bow;
  }
}

String gestureLabel(CulturalGesture gesture) {
  switch (gesture) {
    case CulturalGesture.kneel:
      return 'Respectful kneel';
    case CulturalGesture.bow:
      return 'Respectful bow';
    case CulturalGesture.handshake:
      return 'Warm handshake';
    case CulturalGesture.waveChild:
      return 'Gentle wave';
  }
}

int correctIndexForPerson({
  required GauntletPerson person,
  required int elderCorrectIndex,
  required List<Map<String, dynamic>> options,
}) {
  if (person == GauntletPerson.elder) return elderCorrectIndex;
  for (var i = 0; i < options.length; i++) {
    final reg = options[i]['register']?.toString() ?? '';
    if (reg == 'informal') return i;
  }
  return elderCorrectIndex == 0 ? 1 : 0;
}

String buildPromptEn({
  required GauntletTimeOfDay time,
  required GauntletPerson person,
  required GauntletSetting setting,
  String? itemPrompt,
}) {
  if (itemPrompt != null && itemPrompt.trim().isNotEmpty) {
    return itemPrompt.trim();
  }
  final timeLabel = switch (time) {
    GauntletTimeOfDay.morning => 'morning',
    GauntletTimeOfDay.afternoon => 'afternoon',
    GauntletTimeOfDay.evening => 'evening',
  };
  final who = switch (person) {
    GauntletPerson.elder => 'an elder',
    GauntletPerson.peer => 'a friend your age',
    GauntletPerson.child => 'a young child',
  };
  final where = switch (setting) {
    GauntletSetting.home => 'at home',
    GauntletSetting.market => 'at the market',
    GauntletSetting.street => 'on the street',
  };
  return 'It is $timeLabel $where. Greet $who with the right words and gesture.';
}

String buildWhyWrongEn({
  required GauntletPerson person,
  required String wrongPhrase,
  required String correctPhrase,
  required CulturalGesture expectedGesture,
}) {
  final gesture = gestureLabel(expectedGesture).toLowerCase();
  if (person == GauntletPerson.elder) {
    return '"$wrongPhrase" sounds too casual for an elder. Say "$correctPhrase" and show a $gesture.';
  }
  if (person == GauntletPerson.peer) {
    return '"$wrongPhrase" is overly formal with a peer. Try "$correctPhrase" and a $gesture.';
  }
  return 'Children appreciate a light tone. "$correctPhrase" with a $gesture fits better than "$wrongPhrase".';
}

/// Builds only rounds with expert-reviewed register items (AC3).
List<GauntletRound> buildVerifiedScenarioMatrix({
  required String languageCode,
  required String registerJsonRaw,
  Random? rng,
}) {
  final random = rng ?? Random();
  final doc = _decode(registerJsonRaw);
  final units = doc['units'];
  if (units is! List) return const [];

  final rounds = <GauntletRound>[];
  var salt = 0;

  for (final unit in units) {
    if (unit is! Map<String, dynamic>) continue;
    if (!unitIsCulturallyVerified(unit)) continue;
    final items = unit['practice_items'];
    if (items is! List) continue;
    final themes = unit['themes'] as List<dynamic>?;
    final basePerson = personFromAddressee(unit['addressee_context']?.toString());
    final unitId = unit['id']?.toString() ?? 'register.unit';
    final riskTags = unit['risk_tags'] as List<dynamic>? ?? const [];
    final culturalReviewFlag = riskTags.contains('honorific_register');

    for (final item in items) {
      if (item is! Map) continue;
      if (item['kind'] != 'choose_register') continue;
      final options = item['options'];
      if (options is! List || options.length < 2) continue;
      final opts = options.whereType<Map<String, dynamic>>().toList();
      if (opts.length < 2) continue;
      final elderCorrect = item['correct_index'] is int
          ? item['correct_index'] as int
          : 0;
      if (elderCorrect < 0 || elderCorrect >= opts.length) continue;

      for (final person in GauntletPerson.values) {
        if (person == GauntletPerson.child && basePerson != GauntletPerson.elder) {
          continue;
        }
        final correctIdx = correctIndexForPerson(
          person: person,
          elderCorrectIndex: elderCorrect,
          options: opts,
        );
        final time = timeFromThemes(themes, salt);
        final setting = settingFromThemes(themes, salt);
        salt++;
        final gesture = gestureForLanguageAndPerson(
          languageCode: languageCode,
          person: person,
        );
        final correctPhrase = opts[correctIdx]['text']?.toString() ?? '';
        if (correctPhrase.isEmpty) continue;

        final choices = <GauntletChoice>[];
        for (var i = 0; i < opts.length; i++) {
          final opt = opts[i];
          final text = opt['text']?.toString() ?? '';
          if (text.isEmpty) continue;
          final choiceGesture = i == correctIdx
              ? gesture
              : gestureForLanguageAndPerson(
                  languageCode: languageCode,
                  person: GauntletPerson.elder,
                );
          choices.add(
            GauntletChoice(
              text: text,
              translationEn: opt['translation_en']?.toString() ?? '',
              isCorrect: i == correctIdx,
              gesture: choiceGesture,
            ),
          );
        }
        if (choices.length < 2) continue;

        final wrongIdx = choices.indexWhere((c) => !c.isCorrect);
        final wrongPhrase = wrongIdx >= 0 ? choices[wrongIdx].text : '';
        rounds.add(
          GauntletRound(
            time: time,
            person: person,
            setting: setting,
            promptEn: buildPromptEn(
              time: time,
              person: person,
              setting: setting,
              itemPrompt: item['prompt_en']?.toString(),
            ),
            choices: choices,
            correctIndex: correctIdx,
            correctGesture: gesture,
            whyWrongEn: buildWhyWrongEn(
              person: person,
              wrongPhrase: wrongPhrase,
              correctPhrase: correctPhrase,
              expectedGesture: gesture,
            ),
            sourceRef: 'assets/data/units/register/$unitId#${item['id']}',
            culturalReviewFlag: culturalReviewFlag,
            correctPhraseForAudio: correctPhrase,
          ),
        );
      }
    }
  }

  rounds.shuffle(random);
  return rounds;
}

Map<String, dynamic> _decode(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return const {};
}

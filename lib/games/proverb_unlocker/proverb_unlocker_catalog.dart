import 'dart:math';

/// Live Proverb Unlocker fallback rows from
/// `lib/screens/games/cultural/proverb_unlocker_game.dart`.
///
/// Text is copied from that tablet. Nothing here is a new proverb.
class HarvestedProverb {
  final int id;
  final String language;
  final String original;
  final String translation;
  final String meaning;
  final String cefr;

  const HarvestedProverb({
    required this.id,
    required this.language,
    required this.original,
    required this.translation,
    required this.meaning,
    required this.cefr,
  });
}

const List<HarvestedProverb> kHarvestedProverbUnlockerCatalog = [
  HarvestedProverb(
    id: 1,
    language: 'Yoruba',
    original: 'Agbara eniyan ju ti eranko lo',
    translation: 'Human strength surpasses that of animals',
    meaning: 'Unity and intelligence overcome brute force',
    cefr: 'A1',
  ),
  HarvestedProverb(
    id: 2,
    language: 'Swahili',
    original: 'Haraka haraka haina baraka',
    translation: 'Hurry hurry has no blessing',
    meaning: 'Patience leads to better outcomes',
    cefr: 'A1',
  ),
  HarvestedProverb(
    id: 3,
    language: 'Zulu',
    original: 'Umuntu ngumuntu ngabantu',
    translation: 'A person is a person through people',
    meaning: 'Humanity is defined by community',
    cefr: 'A1',
  ),
  HarvestedProverb(
    id: 4,
    language: 'Igbo',
    original: 'Onye aghana nwanne ya',
    translation: "Be your brother's keeper",
    meaning: 'Look after each other always',
    cefr: 'A1',
  ),
  HarvestedProverb(
    id: 5,
    language: 'Xhosa',
    original: 'Umntu ngumntu ngabantu',
    translation: 'I am because we are',
    meaning: 'Individual identity is rooted in collective belonging',
    cefr: 'A1',
  ),
  HarvestedProverb(
    id: 6,
    language: 'Amharic',
    original: 'Sew besew yinoralal',
    translation: 'People live through people',
    meaning: 'Community support sustains life',
    cefr: 'A1',
  ),
];

/// One seeded unlocker round. Proverb, blanks, tokens, and meaning choices
/// all come from [Random] constructed with [seed].
class ProverbUnlockerDeal {
  final HarvestedProverb proverb;
  final List<String> words;
  final List<int> blankIndices;
  final List<String> tokenOptions;
  final List<String> options;
  final String correctAnswer;
  final int seed;
  final int roundIndex;

  const ProverbUnlockerDeal({
    required this.proverb,
    required this.words,
    required this.blankIndices,
    required this.tokenOptions,
    required this.options,
    required this.correctAnswer,
    required this.seed,
    required this.roundIndex,
  });
}

class ProverbUnlockerOutcome {
  final bool correct;
  final String proverb;
  final String correctAnswer;

  const ProverbUnlockerOutcome({
    required this.correct,
    required this.proverb,
    required this.correctAnswer,
  });
}

/// Stable seed for a language and level. Not [String.hashCode], which changes
/// between VM runs.
int proverbUnlockerStableSeed(String language, String? level) {
  final input = '${language.trim().toLowerCase()}|${(level ?? '').trim()}';
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

String harvestedProverbMeaning(HarvestedProverb proverb) {
  final meaning = proverb.meaning.trim();
  if (meaning.isNotEmpty) return meaning;
  return proverb.translation;
}

List<HarvestedProverb> proverbsForLanguage(
  List<HarvestedProverb> catalog,
  String? language,
) {
  final want = language?.trim().toLowerCase() ?? '';
  if (want.isEmpty) return List<HarvestedProverb>.of(catalog);
  final filtered = catalog
      .where((proverb) => proverb.language.toLowerCase() == want)
      .toList();
  if (filtered.isEmpty) return List<HarvestedProverb>.of(catalog);
  return filtered;
}

/// Seeded replacement for the live tablet's shuffle, blank picker, and token
/// order. Meaning choices are other harvested meanings, not invented lines.
ProverbUnlockerDeal dealProverbUnlocker({
  required int seed,
  List<HarvestedProverb>? catalog,
  String? language,
  int roundIndex = 0,
}) {
  final source = catalog ?? kHarvestedProverbUnlockerCatalog;
  if (source.isEmpty) {
    throw ArgumentError('proverb catalog is empty');
  }
  final pool = proverbsForLanguage(source, language);
  final rng = Random(seed);
  final ordered = List<HarvestedProverb>.of(pool)..shuffle(rng);
  final session = ordered.length > 6
      ? List<HarvestedProverb>.of(ordered.sublist(0, 6))
      : ordered;
  final index = roundIndex < 0 ? 0 : roundIndex % session.length;
  final proverb = session[index];
  final words = proverb.original.split(' ');
  final blankCount = words.length > 5 ? 2 : 1;
  final blanks = <int>{};
  while (blanks.length < blankCount && blanks.length < words.length) {
    blanks.add(rng.nextInt(words.length));
  }
  final blankIndices = blanks.toList()..sort();
  final correctTokens = blankIndices.map((i) => words[i]).toList();
  final distractors = <String>[];
  final distractorTarget = 5 - correctTokens.length;
  if (distractorTarget > 0) {
    for (final entry in session) {
      for (final word in entry.original.split(' ')) {
        if (!correctTokens.contains(word) && !distractors.contains(word)) {
          distractors.add(word);
        }
        if (distractors.length >= distractorTarget) break;
      }
      if (distractors.length >= distractorTarget) break;
    }
  }
  final tokenOptions = <String>[
    ...correctTokens,
    ...distractors.take(distractorTarget < 0 ? 0 : distractorTarget),
  ]..shuffle(rng);

  final correctAnswer = harvestedProverbMeaning(proverb);
  final otherMeanings = <String>[];
  for (final entry in source) {
    final meaning = harvestedProverbMeaning(entry);
    if (meaning == correctAnswer || otherMeanings.contains(meaning)) continue;
    otherMeanings.add(meaning);
    if (otherMeanings.length >= 3) break;
  }
  final options = <String>[correctAnswer, ...otherMeanings]..shuffle(rng);

  return ProverbUnlockerDeal(
    proverb: proverb,
    words: List<String>.unmodifiable(words),
    blankIndices: List<int>.unmodifiable(blankIndices),
    tokenOptions: List<String>.unmodifiable(tokenOptions),
    options: List<String>.unmodifiable(options),
    correctAnswer: correctAnswer,
    seed: seed,
    roundIndex: index,
  );
}

bool proverbFillsAreCorrect(
  ProverbUnlockerDeal deal,
  Map<int, String> fills,
) {
  if (deal.blankIndices.isEmpty) return false;
  for (final index in deal.blankIndices) {
    if (index < 0 || index >= deal.words.length) return false;
    if (fills[index] != deal.words[index]) return false;
  }
  return true;
}

ProverbUnlockerOutcome resolveProverbUnlockerOutcome({
  required String proverb,
  required String correctAnswer,
  required List<int> blankIndices,
  required List<String> words,
  required String selectedAnswer,
  Map<int, String> fills = const {},
}) {
  final bool correct;
  if (fills.isNotEmpty) {
    correct = blankIndices.isNotEmpty &&
        blankIndices.every(
          (index) =>
              index >= 0 &&
              index < words.length &&
              fills[index] == words[index],
        );
  } else {
    correct = selectedAnswer == correctAnswer;
  }
  return ProverbUnlockerOutcome(
    correct: correct,
    proverb: proverb,
    correctAnswer: correctAnswer,
  );
}

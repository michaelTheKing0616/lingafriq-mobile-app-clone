import 'proverb_unlocker_catalog.dart';

class ProverbUnlockerContent {
  final String proverb;
  final String translation;
  final String meaning;
  final String context;
  final List<String> options;
  final String correctAnswer;
  final String contentId;
  final List<String> words;
  final List<int> blankIndices;
  final List<String> tokenOptions;
  final int seed;

  const ProverbUnlockerContent({
    required this.proverb,
    required this.translation,
    required this.meaning,
    required this.context,
    required this.options,
    required this.correctAnswer,
    required this.contentId,
    required this.words,
    required this.blankIndices,
    required this.tokenOptions,
    required this.seed,
  });

  factory ProverbUnlockerContent.fromDeal(ProverbUnlockerDeal deal) {
    final meaning = deal.correctAnswer;
    return ProverbUnlockerContent(
      proverb: deal.proverb.original,
      translation: deal.proverb.translation,
      meaning: meaning,
      context: meaning,
      options: deal.options,
      correctAnswer: meaning,
      contentId: 'proverb_${deal.proverb.id}_s${deal.seed}_r${deal.roundIndex}',
      words: deal.words,
      blankIndices: deal.blankIndices,
      tokenOptions: deal.tokenOptions,
      seed: deal.seed,
    );
  }
}

class ProverbUnlockerInput {
  final String selectedAnswer;
  final Map<int, String> fills;

  const ProverbUnlockerInput({
    required this.selectedAnswer,
    this.fills = const {},
  });
}

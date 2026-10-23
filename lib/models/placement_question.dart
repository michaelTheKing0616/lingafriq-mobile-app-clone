class PlacementQuestion {
  final String id;
  final String languageCode; // e.g. "yoruba", "swahili"
  final String level; // CEFR-ish: A1, A2, B1, B2
  final String skill; // "vocab", "grammar", "listening", "reading"
  final String prompt;
  final List<String> options;
  final int correctIndex;

  const PlacementQuestion({
    required this.id,
    required this.languageCode,
    required this.level,
    required this.skill,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });
}

class PlacementResult {
  final String languageCode;
  final String level;
  final double score;
  final int totalQuestions;
  final int correct;
  final bool provisional;
  final double? ability;
  final double? intervalLow;
  final double? intervalHigh;

  const PlacementResult({
    required this.languageCode,
    required this.level,
    required this.score,
    required this.totalQuestions,
    required this.correct,
    this.provisional = false,
    this.ability,
    this.intervalLow,
    this.intervalHigh,
  });

  Map<String, dynamic> toMap() => {
        'language': languageCode,
        'level': level,
        'score': score,
        'totalQuestions': totalQuestions,
        'correct': correct,
        'provisional': provisional,
        if (ability != null) 'ability': ability,
        if (intervalLow != null) 'interval_low': intervalLow,
        if (intervalHigh != null) 'interval_high': intervalHigh,
      };
}



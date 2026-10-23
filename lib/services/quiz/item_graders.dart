/// Grades item-bank answers. No random value is used.
class AnswerSpec {
  const AnswerSpec({
    required this.correct,
    required this.variants,
    required this.diacriticInsensitive,
  });

  final String correct;
  final List<String> variants;
  final bool diacriticInsensitive;
}

class ItemGrade {
  const ItemGrade({required this.correct});

  final bool correct;

  String get phase => correct ? 'answered-correct' : 'answered-wrong';
}

class ItemCopy {
  static const listen = 'Play the clip';
  static const tone = 'Which tone pattern is this?';
  static const picture = 'Which picture matches?';
  static const correct = "That's the one.";
  static const wrong = 'Not that one.';
  static const audioError = 'The clip did not play.';
  static const retry = 'Try the clip again';
  static const playing = 'Playing';
}

const _baseLetters = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ā': 'a', 'ǎ': 'a', 'ạ': 'a', 'ả': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ẹ': 'e', 'ẻ': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'ị': 'i', 'ỉ': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'ō': 'o', 'ọ': 'o', 'ỏ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ụ': 'u', 'ủ': 'u',
  'ń': 'n', 'ñ': 'n', 'ṅ': 'n', 'ṇ': 'n',
  'ṣ': 's', 'ś': 's',
  'À': 'a', 'Á': 'a', 'Â': 'a', 'Ä': 'a', 'Ā': 'a', 'Ạ': 'a',
  'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e', 'Ē': 'e', 'Ẹ': 'e',
  'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i', 'Ī': 'i', 'Ị': 'i',
  'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Ö': 'o', 'Ō': 'o', 'Ọ': 'o',
  'Ù': 'u', 'Ú': 'u', 'Û': 'u', 'Ü': 'u', 'Ū': 'u', 'Ụ': 'u',
  'Ń': 'n', 'Ñ': 'n', 'Ṅ': 'n', 'Ṣ': 's',
};

String foldAnswer(String value, {required bool diacriticInsensitive}) {
  final trimmed = value.trim();
  if (!diacriticInsensitive) return trimmed;
  final buffer = StringBuffer();
  for (final rune in trimmed.runes) {
    if (rune >= 0x300 && rune <= 0x36F) continue;
    final char = String.fromCharCode(rune);
    buffer.write(_baseLetters[char] ?? char.toLowerCase());
  }
  return buffer.toString();
}

ItemGrade gradeAnswer({
  required String response,
  required AnswerSpec spec,
}) {
  final folded = foldAnswer(response, diacriticInsensitive: spec.diacriticInsensitive);
  if (folded.isEmpty) return const ItemGrade(correct: false);
  final accepted = [spec.correct, ...spec.variants];
  for (final candidate in accepted) {
    if (foldAnswer(candidate, diacriticInsensitive: spec.diacriticInsensitive) == folded) {
      return const ItemGrade(correct: true);
    }
  }
  return const ItemGrade(correct: false);
}

/// Tone items are graded only against the lexeme [tonePattern].
ItemGrade gradeTone({
  required List<String> chosen,
  required List<String> tonePattern,
}) {
  if (tonePattern.isEmpty || chosen.length != tonePattern.length) {
    return const ItemGrade(correct: false);
  }
  for (var index = 0; index < tonePattern.length; index++) {
    final expected = tonePattern[index].trim().toUpperCase();
    final got = chosen[index].trim().toUpperCase();
    if (expected.isEmpty || got != expected) return const ItemGrade(correct: false);
  }
  return const ItemGrade(correct: true);
}

ItemGrade gradePicture({
  required String chosenId,
  required AnswerSpec spec,
}) {
  return gradeAnswer(response: chosenId, spec: spec);
}

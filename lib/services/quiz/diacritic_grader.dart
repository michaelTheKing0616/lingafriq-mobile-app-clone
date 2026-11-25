import 'item_graders.dart';

class DictationGrade {
  const DictationGrade({
    required this.passed,
    required this.full,
    required this.lettersMatch,
  });

  final bool passed;
  final bool full;
  final bool lettersMatch;

  String get phase {
    if (full) return 'correct';
    if (lettersMatch || passed) return 'diacritic-hint';
    return 'wrong';
  }
}

class ItemBuildCopy {
  static const dictation = 'Type what you hear';
  static const build = 'Put the words in order';
  static const diacriticHint = 'The letters match. Add the tone marks.';
  static const variantHint = 'That spelling is accepted. The tone marks are still the full form.';
  static const correct = "That's the one.";
  static const wrong = 'Not that one.';
  static const lowTone = 'Low tone mark';
  static const highTone = 'High tone mark';
  static const midTone = 'Mid tone mark';
  static const dotBelow = 'Dot below';
}

const _composed = <String, String>{
  'a\u0300': 'à', 'a\u0301': 'á', 'a\u0304': 'ā', 'a\u0323': 'ạ',
  'e\u0300': 'è', 'e\u0301': 'é', 'e\u0304': 'ē', 'e\u0323': 'ẹ',
  'i\u0300': 'ì', 'i\u0301': 'í', 'i\u0304': 'ī', 'i\u0323': 'ị',
  'o\u0300': 'ò', 'o\u0301': 'ó', 'o\u0304': 'ō', 'o\u0323': 'ọ',
  'u\u0300': 'ù', 'u\u0301': 'ú', 'u\u0304': 'ū', 'u\u0323': 'ụ',
  'n\u0301': 'ń', 'n\u0303': 'ñ', 's\u0323': 'ṣ',
  'A\u0300': 'À', 'A\u0301': 'Á', 'E\u0301': 'É', 'O\u0323': 'Ọ', 'E\u0323': 'Ẹ',
};

/// Compose one known combining mark so a decomposed answer matches its NFC form.
String nfc(String value) {
  final buffer = StringBuffer();
  final units = value.runes.toList();
  var index = 0;
  while (index < units.length) {
    final current = String.fromCharCode(units[index]);
    if (index + 1 < units.length) {
      final next = String.fromCharCode(units[index + 1]);
      final pair = _composed['$current$next'];
      if (pair != null) {
        buffer.write(pair);
        index += 2;
        continue;
      }
    }
    buffer.write(current);
    index += 1;
  }
  return buffer.toString();
}

DictationGrade gradeDictation({
  required String response,
  required String correct,
  required List<String> asciiVariants,
}) {
  final got = nfc(response.trim());
  final expected = nfc(correct.trim());
  if (got.isEmpty) {
    return const DictationGrade(passed: false, full: false, lettersMatch: false);
  }
  if (got == expected) {
    return const DictationGrade(passed: true, full: true, lettersMatch: true);
  }
  for (final variant in asciiVariants) {
    if (got == nfc(variant.trim()) && got.isNotEmpty) {
      return const DictationGrade(passed: true, full: false, lettersMatch: true);
    }
  }
  final lettersMatch = foldAnswer(got, diacriticInsensitive: true) ==
      foldAnswer(expected, diacriticInsensitive: true);
  return DictationGrade(passed: false, full: false, lettersMatch: lettersMatch);
}

bool sentenceAccepted(List<String> order, List<List<String>> accepted) {
  final got = [for (final token in order) nfc(token.trim())];
  for (final option in accepted) {
    if (option.length != got.length) continue;
    var matches = true;
    for (var index = 0; index < got.length; index++) {
      if (nfc(option[index].trim()) != got[index]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

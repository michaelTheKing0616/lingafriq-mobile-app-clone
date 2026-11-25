import 'package:lingafriq/services/quiz/diacritic_grader.dart';
import 'package:lingafriq/services/quiz/item_graders.dart';

/// Item-bank diacritic rule (v2 `answer_spec.diacritic_matching`).
enum DiacriticMatching {
  strict,
  toneLenient,
  diacriticInsensitive,
}

DiacriticMatching parseDiacriticMatching(String raw) {
  switch (raw.trim()) {
    case 'strict':
      return DiacriticMatching.strict;
    case 'tone_lenient':
      return DiacriticMatching.toneLenient;
    case 'diacritic_insensitive':
      return DiacriticMatching.diacriticInsensitive;
    default:
      throw ArgumentError.value(raw, 'raw', 'unknown diacritic_matching');
  }
}

class V2AnswerSpec {
  const V2AnswerSpec({
    required this.correct,
    required this.acceptedVariants,
    required this.diacriticMatching,
  });

  final String correct;
  final List<String> acceptedVariants;
  final DiacriticMatching diacriticMatching;
}

/// Path-band thresholds: tone marks may be ignored through this level (inclusive).
class DiacriticGradingPolicy {
  const DiacriticGradingPolicy({required this.toneLenientThroughLevel});

  static const defaults = DiacriticGradingPolicy(toneLenientThroughLevel: 2);

  final int toneLenientThroughLevel;
}

class AnswerMatchResult {
  const AnswerMatchResult({
    required this.accepted,
    required this.fullyCorrect,
    required this.displayCorrect,
  });

  final bool accepted;
  final bool fullyCorrect;

  /// Canonical marked form (EP-§6.7-09).
  final String displayCorrect;

  String get phase {
    if (fullyCorrect) return 'correct';
    if (accepted) return 'diacritic-hint';
    return 'wrong';
  }
}

/// Strips tone marks but keeps teaching diacritics (dot-below, hooked letters).
const _toneStripped = <String, String>{
  'à': 'a', 'á': 'a', 'ā': 'a', 'ǎ': 'a', 'ả': 'a',
  'è': 'e', 'é': 'e', 'ē': 'e', 'ẻ': 'e',
  'ì': 'i', 'í': 'i', 'ī': 'i', 'ỉ': 'i',
  'ò': 'o', 'ó': 'o', 'ō': 'o', 'ỏ': 'o',
  'ù': 'u', 'ú': 'u', 'ū': 'u', 'ủ': 'u',
  'À': 'A', 'Á': 'A', 'Ā': 'A',
  'È': 'E', 'É': 'E', 'Ē': 'E',
  'Ì': 'I', 'Í': 'I', 'Ī': 'I',
  'Ò': 'O', 'Ó': 'O', 'Ō': 'O',
  'Ù': 'U', 'Ú': 'U', 'Ū': 'U',
  'ń': 'n', 'Ń': 'N',
};

String foldToneLenient(String value) {
  final buffer = StringBuffer();
  for (final rune in nfc(value.trim()).runes) {
    final char = String.fromCharCode(rune);
    if (rune >= 0x300 && rune <= 0x36F) continue;
    buffer.write(_toneStripped[char] ?? char);
  }
  return buffer.toString();
}

bool _isAsciiFallback(String value) {
  for (final rune in value.runes) {
    if (rune > 0x7F) return false;
  }
  return value.isNotEmpty;
}

bool _matchesCandidate(String got, String candidate, DiacriticMatching mode, {required bool toneLenientActive}) {
  final expected = nfc(candidate.trim());
  if (got == expected) return true;
  switch (mode) {
    case DiacriticMatching.diacriticInsensitive:
      return foldAnswer(got, diacriticInsensitive: true) ==
          foldAnswer(expected, diacriticInsensitive: true);
    case DiacriticMatching.toneLenient:
      if (!toneLenientActive) return false;
      if (_isAsciiFallback(got) && !_isAsciiFallback(expected)) return false;
      return foldToneLenient(got) == foldToneLenient(expected);
    case DiacriticMatching.strict:
      return false;
  }
}

AnswerMatchResult matchLearnerAnswer({
  required String response,
  required V2AnswerSpec spec,
  required int learnerLevel,
  DiacriticGradingPolicy policy = DiacriticGradingPolicy.defaults,
}) {
  final displayCorrect = spec.correct;
  final got = nfc(response.trim());
  if (got.isEmpty) {
    return AnswerMatchResult(
      accepted: false,
      fullyCorrect: false,
      displayCorrect: displayCorrect,
    );
  }

  final toneLenientActive = spec.diacriticMatching == DiacriticMatching.toneLenient &&
      learnerLevel <= policy.toneLenientThroughLevel;

  final candidates = [spec.correct, ...spec.acceptedVariants];
  for (final candidate in candidates) {
    final normalized = nfc(candidate.trim());
    if (got == normalized) {
      final fully = normalized == nfc(spec.correct.trim());
      return AnswerMatchResult(
        accepted: true,
        fullyCorrect: fully,
        displayCorrect: displayCorrect,
      );
    }
  }

  final mode = spec.diacriticMatching;
  if (mode == DiacriticMatching.diacriticInsensitive) {
    for (final candidate in candidates) {
      if (_matchesCandidate(got, candidate, mode, toneLenientActive: false)) {
        final fully = nfc(candidate.trim()) == nfc(spec.correct.trim());
        return AnswerMatchResult(
          accepted: true,
          fullyCorrect: fully,
          displayCorrect: displayCorrect,
        );
      }
    }
  } else if (mode == DiacriticMatching.toneLenient && toneLenientActive) {
    for (final candidate in candidates) {
      if (_matchesCandidate(got, candidate, mode, toneLenientActive: true)) {
        return AnswerMatchResult(
          accepted: true,
          fullyCorrect: false,
          displayCorrect: displayCorrect,
        );
      }
    }
  }

  return AnswerMatchResult(
    accepted: false,
    fullyCorrect: false,
    displayCorrect: displayCorrect,
  );
}

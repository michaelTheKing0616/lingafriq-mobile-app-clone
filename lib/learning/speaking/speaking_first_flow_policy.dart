/// Speaking-first lesson flow and Polie feedback shape (P5-038, EP-§6.2-11/12).
///
/// Session 1 opens with production; Polie negotiates meaning via recasts, not
/// grammar lectures; lesson screens stay within text budgets (not text-heavy).
library;

/// Ordered lesson interaction kinds for A1 speaking-first paths.
enum LessonInteractionKind {
  speak,
  listen,
  choose,
  readPassage,
  build,
  translate,
}

/// How Polie may respond after a learner error.
enum PolieCorrectionStyle {
  recast,
  ruleDump,
  explicitMarking,
}

/// Default step plan for the learner's first session (AC1).
const List<LessonInteractionKind> sessionOneSpeakingFirstPlan = [
  LessonInteractionKind.speak,
  LessonInteractionKind.listen,
  LessonInteractionKind.choose,
  LessonInteractionKind.speak,
];

/// First interaction for a numbered session (1 = first ever).
LessonInteractionKind firstInteractionForSession(int sessionNumber) {
  if (sessionNumber <= 0) {
    throw ArgumentError.value(sessionNumber, 'sessionNumber', 'must be positive');
  }
  if (sessionNumber == 1) {
    return LessonInteractionKind.speak;
  }
  return LessonInteractionKind.listen;
}

/// Whether a planned sequence satisfies session-1 speak-first (AC1).
bool sessionOneStartsWithSpeak(List<LessonInteractionKind> plannedSteps) {
  if (plannedSteps.isEmpty) return false;
  return plannedSteps.first == LessonInteractionKind.speak;
}

/// Polie must not use rule-dump or red-mark styles on errors (AC2).
bool polieErrorStyleAllowed(PolieCorrectionStyle style) =>
    style == PolieCorrectionStyle.recast;

/// Heuristic guard for grammar-lecture replies (studio preview / tests).
bool looksLikeGrammarRuleDump(String reply) {
  final lower = reply.toLowerCase();
  const bannedFragments = [
    'the rule is',
    'grammar rule',
    'conjugat',
    'you must use',
    'incorrect because',
    'past tense of',
    'subject-verb',
    'marked wrong',
    'the correct form is',
  ];
  return bannedFragments.any(lower.contains);
}

/// A recast models the target form without a rule dump (AC2).
bool isRecastReply({
  required String reply,
  required String targetLanguageExcerpt,
}) {
  if (targetLanguageExcerpt.isEmpty) return false;
  if (looksLikeGrammarRuleDump(reply)) return false;
  return reply.contains(targetLanguageExcerpt);
}

/// Per-screen text limits for A1 speaking-first layouts (AC3).
class SpeakingScreenTextBudget {
  const SpeakingScreenTextBudget({
    this.maxInstructionWords = 18,
    this.maxBodyWords = 42,
    this.maxTotalWords = 55,
  });

  final int maxInstructionWords;
  final int maxBodyWords;
  final int maxTotalWords;
}

int _wordCount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}

/// True when copy exceeds the speaking-first budget (AC3).
bool screenIsTextHeavy({
  required String instructionText,
  required String bodyText,
  SpeakingScreenTextBudget budget = const SpeakingScreenTextBudget(),
}) {
  final instructionWords = _wordCount(instructionText);
  final bodyWords = _wordCount(bodyText);
  final total = instructionWords + bodyWords;
  if (instructionWords > budget.maxInstructionWords) return true;
  if (bodyWords > budget.maxBodyWords) return true;
  if (total > budget.maxTotalWords) return true;
  return false;
}

/// Moves the first speak beat before [readPassage] when reordering a unit.
List<LessonInteractionKind> orderSpeakingBeforeReading(
  List<LessonInteractionKind> steps,
) {
  if (steps.isEmpty) return steps;
  final out = List<LessonInteractionKind>.from(steps);
  final readIndex = out.indexOf(LessonInteractionKind.readPassage);
  final speakIndex = out.indexOf(LessonInteractionKind.speak);
  if (speakIndex < 0 || readIndex < 0 || speakIndex < readIndex) {
    return out;
  }
  final speak = out.removeAt(speakIndex);
  out.insert(readIndex, speak);
  return out;
}

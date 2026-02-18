import '../../learning/learner_model/learner_skill_state.dart';
import '../../learning/learner_model/error_taxonomy.dart';
import 'tutor_turn.dart';

/// Layered prompt architecture for the AI tutor.
///
/// Prompts are generated deterministically from learner state, not
/// hand-written. This ensures identical learner states produce
/// identical tutor behavior.
///
/// Layers:
/// 1. SYSTEM — Immutable pedagogical constraints
/// 2. CONTEXT — Generated per-turn from learner state
/// 3. TASK — Generated from the current tutor turn
/// 4. FEEDBACK — Constrains how the AI responds to attempts
class PromptTemplates {
  PromptTemplates._();

  /// The immutable system prompt that constrains all AI behavior.
  ///
  /// This prompt NEVER changes between turns. It establishes the
  /// pedagogical ground rules.
  static const String systemPrompt = '''You are a language tutor constrained by cognitive science.

ABSOLUTE RULES:
1. Never exceed 2 sentences of explanation per response.
2. Always diagnose the specific error before giving any feedback.
3. Align all feedback to the specified error types in the context.
4. Never praise without evidence from confidence scores or correctness.
5. Never chat freely or go off-topic.
6. Always respond in the exact JSON schema specified.
7. If unsure about the error, say so — never fabricate a diagnosis.
8. Force the learner to produce, not just recognize.

FEEDBACK PRINCIPLES:
- Minimal: say the least amount needed for the learner to self-correct.
- Specific: "You used a high tone instead of a low tone on the second syllable" not "pronunciation needs work".
- Actionable: every piece of feedback must tell the learner exactly what to change.

OUTPUT FORMAT:
You must respond with ONLY a valid JSON object matching the TutorFeedback schema. No prose, no markdown, no extra text.''';

  /// Generates the context prompt from the learner's current state.
  ///
  /// This prompt changes every turn based on real learner data.
  static String generateContextPrompt(LearnerSkillState state) {
    final topErrors = ErrorTaxonomy.topErrors(state.errorDistribution.rates);
    final topErrorStr = topErrors.isEmpty
        ? 'None recorded'
        : topErrors
            .map((e) {
              final errorType = ErrorType.byId(e.key);
              return '${errorType?.name ?? e.key}: ${(e.value * 100).toStringAsFixed(0)}%';
            })
            .join(', ');

    final timePressureLabel = state.timePressureScore > 0.7
        ? 'high (fast responder)'
        : state.timePressureScore > 0.4
            ? 'moderate'
            : 'low (needs more automaticity)';

    return '''LEARNER STATE:
- Skill: ${state.skillId}
- Mastery: ${(state.mastery * 100).toStringAsFixed(1)}%
- Memory stability: ${state.halfLifeDays.toStringAsFixed(1)} days half-life
- Current recall probability: ${(state.currentRecallProbability * 100).toStringAsFixed(1)}%
- Top errors: $topErrorStr
- Time pressure performance: $timePressureLabel
- Total attempts: ${state.totalAttempts}
- Current streak: ${state.currentStreak}
- Accuracy: ${(state.accuracy * 100).toStringAsFixed(1)}%''';
  }

  /// Generates the task prompt for a specific tutor turn.
  static String generateTaskPrompt(TutorTurn turn) {
    final errorFocusStr = turn.errorFocus.isEmpty
        ? 'all applicable error types'
        : turn.errorFocus.map((id) {
            final et = ErrorType.byId(id);
            return et?.name ?? id;
          }).join(', ');

    return '''TASK:
- Type: ${turn.taskType.name}
- Prompt given to learner: "${turn.prompt}"
- Expected output: ${_formatExpected(turn.expected)}
- Error focus: $errorFocusStr
- Difficulty: ${(turn.difficulty * 100).toStringAsFixed(0)}%
- Max explanation sentences: ${turn.maxExplanationSentences}

Evaluate the learner's response against the expected output.
Focus your diagnosis on: $errorFocusStr.''';
  }

  /// Generates the feedback constraint prompt.
  static String generateFeedbackPrompt(
    TutorTurn turn,
    String learnerResponse,
  ) {
    final allowedStr = turn.allowedFeedback.map((f) => f.name).join(', ');

    return '''LEARNER RESPONSE: "$learnerResponse"

FEEDBACK CONSTRAINTS:
- Allowed feedback types: $allowedStr
- Maximum sentences: ${turn.maxExplanationSentences}
- Must diagnose before explaining
- Must specify detected error type IDs from: ${turn.errorFocus.isEmpty ? 'any applicable' : turn.errorFocus.join(', ')}

Respond with ONLY a JSON object:
{
  "wasCorrect": bool,
  "partialCredit": float (0.0-1.0),
  "diagnosis": string or null,
  "microExplanation": string or null (max ${turn.maxExplanationSentences} sentences),
  "nextAction": "${NextAction.values.map((a) => a.name).join('" | "')}",
  "diagnosisConfidence": float (0.0-1.0),
  "detectedErrors": [string] (error type IDs)
}''';
  }

  /// Generates the complete prompt sequence for a tutor turn evaluation.
  ///
  /// Returns a list of message objects ready for the AI API.
  static List<Map<String, String>> generateFullPromptSequence({
    required LearnerSkillState state,
    required TutorTurn turn,
    required String learnerResponse,
  }) {
    return [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'system', 'content': generateContextPrompt(state)},
      {'role': 'system', 'content': generateTaskPrompt(turn)},
      {'role': 'user', 'content': generateFeedbackPrompt(turn, learnerResponse)},
    ];
  }

  /// Generates a turn-creation prompt for the AI to generate the next task.
  ///
  /// Used when the AI needs to dynamically create the next practice item
  /// based on the learner's state.
  static List<Map<String, String>> generateTurnCreationPrompt({
    required LearnerSkillState state,
    required String skillName,
    required String skillDescription,
    required TaskType preferredTaskType,
    required double targetDifficulty,
  }) {
    return [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'system', 'content': generateContextPrompt(state)},
      {
        'role': 'user',
        'content': '''Generate a practice task for this learner.

SKILL: $skillName — $skillDescription
PREFERRED TASK TYPE: ${preferredTaskType.name}
TARGET DIFFICULTY: ${(targetDifficulty * 100).toStringAsFixed(0)}%

Based on the learner's error patterns and mastery level, create an appropriate task.

Respond with ONLY a JSON object:
{
  "prompt": string (the task prompt for the learner),
  "expected": {
    "text": string or null,
    "phonemes": [string] or null,
    "alternatives": [string],
    "requiredElements": [string]
  },
  "errorFocus": [string] (error type IDs to watch for),
  "timeLimitSeconds": int
}'''
      },
    ];
  }

  static String _formatExpected(ExpectedOutput expected) {
    final parts = <String>[];
    if (expected.text != null) parts.add('Text: "${expected.text}"');
    if (expected.phonemes != null) {
      parts.add('Phonemes: [${expected.phonemes!.join(", ")}]');
    }
    if (expected.alternatives.isNotEmpty) {
      parts.add('Alternatives: ${expected.alternatives.join(", ")}');
    }
    if (expected.requiredElements.isNotEmpty) {
      parts.add('Required elements: ${expected.requiredElements.join(", ")}');
    }
    return parts.isEmpty ? 'None specified' : parts.join('\n  ');
  }
}

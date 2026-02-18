/// Represents a single structured turn in the AI tutor interaction.
///
/// The AI tutor NEVER free-chats. Every interaction is a structured turn
/// with an explicit goal skill, expected output, and constrained feedback.
/// This ensures deterministic, reproducible pedagogical behavior.
class TutorTurn {
  /// The skill being practiced in this turn.
  final String goalSkillId;

  /// The type of learning task.
  final TaskType taskType;

  /// The prompt presented to the learner.
  final String prompt;

  /// What the learner is expected to produce.
  final ExpectedOutput expected;

  /// Which error types to focus feedback on.
  final List<String> errorFocus;

  /// Allowed types of feedback the AI can give.
  final List<FeedbackType> allowedFeedback;

  /// Maximum sentences the AI can use for explanation.
  final int maxExplanationSentences;

  /// Difficulty level for this turn [0, 1].
  final double difficulty;

  /// Time limit in seconds (0 = no limit).
  final int timeLimitSeconds;

  const TutorTurn({
    required this.goalSkillId,
    required this.taskType,
    required this.prompt,
    required this.expected,
    this.errorFocus = const [],
    this.allowedFeedback = const [
      FeedbackType.diagnosis,
      FeedbackType.microExplanation,
      FeedbackType.retryPrompt,
    ],
    this.maxExplanationSentences = 2,
    this.difficulty = 0.5,
    this.timeLimitSeconds = 0,
  });

  factory TutorTurn.fromJson(Map<String, dynamic> json) {
    return TutorTurn(
      goalSkillId: json['goalSkillId'] as String,
      taskType: TaskType.values.firstWhere(
        (t) => t.name == json['taskType'],
        orElse: () => TaskType.translation,
      ),
      prompt: json['prompt'] as String,
      expected: ExpectedOutput.fromJson(
        json['expected'] as Map<String, dynamic>,
      ),
      errorFocus: (json['errorFocus'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      allowedFeedback: (json['allowedFeedback'] as List<dynamic>?)
              ?.map((e) => FeedbackType.values.firstWhere(
                    (f) => f.name == e,
                    orElse: () => FeedbackType.diagnosis,
                  ))
              .toList() ??
          [FeedbackType.diagnosis],
      maxExplanationSentences: json['maxExplanationSentences'] as int? ?? 2,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.5,
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'goalSkillId': goalSkillId,
        'taskType': taskType.name,
        'prompt': prompt,
        'expected': expected.toJson(),
        'errorFocus': errorFocus,
        'allowedFeedback': allowedFeedback.map((f) => f.name).toList(),
        'maxExplanationSentences': maxExplanationSentences,
        'difficulty': difficulty,
        'timeLimitSeconds': timeLimitSeconds,
      };
}

/// The expected output for a tutor turn.
class ExpectedOutput {
  /// The expected text response (if applicable).
  final String? text;

  /// The expected phoneme sequence (for speaking tasks).
  final List<String>? phonemes;

  /// Acceptable alternative responses.
  final List<String> alternatives;

  /// Key elements that must be present for a correct response.
  final List<String> requiredElements;

  const ExpectedOutput({
    this.text,
    this.phonemes,
    this.alternatives = const [],
    this.requiredElements = const [],
  });

  factory ExpectedOutput.fromJson(Map<String, dynamic> json) {
    return ExpectedOutput(
      text: json['text'] as String?,
      phonemes: (json['phonemes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      requiredElements: (json['requiredElements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (text != null) 'text': text,
        if (phonemes != null) 'phonemes': phonemes,
        'alternatives': alternatives,
        'requiredElements': requiredElements,
      };
}

/// The AI tutor's response to a learner's attempt.
///
/// This is a strict JSON schema — the AI must produce exactly this structure.
class TutorFeedback {
  /// What went wrong (specific, evidence-based).
  final String? diagnosis;

  /// Brief explanation (max 2 sentences).
  final String? microExplanation;

  /// What the learner should do next.
  final NextAction nextAction;

  /// Confidence that the diagnosis is correct [0, 1].
  final double diagnosisConfidence;

  /// Specific error types detected.
  final List<String> detectedErrors;

  /// Whether the response was correct.
  final bool wasCorrect;

  /// Partial credit score [0, 1] (not binary).
  final double partialCredit;

  const TutorFeedback({
    this.diagnosis,
    this.microExplanation,
    required this.nextAction,
    this.diagnosisConfidence = 0.0,
    this.detectedErrors = const [],
    required this.wasCorrect,
    this.partialCredit = 0.0,
  });

  factory TutorFeedback.fromJson(Map<String, dynamic> json) {
    return TutorFeedback(
      diagnosis: json['diagnosis'] as String?,
      microExplanation: json['microExplanation'] as String?,
      nextAction: NextAction.values.firstWhere(
        (a) => a.name == json['nextAction'],
        orElse: () => NextAction.retrySameItem,
      ),
      diagnosisConfidence:
          (json['diagnosisConfidence'] as num?)?.toDouble() ?? 0.0,
      detectedErrors: (json['detectedErrors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      wasCorrect: json['wasCorrect'] as bool? ?? false,
      partialCredit: (json['partialCredit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        if (diagnosis != null) 'diagnosis': diagnosis,
        if (microExplanation != null) 'microExplanation': microExplanation,
        'nextAction': nextAction.name,
        'diagnosisConfidence': diagnosisConfidence,
        'detectedErrors': detectedErrors,
        'wasCorrect': wasCorrect,
        'partialCredit': partialCredit,
      };
}

/// Types of learning tasks the tutor can assign.
enum TaskType {
  /// Translate from native language to target language.
  translation,

  /// Translate from target language to native language.
  reverseTranslation,

  /// Produce spoken output for a given prompt.
  speaking,

  /// Discriminate between similar items (minimal pairs).
  minimalPairSpeaking,

  /// Listen and transcribe.
  listeningTranscription,

  /// Fill in the missing word/morpheme.
  cloze,

  /// Choose the correct option.
  multipleChoice,

  /// Produce a sentence using a target grammar structure.
  sentenceConstruction,

  /// Respond appropriately in a social context.
  pragmaticResponse,

  /// Free production with constraints.
  guidedProduction,
}

/// Types of feedback the AI is allowed to give.
enum FeedbackType {
  /// Identify what went wrong.
  diagnosis,

  /// Brief explanation of the correct answer.
  microExplanation,

  /// Ask the learner to try again.
  retryPrompt,

  /// Provide the correct answer directly.
  correctAnswer,

  /// Give a hint without revealing the answer.
  hint,
}

/// What the learner should do after receiving feedback.
enum NextAction {
  /// Try the same item again.
  retrySameItem,

  /// Move to the next item at the same difficulty.
  nextItemSameDifficulty,

  /// Move to an easier item.
  downgradeToEasier,

  /// Move to the next item at higher difficulty.
  upgradeToHarder,

  /// Practice a prerequisite skill first.
  practicePrerequisite,

  /// End the session (mastery achieved for this skill).
  endSession,
}

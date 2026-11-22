import 'package:lingafriq/features/polie_workspace/polie_workspace_models_core.dart';
import 'package:lingafriq/models/translation_history_model.dart';
import 'package:lingafriq/models/tutor_progress_model.dart';
import 'package:uuid/uuid.dart' as uuid;

TranslationEntry polieToHistoryEntry({
  required String input,
  required TranslationPayload payload,
  required String sourceLanguage,
  required String targetLanguage,
}) {
  return TranslationEntry(
    id: const uuid.Uuid().v4(),
    sourceText: input,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
    primaryTranslation: payload.primary,
    alternatives: payload.alternatives
        .map(
          (a) => TranslationAlternative(
            translation: a.text,
            context: a.note.isEmpty ? null : a.note,
          ),
        )
        .toList(),
    timestamp: DateTime.now(),
  );
}

TutorSessionResult polieBuildTutorSessionResult({
  required String language,
  required String answer,
  required TutorFeedbackPayload verdict,
  required String concept,
  List<String> extraTopics = const <String>[],
  List<String> extraGrammar = const <String>[],
  List<String> vocabularyOverride = const <String>[],
  Map<String, dynamic> extraMetadata = const <String, dynamic>{},
}) {
  final List<String> topics = <String>[
    concept,
    for (final String topic in extraTopics)
      if (topic != concept) topic,
  ];
  final List<String> grammar = <String>[
    concept,
    for (final String point in extraGrammar)
      if (point != concept) point,
  ];
  final List<String> vocabulary = vocabularyOverride.isNotEmpty
      ? vocabularyOverride
      : answer
          .split(RegExp(r'\s+'))
          .where((String word) => word.length > 2)
          .take(8)
          .toList();
  return TutorSessionResult(
    sessionId: 'polie_tutor_${DateTime.now().millisecondsSinceEpoch}',
    language: language,
    cefrLevel: 'A1',
    interactions: [
      TutorInteraction(
        type: 'exercise',
        content: concept,
        userResponse: answer,
        score: verdict.score.toDouble(),
        feedback: verdict.why,
        timestamp: DateTime.now(),
      ),
    ],
    overallScore: verdict.score.toDouble(),
    skillScores: {
      'grammar': verdict.score.toDouble(),
      'vocabulary': verdict.score.toDouble(),
      'comprehension': verdict.score.toDouble(),
      'pronunciation': verdict.score.toDouble(),
    },
    topicsCovered: topics,
    vocabularyLearned: vocabulary,
    grammarPoints: grammar,
    timeSpent: 1,
    completedAt: DateTime.now(),
    metadata: extraMetadata,
  );
}

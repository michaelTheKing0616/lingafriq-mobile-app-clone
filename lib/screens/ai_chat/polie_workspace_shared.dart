import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';

class ModeChipItem {
  final PolieMode mode;
  final String icon;
  final String label;
  const ModeChipItem({required this.mode, required this.icon, required this.label});
}

class ModeTheme {
  final Color background;
  final Color card;
  final Color title;
  final Color body;
  final Color border;
  final Color accent;
  const ModeTheme({
    required this.background,
    required this.card,
    required this.title,
    required this.body,
    required this.border,
    required this.accent,
  });
}

class AltItem {
  final String text;
  final String note;
  const AltItem({required this.text, required this.note});
}

String normalizeInitialRoleplayScene(String? raw) {
  const allowed = <String>{
    'Market',
    'Restaurant',
    'Meeting Elder',
    'Job Interview',
    'Family Dinner',
  };
  if (raw == null) return 'Market';
  final normalized = raw.trim();
  if (allowed.contains(normalized)) return normalized;
  return 'Market';
}

/// Mode ids from [AIModeSelectionScreen], in picker order.
///
/// Assessment used the same id as Review, so review is listed twice.
const List<String> polieLegacyModeIds = <String>[
  'tutor',
  'translation',
  'review',
  'grammar',
  'pronunciation',
  'roleplay',
  'conversation',
  'review',
];

/// Modes whose workspace panel is not an empty box.
const Set<PolieMode> polieModesWithSurface = <PolieMode>{
  PolieMode.translation,
  PolieMode.tutor,
  PolieMode.roleplay,
  PolieMode.conversation,
  PolieMode.vocab,
  PolieMode.review,
};

/// Union of the mode switches in the mode picker, the tracking chat, and
/// the newer chat screen.
PolieMode polieModeForLegacyChatId(String raw) {
  switch (raw.toLowerCase().trim()) {
    case 'translate':
    case 'translation':
      return PolieMode.translation;
    case 'tutor':
      return PolieMode.tutor;
    case 'story':
    case 'stories':
    case 'roleplay':
      return PolieMode.roleplay;
    case 'dialogue':
    case 'conversation':
      return PolieMode.conversation;
    case 'vocab':
    case 'vocabulary':
      return PolieMode.vocab;
    case 'assess':
    case 'assessment':
    case 'review':
      return PolieMode.review;
    case 'pronunciation':
      return PolieMode.pronunciation;
    case 'explain':
    case 'grammar':
      return PolieMode.grammar;
    default:
      return PolieMode.tutor;
  }
}

/// Surprise Me, including grammar and pronunciation.
PolieMode surprisePolieMode(Random random) {
  final String id = polieLegacyModeIds[random.nextInt(polieLegacyModeIds.length)];
  return polieModeForLegacyChatId(id);
}

/// Surprise Me limited to modes the workspace can show.
PolieMode surprisePolieModeOnSurface(Random random) {
  final List<PolieMode> options = <PolieMode>[
    for (final String id in polieLegacyModeIds)
      if (polieModesWithSurface.contains(polieModeForLegacyChatId(id)))
        polieModeForLegacyChatId(id),
  ];
  return options[random.nextInt(options.length)];
}

enum PolieProgressDashboard { roleplay, tutor, conversation, vocabulary, review }

/// Analytics button from the tracking chat. Translation, grammar, and
/// pronunciation had no dashboard in that switch.
PolieProgressDashboard? polieProgressDashboardForMode(PolieMode mode) {
  return switch (mode) {
    PolieMode.roleplay => PolieProgressDashboard.roleplay,
    PolieMode.tutor => PolieProgressDashboard.tutor,
    PolieMode.conversation => PolieProgressDashboard.conversation,
    PolieMode.vocab => PolieProgressDashboard.vocabulary,
    PolieMode.review => PolieProgressDashboard.review,
    PolieMode.translation ||
    PolieMode.pronunciation ||
    PolieMode.grammar =>
      null,
  };
}

const List<String> polieTopicKeywords = <String>[
  'food',
  'travel',
  'greeting',
  'shopping',
  'weather',
  'family',
  'work',
  'health',
];

void polieExtractTopicsAndVocab(
  String text,
  Set<String> topics,
  Map<String, int> vocab,
) {
  final String lowerText = text.toLowerCase();
  for (final String keyword in polieTopicKeywords) {
    if (lowerText.contains(keyword)) {
      topics.add(keyword);
    }
  }
  final List<String> words = text
      .split(RegExp(r'[^\w\s]'))
      .where((String word) => word.length > 3)
      .toList();
  for (final String word in words) {
    final String key = word.toLowerCase();
    vocab[key] = (vocab[key] ?? 0) + 1;
  }
}

List<String> polieExtractGrammarPoints(String text) {
  const List<String> grammarKeywords = <String>[
    'verb',
    'noun',
    'adjective',
    'tense',
    'plural',
    'singular',
  ];
  final String lowerText = text.toLowerCase();
  return grammarKeywords
      .where((String keyword) => lowerText.contains(keyword))
      .toList();
}

String? polieExtractCorrection(String text) {
  final String lower = text.toLowerCase();
  if (lower.contains('correction') ||
      lower.contains(<String>['should', 'be'].join(' '))) {
    return text;
  }
  return null;
}

/// True when the enhanced chat would keep a correction line.
bool polieAutoCorrectionDiffers(String original, String corrected) {
  final String trimmed = corrected.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.toUpperCase() == 'CORRECT') return false;
  if (trimmed.toLowerCase() == original.toLowerCase()) return false;
  return true;
}

/// Topic-chip update from the enhanced conversation screen.
///
/// Related topics come first (up to 3), then top topics that are not already
/// related (up to 7). An empty related set leaves [current] unchanged.
List<String> polieMergeTopicSuggestions({
  required String message,
  required List<String> allTopics,
  required List<String> topTopics,
  required List<String> current,
}) {
  final List<String> keywords = message
      .toLowerCase()
      .split(RegExp(r'[^\w]+'))
      .where((String word) => word.length > 3)
      .toList();
  final List<String> related = allTopics.where((String topic) {
    final String topicLower = topic.toLowerCase();
    return keywords.any((String keyword) => topicLower.contains(keyword));
  }).toList();
  if (related.isEmpty) return current;
  return <String>[
    ...related.take(3),
    ...topTopics.where((String topic) => !related.contains(topic)).take(7),
  ];
}

List<String> polieFallbackTopics(AppLocalizations l10n) {
  return <String>[
    l10n.polieTopicGreetings,
    l10n.polieTopicFood,
    l10n.onboardingTravel,
    l10n.polieTopicShopping,
    l10n.polieTopicWeather,
    l10n.polieTopicHobbies,
    l10n.hubHMeFamily,
    l10n.polieTopicWork,
    l10n.polieTopicHealth,
    l10n.gmCatCultural,
  ];
}

class PolieTutorTopicNames {
  const PolieTutorTopicNames({
    required this.grammar,
    required this.vocabulary,
    required this.pronunciation,
    required this.conversation,
    required this.fallback,
    required this.tense,
    required this.verbUsage,
    required this.agreement,
    required this.wordOrder,
  });

  final String grammar;
  final String vocabulary;
  final String pronunciation;
  final String conversation;
  final String fallback;
  final String tense;
  final String verbUsage;
  final String agreement;
  final String wordOrder;
}

PolieTutorTopicNames polieTutorTopicNames(AppLocalizations l10n) {
  return PolieTutorTopicNames(
    grammar: l10n.gmCatGrammar,
    vocabulary: l10n.gmCatVocabulary,
    pronunciation: l10n.revRvSpeakPronunciation,
    conversation: l10n.onboardingConversation,
    fallback: l10n.polieTutorPracticeTopic,
    tense: l10n.polieGrammarTense,
    verbUsage: l10n.polieGrammarVerb,
    agreement: l10n.polieGrammarAgreement,
    wordOrder: l10n.polieGrammarWordOrder,
  );
}

class PolieTutorTurnDraft {
  const PolieTutorTurnDraft({
    required this.type,
    required this.topics,
    required this.vocabulary,
    required this.grammar,
    required this.score,
    required this.metadata,
  });

  final String type;
  final List<String> topics;
  final List<String> vocabulary;
  final List<String> grammar;
  final double? score;
  final Map<String, Object> metadata;
}

/// Tutor-turn notes from the tracking chat.
///
/// [score] is null unless the backend evaluator flag is on. The workspace
/// keeps the tutor verdict score when it saves the session.
PolieTutorTurnDraft polieTutorTurnDraft({
  required String userInput,
  required String response,
  required bool hasBackendEvaluator,
  required PolieTutorTopicNames names,
}) {
  final String userText = userInput.trim();
  final String tutorText = response.trim();
  final List<String> userWords = userText
      .split(RegExp(r'\s+'))
      .map((String word) => word.trim())
      .where((String word) => word.isNotEmpty)
      .toList();
  final List<String> responseWords = tutorText
      .split(RegExp(r'\s+'))
      .map((String word) => word.trim())
      .where((String word) => word.isNotEmpty)
      .toList();
  final String lowerUser = userText.toLowerCase();
  final String lowerResponse = tutorText.toLowerCase();
  final double? score = hasBackendEvaluator ? 50.0 : null;
  final List<String> vocabulary = userWords
      .map((String word) => word.replaceAll(RegExp(r"[^\w']"), '').toLowerCase())
      .where((String word) => word.length > 2)
      .toSet()
      .take(8)
      .toList();
  final Map<String, List<String>> topicKeywords = <String, List<String>>{
    names.grammar: <String>['grammar', 'tense', 'sentence', 'verb', 'noun'],
    names.vocabulary: <String>['word', 'vocab', 'phrase', 'meaning', 'translate'],
    names.pronunciation: <String>[
      'pronounce',
      'pronunciation',
      'sound',
      'accent',
      'tone',
    ],
    names.conversation: <String>['conversation', 'chat', 'dialogue', 'talk'],
  };
  final List<String> topics = <String>[];
  for (final MapEntry<String, List<String>> entry in topicKeywords.entries) {
    if (entry.value.any(
      (String keyword) =>
          lowerUser.contains(keyword) || lowerResponse.contains(keyword),
    )) {
      topics.add(entry.key);
    }
  }
  if (topics.isEmpty) {
    topics.add(names.fallback);
  }
  final List<String> grammar = <String>[
    if (lowerResponse.contains('tense')) names.tense,
    if (lowerResponse.contains('verb')) names.verbUsage,
    if (lowerResponse.contains('agreement')) names.agreement,
    if (lowerResponse.contains(<String>['word', 'order'].join(' ')))
      names.wordOrder,
  ];
  return PolieTutorTurnDraft(
    type: userText.contains('?') ? 'question' : 'exercise',
    topics: topics,
    vocabulary: vocabulary,
    grammar: grammar,
    score: score,
    metadata: <String, Object>{
      'source': 'ai_chat_tutor_turn',
      'user_words': userWords.length,
      'response_words': responseWords.length,
      'is_scored': hasBackendEvaluator,
      'scoring_mode': hasBackendEvaluator ? 'backend' : 'neutral',
    },
  );
}

class PolieRoleplayTurnNote {
  const PolieRoleplayTurnNote({
    required this.vocabulary,
    required this.grammar,
    required this.correction,
  });

  final List<String> vocabulary;
  final List<String> grammar;
  final String? correction;
}

PolieRoleplayTurnNote polieRoleplayTurnNote(String userText, String response) {
  final List<String> words = userText
      .split(' ')
      .where((String word) => word.isNotEmpty)
      .toList();
  return PolieRoleplayTurnNote(
    vocabulary: words,
    grammar: polieExtractGrammarPoints(response),
    correction: polieExtractCorrection(response),
  );
}

class PolieChatTrackingSession {
  DateTime? startedAt;
  int messageCount = 0;
  int wordCount = 0;
  int errors = 0;
  bool flushed = false;
  final Set<String> topics = <String>{};
  final Map<String, int> vocabularyUsed = <String, int>{};
  final List<String> corrections = <String>[];

  void begin(DateTime now) {
    startedAt = now;
    messageCount = 0;
    wordCount = 0;
    errors = 0;
    flushed = false;
    topics.clear();
    vocabularyUsed.clear();
    corrections.clear();
  }

  void recordUserMessage(String text) {
    messageCount += 1;
    final List<String> words = text
        .split(' ')
        .where((String word) => word.isNotEmpty)
        .toList();
    wordCount += words.length;
    for (final String word in words) {
      final String key = word.toLowerCase();
      vocabularyUsed[key] = (vocabularyUsed[key] ?? 0) + 1;
    }
  }

  void recordAssistantText(String text) {
    polieExtractTopicsAndVocab(text, topics, vocabularyUsed);
  }

  void recordError() {
    errors += 1;
  }
}

class PolieHarvestController {
  PolieHarvestController() {
    session.begin(DateTime.now());
  }

  final ValueNotifier<bool> autoCorrectionEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<List<String>> topicSuggestions =
      ValueNotifier<List<String>>(const <String>[]);
  final ValueNotifier<String?> currentTopic = ValueNotifier<String?>(null);
  final PolieChatTrackingSession session = PolieChatTrackingSession();
  final List<PolieRoleplayTurnNote> roleplayNotes = <PolieRoleplayTurnNote>[];
  final List<PolieTutorTurnDraft> tutorTurns = <PolieTutorTurnDraft>[];

  void dispose() {
    autoCorrectionEnabled.dispose();
    topicSuggestions.dispose();
    currentTopic.dispose();
  }
}

class PolieHarvestScope extends InheritedWidget {
  const PolieHarvestScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final PolieHarvestController controller;

  static PolieHarvestController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PolieHarvestScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(PolieHarvestScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

class PolieEnhancedConversationBar extends StatelessWidget {
  const PolieEnhancedConversationBar({
    super.key,
    required this.controller,
    required this.input,
    required this.topicPrompt,
    required this.correctionOnLabel,
    required this.correctionOffLabel,
    this.enabled = true,
  });

  final PolieHarvestController controller;
  final TextEditingController input;
  final String Function(String topic) topicPrompt;
  final String correctionOnLabel;
  final String correctionOffLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('polie-enhanced-conversation'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ValueListenableBuilder<bool>(
          valueListenable: controller.autoCorrectionEnabled,
          builder: (BuildContext context, bool on, Widget? child) {
            return Semantics(
              button: true,
              label: on ? correctionOnLabel : correctionOffLabel,
              child: IconButton(
                key: const ValueKey<String>('polie-auto-correction'),
                tooltip: on ? correctionOnLabel : correctionOffLabel,
                onPressed: enabled
                    ? () {
                        HapticFeedback.lightImpact();
                        controller.autoCorrectionEnabled.value = !on;
                      }
                    : null,
                icon: Icon(
                  on ? Icons.auto_fix_high_rounded : Icons.auto_fix_off_rounded,
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder<List<String>>(
          valueListenable: controller.topicSuggestions,
          builder: (BuildContext context, List<String> topics, Widget? child) {
            if (topics.isEmpty) return const SizedBox.shrink();
            return ValueListenableBuilder<String?>(
              valueListenable: controller.currentTopic,
              builder: (BuildContext context, String? selected, Widget? child) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final String topic in topics)
                      ChoiceChip(
                        key: ValueKey<String>('polie-topic-$topic'),
                        label: Text(topic),
                        selected: topic == selected,
                        onSelected: enabled
                            ? (_) {
                                HapticFeedback.lightImpact();
                                final bool already = selected == topic;
                                controller.currentTopic.value =
                                    already ? null : topic;
                                if (!already) {
                                  input.text = topicPrompt(topic);
                                }
                              }
                            : null,
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class PolieConversationCorrectionLine extends StatelessWidget {
  const PolieConversationCorrectionLine({
    super.key,
    required this.harvest,
    required this.hasCorrection,
    required this.feedbackLine,
    required this.correction,
    required this.feedbackStyle,
    required this.correctionStyle,
  });

  final PolieHarvestController? harvest;
  final bool hasCorrection;
  final String feedbackLine;
  final String? correction;
  final TextStyle feedbackStyle;
  final TextStyle correctionStyle;

  @override
  Widget build(BuildContext context) {
    if (!hasCorrection) return const SizedBox.shrink();
    final ValueNotifier<bool>? enabled = harvest?.autoCorrectionEnabled;
    if (enabled == null) return _lines();
    return ValueListenableBuilder<bool>(
      valueListenable: enabled,
      builder: (BuildContext context, bool on, Widget? child) {
        if (!on) return const SizedBox.shrink();
        return _lines();
      },
    );
  }

  Widget _lines() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(feedbackLine, style: feedbackStyle),
          if ((correction ?? '').isNotEmpty)
            Text(correction!, style: correctionStyle),
        ],
      ),
    );
  }
}

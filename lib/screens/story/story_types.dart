/// P6-027: gateway story payload mirrors (no client LLM).
library;

const storyAiGeneratedLabelKey = 'story.ai_generated_label';

const storyAiGeneratedLabelEn = 'AI-generated';

enum StoryVisibility {
  personal,
  pendingShared,
  sharedApproved,
}

class StoryGlossEntry {
  const StoryGlossEntry({
    required this.surface,
    required this.glossL1,
    required this.lexemeId,
  });

  final String surface;
  final String glossL1;
  final String lexemeId;

  factory StoryGlossEntry.fromJson(Map<String, dynamic> json) {
    return StoryGlossEntry(
      surface: json['surface']?.toString() ?? '',
      glossL1: json['gloss_l1']?.toString() ?? '',
      lexemeId: json['lexeme_id']?.toString() ?? '',
    );
  }
}

class StoryComprehensionQuestion {
  const StoryComprehensionQuestion({
    required this.questionL1,
    required this.optionsL1,
    required this.correctIndex,
  });

  final String questionL1;
  final List<String> optionsL1;
  final int correctIndex;

  factory StoryComprehensionQuestion.fromJson(Map<String, dynamic> json) {
    final options = (json['options_l1'] as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];
    return StoryComprehensionQuestion(
      questionL1: json['question_l1']?.toString() ?? '',
      optionsL1: options,
      correctIndex: json['correct_index'] is int
          ? json['correct_index'] as int
          : int.tryParse(json['correct_index']?.toString() ?? '') ?? 0,
    );
  }
}

class StorySession {
  const StorySession({
    required this.storyId,
    required this.title,
    required this.storyText,
    required this.glosses,
    required this.comprehension,
    required this.language,
    required this.aiGeneratedLabel,
    required this.visibility,
  });

  final String storyId;
  final String title;
  final String storyText;
  final List<StoryGlossEntry> glosses;
  final List<StoryComprehensionQuestion> comprehension;
  final String language;
  final String aiGeneratedLabel;
  final StoryVisibility visibility;

  List<String> get paragraphs => storyText
      .split(RegExp(r'\n+'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList(growable: false);

  factory StorySession.fromGatewayJson(Map<String, dynamic> json) {
    final glossRaw = json['glosses'] as List? ?? const [];
    final compRaw = json['comprehension'] as List? ?? const [];
    final visibilityRaw = json['visibility']?.toString() ?? 'personal';
    StoryVisibility visibility;
    switch (visibilityRaw) {
      case 'pending_shared':
        visibility = StoryVisibility.pendingShared;
        break;
      case 'shared_approved':
        visibility = StoryVisibility.sharedApproved;
        break;
      default:
        visibility = StoryVisibility.personal;
    }
    return StorySession(
      storyId: json['story_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      storyText: json['story_text']?.toString() ?? '',
      glosses: glossRaw
          .whereType<Map>()
          .map((e) => StoryGlossEntry.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
      comprehension: compRaw
          .whereType<Map>()
          .map((e) => StoryComprehensionQuestion.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
      language: json['language']?.toString() ?? '',
      aiGeneratedLabel:
          json['ai_generated_label']?.toString() ?? storyAiGeneratedLabelEn,
      visibility: visibility,
    );
  }
}

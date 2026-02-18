import 'package:lingafriq/learning/learner_model/learner_model_service.dart';

/// Channel tier by required mastery level.
enum ChannelTier {
  beginner,
  intermediate,
  advanced,
  native,
}

/// Access result for a channel given learner mastery.
class ChannelAccess {
  final String channelId;
  final ChannelTier tier;
  final bool isAccessible;
  final double requiredMastery;
  final double currentMastery;
  final String? nextMilestoneDescription;

  const ChannelAccess({
    required this.channelId,
    required this.tier,
    required this.isAccessible,
    required this.requiredMastery,
    required this.currentMastery,
    this.nextMilestoneDescription,
  });
}

/// Result of moderating a chat message (heuristic-based).
class ModerationResult {
  final bool isApproved;
  final List<String> corrections;
  final double qualityScore;
  final String? reason;

  const ModerationResult({
    required this.isApproved,
    this.corrections = const [],
    this.qualityScore = 0.5,
    this.reason,
  });
}

/// Type of structured prompt for chat.
enum StructuredPromptType {
  daily,
  roleplay,
  debate,
}

/// A curated prompt for guided chat practice.
class StructuredPrompt {
  final String id;
  final StructuredPromptType type;
  final String content;
  final double targetLevel;
  final List<String> expectedSkills;
  final String languageCode;

  const StructuredPrompt({
    required this.id,
    required this.type,
    required this.content,
    required this.targetLevel,
    this.expectedSkills = const [],
    required this.languageCode,
  });
}

/// Enhances chat rooms with level gating, heuristic moderation,
/// and structured prompts. Uses [LearnerModelService] for mastery.
class ChatRoomLearningService {
  ChatRoomLearningService._();
  static final ChatRoomLearningService _instance =
      ChatRoomLearningService._();
  static ChatRoomLearningService get instance => _instance;

  static const double _kBeginnerMax = 0.3;
  static const double _kIntermediateMax = 0.6;
  static const double _kAdvancedMax = 0.8;

  static const Map<String, double> _channelRequiredMastery = {
    'general': 0,
    'yoruba': 0,
    'hausa': 0,
    'igbo': 0,
    'pidgin': 0,
    'swahili': 0,
    'zulu': 0,
  };

  static const Set<String> _blockedPatterns = {
    'spam', 'hate', 'abuse',
  };

  Future<ChannelAccess> canAccessChannel(
    String learnerId,
    String channelId,
    String languageCode,
  ) async {
    final learner = LearnerModelService.instance;
    await learner.initialize();

    final metrics = learner.getCognitiveMetrics(
      learnerId: learnerId,
      languageCode: languageCode,
    );
    final currentMastery = metrics.averageMastery;
    final required = _channelRequiredMastery[channelId] ?? 0.0;
    final tier = _masteryToTier(currentMastery);
    final isAccessible = currentMastery >= required;

    String? nextMilestone;
    if (!isAccessible) {
      nextMilestone = 'Reach ${(required * 100).toInt()}% mastery to unlock this channel.';
    } else if (currentMastery < _kIntermediateMax) {
      nextMilestone = 'Reach 30% mastery for intermediate channels.';
    } else if (currentMastery < _kAdvancedMax) {
      nextMilestone = 'Reach 60% mastery for advanced channels.';
    } else if (currentMastery < 1.0) {
      nextMilestone = 'Keep practicing to reach native-tier level.';
    }

    return ChannelAccess(
      channelId: channelId,
      tier: tier,
      isAccessible: isAccessible,
      requiredMastery: required,
      currentMastery: currentMastery,
      nextMilestoneDescription: nextMilestone,
    );
  }

  Future<List<ChannelAccess>> getAccessibleChannels(
    String learnerId,
    String languageCode,
  ) async {
    final learner = LearnerModelService.instance;
    await learner.initialize();

    final metrics = learner.getCognitiveMetrics(
      learnerId: learnerId,
      languageCode: languageCode,
    );
    final currentMastery = metrics.averageMastery;

    final allChannels = _channelRequiredMastery.keys.toList();
    final result = <ChannelAccess>[];

    for (final channelId in allChannels) {
      final required = _channelRequiredMastery[channelId] ?? 0.0;
      final isAccessible = currentMastery >= required;
      final tier = _masteryToTier(currentMastery);

      String? nextMilestone;
      if (currentMastery < _kIntermediateMax) {
        nextMilestone = 'Reach 30% mastery for intermediate channels.';
      } else if (currentMastery < _kAdvancedMax) {
        nextMilestone = 'Reach 60% mastery for advanced channels.';
      } else if (currentMastery < 1.0) {
        nextMilestone = 'Keep practicing for native-tier channels.';
      }

      result.add(ChannelAccess(
        channelId: channelId,
        tier: tier,
        isAccessible: isAccessible,
        requiredMastery: required,
        currentMastery: currentMastery,
        nextMilestoneDescription: nextMilestone,
      ));
    }

    return result;
  }

  ModerationResult moderateMessage(String message, String languageCode) {
    final trimmed = message.trim();
    final corrections = <String>[];
    double quality = 0.5;

    if (trimmed.isEmpty) {
      return const ModerationResult(
        isApproved: false,
        qualityScore: 0,
        reason: 'Message is empty.',
      );
    }

    final lower = trimmed.toLowerCase();
    for (final pattern in _blockedPatterns) {
      if (lower.contains(pattern)) {
        return ModerationResult(
          isApproved: false,
          qualityScore: 0,
          reason: 'Message contains disallowed content.',
        );
      }
    }

    if (trimmed.length < 2) {
      return ModerationResult(
        isApproved: true,
        corrections: corrections,
        qualityScore: 0.2,
        reason: 'Very short message.',
      );
    }

    if (trimmed[0].toLowerCase() == trimmed[0] && trimmed[0].contains(RegExp(r'[a-z]'))) {
      corrections.add('Consider starting with a capital letter.');
    }
    final last = trimmed[trimmed.length - 1];
    if (!last.contains(RegExp(r'[.!?]'))) {
      corrections.add('Consider ending with . ? or !');
    }

    if (trimmed.length >= 10) quality += 0.2;
    if (trimmed.length >= 30) quality += 0.1;
    if (corrections.isEmpty) quality += 0.2;
    final allCaps = trimmed == trimmed.toUpperCase() && trimmed.contains(RegExp(r'[A-Z]'));
    if (allCaps && trimmed.length > 5) {
      quality -= 0.2;
      corrections.add('Avoid writing in all caps.');
    }
    quality = quality.clamp(0.0, 1.0);

    return ModerationResult(
      isApproved: true,
      corrections: corrections,
      qualityScore: quality,
    );
  }

  String? generateCorrectionSuggestion(String message, String languageCode) {
    final result = moderateMessage(message, languageCode);
    if (result.corrections.isEmpty) return null;
    return result.corrections.join(' ');
  }

  double scoreMessageQuality(String message, String languageCode) {
    return moderateMessage(message, languageCode).qualityScore;
  }

  StructuredPrompt getDailyPrompt(
    String channelId,
    String languageCode,
    double difficultyLevel,
  ) {
    final lang = languageCode.isEmpty ? 'this language' : languageCode;
    final prompts = [
      'Introduce yourself in $lang in one or two sentences.',
      'Describe what you did today using $lang.',
      'Ask the group a question in $lang about culture or daily life.',
      'Share a favorite word or phrase in $lang and why you like it.',
    ];
    final index = (difficultyLevel * (prompts.length - 1)).round().clamp(0, prompts.length - 1);
    return StructuredPrompt(
      id: 'daily_${channelId}_${languageCode}_${DateTime.now().day}',
      type: StructuredPromptType.daily,
      content: prompts[index],
      targetLevel: difficultyLevel,
      expectedSkills: ['greetings', 'presentation', 'vocabulary'],
      languageCode: languageCode,
    );
  }

  List<StructuredPrompt> getRoleplayPrompts(
    String channelId,
    String languageCode,
  ) {
    final lang = languageCode.isEmpty ? 'language' : languageCode;
    return [
      StructuredPrompt(
        id: 'roleplay_market_$channelId',
        type: StructuredPromptType.roleplay,
        content: 'Roleplay: You are at a market. Greet the seller and ask for the price of an item in $lang.',
        targetLevel: 0.4,
        expectedSkills: ['greetings', 'numbers', 'questions'],
        languageCode: languageCode,
      ),
      StructuredPrompt(
        id: 'roleplay_travel_$channelId',
        type: StructuredPromptType.roleplay,
        content: 'Roleplay: You are asking for directions. Ask how to get to the nearest bus stop in $lang.',
        targetLevel: 0.5,
        expectedSkills: ['directions', 'polite requests'],
        languageCode: languageCode,
      ),
      StructuredPrompt(
        id: 'roleplay_family_$channelId',
        type: StructuredPromptType.roleplay,
        content: 'Roleplay: Describe your family to a new friend in $lang.',
        targetLevel: 0.3,
        expectedSkills: ['family', 'descriptions'],
        languageCode: languageCode,
      ),
    ];
  }

  List<StructuredPrompt> getDebateTopics(
    String channelId,
    String languageCode,
    double level,
  ) {
    final lang = languageCode.isEmpty ? 'language' : languageCode;
    final topics = [
      'Is it better to learn $lang at home or in a classroom? Discuss.',
      'Should children learn multiple languages early? Share your view in $lang.',
      'How does music help you learn $lang? Debate with the group.',
    ];
    return topics.asMap().entries.map((e) {
      final i = e.key;
      return StructuredPrompt(
        id: 'debate_${channelId}_$i',
        type: StructuredPromptType.debate,
        content: e.value,
        targetLevel: level.clamp(0.3, 0.8),
        expectedSkills: ['opinion', 'argumentation', 'vocabulary'],
        languageCode: languageCode,
      );
    }).toList();
  }

  Future<void> recordChatInteraction({
    required String learnerId,
    required String message,
    List<String>? corrections,
    required String languageCode,
  }) async {
    final learner = LearnerModelService.instance;
    await learner.initialize();

    final skillId = 'chat_production_${_normalizeLang(languageCode)}';
    final quality = scoreMessageQuality(message, languageCode);
    final appliedCorrections = corrections != null && corrections.isNotEmpty;
    final wasCorrect = !appliedCorrections && quality >= 0.5;

    await learner.recordAttempt(
      learnerId: learnerId,
      skillId: skillId,
      wasCorrect: wasCorrect,
    );
  }

  ChannelTier _masteryToTier(double mastery) {
    if (mastery >= _kAdvancedMax) return ChannelTier.native;
    if (mastery >= _kIntermediateMax) return ChannelTier.advanced;
    if (mastery >= _kBeginnerMax) return ChannelTier.intermediate;
    return ChannelTier.beginner;
  }

  String _normalizeLang(String lang) {
    return lang.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '_');
  }
}

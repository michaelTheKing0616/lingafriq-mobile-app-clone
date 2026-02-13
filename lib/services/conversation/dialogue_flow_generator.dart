/// Dialogue Flow Generator
/// Generates natural, context-aware dialogue flows for conversation practice
/// 
/// Features:
/// - Natural conversation starters
/// - Context-aware follow-up questions
/// - Topic transitions
/// - Cultural context integration
/// - Difficulty-appropriate responses

/// Dialogue flow type
enum DialogueFlowType {
  greeting,
  introduction,
  smallTalk,
  topicDiscussion,
  questionAnswer,
  culturalExchange,
  farewell,
}

/// Dialogue turn
class DialogueTurn {
  final String speaker; // 'user' or 'assistant'
  final String text;
  final String? ipa;
  final String translation;
  final List<String>? tonePattern;
  final String? culturalNote;
  final Map<String, dynamic>? metadata;

  DialogueTurn({
    required this.speaker,
    required this.text,
    this.ipa,
    required this.translation,
    this.tonePattern,
    this.culturalNote,
    this.metadata,
  });
}

/// Dialogue flow
class DialogueFlow {
  final String id;
  final DialogueFlowType type;
  final String languageCode;
  final String level;
  final String topic;
  final List<DialogueTurn> turns;
  final Map<String, dynamic> context;

  DialogueFlow({
    required this.id,
    required this.type,
    required this.languageCode,
    required this.level,
    required this.topic,
    required this.turns,
    required this.context,
  });
}

/// Dialogue Flow Generator
class DialogueFlowGenerator {
  /// Generate natural dialogue flow
  Future<DialogueFlow> generateDialogueFlow({
    required DialogueFlowType type,
    required String languageCode,
    required String level,
    String? topic,
    Map<String, dynamic>? existingContext,
  }) async {
    final flowId = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    final selectedTopic = topic ?? _getDefaultTopic(type, level);

    final turns = await _generateTurns(
      type: type,
      languageCode: languageCode,
      level: level,
      topic: selectedTopic,
      context: existingContext,
    );

    return DialogueFlow(
      id: flowId,
      type: type,
      languageCode: languageCode,
      level: level,
      topic: selectedTopic,
      turns: turns,
      context: existingContext ?? {},
    );
  }

  /// Generate dialogue turns based on type
  Future<List<DialogueTurn>> _generateTurns({
    required DialogueFlowType type,
    required String languageCode,
    required String level,
    required String topic,
    Map<String, dynamic>? context,
  }) async {
    switch (type) {
      case DialogueFlowType.greeting:
        return _generateGreetingFlow(languageCode, level);
      case DialogueFlowType.introduction:
        return _generateIntroductionFlow(languageCode, level);
      case DialogueFlowType.smallTalk:
        return _generateSmallTalkFlow(languageCode, level, topic);
      case DialogueFlowType.topicDiscussion:
        return _generateTopicDiscussionFlow(languageCode, level, topic);
      case DialogueFlowType.questionAnswer:
        return _generateQuestionAnswerFlow(languageCode, level, topic);
      case DialogueFlowType.culturalExchange:
        return _generateCulturalExchangeFlow(languageCode, level, topic);
      case DialogueFlowType.farewell:
        return _generateFarewellFlow(languageCode, level);
    }
  }

  List<DialogueTurn> _generateGreetingFlow(String languageCode, String level) {
    final greetings = _getGreetings(languageCode, level);
    
    return [
      DialogueTurn(
        speaker: 'assistant',
        text: greetings['morning'] ?? 'Hello',
        translation: 'Good morning',
        culturalNote: 'Common greeting',
      ),
      DialogueTurn(
        speaker: 'user',
        text: greetings['response'] ?? 'Hello',
        translation: 'Good morning to you too',
      ),
      DialogueTurn(
        speaker: 'assistant',
        text: greetings['how_are_you'] ?? 'How are you?',
        translation: 'How are you?',
      ),
    ];
  }

  List<DialogueTurn> _generateIntroductionFlow(String languageCode, String level) {
    return [
      DialogueTurn(
        speaker: 'assistant',
        text: _getIntroductionPrompt(languageCode),
        translation: 'What is your name?',
      ),
      DialogueTurn(
        speaker: 'user',
        text: _getIntroductionResponse(languageCode),
        translation: 'My name is...',
      ),
      DialogueTurn(
        speaker: 'assistant',
        text: _getPleasureResponse(languageCode),
        translation: 'Nice to meet you',
      ),
    ];
  }

  List<DialogueTurn> _generateSmallTalkFlow(String languageCode, String level, String topic) {
    return [
      DialogueTurn(
        speaker: 'assistant',
        text: _getTopicStarter(languageCode, topic),
        translation: 'What do you think about $topic?',
      ),
      DialogueTurn(
        speaker: 'user',
        text: _getTopicResponse(languageCode, topic),
        translation: 'I think...',
      ),
      DialogueTurn(
        speaker: 'assistant',
        text: _getFollowUpQuestion(languageCode, topic),
        translation: 'That is interesting. Can you tell me more?',
      ),
    ];
  }

  List<DialogueTurn> _generateTopicDiscussionFlow(String languageCode, String level, String topic) {
    // Generate deeper discussion flow
    return [
      DialogueTurn(
        speaker: 'assistant',
        text: _getDiscussionStarter(languageCode, topic),
        translation: 'Let us discuss $topic',
      ),
      DialogueTurn(
        speaker: 'user',
        text: _getDiscussionResponse(languageCode, topic),
        translation: 'I would like to discuss...',
      ),
    ];
  }

  List<DialogueTurn> _generateQuestionAnswerFlow(String languageCode, String level, String topic) {
    return [
      DialogueTurn(
        speaker: 'assistant',
        text: _getQuestion(languageCode, topic),
        translation: 'Question about $topic',
      ),
      DialogueTurn(
        speaker: 'user',
        text: _getAnswer(languageCode, topic),
        translation: 'Answer',
      ),
    ];
  }

  List<DialogueTurn> _generateCulturalExchangeFlow(String languageCode, String level, String topic) {
    return [
      DialogueTurn(
        speaker: 'assistant',
        text: _getCulturalQuestion(languageCode, topic),
        translation: 'Cultural question',
        culturalNote: 'This reflects cultural practices',
      ),
      DialogueTurn(
        speaker: 'user',
        text: _getCulturalResponse(languageCode, topic),
        translation: 'Cultural response',
      ),
    ];
  }

  List<DialogueTurn> _generateFarewellFlow(String languageCode, String level) {
    return [
      DialogueTurn(
        speaker: 'assistant',
        text: _getFarewell(languageCode),
        translation: 'Goodbye',
      ),
      DialogueTurn(
        speaker: 'user',
        text: _getFarewellResponse(languageCode),
        translation: 'Goodbye to you too',
      ),
    ];
  }

  String _getDefaultTopic(DialogueFlowType type, String level) {
    switch (type) {
      case DialogueFlowType.greeting:
      case DialogueFlowType.introduction:
      case DialogueFlowType.farewell:
        return 'general';
      case DialogueFlowType.smallTalk:
        return level == 'A1' ? 'weather' : 'hobbies';
      case DialogueFlowType.topicDiscussion:
        return level == 'A1' ? 'food' : 'culture';
      case DialogueFlowType.questionAnswer:
        return 'daily_life';
      case DialogueFlowType.culturalExchange:
        return 'traditions';
    }
  }

  Map<String, String> _getGreetings(String languageCode, String level) {
    // Language-specific greetings
    switch (languageCode) {
      case 'yo':
        return {
          'morning': 'Ẹ káàárọ̀',
          'response': 'Ẹ káàárọ̀ pẹ̀lú',
          'how_are_you': 'Báwo ni?',
        };
      case 'ig':
        return {
          'morning': 'Ụtụtụ ọma',
          'response': 'Ụtụtụ ọma',
          'how_are_you': 'Kedu?',
        };
      case 'sw':
        return {
          'morning': 'Habari za asubuhi',
          'response': 'Nzuri',
          'how_are_you': 'Habari yako?',
        };
      default:
        return {
          'morning': 'Hello',
          'response': 'Hello',
          'how_are_you': 'How are you?',
        };
    }
  }

  String _getIntroductionPrompt(String languageCode) {
    switch (languageCode) {
      case 'yo':
        return 'Kíni orúkọ rẹ?';
      case 'ig':
        return 'Kedu aha gị?';
      case 'sw':
        return 'Jina lako nani?';
      default:
        return 'What is your name?';
    }
  }

  String _getIntroductionResponse(String languageCode) {
    switch (languageCode) {
      case 'yo':
        return 'Orúkọ mi ni...';
      case 'ig':
        return 'Aha m bụ...';
      case 'sw':
        return 'Jina langu ni...';
      default:
        return 'My name is...';
    }
  }

  String _getPleasureResponse(String languageCode) {
    switch (languageCode) {
      case 'yo':
        return 'Ó dùn mí pẹ̀lú ìpàdé rẹ';
      case 'ig':
        return 'Ọ dị mma izute gị';
      case 'sw':
        return 'Nimefurahi kukutana nawe';
      default:
        return 'Nice to meet you';
    }
  }

  String _getTopicStarter(String languageCode, String topic) {
    // Generate topic-specific starter
    return 'Let us talk about $topic';
  }

  String _getTopicResponse(String languageCode, String topic) {
    return 'I think about $topic...';
  }

  String _getFollowUpQuestion(String languageCode, String topic) {
    return 'Can you tell me more?';
  }

  String _getDiscussionStarter(String languageCode, String topic) {
    return 'Let us discuss $topic in detail';
  }

  String _getDiscussionResponse(String languageCode, String topic) {
    return 'I would like to discuss $topic';
  }

  String _getQuestion(String languageCode, String topic) {
    return 'What do you know about $topic?';
  }

  String _getAnswer(String languageCode, String topic) {
    return 'I know that $topic...';
  }

  String _getCulturalQuestion(String languageCode, String topic) {
    return 'What is the cultural significance of $topic?';
  }

  String _getCulturalResponse(String languageCode, String topic) {
    return 'In our culture, $topic...';
  }

  String _getFarewell(String languageCode) {
    switch (languageCode) {
      case 'yo':
        return 'Ó dàbọ̀';
      case 'ig':
        return 'Ka ọ dị';
      case 'sw':
        return 'Kwaheri';
      default:
        return 'Goodbye';
    }
  }

  String _getFarewellResponse(String languageCode) {
    switch (languageCode) {
      case 'yo':
        return 'Ó dàbọ̀ pẹ̀lú';
      case 'ig':
        return 'Ka ọ dị';
      case 'sw':
        return 'Kwaheri';
      default:
        return 'Goodbye';
    }
  }
}


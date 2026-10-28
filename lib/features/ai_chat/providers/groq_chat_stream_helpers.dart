part of 'package:lingafriq/providers/ai_chat_provider_groq.dart';

mixin GroqChatStreamHelpers on GroqChatProviderMixin1 {
  String _adaptiveTutorPrompt(String language) {
    if (_random.nextDouble() < 0.3) {
      final roleplayEntry = RoleplayDataset.getRandomForLanguage(language);
      if (roleplayEntry != null) {
        return "Roleplay: ${roleplayEntry.scenario}. ${roleplayEntry.userUtterance}";
      }
    }
    final stages = [
      "Translate to $language:",
      "Say this in $language:",
      "Respond in $language:",
      "Translate a longer sentence to $language:",
      "Create a sentence using two words in $language:",
    ];
    final prompt = stages[_turnIndex % stages.length];
    _turnIndex++;
    return prompt;
  }

  void _evaluateUser(String user, String assistant) {
    final correct = assistant.toLowerCase().contains('correct') ||
        assistant.toLowerCase().contains('nice') ||
        assistant.toLowerCase().contains('good job') ||
        assistant.toLowerCase().contains('yes') ||
        assistant.toLowerCase().contains('excellent');

    if (correct) {
      _successStreak++;
      _failureStreak = 0;
    } else {
      _failureStreak++;
      _successStreak = 0;
    }

    if (_successStreak >= 3 && _difficulty < 5) {
      _difficulty++;
      _successStreak = 0;
    }

    if (_failureStreak >= 2 && _difficulty > 1) {
      _difficulty--;
      _failureStreak = 0;
    }

    _updateLearningEngine(user, assistant, correct);
  }

  Future<void> _updateLearningEngine(
    String userMessage,
    String assistantResponse,
    bool wasCorrect,
  ) async {
    try {
      final bridge = LearningEngineBridge.instance;
      const learnerId = 'default_user';
      final modeName = _mode.toString().split('.').last;

      _lastLearningUpdate = await bridge.onChatInteraction(
        learnerId: learnerId,
        languageCode: _targetLanguage.toLowerCase(),
        mode: modeName,
        userMessage: userMessage,
        aiResponse: assistantResponse,
        responseTimeSeconds: _lastResponseTime,
        wasCorrect: wasCorrect,
      );

      if (_lastLearningUpdate != null) {
        _lastXpEarned = _lastLearningUpdate!.xpEarned;
        _lastMasteryDelta = _lastLearningUpdate!.masteryDelta;
      }
    } catch (_) {}
  }

  LearningEngineUpdate? _lastLearningUpdate;
  int _lastXpEarned = 0;
  double _lastMasteryDelta = 0;
  double _lastResponseTime = 0;

  String? _dueReview() {
    final now = DateTime.now();
    for (final entry in _memory.entries) {
      if (entry.value.nextReview.isBefore(now)) {
        return entry.key;
      }
    }
    return null;
  }
}

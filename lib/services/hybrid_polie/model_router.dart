// Hybrid Polie Model Router
// Routes tasks to the best model for each specific task
// Combines LLaMA-3.1-70B (dialogue/roleplay) with specialist models (translation/orthography)

enum TaskType {
  translate,
  tutor,
  roleplay,
  conversation,
  vocab,
  review,
  pronunciation,
  canonicalPhrase,
  generalChat,
}

enum ModelType {
  llama70b,      // LLaMA-3.1-70B-Versatile - for dialogue, roleplay, tutoring
  gemini,        // Gemini via backend orchestration for long-context dialogue
  nllb200,       // NLLB-200 - for translation
  afriteva,      // AfriTeVa/AfriT5 - for canonical phrase generation
  asrMfa,        // ASR + MFA - for pronunciation scoring
}

class ModelRouter {
  /// Route task to appropriate model based on intent and language
  static ModelType routeTask({
    required TaskType taskType,
    required String language,
    required String? sourceLanguage,
    bool isTranslation = false,
    bool needsCanonical = false,
  }) {
    // Translation tasks → NLLB-200
    if (taskType == TaskType.translate || isTranslation) {
      return ModelType.nllb200;
    }
    
    // Canonical phrase generation → AfriTeVa
    if (taskType == TaskType.canonicalPhrase || needsCanonical) {
      return ModelType.afriteva;
    }
    
    // Pronunciation scoring → ASR + MFA
    if (taskType == TaskType.pronunciation) {
      return ModelType.asrMfa;
    }
    
    const geminiPreferredLanguages = <String>{
      'yoruba', 'yo',
      'hausa', 'ha',
      'igbo', 'ig',
      'swahili', 'sw',
      'amharic', 'am',
      'zulu', 'zu',
      'xhosa', 'xh',
      'kinyarwanda', 'rw',
      'somali', 'so',
    };
    final normalizedLanguage = language.trim().toLowerCase();

    // Dialogue, roleplay, tutoring, conversation -> Gemini for high-context
    // African-language coaching, then fallback to LLaMA in orchestrator.
    if (taskType == TaskType.roleplay ||
        taskType == TaskType.tutor ||
        taskType == TaskType.conversation) {
      if (geminiPreferredLanguages.contains(normalizedLanguage)) {
        return ModelType.gemini;
      }
      return ModelType.llama70b;
    }

    if (taskType == TaskType.vocab ||
        taskType == TaskType.review ||
        taskType == TaskType.generalChat) {
      return ModelType.llama70b;
    }
    
    // Default to LLaMA for general tasks
    return ModelType.llama70b;
  }
  
  /// Determine if canonical phrase injection is needed
  static bool needsCanonicalPhrase(TaskType taskType, String language) {
    return taskType == TaskType.tutor ||
           taskType == TaskType.vocab ||
           (taskType == TaskType.roleplay && language != 'en');
  }
}


part of 'package:lingafriq/providers/ai_chat_provider_groq.dart';

mixin GroqChatProviderMixin1 on GroqChatPersistenceMixin {
  static String _modelName = GroqChatFieldsMixin._legacyModelLabels[0];

  static List<String> get polieGroqModelIds =>
      List<String>.unmodifiable(GroqChatFieldsMixin._legacyModelLabels);

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String get selectedLanguage => _selectedLanguage;
  String get targetLanguage => _targetLanguage;
  String get sourceLanguage => _sourceLanguage;
  String? get currentSystemPrompt => _systemPrompt;
  List<Map<String, String>> get supportedLanguageOptions =>
      List.unmodifiable(GroqChatFieldsMixin._supportedLanguageOptions);
  List<String> get supportedLanguages =>
      GroqChatFieldsMixin._supportedLanguageOptions
          .map((e) => e['name'] ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
  bool get hasMessages => _messages.isNotEmpty;
  bool get isBusy => state.isLoading;
  CEFRInfo get cefrInfo => _cefrInfo;
  ConversationTurn get turn => _turn;
  bool get tutorMode => _tutorMode;
  int get difficulty => _difficulty;
  PolieMode get mode => _mode;
  bool get isTranslationMode => _mode == PolieMode.translation;

  double _temperatureForMode() {
    switch (_mode) {
      case PolieMode.translation:
        return 0.1;
      case PolieMode.roleplay:
        return 0.85;
      case PolieMode.conversation:
        return 0.75;
      case PolieMode.tutor:
        return 0.45;
      case PolieMode.vocab:
      case PolieMode.review:
        return 0.35;
      case PolieMode.pronunciation:
      case PolieMode.grammar:
        return 0.4;
    }
  }

  int _maxTokensForMode() {
    switch (_mode) {
      case PolieMode.translation:
        return 500;
      case PolieMode.roleplay:
        return 900;
      case PolieMode.tutor:
        return 900;
      case PolieMode.conversation:
        // Conversation needs enough budget for multi-sentence replies plus optional translations.
        return 1400;
      case PolieMode.vocab:
      case PolieMode.review:
      case PolieMode.pronunciation:
      case PolieMode.grammar:
        return 700;
    }
  }

  String _applyModeOutputContract(String rawOutput) {
    final trimmed = rawOutput.trim();
    if (trimmed.isEmpty) return trimmed;

    if (_mode == PolieMode.translation) {
      final lower = trimmed.toLowerCase();
      if (!lower.startsWith('translation:')) {
        return 'Translation: $trimmed';
      }
    }
    return trimmed;
  }

  bool _historyLoaded = false;

  @override
  BaseProviderState build() {
    // Only load history once on first build
    if (!_historyLoaded) {
      // Load mode and language FIRST before loading history
      // This ensures the correct mode×language scoped history is loaded
      _loadModeAndLanguage().then((_) {
        _loadChatHistory();
        _loadSRSMemory();
        _loadCEFRInfo();
        _initializeRoleplayDataset();
        _historyLoaded = true;
      });
    }
    _initializeSystemPrompt();
    return BaseProviderState();
  }
  
  /// Load last used mode and language from preferences
  Future<void> _loadModeAndLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load last mode
      final savedMode = prefs.getString('polie_last_mode');
      if (savedMode != null) {
        _mode = PolieMode.values.firstWhere(
          (m) => m.toString().split('.').last == savedMode,
          orElse: () => PolieMode.tutor,
        );
      }
      
      // Load last language
      final savedLanguage = prefs.getString('polie_last_language');
      if (savedLanguage != null && savedLanguage.isNotEmpty) {
        _targetLanguage = savedLanguage;
        _selectedLanguage = savedLanguage;
      }
      
      logger.info('Loaded last session', tag: 'ai-chat', context: {'mode': _mode.name, 'language': _targetLanguage});
    } catch (e) {
      logger.error('Error loading mode/language preferences', tag: 'ai-chat', error: e);
    }
  }
  
  /// Save current mode and language to preferences
  Future<void> _saveModeAndLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('polie_last_mode', _mode.toString().split('.').last);
      await prefs.setString('polie_last_language', _targetLanguage);
    } catch (e) {
      logger.error('Error saving mode/language preferences', tag: 'ai-chat', error: e);
    }
  }
  
  /// Initialize roleplay dataset on first build
  void _initializeRoleplayDataset() {
    if (RoleplayDataset.count == 0) {
      RoleplayDatasetLoader.loadBlock1();
      logger.info('Loaded roleplay entries', tag: 'ai-chat', context: {'count': RoleplayDataset.count});
    }
  }

  /// Shared line appended to every mode prompt: user's focus language and gentle redirect.
  String _languageFocusBlock() =>
      "LANGUAGE FOCUS: The user's selected focus language is $_targetLanguage. Default all examples, translations, and exercises to this language. If the user asks about a different language, answer briefly but remind them: \"By the way, you're currently learning $_targetLanguage. Would you like to switch, or keep $_targetLanguage as your focus?\"";

  String _scenarioHintsBlock() {
    final practice = _practiceTypeHint?.trim();
    final scenarioType = _scenarioTypeHint?.trim();
    final context = _scenarioContextHint;
    if ((practice == null || practice.isEmpty) &&
        (scenarioType == null || scenarioType.isEmpty) &&
        (context == null || context.isEmpty)) {
      return '';
    }

    final buffer = StringBuffer('\n\nSCENARIO HINTS:\n');
    if (practice != null && practice.isNotEmpty) {
      buffer.writeln('- Practice type: $practice.');
      if (practice == 'debate') {
        buffer.writeln(
          '- Debate framing: present balanced viewpoints, ask for evidence, and challenge weak claims politely.',
        );
      } else if (practice == 'photo') {
        buffer.writeln(
          '- Photo framing: anchor replies to visual details from the scene description and ask clarifying follow-up questions.',
        );
      } else if (practice == 'conversation') {
        buffer.writeln('- Conversation framing: keep interaction natural and practical for real-world dialogue.');
      }
    }
    if (scenarioType != null && scenarioType.isNotEmpty) {
      buffer.writeln('- Scenario type: $scenarioType.');
    }
    if (context != null && context.isNotEmpty) {
      final title = context['scenarioTitle']?.toString();
      final description = context['scenarioDescription']?.toString();
      final scene = context['scenarioText']?.toString();
      if (title != null && title.trim().isNotEmpty) {
        buffer.writeln('- Scenario title: ${title.trim()}.');
      }
      if (description != null && description.trim().isNotEmpty) {
        buffer.writeln('- Scenario description: ${description.trim()}.');
      }
      if (scene != null && scene.trim().isNotEmpty) {
        buffer.writeln('- Scenario context: ${scene.trim()}.');
      }
    }
    return buffer.toString().trimRight();
  }

  void _initializeSystemPrompt() {
    _systemPrompt = null;
  }

  AiGatewayClient get _gateway => AiGatewayClient(ref.read(client));

  Dio get _gatewayDio => ref.read(client);

  String get _gatewayMode =>
      AiGatewayClient.gatewayModeForPolie(_mode.name);

  Future<void> setLanguage(String language) async {
    // Save current chat history before switching languages
    if (_targetLanguage != language) {
      await _saveChatHistory();
    }
    
    _selectedLanguage = language;
    _targetLanguage = language;
    
    // Clear current messages and load history for new language
    _messages.clear();
    await _loadChatHistory();
    
    _initializeSystemPrompt();
    state = state.copyWith();
  }

  /// Set language direction and load scoped chat history (mode × language)
  /// This ensures each mode × language combination has its own conversation history
  Future<void> setLanguageDirection(String sourceLanguage, String targetLanguage) async {
    // Save current chat history before switching languages (if language changed)
    if (_sourceLanguage != sourceLanguage || _targetLanguage != targetLanguage) {
      await _saveChatHistory();
    }
    
    _sourceLanguage = sourceLanguage;
    _targetLanguage = targetLanguage;
    _selectedLanguage = targetLanguage;
    _initializeSystemPrompt();
    
    // Clear current messages and load history for new mode × language combination
    _messages.clear();
    await _loadChatHistory();
    
    state = state.copyWith();
  }

  Future<void> setMode(PolieMode mode) async {
    if (_mode == mode) return;
    
    // Save current chat history before switching modes (scoped by mode × language)
    await _saveChatHistory();
    
    // Switch to new mode
    _mode = mode;
    _tutorMode = mode == PolieMode.tutor;
    
    // Reset roleplay state when switching away from roleplay
    if (mode != PolieMode.roleplay) {
      _currentRoleplayScenario = null;
      _roleplayTurnCount = 0;
      _roleplayBranches.clear();
    }
    _practiceTypeHint = null;
    _scenarioTypeHint = null;
    _scenarioContextHint = null;
    
    // Save mode preference for persistence
    await _saveModeAndLanguage();
    
    // Clear current messages and load history for new mode × language combination
    _messages.clear();
    await _loadChatHistory();
    _initializeSystemPrompt();
    
    // Notify listeners of the change
    state = state.copyWith();
    
    final modeName = _mode == PolieMode.translation ? "Translation" 
        : _mode == PolieMode.tutor ? "Tutor"
        : _mode == PolieMode.roleplay ? "Roleplay"
        : _mode == PolieMode.conversation ? "Conversation"
        : _mode == PolieMode.vocab ? "Vocab"
        : _mode == PolieMode.pronunciation ? "Pronunciation"
        : _mode == PolieMode.grammar ? "Grammar"
            : "Review";
    logger.info('Switched mode', tag: 'ai-chat', context: {'mode': modeName, 'messagesCount': _messages.length});
  }
  
  /// Atomically set mode AND language in one operation.
  /// This avoids the race condition where setMode saves/loads with the wrong
  /// language, then setLanguage saves/loads again with the wrong mode key.
  /// The chat history key is: ai_chat_history_groq_{mode}_{language}
  /// Prepends bible/persona context to the active system prompt (conversation mode).
  void prependToSystemPrompt(String prefix) {
    final p = prefix.trim();
    if (p.isEmpty) return;
    final existing = _systemPrompt?.trim() ?? '';
    _systemPrompt = existing.isEmpty ? p : '$p\n\n$existing';
    state = state.copyWith();
  }

  Future<void> setModeAndLanguage({
    required PolieMode mode,
    required String targetLanguage,
    String sourceLanguage = 'English',
  }) async {
    // 1. Save current history under the CURRENT key before switching anything
    await _saveChatHistory();

    // 2. Update all fields at once (no intermediate save/load)
    _mode = mode;
    _tutorMode = mode == PolieMode.tutor;
    _sourceLanguage = sourceLanguage;
    _targetLanguage = targetLanguage;
    _selectedLanguage = targetLanguage;

    if (mode != PolieMode.roleplay) {
      _currentRoleplayScenario = null;
      _roleplayTurnCount = 0;
      _roleplayBranches.clear();
    }
    _practiceTypeHint = null;
    _scenarioTypeHint = null;
    _scenarioContextHint = null;

    // 3. Persist preferences
    await _saveModeAndLanguage();

    // 4. Clear and load history for the NEW key (correct mode × language)
    _messages.clear();
    await _loadChatHistory();
    _initializeSystemPrompt();

    state = state.copyWith();

    final modeName = _mode.toString().split('.').last;
    logger.info('Switched mode+language atomically', tag: 'ai-chat', context: {
      'mode': modeName,
      'language': targetLanguage,
      'messagesCount': _messages.length,
    });
  }

  Future<void> setScenarioContextHints({
    String? practiceType,
    String? scenarioType,
    Map<String, dynamic>? scenarioContext,
  }) async {
    _practiceTypeHint = practiceType?.trim().isEmpty ?? true ? null : practiceType!.trim().toLowerCase();
    _scenarioTypeHint = scenarioType?.trim().isEmpty ?? true ? null : scenarioType!.trim();
    _scenarioContextHint = scenarioContext == null ? null : Map<String, dynamic>.from(scenarioContext);
    _initializeSystemPrompt();
    state = state.copyWith();
  }

  /// Set the current roleplay scenario and add an initial AI message that sets the scene.
  Future<void> setRoleplayScenario(RoleplayEntry scenario) async {
    _currentRoleplayScenario = scenario;
    _roleplayTurnCount = 0;
    _roleplayBranches.clear();
    _roleplayProgress.clear();
    _initializeSystemPrompt();

    final sceneIntro = _buildRoleplayInitialMessage(scenario);
    _messages.add(ChatMessage(
      role: 'assistant',
      content: sceneIntro,
      timestamp: DateTime.now(),
    ));
    state = state.copyWith();
    await _saveChatHistory();
    logger.info('Set roleplay scenario', tag: 'ai-chat', context: {'scenario': scenario.scenario});
  }

  String _buildRoleplayInitialMessage(RoleplayEntry scenario) {
    final place = scenario.scenario;
    final phrase = scenario.assistantResponse.trim();
    final note = scenario.notes.trim();
    final translation = note.isNotEmpty ? ' ($note)' : (phrase.isNotEmpty ? ' (Listen and reply when ready.)' : '');
    return "Welcome! You've just arrived at $place. $phrase$translation";
  }
  
  /// Get current roleplay scenario
  RoleplayEntry? get currentRoleplayScenario => _currentRoleplayScenario;

  /// Returns the welcome message for the given mode and target language.
  /// Roleplay uses the initial scene message from the scenario instead.
  static String getWelcomeMessage(PolieMode mode, String targetLanguage) {
    final lang = targetLanguage.isEmpty ? 'your language' : targetLanguage;
    switch (mode) {
      case PolieMode.translation:
        return "I'll help you translate between English and $lang. Type any word or phrase!";
      case PolieMode.tutor:
        return "Welcome to your $lang lesson! What would you like to learn about? I can teach you about: verbs, nouns, greetings, numbers, grammar rules, or any topic you choose.";
      case PolieMode.roleplay:
        return "Scenario set. I'll start the conversation — watch for my first message setting the scene.";
      case PolieMode.conversation:
        return "Hi! Let's chat in $lang. I'll help you practice natural conversation. Don't worry about mistakes — I'll gently correct you as we talk. What's on your mind?";
      case PolieMode.vocab:
        return "Let's build your $lang vocabulary! I'll teach you new words with pronunciation, meaning, and examples. Ready? Let's start with 5 essential words.";
      case PolieMode.review:
        return "Time to review what you've learned! I'll quiz you on your vocabulary and grammar. Let's see how much you remember!";
      case PolieMode.pronunciation:
        return "Let's work on your pronunciation! I'll guide you through sounds, tones, and phonetics for $lang. Practice with me.";
      case PolieMode.grammar:
        return "Grammar time! I'll teach you rules and patterns for $lang with clear examples and practice. What would you like to learn?";
    }
  }

  /// Stable mode identity tags used to validate mode differentiation in tests.
  Future<void> setTutorMode(bool enabled) async {
    await setMode(enabled ? PolieMode.tutor : PolieMode.translation);
  }

  void interruptAI() {
    _userInterrupt = true;
    _currentStreamCancel?.call();
  }

  // Hybrid Polie orchestrator (optional - can be enabled via feature flag)
  bool _useHybridPolie = true; // Enable hybrid mode by default
  HybridPolieOrchestrator? _hybridOrchestrator;
  
  /// Enable/disable hybrid Polie mode
  void setHybridMode(bool enabled) {
    _useHybridPolie = enabled;
    if (enabled && _hybridOrchestrator == null) {
      _hybridOrchestrator = HybridPolieOrchestrator();
    }
  }

  // ----- Streaming Chat Message -----
  /// Sanitize and validate user input to prevent errors
  String _sanitizeInput(String input) {
    // Remove null bytes and control characters (except newlines and tabs)
    String sanitized = input.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'), '');
    
    // Normalize whitespace (collapse multiple spaces, preserve newlines)
    sanitized = sanitized.replaceAll(RegExp(r'[ \t]+'), ' ');
    
    // Trim but preserve intentional spacing
    sanitized = sanitized.trim();
    
    // Ensure proper encoding (handle any encoding issues)
    try {
      utf8.decode(utf8.encode(sanitized));
    } catch (e) {
      logger.warn('Encoding issue detected, fixing', tag: 'ai-chat', error: e);
      sanitized = input.replaceAll(RegExp(r'[^\x20-\x7E\n\t]'), '');
    }
    
    return sanitized;
  }

  /// Enhanced JSON parsing with fallback handling
}

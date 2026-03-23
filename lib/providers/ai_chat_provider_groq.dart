import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';
import 'api_provider.dart';
import 'backend_sync_provider.dart';
import 'user_provider.dart';
import 'package:lingafriq/services/learning_engine_bridge.dart';
import '../config/url_constants.dart';
import '../utils/diacritics_enforcer.dart';
import '../data/roleplay_dataset.dart';
import '../services/hybrid_polie/hybrid_polie_orchestrator.dart';
import '../services/telemetry_service.dart';
import '../services/env_config.dart';
import '../utils/supported_languages.dart';
import '../services/ai/conversation_context_manager.dart';
import '../services/ai/conversation_practice_enhancer.dart';
import '../services/error/error_recovery_service.dart';
import '../services/monitoring/performance_analytics.dart';
import '../utils/structured_logger.dart';
import '../utils/api_service.dart';

/// Comprehensive AI Chat Provider using Groq API with Aya 8B
/// Features:
/// - Streaming responses
/// - Adaptive tutor mode
/// - Spaced repetition system (SRS)
/// - CEFR level tracking
/// - Grammar error detection
/// - Pronunciation scoring
/// - Speech shadowing
/// - Listening comprehension
/// - Curriculum generation
/// 
/// To use:
/// 1. Get a free Groq API key: https://console.groq.com/
/// 2. Replace YOUR_GROQ_API_KEY below or use environment variable
/// 3. The API is FREE with unlimited usage (no credit card required)

final groqChatProvider = NotifierProvider<GroqChatProvider, BaseProviderState>(() {
  return GroqChatProvider();
});

// Re-export ChatMessage class
class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'],
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

// Word Memory for SRS (SM-2 variant)
class WordMemory {
  double ease = 2.5; // Ease factor (SM-2 algorithm)
  int repetitions = 0; // Number of successful reviews
  int intervalDays = 1; // Days until next review
  DateTime nextReview = DateTime.now();
  int attempts = 0;
  int successes = 0;
  int strength = 0; // Legacy: 0-5 (mapped from repetitions)

  WordMemory({
    this.ease = 2.5,
    this.repetitions = 0,
    this.intervalDays = 1,
    DateTime? nextReview,
    this.attempts = 0,
    this.successes = 0,
  }) : nextReview = nextReview ?? DateTime.now() {
    // Map repetitions to legacy strength for backward compatibility
    strength = repetitions.clamp(0, 5);
  }

  /// Update SRS using SM-2 variant algorithm
  /// Quality: 0-5 (0=complete blackout, 5=perfect recall)
  void updateWithSM2(int quality) {
    if (quality < 3) {
      // Failed: reset
      repetitions = 0;
      intervalDays = 1;
    } else {
      // Passed: update
      if (repetitions == 0) {
        intervalDays = 1;
      } else if (repetitions == 1) {
        intervalDays = 6;
      } else {
        intervalDays = (intervalDays * ease).round();
      }
      repetitions++;
    }
    
    // Update ease factor (SM-2 formula)
    ease = (ease + 0.1 - (5 - quality) * 0.08).clamp(1.3, double.infinity);
    
    // Update next review date
    nextReview = DateTime.now().add(Duration(days: intervalDays));
    
    // Update legacy strength
    strength = repetitions.clamp(0, 5);
    
    attempts++;
    if (quality >= 3) successes++;
  }

  Map<String, dynamic> toJson() => {
        'ease': ease,
        'repetitions': repetitions,
        'intervalDays': intervalDays,
        'strength': strength,
        'nextReview': nextReview.toIso8601String(),
        'attempts': attempts,
        'successes': successes,
      };

  factory WordMemory.fromJson(Map<String, dynamic> json) => WordMemory(
        ease: (json['ease'] ?? 2.5).toDouble(),
        repetitions: json['repetitions'] ?? 0,
        intervalDays: json['intervalDays'] ?? 1,
        nextReview: DateTime.parse(json['nextReview']),
        attempts: json['attempts'] ?? 0,
        successes: json['successes'] ?? 0,
      );
}

// CEFR Info
class CEFRInfo {
  String level; // A1, A2, B1, B2, C1, C2
  double score; // 0-100
  DateTime lastUpdated;

  CEFRInfo({
    required this.level,
    required this.score,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'level': level,
        'score': score,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory CEFRInfo.fromJson(Map<String, dynamic> json) => CEFRInfo(
        level: json['level'] ?? 'A1',
        score: (json['score'] ?? 0.0).toDouble(),
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}

// Grammar Feedback
class GrammarFeedback {
  final String corrected;
  final List<Map<String, String>> errors;
  final double score; // 0.0-1.0

  GrammarFeedback({
    required this.corrected,
    required this.errors,
    required this.score,
  });
}

// Conversation Turn
enum ConversationTurn { user, ai }

// Polie chat modes - Premium version with all modes
enum PolieMode { translation, tutor, roleplay, conversation, vocab, review, pronunciation, grammar }

class GroqChatProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  final List<ChatMessage> _messages = [];
  final Dio _dio = Dio();

  // API Configuration - uses centralized EnvConfig
  static String get _groqApiKey => EnvConfig.groqApiKey;

  static String get _groqUrl => UrlConstants.groqChatCompletions;
  // Groq model names to try in order (favor accuracy for African languages)
  // Note: Aya 8B can be less reliable for some translations (e.g., Yoruba),
  // so we prefer the larger Llama model first for quality, then fall back.
  // Verified available on Groq (Feb 2026). aya-8b is NOT available on Groq.
  // See https://console.groq.com/docs/models for the current model list.
  static const List<String> _modelNames = [
    'llama-3.3-70b-versatile',   // Highest quality, multilingual, free on Groq
    'llama-3.1-8b-instant',      // Faster fallback (~560 tok/s)
  ];
  static String _modelName = _modelNames[0];

  // Supported African languages list (text + speech-friendly where possible)
  static const List<Map<String, String>> _supportedLanguageOptions = [
    {'name': 'Yoruba', 'flag': '🇳🇬', 'code': 'yo'},
    {'name': 'Hausa', 'flag': '🇳🇬', 'code': 'ha'},
    {'name': 'Igbo', 'flag': '🇳🇬', 'code': 'ig'},
    {'name': 'Swahili', 'flag': '🇰🇪', 'code': 'sw'},
    {'name': 'Zulu', 'flag': '🇿🇦', 'code': 'zu'},
    {'name': 'Xhosa', 'flag': '🇿🇦', 'code': 'xh'},
    {'name': 'Amharic', 'flag': '🇪🇹', 'code': 'am'},
    {'name': 'Twi', 'flag': '🇬🇭', 'code': 'tw'},
    {'name': 'Afrikaans', 'flag': '🇿🇦', 'code': 'af'},
    {'name': 'Nigerian Pidgin', 'flag': '🇳🇬', 'code': 'pcm'},
  ];

  // Language and System Prompt
  String _selectedLanguage = 'Yoruba';
  String _sourceLanguage = 'English'; // Language user speaks
  String _targetLanguage = 'Yoruba'; // Language user wants to learn
  String? _systemPrompt;
  PolieMode _mode = PolieMode.tutor;

  // Tutor & Adaptive Fields
  bool _tutorMode = true;
  // ignore: unused_field
  final bool _adaptive = true;
  int _difficulty = 1; // 1-5
  int _successStreak = 0;
  int _failureStreak = 0;
  int _turnIndex = 0;

  // Spaced Repetition
  final Map<String, WordMemory> _memory = {};

  // CEFR Tracking
  CEFRInfo _cefrInfo = CEFRInfo(level: 'A1', score: 0.0);

  // Metrics for averaging
  final List<double> _recentGrammarScores = [];
  final List<double> _recentPronScores = [];
  final List<double> _recentCompScores = [];
  final List<double> _recentVocabScores = [];

  // Conversational turn-taking
  ConversationTurn _turn = ConversationTurn.user;
  bool _userInterrupt = false;
  VoidCallback? _currentStreamCancel;
  
  // Backend sync debouncing
  DateTime? _lastBackendSync;

  // Conversation enhancement services
  final ConversationContextManager _contextManager = ConversationContextManager();
  final ConversationPracticeEnhancer _practiceEnhancer = ConversationPracticeEnhancer();
  final ErrorRecoveryService _errorRecovery = ErrorRecoveryService();
  final PerformanceAnalytics _performanceAnalytics = PerformanceAnalytics();
  
  // Roleplay scenario tracking
  RoleplayEntry? _currentRoleplayScenario;
  int _roleplayTurnCount = 0;
  final List<String> _roleplayBranches = [];
  final Map<String, dynamic> _roleplayProgress = {};
  String? _practiceTypeHint;
  String? _scenarioTypeHint;
  Map<String, dynamic>? _scenarioContextHint;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String get selectedLanguage => _selectedLanguage;
  String get targetLanguage => _targetLanguage;
  String get sourceLanguage => _sourceLanguage;
  String? get currentSystemPrompt => _systemPrompt;
  List<Map<String, String>> get supportedLanguageOptions => List.unmodifiable(_supportedLanguageOptions);
  List<String> get supportedLanguages =>
      _supportedLanguageOptions.map((e) => e['name'] ?? '').where((e) => e.isNotEmpty).toList();
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
        // Headroom for diacritics + multi-line Translation / Notes blocks (avoid cut-off).
        return 1024;
      case PolieMode.roleplay:
        return 1200;
      case PolieMode.tutor:
        return 1200;
      case PolieMode.conversation:
        return 1200;
      case PolieMode.vocab:
      case PolieMode.review:
      case PolieMode.pronunciation:
      case PolieMode.grammar:
        return 900;
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
    // Polie Premium: Enhanced system prompts for all modes
    if (_mode == PolieMode.translation) {
      _systemPrompt = '''You are Polie: an expert, culturally aware translation assistant for African languages.

MODE: TRANSLATE

RULES:
1. Confirm source/target only if missing; otherwise output translation first with canonical diacritics. No refusals or unnecessary clarifications.
2. For "How do you say X" or any phrase/sentence, provide the $_targetLanguage translation immediately.
3. Double-check kinship terms, directional words, and culturally-specific vocabulary. Cross-reference with multiple sources when uncertain.
4. Provide optional ASCII fallback in parentheses only if helpful. Add Usage (formal/informal) and brief Notes (1–2 lines).
5. Never start lessons or introduce other languages unless requested.

FEW-SHOT (error-prone terms): For Yoruba: egbon = older sibling, aburo = younger sibling, iya = mother, baba = father. Apply equivalent care for other languages.
GUARDRAIL: If unsure about a translation, say so and provide alternatives (e.g. "Possible translations: A) ... B) ...").

FORMAT:
Translation: <with diacritics>
ASCII: (<fallback>)
Usage: <register>
Notes: <1–2 lines>

ACCURACY: Use correct orthography and diacritics (e.g. Yoruba: Báwo, Ẹ káàrọ̀). For tonal languages, include tone marks; if ambiguous, give most likely option first then one short alternative.
SUPPORTED: Yoruba, Hausa, Igbo, Swahili, Zulu, Xhosa, Amharic, Twi, Afrikaans, Nigerian Pidgin — verify spelling and register.
CULTURAL: Use correct formal/informal and social hierarchy; point out polite alternatives where appropriate.

${SupportedLanguages.sourceLanguagePromptLine(_sourceLanguage)}
${SupportedLanguages.targetLanguagePromptLine(_targetLanguage)}

${_languageFocusBlock()}
${_scenarioHintsBlock()}

Be accurate, culturally appropriate, and instant.''';
      return;
    }

    if (_mode == PolieMode.tutor) {
      final cefrLevel = _cefrInfo.level;
      final cefrScore = _cefrInfo.score;

      _systemPrompt = '''You are Polie Premium: a structured, culturally-aware language tutor for African languages.

MODE: TUTOR

STRICT RULES:
- Do NOT tell stories or narratives unless the user explicitly requests one (e.g. "tell me a story").
- Always teach in the user's proficiency language (default: English) unless they specify otherwise.
- Structure every teaching response in this order: Explanation → Examples → Practice Exercise → Expected Answers (hidden until user attempts).

REQUIRED RESPONSE STRUCTURE:
1. **Explanation**: What the concept is (clear, concise; use the user's language).
2. **Examples**: At least 5 examples with translation and pronunciation (phonetic/IPA). Include usage in sentences.
3. **Practice Exercise**: 3–5 questions for the user (fill-in, multiple choice, translation, or short answer).
4. **Expected Answers**: Provide correct answers in a clearly marked section (e.g. "Expected answers (try first): ...") so the user can check after attempting.

When the user says "teach me about [topic]" (e.g. verbs, greetings, numbers):
- For verbs: list key verbs, meanings, conjugations, usage in sentences, pronunciation guides (phonetic), spelling/diacritic notes, then a short quiz.
- For any topic: same pattern — concept, 5+ examples with translation and pronunciation, then 3–5 practice questions and expected answers.

ADDITIONAL:
- Suggest connecting to pronunciation scoring when teaching sounds or phrases (e.g. "Try the pronunciation feature to get a score on this phrase.").
- Note important vocabulary for the user's word list (e.g. "Add to your list: [word1], [word2]").
- Use correct orthography and diacritics for the target language. CEFR context: $cefrLevel (${cefrScore.toStringAsFixed(0)}%).

${SupportedLanguages.sourceLanguagePromptLine(_sourceLanguage)}
${SupportedLanguages.targetLanguagePromptLine(_targetLanguage)}

${_languageFocusBlock()}
${_scenarioHintsBlock()}

Be encouraging, patient, and culturally sensitive. No storytelling unless asked.''';
      return;
    }
    
    if (_mode == PolieMode.roleplay) {
      final examples = RoleplayDataset.getFewShotExamples(_selectedLanguage, count: 3);
      String examplesText = '';
      if (examples.isNotEmpty) {
        examplesText = '\n\nFEW-SHOT EXAMPLES:\n';
        for (final example in examples) {
          examplesText += 'Scenario: ${example.scenario}\n';
          examplesText += 'User: ${example.userUtterance}\n';
          examplesText += 'Assistant: ${example.assistantResponse}\n';
          examplesText += 'Notes: ${example.notes}\n\n';
        }
      }

      String scenarioContext = '';
      if (_currentRoleplayScenario != null) {
        scenarioContext = '''

CURRENT SCENARIO:
Scenario: ${_currentRoleplayScenario!.scenario}
Context: ${_currentRoleplayScenario!.notes}
Example User Utterance: "${_currentRoleplayScenario!.userUtterance}"
Expected Response Style: "${_currentRoleplayScenario!.assistantResponse}"

Use this scenario. Play the role (e.g. shopkeeper, waiter). Track turns (current: $_roleplayTurnCount). Offer 2–3 branching choices when appropriate.
''';
      }

      _systemPrompt = '''You are Polie Premium in ROLEPLAY MODE: an immersive conversation partner for practicing $_targetLanguage.

MODE: ROLEPLAY

OPENING: You MUST speak first. Set the scene in BOTH the target language ($_targetLanguage) AND English translation. Example: "Welcome! You've just arrived at a busy market in Lagos. A vendor approaches you... [Yoruba: E kaabo! Se o fe ra nkankan?] (Welcome! Do you want to buy something?)"

AFTER EACH USER RESPONSE:
1. Gentle correction (if needed): briefly note the correct form and translation of what they said.
2. Translation: provide the meaning of what the user said in English.
3. Continue the conversation naturally in character. Stay in character; use natural, everyday vocabulary appropriate to the scenario.

TRACKING: Count turns. After 8–10 turns, provide a short summary: vocabulary learned, grammar points covered, and an accuracy/feedback note. Adapt difficulty (vocabulary and complexity) based on how the user is doing.
$scenarioContext

${SupportedLanguages.targetLanguagePromptLine(_targetLanguage)}
${SupportedLanguages.sourceLanguagePromptLine(_sourceLanguage)}
Current CEFR: ${_cefrInfo.level}. Difficulty: $_difficulty (1=Beginner, 5=Advanced).
$examplesText

${_languageFocusBlock()}
${_scenarioHintsBlock()}

Be encouraging, stay in character, and teach through natural dialogue.''';
      return;
    }
    
    if (_mode == PolieMode.conversation) {
      final defaultTopicSuggestions = ['Greetings', 'Weather', 'Food', 'Travel', 'Hobbies', 'Family', 'Work', 'Shopping', 'Health', 'Education'];

      _systemPrompt = '''You are Polie Premium: a warm, natural conversation partner for practicing $_targetLanguage.

MODE: CONVERSATION

BEHAVIOUR:
- Start with a warm, natural greeting. Adapt to user's proficiency (CEFR: ${_cefrInfo.level}).
- Engage naturally as a conversation partner while gently correcting errors. Corrections should be visible but not interrupting (e.g. "Nice! Small note: [correction]. You said '[attempt]' — the usual way is '[corrected]'.").
- Note interesting or new vocabulary as you go. After every 5 exchanges, briefly summarize new words learned (e.g. "Words we used: [list with short meanings]").
- Provide translations on demand: "Translation: [text]". Use topic suggestions when flow stalls: ${defaultTopicSuggestions.join(', ')}.

DIACRITICS (MANDATORY):
- ALWAYS use correct diacritics and tone marks for $_targetLanguage. This is non-negotiable.
- For Yoruba: use ẹ, ọ, ṣ, and tone marks (à, á, è, é, ì, í, ò, ó, ù, ú, ǹ, ń). Example: "Ẹ káàrọ̀" not "E kaaro", "Báwo ni" not "Bawo ni".
- For Igbo: use ụ, ọ, ị and proper marks. For Hausa: use ɓ, ɗ, ƙ where applicable.
- Never omit diacritics even in casual conversation. Learners must see correct orthography at all times.

${SupportedLanguages.targetLanguagePromptLine(_targetLanguage)}
${SupportedLanguages.sourceLanguagePromptLine(_sourceLanguage)}

${_languageFocusBlock()}
${_scenarioHintsBlock()}

Be warm, encouraging, and culturally sensitive.''';
      return;
    }
    
    if (_mode == PolieMode.vocab) {
      _systemPrompt = '''You are Polie Premium: a vocabulary tutor for $_targetLanguage.

MODE: VOCABULARY

PRESENT EACH WORD WITH:
- Word in target language (correct diacritics)
- Pronunciation (phonetic / IPA)
- Meaning (clear, brief)
- 2 example sentences (target + translation)
- Related words (synonyms, opposites, or same topic)

SPACED REPETITION: Present new words, then mix in previously learned words for reinforcement. Do not only introduce new items; revisit earlier words in the same session.
After presenting 5 new words, give a quick review quiz (e.g. "Quick quiz: What does [word] mean?" or match/translate) before introducing more.

Progress is tracked; prioritize words due for review when relevant. Current CEFR: ${_cefrInfo.level}.

${SupportedLanguages.targetLanguagePromptLine(_targetLanguage)}
${SupportedLanguages.sourceLanguagePromptLine(_sourceLanguage)}

${_languageFocusBlock()}
${_scenarioHintsBlock()}

Keep sessions engaging and reinforce retention.''';
      return;
    }
    
    if (_mode == PolieMode.review) {
      _systemPrompt = '''You are Polie Premium: a review and quiz partner for $_targetLanguage.

MODE: REVIEW

FOCUS: Test previously learned material. Do not introduce new vocabulary as the main goal; reinforce what the user has already seen.

QUESTION TYPES: Use a mix of multiple choice, fill-in-the-blank, and translation both ways (target→$_sourceLanguage and $_sourceLanguage→$_targetLanguage). One question at a time; give immediate feedback (correct/incorrect and brief explanation).

ORDER: Start with the most recently learned words, then mix in older ones. Track correct vs incorrect in your feedback and adjust difficulty (easier items if many errors, slightly harder if they are doing well). Celebrate progress (e.g. "3 in a row!", "Nice recall!").

After a batch of questions, give a short summary: how many correct, what to review again, and encouragement. Current CEFR: ${_cefrInfo.level}.

${SupportedLanguages.targetLanguagePromptLine(_targetLanguage)}
${SupportedLanguages.sourceLanguagePromptLine(_sourceLanguage)}

${_languageFocusBlock()}
${_scenarioHintsBlock()}

Keep reviews efficient and motivating.''';
      return;
    }

    if (_mode == PolieMode.pronunciation) {
      _systemPrompt = '''You are Polie Premium: a pronunciation coach for $_targetLanguage.

MODE: PRONUNCIATION

RESPONSE FORMAT (required):
1. Target phrase
2. IPA / phonetic guide
3. Mouth-position tip
4. Minimal pair practice
5. 1 short speaking drill

RULES:
1. Guide the learner through sounds, tones, and phonetic patterns of $_targetLanguage.
2. Provide IPA transcriptions when helpful.
3. Explain mouth/tongue positions for difficult sounds.
4. Give minimal pairs to distinguish similar sounds.
5. Encourage short, repeatable speaking drills.
6. Be culturally sensitive about regional pronunciation variants.
7. Keep each response practical and speaking-focused (no long grammar lectures).

${SupportedLanguages.targetLanguagePromptLine(_targetLanguage)}
${SupportedLanguages.sourceLanguagePromptLine(_sourceLanguage)}
${_languageFocusBlock()}
${_scenarioHintsBlock()}

Always respond in English with $_targetLanguage examples. Mark pronunciation-critical words in **bold**.''';
      return;
    }

    if (_mode == PolieMode.grammar) {
      _systemPrompt = '''You are Polie Premium: a grammar tutor for $_targetLanguage.

MODE: GRAMMAR

RESPONSE FORMAT (required):
1. Rule
2. Pattern template
3. Examples (target language + translation)
4. Practice questions (2-3)
5. Corrections rubric

RULES:
1. Teach grammar rules of $_targetLanguage with clear, simple explanations.
2. Provide sentence pattern templates with fill-in exercises.
3. Compare grammar structures to English when helpful.
4. Focus on one grammar concept at a time.
5. Give 2-3 practice sentences after each explanation.
6. Correct grammar errors gently with short explanations.
7. Keep explanations precise and avoid free-form conversation drift.

${SupportedLanguages.targetLanguagePromptLine(_targetLanguage)}
${SupportedLanguages.sourceLanguagePromptLine(_sourceLanguage)}
${_languageFocusBlock()}
${_scenarioHintsBlock()}

Always respond in English with $_targetLanguage examples.
Use structured format: Rule -> Example -> Practice.''';
      return;
    }

    // Default: Tutor mode (already set above)
  }

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
  static const Map<PolieMode, String> modeIdentityTags = {
    PolieMode.translation: 'translation-first',
    PolieMode.tutor: 'structured-teaching',
    PolieMode.roleplay: 'immersive-scenario',
    PolieMode.conversation: 'free-dialogue',
    PolieMode.vocab: 'lexical-growth',
    PolieMode.review: 'memory-recall',
    PolieMode.pronunciation: 'speech-coaching',
    PolieMode.grammar: 'rule-patterns',
  };

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
  Map<String, dynamic>? _parseJsonSafely(String jsonStr) {
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>?;
    } catch (e) {
      logger.error('JSON parse error', tag: 'ai-chat', error: e, context: {'preview': jsonStr.substring(0, jsonStr.length > 100 ? 100 : jsonStr.length)});
      // Try to extract partial data if possible
      try {
        // Remove problematic characters and try again
        final cleaned = jsonStr.replaceAll(RegExp(r'[\x00-\x1F]'), '');
        return jsonDecode(cleaned) as Map<String, dynamic>?;
      } catch (_) {
        return null;
      }
    }
  }

  Stream<String> sendMessageStream(String userMessage, {String? systemPromptOverride}) async* {
    final messageStartTime = DateTime.now();

    // Enhanced input validation and sanitization
    final sanitizedMessage = _sanitizeInput(userMessage);
    if (sanitizedMessage.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    // Validate message length (prevent extremely long messages)
    if (sanitizedMessage.length > 2000) {
      throw Exception('Message is too long. Please keep it under 2000 characters.');
    }

    _currentStreamCancel?.call();
    final cancelToken = CancelToken();
    _currentStreamCancel = () => cancelToken.cancel();

    final userMsg = ChatMessage(
      role: 'user',
      content: sanitizedMessage,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    
    // Track roleplay turns
    if (_mode == PolieMode.roleplay) {
      _roleplayTurnCount++;
      // Detect branching choices (A, B, C or similar patterns)
      final branchPattern = RegExp(r'\b([ABC]|option\s+[123]|choice\s+[123])\b', caseSensitive: false);
      if (branchPattern.hasMatch(sanitizedMessage)) {
        final match = branchPattern.firstMatch(sanitizedMessage);
        if (match != null) {
          _roleplayBranches.add(match.group(1) ?? '');
        }
      }
    }
    
    state = state.copyWith();
    await _saveChatHistory();

    state = state.copyWith(isLoading: true);
    
    // Use system prompt override if provided (for content generation)
    var effectiveSystemPrompt = systemPromptOverride ?? _systemPrompt;
    
    // Enhance system prompt with conversation practice features
    final conversationId = '${_mode}_${_selectedLanguage}_$_sourceLanguage';
    final flowState = _practiceEnhancer.analyzeConversationFlow(
      messages: _messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
      currentMessage: sanitizedMessage,
    );
    
    if (effectiveSystemPrompt != null && effectiveSystemPrompt.isNotEmpty) {
      final previousContext = _contextManager.getConversationInsights(conversationId);
      effectiveSystemPrompt = _practiceEnhancer.getEnhancedPrompt(
        conversationId: conversationId,
        flowState: flowState,
        basePrompt: effectiveSystemPrompt,
        currentTopic: previousContext['topics']?.isNotEmpty == true 
            ? (previousContext['topics'] as List).first 
            : null,
        userLevel: previousContext['user_level'] as String?,
        previousContext: previousContext.isNotEmpty ? previousContext : null,
      );
    }
    
    // Use Hybrid Polie if enabled and appropriate for the task
    if (_useHybridPolie && _hybridOrchestrator != null) {
      // Check if we should use hybrid routing
      final shouldUseHybrid = _mode == PolieMode.translation || 
                             _mode == PolieMode.tutor ||
                             _mode == PolieMode.vocab;
      
      if (shouldUseHybrid) {
        try {
          final hybridResponse = await _hybridOrchestrator!.orchestrate(
            userMessage: userMessage,
            mode: _mode,
            targetLanguage: _selectedLanguage,
            sourceLanguage: _sourceLanguage,
            groqProvider: this,
            hfToken: null, // Can be set via environment
          );
          
          // Translation: emit full string once (NLLB/GTranslate output must not look "chopped" in UI).
          if (_mode == PolieMode.translation) {
            if (!_userInterrupt) {
              yield hybridResponse.output;
            }
          } else {
            final words = hybridResponse.output.split(' ');
            for (int i = 0; i < words.length; i++) {
              if (_userInterrupt) {
                state = state.copyWith(isLoading: false);
                return;
              }

              final chunk = i == 0 ? words[i] : ' ${words[i]}';
              yield chunk;
              await Future.delayed(const Duration(milliseconds: 30));
            }
          }
          
          // Log telemetry if diacritics were corrected
          if (hybridResponse.diacriticsCorrected) {
            logger.info('Hybrid Polie: Diacritics corrected', tag: 'ai-chat', context: {'model': hybridResponse.model});
          }
          
          // Add assistant message
          final assistantMsg = ChatMessage(
            role: 'assistant',
            content: hybridResponse.output,
            timestamp: DateTime.now(),
          );
          _messages.add(assistantMsg);
          state = state.copyWith();
          await _saveChatHistory();
          
          // Save conversation context
          await _contextManager.saveConversationContext(
            conversationId: conversationId,
            messages: _messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
          );
          
          // Add tutor prompts if in tutor mode
          if (_tutorMode && !_userInterrupt) {
            final reviewWord = _dueReview();
            if (reviewWord != null) {
              final tutorCue = "Review time! Translate '$reviewWord' to $_selectedLanguage.";
              yield "\n\n$tutorCue";
            } else {
              final tutorCue = _adaptiveTutorPrompt(_selectedLanguage);
              if (!hybridResponse.output.trim().endsWith("?") &&
                  !hybridResponse.output.toLowerCase().contains("your turn") &&
                  !hybridResponse.output.toLowerCase().contains("now you try")) {
                yield "\n\n$tutorCue";
              }
            }
          }
          
          _turn = ConversationTurn.user;
          state = state.copyWith(isLoading: false);
          return;
        } catch (e) {
          logger.warn('Hybrid Polie failed, falling back to standard mode', tag: 'ai-chat', error: e);
          // Fall through to standard Groq implementation
        }
      }
    }

    int retryCount = 0;
    int modelIndex = 0;

    while (true) {
      try {
        _turn = ConversationTurn.ai;
        _userInterrupt = false;

        // Try different model names if previous one failed
        final currentModel = _modelNames[modelIndex];

        // Ensure system prompt is not empty (use override if provided)
        final systemPrompt = (systemPromptOverride ?? _systemPrompt)?.trim() ?? 'You are Polie, a helpful AI language assistant for African languages.';
        
        // Build messages array - CRITICAL: Groq API format
        // Groq expects:
        // - messages: array of {role: "user"|"assistant", content: string}
        // - system messages are passed separately (not in messages array for some models)
        // - For Groq, we can include system in messages array, but it's cleaner to pass separately
        
        var messagesList = <Map<String, dynamic>>[];
        
        // Filter messages by current mode and language to create scoped chat bodies
        // This ensures each mode × language combination has its own conversation history
        final scopedMessages = _messages.where((msg) {
          // Only include user and assistant messages (system is handled separately)
          return msg.content.trim().isNotEmpty && 
                 (msg.role == 'user' || msg.role == 'assistant');
        }).toList();
        
        // Add conversation messages, filtering out empty ones and ensuring valid roles
        for (final msg in scopedMessages) {
          final content = msg.content.trim();
          if (content.isNotEmpty) {
            // Ensure role is valid (user or assistant) - Groq only accepts these roles in messages array
            final role = (msg.role == 'user' || msg.role == 'assistant') 
                ? msg.role 
                : 'user';
            
            // Ensure content is a string and not null
            final contentStr = content.toString();
            if (contentStr.isNotEmpty && contentStr.length <= 100000) { // Groq has content length limits
              messagesList.add({
                "role": role,
                "content": contentStr,
              });
            }
          }
        }
        
        // CRITICAL: Ensure we have at least one user message (the current one)
        // The current user message should be the last one
        final currentUserMessage = sanitizedMessage.trim();
        if (currentUserMessage.isNotEmpty) {
          // Check if the last message is already this user message
          final lastMessage = messagesList.isNotEmpty ? messagesList.last : null;
          if (lastMessage == null || 
              lastMessage["role"] != "user" || 
              lastMessage["content"] != currentUserMessage) {
            // Add current user message
            messagesList.add({
              "role": "user",
              "content": currentUserMessage,
            });
          }
        }
        
        // Validate we have at least one user message
        final hasUserMessage = messagesList.any((m) => m["role"] == "user");
        if (messagesList.isEmpty || !hasUserMessage) {
          throw Exception('No valid messages to send. Please enter a message.');
        }
        
        // Final validation: Ensure all messages have required fields and correct types
        for (int i = 0; i < messagesList.length; i++) {
          final msg = messagesList[i];
          if (msg["role"] == null || msg["content"] == null) {
            throw Exception('Invalid message format at index $i: missing role or content');
          }
          if (msg["role"] is! String) {
            throw Exception('Invalid message format at index $i: role must be a string');
          }
          if (msg["content"] is! String) {
            // Convert to string if it's not already
            msg["content"] = msg["content"].toString();
          }
          final contentStr = msg["content"] as String;
          if (contentStr.isEmpty) {
            throw Exception('Invalid message format at index $i: content cannot be empty');
          }
          // Ensure role is valid (only user or assistant in messages array)
          if (msg["role"] != "user" && msg["role"] != "assistant") {
            throw Exception('Invalid message format at index $i: role must be "user" or "assistant"');
          }
        }
        
        // Ensure messages array is not empty after validation
        if (messagesList.isEmpty) {
          throw Exception('No valid messages after validation. Please try again.');
        }
        
        // Enhance conversation context with intelligent management
        final enhancedMessagesList = await _contextManager.getConversationContext(
          conversationId: conversationId,
          currentMessages: messagesList,
          systemPrompt: effectiveSystemPrompt ?? '',
          maxTokens: 2000, // Groq token limit consideration
        );
        
        // Use enhanced context (which may include summary)
        // Extract messages from enhanced context (excluding system prompt as it's added separately)
        messagesList = enhancedMessagesList
            .where((m) => m['role'] != 'system')
            .toList();
        
        // Limit messages array to last 20 messages (to avoid token limits)
        // Groq has token limits, so we keep recent conversation context
        if (messagesList.length > 20) {
          messagesList.removeRange(0, messagesList.length - 20);
        }
        
        // Update effective system prompt if enhanced context added a summary
        final enhancedSystemPrompt = enhancedMessagesList
            .where((m) => m['role'] == 'system')
            .map((m) => m['content'] as String)
            .join('\n\n');
        if (enhancedSystemPrompt.isNotEmpty) {
          effectiveSystemPrompt = enhancedSystemPrompt;
        }

        // When app has no Groq key, use backend completion proxy (no streaming)
        if (_groqApiKey.isEmpty || _groqApiKey == 'YOUR_GROQ_API_KEY') {
          try {
            await ApiService.initialize();
            final apiMessages = messagesList
                .map<Map<String, dynamic>>((m) => {'role': m['role'] as String, 'content': m['content'] as String})
                .toList();
            final resp = await ApiService.post(
              '/api/ai/chat/completion',
              data: {
                'messages': apiMessages,
                'systemPrompt': effectiveSystemPrompt ?? systemPrompt,
                'temperature': _temperatureForMode(),
                'max_tokens': _maxTokensForMode(),
                'language': _targetLanguage,
                'languageCode': SupportedLanguages.getLanguageCode(_targetLanguage),
                'sourceLanguage': SupportedLanguages.getLanguageCode(_sourceLanguage),
                'targetLanguage': SupportedLanguages.getLanguageCode(_targetLanguage),
                'cefr': _cefrInfo.level,
                'mode': _mode.name,
              },
            );
            if (resp.statusCode == 200 && resp.data != null) {
              final content = (resp.data is Map) ? (resp.data['content']?.toString() ?? '').trim() : '';
              if (content.isNotEmpty) {
                final modeConstrained = _applyModeOutputContract(content);
                final enforced = DiacriticsEnforcer.enforceWithMetadata(
                  modeConstrained,
                  _selectedLanguage,
                  enableFuzzy: true,
                  fuzzyThreshold: 0.75,
                );
                final correctedOutput = enforced['text'] as String;
                final assistantMessage = ChatMessage(
                  role: 'assistant',
                  content: correctedOutput,
                  timestamp: DateTime.now(),
                );
                _messages.add(assistantMessage);
                _turn = ConversationTurn.user;
                state = state.copyWith(isLoading: false);
                return;
              }
              throw Exception('AI returned an empty response. Please try again.');
            }
            // Non-200 response (e.g. if validateStatus allowed it): extract error from body
            final respData = resp.data;
            String errMsg = 'Request failed. Please try again.';
            if (respData is Map) {
              errMsg = (respData['error'] ?? respData['message'] ?? respData['detail'] ?? errMsg).toString();
            } else if (respData is String && respData.trim().isNotEmpty) {
              errMsg = respData.trim();
            }
            throw Exception(errMsg);
          } on DioException catch (e) {
            throw Exception(TransportErrorPolicy.toUserMessage(e));
          }
        }
        
        // Log the final message structure for debugging
        logger.debug('Sending to Groq API', tag: 'ai-chat', context: {
          'model': currentModel,
          'systemPromptLength': systemPrompt.length,
          'messagesCount': messagesList.length,
        });
        for (int i = 0; i < messagesList.length; i++) {
          final msg = messagesList[i];
          final content = msg["content"] as String;
          logger.debug('Message details', tag: 'ai-chat', context: {
            'index': i,
            'role': msg["role"],
            'contentLength': content.length,
            'preview': content.substring(0, content.length > 50 ? 50 : content.length),
          });
        }
        
        // Validate model name
        if (currentModel.isEmpty) {
          throw Exception('Invalid model configuration. Please check your settings.');
        }
        
        logger.debug('Sending to Groq', tag: 'ai-chat', context: {'model': currentModel, 'messagesCount': messagesList.length});
        
        // Track request start time for performance metrics
        final requestStartTime = DateTime.now();
        final performanceTrackingId = _performanceAnalytics.startTracking(
          operationName: 'groq_api_call',
          metadata: {
            'model': currentModel,
            'message_count': messagesList.length,
            'mode': _mode.toString(),
          },
        );
        
        // Enhanced request with timeout, error recovery, and better error handling
        final response = await _errorRecovery.executeWithRecovery(
          operation: () => _dio.post(
          _groqUrl,
          cancelToken: cancelToken,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_groqApiKey',
            },
            responseType: ResponseType.stream,
            validateStatus: (status) => status! < 500, // Don't throw on 4xx, handle manually
            receiveTimeout: const Duration(seconds: 60), // 60 second timeout for responses
            sendTimeout: const Duration(seconds: 30), // 30 second timeout for sending
          ),
          data: {
            "model": currentModel,
            "messages": [
              // Add system message as first message (Groq accepts this format)
              if (systemPrompt.isNotEmpty)
                {
                  "role": "system",
                  "content": systemPrompt,
                },
              // Add conversation messages
              ...messagesList,
            ],
            "temperature": _temperatureForMode(),
            "max_tokens": _maxTokensForMode(),
            "stream": true,
          },
        ).timeout(
          const Duration(seconds: 90), // Overall timeout
          onTimeout: () {
            throw TimeoutException('Request timed out. Please check your connection and try again.');
          },
        ),
          maxRetries: 3,
          operationName: 'groq_api_request',
          shouldRetry: (error) {
            // Retry on network errors and timeouts
            return error is DioException || error is TimeoutException;
          },
        );
        
        // Stop performance tracking
        _performanceAnalytics.stopTracking(
          trackingId: performanceTrackingId,
          operationName: 'groq_api_call',
          additionalMetadata: {
            'status_code': response.statusCode,
            'duration_ms': DateTime.now().difference(requestStartTime).inMilliseconds,
          },
        );
        
        // Check for 4xx errors manually
        if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
          String errorDetail = 'Bad request';
          try {
            // Try to read error response if available
            if (response.data != null) {
              // For stream responses, we might not be able to read the body easily
              // But we can log the status code for debugging
              logger.error('Groq API error', tag: 'ai-chat', context: {'statusCode': response.statusCode});
              errorDetail = 'Request validation failed. Please check your message format and API key.';
            }
          } catch (e) {
            logger.error('Error reading response', tag: 'ai-chat', error: e);
          }
          
          if (response.statusCode == 400) {
            // Provide more helpful error message
            throw Exception('Invalid request format. $errorDetail\n\nPlease ensure:\n- Your message is not empty\n- API key is valid\n- Message format is correct');
          } else if (response.statusCode == 401) {
            throw Exception('Invalid API key. Please check your Groq API key in settings.');
          } else if (response.statusCode == 429) {
            throw Exception('Rate limit exceeded. Please try again in a few moments.');
          } else {
            throw Exception('Request failed with status ${response.statusCode}: $errorDetail');
          }
        }

        String buffer = "";
        String output = "";

        final responseBody = response.data;
        // Check if response is a stream
        if (responseBody == null) {
          throw Exception('Unexpected response from Groq (missing stream body).');
        }

        // Handle stream response - Dio returns ResponseBody for stream responses
        final byteStream = (responseBody as dynamic).stream.cast<List<int>>();

        await for (final chunk in byteStream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (_userInterrupt) {
            state = state.copyWith(isLoading: false);
            return;
          }

          if (chunk.startsWith("data: ")) {
            final jsonStr = chunk.substring(6).trim();
            if (jsonStr == "[DONE]") break;

            try {
              // Use enhanced JSON parsing with fallback
              final jsonData = _parseJsonSafely(jsonStr);
              if (jsonData == null) {
                continue; // Skip malformed JSON chunks
              }
              
              final delta = jsonData["choices"]?[0]?["delta"]?["content"];

              if (delta != null && delta is String) {
                buffer += delta;

                final last = buffer.trim().isNotEmpty
                    ? buffer.trim()[buffer.trim().length - 1]
                    : '';

                // Language-aware sentence segmentation.
                // Do NOT flush on ":" / ";" — Polie translation/vocab use "Translation:", "Notes:", etc.
                // and Yoruba text can contain colons; that used to yield only the first fragment (e.g. "E").
                final isSentenceEnd = [".", "!", "?", "…", "\n"].contains(last);

                final hasLongChunk = buffer.length > 220;

                // Never use endsWith('?') here — normal questions mid-reply would truncate the stream.
                final isTurnHandOff = (_mode == PolieMode.conversation ||
                        _mode == PolieMode.roleplay ||
                        _mode == PolieMode.tutor) &&
                    (buffer.toLowerCase().contains('your turn') ||
                        buffer.toLowerCase().contains('now you try') ||
                        buffer.toLowerCase().contains('ask me'));

                // Emit on sentence end or large chunk so stream stays responsive without truncating labels.
                if (isSentenceEnd || hasLongChunk) {
                  output += buffer;
                  yield buffer;
                  buffer = '';

                  if (isTurnHandOff) {
                    _turn = ConversationTurn.user;
                    _currentStreamCancel?.call();
                    break;
                  }
                }
              }
            } catch (_) {
              // Ignore malformed JSON chunks
            }
          }
        }

        // Flush remaining buffer
        if (buffer.isNotEmpty) {
          yield buffer;
          output += buffer;
        }

        // Evaluate user performance and feed learning engine
        _lastResponseTime = DateTime.now().difference(messageStartTime).inMilliseconds / 1000.0;
        if (_messages.length >= 2) {
          final lastUser = _messages[_messages.length - 2].content;
          _evaluateUser(lastUser, output);
        }

        // Add tutor prompt if enabled
        if (_tutorMode && !_userInterrupt) {
          final reviewWord = _dueReview();
          if (reviewWord != null) {
            final tutorCue = "Review time! Translate '$reviewWord' to $_selectedLanguage.";
            output += "\n\n$tutorCue";
            yield "\n\n$tutorCue";
          } else {
            final tutorCue = _adaptiveTutorPrompt(_selectedLanguage);
            if (!output.trim().endsWith("?") &&
                !output.toLowerCase().contains("your turn") &&
                !output.toLowerCase().contains("now you try")) {
              output += "\n\n$tutorCue";
              yield "\n\n$tutorCue";
            }
          }
        }

        _turn = ConversationTurn.user;
        state = state.copyWith(isLoading: false);

        // Enhanced diacritics enforcement with metadata and audit logging
        final modeConstrainedOutput = _applyModeOutputContract(output);
        final diacriticsResult = DiacriticsEnforcer.enforceWithMetadata(
          modeConstrainedOutput,
          _selectedLanguage,
          enableFuzzy: true,
          fuzzyThreshold: 0.75,
        );
        
        final correctedOutput = diacriticsResult['text'] as String;
        final wasChanged = diacriticsResult['changed'] as bool;
        final metadata = diacriticsResult['metadata'] as Map<String, dynamic>;
        
        // Log telemetry event if diacritics were corrected
        if (wasChanged) {
          logger.info('Diacritics corrected', tag: 'ai-chat', context: {'method': metadata['method'], 'language': _selectedLanguage});
          // Track diacritics correction via telemetry service
          try {
            final telemetry = ref.read(telemetryServiceProvider);
            await telemetry.trackPoliePerformance(
              mode: _mode.name,
              language: _selectedLanguage,
              responseTimeMs: 0, // Would need to track start time
              tokenCount: output.length,
              diacriticsCorrected: true,
              modelUsed: _modelName,
              confidence: (metadata['score'] as num?)?.toDouble() ?? 1.0,
            );
          } catch (e) {
            logger.error('Error tracking diacritics correction', tag: 'ai-chat', error: e);
          }
        }

        final assistantMsg = ChatMessage(
          role: 'assistant',
          content: correctedOutput,
          timestamp: DateTime.now(),
        );

        _messages.add(assistantMsg);
        state = state.copyWith();
        await _saveChatHistory();

        // Track Polie performance metrics
        try {
          final responseTime = DateTime.now().difference(requestStartTime);
          final telemetry = ref.read(telemetryServiceProvider);
          await telemetry.trackPoliePerformance(
            mode: _mode.name,
            language: _selectedLanguage,
            responseTimeMs: responseTime.inMilliseconds,
            tokenCount: correctedOutput.length, // Approximate token count
            diacriticsCorrected: wasChanged,
            modelUsed: _modelName,
            confidence: (metadata['score'] as num?)?.toDouble(),
          );
        } catch (e) {
          logger.error('Error tracking Polie performance', tag: 'ai-chat', error: e);
        }

        return;
      } catch (e) {
        if (e is DioException && CancelToken.isCancel(e)) {
          state = state.copyWith(isLoading: false);
          return;
        }

        // Try next model name if we get a 404 (model not found)
        if (e is DioException && e.response?.statusCode == 404) {
          if (modelIndex < _modelNames.length - 1) {
            modelIndex++;
            _modelName = _modelNames[modelIndex];
            if (kDebugMode) {
              logger.warn('Model not found, trying alternative', tag: 'ai-chat', context: {'previousModel': _modelNames[modelIndex - 1], 'tryingModel': _modelName});
            }
            continue; // Try with next model
          }
        }

        if (retryCount < 1) {
          retryCount++;
          continue;
        }

        state = state.copyWith(isLoading: false);

        String errorMessage;
        if (e is DioException) {
          if (e.response != null) {
            final errorData = e.response!.data;
            if (e.response!.statusCode == 400) {
              logger.error('Groq API 400 error', tag: 'ai-chat', context: {'errorData': errorData});
            }
          }
          errorMessage = TransportErrorPolicy.toUserMessage(e);
        } else if (e is TimeoutException) {
          errorMessage = 'Request timed out. Please try again.';
        } else {
          final errorStr = e.toString();
          if (errorStr.contains('Invalid request format')) {
            errorMessage = errorStr;
          } else {
            errorMessage = 'Failed to send message: ${errorStr.replaceAll('Exception: ', '')}';
          }
        }
        throw Exception(errorMessage);
      }
    }
  }

  // Non-streaming version (fallback)
  Future<String> sendMessage(String userMessage, {String? systemPromptOverride}) async {
    String fullResponse = '';
    await for (final chunk in sendMessageStream(userMessage, systemPromptOverride: systemPromptOverride)) {
      fullResponse += chunk;
    }
    final corrected = DiacriticsEnforcer.enforceWithMetadata(
      fullResponse.trim(),
      _selectedLanguage,
      enableFuzzy: true,
      fuzzyThreshold: 0.75,
    );
    return corrected['text'] as String;
  }

  /// JSON-only completion: bypasses chat history, hybrid routing, and diacritics
  /// enforcement to return raw JSON from the LLM for structured mode UIs.
  Future<String> sendMessageForJson(String userMessage) async {
    const jsonSystemPrompt =
        'You are a JSON API. You MUST respond with ONLY valid JSON. '
        'No markdown fences, no explanation, no prose before or after the JSON. '
        'Follow the exact schema provided in the user message.';

    // For translation mode, force backend orchestration so the app can use
    // provider routing policy (OpenAI-first with backend fallbacks) instead of
    // being locked to one direct client model.
    final useBackendJsonPath = _mode == PolieMode.translation ||
        _groqApiKey.isEmpty ||
        _groqApiKey == 'YOUR_GROQ_API_KEY';

    if (useBackendJsonPath) {
      await ApiService.initialize();
      final resp = await ApiService.post(
        '/api/ai/chat/completion',
        data: {
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
          'systemPrompt': jsonSystemPrompt,
          'temperature': 0.3,
          'max_tokens': _maxTokensForMode(),
          'language': _targetLanguage,
          'languageCode': SupportedLanguages.getLanguageCode(_targetLanguage),
          'sourceLanguage': SupportedLanguages.getLanguageCode(_sourceLanguage),
          'targetLanguage': SupportedLanguages.getLanguageCode(_targetLanguage),
          'mode': _mode.name,
          'context': {
            'mode': _mode.name,
            'feature': 'polie_translation_json',
            'providerPolicy': 'gemini_first',
          },
          'response_format': {'type': 'json_object'},
        },
      );
      if (resp.statusCode == 200 && resp.data != null) {
        final content = (resp.data is Map)
            ? (resp.data['content']?.toString() ?? '').trim()
            : '';
        if (content.isNotEmpty) return content;
      }
      throw Exception('Backend returned empty response for JSON request.');
    }

    final response = await _dio.post(
      _groqUrl,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
      ),
      data: {
        'model': _modelName,
        'messages': [
          {'role': 'system', 'content': jsonSystemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.3,
        'max_tokens': _maxTokensForMode(),
        'stream': false,
        'response_format': {'type': 'json_object'},
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final choices = response.data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final content =
            choices[0]['message']?['content']?.toString().trim() ?? '';
        if (content.isNotEmpty) return content;
      }
    }
    throw Exception('Groq returned empty response for JSON request.');
  }

  // Random number generator for roleplay scenarios
  final Random _random = Random();
  
  // ----- Tutor Turn & Adaptive Prompt -----
  String _adaptiveTutorPrompt(String language) {
    // Use roleplay dataset to suggest scenarios (30% chance)
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
      "Create a sentence using two words in $language:"
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

    // Feed the learning engine with this interaction
    _updateLearningEngine(user, assistant, correct);
  }

  /// Bridges every Polie interaction into the cognitive learning engine.
  ///
  /// This ensures: mastery updates, error tracking, XP calibration,
  /// achievement detection, and review scheduling all happen in real-time.
  Future<void> _updateLearningEngine(
    String userMessage,
    String assistantResponse,
    bool wasCorrect,
  ) async {
    try {
      final bridge = LearningEngineBridge.instance;
      final learnerId = 'default_user';
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
    } catch (_) {
      // Learning engine updates are best-effort — never block chat
    }
  }

  LearningEngineUpdate? _lastLearningUpdate;
  int _lastXpEarned = 0;
  double _lastMasteryDelta = 0;
  double _lastResponseTime = 0;

  /// Exposes the latest learning engine update for UI consumption.
  LearningEngineUpdate? get lastLearningUpdate => _lastLearningUpdate;
  int get lastXpEarned => _lastXpEarned;
  double get lastMasteryDelta => _lastMasteryDelta;

  String? _dueReview() {
    final now = DateTime.now();
    for (final entry in _memory.entries) {
      if (entry.value.nextReview.isBefore(now)) {
        return entry.key;
      }
    }
    return null;
  }

  // ----- CEFR Tracking -----
  void _recordSessionMetrics({
    double grammar = 0.0,
    double pron = 0.0,
    double comp = 0.0,
    double vocab = 0.0,
  }) {
    _recentGrammarScores.add(grammar);
    if (_recentGrammarScores.length > 50) _recentGrammarScores.removeAt(0);

    _recentPronScores.add(pron);
    if (_recentPronScores.length > 50) _recentPronScores.removeAt(0);

    _recentCompScores.add(comp);
    if (_recentCompScores.length > 50) _recentCompScores.removeAt(0);

    _recentVocabScores.add(vocab);
    if (_recentVocabScores.length > 50) _recentVocabScores.removeAt(0);

    updateCEFR();
  }

  double _average(List<double> scores) =>
      scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

  Future<void> updateCEFR() async {
    final composite = (_average(_recentGrammarScores) * 0.3 +
            _average(_recentPronScores) * 0.2 +
            _average(_recentCompScores) * 0.3 +
            _average(_recentVocabScores) * 0.2)
        .clamp(0.0, 1.0);
    final pct = (composite * 100).roundToDouble();
    final newLevel = _mapScoreToCEFR(pct);
    _cefrInfo = CEFRInfo(level: newLevel, score: pct);
    _saveCEFRInfo();
  }

  // Public for testing
  String mapScoreToCEFR(double pct) {
    // Explicit inclusive boundaries to match CEFR thresholds used across the app/tests.
    if (pct <= 19) return 'A1';
    if (pct <= 40) return 'A2';
    if (pct <= 59) return 'B1';
    if (pct <= 84) return 'B2';
    if (pct <= 89) return 'C1';
    return 'C2';
  }

  String _mapScoreToCEFR(double pct) => mapScoreToCEFR(pct);

  // ----- Grammar Error Detection -----
  Future<GrammarFeedback> grammarCheck(String language, String userText) async {
    final prompt = '''
You are a concise grammar assistant for $language. 
Analyze the user's sentence and return a strict JSON object with three keys:
{
  "corrected": "<corrected sentence>",
  "errors": [{"type":"<grammar|vocabulary|spelling|word_order>", "original":"...", "correction":"...", "explanation":"brief explanation (max 20 words)"}],
  "score": <0.0-1.0> // 1.0 perfect
}
User sentence: """$userText"""
Return only valid JSON.
''';

    try {
      final response = await _dio.post(
        _groqUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_groqApiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": _modelName,
          "messages": [
            {"role": "system", "content": "You are a JSON-output grammar checker."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.0,
          "max_tokens": 300,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Grammar API error: ${response.data}');
      }

      final text = response.data['choices'][0]['message']['content']?.toString() ?? '';
      final json = jsonDecode(text);

      final corrected = json['corrected'] as String? ?? userText;
      final errorsRaw = (json['errors'] as List?) ?? [];
      final errors = errorsRaw
          .map<Map<String, String>>((e) => {
                'type': e['type'] ?? '',
                'original': e['original'] ?? '',
                'correction': e['correction'] ?? '',
                'explanation': e['explanation'] ?? '',
              })
          .toList();
      final score = (json['score'] is num) ? (json['score'] as num).toDouble() : 0.0;

      _recordSessionMetrics(grammar: score);

      return GrammarFeedback(corrected: corrected, errors: errors, score: score);
    } catch (e) {
      logger.error('Grammar check error', tag: 'ai-chat', error: e);
      return GrammarFeedback(
        corrected: userText,
        errors: [],
        score: 0.5,
      );
    }
  }

  // ----- Word Error Rate (WER) Calculation -----
  int _wordErrorCount(List<String> ref, List<String> hyp) {
    final n = ref.length;
    final m = hyp.length;
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = 0; i <= n; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= m; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + (ref[i - 1] == hyp[j - 1] ? 0 : 1)
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[n][m];
  }

  double wordErrorRate(String reference, String hypothesis) {
    final refWords = reference
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final hypWords = hypothesis
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // If there's no reference text, WER is defined as:
    // - 0.0 if both are empty
    // - 1.0 if hypothesis has content (max error)
    if (refWords.isEmpty) return hypWords.isEmpty ? 0.0 : 1.0;

    final errs = _wordErrorCount(refWords, hypWords);
    // Cap at 1.0 to avoid >1 values when hypothesis is much longer than reference.
    return (errs / refWords.length).clamp(0.0, 1.0);
  }

  // ----- Audio Transcription -----
  Future<String> transcribeAudio(Uint8List audioData) async {
    try {
      final response = await _dio.post(
        UrlConstants.groqAudioTranscriptions,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(audioData, filename: 'audio.wav'),
          'model': 'whisper-large-v3',
        }),
        options: Options(
          headers: {
            "Authorization": "Bearer $_groqApiKey",
          },
        ),
      );

      final text = response.data['text']?.toString() ?? '';
      return text.trim();
    } catch (e) {
      logger.error('Audio transcription error', tag: 'ai-chat', error: e);
      return '';
    }
  }

  // ----- Pronunciation Scoring -----
  Future<double> scorePronunciation(Uint8List audioData) async {
    try {
      final response = await _dio.post(
        UrlConstants.groqAudioTranscriptions,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(audioData, filename: 'audio.wav'),
          'model': 'whisper-large-v3',
        }),
        options: Options(
          headers: {
            "Authorization": "Bearer $_groqApiKey",
          },
        ),
      );

      final confidence = (response.data['confidence'] ?? 0.5) as double? ?? 0.5;
      _recordSessionMetrics(pron: confidence);
      return confidence;
    } catch (e) {
      logger.error('Pronunciation scoring error', tag: 'ai-chat', error: e);
      return 0.5;
    }
  }

  String pronunciationFeedback(double score) {
    if (score > 0.85) return "Excellent pronunciation! 👏";
    if (score > 0.65) return "Good! Try to be clearer on some sounds.";
    if (score > 0.45) return "Almost! Focus on the vowel sounds.";
    return "Let's practice pronunciation. Listen and repeat after me:";
  }

  // ----- Speech Shadowing Exercise -----
  Future<Map<String, dynamic>> shadowingExercise(
      Uint8List userAudio, String referenceText) async {
    try {
      // Transcribe user audio using Groq Whisper
      final transResp = await _dio.post(
        UrlConstants.groqAudioTranscriptions,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(userAudio, filename: 'speech.wav'),
          'model': 'whisper-large-v3',
        }),
        options: Options(
          headers: {'Authorization': 'Bearer $_groqApiKey'},
        ),
      );

      final userText = transResp.data['text']?.toString() ?? '';
      final wer = wordErrorRate(referenceText, userText);
      final pronunciationScore = (transResp.data['confidence'] ?? 0.6) as double? ?? 0.6;

      final score = ((1 - wer) * 0.6 + pronunciationScore * 0.4).clamp(0.0, 1.0);

      final grammar = await grammarCheck(_selectedLanguage, userText);

      _recordSessionMetrics(pron: score, grammar: grammar.score);

      return {
        'score': score,
        'wer': wer,
        'userText': userText,
        'pronunciationScore': pronunciationScore,
        'corrections': grammar.errors,
      };
    } catch (e) {
      logger.error('Shadowing exercise error', tag: 'ai-chat', error: e);
      return {
        'score': 0.0,
        'wer': 1.0,
        'userText': '',
        'pronunciationScore': 0.0,
        'corrections': [],
      };
    }
  }

  // ----- Listening Comprehension -----
  Future<Map<String, dynamic>> generateListeningPassage(
      String language, int difficulty) async {
    final prompt = '''
You are to create a short listening comprehension passage in $language (level difficulty $difficulty). 
Return JSON:
{
  "passage": "<text to be spoken>",
  "questions": [
    {"id":1, "type":"mcq", "question":"...", "options":["a","b","c","d"], "answer":"b"},
    {"id":2, "type":"open", "question":"...", "answer":"expected short answer"}
  ]
}
Return only JSON.
''';

    try {
      final resp = await _dio.post(
        _groqUrl,
        data: {
          "model": _modelName,
          "messages": [
            {"role": "system", "content": "You are a JSON-output listening generator."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.3,
          "max_tokens": 500,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_groqApiKey'},
        ),
      );

      final text = resp.data['choices'][0]['message']['content'];
      return jsonDecode(text);
    } catch (e) {
      logger.error('Listening passage generation error', tag: 'ai-chat', error: e);
      return {
        'passage': '',
        'questions': [],
      };
    }
  }

  Future<double> evaluateOpenAnswer(
      String question, String expected, String userAnswer) async {
    final prompt = '''
You are a grader. Given the question: "$question"
Expected short answer: "$expected"
User answer: "$userAnswer"

Return a JSON: {"score": <0.0-1.0>, "feedback": "short feedback (max 25 words)"}
Return only JSON.
''';

    try {
      final resp = await _dio.post(
        _groqUrl,
        data: {
          "model": _modelName,
          "messages": [{"role": "user", "content": prompt}],
          "temperature": 0.0,
          "max_tokens": 150
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_groqApiKey'},
        ),
      );

      final json = jsonDecode(resp.data['choices'][0]['message']['content']);
      final score = (json['score'] as num).toDouble();
      _recordSessionMetrics(comp: score);
      return score;
    } catch (e) {
      logger.error('Answer evaluation error', tag: 'ai-chat', error: e);
      return 0.5;
    }
  }

  // ----- Curriculum Generation -----
  Future<Map<String, dynamic>> generateCurriculum({
    required String language,
    required String targetCEFR,
    int weeks = 8,
  }) async {
    final prompt = '''
Create a $weeks-week curriculum for teaching $language to reach CEFR $targetCEFR.
Return strict JSON:
{
  "language":"$language",
  "level":"$targetCEFR",
  "weeks":[
    {"week":1, "lessons":[ {"title":"", "objectives":["..."], "vocab":["..."], "exercises":[{"type":"shadow","prompt":"..."}]} ]}
  ]
}
Return only JSON.
''';

    try {
      final resp = await _dio.post(
        _groqUrl,
        data: {
          "model": _modelName,
          "messages": [
            {"role": "system", "content": "You are a curriculum generator that outputs strict JSON."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.2,
          "max_tokens": 1500,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_groqApiKey'},
        ),
      );

      final text = resp.data['choices'][0]['message']['content'];
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      logger.error('Curriculum generation error', tag: 'ai-chat', error: e);
      return {
        'language': language,
        'level': targetCEFR,
        'weeks': [],
      };
    }
  }

  // ----- Chat Management -----
  Future<void> clearChat() async {
    _messages.clear();
    state = state.copyWith();
    await _saveChatHistory(); // Save empty history to clear this mode's history
        final modeName = _mode == PolieMode.translation ? "Translation" 
            : _mode == PolieMode.tutor ? "Tutor"
            : _mode == PolieMode.roleplay ? "Roleplay"
            : _mode == PolieMode.conversation ? "Conversation"
            : _mode == PolieMode.vocab ? "Vocab"
            : _mode == PolieMode.pronunciation ? "Pronunciation"
            : _mode == PolieMode.grammar ? "Grammar"
            : "Review";
        logger.info('Cleared chat history', tag: 'ai-chat', context: {'mode': modeName});
  }

  // ----- Persistence -----
  // Separate chat histories for each mode
  /// Chat history key scoped by mode × language (m × n chat bodies)
  /// This ensures each mode × language combination has its own conversation history
  String get _chatHistoryKey {
    final modeName = _mode.toString().split('.').last;
    // Use selectedLanguage as fallback if targetLanguage is empty
    final language = (_targetLanguage.isNotEmpty ? _targetLanguage : _selectedLanguage)
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), ''); // Sanitize
    // Format: ai_chat_history_groq_{mode}_{language}
    // Example: ai_chat_history_groq_translation_yoruba
    return 'ai_chat_history_groq_${modeName}_$language';
  }
  
  /// Get language code for backend API (normalized)
  String get _languageCodeForBackend {
    final language = (_targetLanguage.isNotEmpty ? _targetLanguage : _selectedLanguage)
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return language;
  }
  
  /// Get mode name for backend API
  String get _modeNameForBackend {
    return _mode == PolieMode.translation ? 'translation'
        : _mode == PolieMode.tutor ? 'tutor'
        : _mode == PolieMode.roleplay ? 'roleplay'
        : _mode == PolieMode.conversation ? 'conversation'
        : _mode == PolieMode.vocab ? 'vocab'
        : _mode == PolieMode.pronunciation ? 'pronunciation'
        : _mode == PolieMode.grammar ? 'grammar'
        : 'review';
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages.map((msg) => msg.toJson()).toList();
      await prefs.setString(_chatHistoryKey, jsonEncode(messagesJson));
      
      // Sync to backend (debounced to avoid too many calls)
      _syncChatHistoryToBackend();
    } catch (e) {
      logger.error('Error saving chat history', tag: 'ai-chat', error: e);
    }
  }

  /// Sync chat history to backend (debounced to avoid too many calls)
  Future<void> _syncChatHistoryToBackend() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      // Debounce: only sync if last sync was more than 3 seconds ago
      final now = DateTime.now();
      if (_lastBackendSync != null && now.difference(_lastBackendSync!).inSeconds < 3) {
        return;
      }
      _lastBackendSync = now;

      // Use backend API directly for chat history
      try {
        final apiNotifier = ref.read(apiProvider.notifier);
        final success = await apiNotifier.saveAiChatHistory({
          'mode': _modeNameForBackend,
          'language_code': _languageCodeForBackend,
          'messages': _messages.map((m) => m.toJson()).toList(),
        });
        if (success) {
          logger.info('Chat history synced to backend', tag: 'ai-chat', context: {'mode': _modeNameForBackend, 'language': _languageCodeForBackend});
        }
      } catch (apiError) {
        logger.warn('Error syncing to backend API, falling back to sync queue', tag: 'ai-chat', error: apiError);
        // Fallback to sync queue
        final syncProvider = ref.read(backendSyncProvider.notifier);
        await syncProvider.queueSync(SyncTask(
          type: SyncType.aiChatHistory,
          data: {
            'user_id': user.id.toString(),
            'mode': _modeNameForBackend,
            'languageCode': _languageCodeForBackend,
            'messages': _messages.map((m) => m.toJson()).toList(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
      }
    } catch (e) {
      logger.error('Error syncing chat history', tag: 'ai-chat', error: e);
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      // Try loading from backend first
      try {
        final user = ref.read(userProvider);
        if (user != null) {
          final apiNotifier = ref.read(apiProvider.notifier);
          final backendHistory = await apiNotifier.getAiChatHistory(
            mode: _modeNameForBackend,
            languageCode: _languageCodeForBackend,
          );
          
          if (backendHistory != null && backendHistory.isNotEmpty) {
            _messages.clear();
            _messages.addAll(
              backendHistory.map((json) => ChatMessage.fromJson(json)),
            );
            final modeName = _mode == PolieMode.translation ? "Translation" 
                : _mode == PolieMode.tutor ? "Tutor"
                : _mode == PolieMode.roleplay ? "Roleplay"
                : _mode == PolieMode.conversation ? "Conversation"
                : _mode == PolieMode.vocab ? "Vocab"
                : _mode == PolieMode.pronunciation ? "Pronunciation"
                : _mode == PolieMode.grammar ? "Grammar"
                : "Review";
            logger.info('Loaded messages from backend', tag: 'ai-chat', context: {'count': _messages.length, 'mode': modeName, 'language': _languageCodeForBackend});
            state = state.copyWith();
            
            // Also save to local storage for offline access
            final prefs = await SharedPreferences.getInstance();
            final messagesJson = _messages.map((msg) => msg.toJson()).toList();
            await prefs.setString(_chatHistoryKey, jsonEncode(messagesJson));
            return;
          }
        }
      } catch (backendError) {
        logger.warn('Error loading from backend, trying local storage', tag: 'ai-chat', error: backendError);
      }
      
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_chatHistoryKey);
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> messagesList = jsonDecode(historyJson);
        _messages.clear();
        _messages.addAll(
          messagesList.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)),
        );
        final modeName = _mode == PolieMode.translation ? "Translation" 
            : _mode == PolieMode.tutor ? "Tutor"
            : _mode == PolieMode.roleplay ? "Roleplay"
            : _mode == PolieMode.conversation ? "Conversation"
            : _mode == PolieMode.vocab ? "Vocab"
            : _mode == PolieMode.pronunciation ? "Pronunciation"
            : _mode == PolieMode.grammar ? "Grammar"
            : "Review";
        logger.info('Loaded messages from local storage', tag: 'ai-chat', context: {'count': _messages.length, 'mode': modeName});
        state = state.copyWith();
      } else {
        // No history for this mode × language combination
        _messages.clear();
        final modeName = _mode == PolieMode.translation ? "Translation" 
            : _mode == PolieMode.tutor ? "Tutor"
            : _mode == PolieMode.roleplay ? "Roleplay"
            : _mode == PolieMode.conversation ? "Conversation"
            : _mode == PolieMode.vocab ? "Vocab"
            : _mode == PolieMode.pronunciation ? "Pronunciation"
            : _mode == PolieMode.grammar ? "Grammar"
            : "Review";
        logger.info('No chat history found', tag: 'ai-chat', context: {'mode': modeName, 'language': _languageCodeForBackend});
        state = state.copyWith();
      }
    } catch (e) {
      logger.error('Error loading chat history', tag: 'ai-chat', error: e);
      // On error, clear messages to prevent showing wrong mode's history
      _messages.clear();
      state = state.copyWith();
    }
  }

  Future<void> _loadSRSMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoryJson = prefs.getString('srs_memory');
      if (memoryJson != null) {
        final Map<String, dynamic> memoryMap = jsonDecode(memoryJson);
        _memory.clear();
        memoryMap.forEach((key, value) {
          _memory[key] = WordMemory.fromJson(value);
        });
      }
    } catch (e) {
      logger.error('Error loading SRS memory', tag: 'ai-chat', error: e);
    }
  }

  Future<void> _saveCEFRInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cefr_info', jsonEncode(_cefrInfo.toJson()));
    } catch (e) {
      logger.error('Error saving CEFR info', tag: 'ai-chat', error: e);
    }
  }

  Future<void> _loadCEFRInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cefrJson = prefs.getString('cefr_info');
      if (cefrJson != null) {
        _cefrInfo = CEFRInfo.fromJson(jsonDecode(cefrJson));
      }
    } catch (e) {
      logger.error('Error loading CEFR info', tag: 'ai-chat', error: e);
    }
  }
}


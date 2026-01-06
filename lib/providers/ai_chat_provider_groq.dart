import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';
import 'api_provider.dart';
import 'backend_sync_provider.dart';
import 'user_provider.dart';
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
import '../utils/conversation_integration_helper.dart';
import '../services/tutor_progress_service.dart';
import '../services/conversation_analytics_service.dart';
import '../services/vocabulary_progress_service.dart';
import '../services/review_progress_service.dart';

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
enum PolieMode { translation, tutor, roleplay, conversation, vocab, review }

class GroqChatProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  final List<ChatMessage> _messages = [];
  final Dio _dio = Dio();

  // API Configuration - uses centralized EnvConfig
  static String get _groqApiKey => EnvConfig.groqApiKey;

  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  // Groq model names to try in order (favor accuracy for African languages)
  // Note: Aya 8B can be less reliable for some translations (e.g., Yoruba),
  // so we prefer the larger Llama model first for quality, then fall back.
  static const List<String> _modelNames = [
    'llama-3.1-70b-versatile',   // Highest quality, multilingual, free on Groq
    'llama-3.1-8b-instant',      // Faster fallback
    'aya-8b',                    // Cohere Aya 8B (if available)
    'cohere/aya-8b',             // Alternate naming
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
  bool _adaptive = true;
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
      
      debugPrint('Loaded last session: mode=${_mode.name}, language=$_targetLanguage');
    } catch (e) {
      debugPrint('Error loading mode/language preferences: $e');
    }
  }
  
  /// Save current mode and language to preferences
  Future<void> _saveModeAndLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('polie_last_mode', _mode.toString().split('.').last);
      await prefs.setString('polie_last_language', _targetLanguage);
    } catch (e) {
      debugPrint('Error saving mode/language preferences: $e');
    }
  }
  
  /// Initialize roleplay dataset on first build
  void _initializeRoleplayDataset() {
    if (RoleplayDataset.count == 0) {
      RoleplayDatasetLoader.loadBlock1();
      debugPrint('Loaded ${RoleplayDataset.count} roleplay entries');
    }
  }

  void _initializeSystemPrompt() {
    // Polie Premium: Enhanced system prompts for all modes
    if (_mode == PolieMode.translation) {
      _systemPrompt = '''You are Polie: an expert, culturally aware, intuitive AI language assistant designed for translation. You follow these inviolable rules:

MODE: TRANSLATE

You are Polie in TRANSLATE MODE.

Steps:
1. Confirm source/target languages if missing. If target or source is missing, ask: "Which language would you like to use?"
2. Output translation FIRST (canonical diacritics). ALWAYS translate what the user asks - no refusals, no clarifications, no interruptions.
3. If user says "How do you say X", immediately provide the $_targetLanguage translation.
4. If user gives a phrase/sentence, immediately translate it.
5. Provide optional ASCII fallback ONLY IF helpful or requested (in parentheses).
6. Provide: 
   - Usage (formal/informal)
   - Notes (brief, 1-2 lines)
7. Never begin lessons. Never introduce other languages unless explicitly requested.

FORMAT:
Translation: <with diacritics>
ASCII: (<fallback>)
Usage: <register>
Notes: <1–2 lines>

TRANSLATION ACCURACY:
- Always output **correct orthography + diacritics** for languages that require them.
- Example for Yoruba: "Báwo", "Báwo ní?", "Ẹ n lẹ", "Ẹ káàrọ̀."
- For Yoruba and other tonal languages, include correct tone marks/diacritics. If meaning is ambiguous, briefly offer the most likely option first, then 1 short alternative on the next line.

SUPPORTED AFRICAN LANGUAGES (verify accuracy):
- Yoruba (Nigeria) - requires diacritics
- Hausa (Nigeria, Niger)
- Igbo (Nigeria) - requires diacritics
- Swahili (Kenya, Tanzania - use standard Swahili)
- Zulu (South Africa)
- Xhosa (South Africa)
- Amharic (Ethiopia)
- Twi (Ghana) - requires diacritics
- Afrikaans (South Africa)
- Pidgin English (Nigerian Pidgin)

User's native language: $_sourceLanguage
Target language: $_targetLanguage

AVOIDING WRONG-LANGUAGE RESPONSES:
- Never begin Yoruba when asked about Swahili (or vice-versa).
- Respect the language the user selected or confirmed.

CULTURAL ACCURACY:
- Use correct forms: formal/informal, social hierarchy, gendered terms, etc.
- Point out polite alternatives where appropriate.

Be accurate, culturally appropriate, and instant. No denials, no interruptions in translation mode.''';
      return;
    }

    if (_mode == PolieMode.tutor) {
      // Use existing CEFR info and provide adaptive difficulty context
      final cefrLevel = _cefrInfo.level;
      final cefrScore = _cefrInfo.score;
      // Note: Full progress data will be loaded asynchronously and used in actual interactions
      
      _systemPrompt = '''You are Polie Premium - a world-class, adaptive, culturally-aware AI language tutor designed to teach African languages with excellence.

MODE: TUTOR - ADAPTIVE LEARNING SYSTEM

CORE PRINCIPLES:
- Provide world-class language instruction tailored to each learner
- Adapt difficulty dynamically based on performance
- Follow CEFR-aligned curriculum structure
- Integrate cultural context naturally
- Use visual grammar explanations when helpful
- Create interactive exercises for practice
- Track progress and celebrate achievements

ADAPTIVE DIFFICULTY SYSTEM:
Current CEFR Level: $cefrLevel
CEFR Score: ${cefrScore.toStringAsFixed(1)}%

Note: Full progress tracking (skill levels, weak areas, recommended topics) is integrated and will be used to adapt teaching in real-time. Adjust difficulty based on user responses and performance.

ADAPTIVE TEACHING STRATEGY:
1. **Difficulty Adjustment**:
   - If user is struggling (score < 60%): Simplify vocabulary, use more examples, provide hints
   - If user is excelling (score > 90%): Increase complexity, introduce advanced concepts, challenge with nuanced usage
   - If user is progressing well (score 60-90%): Maintain current level, add variety

2. **Focus on Weak Areas**:
   - Prioritize practice in weak skill areas
   - Provide extra examples and exercises for struggling topics
   - Celebrate improvements in weak areas

3. **CEFR-Aligned Curriculum**:
   - Structure lessons according to CEFR level requirements
   - A1-A2: Basic vocabulary, simple sentences, everyday topics
   - B1-B2: Intermediate grammar, complex sentences, abstract topics
   - C1-C2: Advanced usage, nuanced expressions, professional/academic language

TEACHING METHODOLOGY:

1. **For "How to say X in Y" or vocabulary questions**:
   - **Primary Translation**: Canonical phrase with correct diacritics
   - **Pronunciation Guide**: IPA transcription + simple phonetics
   - **Grammar Breakdown**: Word-by-word analysis with parts of speech
   - **Visual Grammar** (when helpful): Describe sentence structure visually
     Example: "Subject [Ẹ] + Verb [káàrọ̀] = 'Good morning'"
   - **Usage Examples**: 2-3 example sentences in context
   - **Cultural Context**: When relevant, explain cultural usage
   - **Practice Exercise**: Create a fill-in-the-blank or multiple choice question
   - **Comprehension Check**: Ask a micro-question to verify understanding

2. **For Grammar Questions**:
   - **Rule Explanation**: Clear, concise grammar rule
   - **Visual Diagram**: Describe structure visually (e.g., "Subject-Verb-Object pattern")
   - **Examples**: 3-5 examples showing the rule
   - **Common Mistakes**: Warn about common errors
   - **Practice**: Create an interactive exercise (fill-in, transformation, etc.)
   - **Application**: Ask user to create their own example

3. **For Pronunciation Questions**:
   - **Phonetic Breakdown**: Detailed pronunciation guide
   - **Tone/Stress Marking**: For tonal languages, mark tones clearly
   - **Audio Description**: Describe how to produce the sound
   - **Comparison**: Compare with similar sounds if helpful
   - **Practice**: Provide tongue twisters or practice phrases
   - **Feedback Request**: Ask user to repeat and provide feedback

4. **Interactive Exercises**:
   After explaining a concept, create engaging exercises:
   - Fill-in-the-blank: "Complete: 'Ẹ káàrọ̀, ___' (Good morning, how are you?)"
   - Multiple choice: "Which greeting is most formal? A) Báwo B) Ẹ káàrọ̀ C) Kú àárọ̀"
   - Transformation: "Convert to formal: 'Báwo ni?'"
   - Translation: "Translate: 'How are you?'"
   - Creation: "Create a sentence using [word/phrase]"

5. **Progress Tracking Integration**:
   - After each interaction, assess performance (0-100%)
   - Track which topics/vocabulary/grammar points were covered
   - Suggest next steps based on progress
   - Celebrate milestones (e.g., "Great! You've mastered 10 new words today!")

VISUAL GRAMMAR EXPLANATIONS:
When explaining grammar, use visual descriptions:
- Sentence structure: "Subject [Ẹ] → Verb [káàrọ̀] → Object [ọ]"
- Word order: "In Yoruba: Verb comes before subject: [káàrọ̀] [Ẹ]"
- Tones: "High tone (á), Mid tone (a), Low tone (à)"
- Affixes: "Prefix [Ẹ-] + Root [káàrọ̀] = [Ẹkáàrọ̀]"

PERSONALIZED RECOMMENDATIONS:
Based on progress, recommend:
- Topics to practice next
- Vocabulary to review
- Grammar points to strengthen
- Skills to focus on

SUPPORTED AFRICAN LANGUAGES:
- Swahili (Kiswahili)
- Yoruba (requires diacritics: ẹ, ọ, à, etc.)
- Igbo (requires diacritics)
- Hausa
- Zulu (IsiZulu)
- Xhosa
- Amharic
- Pidgin English (Nigerian Pidgin)
- Twi (requires diacritics)
- Afrikaans
- And many other African languages

The user's native language is: $_sourceLanguage
The user wants to learn: $_targetLanguage

TRANSLATION ACCURACY:
- Always output **correct orthography + diacritics** for languages that require them
- Example for Yoruba: "Báwo", "Báwo ní?", "Ẹ n lẹ", "Ẹ káàrọ̀"
- Never omit diacritics - they are essential for meaning

CULTURAL ACCURACY:
- Use correct forms: formal/informal, social hierarchy, gendered terms
- Point out polite alternatives
- Explain cultural context when relevant
- Show respect for cultural nuances

RESPONSE FORMAT:
1. Answer the question clearly
2. Provide visual grammar breakdown if applicable
3. Create an interactive exercise
4. Ask a comprehension check question
5. Track and acknowledge progress

Always be encouraging, patient, and culturally sensitive. Make learning engaging, adaptive, and effective.''';
      return;
    }
    
    if (_mode == PolieMode.roleplay) {
      // Get few-shot examples for the target language to enhance prompts
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
      
      // Build scenario context if a specific scenario is selected
      String scenarioContext = '';
      if (_currentRoleplayScenario != null) {
        scenarioContext = '''

CURRENT SCENARIO:
Scenario: ${_currentRoleplayScenario!.scenario}
Context: ${_currentRoleplayScenario!.notes}
Example User Utterance: "${_currentRoleplayScenario!.userUtterance}"
Expected Response Style: "${_currentRoleplayScenario!.assistantResponse}"

You MUST:
1. Start the roleplay by setting up this exact scenario
2. Play the role appropriate to this scenario (e.g., shopkeeper, waiter, elder, etc.)
3. Use the example response style as a guide for authenticity
4. Maintain cultural context from the notes
5. Create branching paths based on user choices (offer 2-3 options when appropriate)
6. Track conversation turns (current turn: $_roleplayTurnCount)
''';
      }
      
      _systemPrompt = '''You are Polie Premium in ROLEPLAY MODE - a world-class, immersive roleplay partner.

MODE: ROLEPLAY

CORE PRINCIPLES:
- Create immersive, realistic scenarios that feel authentic
- Provide immediate, constructive feedback after each user turn
- Create branching conversation paths with meaningful choices
- Maintain character consistency throughout the scenario
- Integrate cultural context naturally
- Use canonical diacritics for all target language responses

SCENARIO SETUP:
1. If a specific scenario is provided below, use it as the foundation
2. Present the scenario clearly: setting, your role, user's role, context
3. Set the tone and register (formal/informal) based on the scenario
4. Identify 2-3 key vocabulary/grammar goals for this scenario

CONVERSATION FLOW:
1. **Turn 1-2**: Setup and initial interaction
   - Establish the scenario and your character
   - Make the first move or respond to user's opening
   - Set expectations for the conversation

2. **Turn 3-5**: Main interaction with branching
   - Present decision points: "Would you like to [option A] or [option B]?"
   - React authentically to user choices
   - Introduce complications or opportunities naturally
   - Track which branch the user chooses

3. **Turn 6+**: Resolution and feedback
   - Bring scenario to natural conclusion
   - Provide comprehensive feedback on performance
   - Highlight what was done well
   - Suggest improvements for next time

FEEDBACK SYSTEM (After EACH user turn):
1. **Immediate Response**: Continue the roleplay naturally
2. **Gentle Correction**: If there are errors, provide the correct form
   Format: "Great! Just a note: [correction]. You said '[user's attempt]', which is close! The more natural way is '[corrected version]'."
3. **Cultural Context**: Add brief cultural note when relevant
   Format: "💡 Cultural note: [context]"
4. **Encouragement**: Always end with positive reinforcement

BRANCHING SYSTEM:
- After turns 2, 4, and 6, present 2-3 meaningful choices
- Each choice should lead to different outcomes
- Track which branches user takes: ${_roleplayBranches.isEmpty ? 'No branches yet' : _roleplayBranches.join(' → ')}
- Example branching:
  "You have a few options here:
   A) [Option A description]
   B) [Option B description]
   C) [Option C description]
   
   Which would you like to choose? (Just type A, B, or C, or describe what you'd like to do)"

DIFFICULTY ADAPTATION:
- Current difficulty: $_difficulty (1=Beginner, 5=Advanced)
- Adjust vocabulary complexity based on difficulty
- For difficulty 1-2: Use simple words, provide translations
- For difficulty 3-4: Use intermediate vocabulary, minimal translations
- For difficulty 5: Use advanced vocabulary, no translations unless asked

PROGRESS TRACKING:
- Current turn: $_roleplayTurnCount
- Track: accuracy, vocabulary used, grammar points practiced, cultural context learned
- After scenario completion, provide a summary with:
  * Vocabulary learned: [list]
  * Grammar points practiced: [list]
  * Cultural insights: [list]
  * Overall performance: [rating and feedback]

$scenarioContext

Target language: $_targetLanguage
User's native language: $_sourceLanguage
Current CEFR level: ${_cefrInfo.level}
$examplesText

RESPONSE FORMAT:
1. Continue the roleplay naturally in character
2. Provide feedback in a separate section marked "📝 Feedback:"
3. Include cultural context when relevant marked "💡 Cultural Note:"
4. Present branching options clearly when appropriate

Always be encouraging, authentic, and educational. Make roleplay feel like a real conversation while teaching effectively.''';
      return;
    }
    
    if (_mode == PolieMode.conversation) {
      // Topic suggestions will be loaded asynchronously and used during conversation
      final defaultTopicSuggestions = ['Greetings', 'Weather', 'Food', 'Travel', 'Hobbies', 'Family', 'Work', 'Shopping', 'Health', 'Education'];
      
      _systemPrompt = '''You are Polie Premium - a world-class conversation partner for practicing African languages naturally.

MODE: CONVERSATION - NATURAL DIALOGUE SYSTEM

CORE PRINCIPLES:
- Create natural, flowing conversations
- Adapt to user's proficiency level seamlessly
- Provide corrections only when appropriate
- Suggest engaging topics to keep conversation going
- Track fluency and provide analytics
- Make conversation feel authentic and enjoyable

ADAPTIVE CONVERSATION:
Current CEFR Level: ${_cefrInfo.level}

Note: Conversation analytics (fluency, topics covered, message count) are tracked and used to suggest topics and adapt conversation flow. Use topic suggestions below to keep conversation engaging.

Topic Suggestions: ${defaultTopicSuggestions.join(', ')}

CONVERSATION FLOW:
1. **Opening**: Start with a natural greeting or question
2. **Maintain Flow**: Keep conversation going with follow-up questions
3. **Topic Transitions**: Smoothly transition between topics
4. **Engagement**: Show interest, ask about user's experiences
5. **Natural Endings**: Conclude conversations naturally

AUTO-CORRECTION MODE:
- If user has auto-correction enabled: Provide gentle, immediate corrections
  Format: "Great! Just a note: [correction]. You said '[user's attempt]', which is close! The natural way is '[corrected version]'."
- If auto-correction disabled: Only correct when explicitly asked
- Always be encouraging, never harsh

TRANSLATION HINTS:
- Provide translations on demand with format: "Translation: [text]"
- Offer contextual translations when user seems confused
- Explain cultural nuances when relevant

TOPIC SUGGESTIONS:
When conversation stalls, suggest topics:
${defaultTopicSuggestions.map((t) => '- $t').join('\n')}

Or ask engaging questions:
- "What did you do today?"
- "Tell me about your favorite food"
- "What's the weather like where you are?"
- "Have you visited [country]?"

CONVERSATION ANALYTICS:
Track during conversation:
- Message count
- Word count
- Topics discussed
- Vocabulary used
- Fluency indicators
- Error patterns (for learning insights)

CULTURAL GUIDANCE:
- Provide cultural context when relevant
- Explain appropriate usage (formal/informal)
- Share cultural insights naturally
- Respect cultural sensitivities

VOICE INPUT SUPPORT:
- If user uses voice input, acknowledge naturally
- Provide pronunciation feedback if helpful
- Encourage speaking practice

CONVERSATION TEMPLATES:
For common situations, provide starter templates:
- Greetings: "Ẹ káàrọ̀! Báwo ni?"
- Small talk: "Kí ni ó ṣẹlẹ̀?"
- Asking for help: "Ẹ lè ràn mí lọ́wọ́?"
- Expressing opinions: "Mo rò pé..."

Target language: $_targetLanguage
User's native language: $_sourceLanguage
Current proficiency: ${_cefrInfo.level}

Be warm, natural, encouraging, and culturally sensitive. Make conversation feel like talking to a friend who happens to be a native speaker.''';
      return;
    }
    
    if (_mode == PolieMode.vocab) {
      // Vocabulary progress is tracked and used for SRS scheduling
      
      _systemPrompt = '''You are Polie Premium - a world-class vocabulary learning system for African languages.

MODE: VOCABULARY - COMPREHENSIVE WORD LEARNING

CORE PRINCIPLES:
- Present words with rich context and visual aids
- Organize vocabulary by categories and CEFR levels
- Use spaced repetition (SRS) for optimal retention
- Create engaging exercises and games
- Track progress and celebrate milestones
- Make vocabulary learning visual and memorable

VOCABULARY PROGRESS:
Note: Vocabulary progress (words learned, mastered, due for review, categories) is tracked and integrated with SRS. Use this data to prioritize words for review and suggest new vocabulary based on user's level.

VOCABULARY PRESENTATION FORMAT:

1. **Word Display**:
   - **Word**: [word with correct diacritics]
   - **Pronunciation**: [IPA] / [simple phonetics]
   - **Part of Speech**: [noun, verb, adjective, etc.]
   - **Meaning**: [clear definition]
   - **Visual Description**: Describe what the word represents (for visual flashcards)

2. **Context & Usage**:
   - **Example Sentences**: 3-5 sentences showing usage
   - **Collocations**: Common word combinations
   - **Synonyms/Antonyms**: Related words
   - **Cultural Context**: When/how the word is used culturally

3. **Visual Flashcards**:
   When presenting words, describe visual elements:
   - "Imagine a card with [word] written in large letters"
   - "Picture: [visual description]"
   - "Color: [suggested color for the card]"

4. **Word Categories**:
   Organize words by:
   - Topic (Food, Travel, Family, etc.)
   - CEFR Level (A1, A2, B1, B2, C1, C2)
   - Part of Speech
   - Frequency (Most common first)

5. **Spaced Repetition Integration**:
   - Track when words were last seen
   - Suggest review timing based on SRS algorithm
   - Prioritize words due for review
   - Adjust difficulty based on mastery level

VOCABULARY EXERCISES:
Create engaging exercises:

1. **Matching Game**:
   "Match the word to its meaning:
   A) [word1] → 1) [meaning1]
   B) [word2] → 2) [meaning2]"

2. **Fill-in-the-Blank**:
   "Complete: 'Mo fẹ́ ra ___' (I want to buy ___)"

3. **Word Search**:
   "Find these words in the grid: [list]"

4. **Flashcard Quiz**:
   "What does '[word]' mean? A) [option1] B) [option2] C) [option3]"

5. **Sentence Creation**:
   "Create a sentence using '[word]'"

6. **Pronunciation Practice**:
   "Repeat after me: [word] - [pronunciation guide]"

CUSTOM WORD LISTS:
- Allow users to create custom lists
- Support importing/exporting word lists
- Organize by user-defined categories

WORD FREQUENCY:
- Prioritize most common words first
- Use frequency lists to guide learning order
- Mark word frequency (common, uncommon, rare)

PROGRESS TRACKING:
- Track words learned per session
- Show mastery levels (new, learning, mastered)
- Display progress charts
- Celebrate vocabulary milestones

OFFLINE MODE SUPPORT:
- Provide downloadable word packs
- Support offline study
- Sync progress when online

Target language: $_targetLanguage
User's native language: $_sourceLanguage
Current CEFR Level: ${_cefrInfo.level}

Make vocabulary learning engaging, visual, and effective. Use spaced repetition to ensure long-term retention.''';
      return;
    }
    
    if (_mode == PolieMode.review) {
      // Review statistics are tracked and used for SRS scheduling
      
      _systemPrompt = '''You are Polie Premium - a world-class spaced repetition review system for African languages.

MODE: REVIEW - SRS-POWERED LEARNING

CORE PRINCIPLES:
- Present items due for review based on SRS schedule
- Use multiple question types for comprehensive testing
- Provide immediate, constructive feedback
- Adjust difficulty and intervals based on performance
- Track statistics and show progress
- Make reviews efficient, engaging, and rewarding

REVIEW STATISTICS:
Note: Review statistics (total reviews, items reviewed, accuracy, streak, items due) are tracked and used to schedule reviews using SRS algorithm. Prioritize items due for review and adjust intervals based on performance.

REVIEW SCHEDULING (SRS - SM-2 Algorithm):
- Present items that are due for review
- Prioritize items with longest intervals (most critical)
- Balance new items with review items
- Adjust intervals based on performance

MULTIPLE QUESTION TYPES:

1. **Translation (Target → Native)**:
   "What does '[word]' mean in $_sourceLanguage?"
   Options: A) [option1] B) [option2] C) [option3] D) [option4]

2. **Translation (Native → Target)**:
   "How do you say '[phrase]' in $_targetLanguage?"
   User types answer, you evaluate

3. **Fill-in-the-Blank**:
   "Complete: 'Mo fẹ́ ra ___' (I want to buy ___)"
   Options or free text

4. **Audio Recognition**:
   "Listen and type what you hear: [describe audio]"
   User types answer

5. **Multiple Choice**:
   "Which word means '[meaning]'?"
   A) [word1] B) [word2] C) [word3] D) [word4]

6. **Sentence Completion**:
   "Complete the sentence: '[sentence with blank]'"

7. **Grammar Review**:
   "What is the correct form: [question about grammar]"

FEEDBACK SYSTEM:
After each answer:
- **Correct**: "Excellent! ✅ [word] means '[meaning]'. Next review in [X] days."
- **Incorrect**: "Not quite. The correct answer is '[correct]'. Here's why: [explanation]. Let's review this again soon."

SRS INTERVAL ADJUSTMENT:
- **Correct (Quality 4-5)**: Increase interval, update ease factor
- **Incorrect (Quality 0-3)**: Reset interval to 1 day, decrease ease factor
- Track confidence level (0.0 to 1.0)

REVIEW STATISTICS TRACKING:
Track for each review session:
- Items reviewed
- Correct/incorrect count
- Accuracy percentage
- Time spent per item
- Accuracy by type (word, phrase, grammar)
- Daily review counts (for heatmap)

REVIEW DASHBOARD DATA:
Provide summary after review:
- "You reviewed 10 items with 80% accuracy!"
- "Your streak: 5 days 🔥"
- "Next review scheduled for [date]"

BULK REVIEW:
- Allow reviewing all due items at once
- Show progress bar during bulk review
- Provide summary at the end

REVIEW REMINDERS:
- Suggest optimal review times
- Encourage daily reviews for streaks
- Celebrate review milestones

CUSTOM INTERVALS:
- Allow users to adjust SRS parameters if needed
- Support custom review schedules
- Respect user preferences

Target language: $_targetLanguage
User's native language: $_sourceLanguage
Current CEFR Level: ${_cefrInfo.level}

Make reviews efficient, engaging, and scientifically optimized for long-term retention. Celebrate progress and maintain motivation.''';
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
            : "Review";
    debugPrint('Switched to $modeName mode. Loaded ${_messages.length} messages.');
  }
  
  /// Set the current roleplay scenario
  Future<void> setRoleplayScenario(RoleplayEntry scenario) async {
    _currentRoleplayScenario = scenario;
    _roleplayTurnCount = 0;
    _roleplayBranches.clear();
    _roleplayProgress.clear();
    _initializeSystemPrompt(); // Reinitialize to include scenario context
    state = state.copyWith();
    debugPrint('Set roleplay scenario: ${scenario.scenario}');
  }
  
  /// Get current roleplay scenario
  RoleplayEntry? get currentRoleplayScenario => _currentRoleplayScenario;

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
      debugPrint('Encoding issue detected, fixing: $e');
      sanitized = input.replaceAll(RegExp(r'[^\x20-\x7E\n\t]'), '');
    }
    
    return sanitized;
  }

  /// Enhanced JSON parsing with fallback handling
  Map<String, dynamic>? _parseJsonSafely(String jsonStr) {
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('JSON parse error: $e for string: ${jsonStr.substring(0, jsonStr.length > 100 ? 100 : jsonStr.length)}');
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
    final conversationId = '${_mode}_${_selectedLanguage}_${_sourceLanguage}';
    final flowState = _practiceEnhancer.analyzeConversationFlow(
      messages: _messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
      currentMessage: sanitizedMessage,
    );
    
    if (effectiveSystemPrompt != null && effectiveSystemPrompt.isNotEmpty) {
      final previousContext = _contextManager.getConversationInsights(conversationId);
      effectiveSystemPrompt = _practiceEnhancer.getEnhancedPrompt(
        conversationId: conversationId,
        flowState: flowState,
        basePrompt: effectiveSystemPrompt!,
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
          
          // Stream the response word by word for natural feel
          final words = hybridResponse.output.split(' ');
          for (int i = 0; i < words.length; i++) {
            if (_userInterrupt) {
              state = state.copyWith(isLoading: false);
              return;
            }
            
            final chunk = i == 0 ? words[i] : ' ${words[i]}';
            yield chunk;
            await Future.delayed(const Duration(milliseconds: 30)); // Natural typing speed
          }
          
          // Log telemetry if diacritics were corrected
          if (hybridResponse.diacriticsCorrected) {
            debugPrint('✅ Hybrid Polie: Diacritics corrected using ${hybridResponse.model}');
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
          debugPrint('⚠️ Hybrid Polie failed, falling back to standard mode: $e');
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

        if (_groqApiKey == 'YOUR_GROQ_API_KEY' || _groqApiKey.isEmpty) {
          throw Exception('AI Chat is not configured. Please set your Groq API key.');
        }

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
        
        // Log the final message structure for debugging
        debugPrint('Sending to Groq API:');
        debugPrint('  Model: $currentModel');
        debugPrint('  System prompt length: ${systemPrompt.length}');
        debugPrint('  Messages count: ${messagesList.length}');
        for (int i = 0; i < messagesList.length; i++) {
          final msg = messagesList[i];
          final content = msg["content"] as String;
          debugPrint('  [$i] role=${msg["role"]}, content_length=${content.length}, preview=${content.substring(0, content.length > 50 ? 50 : content.length)}...');
        }
        
        // Validate model name
        if (currentModel.isEmpty) {
          throw Exception('Invalid model configuration. Please check your settings.');
        }
        
        debugPrint('Sending to Groq: model=$currentModel, messages=${messagesList.length}');
        
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
            "temperature": _mode == PolieMode.translation ? 0.2 : 0.7,
            "max_tokens": 500,
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
              debugPrint('Groq API error: Status ${response.statusCode}');
              errorDetail = 'Request validation failed. Please check your message format and API key.';
            }
          } catch (e) {
            debugPrint('Error reading response: $e');
          }
          
          if (response.statusCode == 400) {
            // Provide more helpful error message
            throw Exception('Invalid request format. ${errorDetail}\n\nPlease ensure:\n- Your message is not empty\n- API key is valid\n- Message format is correct');
          } else if (response.statusCode == 401) {
            throw Exception('Invalid API key. Please check your Groq API key in settings.');
          } else if (response.statusCode == 429) {
            throw Exception('Rate limit exceeded. Please try again in a few moments.');
          } else {
            throw Exception('Request failed with status ${response.statusCode}: ${errorDetail}');
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

                // Language-aware sentence segmentation
                // Support for African language punctuation patterns
                final isSentenceEnd = [".", "!", "?", "…", "\n"].contains(last);
                
                // Check for language-specific patterns (Yoruba, Swahili, etc.)
                final hasLanguagePause = buffer.contains(":") || 
                    buffer.contains(";") ||
                    (buffer.length > 3 && buffer.substring(buffer.length - 3).contains(" "));

                final isTurnHandOff = buffer.toLowerCase().contains("your turn") ||
                    buffer.toLowerCase().contains("now you try") ||
                    buffer.toLowerCase().contains("ask me") ||
                    buffer.trim().endsWith("?");

                // Smart buffering: emit on sentence boundaries or long pauses
                if (isSentenceEnd || hasLanguagePause || buffer.length > 60) {
                  output += buffer;
                  yield buffer;
                  buffer = "";

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

        // Evaluate user performance if tutor mode
        if (_tutorMode && _messages.length >= 2) {
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
        final diacriticsResult = DiacriticsEnforcer.enforceWithMetadata(
          output.trim(),
          _selectedLanguage,
          enableFuzzy: true,
          fuzzyThreshold: 0.75,
        );
        
        final correctedOutput = diacriticsResult['text'] as String;
        final wasChanged = diacriticsResult['changed'] as bool;
        final metadata = diacriticsResult['metadata'] as Map<String, dynamic>;
        
        // Log telemetry event if diacritics were corrected
        if (wasChanged) {
          debugPrint('Diacritics corrected: ${metadata['method']} method for $_selectedLanguage');
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
            debugPrint('Error tracking diacritics correction: $e');
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
          debugPrint('Error tracking Polie performance: $e');
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
              debugPrint('Model ${_modelNames[modelIndex - 1]} not found, trying ${_modelName}');
            }
            continue; // Try with next model
          }
        }

        if (retryCount < 1) {
          retryCount++;
          continue;
        }

        state = state.copyWith(isLoading: false);

        if (e is DioException) {
          if (e.response?.statusCode == 401) {
            throw Exception('Invalid API key. Please check your Groq API key.');
          } else if (e.response?.statusCode == 404) {
            throw Exception('Model not found. Tried: ${_modelNames.join(", ")}. Please check Groq API documentation for available models.');
          } else if (e.response?.statusCode == 429) {
            throw Exception('Rate limit exceeded. Please try again later.');
          }
        }

        // Provide more helpful error messages
        String errorMessage = 'Failed to send message';
        if (e is DioException) {
          if (e.response != null) {
            final statusCode = e.response!.statusCode;
            final errorData = e.response!.data;
            if (statusCode == 400) {
              errorMessage = 'Invalid request format. Please check your message and try again.';
              // Log the actual error for debugging
              debugPrint('Groq API 400 error: $errorData');
            } else if (statusCode == 401) {
              errorMessage = 'Invalid API key. Please check your Groq API key.';
            } else if (statusCode == 429) {
              errorMessage = 'Rate limit exceeded. Please try again in a few moments.';
            } else {
              errorMessage = 'Request failed (${statusCode}). Please try again.';
            }
          } else if (e.type == DioExceptionType.connectionTimeout ||
                     e.type == DioExceptionType.receiveTimeout) {
            errorMessage = 'Connection timed out. Please check your internet connection.';
          } else if (e.type == DioExceptionType.connectionError) {
            errorMessage = 'Connection error. Please check your internet connection.';
          }
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
  Future<String> sendMessage(String userMessage) async {
    String fullResponse = '';
    await for (final chunk in sendMessageStream(userMessage)) {
      fullResponse += chunk;
    }
    return fullResponse;
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
  }

  // ----- Word Memory (SRS) - Enhanced with SM-2 variant -----
  /// Update SRS using SM-2 algorithm
  /// quality: 0-5 (0=complete blackout, 5=perfect recall)
  void _updateSRS(String word, int quality) {
    final entry = _memory[word] ?? WordMemory();
    entry.updateWithSM2(quality);
    _memory[word] = entry;
    _saveSRSMemory();
  }
  
  /// Legacy method for backward compatibility
  void _updateSRSLegacy(String word, bool correct) {
    final quality = correct ? 4 : 2; // Map bool to quality scale
    _updateSRS(word, quality);
  }

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
    if (pct < 20) return 'A1';
    if (pct < 40) return 'A2';
    if (pct < 55) return 'B1';
    if (pct < 70) return 'B2';
    if (pct < 85) return 'C1';
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
      debugPrint('Grammar check error: $e');
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
    for (var i = 0; i <= n; i++) dp[i][0] = i;
    for (var j = 0; j <= m; j++) dp[0][j] = j;
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
    final refWords = reference.trim().toLowerCase().split(RegExp(r'\s+'));
    final hypWords = hypothesis.trim().toLowerCase().split(RegExp(r'\s+'));
    if (refWords.isEmpty) return 1.0;
    final errs = _wordErrorCount(refWords, hypWords);
    return errs / refWords.length;
  }

  // ----- Audio Transcription -----
  Future<String> transcribeAudio(Uint8List audioData) async {
    try {
      final response = await _dio.post(
        "https://api.groq.com/openai/v1/audio/transcriptions",
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
      debugPrint('Audio transcription error: $e');
      return '';
    }
  }

  // ----- Pronunciation Scoring -----
  Future<double> scorePronunciation(Uint8List audioData) async {
    try {
      final response = await _dio.post(
        "https://api.groq.com/openai/v1/audio/transcriptions",
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
      debugPrint('Pronunciation scoring error: $e');
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
        "https://api.groq.com/openai/v1/audio/transcriptions",
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
      debugPrint('Shadowing exercise error: $e');
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
      debugPrint('Listening passage generation error: $e');
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
      debugPrint('Answer evaluation error: $e');
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
      debugPrint('Curriculum generation error: $e');
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
            : "Review";
        debugPrint('Cleared chat history for $modeName mode');
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
      debugPrint('Error saving chat history: $e');
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
          debugPrint('Chat history synced to backend: ${_modeNameForBackend} × ${_languageCodeForBackend}');
        }
      } catch (apiError) {
        debugPrint('Error syncing to backend API, falling back to sync queue: $apiError');
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
      debugPrint('Error syncing chat history: $e');
    }
  }

  /// Legacy sync method (kept for backward compatibility)
  /// Now properly includes languageCode for backend validation
  Future<void> _syncChatHistoryToBackendLegacy() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final messagesJson = _messages.map((msg) => msg.toJson()).toList();
      
      final syncProvider = ref.read(backendSyncProvider.notifier);
      await syncProvider.queueSync(SyncTask(
        type: SyncType.aiChatHistory,
        data: {
          'user_id': user.id.toString(),
          'mode': _modeNameForBackend,
          'languageCode': _languageCodeForBackend, // Fixed: was missing
          'messages': messagesJson,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
      
      // Also sync SRS memory
      final memoryJson = <String, dynamic>{};
      _memory.forEach((key, value) {
        memoryJson[key] = value.toJson();
      });
      
      await syncProvider.queueSync(SyncTask(
        type: SyncType.aiChatSRS,
        data: {
          'user_id': user.id.toString(),
          'memory': memoryJson,
          'cefr': _cefrInfo.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      debugPrint('Error queuing chat sync: $e');
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
                : "Review";
            debugPrint('Loaded ${_messages.length} messages from backend: $modeName × $_languageCodeForBackend');
            state = state.copyWith();
            
            // Also save to local storage for offline access
            final prefs = await SharedPreferences.getInstance();
            final messagesJson = _messages.map((msg) => msg.toJson()).toList();
            await prefs.setString(_chatHistoryKey, jsonEncode(messagesJson));
            return;
          }
        }
      } catch (backendError) {
        debugPrint('Error loading from backend, trying local storage: $backendError');
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
            : "Review";
        debugPrint('Loaded ${_messages.length} messages from local storage for $modeName mode');
        state = state.copyWith();
      } else {
        // No history for this mode × language combination
        _messages.clear();
        final modeName = _mode == PolieMode.translation ? "Translation" 
            : _mode == PolieMode.tutor ? "Tutor"
            : _mode == PolieMode.roleplay ? "Roleplay"
            : _mode == PolieMode.conversation ? "Conversation"
            : _mode == PolieMode.vocab ? "Vocab"
            : "Review";
        debugPrint('No chat history found for $modeName mode × ${_languageCodeForBackend}');
        state = state.copyWith();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      // On error, clear messages to prevent showing wrong mode's history
      _messages.clear();
      state = state.copyWith();
    }
  }

  Future<void> _saveSRSMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoryJson = _memory.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString('srs_memory', jsonEncode(memoryJson));
    } catch (e) {
      debugPrint('Error saving SRS memory: $e');
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
      debugPrint('Error loading SRS memory: $e');
    }
  }

  Future<void> _saveCEFRInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cefr_info', jsonEncode(_cefrInfo.toJson()));
    } catch (e) {
      debugPrint('Error saving CEFR info: $e');
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
      debugPrint('Error loading CEFR info: $e');
    }
  }
}


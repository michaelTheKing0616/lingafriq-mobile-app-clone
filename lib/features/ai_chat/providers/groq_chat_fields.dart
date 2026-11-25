part of 'package:lingafriq/providers/ai_chat_provider_groq.dart';

mixin GroqChatFieldsMixin on Notifier<BaseProviderState>, BaseProviderMixin {
  final List<ChatMessage> _messages = [];
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 30),
  ));

  // P6-019: model routing is server-side; client sends gateway mode only.
  static const List<String> _legacyModelLabels = ['gateway'];
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
  String _sourceLanguage = 'English';
  String _targetLanguage = 'Yoruba';
  String? _systemPrompt;
  PolieMode _mode = PolieMode.tutor;
  bool _tutorMode = true;
  // ignore: unused_field
  final bool _adaptive = true;
  int _difficulty = 1;
  int _successStreak = 0;
  int _failureStreak = 0;
  int _turnIndex = 0;
  bool _userInterrupt = false;
  VoidCallback? _currentStreamCancel;
  DateTime? _lastBackendSync;
  int _roleplayTurnCount = 0;
  Map<String, dynamic>? _scenarioContextHint;
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
  final ConversationContextManager _contextManager = ConversationContextManager();
  final ConversationPracticeEnhancer _practiceEnhancer = ConversationPracticeEnhancer();
  final ErrorRecoveryService _errorRecovery = ErrorRecoveryService();
  final PerformanceAnalytics _performanceAnalytics = PerformanceAnalytics();
  
  // Roleplay scenario tracking
  RoleplayEntry? _currentRoleplayScenario;
  final List<String> _roleplayBranches = [];
  final Map<String, dynamic> _roleplayProgress = {};
  String? _practiceTypeHint;
  String? _scenarioTypeHint;
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

  final Random _random = Random();
  
  // ----- Tutor Turn & Adaptive Prompt -----
}

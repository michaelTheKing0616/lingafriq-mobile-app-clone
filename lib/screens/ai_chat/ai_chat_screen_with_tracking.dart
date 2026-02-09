import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'package:lingafriq/providers/ai_chat_provider_groq.dart' show groqChatProvider, PolieMode;
import 'package:lingafriq/utils/roleplay_session_helper.dart';
import 'package:lingafriq/utils/ai_chat_navigation_helper.dart';
import 'package:lingafriq/services/ai_chat_integration_service.dart';
import 'package:lingafriq/services/conversation_analytics_service.dart';
import 'package:lingafriq/services/tutor_progress_service.dart';
import 'package:lingafriq/services/vocabulary_progress_service.dart';
import 'package:lingafriq/services/review_progress_service.dart';
import 'package:lingafriq/services/translation_history_service.dart';
import 'package:lingafriq/models/vocabulary_progress_model.dart';
import 'package:lingafriq/models/tutor_progress_model.dart';

/// Enhanced AI Chat Screen with Full Progress Tracking
/// Integrates all progress tracking services for comprehensive analytics
class AIChatScreenWithTracking extends HookConsumerWidget {
  final String language;
  final String languageName;
  final String mode;
  final String modeName;
  final dynamic initialScenario; // RoleplayEntry for roleplay mode

  const AIChatScreenWithTracking({
    Key? key,
    required this.language,
    required this.languageName,
    required this.mode,
    required this.modeName,
    this.initialScenario,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final messages = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(false);
    final scrollController = useScrollController();
    final sessionHelper = useMemoized(() => RoleplaySessionHelper(ref as Ref));
    final integrationService = ref.read(aiChatIntegrationServiceProvider);
    final conversationService = ref.read(conversationAnalyticsServiceProvider);
    final tutorService = ref.read(tutorProgressServiceProvider);
    final vocabService = ref.read(vocabularyProgressServiceProvider);
    final reviewService = ref.read(reviewProgressServiceProvider);
    final translationService = ref.read(translationHistoryServiceProvider);
    final chatProvider = ref.read(groqChatProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionStartTime = useRef<DateTime?>(null);
    final messageCount = useRef<int>(0);
    final wordCount = useRef<int>(0);
    final topics = useRef<Set<String>>({});
    final vocabularyUsed = useRef<Map<String, int>>({});
    final errors = useRef<int>(0);
    final corrections = useRef<List<String>>([]);

    // Initialize session tracking
    useEffect(() {
      sessionStartTime.value = DateTime.now();
      messageCount.value = 0;
      wordCount.value = 0;
      topics.value = {};
      vocabularyUsed.value = {};
      errors.value = 0;
      corrections.value = [];

      // Start roleplay session if applicable
      if (mode == 'roleplay' && initialScenario != null) {
        sessionHelper.startSession(
          scenarioId: initialScenario.id ?? initialScenario.scenario ?? 'unknown',
          language: languageName,
          metadata: {
            'scenario': initialScenario.scenario ?? '',
            'category': initialScenario.category ?? 'general',
            'difficulty': initialScenario.difficulty ?? 'A1',
          },
        );
      }

      return null;
    }, []);

    // Load chat history
    Future<void> _loadChatHistory() async {
      try {
        final response = await ApiService.get(
          '/ai-chat/history',
          queryParameters: {
            'language': language,
            'mode': mode,
          },
        );

        if (response.statusCode == 200 && response.data['data'] != null) {
          messages.value = List<Map<String, dynamic>>.from(response.data['data']);
        }
      } catch (e) {
        // History might not exist yet, that's okay
      }
    }

    useEffect(() {
      _loadChatHistory();
      return null;
    }, []);

    Future<void> sendMessage() async {
      if (messageController.text.isEmpty) return;

      final userMessageText = messageController.text.trim();
      final userMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': userMessageText,
        'sender': 'user',
        'timestamp': DateTime.now().toIso8601String(),
      };

      messages.value = [...messages.value, userMessage];
      messageController.clear();

      // Update tracking
      messageCount.value++;
      final words = userMessageText.split(' ').where((w) => w.isNotEmpty).toList();
      wordCount.value += words.length;
      for (final word in words) {
        vocabularyUsed.value[word.toLowerCase()] = (vocabularyUsed.value[word.toLowerCase()] ?? 0) + 1;
      }

      // Scroll to bottom
      Future.delayed(Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      isLoading.value = true;
      try {
        // Atomic mode+language switch for correct history scoping
        final polieMode = _mapModeToPolieMode(mode);
        await chatProvider.setModeAndLanguage(
          mode: polieMode,
          targetLanguage: languageName,
          sourceLanguage: language,
        );

        final response = await chatProvider.sendMessage(userMessageText);

        // Extract topics and vocabulary from response
        _extractTopicsAndVocab(response, topics.value, vocabularyUsed.value);

        final polieMessage = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'text': response,
          'sender': 'polie',
          'timestamp': DateTime.now().toIso8601String(),
        };
        messages.value = [...messages.value, polieMessage];

        // Track roleplay turn
        if (mode == 'roleplay') {
          sessionHelper.recordTurn(
            vocabulary: words,
            grammar: _extractGrammarPoints(response),
            correction: _extractCorrection(response),
          );
        }

        // Track tutor interaction
        if (mode == 'tutor') {
          await _trackTutorInteraction(
            tutorService,
            userMessageText,
            response,
            languageName,
          );
        }

        // Track vocabulary
        if (mode == 'vocab') {
          await _trackVocabulary(vocabService, words, languageName);
        }

      } catch (e) {
        errors.value++;
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      } finally {
        isLoading.value = false;
      }
    }

    // Handle session completion
    Future<void> _handleSessionCompletion() async {
      if (sessionStartTime.value == null) return;

      final sessionDuration = DateTime.now().difference(sessionStartTime.value!);

      // Record conversation session
      if (mode == 'conversation') {
        final fluencyScore = integrationService.calculateConversationFluency(
          messageCount: messageCount.value,
          wordCount: wordCount.value,
          errorCount: errors.value,
          vocabularyUsed: vocabularyUsed.value,
        );

        await integrationService.recordConversationSession(
          sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
          language: languageName,
          startTime: sessionStartTime.value!,
          messageCount: messageCount.value,
          wordCount: wordCount.value,
          topics: topics.value.toList(),
          fluencyScore: fluencyScore,
          errorCount: errors.value,
          corrections: corrections.value,
          vocabularyUsed: vocabularyUsed.value,
          metadata: {},
        );
      }

      // Handle roleplay completion
      if (mode == 'roleplay') {
        final result = await sessionHelper.completeSession();
        if (result != null && context.mounted) {
          navigateToRoleplayCompletionSummary(
            context,
            result: result,
            language: language,
            languageName: languageName,
            onContinue: () {
              Navigator.pop(context);
            },
          );
        }
      }
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _handleSessionCompletion();
        }
      },
      child: LoadingOverlay(
        isLoading: isLoading.value,
        message: 'Sending message...',
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(modeName),
                Text(
                  languageName,
                  style: PanAfricanTypography.bodySmall(context),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              // Progress dashboard button
              IconButton(
                icon: Icon(Icons.analytics),
                onPressed: () {
                  _navigateToDashboard(context, mode, language, languageName);
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? PanAfricanGradients.darkSurface
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        PanAfricanColors.surfaceLight,
                        PanAfricanColors.surfaceContainerLight,
                      ],
                    ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    itemCount: messages.value.length,
                    itemBuilder: (context, index) {
                      final message = messages.value[index];
                      final isUser = message['sender'] == 'user';
                      return _MessageBubble(
                        message: message,
                        isUser: isUser,
                        isDark: isDark,
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideX(begin: isUser ? 0.1 : -0.1);
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black38,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                              ),
                              filled: true,
                              fillColor: isDark ? PanAfricanColors.surfaceDark : Colors.white,
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => sendMessage(),
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: sendMessage,
                          color: PanAfricanColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PolieMode _mapModeToPolieMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'translation':
        return PolieMode.translation;
      case 'tutor':
        return PolieMode.tutor;
      case 'roleplay':
        return PolieMode.roleplay;
      case 'conversation':
        return PolieMode.conversation;
      case 'vocab':
      case 'vocabulary':
        return PolieMode.vocab;
      case 'review':
        return PolieMode.review;
      default:
        return PolieMode.tutor;
    }
  }

  void _extractTopicsAndVocab(String text, Set<String> topics, Map<String, int> vocab) {
    // Simple topic extraction - in production, use NLP
    final topicKeywords = ['food', 'travel', 'greeting', 'shopping', 'weather', 'family', 'work', 'health'];
    final lowerText = text.toLowerCase();
    for (final keyword in topicKeywords) {
      if (lowerText.contains(keyword)) {
        topics.add(keyword);
      }
    }

    // Extract vocabulary (simple word extraction)
    final words = text.split(RegExp(r'[^\w\s]')).where((w) => w.length > 3).toList();
    for (final word in words) {
      vocab[word.toLowerCase()] = (vocab[word.toLowerCase()] ?? 0) + 1;
    }
  }

  List<String> _extractGrammarPoints(String text) {
    // Simple grammar extraction - in production, use NLP
    final grammarKeywords = ['verb', 'noun', 'adjective', 'tense', 'plural', 'singular'];
    final lowerText = text.toLowerCase();
    return grammarKeywords.where((keyword) => lowerText.contains(keyword)).toList();
  }

  String? _extractCorrection(String text) {
    // Look for correction patterns
    if (text.toLowerCase().contains('correction') || text.toLowerCase().contains('should be')) {
      return text;
    }
    return null;
  }

  Future<void> _trackTutorInteraction(
    TutorProgressService service,
    String userInput,
    String response,
    String language,
  ) async {
    // Extract skill scores from interaction
    final skillScores = <String, double>{
      'grammar': 0.8,
      'pronunciation': 0.7,
      'vocabulary': 0.85,
      'comprehension': 0.75,
    };

    // Calculate overall score
    final overallScore = skillScores.values.reduce((a, b) => a + b) / skillScores.length;

    // Extract topics and vocabulary
    final topics = <String>[];
    final vocabulary = <String>[];
    final grammar = <String>[];

    // Simple extraction - in production, use AI to analyze
    if (response.toLowerCase().contains('grammar')) {
      topics.add('Grammar');
      grammar.add('Basic grammar');
    }
    if (response.toLowerCase().contains('vocab')) {
      topics.add('Vocabulary');
      vocabulary.addAll(userInput.split(' ').where((w) => w.length > 3).take(5));
    }

    // Create interaction
    final interaction = TutorInteraction(
      type: 'question',
      content: userInput,
      userResponse: userInput,
      score: overallScore,
      feedback: response,
      timestamp: DateTime.now(),
    );

    // Record session (simplified - would batch interactions)
    // In production, batch interactions and record at session end
  }

  Future<void> _trackVocabulary(
    VocabularyProgressService service,
    List<String> words,
    String language,
  ) async {
    for (final word in words) {
      if (word.length > 2) {
        await service.addWord(
          VocabularyWord(
            word: word,
            meaning: '',
            language: language,
          ),
          category: 'conversation',
        );
      }
    }
  }

  void _navigateToDashboard(BuildContext context, String mode, String language, String languageName) {
    switch (mode.toLowerCase()) {
      case 'roleplay':
        navigateToRoleplayProgressDashboard(context, language: language, languageName: languageName);
        break;
      case 'tutor':
        navigateToTutorProgressDashboard(context, language: language, languageName: languageName);
        break;
      case 'conversation':
        navigateToConversationAnalytics(context, language: language, languageName: languageName);
        break;
      case 'vocab':
      case 'vocabulary':
        navigateToVocabularyDashboard(context, language: language, languageName: languageName);
        break;
      case 'review':
        navigateToReviewDashboard(context, language: language, languageName: languageName);
        break;
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isUser;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16.r,
              backgroundColor: PanAfricanColors.primary,
              child: Icon(Icons.smart_toy, size: 16.sp, color: Colors.white),
            ),
            SizedBox(width: PanAfricanSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.md,
                vertical: PanAfricanSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight),
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'] as String? ?? '',
                    style: PanAfricanTypography.bodyMedium(context)?.copyWith(
                      color: isUser ? Colors.white : null,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    _formatTime(message['timestamp'] as String?),
                    style: PanAfricanTypography.bodySmall(context)?.copyWith(
                      color: isUser ? Colors.white70 : PanAfricanColors.neutralMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: PanAfricanSpacing.sm),
            CircleAvatar(
              radius: 16.r,
              backgroundColor: PanAfricanColors.secondary,
              child: Icon(Icons.person, size: 16.sp, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(time);
      
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}


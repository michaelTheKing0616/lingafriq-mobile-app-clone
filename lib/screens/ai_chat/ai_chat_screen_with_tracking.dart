import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
// Chat history is managed by Groq provider (local + backend sync); no backend /ai-chat/history call
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/empty_state_widget.dart';
import 'package:lingafriq/widgets/error_state_widget.dart';
import 'package:lingafriq/widgets/skeleton_loader.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart' show groqChatProvider, GroqChatProvider, PolieMode;
import 'package:lingafriq/data/roleplay_dataset.dart';
import 'package:lingafriq/utils/roleplay_session_helper.dart';
import 'package:lingafriq/utils/ai_chat_navigation_helper.dart';
import 'package:lingafriq/services/ai_chat_integration_service.dart';
import 'package:lingafriq/services/tutor_progress_service.dart';
import 'package:lingafriq/services/vocabulary/vocabulary_service.dart';
import 'package:lingafriq/services/vocabulary_progress_service.dart';
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
  final String? scenarioType;
  final String? practiceType;
  final Map<String, dynamic>? scenarioContext;

  const AIChatScreenWithTracking({
    super.key,
    required this.language,
    required this.languageName,
    required this.mode,
    required this.modeName,
    this.initialScenario,
    this.scenarioType,
    this.practiceType,
    this.scenarioContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final messages = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(false);
    // Chat history is managed by Groq provider (local + backend sync); no backend /ai-chat/history call
    // isLoadingHistory kept for UI compatibility but always false
    final isLoadingHistory = useState(false);
    final loadHistoryError = useState<String?>(null);
    final scrollController = useScrollController();
    final sessionHelper = useMemoized(() => RoleplaySessionHelper(ref));
    final integrationService = ref.read(aiChatIntegrationServiceProvider);
    final tutorService = ref.read(tutorProgressServiceProvider);
    final vocabService = ref.read(vocabularyProgressServiceProvider);
    final vocabularyBankService = ref.read(vocabularyServiceProvider);
    final chatProvider = ref.read(groqChatProvider.notifier);
    final routeArgsRaw = ModalRoute.of(context)?.settings.arguments;
    final routeArgs = routeArgsRaw is Map ? Map<String, dynamic>.from(routeArgsRaw) : const <String, dynamic>{};

    final resolvedMode = _resolveStringArg(routeArgs, 'mode') ?? mode;
    final resolvedScenarioType = _resolveStringArg(routeArgs, 'scenarioType') ?? scenarioType;
    final resolvedPracticeType = _resolveStringArg(routeArgs, 'practiceType') ?? practiceType;
    final routeScenarioContext = routeArgs['scenarioContext'];
    final resolvedScenarioContext = routeScenarioContext is Map
        ? Map<String, dynamic>.from(routeScenarioContext)
        : (scenarioContext ?? const <String, dynamic>{});
    final resolvedPolieMode = _mapModeToPolieMode(resolvedMode);
    final resolvedModeName = modeName.trim().isNotEmpty
        ? modeName
        : resolvedMode.substring(0, 1).toUpperCase() + resolvedMode.substring(1);
    final hasScenarioImage = (resolvedScenarioContext['scenarioImage']?.toString().trim().isNotEmpty ?? false);
    final requiresPhotoDescription = resolvedPracticeType == 'photo' && !hasScenarioImage;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionStartTime = useRef<DateTime?>(null);
    final messageCount = useRef<int>(0);
    final wordCount = useRef<int>(0);
    final topics = useRef<Set<String>>({});
    final vocabularyUsed = useRef<Map<String, int>>({});
    final errors = useRef<int>(0);
    final corrections = useRef<List<String>>([]);

    Future<void> initializeRoleplaySession() async {
      isLoadingHistory.value = true;
      loadHistoryError.value = null;
      try {
        await chatProvider
            .setModeAndLanguage(
              mode: resolvedPolieMode,
              targetLanguage: languageName,
              sourceLanguage: language,
            )
            .timeout(const Duration(seconds: 12));

        if (initialScenario is RoleplayEntry) {
          await chatProvider
              .setRoleplayScenario(initialScenario as RoleplayEntry)
              .timeout(const Duration(seconds: 12));
        }
      } catch (e) {
        loadHistoryError.value = 'Roleplay setup had issues. You can retry or continue chatting.';
      } finally {
        _initRoleplay(
          chatProvider,
          sessionHelper,
          resolvedPolieMode,
          languageName,
          language,
          initialScenario,
          messages,
        );
        isLoadingHistory.value = false;
      }
    }

    // Initialize session tracking and set mode+language atomically ONCE
    useEffect(() {
      sessionStartTime.value = DateTime.now();
      messageCount.value = 0;
      wordCount.value = 0;
      topics.value = {};
      vocabularyUsed.value = {};
      errors.value = 0;
      corrections.value = [];

      chatProvider.setScenarioContextHints(
        practiceType: resolvedPracticeType,
        scenarioType: resolvedScenarioType,
        scenarioContext: resolvedScenarioContext,
      );

      // For roleplay, RoleplayScenarioSelectionScreen already set mode+language
      // and injected the scenario intro. Calling setModeAndLanguage again would
      // clear that intro. Instead, just ensure the scenario is applied.
      if (resolvedMode == 'roleplay' && initialScenario != null) {
        initializeRoleplaySession();
      } else {
        chatProvider.setModeAndLanguage(
          mode: resolvedPolieMode,
          targetLanguage: languageName,
          sourceLanguage: language,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final welcome = _buildScenarioAwareWelcome(
            mode: resolvedPolieMode,
            languageName: languageName,
            scenarioType: resolvedScenarioType,
            practiceType: resolvedPracticeType,
            scenarioContext: resolvedScenarioContext,
          );
          messages.value = [
            {
              'id': 'welcome',
              'text': welcome,
              'sender': 'polie',
              'timestamp': DateTime.now().toIso8601String(),
            },
          ];
        });
      }

      return null;
    }, []);

    Future<void> sendMessage() async {
      if (messageController.text.isEmpty || isLoading.value) return;

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
        // Mode+language already set atomically in useEffect init.
        // Do NOT call setModeAndLanguage per-message — it triggers
        // a full save/clear/load cycle which would wipe the visible messages.
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
        if (resolvedMode == 'roleplay') {
          sessionHelper.recordTurn(
            vocabulary: words,
            grammar: _extractGrammarPoints(response),
            correction: _extractCorrection(response),
          );
        }

        // Track tutor interaction
        if (resolvedMode == 'tutor') {
          await _trackTutorInteraction(
            tutorService,
            userMessageText,
            response,
            languageName,
          );
        }

        // Track vocabulary
        if (resolvedMode == 'vocab') {
          await _trackVocabulary(vocabService, vocabularyBankService, words, languageName);
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
    Future<void> handleSessionCompletion() async {
      if (sessionStartTime.value == null) return;

      // Record conversation session
      if (resolvedMode == 'conversation') {
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
      if (resolvedMode == 'roleplay') {
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
          await handleSessionCompletion();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resolvedModeName),
                Text(
                  languageName,
                  style: PanAfricanTypography.bodySmall(context),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Semantics(
              label: 'Progress dashboard',
              button: true,
              child: IconButton(
                icon: Icon(Icons.analytics, semanticLabel: 'Analytics'),
                onPressed: () {
                  _navigateToDashboard(context, resolvedMode, language, languageName);
                },
              ),
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
              _ModeBanner(mode: resolvedMode, languageName: languageName, isDark: isDark),
              if (requiresPhotoDescription)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.fromLTRB(
                    PanAfricanSpacing.md,
                    PanAfricanSpacing.sm,
                    PanAfricanSpacing.md,
                    0,
                  ),
                  padding: EdgeInsets.all(PanAfricanSpacing.sm),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.warning.withOpacity(isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    border: Border.all(
                      color: PanAfricanColors.warning.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    'Photo practice works best with visual details. Start by describing the scene in 1-2 sentences (people, place, and action), then ask a follow-up question.',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ),
              if (messages.value.isEmpty)
                _ModeSuggestionChips(
                  mode: resolvedMode,
                  languageName: languageName,
                  onSuggestionTap: (text) {
                    messageController.text = text;
                  },
                ),
              Expanded(
                child: isLoadingHistory.value
                    ? ListView.builder(
                        padding: EdgeInsets.all(PanAfricanSpacing.md),
                        itemCount: 4,
                        itemBuilder: (_, __) => SkeletonListCard(),
                      )
                    : (loadHistoryError.value != null && messages.value.isEmpty)
                        ? AppErrorState(
                            message: loadHistoryError.value!,
                            onRetry: resolvedMode == 'roleplay' ? initializeRoleplaySession : null,
                          )
                        : loadHistoryError.value != null
                            ? AppEmptyState(
                                icon: Icons.warning_amber_rounded,
                                title: 'Recovery mode',
                                subtitle:
                                    'Setup had issues, but you can continue chatting normally.',
                              )
                        : messages.value.isEmpty
                            ? AppEmptyState(
                                icon: _getModeIcon(resolvedMode),
                                title: _getModeEmptyTitle(resolvedMode),
                                subtitle: _getModeEmptySubtitle(
                                  resolvedMode,
                                  languageName,
                                  practiceType: resolvedPracticeType,
                                  scenarioContext: resolvedScenarioContext,
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: EdgeInsets.all(PanAfricanSpacing.md),
                                itemCount: messages.value.length + (isLoading.value ? 1 : 0),
                                itemBuilder: (context, index) {
                                  // Show typing indicator as the last item
                                  if (index >= messages.value.length) {
                                    return _TypingIndicator(isDark: isDark);
                                  }
                                  final message = messages.value[index];
                                  final isUser = message['sender'] == 'user';
                                  final senderLabel = isUser ? 'Your message' : 'AI message';
                                  final text = message['text'] as String? ?? '';
                                  return Semantics(
                                    label: '$senderLabel: $text',
                                    excludeSemantics: true,
                                    child: _MessageBubble(
                                      message: message,
                                      isUser: isUser,
                                      isDark: isDark,
                                    ),
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
                        child: Semantics(
                          label: 'Chat message input',
                          hint: 'Type your message',
                          child: TextField(
                            controller: messageController,
                            enabled: !isLoading.value,
                            maxLength: 2000,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: isLoading.value ? 'Polie is thinking...' : 'Type your message...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                              counterText: '',
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => sendMessage(),
                          ),
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.sm),
                      Semantics(
                        label: 'Send message',
                        button: true,
                        child: isLoading.value
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: PanAfricanColors.primary,
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.send, semanticLabel: 'Send'),
                                onPressed: sendMessage,
                                color: PanAfricanColors.primary,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initRoleplay(
    GroqChatProvider chatProvider,
    RoleplaySessionHelper sessionHelper,
    PolieMode polieMode,
    String languageName,
    String language,
    dynamic scenario,
    ValueNotifier<List<Map<String, dynamic>>> messages,
  ) {
    try {
      final scenarioObj = scenario;
      final scenarioId = scenarioObj is Map
          ? (scenarioObj['id']?.toString() ?? 'unknown')
          : (scenarioObj.id?.toString() ?? scenarioObj.scenario?.toString() ?? 'unknown');
      final scenarioName = scenarioObj is Map
          ? (scenarioObj['scenario'] ?? '')
          : (scenarioObj.scenario ?? '');
      sessionHelper.startSession(
        scenarioId: scenarioId,
        language: languageName,
        metadata: {
          'scenario': scenarioName,
          'category': 'general',
          'difficulty': 'A1',
        },
      );
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scenarioText = scenario is Map
          ? (scenario['scenario'] ?? '')
          : (scenario.scenario ?? '');
      final intro = scenarioText.toString().isNotEmpty
          ? 'Welcome! You\'ve just entered the "$scenarioText" scenario in $languageName. Let\'s begin!'
          : GroqChatProvider.getWelcomeMessage(polieMode, languageName);
      messages.value = [
        {
          'id': 'welcome',
          'text': intro,
          'sender': 'polie',
          'timestamp': DateTime.now().toIso8601String(),
        },
      ];
    });
  }

  String? _resolveStringArg(Map<String, dynamic> args, String key) {
    final value = args[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _buildScenarioAwareWelcome({
    required PolieMode mode,
    required String languageName,
    String? scenarioType,
    String? practiceType,
    Map<String, dynamic>? scenarioContext,
  }) {
    final base = GroqChatProvider.getWelcomeMessage(mode, languageName);
    if (practiceType == 'debate') {
      final topic = scenarioContext?['scenarioTitle']?.toString();
      final debateTopic = (topic != null && topic.trim().isNotEmpty)
          ? topic.trim()
          : 'today\'s topic';
      return '$base\n\nDebate setup: take a clear position on "$debateTopic", defend it with reasons, and challenge weak arguments politely.';
    }
    if (practiceType == 'photo') {
      final hasImage = scenarioContext?['scenarioImage']?.toString().trim().isNotEmpty ?? false;
      if (!hasImage) {
        return '$base\n\nPhoto practice tip: first describe the scene in 1-2 sentences (people, place, action), then ask a question so I can respond with context.';
      }
    }
    if (scenarioType != null && scenarioType.isNotEmpty) {
      return '$base\n\nScenario context is active, so I will keep responses aligned to this practice flow.';
    }
    return base;
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
      case 'pronunciation':
        return PolieMode.pronunciation;
      case 'grammar':
        return PolieMode.grammar;
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
    try {
      final userText = userInput.trim();
      final tutorText = response.trim();
      if (userText.isEmpty && tutorText.isEmpty) {
        return;
      }

      final userWords = userText
          .split(RegExp(r'\s+'))
          .map((word) => word.trim())
          .where((word) => word.isNotEmpty)
          .toList();
      final responseWords = tutorText
          .split(RegExp(r'\s+'))
          .map((word) => word.trim())
          .where((word) => word.isNotEmpty)
          .toList();

      final lowerUser = userText.toLowerCase();
      final lowerResponse = tutorText.toLowerCase();
      const hasBackendEvaluator = bool.fromEnvironment(
        'ENABLE_BACKEND_TUTOR_EVALUATOR',
        defaultValue: false,
      );
      final skillScores = <String, double>{};
      final overallScore = hasBackendEvaluator ? 50.0 : 0.0;

      final vocabulary = userWords
          .map((word) => word.replaceAll(RegExp(r"[^\w']"), '').toLowerCase())
          .where((word) => word.length > 2)
          .toSet()
          .take(8)
          .toList();

      final topicKeywords = <String, List<String>>{
        'Grammar': ['grammar', 'tense', 'sentence', 'verb', 'noun'],
        'Vocabulary': ['word', 'vocab', 'phrase', 'meaning', 'translate'],
        'Pronunciation': ['pronounce', 'pronunciation', 'sound', 'accent', 'tone'],
        'Conversation': ['conversation', 'chat', 'dialogue', 'talk'],
      };
      final topics = <String>[];
      for (final entry in topicKeywords.entries) {
        if (entry.value.any((keyword) => lowerUser.contains(keyword) || lowerResponse.contains(keyword))) {
          topics.add(entry.key);
        }
      }
      if (topics.isEmpty) {
        topics.add('Tutor Practice');
      }

      final grammar = <String>[
        if (lowerResponse.contains('tense')) 'Tense',
        if (lowerResponse.contains('verb')) 'Verb usage',
        if (lowerResponse.contains('agreement')) 'Agreement',
        if (lowerResponse.contains('word order')) 'Word order',
      ];

      final interaction = TutorInteraction(
        type: userText.contains('?') ? 'question' : 'exercise',
        content: tutorText,
        userResponse: userText,
        score: hasBackendEvaluator ? overallScore : null,
        feedback: tutorText,
        timestamp: DateTime.now(),
      );

      await service.recordSession(
        TutorSessionResult(
          sessionId: 'tutor_${DateTime.now().millisecondsSinceEpoch}',
          language: language,
          cefrLevel: 'A1',
          interactions: [interaction],
          overallScore: overallScore,
          skillScores: skillScores,
          topicsCovered: topics,
          vocabularyLearned: vocabulary,
          grammarPoints: grammar,
          timeSpent: 1,
          completedAt: DateTime.now(),
          metadata: {
            'source': 'ai_chat_tutor_turn',
            'user_words': userWords.length,
            'response_words': responseWords.length,
            'is_scored': hasBackendEvaluator,
            'scoring_mode': hasBackendEvaluator ? 'backend' : 'neutral',
          },
        ),
      );
    } catch (e) {
      debugPrint('Non-blocking tutor tracking error: $e');
    }
  }

  Future<void> _trackVocabulary(
    VocabularyProgressService service,
    VocabularyService vocabularyService,
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
        await vocabularyService.addWord(
          word: word,
          language: language,
          translation: '',
          tags: const ['ai_chat', 'conversation'],
          enrichWithAI: false,
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
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 16.r,
                backgroundColor: PanAfricanColors.primary,
                child: Icon(Icons.smart_toy, size: 16.sp, color: Theme.of(context).colorScheme.onPrimary),
              ),
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
                    style: PanAfricanTypography.bodyMedium(context).copyWith(
                      color: isUser ? Theme.of(context).colorScheme.onPrimary : null,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    _formatTime(message['timestamp'] as String?),
                    style: PanAfricanTypography.bodySmall(context).copyWith(
                      color: isUser ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7) : PanAfricanColors.neutralMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: PanAfricanSpacing.sm),
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 16.r,
                backgroundColor: PanAfricanColors.secondary,
                child: Icon(Icons.person, size: 16.sp, color: Theme.of(context).colorScheme.onSecondary),
              ),
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

/// Inline typing indicator shown in the message list while Polie is thinking.
class _TypingIndicator extends StatelessWidget {
  final bool isDark;
  const _TypingIndicator({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: PanAfricanColors.primary,
            child: Icon(Icons.smart_toy, size: 16.sp, color: Theme.of(context).colorScheme.onPrimary),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md,
              vertical: PanAfricanSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4),
                _buildDot(1),
                SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: PanAfricanColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

IconData _getModeIcon(String mode) {
  switch (mode.toLowerCase()) {
    case 'translation': return Icons.translate_rounded;
    case 'tutor': return Icons.school_rounded;
    case 'roleplay': return Icons.theater_comedy_rounded;
    case 'conversation': return Icons.chat_bubble_outline_rounded;
    case 'vocab': case 'vocabulary': return Icons.book_rounded;
    case 'review': return Icons.refresh_rounded;
    case 'pronunciation': return Icons.record_voice_over_rounded;
    case 'grammar': return Icons.account_tree_rounded;
    default: return Icons.chat_bubble_outline_rounded;
  }
}

String _getModeEmptyTitle(String mode) {
  switch (mode.toLowerCase()) {
    case 'translation': return 'Ready to translate!';
    case 'tutor': return 'Lesson time!';
    case 'roleplay': return 'Enter the scene!';
    case 'conversation': return 'Let\'s chat!';
    case 'vocab': case 'vocabulary': return 'Build your vocabulary!';
    case 'review': return 'Time to review!';
    case 'pronunciation': return 'Practice your pronunciation!';
    case 'grammar': return 'Grammar workshop!';
    default: return 'Start a conversation!';
  }
}

String _getModeEmptySubtitle(
  String mode,
  String lang, {
  String? practiceType,
  Map<String, dynamic>? scenarioContext,
}) {
  if (practiceType == 'debate') {
    final topic = scenarioContext?['scenarioTitle']?.toString();
    final debateTopic = (topic != null && topic.trim().isNotEmpty) ? topic.trim() : 'the scenario topic';
    return 'Debate mode is active for "$debateTopic". State your position first, then support it with two reasons.';
  }
  if (practiceType == 'photo') {
    final hasImage = scenarioContext?['scenarioImage']?.toString().trim().isNotEmpty ?? false;
    if (!hasImage) {
      return 'No image attached yet. Start by describing what you imagine in the scene, then ask a follow-up question in $lang.';
    }
  }
  switch (mode.toLowerCase()) {
    case 'translation': return 'Type any word or phrase to translate to $lang.';
    case 'tutor': return 'Ask me to teach you about verbs, greetings, numbers, or any topic in $lang.';
    case 'roleplay': return 'You\'re in a real-world scenario. Respond naturally in $lang!';
    case 'conversation': return 'Chat freely in $lang. I\'ll gently correct mistakes as we go.';
    case 'vocab': case 'vocabulary': return 'I\'ll teach you new $lang words with examples and quizzes.';
    case 'review': return 'I\'ll quiz you on words and grammar you\'ve learned in $lang.';
    case 'pronunciation': return 'Let\'s work on sounds, tones, and phonetics for $lang.';
    case 'grammar': return 'I\'ll teach you sentence patterns and rules for $lang with practice.';
    default: return 'I\'m here to help you learn. Type your message below.';
  }
}

class _ModeBanner extends StatelessWidget {
  final String mode;
  final String languageName;
  final bool isDark;
  const _ModeBanner({required this.mode, required this.languageName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final config = _getModeConfig(mode);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md, vertical: PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: config.color.withOpacity(isDark ? 0.15 : 0.08),
        border: Border(bottom: BorderSide(color: config.color.withOpacity(0.3), width: 1)),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 20),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Text(
              config.label,
              style: PanAfricanTypography.bodySmall(context).copyWith(
                color: config.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static _ModeConfig _getModeConfig(String mode) {
    switch (mode.toLowerCase()) {
      case 'translation': return _ModeConfig(Icons.translate_rounded, Color(0xFF2196F3), 'Translation Mode');
      case 'tutor': return _ModeConfig(Icons.school_rounded, Color(0xFFFF9800), 'Tutor Mode — structured lessons');
      case 'roleplay': return _ModeConfig(Icons.theater_comedy_rounded, Color(0xFF9C27B0), 'Roleplay Mode — immersive scenario');
      case 'conversation': return _ModeConfig(Icons.chat_bubble_outline_rounded, Color(0xFF4CAF50), 'Conversation Mode — free-flowing chat');
      case 'vocab': case 'vocabulary': return _ModeConfig(Icons.book_rounded, Color(0xFFFF5722), 'Vocabulary Mode — learn new words');
      case 'review': return _ModeConfig(Icons.refresh_rounded, Color(0xFF009688), 'Review Mode — test your memory');
      case 'pronunciation': return _ModeConfig(Icons.record_voice_over_rounded, Color(0xFF3F51B5), 'Pronunciation Mode — master sounds');
      case 'grammar': return _ModeConfig(Icons.account_tree_rounded, Color(0xFF795548), 'Grammar Mode — patterns & rules');
      default: return _ModeConfig(Icons.chat_bubble_outline_rounded, Color(0xFF607D8B), 'Chat');
    }
  }
}

class _ModeConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _ModeConfig(this.icon, this.color, this.label);
}

class _ModeSuggestionChips extends StatelessWidget {
  final String mode;
  final String languageName;
  final ValueChanged<String> onSuggestionTap;
  const _ModeSuggestionChips({required this.mode, required this.languageName, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = _getSuggestions();
    if (suggestions.isEmpty) return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md, vertical: PanAfricanSpacing.sm),
      child: Wrap(
        spacing: PanAfricanSpacing.sm,
        runSpacing: PanAfricanSpacing.xs,
        children: suggestions.map((s) => ActionChip(
          label: Text(s, style: TextStyle(fontSize: 12)),
          onPressed: () => onSuggestionTap(s),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        )).toList(),
      ),
    );
  }

  List<String> _getSuggestions() {
    switch (mode.toLowerCase()) {
      case 'translation': return ['How do you say hello?', 'Translate: thank you', 'What does this mean?'];
      case 'tutor': return ['Teach me verbs', 'Teach me greetings', 'Teach me numbers', 'How do sentences work?'];
      case 'conversation': return ['Hello!', 'How are you?', 'Tell me about yourself', 'What\'s the weather like?'];
      case 'vocab': case 'vocabulary': return ['Start with basics', 'Food words', 'Family words', 'Action words'];
      case 'review': return ['Quiz me!', 'Review recent words', 'Test my grammar'];
      case 'pronunciation': return ['Help me with vowels', 'Tone practice', 'Common greetings'];
      case 'grammar': return ['Sentence structure', 'Past tense', 'Questions', 'Negation'];
      default: return [];
    }
  }
}


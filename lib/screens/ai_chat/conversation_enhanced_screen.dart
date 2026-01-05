import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart' show groqChatProvider, PolieMode;
import 'package:lingafriq/services/conversation_analytics_service.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Enhanced Conversation Screen
/// Features auto-correction, topic suggestions, and real-time feedback
class ConversationEnhancedScreen extends HookConsumerWidget {
  final String language;
  final String languageName;

  const ConversationEnhancedScreen({
    Key? key,
    required this.language,
    required this.languageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final messages = useState<List<_Message>>([]);
    final isLoading = useState(false);
    final autoCorrectionEnabled = useState(true);
    final topicSuggestions = useState<List<String>>([]);
    final currentTopic = useState<String?>(null);
    final corrections = useState<Map<int, String>>({});
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatProvider = ref.read(groqChatProvider.notifier);
    final analyticsService = ref.read(conversationAnalyticsServiceProvider);
    final scrollController = useScrollController();

    // Load topic suggestions
    useEffect(() {
      _loadTopicSuggestions(analyticsService, topicSuggestions);
      return null;
    }, []);

    Future<void> sendMessage() async {
      final text = messageController.text.trim();
      if (text.isEmpty || isLoading.value) return;

      // Add user message
      final userMessage = _Message(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      );
      messages.value = [...messages.value, userMessage];
      messageController.clear();

      // Auto-correct if enabled
      if (autoCorrectionEnabled.value) {
        await _autoCorrect(text, messages.value.length - 1, corrections);
      }

      // Scroll to bottom
      _scrollToBottom(scrollController);

      // Get AI response
      isLoading.value = true;
      HapticFeedback.mediumImpact();

      try {
        await chatProvider.setMode(PolieMode.conversation);
        final response = await chatProvider.sendMessage(text);
        
        final aiMessage = _Message(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        );
        messages.value = [...messages.value, aiMessage];

        // Update topic suggestions based on conversation
        await _updateTopicSuggestions(analyticsService, text, topicSuggestions);

        // Scroll to bottom
        _scrollToBottom(scrollController);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Conversation Practice'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              autoCorrectionEnabled.value ? Icons.auto_fix_high : Icons.auto_fix_off,
            ),
            onPressed: () {
              autoCorrectionEnabled.value = !autoCorrectionEnabled.value;
              HapticFeedback.lightImpact();
            },
            tooltip: 'Auto-correction',
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
        child: SafeArea(
          child: Column(
            children: [
              // Topic Suggestions
              if (topicSuggestions.value.isNotEmpty)
                Container(
                  height: 60.h,
                  padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
                    children: topicSuggestions.value.map((topic) {
                      final isSelected = topic == currentTopic.value;
                      return Padding(
                        padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
                        child: FilterChip(
                          label: Text(topic),
                          selected: isSelected,
                          onSelected: (selected) {
                            currentTopic.value = selected ? topic : null;
                            if (selected) {
                              messageController.text = 'Let\'s talk about $topic';
                            }
                            HapticFeedback.lightImpact();
                          },
                          selectedColor: PanAfricanColors.primary,
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.1),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  itemCount: messages.value.length,
                  itemBuilder: (context, index) {
                    final message = messages.value[index];
                    final correction = corrections[index];
                    return _MessageBubble(
                      message: message,
                      correction: correction,
                      isDark: isDark,
                    )
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .slideX(begin: message.isUser ? 0.1 : -0.1);
                  },
                ),
              ),

              // Input Section
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? PanAfricanColors.surfaceContainerDark
                      : PanAfricanColors.surfaceContainerLight,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                          ),
                          filled: true,
                          fillColor: isDark ? PanAfricanColors.surfaceDark : Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: PanAfricanSpacing.md,
                            vertical: PanAfricanSpacing.sm,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: PanAfricanColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: isLoading.value
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.send, color: Colors.white),
                        onPressed: isLoading.value ? null : sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _autoCorrect(
    String text,
    int messageIndex,
    ValueNotifier<Map<int, String>> corrections,
  ) async {
    try {
      // Use AI chat provider to check grammar and get corrections
      final correctionPrompt = '''
Please check this sentence for grammar, spelling, and naturalness in $languageName.
If there are errors, provide the corrected version. If it's correct, respond with "CORRECT".
Only provide the corrected sentence, nothing else.

Sentence: "$text"
''';
      
      final correctionResponse = await chatProvider.sendMessage(correctionPrompt);
      final correctedText = correctionResponse.trim();
      
      // Only show correction if it's different and not "CORRECT"
      if (correctedText.isNotEmpty && 
          correctedText.toUpperCase() != 'CORRECT' &&
          correctedText.toLowerCase() != text.toLowerCase()) {
        corrections.value = {
          ...corrections.value,
          messageIndex: correctedText,
        };
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Auto-correction error: $e');
      // Silently fail - don't interrupt user experience
    }
  }

  Future<void> _loadTopicSuggestions(
    ConversationAnalyticsService service,
    ValueNotifier<List<String>> suggestions,
  ) async {
    try {
      final analytics = await service.loadAnalytics(languageName);
      final topTopics = analytics.getTopTopics(limit: 10);
      suggestions.value = topTopics.map((e) => e.key).toList();
    } catch (e) {
      // Default suggestions
      suggestions.value = [
        'Greetings',
        'Food & Dining',
        'Travel',
        'Shopping',
        'Weather',
        'Hobbies',
        'Family',
        'Work',
        'Health',
        'Culture',
      ];
    }
  }

  Future<void> _updateTopicSuggestions(
    ConversationAnalyticsService service,
    String message,
    ValueNotifier<List<String>> suggestions,
  ) async {
    try {
      // Analyze message and get related topics from analytics
      final analytics = await service.loadAnalytics(languageName);
      
      // Extract keywords from message
      final keywords = message.toLowerCase()
          .split(RegExp(r'[^\w]+'))
          .where((w) => w.length > 3)
          .toList();
      
      // Get topics that match keywords
      final allTopics = analytics.allTopics;
      final relatedTopics = allTopics.where((topic) {
        final topicLower = topic.toLowerCase();
        return keywords.any((keyword) => topicLower.contains(keyword));
      }).toList();
      
      // Update suggestions with related topics first, then top topics
      if (relatedTopics.isNotEmpty) {
        final topTopics = analytics.getTopTopics(limit: 5);
        final topTopicNames = topTopics.map((e) => e.key).toList();
        suggestions.value = [
          ...relatedTopics.take(3),
          ...topTopicNames.where((t) => !relatedTopics.contains(t)).take(7),
        ];
      }
    } catch (e) {
      debugPrint('Error updating topic suggestions: $e');
    }
  }

  void _scrollToBottom(ScrollController controller) {
    if (controller.hasClients) {
      Future.delayed(Duration(milliseconds: 100), () {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }
}

class _Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  final String? correction;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    this.correction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
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
                color: message.isUser
                    ? PanAfricanColors.primary
                    : (isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight),
                borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: PanAfricanTypography.bodyMedium(context)?.copyWith(
                      color: message.isUser ? Colors.white : null,
                    ),
                  ),
                  if (correction != null && message.isUser) ...[
                    SizedBox(height: PanAfricanSpacing.xs),
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.xs),
                      decoration: BoxDecoration(
                        color: PanAfricanColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(PanAfricanRadius.xs),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_fix_high,
                              size: 14.sp, color: PanAfricanColors.accent),
                          SizedBox(width: PanAfricanSpacing.xs),
                          Expanded(
                            child: Text(
                              'Suggested: $correction',
                              style: PanAfricanTypography.labelSmall(context)
                                  ?.copyWith(color: PanAfricanColors.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
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
}


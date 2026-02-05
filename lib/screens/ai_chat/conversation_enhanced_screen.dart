import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart' show groqChatProvider, PolieMode;
import 'package:lingafriq/services/conversation_analytics_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Enhanced Conversation Screen - Polie Dark Theme
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
    final chatProvider = ref.read(groqChatProvider.notifier);
    final analyticsService = ref.read(conversationAnalyticsServiceProvider);
    final scrollController = useScrollController();

    useEffect(() {
      _loadTopicSuggestions(analyticsService, topicSuggestions);
      return null;
    }, []);

    Future<void> sendMessage() async {
      final text = messageController.text.trim();
      if (text.isEmpty || isLoading.value) return;

      HapticFeedback.mediumImpact();

      final userMessage = _Message(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      );
      messages.value = [...messages.value, userMessage];
      messageController.clear();

      if (autoCorrectionEnabled.value) {
        await _autoCorrect(text, messages.value.length - 1, corrections, chatProvider);
      }

      _scrollToBottom(scrollController);

      isLoading.value = true;

      try {
        await chatProvider.setMode(PolieMode.conversation);
        final response = await chatProvider.sendMessage(text);
        
        final aiMessage = _Message(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        );
        messages.value = [...messages.value, aiMessage];

        await _updateTopicSuggestions(analyticsService, text, topicSuggestions);

        _scrollToBottom(scrollController);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: PolieColors.error,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PolieColors.primary,
              PolieColors.primaryDark,
              PolieColors.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, autoCorrectionEnabled),
              if (topicSuggestions.value.isNotEmpty)
                _buildTopicSuggestions(
                  context,
                  topicSuggestions,
                  currentTopic,
                  messageController,
                ),
              Expanded(
                child: _buildMessages(
                  context,
                  messages,
                  corrections,
                  scrollController,
                ),
              ),
              _buildInputSection(
                context,
                messageController,
                isLoading,
                sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ValueNotifier<bool> autoCorrectionEnabled,
  ) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversation Practice',
                  style: PolieTypography.h2(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
                Text(
                  languageName,
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _GlassIconButton(
            icon: autoCorrectionEnabled.value
                ? Icons.auto_fix_high_rounded
                : Icons.auto_fix_off_rounded,
            onPressed: () {
              HapticFeedback.lightImpact();
              autoCorrectionEnabled.value = !autoCorrectionEnabled.value;
            },
            isActive: autoCorrectionEnabled.value,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildTopicSuggestions(
    BuildContext context,
    ValueNotifier<List<String>> topicSuggestions,
    ValueNotifier<String?> currentTopic,
    TextEditingController messageController,
  ) {
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(vertical: PolieSpacing.xs),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md),
        children: topicSuggestions.value.map((topic) {
          final isSelected = topic == currentTopic.value;
          return Padding(
            padding: EdgeInsets.only(right: PolieSpacing.sm),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                currentTopic.value = isSelected ? null : topic;
                if (!isSelected) {
                  messageController.text = 'Let\'s talk about $topic';
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: PolieSpacing.md,
                  vertical: PolieSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PolieColors.royalAmethyst.withOpacity(0.3)
                      : PolieColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(PolieRadius.pill),
                  border: Border.all(
                    color: isSelected
                        ? PolieColors.royalAmethyst
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  topic,
                  style: PolieTypography.label(context).copyWith(
                    color: isSelected
                        ? PolieColors.royalAmethyst
                        : PolieColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildMessages(
    BuildContext context,
    ValueNotifier<List<_Message>> messages,
    ValueNotifier<Map<int, String>> corrections,
    ScrollController scrollController,
  ) {
    if (messages.value.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(PolieSpacing.xl),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    PolieColors.electricTeal.withOpacity(0.3),
                    PolieColors.royalAmethyst.withOpacity(0.2),
                  ],
                ),
                boxShadow: PolieElevation.level2(context, glowColor: PolieColors.electricTeal),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48.sp,
                color: PolieColors.textPrimary,
              ),
            ),
            SizedBox(height: PolieSpacing.lg),
            Text(
              'Start a conversation',
              style: PolieTypography.h2(context).copyWith(
                color: PolieColors.textPrimary,
              ),
            ),
            SizedBox(height: PolieSpacing.sm),
            Text(
              'Pick a topic above or type your message',
              style: PolieTypography.body(context).copyWith(
                color: PolieColors.textSecondary,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.all(PolieSpacing.md),
      itemCount: messages.value.length,
      itemBuilder: (context, index) {
        final message = messages.value[index];
        final correction = corrections.value[index];
        return _MessageBubble(
          message: message,
          correction: correction,
        ).animate().fadeIn(duration: 200.ms).slideX(
              begin: message.isUser ? 0.1 : -0.1,
            );
      },
    );
  }

  Widget _buildInputSection(
    BuildContext context,
    TextEditingController messageController,
    ValueNotifier<bool> isLoading,
    VoidCallback sendMessage,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(PolieSpacing.md),
          decoration: BoxDecoration(
            color: PolieColors.surfaceGlass,
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: PolieColors.surfaceGlassDark,
                    borderRadius: BorderRadius.circular(PolieRadius.pill),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: messageController,
                    enabled: !isLoading.value,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => sendMessage(),
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: PolieTypography.body(context).copyWith(
                        color: PolieColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: PolieSpacing.lg,
                        vertical: PolieSpacing.sm,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: PolieSpacing.sm),
              GestureDetector(
                onTap: isLoading.value ? null : sendMessage,
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [PolieColors.electricTeal, PolieColors.royalAmethyst],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: PolieElevation.level2(context, glowColor: PolieColors.electricTeal),
                  ),
                  child: isLoading.value
                      ? Padding(
                          padding: EdgeInsets.all(12.w),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.send_rounded, color: Colors.white, size: 22.sp),
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
    dynamic chatProvider,
  ) async {
    try {
      final correctionPrompt = '''
Please check this sentence for grammar, spelling, and naturalness in $languageName.
If there are errors, provide the corrected version. If it's correct, respond with "CORRECT".
Only provide the corrected sentence, nothing else.

Sentence: "$text"
''';
      
      final correctionResponse = await chatProvider.sendMessage(correctionPrompt);
      final correctedText = correctionResponse.trim();
      
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
      final analytics = await service.loadAnalytics(languageName);
      
      final keywords = message.toLowerCase()
          .split(RegExp(r'[^\w]+'))
          .where((w) => w.length > 3)
          .toList();
      
      final allTopics = analytics.allTopics;
      final relatedTopics = allTopics.where((topic) {
        final topicLower = topic.toLowerCase();
        return keywords.any((keyword) => topicLower.contains(keyword));
      }).toList();
      
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

  const _MessageBubble({
    required this.message,
    this.correction,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = message.isUser ? PolieColors.goldEmber : PolieColors.electricTeal;

    return Padding(
      padding: EdgeInsets.only(bottom: PolieSpacing.md),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [PolieColors.electricTeal, PolieColors.royalAmethyst],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_rounded, size: 18.sp, color: Colors.white),
            ),
            SizedBox(width: PolieSpacing.sm),
          ],
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(PolieRadius.lg),
                topRight: Radius.circular(PolieRadius.lg),
                bottomLeft: Radius.circular(message.isUser ? PolieRadius.lg : PolieRadius.sm),
                bottomRight: Radius.circular(message.isUser ? PolieRadius.sm : PolieRadius.lg),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PolieSpacing.md,
                    vertical: PolieSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? PolieColors.goldEmber.withOpacity(0.2)
                        : PolieColors.surfaceGlass,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(PolieRadius.lg),
                      topRight: Radius.circular(PolieRadius.lg),
                      bottomLeft: Radius.circular(message.isUser ? PolieRadius.lg : PolieRadius.sm),
                      bottomRight: Radius.circular(message.isUser ? PolieRadius.sm : PolieRadius.lg),
                    ),
                    border: Border.all(
                      color: accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: PolieTypography.body(context).copyWith(
                          color: PolieColors.textPrimary,
                        ),
                      ),
                      if (correction != null && message.isUser) ...[
                        SizedBox(height: PolieSpacing.sm),
                        Container(
                          padding: EdgeInsets.all(PolieSpacing.sm),
                          decoration: BoxDecoration(
                            color: PolieColors.electricTeal.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(PolieRadius.sm),
                            border: Border.all(
                              color: PolieColors.electricTeal.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_fix_high_rounded,
                                size: 14.sp,
                                color: PolieColors.electricTeal,
                              ),
                              SizedBox(width: PolieSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Suggested: $correction',
                                  style: PolieTypography.bodySmall(context).copyWith(
                                    color: PolieColors.electricTeal,
                                  ),
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
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: PolieSpacing.sm),
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [PolieColors.goldEmber, PolieColors.goldEmberLight],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded, size: 18.sp, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: isActive
              ? PolieColors.electricTeal.withOpacity(0.3)
              : PolieColors.surfaceGlass,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? PolieColors.electricTeal
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? PolieColors.electricTeal : PolieColors.textPrimary,
          size: 22.sp,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    HapticFeedback.lightImpact();
    _messageController.clear();
    _focusNode.unfocus();

    try {
      final notifier = ref.read(groqChatProvider.notifier);
      await notifier.sendMessage(message);
      if (mounted) _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _clearChat() async {
    HapticFeedback.lightImpact();
    final result = await ref.read(dialogProvider('')).showPlatformDialogue(
          title: 'Clear Chat',
          content: const Text('Are you sure you want to clear all messages?'),
          action1Text: 'Clear',
          action2Text: 'Cancel',
          action1OnTap: true,
          action2OnTap: false,
        );

    if (result == true) {
      await ref.read(groqChatProvider.notifier).clearChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatNotifier = ref.read(groqChatProvider.notifier);
    final chatState = ref.watch(groqChatProvider);

    return Scaffold(
      drawer: const AppDrawer(),
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
        child: Column(
          children: [
            _buildHeader(context, chatNotifier),
            Expanded(
              child: chatNotifier.messages.isEmpty
                  ? _buildEmptyState(context)
                  : _buildChatMessages(context, chatNotifier),
            ),
            _buildMessageInput(context, chatNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GroqChatProvider chatNotifier) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + PolieSpacing.sm,
        left: PolieSpacing.md,
        right: PolieSpacing.md,
        bottom: PolieSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PolieColors.primary,
            PolieColors.primary.withOpacity(0.8),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: PolieColors.royalAmethyst.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu_rounded, color: PolieColors.textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Language Tutor',
                  style: PolieTypography.h2(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
                SizedBox(height: PolieSpacing.xs),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: PolieColors.electricTeal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: PolieColors.electricTeal.withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: PolieSpacing.xs),
                    Text(
                      'Polie is online',
                      style: PolieTypography.bodySmall(context).copyWith(
                        color: PolieColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (chatNotifier.hasMessages)
            _GlassIconButton(
              icon: Icons.delete_outline_rounded,
              onPressed: _clearChat,
              tooltip: 'Clear chat',
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(PolieSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PolieGlassCard(
              hasGlow: true,
              glowColor: PolieColors.royalAmethyst,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(PolieSpacing.xl),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          PolieColors.royalAmethyst.withOpacity(0.35),
                          PolieColors.electricTeal.withOpacity(0.25),
                        ],
                      ),
                      boxShadow: PolieElevation.level2(
                        context,
                        glowColor: PolieColors.royalAmethyst,
                      ),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64.sp,
                      color: PolieColors.textPrimary,
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
                  SizedBox(height: PolieSpacing.lg),
                  Text(
                    'Start a conversation!',
                    style: PolieTypography.h1(context).copyWith(
                      color: PolieColors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  SizedBox(height: PolieSpacing.sm),
                  Text(
                    'I\'m here to help you learn. Chat with Polie to practice African languages, translate phrases, and explore grammar.',
                    textAlign: TextAlign.center,
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  SizedBox(height: PolieSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeaturePill(
                        context,
                        icon: Icons.translate_rounded,
                        label: 'Translate',
                      ),
                      SizedBox(width: PolieSpacing.sm),
                      _buildFeaturePill(
                        context,
                        icon: Icons.theater_comedy_rounded,
                        label: 'Roleplay',
                      ),
                      SizedBox(width: PolieSpacing.sm),
                      _buildFeaturePill(
                        context,
                        icon: Icons.school_rounded,
                        label: 'Tutor',
                      ),
                    ],
                  ),
                  SizedBox(height: PolieSpacing.lg),
                  PoliePrimaryButton(
                    label: 'Try a greeting',
                    icon: Icons.auto_awesome,
                    onPressed: () {
                      _messageController.text = 'Teach me a warm greeting in Swahili';
                      _sendMessage();
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: PolieSpacing.xl),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Suggested prompts',
                style: PolieTypography.label(context).copyWith(
                  color: PolieColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: PolieSpacing.sm),
            Wrap(
              spacing: PolieSpacing.sm,
              runSpacing: PolieSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(context, 'How do I say hello in Swahili?', PolieColors.electricTeal),
                _buildSuggestionChip(context, 'Translate "thank you" to Yoruba', PolieColors.goldEmber),
                _buildSuggestionChip(context, 'Practice Pidgin English', PolieColors.royalAmethyst),
                _buildSuggestionChip(context, 'Explain Igbo grammar', PolieColors.electricTealLight),
              ],
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String text, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: PolieSpacing.md,
          vertical: PolieSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
          borderRadius: BorderRadius.circular(PolieRadius.pill),
          border: Border.all(
            color: accentColor.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Text(
          text,
          style: PolieTypography.label(context).copyWith(
            color: accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PolieSpacing.sm,
        vertical: PolieSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PolieRadius.pill),
        border: Border.all(
          color: PolieColors.royalAmethyst.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: PolieColors.royalAmethyst),
          SizedBox(width: PolieSpacing.xxs),
          Text(
            label,
            style: PolieTypography.label(context).copyWith(
              color: PolieColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages(BuildContext context, GroqChatProvider chatProvider) {
    final isTyping = chatProvider.isBusy;
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: PolieSpacing.md,
        vertical: PolieSpacing.sm,
      ),
      itemCount: chatProvider.messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= chatProvider.messages.length) {
          return _buildTypingIndicator(context);
        }

        final message = chatProvider.messages[index];
        final previousRole =
            index > 0 ? chatProvider.messages[index - 1].role : null;
        final showLabel = previousRole == null || previousRole != message.role;
        return _buildMessageBubble(context, message, index, showLabel);
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage message,
    int index,
    bool showLabel,
  ) {
    final isUser = message.role == 'user';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: PolieSpacing.xs),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(
              icon: Icons.smart_toy_rounded,
              gradient: [PolieColors.royalAmethyst, PolieColors.electricTeal],
            ),
            SizedBox(width: PolieSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showLabel) ...[
                  Text(
                    isUser ? 'You' : 'Polie',
                    style: PolieTypography.label(context).copyWith(
                      color: PolieColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.xxs),
                ],
                PolieChatBubble(
                  text: message.content,
                  role: isUser
                      ? PolieChatBubbleRole.user
                      : PolieChatBubbleRole.assistant,
                ),
                SizedBox(height: PolieSpacing.xxs),
                Text(
                  _formatTime(message.timestamp),
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary.withOpacity(0.8),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: PolieSpacing.sm),
            _buildAvatar(
              icon: Icons.person_rounded,
              gradient: [PolieColors.goldEmber, PolieColors.goldEmberLight],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: isUser ? 0.1 : -0.1);
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: PolieSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(
            icon: Icons.smart_toy_rounded,
            gradient: [PolieColors.royalAmethyst, PolieColors.electricTeal],
          ),
          SizedBox(width: PolieSpacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: PolieSpacing.md,
              vertical: PolieSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? PolieColors.surfaceContainer
                  : PolieColors.surfaceContainerLight,
              borderRadius: BorderRadius.circular(PolieRadius.md),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                _buildDot(delay: 0.ms),
                SizedBox(width: PolieSpacing.xs),
                _buildDot(delay: 150.ms),
                SizedBox(width: PolieSpacing.xs),
                _buildDot(delay: 300.ms),
              ],
            ),
          ).animate().fadeIn(duration: 150.ms),
        ],
      ),
    );
  }

  Widget _buildDot({required Duration delay}) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: PolieColors.electricTeal,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(delay: delay, duration: 300.ms)
        .fadeOut(delay: delay + 300.ms, duration: 300.ms);
  }

  Widget _buildAvatar({required IconData icon, required List<Color> gradient}) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 18.sp),
    );
  }

  Widget _buildMessageInput(BuildContext context, GroqChatProvider chatProvider) {
    final isLoading = chatProvider.isBusy;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
          padding: EdgeInsets.only(
            left: PolieSpacing.md,
            right: PolieSpacing.md,
            top: PolieSpacing.sm,
            bottom: MediaQuery.of(context).padding.bottom + PolieSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: PolieInputField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  enabled: !isLoading,
                  hintText: 'Type your message...',
                  maxLines: 4,
                  maxLength: 2000,
                  onSubmitted: (_) => _sendMessage(),
                  prefixIcon: Icons.auto_awesome,
                ),
              ),
              SizedBox(width: PolieSpacing.sm),
              _buildSendButton(isLoading),
            ],
          ),
    );
  }

  Widget _buildSendButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _sendMessage,
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [PolieColors.royalAmethyst, PolieColors.electricTeal],
          ),
          shape: BoxShape.circle,
          boxShadow: PolieElevation.level2(context, glowColor: PolieColors.royalAmethyst),
        ),
        child: isLoading
            ? Padding(
                padding: EdgeInsets.all(12.w),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                ),
              )
            : Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 22.sp),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Glass-style icon button for header actions
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? PolieColors.surfaceContainer
                : PolieColors.surfaceContainerLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20.sp,
          ),
        ),
      ),
    );
  }
}

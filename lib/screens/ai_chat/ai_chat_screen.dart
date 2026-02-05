import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
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
                Text(
                  'Practice African languages',
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
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
            // Glowing icon container
            Container(
              padding: EdgeInsets.all(PolieSpacing.xl),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    PolieColors.royalAmethyst.withOpacity(0.3),
                    PolieColors.electricTeal.withOpacity(0.2),
                  ],
                ),
                boxShadow: PolieElevation.level2(context, glowColor: PolieColors.royalAmethyst),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64.sp,
                color: PolieColors.textPrimary,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
            SizedBox(height: PolieSpacing.xl),
            Text(
              'Start Learning',
              style: PolieTypography.h1(context).copyWith(
                color: PolieColors.textPrimary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            SizedBox(height: PolieSpacing.sm),
            Text(
              'Chat with our AI tutor to practice African languages.\nAsk questions, have conversations, or get help with translations.',
              textAlign: TextAlign.center,
              style: PolieTypography.body(context).copyWith(
                color: PolieColors.textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            SizedBox(height: PolieSpacing.xl),
            Wrap(
              spacing: PolieSpacing.sm,
              runSpacing: PolieSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('How do I say hello in Swahili?', PolieColors.electricTeal),
                _buildSuggestionChip('Translate "thank you" to Yoruba', PolieColors.goldEmber),
                _buildSuggestionChip('Practice Pidgin English', PolieColors.royalAmethyst),
                _buildSuggestionChip('Explain Igbo grammar', PolieColors.electricTealLight),
              ],
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, Color accentColor) {
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
          color: PolieColors.surfaceGlass,
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

  Widget _buildChatMessages(BuildContext context, GroqChatProvider chatProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: PolieSpacing.md,
        vertical: PolieSpacing.sm,
      ),
      itemCount: chatProvider.messages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.messages[index];
        return _buildMessageBubble(context, message, index);
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message, int index) {
    final isUser = message.role == 'user';
    final accentColor = isUser ? PolieColors.goldEmber : PolieColors.royalAmethyst;

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
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(PolieRadius.lg),
                topRight: Radius.circular(PolieRadius.lg),
                bottomLeft: Radius.circular(isUser ? PolieRadius.lg : PolieRadius.sm),
                bottomRight: Radius.circular(isUser ? PolieRadius.sm : PolieRadius.lg),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PolieSpacing.md,
                    vertical: PolieSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? PolieColors.goldEmber.withOpacity(0.2)
                        : PolieColors.surfaceGlass,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(PolieRadius.lg),
                      topRight: Radius.circular(PolieRadius.lg),
                      bottomLeft: Radius.circular(isUser ? PolieRadius.lg : PolieRadius.sm),
                      bottomRight: Radius.circular(isUser ? PolieRadius.sm : PolieRadius.lg),
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
                        message.content,
                        style: PolieTypography.body(context).copyWith(
                          color: PolieColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: PolieSpacing.xs),
                      Text(
                        _formatTime(message.timestamp),
                        style: PolieTypography.bodySmall(context).copyWith(
                          color: PolieColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      child: Icon(icon, color: Colors.white, size: 18.sp),
    );
  }

  Widget _buildMessageInput(BuildContext context, GroqChatProvider chatProvider) {
    final isLoading = chatProvider.isBusy;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: PolieSpacing.md,
            right: PolieSpacing.md,
            top: PolieSpacing.sm,
            bottom: MediaQuery.of(context).padding.bottom + PolieSpacing.sm,
          ),
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
                    controller: _messageController,
                    focusNode: _focusNode,
                    enabled: !isLoading,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
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
              _buildSendButton(isLoading),
            ],
          ),
        ),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.send_rounded, color: Colors.white, size: 22.sp),
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
            color: PolieColors.surfaceGlass,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: PolieColors.textPrimary,
            size: 20.sp,
          ),
        ),
      ),
    );
  }
}

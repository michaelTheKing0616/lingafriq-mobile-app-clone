import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  String _streamingText = '';
  bool _isStreaming = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    // Interrupt AI if streaming
    if (_isStreaming) {
      ref.read(groqChatProvider.notifier).interruptAI();
    }
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

    // Interrupt AI if currently streaming
    if (_isStreaming) {
      ref.read(groqChatProvider.notifier).interruptAI();
    }

    _messageController.clear();
    _focusNode.unfocus();

    setState(() {
      _streamingText = '';
      _isStreaming = true;
    });

    try {
      final provider = ref.read(groqChatProvider.notifier);
      await for (final chunk in provider.sendMessageStream(message)) {
        if (mounted) {
          setState(() {
            _streamingText += chunk;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(dialogProvider('')).showPlatformDialogue(
              title: 'Error',
              content: Text(e.toString().replaceAll('Exception: ', '')),
              action1Text: 'OK',
            );
      }
    } finally {
      if (mounted) {
        setState(() {
          _streamingText = '';
          _isStreaming = false;
        });
      }
    }
  }

  Future<void> _clearChat() async {
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
      setState(() {
        _streamingText = '';
        _isStreaming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatNotifier = ref.read(groqChatProvider.notifier);
    final chatState = ref.watch(groqChatProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          TopGradientBox(
            borderRadius: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                    ),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) => Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.menu_rounded, color: Colors.white),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'LingAfriq Polyglot - AI Language Chat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (chatNotifier.hasMessages)
                  Padding(
                    padding: EdgeInsets.only(
                      top: 8,
                      right: 8,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: _clearChat,
                      tooltip: 'Clear chat',
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: chatNotifier.messages.isEmpty
                ? _buildEmptyState(context)
                : _buildChatMessages(context, chatNotifier),
          ),
          _buildMessageInput(context, chatNotifier),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.2),
                    AppColors.accentGold.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 80.sp,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start Learning',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: context.adaptive,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chat with LingAfriq Polyglot, your AI language tutor.\nPractice African languages, ask questions, have conversations, or get help with translations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: context.adaptive54,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('How do I say hello in Swahili?'),
                _buildSuggestionChip('Translate "thank you" to Yoruba'),
                _buildSuggestionChip('Practice Pidgin English conversation'),
                _buildSuggestionChip('Explain Igbo grammar'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
      backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
      labelStyle: TextStyle(
        color: AppColors.primaryGreen,
        fontSize: 14.sp,
      ),
    );
  }

  Widget _buildChatMessages(BuildContext context, GroqChatProvider chatProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chatProvider.messages.length + (_isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatProvider.messages.length && _isStreaming) {
          // Show streaming message
          return _buildStreamingBubble(context);
        }
        final message = chatProvider.messages[index];
        return _buildMessageBubble(context, message);
      },
    );
  }

  Widget _buildStreamingBubble(BuildContext context) {
    final isDark = context.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen,
                  AppColors.accentGold,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _streamingText.isEmpty ? '...' : _streamingText,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15.sp,
                      height: 1.4,
                    ),
                  ),
                  if (_streamingText.isNotEmpty)
                    const SizedBox(height: 4),
                  if (_streamingText.isNotEmpty)
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI is typing...',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUser = message.role == 'user';
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.accentGold,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryGreen
                    : (isDark
                        ? Colors.grey[800]
                        : Colors.grey[100]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                      fontSize: 15.sp,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser
                          ? Colors.white70
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: AppColors.accentGold,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, GroqChatProvider chatProvider) {
    final isDark = context.isDarkMode;
    final isLoading = chatProvider.isBusy || _isStreaming;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 8 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  enabled: !isLoading,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  onChanged: (_) {
                    // Interrupt AI when user starts typing
                    if (_isStreaming) {
                      ref.read(groqChatProvider.notifier).interruptAI();
                      setState(() {
                        _isStreaming = false;
                        _streamingText = '';
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                      color: context.adaptive54,
                      fontSize: 15.sp,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: AppColors.primaryGreen,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    color: context.adaptive,
                    fontSize: 15.sp,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.accentGold,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: isLoading ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
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


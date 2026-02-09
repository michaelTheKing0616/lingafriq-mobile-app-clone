import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/chat_socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart' hide ErrorBoundary;
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/services/polie_mention_handler.dart';
import 'package:lingafriq/avatars/avatars.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GlobalChatScreen extends ConsumerStatefulWidget {
  final String? language;
  
  const GlobalChatScreen({Key? key, this.language}) : super(key: key);

  @override
  ConsumerState<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends ConsumerState<GlobalChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedRoom = 'general';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocket();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    ref.read(socketProvider.notifier).leaveRoom(_selectedRoom);
    super.dispose();
  }

  void _initializeSocket() {
    final user = ref.read(userProvider);
    if (user != null) {
      safeAsyncSilent(
        operation: () async {
          final socket = ref.read(socketProvider.notifier);
          socket.connect(
            user.id.toString(),
            user.username,
          );
          socket.joinRoom(_selectedRoom);
          socket.setActiveRoom(_selectedRoom);
        },
        errorContext: 'initializeSocket',
        onError: (e) {
          if (mounted) {
            ErrorHandler.showError(context, e);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'Unable to load global chat. Please check your connection and try again.',
      onRetry: () {
        setState(() {});
        _initializeSocket();
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    ref.watch(socketProvider);
    final socketNotifier = ref.read(socketProvider.notifier);
    final messages = socketNotifier.messages;
    final onlineUsers = socketNotifier.onlineUsers;
    final isConnected = socketNotifier.isConnected;
    final user = ref.watch(userProvider);
    final isDark = context.isDarkMode;

    // Ensure socket is initialized if user is available
    if (user != null && !isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeSocket();
      });
    }

    return Scaffold(
      backgroundColor: isDark 
          ? PanAfricanColors.surfaceDark 
          : PanAfricanColors.surfaceLight,
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: BoxDecoration(
              gradient: PanAfricanGradients.primaryHeader,
              boxShadow: PanAfricanShadows.md,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.xs),
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        final scaffoldState = Scaffold.of(context);
                        scaffoldState.openDrawer();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community Chat',
                            style: PanAfricanTypography.titleMedium(context)
                                .copyWith(color: Colors.white),
                          ),
                          if (isConnected)
                            Text(
                              '${onlineUsers.length} learners online',
                              style: PanAfricanTypography.labelSmall(context)
                                  .copyWith(color: Colors.white.withOpacity(0.8)),
                            ),
                        ],
                      ),
                      ),
                    if (!isConnected)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.sm,
                          vertical: PanAfricanSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.25),
                          borderRadius: PanAfricanRadius.roundBR,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(width: PanAfricanSpacing.xxs),
                            Text(
                              'Connecting...',
                              style: PanAfricanTypography.labelSmall(context)
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    if (isConnected)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: PanAfricanSpacing.sm,
                        vertical: PanAfricanSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: PanAfricanRadius.roundBR,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_rounded, color: Colors.white, size: 16),
                          SizedBox(width: PanAfricanSpacing.xxs),
                          Text(
                            '${onlineUsers.length}',
                            style: PanAfricanTypography.labelSmall(context)
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Messages Area
          Expanded(
            child: Container(
              color: isDark 
                  ? PanAfricanColors.surfaceDark 
                  : PanAfricanColors.surfaceLight,
              child: Column(
                children: [
                  // Room selector
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: PanAfricanSpacing.md,
                      vertical: PanAfricanSpacing.xs,
                    ),
                    color: isDark 
                        ? PanAfricanColors.surfaceContainerDark 
                        : PanAfricanColors.surfaceContainerLight,
                    child: Row(
                      children: [
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.language,
                            color: isDark ? Colors.white : PanAfricanColors.textPrimary,
                          ),
                          onSelected: (room) {
                            if (_selectedRoom == room) return;
                            HapticFeedback.selectionClick();
                            final socket = ref.read(socketProvider.notifier);
                            socket.leaveRoom(_selectedRoom);
                            setState(() {
                              _selectedRoom = room;
                            });
                            socket.joinRoom(room);
                            socket.setActiveRoom(room);
                            _scrollToBottom();
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'general', child: Text('General')),
                            const PopupMenuItem(value: 'yoruba', child: Text('Yoruba')),
                            const PopupMenuItem(value: 'hausa', child: Text('Hausa')),
                            const PopupMenuItem(value: 'swahili', child: Text('Swahili')),
                            const PopupMenuItem(value: 'igbo', child: Text('Igbo')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Online Users Bar
                  if (isConnected && onlineUsers.isNotEmpty)
                    Container(
                      height: 60.w,
                      color: isDark 
                          ? PanAfricanColors.surfaceContainerDark 
                          : PanAfricanColors.surfaceContainerLight,
                      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
                      child: OptimizedListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: onlineUsers.length,
                        itemBuilder: (context, index) {
                          final onlineUser = onlineUsers[index];
                          return Container(
                            margin: EdgeInsets.only(right: PanAfricanSpacing.sm),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LingAfriqAvatar.fromInitials(
                                  username: onlineUser['username'] as String? ?? 'U',
                                  size: 36.w,
                                ),
                                SizedBox(height: PanAfricanSpacing.xxs),
                                Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    color: PanAfricanColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // Messages
                  Expanded(
                    child: user == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_off,
                                  size: 64.w,
                                  color: PanAfricanColors.neutralMedium,
                                ),
                                SizedBox(height: PanAfricanSpacing.md),
                                Text(
                                  'Please log in to use chat',
                                  style: PanAfricanTypography.bodyLarge(context)
                                      .copyWith(color: PanAfricanColors.neutralMedium),
                                ),
                              ],
                            ),
                          )
                        : messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 64.w,
                                      color: PanAfricanColors.neutralMedium,
                                    ),
                                    SizedBox(height: PanAfricanSpacing.md),
                                    Text(
                                      isConnected
                                          ? 'No messages yet. Start the conversation!'
                                          : 'Connecting...',
                                      style: PanAfricanTypography.bodyLarge(context)
                                          .copyWith(color: PanAfricanColors.neutralMedium),
                                    ),
                                  ],
                                ),
                              )
                            : OptimizedListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.all(PanAfricanSpacing.md),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  final isMe = message['userId'] == user.id.toString();
                                  return _buildMessageBubble(context, message, isMe, isDark);
                                },
                              ),
                  ),
                  
                  // Input Area
                  Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? PanAfricanColors.surfaceContainerDark
                          : PanAfricanColors.surfaceContainerLight,
                      boxShadow: PanAfricanShadows.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: PanAfricanRadius.lgBR,
                                borderSide: BorderSide(
                                  color: isDark
                                      ? PanAfricanColors.borderDark
                                      : PanAfricanColors.borderLight,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: PanAfricanRadius.lgBR,
                                borderSide: BorderSide(
                                  color: isDark
                                      ? PanAfricanColors.borderDark
                                      : PanAfricanColors.borderLight,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: PanAfricanRadius.lgBR,
                                borderSide: BorderSide(
                                  color: PanAfricanColors.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? PanAfricanColors.surfaceDark
                                  : PanAfricanColors.surfaceLight,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: PanAfricanSpacing.md,
                                vertical: PanAfricanSpacing.sm,
                              ),
                            ),
                            style: PanAfricanTypography.bodyMedium(context),
                            maxLines: null,
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            gradient: PanAfricanGradients.primaryHeader,
                            shape: BoxShape.circle,
                            boxShadow: PanAfricanShadows.sm,
                          ),
                          child: IconButton(
                            onPressed: user != null && isConnected && _messageController.text.isNotEmpty
                                ? () async {
                                    HapticFeedback.lightImpact();
                                    final text = _messageController.text.trim();
                                    if (text.isEmpty) return;
                                    
                                    final socket = ref.read(socketProvider.notifier);
                                    final polieHandler = ref.read(polieMentionHandlerProvider);
                                    
                                    try {
                                      // Send user's message
                                      socket.sendMessage(
                                        _selectedRoom,
                                        text,
                                        user.id.toString(),
                                        user.username,
                                      );
                                      _messageController.clear();
                                      _scrollToBottom();
                                      
                                      // Check for @Polie mention
                                      if (polieHandler.hasMention(text)) {
                                        final onboarding = ref.read(onboardingProvider);
                                        final userLanguage = onboarding.selectedLanguage ?? 'english';
                                        
                                        // Show typing indicator
                                        socket.sendMessage(
                                          _selectedRoom,
                                          '🤖 Polie is thinking...',
                                          'polie_bot',
                                          'Polie',
                                        );
                                        _scrollToBottom();
                                        
                                        // Process mention
                                        final result = await polieHandler.processMessage(
                                          message: text,
                                          userLanguage: userLanguage,
                                        );
                                        
                                        // Send Polie's response
                                        final formattedResponse = polieHandler.formatResponseForChat(result);
                                        if (formattedResponse.isNotEmpty) {
                                          socket.sendMessage(
                                            _selectedRoom,
                                            formattedResponse,
                                            'polie_bot',
                                            'Polie',
                                          );
                                        }
                                        _scrollToBottom();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ErrorHandler.showError(context, e);
                                      }
                                    }
                                  }
                                : null,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> message,
    bool isMe,
    bool isDark,
  ) {
    final username = message['username'] as String? ?? 'Anonymous';
    
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users
          if (!isMe) ...[
            LingAfriqAvatar.fromInitials(username: username, size: 28),
            SizedBox(width: PanAfricanSpacing.xs),
          ],
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.md,
                vertical: PanAfricanSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? PanAfricanColors.primary
                    : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                borderRadius: PanAfricanRadius.lgBR.copyWith(
                  bottomRight: isMe ? const Radius.circular(4) : null,
                  bottomLeft: !isMe ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      username,
                      style: PanAfricanTypography.labelMedium(context).copyWith(
                        color: PanAfricanColors.primary,
                      ),
                    ),
                  if (!isMe) SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    message['message'] ?? '',
                    style: PanAfricanTypography.bodyMedium(context).copyWith(
                      color: isMe ? Colors.white : null,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    _formatTime(message['timestamp']),
                    style: PanAfricanTypography.labelSmall(context).copyWith(
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : PanAfricanColors.neutralMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Self avatar
          if (isMe) ...[
            SizedBox(width: PanAfricanSpacing.xs),
            const LingAfriqAvatar(size: 28, showBorder: false),
          ],
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
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
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/private_chat_contact.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/chat_socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/services/polie_mention_handler.dart';
import 'package:lingafriq/avatars/avatars.dart';

class PrivateChatScreen extends ConsumerStatefulWidget {
  final PrivateChatContact contact;

  const PrivateChatScreen({super.key, required this.contact});

  @override
  ConsumerState<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends ConsumerState<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String _roomId;
  bool _socketInitialized = false;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(userProvider);
    _roomId = currentUser == null
        ? ''
        : _buildRoomId(currentUser.id, widget.contact.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocket();
    });
  }

  @override
  void dispose() {
    final socket = ref.read(socketProvider.notifier);
    if (_roomId.isNotEmpty) {
      socket.leaveRoom(_roomId);
      socket.setActiveRoom('general');
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeSocket() {
    if (_socketInitialized || _roomId.isEmpty) return;
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;
    final socket = ref.read(socketProvider.notifier);
    if (!socket.isConnected) {
      socket.connect(
        currentUser.id.toString(),
        currentUser.username,
        globalId: currentUser.global_id,
      );
    }
    socket.joinRoom(_roomId);
    socket.setActiveRoom(_roomId);
    _socketInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Private Chat')),
        body: const Center(
          child: Text('Please sign in to chat with other learners.'),
        ),
      );
    }

    ref.watch(socketProvider);
    final socket = ref.read(socketProvider.notifier);
    final messages = _roomId.isEmpty
        ? const <Map<String, dynamic>>[]
        : socket.messagesForRoom(_roomId);
    final isConnected = socket.isConnected;
    final isPartnerOnline = socket.onlineUsers.any(
      (user) => user['userId']?.toString() == widget.contact.id.toString(),
    );

    final isDark = context.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark 
          ? PanAfricanColors.surfaceDark 
          : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            LingAfriqAvatar.fromInitials(
              username: widget.contact.username.isNotEmpty 
                  ? widget.contact.username 
                  : '?',
              size: 40.w,
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contact.username,
                  style: PanAfricanTypography.titleSmall(context),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: isPartnerOnline 
                          ? PanAfricanColors.success 
                          : PanAfricanColors.neutralMedium,
                    ),
                    SizedBox(width: PanAfricanSpacing.xxs),
                    Text(
                      isPartnerOnline ? 'Online' : 'Offline',
                      style: PanAfricanTypography.labelSmall(context).copyWith(
                        color: isPartnerOnline 
                            ? PanAfricanColors.success 
                            : PanAfricanColors.neutralMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
            child: Icon(Icons.lock_outline, size: 20, color: PanAfricanColors.neutralMedium),
          ),
        ],
      ),
      body: Column(
        children: [
          // Encryption notice
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md,
              vertical: PanAfricanSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: PanAfricanColors.primary.withOpacity(0.08),
              border: Border(
                bottom: BorderSide(
                  color: PanAfricanColors.primary.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, color: PanAfricanColors.primary, size: 20),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: Text(
                    'Messages are end-to-end encrypted. Only you and ${widget.contact.username} can read them.',
                    style: PanAfricanTypography.labelSmall(context).copyWith(
                      color: PanAfricanColors.primary.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: messages.isEmpty
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
                          'No messages yet',
                          style: PanAfricanTypography.bodyLarge(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.xs),
                        Text(
                          'Say hello to ${widget.contact.username} 👋',
                          style: PanAfricanTypography.bodySmall(context)
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
                      final isMe =
                          message['userId'] == currentUser.id.toString();
                      return _buildMessageBubble(message, isMe, isDark);
                    },
                  ),
          ),
          _buildInput(isConnected && _roomId.isNotEmpty, currentUser, isDark),
        ],
      ),
    );
  }

  Widget _buildInput(bool canSend, ProfileModel currentUser, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
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
              enabled: canSend,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: canSend
                    ? 'Message ${widget.contact.username}...'
                    : 'Connecting...',
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
              onSubmitted: canSend ? (_) {
                HapticFeedback.lightImpact();
                _sendMessage(currentUser);
              } : null,
            ),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          IconButton.filled(
            onPressed: canSend
                ? () {
                    HapticFeedback.lightImpact();
                    _sendMessage(currentUser);
                  }
                : null,
            style: IconButton.styleFrom(
              backgroundColor: PanAfricanColors.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isMe, bool isDark) {
    final timestamp = message['timestamp']?.toString();
    final username = message['username'] as String? ?? widget.contact.username;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            LingAfriqAvatar.fromInitials(username: username, size: 26),
            SizedBox(width: PanAfricanSpacing.xs),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.md,
                vertical: PanAfricanSpacing.sm,
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'] ?? '',
                    style: PanAfricanTypography.bodyMedium(context).copyWith(
                      color: isMe ? colorScheme.onPrimary : null,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(timestamp),
                        style: PanAfricanTypography.labelSmall(context).copyWith(
                          color: isMe
                              ? colorScheme.onPrimary.withOpacity(0.7)
                              : PanAfricanColors.neutralMedium,
                        ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: PanAfricanSpacing.xxs),
                        Icon(
                          message['failed'] == true
                              ? Icons.error_outline
                              : (message['read'] == true
                                  ? Icons.done_all
                                  : Icons.done),
                          size: 14,
                          color: message['failed'] == true
                              ? PanAfricanColors.error
                              : colorScheme.onPrimary.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: PanAfricanSpacing.xs),
            const LingAfriqAvatar(size: 26, showBorder: false),
          ],
        ],
      ),
    );
  }

  void _sendMessage(ProfileModel currentUser) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _roomId.isEmpty) return;
    
    final socket = ref.read(socketProvider.notifier);
    final polieHandler = ref.read(polieMentionHandlerProvider);
    
    try {
      // Send the user's message first
      socket.sendMessage(
        _roomId,
        text,
        currentUser.id.toString(),
        currentUser.username,
        null,
        currentUser.global_id,
      );
      _messageController.clear();
      _scrollToBottom();
      
      // Check for @Polie mention and process
      if (polieHandler.hasMention(text)) {
        // Get user's learning language
        final onboarding = ref.read(onboardingProvider);
        final userLanguage = onboarding.selectedLanguage ?? 'english';
        
        // Show typing indicator
        socket.sendMessage(
          _roomId,
          '🤖 Polie is thinking...',
          'polie_bot',
          'Polie',
            null,
            'polie_bot',
        );
        
        // Process the mention
        final result = await polieHandler.processMessage(
          message: text,
          userLanguage: userLanguage,
        );
        
        // Send Polie's response
        final formattedResponse = polieHandler.formatResponseForChat(result);
        if (formattedResponse.isNotEmpty) {
          socket.sendMessage(
            _roomId,
            formattedResponse,
            'polie_bot',
            'Polie',
            null,
            'polie_bot',
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  String _buildRoomId(int a, int b) {
    final ids = [a, b]..sort();
    return 'private_${ids[0]}_${ids[1]}';
  }
}


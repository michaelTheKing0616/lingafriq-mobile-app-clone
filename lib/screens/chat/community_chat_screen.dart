import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/avatars/avatars.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/chat_socket_provider.dart';

/// Community Chat (Language Villages) with Material 3 Design
class CommunityChatScreen extends HookConsumerWidget {
  final String villageId;
  final String villageName;

  const CommunityChatScreen({
    Key? key,
    required this.villageId,
    required this.villageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final messages = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(false);
    final scrollController = useScrollController();
    final page = useState(1);
    final socketNotifier = ref.read(chatSocketProvider.notifier);
    final socketState = ref.watch(chatSocketProvider);
    final currentUser = ref.watch(userProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomId = 'community_$villageId';

    Future<void> loadMessages() async {
      try {
        final response = await ApiService.get(
          '/chat/community/$villageId',
          queryParameters: {
            'page': page.value,
            'limit': 50,
          },
        );

        if (response.statusCode == 200 && response.data['data'] != null) {
          messages.value = List<Map<String, dynamic>>.from(response.data['data']);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }

    Future<void> sendMessage() async {
      if (messageController.text.isEmpty) return;

      isLoading.value = true;
      try {
        final response = await ApiService.post(
          '/chat/community/$villageId',
          data: {
            'message': messageController.text,
          },
        );

        if (response.statusCode == 200) {
          messageController.clear();
          // Message will be received via socket, no need to reload
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      // Load initial messages
      loadMessages();

      // Connect socket and join room
      if (currentUser != null) {
        socketNotifier.connect(currentUser.id.toString(), currentUser.username);
        socketNotifier.joinRoom(roomId);
      }

      // Listen for socket events
      final socketMessages = socketState.messages.where((msg) {
        final msgRoom = msg['room']?.toString() ?? '';
        return msgRoom == roomId || msgRoom == 'community_$villageId';
      }).toList();

      // Merge socket messages with loaded messages
      final allMessages = <Map<String, dynamic>>[];
      final messageIds = <String>{};

      // Add loaded messages first
      for (final msg in messages.value) {
        final id = msg['_id']?.toString() ?? msg['id']?.toString() ?? '';
        if (id.isNotEmpty && !messageIds.contains(id)) {
          allMessages.add(msg);
          messageIds.add(id);
        }
      }

      // Add socket messages
      for (final msg in socketMessages) {
        final id = msg['_id']?.toString() ?? msg['id']?.toString() ?? msg['messageId']?.toString() ?? '';
        if (id.isNotEmpty && !messageIds.contains(id)) {
          allMessages.add(msg);
          messageIds.add(id);
        }
      }

      // Sort by timestamp
      allMessages.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? a['timestamp']?.toString() ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? b['timestamp']?.toString() ?? '') ?? DateTime(1970);
        return aTime.compareTo(bTime);
      });

      messages.value = allMessages;

      return () {
        // Leave room on dispose
        socketNotifier.leaveRoom(roomId);
      };
    }, [socketState.messages, currentUser]);

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Sending message...',
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(villageName),
              Text(
                'Language Village',
                style: PanAfricanTypography.bodySmall(context),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      body: Container(
        color: isDark
            ? PanAfricanColors.surfaceDark
            : PanAfricanColors.surfaceLight,
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: messages.value.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64.sp,
                            color: PanAfricanColors.neutralMedium,
                          ),
                          SizedBox(height: PanAfricanSpacing.md),
                          Text(
                            'No messages yet',
                            style: PanAfricanTypography.bodyLarge(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs),
                          Text(
                            'Be the first to start the conversation!',
                            style: PanAfricanTypography.bodySmall(context),
                          ),
                        ],
                      ),
                    )
                  : OptimizedListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      itemCount: messages.value.length,
                      itemBuilder: (context, index) {
                        final message = messages.value[index];
                        final currentUser = ref.read(userProvider);
                        final senderId = message['sender_id'] is Map
                            ? (message['sender_id'] as Map)['id']
                            : message['sender_id'];
                        final isFromCurrentUser = currentUser != null &&
                            senderId != null &&
                            senderId.toString() == currentUser.id.toString();
                        return _CommunityMessageBubble(
                          message: message,
                          isDark: isDark,
                          isFromCurrentUser: isFromCurrentUser,
                        )
                            .animate(delay: (index * 30).ms)
                            .fadeIn(duration: 200.ms);
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
                    child: Semantics(
                      label: 'Message input field',
                      hint: 'Type a message to send',
                      textField: true,
                      child: TextField(
                        controller: messageController,
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
                      onSubmitted: (_) {
                        HapticFeedback.lightImpact();
                        sendMessage();
                      },
                    ),
                    ),
                  ),
                  SizedBox(width: PanAfricanSpacing.sm),
                  Semantics(
                    label: isLoading.value ? 'Sending message' : 'Send message',
                    button: true,
                    enabled: !isLoading.value,
                    child: IconButton(
                      icon: isLoading.value
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.send),
                      onPressed: isLoading.value
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              sendMessage();
                            },
                      color: PanAfricanColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ), // closes Scaffold body Container
    ), // closes Scaffold
  ); // closes LoadingOverlay
  }
}

class _CommunityMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isDark;
  final bool isFromCurrentUser;

  const _CommunityMessageBubble({
    required this.message,
    required this.isDark,
    this.isFromCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final sender = message['sender_id'] as Map<String, dynamic>?;
    final rawName = sender?['username'] ?? sender?['first_name'] ?? 'Unknown';
    final senderName = rawName is String && rawName.isNotEmpty ? rawName : 'Unknown';
    final timestamp = message['createdAt'] ?? message['timestamp'];
    final bubbleColor = isFromCurrentUser
        ? PanAfricanColors.primary
        : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight);

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromCurrentUser)
            Semantics(
              label: 'Avatar for $senderName',
              excludeSemantics: true,
              child: LingAfriqAvatar.fromInitials(
                username: senderName.isNotEmpty ? senderName : '?',
                size: 40.w,
              ),
            ),
          if (!isFromCurrentUser) SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Semantics(
              label: 'Message from $senderName: ${message['message'] ?? ''}',
              child: Column(
                crossAxisAlignment:
                    isFromCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: PanAfricanTypography.labelMedium(context)
                            .copyWith(color: PanAfricanColors.primary),
                      ),
                    if (timestamp != null) ...[
                      SizedBox(width: PanAfricanSpacing.xs),
                      Text(
                        _formatTimestamp(timestamp.toString()),
                        style: PanAfricanTypography.labelSmall(context)
                            .copyWith(color: PanAfricanColors.neutralMedium),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.md,
                    vertical: PanAfricanSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: PanAfricanRadius.lgBR,
                  ),
                  child: Text(
                    message['message'] ?? '',
                    style: PanAfricanTypography.bodyMedium(context).copyWith(
                      color: isFromCurrentUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : (isDark ? null : PanAfricanColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
          if (isFromCurrentUser) SizedBox(width: PanAfricanSpacing.sm),
          if (isFromCurrentUser)
            Semantics(
              label: 'Your avatar',
              excludeSemantics: true,
              child: LingAfriqAvatar.fromInitials(
                username: senderName.isNotEmpty ? senderName : '?',
                size: 40.w,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }
}


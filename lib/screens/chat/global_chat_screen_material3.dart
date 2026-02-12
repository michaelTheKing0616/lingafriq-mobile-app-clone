import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/screens/chat/user_search_global_id_screen.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/widgets/empty_state_widget.dart';
import 'package:lingafriq/widgets/error_state_widget.dart';
import 'package:lingafriq/widgets/skeleton_loader.dart';

/// Redesigned Global Chat with Material 3 and Language-Specific Channels
class GlobalChatScreenMaterial3 extends HookConsumerWidget {
  const GlobalChatScreenMaterial3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final messages = useState<List<Map<String, dynamic>>>([]);
    final channels = useState<List<String>>(['general', 'yoruba', 'hausa', 'igbo', 'pidgin', 'swahili', 'zulu']);
    final selectedChannel = useState('general');
    final isLoading = useState(false);
    final isLoadingMessages = useState(true);
    final loadError = useState<String?>(null);
    final scrollController = useScrollController();
    final showChannels = useState(false);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<Map<String, dynamic>> _parseMessageList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{'body': e.toString()}).toList();
      }
      return [];
    }

    Future<void> loadMessages() async {
      isLoadingMessages.value = true;
      loadError.value = null;
      try {
        final response = await ApiService.get(
          Api.chatGlobal,
          queryParameters: {
            'channel': selectedChannel.value,
            'limit': 50,
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          List<Map<String, dynamic>> list = [];
          final raw = response.data;
          if (raw is List) {
            list = _parseMessageList(raw);
          } else if (raw is Map) {
            final data = raw as Map;
            list = _parseMessageList(data['data'] ?? data['messages'] ?? data['results'] ?? data['leaderboard']);
          }
          messages.value = list;
        }
      } catch (e) {
        loadError.value = e is DioException
            ? TransportErrorPolicy.toUserMessage(e)
            : 'Connection failed. Tap Retry to load messages.';
        if (context.mounted) ErrorHandler.showError(context, e);
      } finally {
        isLoadingMessages.value = false;
      }
    }

    Future<void> sendMessage() async {
      if (messageController.text.isEmpty) return;

      isLoading.value = true;
      try {
        final response = await ApiService.post(
          Api.chatGlobal,
          data: {
            'message': messageController.text,
            'channel': selectedChannel.value,
          },
        );

        if (response.statusCode == 200) {
          messageController.clear();
          loadMessages();
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
      loadMessages();
      return null;
    }, [selectedChannel.value]);

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Sending message...',
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Global Chat'),
              Text(
                '#${selectedChannel.value}',
                style: PanAfricanTypography.bodySmall(context),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
          IconButton(
            icon: Icon(Icons.person_search),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                SmoothPageRoute(
                  child: UserSearchGlobalIdScreen(
                    onUserSelected: (user) {
                      messageController.text = '@${user['global_id'] ?? user['username']} ';
                    },
                    currentChatType: 'global',
                  ),
                ),
              );
            },
            tooltip: 'Find User',
          ),
          IconButton(
            icon: Icon(Icons.tag),
            onPressed: () {
              HapticFeedback.selectionClick();
              showChannels.value = !showChannels.value;
            },
            tooltip: 'Channels',
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              HapticFeedback.selectionClick();
              // Moderation tools
            },
            tooltip: 'More',
          ),
        ],
      ),
      body: Container(
        color: isDark
            ? PanAfricanColors.surfaceDark
            : PanAfricanColors.surfaceLight,
        child: Row(
          children: [
            // Channels Sidebar
            if (showChannels.value)
              Container(
                width: 200.w,
                decoration: BoxDecoration(
                  color: isDark
                      ? PanAfricanColors.surfaceContainerDark
                      : PanAfricanColors.surfaceContainerLight,
                  border: Border(
                    right: BorderSide(
                      color: isDark
                          ? PanAfricanColors.borderDark
                          : PanAfricanColors.borderLight,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      child: Text(
                        'Channels',
                        style: PanAfricanTypography.titleMedium(context),
                      ),
                    ),
                    Expanded(
                      child: OptimizedListView.builder(
                        itemCount: channels.value.length,
                        itemBuilder: (context, index) {
                          final channel = channels.value[index];
                          final isSelected = selectedChannel.value == channel;

                          return PanAfricanListTile(
                            title: '#$channel',
                            leading: Icon(
                              Icons.tag,
                              color: isSelected
                                  ? PanAfricanColors.primary
                                  : PanAfricanColors.neutralMedium,
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: PanAfricanColors.primary)
                                : null,
                            onTap: () {
                              selectedChannel.value = channel;
                              HapticFeedback.mediumImpact();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Messages Area
            Expanded(
              child: Column(
                children: [
                  // Messages List
                  Expanded(
                    child: isLoadingMessages.value
                        ? ListView.builder(
                            padding: EdgeInsets.all(PanAfricanSpacing.md),
                            itemCount: 5,
                            itemBuilder: (context, index) => const SkeletonListCard(),
                          )
                        : loadError.value != null
                            ? AppErrorState(
                                message: loadError.value!,
                                onRetry: loadMessages,
                                icon: Icons.wifi_off_rounded,
                              )
                            : messages.value.isEmpty
                                ? AppEmptyState(
                                    icon: Icons.chat_bubble_outline,
                                    title: 'No messages yet',
                                    subtitle: 'Be the first to start the conversation!',
                                    actionLabel: 'Say hello',
                                    onAction: () {
                                      messageController.text =
                                          'Hello everyone! Excited to learn together.';
                                      sendMessage();
                                    },
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
                              return _GlobalMessageBubble(
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
                          child: PanAfricanTextField(
                            controller: messageController,
                            hint: 'Type a message...',
                            maxLines: 3,
                            onChanged: (_) {},
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        PanAfricanButton(
                          label: 'Send',
                          icon: Icons.send_rounded,
                          isLoading: isLoading.value,
                          onPressed: isLoading.value
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  sendMessage();
                                },
                          backgroundColor: PanAfricanColors.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ],
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
}

class _GlobalMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isDark;
  final bool isFromCurrentUser;

  const _GlobalMessageBubble({
    required this.message,
    required this.isDark,
    this.isFromCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final sender = message['sender_id'] is Map
        ? message['sender_id'] as Map<String, dynamic>
        : null;
    final rawName = sender?['username'] ??
        sender?['first_name'] ??
        message['username'] ??
        message['sender'];
    final senderName = rawName is String ? rawName : (rawName?.toString() ?? 'Unknown');
    final isToxic = message['flagged_toxic'] ?? false;
    final timestamp = message['createdAt'] ?? message['timestamp'];
    final avatarUrl = sender?['avatar_url'] ?? sender?['avatar'] ?? message['avatar'];
    final globalId = sender?['global_id'] ?? message['global_id'];
    final messageText = message['message'] ?? message['body'] ?? message['text'] ?? '';
    final bubbleColor = isToxic
        ? PanAfricanColors.error.withOpacity(0.08)
        : (isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight);

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanAfricanAvatar(
            imageUrl: avatarUrl is String ? avatarUrl : null,
            initials: senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
            size: 40.w,
            backgroundColor: isToxic ? PanAfricanColors.error : PanAfricanColors.primary,
            borderColor: isToxic ? PanAfricanColors.error : PanAfricanColors.primary,
            showBadge: isToxic,
            badgeColor: PanAfricanColors.error,
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            senderName,
                            style: PanAfricanTypography.labelMedium(context)
                                .copyWith(color: PanAfricanColors.primary),
                          ),
                          if (globalId != null) ...[
                            SizedBox(width: PanAfricanSpacing.xxs),
                            Text(
                              '@${globalId.toString()}',
                              style: PanAfricanTypography.labelSmall(context).copyWith(
                                color: PanAfricanColors.neutralMedium,
                              ),
                            ),
                          ],
                          if (isToxic) ...[
                            SizedBox(width: PanAfricanSpacing.xs),
                            PanAfricanBadge(
                              label: 'Flagged',
                              color: PanAfricanColors.error,
                              icon: Icons.report_problem_rounded,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        _formatTimestamp(timestamp.toString()),
                        style: PanAfricanTypography.labelSmall(context)
                            .copyWith(color: PanAfricanColors.neutralMedium),
                      ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                PanAfricanCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.md,
                    vertical: PanAfricanSpacing.sm,
                  ),
                  backgroundColor: bubbleColor,
                  child: Text(
                    messageText,
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ),
              ],
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


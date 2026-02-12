import 'package:flutter/material.dart';
import 'package:lingafriq/utils/performance_utils.dart' hide OptimizedListView;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';
import 'package:lingafriq/widgets/performance/optimized_list_view.dart';
import 'package:lingafriq/avatars/avatars.dart';
import 'package:lingafriq/providers/chat_socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';

/// Tribe Chat Screen with Material 3 Design
class TribeChatScreen extends HookConsumerWidget {
  final String tribeId;
  final String tribeName;

  const TribeChatScreen({
    Key? key,
    required this.tribeId,
    required this.tribeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final messages = useState<List<Map<String, dynamic>>>([]);
    final members = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(false);
    final loadError = useState<String?>(null);
    final scrollController = useScrollController();
    final showMembers = useState(false);
    final socketNotifier = ref.read(chatSocketProvider.notifier);
    final socketState = ref.watch(chatSocketProvider);
    final currentUser = ref.watch(userProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomId = 'tribe_$tribeId';

    List<Map<String, dynamic>> _parseList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{'body': e.toString()}).toList();
      }
      return [];
    }

    String _connectionMessage(dynamic e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') || msg.contains('connection') || msg.contains('unavailable') || msg.contains('failed host')) {
        return 'Server unavailable. Check your connection and try again.';
      }
      if (msg.contains('timeout')) return 'Request timed out.';
      return 'Unable to load messages.';
    }

    Future<void> loadMessages() async {
      loadError.value = null;
      try {
        final response = await ApiService.get(
          '/chat/tribe/$tribeId',
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>?;
          final list = data?['data'] != null
              ? _parseList(data!['data'])
              : data?['messages'] != null
                  ? _parseList(data!['messages'])
                  : <Map<String, dynamic>>[];
          messages.value = list;
        }
      } catch (e) {
        loadError.value = e is DioException
            ? TransportErrorPolicy.toUserMessage(e)
            : _connectionMessage(e);
        if (context.mounted) ErrorHandler.showError(context, e);
      }
    }

    Future<void> loadMembers() async {
      try {
        final response = await ApiService.get(
          '/chat/tribe/$tribeId/members',
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>?;
          final raw = data?['data'] ?? data?['members'];
          members.value = _parseList(raw);
        }
      } catch (e) {
        if (context.mounted) ErrorHandler.showError(context, e);
      }
    }

    Future<void> sendMessage() async {
      if (messageController.text.isEmpty) return;

      isLoading.value = true;
      try {
        final response = await ApiService.post(
          '/chat/tribe/$tribeId',
          data: {
            'message': messageController.text,
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
      loadMembers();
      return null;
    }, []);

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Sending message...',
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tribeName),
              Text(
                '${members.value.length} members',
                style: PanAfricanTypography.bodySmall(context),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.people),
              onPressed: () {
                HapticFeedback.selectionClick();
                showMembers.value = !showMembers.value;
              },
              tooltip: 'Tribe Members',
            ),
          ],
        ),
      body: ResponsiveSafeArea(
        child: loadError.value != null && messages.value.isEmpty
            ? LingAfriqRetryBlock(
                message: loadError.value!,
                onRetry: () => loadMessages(),
              )
            : Row(
        children: [
          // Messages Area
          Expanded(
            child: Container(
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
                  // Messages List
                  Expanded(
                    child: messages.value.isEmpty
                        ? Center(
                            child: PanAfricanCard(
                              padding: EdgeInsets.all(PanAfricanSpacing.lg),
                              hasGlow: true,
                              glowColor: PanAfricanColors.secondary,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.forum_outlined,
                                    size: 56.sp,
                                    color: PanAfricanColors.secondary,
                                  ),
                                  SizedBox(height: PanAfricanSpacing.md),
                                  Text(
                                    'No messages yet',
                                    style: PanAfricanTypography.titleMedium(context),
                                  ),
                                  SizedBox(height: PanAfricanSpacing.xs),
                                  Text(
                                    'Say hello and start the conversation.',
                                    style: PanAfricanTypography.bodySmall(context).copyWith(
                                      color: PanAfricanColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: PanAfricanSpacing.md),
                                  PanAfricanButton(
                                    label: 'Introduce yourself',
                                    icon: Icons.waving_hand_rounded,
                                    backgroundColor: PanAfricanColors.secondary,
                                    foregroundColor: PanAfricanColors.neutralDarkest,
                                    onPressed: () {
                                      messageController.text =
                                          'Hello tribe! Excited to learn together.';
                                      sendMessage();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        : OptimizedListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.all(PanAfricanSpacing.md),
                            itemCount: messages.value.length,
                            itemBuilder: (context, index) {
                              final message = messages.value[index];
                              return _TribeMessageBubble(
                                message: message,
                                isDark: isDark,
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
                          backgroundColor: PanAfricanColors.secondary,
                          foregroundColor: PanAfricanColors.neutralDarkest,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Members Sidebar
          if (showMembers.value)
            Container(
              width: 200.w,
              decoration: BoxDecoration(
                color: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
                border: Border(
                  left: BorderSide(
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
                      'Tribe Members',
                      style: PanAfricanTypography.titleMedium(context),
                    ),
                  ),
                  Expanded(
                    child: OptimizedListView.builder(
                      itemCount: members.value.length,
                      itemBuilder: (context, index) {
                        final member = members.value[index];
                        final name =
                            member['username'] ?? member['first_name'] ?? 'Unknown';
                        final globalId = member['global_id'] ?? member['globalId'];
                        return PanAfricanListTile(
                          title: name,
                          subtitle: globalId != null ? '@${globalId.toString()}' : null,
                          leading: LingAfriqAvatar.fromInitials(
                            username: name.toString().isNotEmpty ? name.toString() : 'U',
                            size: 36.w,
                          ),
                        );
                      },
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

class _TribeMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isDark;

  const _TribeMessageBubble({
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sender = message['sender_id'] as Map<String, dynamic>?;
    final raw = sender?['username'] ?? sender?['first_name'] ?? 'Unknown';
    final senderName = raw != null && raw.toString().trim().isNotEmpty ? raw.toString() : 'Unknown';
    final timestamp = message['createdAt'] ?? message['timestamp'];
    final avatarUrl = sender?['avatar_url'] ?? sender?['avatar'] ?? message['avatar'];
    final globalId = sender?['global_id'] ?? message['global_id'];
    final messageText = message['message'] ?? message['body'] ?? message['text'] ?? '';
    final bubbleColor = isDark
        ? PanAfricanColors.surfaceContainerDark
        : PanAfricanColors.surfaceContainerLight;

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LingAfriqAvatar.fromInitials(
            username: senderName.isNotEmpty ? senderName : '?',
            size: 40.w,
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
                                .copyWith(color: PanAfricanColors.secondary),
                          ),
                          if (globalId != null) ...[
                            SizedBox(width: PanAfricanSpacing.xxs),
                            Text(
                              '@${globalId.toString()}',
                              style: PanAfricanTypography.labelSmall(context)
                                  .copyWith(color: PanAfricanColors.neutralMedium),
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


import 'package:flutter/material.dart';
import 'package:lingafriq/utils/performance_utils.dart';
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
        loadError.value = 'Connection failed. Tap Retry to load messages.';
        if (context.mounted) ErrorHandler.showError(context, e);
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
              Navigator.push(
                context,
                SmoothPageRoute(
                  child: UserSearchGlobalIdScreen(
                    onUserSelected: (user) {
                      // Mention user in chat or open private chat
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
            onPressed: () => showChannels.value = !showChannels.value,
            tooltip: 'Channels',
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // Moderation tools
            },
            tooltip: 'More',
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

                          return ListTile(
                            selected: isSelected,
                            leading: Icon(
                              Icons.tag,
                              color: isSelected
                                  ? PanAfricanColors.primary
                                  : PanAfricanColors.neutralMedium,
                            ),
                            title: Text(
                              '#$channel',
                              style: PanAfricanTypography.bodyMedium(context).copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                color: isSelected
                                    ? PanAfricanColors.primary
                                    : null,
                              ),
                            ),
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
                              return _GlobalMessageBubble(
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
                          child: TextField(
                            controller: messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? PanAfricanColors.surfaceDark
                                  : PanAfricanColors.surfaceLight,
                            ),
                            onSubmitted: (_) => sendMessage(),
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        IconButton(
                          icon: isLoading.value
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : Icon(Icons.send),
                          onPressed: isLoading.value ? null : sendMessage,
                          color: PanAfricanColors.primary,
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

  const _GlobalMessageBubble({
    required this.message,
    required this.isDark,
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

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: isToxic
                ? PanAfricanColors.error
                : PanAfricanColors.primary,
            child: Text(
              senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
              style: PanAfricanTypography.labelMedium(context)
                  .copyWith(color: Colors.white),
            ),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      senderName,
                      style: PanAfricanTypography.labelSmall(context)
                          .copyWith(color: PanAfricanColors.primary),
                    ),
                    SizedBox(width: PanAfricanSpacing.xs),
                    if (isToxic)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PanAfricanColors.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'FLAGGED',
                          style: PanAfricanTypography.labelSmall(context)
                              .copyWith(
                            color: PanAfricanColors.error,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  ),
                  child: Text(
                    message['message'] ?? message['body'] ?? message['text'] ?? '',
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
}


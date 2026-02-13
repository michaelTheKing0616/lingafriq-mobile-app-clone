import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';

/// Redesigned Private Chat with Material 3
class PrivateChatScreenMaterial3 extends HookConsumerWidget {
  final String otherUserId;
  final String otherUserName;

  const PrivateChatScreenMaterial3({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final messages = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(false);
    final loadError = useState<String?>(null);
    final scrollController = useScrollController();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> loadMessages() async {
      loadError.value = null;
      try {
        final response = await ApiService.get(
          '/chat/private/$otherUserId',
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>?;
          final raw = data?['data'];
          List<dynamic> list = const [];
          if (raw is List) {
            list = raw;
          } else if (raw is Map && raw['docs'] is List) {
            list = raw['docs'] as List;
          } else if (data?['messages'] is List) {
            list = data!['messages'];
          }
          messages.value = list
              .map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{'body': e.toString()})
              .toList();
        }
      } catch (e) {
        loadError.value = e is DioException
            ? TransportErrorPolicy.toUserMessage(e)
            : 'Unable to load messages. Tap Retry to try again.';
        if (context.mounted) ErrorHandler.showError(context, e);
      }
    }

    Future<void> sendMessage() async {
      if (messageController.text.isEmpty) return;

      isLoading.value = true;
      try {
        final response = await ApiService.post(
          '/chat/private',
          data: {
            'recipientId': otherUserId,
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
      return null;
    }, []);

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Sending message...',
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: PanAfricanColors.primary,
                child: Text(
                  otherUserName[0].toUpperCase(),
                  style: PanAfricanTypography.labelSmall(context)
                      .copyWith(color: colorScheme.onPrimary),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Text(otherUserName),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      body: ResponsiveSafeArea(
        child: loadError.value != null && messages.value.isEmpty
            ? LingAfriqRetryBlock(
                message: loadError.value!,
                onRetry: () => loadMessages(),
              )
            : Container(
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
                            'Start a conversation with $otherUserName',
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
                        final isMe = message['sender_id'] == 'current_user_id'; // Replace with actual check

                        return _PrivateMessageBubble(
                          message: message,
                          isMe: isMe,
                          isDark: isDark,
                        )
                            .animate(delay: (index * 30).ms)
                            .fadeIn(duration: 200.ms)
                            .slideX(begin: isMe ? 0.2 : -0.2);
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
                  SizedBox(width: PanAfricanSpacing.sm),
                  IconButton(
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
                ],
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}

class _PrivateMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool isDark;

  const _PrivateMessageBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = message['createdAt'] ?? message['timestamp'];
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
        constraints: BoxConstraints(maxWidth: 0.7.sw),
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? PanAfricanColors.primary
              : (isDark
                  ? PanAfricanColors.cardDark
                  : PanAfricanColors.cardLight),
          borderRadius: PanAfricanRadius.lgBR.copyWith(
            bottomLeft: isMe ? null : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : null,
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
            if (timestamp != null) ...[
              SizedBox(height: PanAfricanSpacing.xxs),
              Text(
                _formatTimestamp(timestamp.toString()),
                style: PanAfricanTypography.labelSmall(context).copyWith(
                  color: isMe
                      ? colorScheme.onPrimary.withOpacity(0.7)
                      : PanAfricanColors.neutralMedium,
                ),
              ),
            ],
          ],
        ),
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


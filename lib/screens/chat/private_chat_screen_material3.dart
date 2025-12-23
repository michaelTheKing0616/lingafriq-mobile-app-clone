import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';

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
    final scrollController = useScrollController();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> loadMessages() async {
      try {
        final response = await ApiService.get(
          '/chat/private/$otherUserId',
        );

        if (response.statusCode == 200 && response.data['data'] != null) {
          messages.value = List<Map<String, dynamic>>.from(response.data['data']);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: ${e.toString()}')),
        );
      }
    }

    Future<void> sendMessage() async {
      if (messageController.text.isEmpty) return;

      isLoading.value = true;
      try {
        final response = await ApiService.post(
          '/chat/private',
          data: {
            'recipient_id': otherUserId,
            'message': messageController.text,
          },
        );

        if (response.statusCode == 200) {
          messageController.clear();
          loadMessages();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${e.toString()}')),
        );
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
                    .copyWith(color: Colors.white),
              ),
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            Text(otherUserName),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  : ListView.builder(
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
        constraints: BoxConstraints(maxWidth: 0.7.sw),
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: isMe
              ? PanAfricanColors.primary
              : (isDark
                  ? PanAfricanColors.surfaceContainerDark
                  : PanAfricanColors.surfaceContainerLight),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(PanAfricanRadius.md),
            topRight: Radius.circular(PanAfricanRadius.md),
            bottomLeft: isMe
                ? Radius.circular(PanAfricanRadius.md)
                : Radius.circular(0),
            bottomRight: isMe
                ? Radius.circular(0)
                : Radius.circular(PanAfricanRadius.md),
          ),
        ),
        child: Text(
          message['message'] ?? '',
          style: PanAfricanTypography.bodyMedium(context).copyWith(
            color: isMe ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}


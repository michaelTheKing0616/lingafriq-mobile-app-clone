import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        return _CommunityMessageBubble(
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
      ), // closes Scaffold body Container
    ), // closes Scaffold
  ); // closes LoadingOverlay
  }
}

class _CommunityMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isDark;

  const _CommunityMessageBubble({
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sender = message['sender_id'] as Map<String, dynamic>?;
    final senderName = sender?['username'] ?? sender?['first_name'] ?? 'Unknown';

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 20.r,
            backgroundColor: PanAfricanColors.primary,
            child: Text(
              senderName[0].toUpperCase(),
              style: PanAfricanTypography.labelMedium(context)
                  .copyWith(color: Colors.white),
            ),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: PanAfricanTypography.labelSmall(context)
                      .copyWith(color: PanAfricanColors.primary),
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
                    message['message'] ?? '',
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


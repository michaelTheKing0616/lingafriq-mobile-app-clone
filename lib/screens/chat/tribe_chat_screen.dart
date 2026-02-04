import 'package:flutter/material.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';
import 'package:lingafriq/widgets/performance/optimized_list_view.dart';

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        loadError.value = _connectionMessage(e);
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
        title: Text(tribeName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.people),
            onPressed: () => showMembers.value = !showMembers.value,
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
                        ? LingAfriqEmptyState(
                            icon: Icons.chat_bubble_outline,
                            title: 'No messages yet',
                            subtitle: 'Say hello and start the conversation.',
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
                          child: TextField(
                            controller: messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(PanAfricanRadius.md),
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
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: PanAfricanColors.primary,
                            child: Text(
                              (member['username'] ?? member['first_name'] ?? 'U')[0]
                                  .toUpperCase(),
                              style: PanAfricanTypography.labelSmall(context)
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            member['username'] ?? member['first_name'] ?? 'Unknown',
                            style: PanAfricanTypography.bodyMedium(context),
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

    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: PanAfricanColors.secondary,
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
                Text(
                  senderName,
                  style: PanAfricanTypography.labelSmall(context)
                      .copyWith(color: PanAfricanColors.secondary),
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


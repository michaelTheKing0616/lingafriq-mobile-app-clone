import 'package:flutter/material.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Moderation Tools for Global and Community Chat
class ModerationToolsScreen extends HookConsumerWidget {
  final String chatType; // 'global' or 'community'
  final String? chatId; // villageId for community, null for global

  const ModerationToolsScreen({
    Key? key,
    required this.chatType,
    this.chatId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flaggedMessages = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> loadFlaggedMessages() async {
      isLoading.value = true;
      try {
        final endpoint = chatType == 'global'
            ? '/chat/global/flagged'
            : '/chat/community/$chatId/flagged';

        final response = await ApiService.get(endpoint);

        if (response.statusCode == 200 && response.data['data'] != null) {
          flaggedMessages.value = List<Map<String, dynamic>>.from(response.data['data']);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> moderateMessage(
      String messageId,
      String action, // 'approve', 'delete', 'warn'
    ) async {
      try {
        await ApiService.post(
          '/chat/messages/$messageId/moderate',
          data: {
            'action': action,
            'chatType': chatType,
            'chatId': chatId,
          },
        );

        loadFlaggedMessages();
        if (context.mounted) {
          ErrorHandler.showSuccess(context, 'Message ${action}d successfully');
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }

    useEffect(() {
      loadFlaggedMessages();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Moderation Tools'),
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
        child: isLoading.value
            ? Center(child: CircularProgressIndicator())
            : flaggedMessages.value.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64.sp,
                          color: PanAfricanColors.success,
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                        Text(
                          'No flagged messages',
                          style: PanAfricanTypography.bodyLarge(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.xs),
                        Text(
                          'All messages are clean!',
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ],
                    ),
                  )
                : OptimizedListView.builder(
                    padding: EdgeInsets.all(PanAfricanSpacing.lg),
                    itemCount: flaggedMessages.value.length,
                    itemBuilder: (context, index) {
                      final message = flaggedMessages.value[index];
                      return _FlaggedMessageCard(
                        message: message,
                        onModerate: moderateMessage,
                        isDark: isDark,
                      )
                          .animate(delay: (index * 50).ms)
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.2);
                    },
                  ),
      ),
    );
  }
}

class _FlaggedMessageCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final Function(String, String) onModerate;
  final bool isDark;

  const _FlaggedMessageCard({
    required this.message,
    required this.onModerate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reason = message['flag_reason'] ?? 'Toxic content';
    final severity = message['severity'] ?? 'medium';
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      child: ExpansionTile(
        leading: Icon(
          Icons.flag,
          color: _getSeverityColor(severity),
        ),
        title: Text(
          message['sender']?['username'] ?? 'Unknown User',
          style: PanAfricanTypography.titleMedium(context),
        ),
        subtitle: Text(
          'Reason: $reason',
          style: PanAfricanTypography.bodySmall(context),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message:',
                  style: PanAfricanTypography.labelMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.xs),
                Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
                  ),
                  child: Text(
                    message['message'] ?? '',
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => onModerate(message['_id'], 'approve'),
                      icon: Icon(Icons.check),
                      label: Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PanAfricanColors.success,
                    foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => onModerate(message['_id'], 'warn'),
                      icon: Icon(Icons.warning),
                      label: Text('Warn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PanAfricanColors.warning,
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => onModerate(message['_id'], 'delete'),
                      icon: Icon(Icons.delete),
                      label: Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PanAfricanColors.error,
                    foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return PanAfricanColors.error;
      case 'medium':
        return PanAfricanColors.warning;
      case 'low':
        return PanAfricanColors.info;
      default:
        return PanAfricanColors.neutralMedium;
    }
  }
}


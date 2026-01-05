import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'package:uuid/uuid.dart';

/// Dialogue View with Chat Interface, Context Indicators, Correction Hints
class TutorDialogueModeScreen extends HookConsumerWidget {
  const TutorDialogueModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final selectedLanguage = useState<AppLanguage>(AppLanguage.yoruba);
    final sessionId = useMemoized(() => const Uuid().v4());
    final messages = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(false);
    final scrollController = useScrollController();
    final localizationService = useMemoized(() => DynamicLocalizationService());
    final availableLanguages = AppLanguage.values;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> sendMessage() async {
      if (messageController.text.isEmpty) return;

      final userMessage = {
        'id': const Uuid().v4(),
        'text': messageController.text,
        'sender': 'user',
        'timestamp': DateTime.now(),
      };

      messages.value = [...messages.value, userMessage];
      messageController.clear();

      // Scroll to bottom
      Future.delayed(Duration(milliseconds: 100), () {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      isLoading.value = true;
      await safeAsync(
        context: context,
        operation: () async {
          final response = await ApiService.post(
            AppConfig.tutorDialogue,
            data: {
              'message': userMessage['text'],
              'sessionId': sessionId,
              'language': selectedLanguage.value.name,
              'context': messages.value
                  .map((m) => {'role': m['sender'], 'content': m['text']})
                  .toList(),
            },
          );

          if (response.statusCode == 200) {
            final polieMessage = {
              'id': const Uuid().v4(),
              'text': response.data['response'] ?? response.data['message'] ?? '',
              'sender': 'polie',
              'timestamp': DateTime.now(),
              'corrections': response.data['corrections'],
              'hints': response.data['hints'],
            };
            messages.value = [...messages.value, polieMessage];
          } else {
            throw Exception('Failed to send message');
          }
        },
        errorContext: 'sendMessage',
        showError: true,
      );
      isLoading.value = false;
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Sending message...',
      child: Scaffold(
        appBar: AppBar(
          title: Text('Practice Dialogue'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Language'),
                  content: DropdownButtonFormField<AppLanguage>(
                    value: selectedLanguage.value,
                    decoration: InputDecoration(labelText: 'Language'),
                    items: availableLanguages.map((lang) => DropdownMenuItem<AppLanguage>(
                      value: lang,
                      child: Text(
                        lang.name.substring(0, 1).toUpperCase() + lang.name.substring(1),
                      ),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) selectedLanguage.value = value;
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Done'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Context Indicator
          if (messages.value.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.md,
                vertical: PanAfricanSpacing.sm,
              ),
              color: PanAfricanColors.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16.sp),
                  SizedBox(width: PanAfricanSpacing.xs),
                  Expanded(
                    child: Text(
                      'Context: ${messages.value.length} messages',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ),
                ],
              ),
            ),

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
                          'Start a conversation with Polie',
                          style: PanAfricanTypography.bodyLarge(context),
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
                      return _MessageBubble(
                        message: message,
                        isDark: isDark,
                      )
                          .animate(delay: (index * 50).ms)
                          .fadeIn(duration: 200.ms)
                          .slideX(begin: message['sender'] == 'user' ? 0.2 : -0.2);
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
                      hintText: 'Type your message...',
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
    ), // closes LoadingOverlay
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message['sender'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
        constraints: BoxConstraints(maxWidth: 0.7.sw),
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: isUser
              ? PanAfricanColors.primary
              : (isDark
                  ? PanAfricanColors.surfaceContainerDark
                  : PanAfricanColors.surfaceContainerLight),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(PanAfricanRadius.md),
            topRight: Radius.circular(PanAfricanRadius.md),
            bottomLeft: isUser
                ? Radius.circular(PanAfricanRadius.md)
                : Radius.circular(0),
            bottomRight: isUser
                ? Radius.circular(0)
                : Radius.circular(PanAfricanRadius.md),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['text'],
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: isUser ? Colors.white : null,
              ),
            ),
            if (message['corrections'] != null &&
                (message['corrections'] as List).isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              ...(message['corrections'] as List).map((correction) {
                return Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.xs),
                  margin: EdgeInsets.only(bottom: PanAfricanSpacing.xxs),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.xs),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 14.sp),
                      SizedBox(width: PanAfricanSpacing.xxs),
                      Expanded(
                        child: Text(
                          correction,
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (message['hints'] != null && (message['hints'] as List).isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              ...(message['hints'] as List).map((hint) {
                return Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.xs),
                  margin: EdgeInsets.only(bottom: PanAfricanSpacing.xxs),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.xs),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14.sp),
                      SizedBox(width: PanAfricanSpacing.xxs),
                      Expanded(
                        child: Text(
                          hint,
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}


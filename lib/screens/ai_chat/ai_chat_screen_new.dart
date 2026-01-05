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
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;

/// Redesigned AI Chat Screen with Material 3, proper history scoping (language×mode)
class AIChatScreen extends HookConsumerWidget {
  final String language;
  final String languageName;
  final String mode;
  final String modeName;
  final dynamic initialScenario; // RoleplayEntry for roleplay mode

  const AIChatScreen({
    Key? key,
    required this.language,
    required this.languageName,
    required this.mode,
    required this.modeName,
    this.initialScenario,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final messages = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(false);
    final scrollController = useScrollController();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load chat history function
    Future<void> _loadChatHistory() async {
      try {
        final response = await ApiService.get(
          '/ai-chat/history',
          queryParameters: {
            'language': language,
            'mode': mode,
          },
        );

        if (response.statusCode == 200 && response.data['data'] != null) {
          messages.value = List<Map<String, dynamic>>.from(response.data['data']);
        }
      } catch (e) {
        // History might not exist yet, that's okay - silent fail
        // For other errors, we could show a message but it's not critical
      }
    }

    // Load chat history for this language×mode combination
    useEffect(() {
      _loadChatHistory();
      return null;
    }, []);

    Future<void> sendMessage() async {
      if (messageController.text.isEmpty) return;

      final userMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': messageController.text,
        'sender': 'user',
        'timestamp': DateTime.now().toIso8601String(),
      };

      messages.value = [...messages.value, userMessage];
      messageController.clear();

      // Scroll to bottom
      Future.delayed(Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      isLoading.value = true;
      try {
        final endpoint = _getEndpointForMode(mode);
        final response = await ApiService.post(
          endpoint,
          data: _getDataForMode(mode, userMessage['text'] as String),
        );

        if (response.statusCode == 200) {
          final polieMessage = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'text': _extractResponseFromMode(mode, response.data),
            'sender': 'polie',
            'timestamp': DateTime.now().toIso8601String(),
            'data': response.data,
          };
          messages.value = [...messages.value, polieMessage];
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      } finally {
        isLoading.value = false;
      }
    }

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Sending message...',
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(modeName),
              Text(
                languageName,
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
                            'Start chatting with Polie',
                            style: PanAfricanTypography.bodyLarge(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs),
                          Text(
                            'Mode: $modeName • Language: $languageName',
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
                        return _MessageBubble(
                          message: message,
                          mode: mode,
                          isDark: isDark,
                        )
                            .animate(delay: (index * 50).ms)
                            .fadeIn(duration: 200.ms)
                            .slideX(
                              begin: message['sender'] == 'user' ? 0.2 : -0.2,
                            );
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
                      maxLines: null,
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
    ), // closes LoadingOverlay
    );
  }

  String _getEndpointForMode(String mode) {
    switch (mode) {
      case 'tutor':
        return '/polie/tutor';
      case 'translate':
        return '/polie/tutor/translate';
      case 'review':
        return '/polie/tutor/review';
      case 'explain':
        return '/polie/tutor/explain';
      case 'pronunciation':
        return '/polie/tutor/pronunciation';
      case 'story':
        return '/polie/tutor/story';
      case 'dialogue':
        return '/polie/tutor/dialogue';
      case 'assess':
        return '/polie/tutor/assess';
      default:
        return '/polie/tutor';
    }
  }

  Map<String, dynamic> _getDataForMode(String mode, String text) {
    switch (mode) {
      case 'tutor':
        return {
          'message': text,
          'language': language,
          'mode': 'tutor',
          'sessionId': 'session_${DateTime.now().millisecondsSinceEpoch}',
        };
      case 'translate':
        return {
          'text': text,
          'sourceLang': 'english',
          'targetLang': language,
        };
      case 'review':
        return {
          'message': text,
          'language': language,
          'mode': 'review',
          'sessionId': 'session_${DateTime.now().millisecondsSinceEpoch}',
        };
      case 'explain':
        return {
          'topic': text,
          'language': language,
          'userLevel': 'A1',
        };
      case 'pronunciation':
        return {
          'text': text,
          'language': language,
          'mode': 'pronunciation',
        };
      case 'story':
        return {
          'theme': text,
          'language': language,
          'userLevel': 'A1',
        };
      case 'dialogue':
        return {
          'message': text,
          'language': language,
          'sessionId': 'session_${DateTime.now().millisecondsSinceEpoch}',
        };
      case 'assess':
        return {
          'language': language,
          'assessmentType': 'progress',
        };
      default:
        return {'text': text, 'language': language};
    }
  }

  String _extractResponseFromMode(String mode, Map<String, dynamic> data) {
    switch (mode) {
      case 'tutor':
        return data['response'] ?? data['message'] ?? data['explanation'] ?? '';
      case 'translate':
        return data['translation'] ?? data['adaptiveTranslation'] ?? data['response'] ?? '';
      case 'review':
        return data['review'] ?? data['response'] ?? data['message'] ?? '';
      case 'explain':
        return data['canonicalRule'] ?? data['explanation'] ?? data['response'] ?? '';
      case 'pronunciation':
        return data['pronunciation'] ?? data['feedback'] ?? data['response'] ?? '';
      case 'story':
        return data['story'] ?? data['response'] ?? '';
      case 'dialogue':
        return data['response'] ?? data['message'] ?? '';
      case 'assess':
        return 'Your proficiency level: ${data['proficiencyLevel'] ?? 'A1'}';
      default:
        return data['response'] ?? data['message'] ?? '';
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final String mode;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.mode,
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
            if (!isUser)
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: PanAfricanColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      size: 16.sp,
                      color: PanAfricanColors.primary,
                    ),
                  ),
                  SizedBox(width: PanAfricanSpacing.xs),
                  Text(
                    'Polie',
                    style: PanAfricanTypography.labelSmall(context)
                        .copyWith(color: PanAfricanColors.primary),
                  ),
                ],
              ),
            SizedBox(height: isUser ? 0 : PanAfricanSpacing.xs),
            Text(
              message['text'],
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: isUser ? Colors.white : null,
              ),
            ),
            // Show additional data based on mode
            if (!isUser && message['data'] != null)
              Builder(
                builder: (_) {
                  final content = _buildModeSpecificContent(context, mode, message['data'], isDark);
                  return content ?? const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildModeSpecificContent(
    BuildContext context,
    String mode,
    Map<String, dynamic> data,
    bool isDark,
  ) {
    switch (mode) {
      case 'translate':
        if (data['grammarNotes'] != null) {
          return Padding(
            padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
            child: Container(
              padding: EdgeInsets.all(PanAfricanSpacing.sm),
              decoration: BoxDecoration(
                color: PanAfricanColors.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
              ),
              child: Text(
                'Grammar: ${data['grammarNotes']}',
                style: PanAfricanTypography.bodySmall(context),
              ),
            ),
          );
        }
        return null;
      case 'explain':
        if (data['examples'] != null && (data['examples'] as List).isNotEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Examples:',
                  style: PanAfricanTypography.labelSmall(context),
                ),
                ...(data['examples'] as List).take(2).map((ex) {
                  final example = ex as Map<String, dynamic>;
                  return Padding(
                    padding: EdgeInsets.only(top: PanAfricanSpacing.xxs),
                    child: Text(
                      '• ${example['target']} - ${example['translation']}',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  );
                }),
              ],
            ),
          );
        }
        return null;
      default:
        return null;
    }
  }
}


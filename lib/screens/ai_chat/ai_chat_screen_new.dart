import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
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
          actions: [
            Padding(
              padding: EdgeInsets.only(right: PolieSpacing.sm, top: PolieSpacing.xs, bottom: PolieSpacing.xs),
              child: Center(
                child: PolieFloatingLanguagePill(
                  languageName: languageName,
                  accentColor: PolieColors.electricTeal,
                ),
              ),
            ),
          ],
        ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PolieColors.primary,
                    PolieColors.primaryDark,
                    PolieColors.obsidian,
                  ],
                )
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
                            color: isDark
                                ? PolieColors.electricTeal.withOpacity(0.7)
                                : PanAfricanColors.neutralMedium,
                          ),
                          SizedBox(height: PolieSpacing.lg),
                          Text(
                            'Start chatting with Polie',
                            style: isDark
                                ? PolieTypography.body(context)
                                : PanAfricanTypography.bodyLarge(context),
                          ),
                          SizedBox(height: PolieSpacing.xs),
                          Text(
                            'Mode: $modeName • Language: $languageName',
                            style: isDark
                                ? PolieTypography.bodySmall(context)
                                : PanAfricanTypography.bodySmall(context),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.all(PolieSpacing.md),
                      itemCount: messages.value.length,
                      itemBuilder: (context, index) {
                        final message = messages.value[index];
                        return _PolieMessageItem(
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

            // Input Area — Polie glass styling
            PolieGlassCard(
              padding: EdgeInsets.symmetric(
                horizontal: PolieSpacing.md,
                vertical: PolieSpacing.sm,
              ),
              borderRadius: 0,
              child: Row(
                children: [
                  Expanded(
                    child: PolieInputField(
                      controller: messageController,
                      enabled: !isLoading.value,
                      hintText: 'Type your message...',
                      maxLines: 4,
                      onSubmitted: (_) => sendMessage(),
                      prefixIcon: Icons.auto_awesome,
                    ),
                  ),
                  SizedBox(width: PolieSpacing.sm),
                  GestureDetector(
                    onTap: isLoading.value ? null : sendMessage,
                    child: Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [PolieColors.royalAmethyst, PolieColors.electricTeal],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: PolieElevation.level2(context, glowColor: PolieColors.royalAmethyst),
                      ),
                      child: isLoading.value
                          ? Padding(
                              padding: EdgeInsets.all(12.w),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                              ),
                            )
                          : Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 22.sp),
                    ),
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

/// Message row using PolieChatBubble and optional correction / mode-specific content.
class _PolieMessageItem extends StatelessWidget {
  final Map<String, dynamic> message;
  final String mode;
  final bool isDark;

  const _PolieMessageItem({
    required this.message,
    required this.mode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message['sender'] == 'user';
    final text = message['text'] as String? ?? '';
    final correctionText = message['correctionText'] as String?;

    if (isUser) {
      return PolieChatBubble(
        text: text,
        role: PolieChatBubbleRole.user,
      );
    }

    final modeContent = message['data'] != null
        ? _buildModeSpecificContent(context, mode, message['data'] as Map<String, dynamic>, isDark)
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: PolieSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.smart_toy,
                size: 16.sp,
                color: PolieColors.electricTeal,
              ),
              SizedBox(width: PolieSpacing.xs),
              Text(
                'Polie',
                style: PolieTypography.label(context).copyWith(
                  color: PolieColors.electricTeal,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.xs),
          PolieChatBubble(
            text: text,
            role: PolieChatBubbleRole.assistant,
            isCorrectionOverlay: correctionText != null && correctionText.isNotEmpty,
            correctionText: correctionText,
          ),
          if (modeContent != null) ...[
            SizedBox(height: PolieSpacing.sm),
            PolieGlassCard(
              padding: EdgeInsets.all(PolieSpacing.sm),
              borderRadius: PolieRadius.sm,
              child: modeContent,
            ),
          ],
        ],
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


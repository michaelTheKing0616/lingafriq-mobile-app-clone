import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'package:uuid/uuid.dart';
import 'package:lingafriq/services/env_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:flutter/services.dart';

/// Dialogue roles for role selection (friend, teacher, market seller, elder).
const List<Map<String, dynamic>> kDialogueRoles = [
  {'id': 'friend', 'label': 'Friend', 'icon': Icons.people_rounded, 'desc': 'Casual chat'},
  {'id': 'teacher', 'label': 'Teacher', 'icon': Icons.school_rounded, 'desc': 'Patient guidance'},
  {'id': 'market_seller', 'label': 'Market seller', 'icon': Icons.store_rounded, 'desc': 'Market scenario'},
  {'id': 'elder', 'label': 'Elder', 'icon': Icons.face_rounded, 'desc': 'Respectful dialogue'},
];

/// Dialogue Mode — premium chat (PolieChatBubble), role selection, real-time correction overlay, tone/difficulty slider.
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
    final availableLanguages = AppLanguage.values;
    final selectedRole = useState<String>('friend');
    final difficulty = useState<double>(0.5); // 0 = easier, 1 = harder

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<Map<String, dynamic>> _generateDialogueTurnWithGroq({
      required String language,
      required String userMessage,
      required List<Map<String, String>> contextTurns,
      required String role,
      required double difficultyLevel,
    }) async {
      final groqKey = EnvConfig.groqApiKey;
      final useBackend = groqKey.isEmpty ||
          groqKey.trim().isEmpty ||
          groqKey == 'YOUR_GROQ_API_KEY' ||
          groqKey.startsWith('YOUR_');
      final roleDesc = kDialogueRoles.firstWhere((r) => r['id'] == role, orElse: () => kDialogueRoles.first)['label'] as String;
      final difficultyDesc = difficultyLevel < 0.4 ? 'Use simple vocabulary and short sentences.' : (difficultyLevel > 0.7 ? 'Use richer vocabulary and longer sentences; correct subtle errors.' : 'Use moderate complexity.');
      final prompt = '''
You are Polie, an elite African language tutor.
Run a realistic practice dialogue in the TARGET_LANGUAGE. You are playing the role of: $roleDesc. $difficultyDesc
Respond in TARGET_LANGUAGE in the "response" field only. Put short English hints in "hints" only.

TARGET_LANGUAGE: $language
ROLE: $roleDesc

Conversation context (most recent last):
${contextTurns.map((t) => '${t['role']}: ${t['content']}').join('\n')}

User message: $userMessage

Return STRICT JSON ONLY (no markdown) in this exact shape:
{
  "response": "Polie's reply in $language (with correct diacritics if applicable)",
  "corrections": [
    {"original": "user text snippet", "corrected": "corrected snippet", "reason": "short explanation"},
    {"original": "...", "corrected": "...", "reason": "..."}
  ],
  "hints": ["One actionable tip or micro-exercise only when it would genuinely help the learner"]
}

Rules:
- If user message is already correct, return an empty array for "corrections".
- Be concise: response 1-4 sentences.
- Contextual hints (prompt-side): Provide "hints" only when genuinely helpful (e.g. after a correction, when the user made a clear mistake, or when they might be stuck). When the user wrote well or the reply is straightforward, return an empty array for "hints". Do not add hints on every turn.
''';

      if (useBackend) {
        final messages = <Map<String, String>>[
          {'role': 'user', 'content': prompt},
        ];
        final resp = await ApiService.post(
          '/api/ai/chat/completion',
          data: {
            'messages': messages.map((m) => {'role': m['role'], 'content': m['content']!}).toList(),
            'systemPrompt': 'You output only valid JSON. Never include markdown or commentary.',
            'temperature': 0.3,
            'max_tokens': 700,
          },
        );
        if (resp.statusCode != 200 || resp.data == null) {
          throw Exception('AI request failed. Please try again.');
        }
        final content = (resp.data is Map)
            ? (resp.data['content']?.toString() ?? '')
            : '';
        if (content.trim().isEmpty) throw Exception('AI returned an empty response. Please try again.');
        try {
          return jsonDecode(content) as Map<String, dynamic>;
        } catch (_) {
          final start = content.indexOf('{');
          final end = content.lastIndexOf('}');
          if (start >= 0 && end > start) {
            return jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
          }
          return {
            'response': content.trim(),
            'corrections': null,
            'hints': null,
          };
        }
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

      final resp = await dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        data: {
          'model': 'llama-3.1-70b-versatile',
          'temperature': 0.3,
          'max_tokens': 700,
          'messages': [
            {
              'role': 'system',
              'content': 'You output only valid JSON. Never include markdown or commentary.',
            },
            {'role': 'user', 'content': prompt},
          ],
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $groqKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (resp.statusCode != 200) {
        throw Exception('AI request failed (${resp.statusCode}). Please try again.');
      }

      final content = (resp.data is Map)
          ? (resp.data['choices']?[0]?['message']?['content']?.toString() ?? '')
          : '';
      if (content.trim().isEmpty) {
        throw Exception('AI returned an empty response. Please try again.');
      }

      try {
        return jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start >= 0 && end > start) {
          final slice = content.substring(start, end + 1);
          return jsonDecode(slice) as Map<String, dynamic>;
        }
        return {
          'response': content.trim(),
          'corrections': null,
          'hints': null,
        };
      }
    }

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
          final contextTurns = messages.value
              .map((m) => {
                    'role': (m['sender'] == 'user') ? 'user' : 'assistant',
                    'content': (m['text'] ?? '').toString(),
                  })
              .toList();

          final result = await _generateDialogueTurnWithGroq(
            language: selectedLanguage.value.name,
            userMessage: userMessage['text'].toString(),
            contextTurns: contextTurns,
            role: selectedRole.value,
            difficultyLevel: difficulty.value,
          );

          final polieMessage = {
            'id': const Uuid().v4(),
            'text': (result['response'] ?? '').toString(),
            'sender': 'polie',
            'timestamp': DateTime.now(),
            'corrections': result['corrections'],
            'hints': result['hints'],
          };

          messages.value = [...messages.value, polieMessage];
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PolieColors.primary,
                PolieColors.primaryDark,
                PolieColors.obsidian,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header: back, title, language
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: PolieSpacing.xs),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_rounded, color: PolieColors.textPrimary),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Practice Dialogue',
                          style: PolieTypography.h2(context).copyWith(color: PolieColors.textPrimary),
                        ),
                      ),
                      PolieLanguagePill(
                        label: selectedLanguage.value.displayName,
                        isSelected: true,
                        accentColor: PolieColors.royalAmethyst,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => Container(
                              padding: EdgeInsets.all(PolieSpacing.lg),
                              decoration: BoxDecoration(
                                color: PolieColors.surfaceContainer,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(PolieRadius.xl)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Language', style: PolieTypography.h2(ctx)),
                                  SizedBox(height: PolieSpacing.md),
                                  ...availableLanguages.map((lang) => ListTile(
                                    title: Text(lang.displayName, style: PolieTypography.body(ctx)),
                                    onTap: () {
                                      selectedLanguage.value = lang;
                                      Navigator.pop(ctx);
                                    },
                                  )),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: PolieSpacing.xs),
                    ],
                  ),
                ),
                // Role selection chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md, vertical: PolieSpacing.xs),
                  child: Row(
                    children: kDialogueRoles.map((r) {
                      final id = r['id'] as String;
                      final isSelected = selectedRole.value == id;
                      return Padding(
                        padding: EdgeInsets.only(right: PolieSpacing.sm),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(r['icon'] as IconData, size: 16.sp, color: isSelected ? Colors.white : PolieColors.textSecondary),
                              SizedBox(width: PolieSpacing.xs),
                              Text(r['label'] as String, style: PolieTypography.label(context)),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (v) {
                            HapticFeedback.selectionClick();
                            selectedRole.value = id;
                          },
                          selectedColor: PolieColors.royalAmethyst,
                          checkmarkColor: Colors.white,
                          backgroundColor: PolieColors.surfaceGlassDark,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Tone / difficulty slider
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: PolieSpacing.lg),
                  child: Row(
                    children: [
                      Text('Easier', style: PolieTypography.bodySmall(context)),
                      Expanded(
                        child: Slider(
                          value: difficulty.value,
                          onChanged: (v) => difficulty.value = v,
                          activeColor: PolieColors.electricTeal,
                        ),
                      ),
                      Text('Harder', style: PolieTypography.bodySmall(context)),
                    ],
                  ),
                ),
                Expanded(
                  child: messages.value.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 64.sp, color: PolieColors.textSecondary),
                              SizedBox(height: PolieSpacing.md),
                              Text(
                                'Start a conversation with Polie',
                                style: PolieTypography.body(context),
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
                            return _DialogueMessageItem(message: message, isDark: isDark)
                                .animate(delay: (index * 50).ms)
                                .fadeIn(duration: 200.ms)
                                .slideX(begin: message['sender'] == 'user' ? 0.2 : -0.2);
                          },
                        ),
                ),
                PolieGlassCard(
                  padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md, vertical: PolieSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            border: InputBorder.none,
                            filled: false,
                          ),
                          style: PolieTypography.body(context),
                          onSubmitted: (_) => sendMessage(),
                        ),
                      ),
                      SizedBox(width: PolieSpacing.sm),
                      IconButton(
                        icon: isLoading.value
                            ? SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(PolieColors.electricTeal),
                                ),
                              )
                            : Icon(Icons.send_rounded, color: PolieColors.electricTeal),
                        onPressed: isLoading.value ? null : sendMessage,
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

/// Expression state for Polie avatar micro-expressions.
enum _PolieExpression { neutral, speaking, thinking, encouraging }

/// Single message row: AI avatar for Polie, PolieChatBubble, correction overlay, confidence nudges (hints).
class _DialogueMessageItem extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isDark;

  const _DialogueMessageItem({required this.message, required this.isDark});

  @override
  State<_DialogueMessageItem> createState() => _DialogueMessageItemState();
}

class _DialogueMessageItemState extends State<_DialogueMessageItem> {
  bool _hintsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message['sender'] == 'user';
    final text = widget.message['text']?.toString() ?? '';
    final corrections = widget.message['corrections'] as List?;
    final hints = widget.message['hints'] as List?;
    final hasHints = hints != null && hints.isNotEmpty;

    String? correctionText;
    if (corrections != null && corrections.isNotEmpty) {
      correctionText = corrections.map((c) {
        if (c is Map) return '${c['original']} → ${c['corrected']}';
        return c.toString();
      }).join(' • ');
    }

    final expression = !isUser
        ? (hasHints
            ? _PolieExpression.thinking
            : (correctionText != null && correctionText.isNotEmpty)
                ? _PolieExpression.encouraging
                : _PolieExpression.neutral)
        : _PolieExpression.neutral;

    return Padding(
      padding: EdgeInsets.only(bottom: PolieSpacing.sm),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _PolieAvatarAnimated(
                  expression: expression,
                  showGesture: true,
                ),
                SizedBox(width: PolieSpacing.sm),
              ],
              Flexible(
                child: PolieChatBubble(
                  text: text,
                  role: isUser ? PolieChatBubbleRole.user : PolieChatBubbleRole.assistant,
                  isCorrectionOverlay: correctionText != null && correctionText.isNotEmpty,
                  correctionText: correctionText,
                ),
              ),
              if (isUser) SizedBox(width: PolieSpacing.sm),
            ],
          ),
          if (hasHints)
            Padding(
              padding: EdgeInsets.only(top: PolieSpacing.xs, left: PolieSpacing.md, right: PolieSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _hintsExpanded = !_hintsExpanded);
                    },
                    child: PolieGlassCard(
                      padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: PolieSpacing.xs),
                      borderRadius: PolieRadius.sm,
                      child: Row(
                        children: [
                          Icon(
                            _hintsExpanded ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                            size: 16.sp,
                            color: PolieColors.goldEmber,
                          ),
                          SizedBox(width: PolieSpacing.xs),
                          Text(
                            _hintsExpanded ? 'Hide hint' : 'Need a hint?',
                            style: PolieTypography.label(context).copyWith(color: PolieColors.goldEmber),
                          ),
                          SizedBox(width: PolieSpacing.xs),
                          Icon(
                            _hintsExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 18.sp,
                            color: PolieColors.goldEmber,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_hintsExpanded)
                    Padding(
                      padding: EdgeInsets.only(top: PolieSpacing.xs),
                      child: PolieGlassCard(
                        padding: EdgeInsets.symmetric(horizontal: PolieSpacing.sm, vertical: PolieSpacing.xs),
                        borderRadius: PolieRadius.sm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (hints as List).map<Widget>((h) => Padding(
                            padding: EdgeInsets.only(bottom: PolieSpacing.xs),
                            child: Text(h.toString(), style: PolieTypography.bodySmall(context)),
                          )).toList(),
                        ),
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

/// Polie AI avatar with micro-expressions and cultural gesture animation.
class _PolieAvatarAnimated extends StatefulWidget {
  final _PolieExpression expression;
  final bool showGesture;

  const _PolieAvatarAnimated({
    required this.expression,
    this.showGesture = true,
  });

  @override
  State<_PolieAvatarAnimated> createState() => _PolieAvatarAnimatedState();
}

class _PolieAvatarAnimatedState extends State<_PolieAvatarAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _gestureController;
  bool _gesturePlayed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _gestureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.showGesture) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_gesturePlayed && mounted) {
          _gesturePlayed = true;
          _gestureController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _gestureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSpeaking = widget.expression == _PolieExpression.speaking;
    final isThinking = widget.expression == _PolieExpression.thinking;
    final isEncouraging = widget.expression == _PolieExpression.encouraging;

    return SizedBox(
      width: 44.w,
      height: 44.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 +
                  (isSpeaking ? 0.04 * _pulseController.value : 0.0) +
                  (isThinking ? 0.02 * (0.5 + 0.5 * _pulseController.value) : 0.0);
              return Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: isThinking ? 0.02 * (1 - 2 * _pulseController.value) : 0,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PolieColors.royalAmethyst,
                    PolieColors.electricTeal,
                  ],
                ),
                border: Border.all(
                  color: isEncouraging
                      ? PolieColors.goldEmber.withOpacity(0.8)
                      : PolieColors.goldEmber.withOpacity(0.5),
                  width: isEncouraging ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PolieColors.royalAmethyst.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _PolieFaceExpression(expression: widget.expression),
                ],
              ),
            ),
          ),
          if (widget.showGesture)
            Positioned(
              right: -4.w,
              bottom: -2.w,
              child: AnimatedBuilder(
                animation: _gestureController,
                builder: (context, child) {
                  final curve = Curves.easeOut.transform(_gestureController.value);
                  final opacity = curve < 0.5
                      ? curve * 2
                      : 2 * (1 - curve);
                  final rotate = curve * 0.4;
                  return Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: rotate,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  Icons.waving_hand_rounded,
                  color: PolieColors.goldEmber,
                  size: 18.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Face with simple eyes and mouth for micro-expressions.
class _PolieFaceExpression extends StatelessWidget {
  final _PolieExpression expression;

  const _PolieFaceExpression({required this.expression});

  @override
  Widget build(BuildContext context) {
    final isThinking = expression == _PolieExpression.thinking;
    final isEncouraging = expression == _PolieExpression.encouraging;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _eye(offset: isThinking ? -0.5 : 0),
            SizedBox(width: 6.w),
            _eye(offset: isThinking ? -0.5 : 0),
          ],
        ),
        SizedBox(height: 4.w),
        _mouth(smile: isEncouraging, open: expression == _PolieExpression.speaking),
      ],
    );
  }

  Widget _eye({double offset = 0}) {
    return Transform.translate(
      offset: Offset(0, offset),
      child: Container(
        width: 5.w,
        height: 5.w,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _mouth({bool smile = false, bool open = false}) {
    if (open) {
      return Container(
        width: 10.w,
        height: 4.w,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return Container(
      width: 8.w,
      height: 2.w,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(smile ? 0.95 : 0.8),
        borderRadius: BorderRadius.circular(1),
      ),
      transform: Matrix4.translationValues(0, smile ? -1 : 0, 0),
    );
  }
}


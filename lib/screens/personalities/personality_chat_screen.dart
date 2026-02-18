import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:lingafriq/providers/persona_providers.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/persona_cognition/persona_cognition_engine.dart';
import 'package:lingafriq/ai/persona_cognition/epistemic_classifier.dart';
import 'package:lingafriq/services/ai/historical_personality_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/services/monitoring/sentry_service.dart';
import 'package:lingafriq/providers/user_provider.dart';

class CognitionChatMessage {
  final String role;
  final String displayText;
  final PersonaCognitionResult? cognitionResult;
  final DateTime timestamp;

  const CognitionChatMessage({
    required this.role,
    required this.displayText,
    this.cognitionResult,
    required this.timestamp,
  });
}

class PersonalityChatScreen extends HookConsumerWidget {
  final HistoricalPersonality personality;

  const PersonalityChatScreen({
    super.key,
    required this.personality,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalityService = ref.read(historicalPersonalityServiceProvider);
    final user = ref.watch(userProvider);
    final messageController = useTextEditingController();
    final messages = useState<List<CognitionChatMessage>>([]);
    final isLoading = useState(false);
    final session = useState<PersonalityChatSession?>(null);
    final personaChat = ref.read(personaChatProvider.notifier);
    final tts = ref.read(personaTtsControllerProvider);

    useEffect(() {
      if (user?.id != null && session.value == null) {
        _initializeSession(
          context,
          personalityService,
          user!.id.toString(),
          session,
        );
      }
      personaChat.setPersona(personality.id);
      return null;
    }, [user?.id]);

    Future<void> sendMessage() async {
      if (messageController.text.trim().isEmpty || session.value == null) return;

      final userMessage = messageController.text.trim();
      messageController.clear();

      messages.value = [
        ...messages.value,
        CognitionChatMessage(
          role: 'user',
          displayText: userMessage,
          timestamp: DateTime.now(),
        ),
      ];

      try {
        isLoading.value = true;
        final enhancedPersona = HistoricalPersonaRegistry.findById(personality.id);

        if (enhancedPersona != null) {
          final result = await personaChat.sendMessage(
            userMessage,
            learnerId: user?.id.toString(),
            languageCode: 'en',
          );
          if (result != null && context.mounted) {
            messages.value = [
              ...messages.value,
              CognitionChatMessage(
                role: 'persona',
                displayText: result.personaReply,
                cognitionResult: result,
                timestamp: DateTime.now(),
              ),
            ];
          } else if (context.mounted) {
            final err = ref.read(personaChatProvider).error;
            if (err != null) ErrorHandler.showError(context, Exception(err));
          }
        } else {
          final response = await personalityService.sendMessage(
            sessionId: session.value!.sessionId,
            message: userMessage,
          );
          messages.value = [
            ...messages.value,
            CognitionChatMessage(
              role: 'persona',
              displayText: response.content,
              timestamp: DateTime.now(),
            ),
          ];
          if (response.content.trim().isNotEmpty) {
            tts.speak(response.content);
          }
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
        SentryService().captureException(
          e,
          context: {
            'screen': 'PersonalityChatScreen',
            'action': 'sendMessage',
            'personality': personality.id,
          },
        );
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(personality.name),
            Text(
              personality.country,
              style: PanAfricanTypography.labelMedium(context),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.stop_circle_outlined),
            onPressed: isLoading.value ? null : () => personaChat.interrupt(),
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              _showPersonalityInfo(context, personality);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.value.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: PanAfricanSpacing.md),
                        Text(
                          'Start a conversation with ${personality.name}',
                          style: PanAfricanTypography.bodyLarge(context),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: PanAfricanSpacing.sm),
                        Text(
                          personality.biography,
                          style: PanAfricanTypography.bodyMedium(context),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    itemCount: messages.value.length,
                    itemBuilder: (context, index) {
                      final message = messages.value[index];
                      return _MessageBubble(
                        message: message,
                        isUser: message.role == 'user',
                        personalityName: personality.name,
                        onReplay: message.role == 'persona'
                            ? () => tts.speak(message.displayText)
                            : null,
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
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
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                IconButton(
                  icon: isLoading.value
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send),
                  onPressed: isLoading.value ? null : sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeSession(
    BuildContext context,
    HistoricalPersonalityService service,
    String userId,
    ValueNotifier<PersonalityChatSession?> session,
  ) async {
    try {
      final newSession = await service.startChatSession(
        personalityId: personality.id,
        userId: userId,
      );
      session.value = newSession;
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, e);
      }
      SentryService().captureException(
        e,
        context: {
          'screen': 'PersonalityChatScreen',
          'action': 'initializeSession',
          'personality': personality.id,
        },
      );
    }
  }

  void _showPersonalityInfo(
    BuildContext context,
    HistoricalPersonality personality,
  ) {
    final enhanced = HistoricalPersonaRegistry.findById(personality.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(personality.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (enhanced != null) ...[
                Text(
                  '${enhanced.region} • ${enhanced.primaryLanguages.join(", ")}',
                  style: PanAfricanTypography.labelMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.xs),
                Text(
                  enhanced.shortBio,
                  style: PanAfricanTypography.bodyMedium(context),
                ),
                if (enhanced.coreEvents.isNotEmpty) ...[
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    'Key events',
                    style: PanAfricanTypography.labelLarge(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...enhanced.coreEvents.take(3).map(
                        (e) => Padding(
                          padding: EdgeInsets.only(
                            left: PanAfricanSpacing.md,
                            top: PanAfricanSpacing.xs,
                          ),
                          child: Text(
                            '${e.year}: ${e.event}',
                            style: PanAfricanTypography.bodySmall(context),
                          ),
                        ),
                      ),
                ],
              ] else ...[
                Text('${personality.country} • ${personality.language}'),
                if (personality.birthDate != null || personality.deathDate != null)
                  Text('${personality.birthDate ?? ''} - ${personality.deathDate ?? ''}'),
                SizedBox(height: PanAfricanSpacing.md),
                Text(
                  personality.biography,
                  style: PanAfricanTypography.bodyMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Text(
                  'Key Achievements:',
                  style: PanAfricanTypography.labelLarge(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...personality.achievements.map(
                  (a) => Padding(
                    padding: EdgeInsets.only(
                      left: PanAfricanSpacing.md,
                      top: 4,
                    ),
                    child: Text(
                      '• $a',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final CognitionChatMessage message;
  final bool isUser;
  final String personalityName;
  final VoidCallback? onReplay;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.personalityName,
    this.onReplay,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _citationsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.message.cognitionResult;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: widget.isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isUser) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.personalityName,
                      style: PanAfricanTypography.labelSmall(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (result != null) ...[
                    _EpistemicBadge(status: result.epistemicStatus),
                    SizedBox(width: PanAfricanSpacing.xs),
                    Opacity(
                      opacity: 0.5 + result.confidence * 0.5,
                      child: Icon(Icons.circle, size: 8, color: colorScheme.primary),
                    ),
                  ],
                  if (widget.onReplay != null)
                    IconButton(
                      icon: Icon(Icons.volume_up, size: 20),
                      onPressed: widget.onReplay,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
              SizedBox(height: PanAfricanSpacing.xs),
            ],
            Text(
              widget.message.displayText,
              style: PanAfricanTypography.bodyMedium(context),
            ),
            if (result != null) ...[
              if (result.languageFeedback.isNotEmpty) ...[
                SizedBox(height: PanAfricanSpacing.sm),
                Wrap(
                  spacing: PanAfricanSpacing.xs,
                  runSpacing: PanAfricanSpacing.xs,
                  children: result.languageFeedback
                      .map(
                        (tp) => Chip(
                          label: Text(
                            '${tp.type}: ${tp.note}',
                            style: PanAfricanTypography.labelSmall(context),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: PanAfricanSpacing.xs,
                            vertical: 2,
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (result.culturalNote != null &&
                  result.culturalNote!.isNotEmpty) ...[
                SizedBox(height: PanAfricanSpacing.sm),
                Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: colorScheme.tertiary,
                      ),
                      SizedBox(width: PanAfricanSpacing.xs),
                      Expanded(
                        child: Text(
                          result.culturalNote!,
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (result.citations.isNotEmpty) ...[
                SizedBox(height: PanAfricanSpacing.sm),
                InkWell(
                  onTap: () =>
                      setState(() => _citationsExpanded = !_citationsExpanded),
                  borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.xs),
                    child: Row(
                      children: [
                        Icon(
                          _citationsExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 20,
                        ),
                        SizedBox(width: PanAfricanSpacing.xs),
                        Text(
                          'Sources (${result.citations.length})',
                          style: PanAfricanTypography.labelSmall(context),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_citationsExpanded)
                  ...result.citations.map(
                    (c) => Padding(
                      padding: EdgeInsets.only(
                        left: PanAfricanSpacing.md,
                        top: PanAfricanSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.source,
                            style: PanAfricanTypography.labelSmall(context)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            c.relevance,
                            style: PanAfricanTypography.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              _formatTime(widget.message.timestamp),
              style: PanAfricanTypography.bodySmall(context).copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _EpistemicBadge extends StatelessWidget {
  final EpistemicStatus status;

  const _EpistemicBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      EpistemicStatus.documented => ('Documented', Colors.green),
      EpistemicStatus.inferred => ('Inferred', Colors.amber),
      EpistemicStatus.uncertain => ('Uncertain', Colors.red),
      EpistemicStatus.anachronistic => ('Anachronistic', colorScheme.error),
      EpistemicStatus.outOfScope => ('Out of scope', colorScheme.outline),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
      ),
      child: Text(
        label,
        style: PanAfricanTypography.labelSmall(context).copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }
}

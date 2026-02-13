/// Historical Personality Chat Screen
/// Chat with historical African personalities
/// 
/// Production-ready implementation (December 2025)

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/ai/historical_personality_service.dart';
import '../../utils/pan_african_design_system.dart';
import '../../utils/error_handler.dart';
import '../../services/monitoring/sentry_service.dart';
import '../../providers/user_provider.dart';

class PersonalityChatScreen extends HookConsumerWidget {
  final HistoricalPersonality personality;

  const PersonalityChatScreen({
    Key? key,
    required this.personality,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalityService = ref.read(historicalPersonalityServiceProvider);
    final user = ref.watch(userProvider);
    final messageController = useTextEditingController();
    final messages = useState<List<PersonalityMessage>>([]);
    final isLoading = useState(false);
    final session = useState<PersonalityChatSession?>(null);

    // Initialize chat session
    useEffect(() {
      if (user?.id != null && session.value == null) {
        _initializeSession(
          context,
          personalityService,
          user!.id.toString(),
          session,
        );
      }
      return null;
    }, [user?.id]);

    Future<void> sendMessage() async {
      if (messageController.text.trim().isEmpty || session.value == null) return;

      final userMessage = messageController.text.trim();
      messageController.clear();

      // Add user message to UI
      messages.value = [
        ...messages.value,
        PersonalityMessage(
          role: 'user',
          content: userMessage,
          timestamp: DateTime.now(),
        ),
      ];

      try {
        isLoading.value = true;
        final response = await personalityService.sendMessage(
          sessionId: session.value!.sessionId,
          message: userMessage,
        );

        // Add personality response
        messages.value = [
          ...messages.value,
          response,
        ];
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
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
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
          // Messages
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
                      );
                    },
                  ),
          ),
          // Input
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

  void _showPersonalityInfo(BuildContext context, HistoricalPersonality personality) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(personality.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              ...personality.achievements.map((a) => Padding(
                    padding: EdgeInsets.only(left: PanAfricanSpacing.md, top: 4),
                    child: Text('• $a', style: PanAfricanTypography.bodySmall(context)),
                  )),
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

/// Message Bubble Widget
class _MessageBubble extends StatelessWidget {
  final PersonalityMessage message;
  final bool isUser;
  final String personalityName;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.personalityName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Text(
                personalityName,
                style: PanAfricanTypography.labelSmall(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              message.content,
              style: PanAfricanTypography.bodyMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              _formatTime(message.timestamp),
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


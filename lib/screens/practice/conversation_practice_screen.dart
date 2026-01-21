import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/conversation/conversation_practice_service.dart';
import '../../services/conversation/dialogue_flow_generator.dart';
import '../../models/lesson_item_model.dart';
import '../../providers/dio_provider.dart';
import 'package:dio/dio.dart';
import '../../widgets/global/error_recovery_widget.dart';
import '../../widgets/global/offline_banner.dart';
import '../../utils/screen_integration_helper.dart';
import '../../widgets/error_boundary.dart';

class ConversationPracticeScreen extends ConsumerStatefulWidget {
  final String languageCode;
  final String level;
  final String? personality;

  const ConversationPracticeScreen({
    Key? key,
    required this.languageCode,
    required this.level,
    this.personality,
  }) : super(key: key);

  @override
  ConsumerState<ConversationPracticeScreen> createState() => _ConversationPracticeScreenState();
}

class _ConversationPracticeScreenState extends ConsumerState<ConversationPracticeScreen>
    with PerformanceScreenMixin {
  late ConversationPracticeService _conversationService;
  ConversationSession? _session;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Note: initState doesn't have access to ref, so we'll initialize in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final dioClient = ref.read(client);
      _conversationService = ConversationPracticeService(dioClient);
      _isInitialized = true;
      _startSession();
    }
  }

  bool _isInitialized = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_session != null) {
      _conversationService.endSession(_session!.id);
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final session = await _conversationService.startSession(
        languageCode: widget.languageCode,
        level: widget.level,
        personality: widget.personality,
        flowType: DialogueFlowType.greeting,
      );

      setState(() {
        _session = session;
        _messages.clear();
        _messages.addAll(_conversationService.getConversationHistory(session.id));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _session == null) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _conversationService.sendMessage(
        sessionId: _session!.id,
        message: message,
      );

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OfflineBanner(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Conversation Practice - ${widget.languageCode.toUpperCase()}'),
          actions: [
            if (_session != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _startSession,
                tooltip: 'Start New Conversation',
              ),
          ],
        ),
        body: ErrorBoundary(
          errorMessage: _error,
          onRetry: _startSession,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final message = _messages[index];
              final isUser = message['role'] == 'user';

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: isUser ? Theme.of(context).primaryColor : Colors.grey[300],
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['content'] as String,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      if (message['timestamp'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            _formatTime(message['timestamp'] as DateTime),
                            style: TextStyle(
                              color: isUser ? Colors.white70 : Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
              color: Theme.of(context).primaryColor,
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}


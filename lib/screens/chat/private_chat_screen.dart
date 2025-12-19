import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lingafriq/models/private_chat_contact.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/chat_socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/audio_player_widget.dart';

class PrivateChatScreen extends ConsumerStatefulWidget {
  final PrivateChatContact contact;

  const PrivateChatScreen({super.key, required this.contact});

  @override
  ConsumerState<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends ConsumerState<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String _roomId;
  bool _socketInitialized = false;
  Map<String, dynamic>? _replyToMessage;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(userProvider);
    _roomId = currentUser == null
        ? ''
        : _buildRoomId(currentUser.id, widget.contact.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocket();
    });
  }

  @override
  void dispose() {
    final socket = ref.read(socketProvider.notifier);
    if (_roomId.isNotEmpty) {
      socket.leaveRoom(_roomId);
      socket.setActiveRoom('general');
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeSocket() {
    if (_socketInitialized || _roomId.isEmpty) return;
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;
    final socket = ref.read(socketProvider.notifier);
    if (!socket.isConnected) {
      socket.connect(currentUser.id.toString(), currentUser.username);
    }
    socket.joinRoom(_roomId);
    socket.setActiveRoom(_roomId);
    _socketInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Private Chat')),
        body: const Center(
          child: Text('Please sign in to chat with other learners.'),
        ),
      );
    }

    ref.watch(socketProvider);
    final socket = ref.read(socketProvider.notifier);
    final messages = _roomId.isEmpty
        ? const <Map<String, dynamic>>[]
        : socket.messagesForRoom(_roomId);
    final isConnected = socket.isConnected;
    final isPartnerOnline = socket.onlineUsers.any(
      (user) => user['userId']?.toString() == widget.contact.id.toString(),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryGreen,
              child: Text(
                widget.contact.username.isNotEmpty
                    ? widget.contact.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contact.username,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: isPartnerOnline ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPartnerOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isPartnerOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.lock_outline, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.08),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Messages are protected with secure encryption in transit. End-to-end encryption is on our roadmap.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primaryGreen.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Say hello to ${widget.contact.username} 👋',
                      style: TextStyle(color: context.adaptive54),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe =
                          message['userId'] == currentUser.id.toString();
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),
          _buildInput(isConnected && _roomId.isNotEmpty, currentUser),
        ],
      ),
    );
  }

  Widget _buildInput(bool canSend, ProfileModel currentUser) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1F3527) : Colors.white,
        border: Border(
          top: BorderSide(
            color: context.isDarkMode
                ? const Color(0xFF2A4A35)
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyToMessage != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? const Color(0xFF102216)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _replyToMessage?['message'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.adaptive54,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _replyToMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: canSend ? () => _pickAndSendMedia(currentUser) : null,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: canSend,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: canSend
                        ? 'Message ${widget.contact.username}...'
                        : 'Connecting...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: context.isDarkMode
                        ? const Color(0xFF102216)
                        : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: canSend ? () => _sendMessage(currentUser) : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isMe) {
    final timestamp = message['timestamp']?.toString();
    final status = message['status']?.toString();
    final reactions = (message['reactions'] as List?) ?? const [];
    final isPolie = message['isPolie'] == true ||
        (message['username']?.toString().toLowerCase() == 'polie');
    final messageType = message['messageType']?.toString() ?? 'text';
    final fileUrl = message['fileUrl']?.toString();
    final messageType = message['messageType']?.toString() ?? 'text';
    final fileUrl = message['fileUrl']?.toString();
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(context, message, isMe),
        child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isMe || isPolie
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00A86B),
                    Color(0xFF00A8E8),
                  ],
                )
              : null,
          color: isMe || isPolie
              ? null
              : (context.isDarkMode ? const Color(0xFF2A4A35) : Colors.white),
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
          border: isMe
              ? null
              : Border.all(
                  color: context.isDarkMode
                      ? const Color(0xFF365640)
                      : Colors.grey.shade200,
                ),
          boxShadow: [
            BoxShadow(
              color: (isMe || isPolie ? AppColors.primaryGreen : Colors.black)
                  .withOpacity(isMe || isPolie ? 0.35 : 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message['replyToMessage'] != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe || isPolie
                      ? Colors.white.withOpacity(0.12)
                      : (context.isDarkMode
                          ? const Color(0xFF163424)
                          : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message['replyToMessage'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontStyle: FontStyle.italic,
                    color: isMe || isPolie
                        ? Colors.white.withOpacity(0.9)
                        : context.adaptive54,
                  ),
                ),
              ),
            if (!isMe && isPolie)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.smart_toy_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Polie',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            if (messageType == 'image' &&
                fileUrl != null &&
                fileUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  fileUrl,
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
              )
            else
            if (messageType == 'image' &&
                fileUrl != null &&
                fileUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  fileUrl,
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
              )
            else if (messageType == 'audio' &&
                fileUrl != null &&
                fileUrl.isNotEmpty)
              AudioPlayerWidget(audioUrl: fileUrl)
            else
              Text(
                message['message'] ?? '',
                style: TextStyle(
                  color: isMe || isPolie ? Colors.white : context.adaptive,
                  fontSize: 15.sp,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    color: (isMe ? Colors.white70 : context.adaptive54),
                    fontSize: 10.sp,
                  ),
                ),
                if (isMe && status != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    status == 'sending'
                        ? Icons.access_time
                        : Icons.done_all_rounded,
                    size: 12.sp,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
            if (reactions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 2,
                children: reactions
                    .map<Widget>((r) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            r['emoji']?.toString() ?? '❤️',
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    ));
  }

  void _sendMessage(ProfileModel currentUser) {
    final text = _messageController.text.trim();
    if (text.isEmpty || _roomId.isEmpty) return;
    final socket = ref.read(socketProvider.notifier);
    final replyToId = _replyToMessage?['id']?.toString();
    socket.sendMessage(
      _roomId,
      text,
      currentUser.id.toString(),
      currentUser.username,
      chatType: 'private',
      recipientId: widget.contact.id.toString(),
      replyTo: replyToId,
    );
    _messageController.clear();
    setState(() {
      _replyToMessage = null;
    });
    _scrollToBottom();

    // Optional: allow @Polie mention inside private chats as a personal assistant.
    if (text.toLowerCase().contains('@polie')) {
      _invokePolieAssistant(text);
    }
  }

  Future<void> _pickAndSendMedia(ProfileModel currentUser) async {
    if (_roomId.isEmpty) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp3', 'wav', 'm4a'],
      );
      if (result == null || result.files.single.path == null) return;

      final path = result.files.single.path!;
      final ext = (result.files.single.extension ?? '').toLowerCase();
      final file = File(path);
      final fileName = result.files.single.name;

      final api = ref.read(apiProvider.notifier);
      final media = await api.uploadMedia(
        filePath: file.path,
        fileName: fileName,
        title: fileName,
        description: 'Shared in private chat',
      );

      final fileUrl =
          (media['file_url'] ?? media['fileUrl'] ?? '').toString();
      if (fileUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to share media right now.'),
            ),
          );
        }
        return;
      }

      final isAudio = ['mp3', 'wav', 'm4a'].contains(ext);
      final socket = ref.read(socketProvider.notifier);
      final replyToId = _replyToMessage?['id']?.toString();

      socket.sendMessage(
        _roomId,
        isAudio ? 'Voice note' : '',
        currentUser.id.toString(),
        currentUser.username,
        chatType: 'private',
        recipientId: widget.contact.id.toString(),
        replyTo: replyToId,
        messageType: isAudio ? 'audio' : 'image',
        fileUrl: fileUrl,
      );

      setState(() {
        _replyToMessage = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing media: $e'),
        ),
      );
    }
  }

  void _showMessageActions(
    BuildContext context,
    Map<String, dynamic> message,
    bool isMe,
  ) {
    final messageId = message['id']?.toString();
    final senderId = message['userId']?.toString();
    if (messageId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _replyToMessage = message;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions_outlined),
                title: const Text('Add reaction'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReactionPicker(context, messageId);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(context, messageId, message['message'] ?? '');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report message'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await ref
                      .read(apiProvider.notifier)
                      .reportChatMessage(messageId: messageId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Message reported'
                          : 'Unable to report message right now'),
                    ),
                  );
                },
              ),
              if (!isMe && senderId != null && senderId.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Block user'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(apiProvider.notifier).blockUser(senderId);
                      ref
                          .read(socketProvider.notifier)
                          .markUserBlocked(senderId);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User blocked. You will no longer see messages from them.'),
                        ),
                      );
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to block user right now.'),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showReactionPicker(BuildContext context, String messageId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['👍', '❤️', '🔥', '👏', '🤔'].map((emoji) {
            return IconButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(socketProvider.notifier).reactToMessage(messageId, emoji);
              },
              icon: Text(emoji, style: TextStyle(fontSize: 24.sp)),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String messageId,
    String currentText,
  ) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty && newText != currentText) {
                ref.read(socketProvider.notifier).editMessage(messageId, newText);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _invokePolieAssistant(String rawText) async {
    final query = rawText.replaceAll(RegExp(r'@polie', caseSensitive: false), '').trim();
    final effectiveQuery = query.isEmpty ? rawText : query;

    try {
      final polie = ref.read(groqChatProvider.notifier);
      await polie.setMode(PolieMode.conversation);
      final response = await polie.sendMessage(effectiveQuery);

      ref.read(socketProvider.notifier).addLocalPolieMessage(
            _roomId,
            response,
          );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Polie is unavailable right now: $e'),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  String _buildRoomId(int a, int b) {
    final ids = [a, b]..sort();
    return 'private_${ids[0]}_${ids[1]}';
  }
}


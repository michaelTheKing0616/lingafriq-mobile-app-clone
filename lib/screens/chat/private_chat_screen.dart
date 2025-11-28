import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/private_chat_contact.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';

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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.lock_outline, size: 20),
          )
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
                    'Messages are end-to-end encrypted. Only you and ${widget.contact.username} can read them.',
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
      child: Row(
        children: [
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isMe) {
    final timestamp = message['timestamp']?.toString();
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primaryGreen
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
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['message'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : context.adaptive,
                fontSize: 15.sp,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(timestamp),
              style: TextStyle(
                color: (isMe ? Colors.white70 : context.adaptive54),
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(ProfileModel currentUser) {
    final text = _messageController.text.trim();
    if (text.isEmpty || _roomId.isEmpty) return;
    final socket = ref.read(socketProvider.notifier);
    socket.sendMessage(
      _roomId,
      text,
      currentUser.id.toString(),
      currentUser.username,
    );
    _messageController.clear();
    _scrollToBottom();
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


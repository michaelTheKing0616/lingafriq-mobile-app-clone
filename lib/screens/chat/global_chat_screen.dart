import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lingafriq/providers/chat_socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/screens/chat/chat_search_screen.dart';
import 'package:lingafriq/widgets/audio_player_widget.dart';

class GlobalChatScreen extends ConsumerStatefulWidget {
  final String? language;
  
  const GlobalChatScreen({Key? key, this.language}) : super(key: key);

  @override
  ConsumerState<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends ConsumerState<GlobalChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedRoom = 'general';
  Map<String, dynamic>? _replyToMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocket();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    ref.read(socketProvider.notifier).leaveRoom(_selectedRoom);
    super.dispose();
  }

  void _initializeSocket() {
    try {
      final user = ref.read(userProvider);
      if (user != null) {
        final socket = ref.read(socketProvider.notifier);
        socket.connect(
          user.id.toString(),
          user.username,
        );
        socket.joinRoom(_selectedRoom);
        socket.setActiveRoom(_selectedRoom);
      }
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'Global Chat is temporarily unavailable',
      onRetry: () {
        setState(() {});
        _initializeSocket();
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    ref.watch(socketProvider);
    final socketNotifier = ref.read(socketProvider.notifier);
    final messages = socketNotifier.messages;
    final onlineUsers = socketNotifier.onlineUsers;
    final isConnected = socketNotifier.isConnected;
    final user = ref.watch(userProvider);
    final isDark = context.isDarkMode;

    // Ensure socket is initialized if user is available
    if (user != null && !isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeSocket();
      });
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF007A3D), // Green
                  Color(0xFF00A8E8), // Blue
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community Chat',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (isConnected)
                            Text(
                              '${onlineUsers.length} learners online',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 1.w),
                          Text(
                            '${onlineUsers.length}',
                            style: TextStyle(color: Colors.white, fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 1.w),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatSearchScreen(
                              room: _selectedRoom,
                              type: 'global',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Messages Area
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
              child: Column(
                children: [
                  // Room selector
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    color: isDark ? const Color(0xFF1F3527) : Colors.white,
                    child: Row(
                      children: [
                        PopupMenuButton<String>(
                          icon: Icon(Icons.language, color: isDark ? Colors.white : Colors.black87),
                          onSelected: (room) {
                            if (_selectedRoom == room) return;
                            final socket = ref.read(socketProvider.notifier);
                            socket.leaveRoom(_selectedRoom);
                            setState(() {
                              _selectedRoom = room;
                            });
                            socket.joinRoom(room);
                            socket.setActiveRoom(room);
                            _scrollToBottom();
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'general', child: Text('General')),
                            const PopupMenuItem(value: 'yoruba', child: Text('Yoruba')),
                            const PopupMenuItem(value: 'hausa', child: Text('Hausa')),
                            const PopupMenuItem(value: 'swahili', child: Text('Swahili')),
                            const PopupMenuItem(value: 'igbo', child: Text('Igbo')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Online Users Bar
                  if (isConnected && onlineUsers.isNotEmpty)
                    Container(
                      height: 60.sp,
                      color: isDark ? const Color(0xFF1F3527) : Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16.sp),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: onlineUsers.length,
                        itemBuilder: (context, index) {
                          final onlineUser = onlineUsers[index];
                          return Container(
                            margin: EdgeInsets.only(right: 8.sp),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 18.sp,
                                  backgroundColor: AppColors.primaryGreen,
                                  child: Text(
                                    (onlineUser['username'] as String? ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4.sp),
                                Container(
                                  width: 8.sp,
                                  height: 8.sp,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // Messages
                  Expanded(
                    child: user == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_off,
                                  size: 64.sp,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                ),
                                SizedBox(height: 16.sp),
                                Text(
                                  'Please log in to use chat',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 64.sp,
                                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                                    ),
                                    SizedBox(height: 16.sp),
                                    Text(
                                      isConnected
                                          ? 'No messages yet. Start the conversation!'
                                          : 'Connecting...',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.all(16.sp),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  final isMe = message['userId'] == user.id.toString();
                                  return _buildMessageBubble(context, message, isMe, isDark);
                                },
                              ),
                  ),
                  
                  // Input Area - Figma Make Style
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6)).withOpacity(0),
                          (isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6)),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.attach_file,
                              color: Colors.white.withOpacity(0.9), size: 20.sp),
                          onPressed: user != null && isConnected
                              ? () => _pickAndSendMedia(user)
                              : null,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F3527) : Colors.white,
                              borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                              boxShadow: DesignSystem.shadowMedium,
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                                filled: false,
                              ),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: null,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF007A3D), Color(0xFF00A8E8)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: DesignSystem.shadowMedium,
                          ),
                          child: IconButton(
                            onPressed: user != null && isConnected && _messageController.text.isNotEmpty
                                ? () => _handleSendMessage(user)
                                : null,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage(ProfileModel user) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final socket = ref.read(socketProvider.notifier);
    final replyToId = _replyToMessage?['id']?.toString();

    socket.sendMessage(
      _selectedRoom,
      text,
      user.id.toString(),
      user.username,
      chatType: 'global',
      replyTo: replyToId,
    );
    _messageController.clear();
    setState(() {
      _replyToMessage = null;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // If user mentions @Polie, invoke Polie as an in-chat assistant.
    if (text.toLowerCase().contains('@polie')) {
      _invokePolieAssistant(text);
    }
  }

  Future<void> _pickAndSendMedia(ProfileModel user) async {
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
        description: 'Shared from global chat',
        language: _selectedRoom,
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
        _selectedRoom,
        isAudio ? 'Voice note' : '',
        user.id.toString(),
        user.username,
        chatType: 'global',
        messageType: isAudio ? 'audio' : 'image',
        replyTo: replyToId,
        fileUrl: fileUrl,
      );

      setState(() {
        _replyToMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing media: $e'),
        ),
      );
    }
  }

  Future<void> _invokePolieAssistant(String rawText) async {
    final query = rawText.replaceAll(RegExp(r'@polie', caseSensitive: false), '').trim();
    final effectiveQuery = query.isEmpty ? rawText : query;

    try {
      final polie = ref.read(groqChatProvider.notifier);
      await polie.setMode(PolieMode.conversation);
      final response = await polie.sendMessage(effectiveQuery);

      ref.read(socketProvider.notifier).addLocalPolieMessage(
            _selectedRoom,
            response,
          );
      // Auto-scroll to show Polie's reply
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

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> message,
    bool isMe,
    bool isDark,
  ) {
    final isPolie = message['isPolie'] == true ||
        (message['username']?.toString().toLowerCase() == 'polie');
    final flaggedToxic = message['flaggedToxic'] == true;
    final messageType = message['messageType']?.toString() ?? 'text';
    final fileUrl = message['fileUrl']?.toString();
    final status = message['status']?.toString();
    final reactions = (message['reactions'] as List?) ?? const [];
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(context, message, isMe),
        child: Container(
        margin: EdgeInsets.only(bottom: 12.sp),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
        decoration: BoxDecoration(
          // Futuristic Pan-African bubbles with soft glow
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
              : (isDark ? const Color(0xFF2A4A35) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? Radius.circular(4) : null,
            bottomLeft: !isMe ? Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: (isMe || isPolie ? AppColors.primaryGreen : Colors.black)
                  .withOpacity(isMe || isPolie ? 0.35 : 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message['replyToMessage'] != null)
              Container(
                margin: EdgeInsets.only(bottom: 4.sp),
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  color: isMe || isPolie
                      ? Colors.white.withOpacity(0.12)
                      : (isDark ? const Color(0xFF163424) : Colors.grey[300]),
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
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            if (!isMe)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPolie)
                    const Icon(
                      Icons.smart_toy_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  if (isPolie) SizedBox(width: 1.w),
                  Text(
                    message['username'] ?? (isPolie ? 'Polie' : 'Anonymous'),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isMe || isPolie ? Colors.white : AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            if (!isMe) SizedBox(height: 4.sp),
            if (messageType == 'image' &&
                fileUrl != null &&
                fileUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
                  fontSize: 14.sp,
                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  decoration: flaggedToxic
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationStyle: flaggedToxic
                      ? TextDecorationStyle.dashed
                      : TextDecorationStyle.solid,
                ),
              ),
            SizedBox(height: 4.sp),
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  _formatTime(message['timestamp']),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                if (isMe && status != null) ...[
                  SizedBox(width: 4.sp),
                  Icon(
                    status == 'sending'
                        ? Icons.access_time
                        : Icons.done_all_rounded,
                    size: 12.sp,
                    color: Colors.white.withOpacity(
                      status == 'sending' ? 0.7 : 1.0,
                    ),
                  ),
                ],
              ],
            ),
            if (reactions.isNotEmpty) ...[
              SizedBox(height: 4.sp),
              Wrap(
                spacing: 2.sp,
                children: reactions
                    .map<Widget>((r) => Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.sp, vertical: 2.sp),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
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

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
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
}


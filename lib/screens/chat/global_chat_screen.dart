import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(socketProvider);
    final socketNotifier = ref.read(socketProvider.notifier);
    final messages = socketNotifier.messages;
    final onlineUsers = socketNotifier.onlineUsers;
    final isConnected = socketNotifier.isConnected;
    final user = ref.watch(userProvider);
    final isDark = context.isDarkMode;

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
                    child: messages.isEmpty
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
                              final isMe = message['userId'] == user?.id.toString();
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
                            onPressed: isConnected && _messageController.text.isNotEmpty
                                ? () {
                                    ref.read(socketProvider.notifier).sendMessage(
                                      _selectedRoom,
                                      _messageController.text,
                                      user?.id.toString() ?? '',
                                      user?.username ?? 'Anonymous',
                                    );
                                    _messageController.clear();
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      if (_scrollController.hasClients) {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    });
                                  }
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

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> message,
    bool isMe,
    bool isDark,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.sp),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primaryGreen
              : (isDark ? const Color(0xFF2A4A35) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? Radius.circular(4) : null,
            bottomLeft: !isMe ? Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message['username'] ?? 'Anonymous',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: isMe ? Colors.white : AppColors.primaryGreen,
                ),
              ),
            if (!isMe) SizedBox(height: 4.sp),
            Text(
              message['message'] ?? '',
              style: TextStyle(
                fontSize: 14.sp,
                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            SizedBox(height: 4.sp),
            Text(
              _formatTime(message['timestamp']),
              style: TextStyle(
                fontSize: 10.sp,
                color: isMe
                    ? Colors.white.withOpacity(0.7)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
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


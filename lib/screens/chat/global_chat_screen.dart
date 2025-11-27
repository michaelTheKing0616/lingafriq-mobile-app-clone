import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
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
    ref.read(socketProvider.notifier).disconnect();
    super.dispose();
  }

  void _initializeSocket() {
    final user = ref.read(userProvider);
    if (user != null) {
      ref.read(socketProvider.notifier).connect(
        user.id.toString(),
        user.username,
      );
      ref.read(socketProvider.notifier).joinRoom(_selectedRoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final socketNotifier = ref.watch(socketProvider.notifier);
    final messages = ref.watch(socketProvider.notifier).messages;
    final onlineUsers = ref.watch(socketProvider.notifier).onlineUsers;
    final isConnected = ref.watch(socketProvider.notifier).isConnected;
    final user = ref.watch(userProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedRoom == 'general' ? 'Global Chat' : '${_selectedRoom.toUpperCase()} Chat',
              style: TextStyle(fontSize: 18.sp),
            ),
            if (isConnected)
              Text(
                '${onlineUsers.length} online',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.green,
                ),
              ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.language, color: isDark ? Colors.white : Colors.black87),
            onSelected: (room) {
              setState(() {
                _selectedRoom = room;
              });
              ref.read(socketProvider.notifier).leaveRoom(_selectedRoom);
              ref.read(socketProvider.notifier).joinRoom(room);
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
      body: Column(
        children: [
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
                          decoration: BoxDecoration(
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
          
          // Input Area
          Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F3527) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.sp,
                        vertical: 12.sp,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8.sp),
                IconButton(
                  onPressed: isConnected && _messageController.text.isNotEmpty
                      ? () {
                          ref.read(socketProvider.notifier).sendMessage(
                            _selectedRoom,
                            _messageController.text,
                            user?.id.toString() ?? '',
                            user?.username ?? 'Anonymous',
                          );
                          _messageController.clear();
                          Future.delayed(Duration(milliseconds: 100), () {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });
                        }
                      : null,
                  icon: Icon(
                    Icons.send_rounded,
                    color: isConnected && _messageController.text.isNotEmpty
                        ? AppColors.primaryGreen
                        : (isDark ? Colors.grey[600] : Colors.grey[400]),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isConnected && _messageController.text.isNotEmpty
                        ? AppColors.primaryGreen.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                ),
              ],
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
}


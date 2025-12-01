import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/screens/chat/global_chat_screen.dart';
import 'package:lingafriq/screens/chat/private_chat_list_screen.dart';
import 'package:lingafriq/screens/chat/private_chat_screen.dart';
import 'package:lingafriq/models/private_chat_contact.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserConnectionsScreen extends ConsumerStatefulWidget {
  const UserConnectionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserConnectionsScreen> createState() => _UserConnectionsScreenState();
}

class _UserConnectionsScreenState extends ConsumerState<UserConnectionsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocket();
    });
  }

  void _initializeSocket() {
    final user = ref.read(userProvider);
    if (user != null) {
      ref.read(socketProvider.notifier).connect(
        user.id.toString(),
        user.username,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'User connections are temporarily unavailable',
      onRetry: () {
        setState(() {});
        _initializeSocket();
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final onlineUsers = ref.watch(socketProvider.notifier).onlineUsers;
    final isConnected = ref.watch(socketProvider.notifier).isConnected;
    final currentUser = ref.watch(userProvider);
    final isDark = context.isDarkMode;

    final filteredUsers = onlineUsers.where((user) {
      if (_searchQuery.isEmpty) return true;
      final username = (user['username'] ?? '').toString().toLowerCase();
      final userId = (user['id'] ?? '').toString().toLowerCase();
      final displayName = (user['displayName'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return username.contains(query) || 
             userId.contains(query) || 
             displayName.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Connect with Learners'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Private chats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivateChatListScreen(),
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.sp),
            color: isDark ? const Color(0xFF1F3527) : Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          
          // Connection Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
            color: isDark ? const Color(0xFF1F3527) : Colors.white,
            child: Row(
              children: [
                Container(
                  width: 8.sp,
                  height: 8.sp,
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.sp),
                Text(
                  isConnected
                      ? '${onlineUsers.length} users online'
                      : 'Connecting...',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Users List
          Expanded(
            child: isConnected && filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64.sp,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        SizedBox(height: 16.sp),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No users online'
                              : 'No users found',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.sp),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isCurrentUser = user['userId'] == currentUser?.id.toString();
                      if (isCurrentUser) return SizedBox.shrink();
                      return _buildUserCard(context, user, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> userData, bool isDark) {
    final username = userData['username'] ?? 'Anonymous';
    final userId = userData['userId'] ?? '';
    final isOnline = userData['isOnline'] ?? true;

    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
        ),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24.sp,
              backgroundColor: AppColors.primaryGreen,
              child: Text(
                username[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14.sp,
                  height: 14.sp,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1F3527) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          username,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            fontSize: 12.sp,
            color: isOnline
                ? Colors.green
                : (isDark ? Colors.grey[500] : Colors.grey[500]),
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.lock_outline, color: AppColors.primaryGreen),
          onPressed: () {
            final contact = PrivateChatContact.fromOnlineMap(userData);
            if (contact.id < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This user is not ready for private chats yet.'),
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PrivateChatScreen(contact: contact),
              ),
            );
          },
        ),
      ),
    );
  }
}



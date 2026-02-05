import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/chat_socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/performance_utils.dart';
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
  late final Debouncer _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocket();
    });
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _initializeSocket() {
    try {
      final user = ref.read(userProvider);
      if (user != null) {
        ref.read(socketProvider.notifier).connect(
          user.id.toString(),
          user.username,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'Unable to load user connections. Please check your connection and try again.',
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

    // Ensure socket is initialized if user is available
    if (currentUser != null && !isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeSocket();
      });
    }

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
      backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Connect with Learners'),
        backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Private chats',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                SmoothPageRoute(
                  child: const PrivateChatListScreen(),
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
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
            child: TextField(
              onChanged: (value) {
                _searchDebouncer.run(() {
                  setState(() {
                    _searchQuery = value;
                  });
                });
              },
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search, color: PanAfricanColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: PanAfricanRadius.lgBR,
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                contentPadding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md, vertical: PanAfricanSpacing.sm),
              ),
              style: PanAfricanTypography.bodyMedium(context),
            ),
          ),
          
          // Connection Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md, vertical: PanAfricanSpacing.sm),
            color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: isConnected ? PanAfricanColors.success : PanAfricanColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                Text(
                  isConnected
                      ? '${onlineUsers.length} users online'
                      : 'Connecting...',
                  style: PanAfricanTypography.labelLarge(context).copyWith(
                    color: PanAfricanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Users List
          Expanded(
            child: currentUser == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 56.w,
                          color: PanAfricanColors.textSecondary,
                        ),
                        SizedBox(height: PanAfricanSpacing.md),
                        Text(
                          'Please log in to connect with users',
                          style: PanAfricanTypography.bodyMedium(context).copyWith(
                            color: PanAfricanColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : !isConnected
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off,
                              size: 56.w,
                              color: PanAfricanColors.textSecondary,
                            ),
                            SizedBox(height: PanAfricanSpacing.md),
                            Text(
                              'Connecting...',
                              style: PanAfricanTypography.bodyMedium(context).copyWith(
                                color: PanAfricanColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 56.w,
                                  color: PanAfricanColors.textSecondary,
                                ),
                                SizedBox(height: PanAfricanSpacing.md),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No users online'
                                      : 'No users found',
                                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                                    color: PanAfricanColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : OptimizedListView(
                            padding: EdgeInsets.all(PanAfricanSpacing.md),
                            itemCount: filteredUsers.length,
                            itemExtent: 80.h,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final isCurrentUser = user['userId'] == currentUser.id.toString();
                              if (isCurrentUser) return const SizedBox.shrink();
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
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.xs,
        ),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24.w,
              backgroundColor: PanAfricanColors.primary,
              child: Text(
                username[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: PanAfricanColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          username,
          style: PanAfricanTypography.titleMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isOnline ? 'Online' : 'Offline',
          style: PanAfricanTypography.labelLarge(context).copyWith(
            color: isOnline ? PanAfricanColors.success : PanAfricanColors.textSecondary,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.chat_bubble_outline_rounded, color: PanAfricanColors.primary),
          onPressed: () {
            HapticFeedback.lightImpact();
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
              SmoothPageRoute(
                child: PrivateChatScreen(contact: contact),
              ),
            );
          },
        ),
      ),
    );
  }
}



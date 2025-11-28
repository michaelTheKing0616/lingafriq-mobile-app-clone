import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/models/private_chat_contact.dart';
import 'package:lingafriq/providers/private_chat_provider.dart';
import 'package:lingafriq/providers/socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/chat/private_chat_screen.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/african_theme.dart';

class PrivateChatListScreen extends ConsumerStatefulWidget {
  const PrivateChatListScreen({super.key});

  @override
  ConsumerState<PrivateChatListScreen> createState() =>
      _PrivateChatListScreenState();
}

class _PrivateChatListScreenState
    extends ConsumerState<PrivateChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(privateChatProvider.notifier).loadContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privateChatProvider);
    ref.watch(socketProvider);
    final socket = ref.read(socketProvider.notifier);
    final onlineIds = socket.onlineUsers
        .map((user) => user['userId']?.toString())
        .whereType<String>()
        .toSet();
    final currentUser = ref.watch(userProvider);

    final contacts = state.filteredContacts
        .where((contact) => contact.id != currentUser?.id)
        .toList();
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 15.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7B2CBF), // Purple
                  Color(0xFFCE1126), // Red
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
                      child: Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            top: 13.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F3527) : Colors.white,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                      boxShadow: DesignSystem.shadowMedium,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          ref.read(privateChatProvider.notifier).search(value),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, or language...',
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                      ),
                    ),
                  ),
                ),
                // Contacts List
                Expanded(
                  child: Container(
                    color: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
                    child: _buildContactsList(context, state, contacts, onlineIds, isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(
    BuildContext context,
    state,
    List contacts,
    Set<String> onlineIds,
    bool isDark,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
            SizedBox(height: 2.h),
            Text(
              state.error!,
              style: TextStyle(color: Colors.red.shade300, fontSize: 16.sp),
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () => ref.read(privateChatProvider.notifier).loadContacts(forceRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64.sp, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'No contacts found',
              style: TextStyle(fontSize: 18.sp, color: isDark ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isOnline = onlineIds.contains(contact.id.toString());
        final unreadCount = 0; // TODO: Get from contact model
        
        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F3527) : Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
            boxShadow: DesignSystem.shadowMedium,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(4.w),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AfricanTheme.primaryGreen,
                  child: Text(
                    contact.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF1F3527) : Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              contact.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              contact.lastMessage ?? 'No messages yet',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '2m ago', // TODO: Format from timestamp
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: EdgeInsets.only(top: 0.5.h),
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AfricanTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrivateChatScreen(contact: contact),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  final PrivateChatContact contact;
  final bool isOnline;
  final VoidCallback onTap;

  const _ContactTile({
    required this.contact,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final initials = contact.username.isNotEmpty
        ? contact.username[0].toUpperCase()
        : '?';
    return Material(
      color: isDark ? const Color(0xFF1F3527) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryGreen,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.username,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (contact.email != null)
                      Text(
                        contact.email!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    if (contact.language != null &&
                        contact.language!.trim().isNotEmpty)
                      Text(
                        contact.language!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    isOnline ? Icons.circle : Icons.circle_outlined,
                    color: isOnline ? Colors.green : Colors.grey,
                    size: 14,
                  ),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


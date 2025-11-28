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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(privateChatProvider.notifier).loadContacts(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(privateChatProvider.notifier).search(value),
              decoration: InputDecoration(
                hintText: 'Search by name, email, or language...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.isDarkMode
                    ? const Color(0xFF1F3527)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (state.isLoading)
            const LinearProgressIndicator(minHeight: 2),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(privateChatProvider.notifier)
                  .loadContacts(forceRefresh: true),
              child: contacts.isEmpty && !state.isLoading
                  ? ListView(
                      children: [
                        SizedBox(height: 80.sp),
                        Icon(Icons.chat_bubble_outline,
                            size: 64.sp, color: context.adaptive26),
                        const SizedBox(height: 12),
                        Text(
                          state.query.isEmpty
                              ? 'No contacts found. Pull to refresh.'
                              : 'No matches for "${state.query}".',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.adaptive54,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: contacts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final isOnline =
                            onlineIds.contains(contact.id.toString());
                        return _ContactTile(
                          contact: contact,
                          isOnline: isOnline,
                          onTap: () {
                            if (contact.id < 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('This user cannot chat yet.')),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PrivateChatScreen(contact: contact),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
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


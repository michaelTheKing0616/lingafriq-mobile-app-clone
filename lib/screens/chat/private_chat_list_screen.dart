import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/private_chat_contact.dart';
import 'package:lingafriq/providers/private_chat_provider.dart';
import 'package:lingafriq/providers/chat_socket_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/chat/private_chat_screen.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/lingafriq_ui_helpers.dart';
import 'package:lingafriq/widgets/skeleton_loader.dart';
import 'package:lingafriq/widgets/error_state_widget.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
// pan_african_components removed as unused

class PrivateChatListScreen extends ConsumerStatefulWidget {
  const PrivateChatListScreen({super.key});

  @override
  ConsumerState<PrivateChatListScreen> createState() =>
      _PrivateChatListScreenState();
}

class _PrivateChatListScreenState
    extends ConsumerState<PrivateChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final Debouncer _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
    // Load contacts will be triggered in build method
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'Unable to load private chats. Please check your connection and try again.',
      onRetry: () {
        setState(() {});
        ref.read(privateChatProvider.notifier).loadContacts();
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final state = ref.watch(privateChatProvider);
    ref.watch(socketProvider);
    final socket = ref.read(socketProvider.notifier);
    final onlineIds = socket.onlineUsers
        .map((user) => user['userId']?.toString())
        .whereType<String>()
        .toSet();
    final currentUser = ref.watch(userProvider);
    final isDark = context.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Load contacts if not already loaded
    if (state.contacts.isEmpty && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(privateChatProvider.notifier).loadContacts();
      });
    }

    final contacts = state.filteredContacts
        .where((contact) => contact.id != currentUser?.id)
        .toList();

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      body: ResponsiveSafeArea(
        child: Stack(
        children: [
          // Gradient Header
          Container(
            height: 15.h,
            decoration: BoxDecoration(
              gradient: PanAfricanGradients.kenteVibrant,
              boxShadow: PanAfricanShadows.md,
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                    const Spacer(),
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
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? PanAfricanColors.cardDark
                          : PanAfricanColors.cardLight,
                      borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
                      boxShadow: PanAfricanShadows.md,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _searchDebouncer.run(() =>
                          ref.read(privateChatProvider.notifier).search(value)),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, or language...',
                        hintStyle: PanAfricanTypography.bodyMedium(context)
                            .copyWith(color: PanAfricanColors.neutralMedium),
                        prefixIcon: Icon(Icons.search, color: PanAfricanColors.neutralMedium),
                        border: OutlineInputBorder(
                          borderRadius: PanAfricanRadius.lgBR,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: PanAfricanRadius.lgBR,
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: PanAfricanRadius.lgBR,
                          borderSide: BorderSide(
                            color: PanAfricanColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.md,
                          vertical: PanAfricanSpacing.sm,
                        ),
                      ),
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                  ),
                ),
                // Contacts List
                Expanded(
                  child: Container(
                    color: isDark
                        ? PanAfricanColors.surfaceDark
                        : PanAfricanColors.surfaceLight,
                    child: _buildContactsList(context, state, contacts, onlineIds, isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    if (state.isLoading) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
        itemCount: 6,
        itemBuilder: (_, __) => SkeletonListCard(),
      );
    }

    if (state.error != null) {
      return AppErrorState(
        message: state.error!,
        onRetry: () =>
            ref.read(privateChatProvider.notifier).loadContacts(forceRefresh: true),
      );
    }
    
    if (contacts.isEmpty) {
      return LingAfriqEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No contacts found',
        subtitle: 'Start a LingAfriq chat from the community or add friends to see conversations here.',
      );
    }
    
    return OptimizedListView.builder(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isOnline = onlineIds.contains(contact.id.toString());
        // Get unread count from chat socket provider for this contact's room
        final chatSocketNotifier = ref.read(socketProvider.notifier);
        final roomId = _buildRoomId(ref.read(userProvider)?.id ?? 0, contact.id);
        final roomMessages = chatSocketNotifier.messagesForRoom(roomId);
        final currentUserId = ref.read(userProvider)?.id.toString();
        final unreadCount = roomMessages.where((msg) => 
          msg['userId'] != currentUserId && 
          (msg['read'] == null || msg['read'] == false)
        ).length;
        
        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          decoration: BoxDecoration(
            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
            borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
            boxShadow: PanAfricanShadows.md,
            border: Border.all(
              color:
                  isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(PanAfricanSpacing.md),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24.w,
                  backgroundColor: PanAfricanColors.primary,
                  child: Text(
                    contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                    style: PanAfricanTypography.labelMedium(context)
                        .copyWith(color: colorScheme.onPrimary),
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
                          color: isDark 
                              ? PanAfricanColors.surfaceContainerDark 
                              : PanAfricanColors.surfaceContainerLight,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              contact.name,
              style: PanAfricanTypography.titleSmall(context),
            ),
            subtitle: Text(
              contact.lastMessage ?? 'No messages yet',
              style: PanAfricanTypography.bodySmall(context)
                  .copyWith(color: PanAfricanColors.neutralMedium),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(_getLastMessageTimestamp(roomMessages)),
                  style: PanAfricanTypography.labelSmall(context)
                      .copyWith(color: PanAfricanColors.neutralMedium),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: EdgeInsets.only(top: PanAfricanSpacing.xxs),
                    padding: EdgeInsets.symmetric(
                      horizontal: PanAfricanSpacing.sm,
                      vertical: PanAfricanSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: PanAfricanColors.primary,
                      borderRadius: PanAfricanRadius.roundBR,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: PanAfricanTypography.labelSmall(context)
                          .copyWith(color: colorScheme.onPrimary),
                    ),
                  ),
              ],
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                SmoothPageRoute(
                  child: PrivateChatScreen(contact: contact),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _buildRoomId(int userId1, int userId2) {
    final ids = [userId1, userId2]..sort();
    return 'private_${ids[0]}_${ids[1]}';
  }

  String? _getLastMessageTimestamp(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return null;
    final lastMessage = messages.last;
    return lastMessage['timestamp']?.toString();
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: isDark 
          ? PanAfricanColors.surfaceContainerDark 
          : PanAfricanColors.surfaceContainerLight,
      borderRadius: PanAfricanRadius.lgBR,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: PanAfricanRadius.lgBR,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.sm,
            vertical: PanAfricanSpacing.sm,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24.w,
                backgroundColor: PanAfricanColors.primary,
                child: Text(
                  initials,
                  style: PanAfricanTypography.titleSmall(context)
                      .copyWith(color: colorScheme.onPrimary),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.username,
                      style: PanAfricanTypography.titleSmall(context),
                    ),
                    if (contact.email != null)
                      Text(
                        contact.email!,
                        style: PanAfricanTypography.labelSmall(context)
                            .copyWith(color: PanAfricanColors.neutralMedium),
                      ),
                    if (contact.language != null &&
                        contact.language!.trim().isNotEmpty)
                      Text(
                        contact.language!,
                        style: PanAfricanTypography.labelSmall(context)
                            .copyWith(color: PanAfricanColors.neutralMedium),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    isOnline ? Icons.circle : Icons.circle_outlined,
                    color: isOnline 
                        ? PanAfricanColors.success 
                        : PanAfricanColors.neutralMedium,
                    size: 14,
                  ),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: PanAfricanTypography.labelSmall(context).copyWith(
                      color: isOnline 
                          ? PanAfricanColors.success 
                          : PanAfricanColors.neutralMedium,
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


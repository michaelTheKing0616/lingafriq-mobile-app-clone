import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/user_provider.dart';
import '../../providers/wa_status_provider.dart';
import '../../services/chat/wa_private_chat_service.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../utils/pan_african_design_system.dart' show PanAfricanSpacing;
import '../../utils/transport_error_policy.dart';
import '../../widgets/griot/griot_widgets.dart';
import 'call_history_screen.dart';
import 'private_chat_screen.dart';
import 'user_search_global_id_screen.dart';

/// WhatsApp-style inbox: real conversations from `/api/wa/conversations`,
/// status carousel from `/api/wa/status/*`, calls tab opens dedicated history UI.
class PrivateChatListScreen extends ConsumerStatefulWidget {
  const PrivateChatListScreen({super.key});

  @override
  ConsumerState<PrivateChatListScreen> createState() =>
      _PrivateChatListScreenState();
}

class _PrivateChatListScreenState extends ConsumerState<PrivateChatListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  static const _tabs = ['Chats', 'Status', 'Calls'];

  List<WaPrivateConversationRow> _conversations = [];
  bool _loadingChats = true;
  String? _chatsError;

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  static String _formatTime(DateTime? t) {
    if (t == null) return '';
    final local = t.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return DateFormat.jm().format(local);
    }
    if (now.difference(local).inDays < 7) {
      return DateFormat.E().format(local);
    }
    return DateFormat.MMMd().format(local);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshChats();
      ref.read(waStatusProvider.notifier).loadFeed();
      ref.read(waStatusProvider.notifier).loadMine();
    });
  }

  Future<void> _refreshChats() async {
    final me = ref.read(userProvider);
    if (me == null || me.id == 0) {
      setState(() {
        _loadingChats = false;
        _chatsError = 'Sign in to see your private messages.';
        _conversations = [];
      });
      return;
    }
    setState(() {
      _loadingChats = true;
      _chatsError = null;
    });
    try {
      final rows = await WaPrivateChatService.fetchConversations(
        myNumericUserId: me.id,
        myUsername: me.username,
      );
      if (mounted) {
        setState(() {
          _conversations = rows;
          _loadingChats = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingChats = false;
        _chatsError = e is DioException
            ? TransportErrorPolicy.toUserMessage(e)
            : 'Could not load conversations.';
      });
    }
  }

  List<WaPrivateConversationRow> get _filteredConversations {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _conversations;
    return _conversations
        .where(
          (c) =>
              c.displayName.toLowerCase().contains(q) ||
              c.lastPreview.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: ModernGriotColors.surface,
      appBar: GriotAppBar(
        avatar: GriotAvatar(
          size: 32,
          status: GriotAvatarStatus.online,
          placeholder: Icon(Icons.person_rounded, size: 16.sp, color: cs.onSurfaceVariant),
        ),
        showBranding: true,
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: cs.onSurface,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(cs),
          _buildTabBar(cs),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatsTab(cs),
                _buildStatusTab(cs),
                const CallHistoryScreen(embedInTab: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: GriotFab(
        icon: Icons.edit_rounded,
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (ctx) => UserSearchGlobalIdScreen(
                currentChatType: 'private',
                onUserSelected: (u) {
                  Navigator.pop(ctx);
                  final id = u['id'];
                  final uid = int.tryParse(id?.toString() ?? '');
                  if (uid == null) return;
                  final name = u['username']?.toString() ??
                      u['first_name']?.toString() ??
                      'User';
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrivateChatScreen(
                        otherUserId: uid,
                        otherDisplayName: name,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: _showSearch ? 64.h : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showSearch ? 1.0 : 0.0,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.md,
            vertical: PanAfricanSpacing.xs,
          ),
          child: GriotInput(
            controller: _searchController,
            hintText: 'Search conversations...',
            prefixIcon: Icons.search_rounded,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: ModernGriotRadius.borderPill,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: ModernGriotColors.primary,
          borderRadius: ModernGriotRadius.borderPill,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: ModernGriotColors.onPrimary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: ModernGriotTypography.labelLarge(),
        unselectedLabelStyle: ModernGriotTypography.labelMedium(),
        splashBorderRadius: ModernGriotRadius.borderPill,
        tabs: _tabs.map((t) => Tab(text: t, height: 40.h)).toList(),
      ),
    );
  }

  Widget _buildChatsTab(ColorScheme cs) {
    if (_loadingChats) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_chatsError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_chatsError!, textAlign: TextAlign.center),
              SizedBox(height: PanAfricanSpacing.md),
              FilledButton(onPressed: _refreshChats, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final list = _filteredConversations;

    return RefreshIndicator(
      onRefresh: _refreshChats,
      child: ListView(
        padding: EdgeInsets.only(top: PanAfricanSpacing.md),
        children: [
          _buildStatusCarousel(cs),
          SizedBox(height: PanAfricanSpacing.md),
          if (list.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg, vertical: 24.h),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 48.sp, color: cs.onSurfaceVariant),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    'No conversations yet',
                    style: ModernGriotTypography.titleSmall(color: cs.onSurface),
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  Text(
                    'Tap + to find someone by handle, or connect in Social Hub.',
                    style: ModernGriotTypography.bodySmall(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            _buildSectionHeader('Messages', Icons.forum_outlined, cs),
            ...list.map((c) => _buildConversationTile(c, cs)),
          ],
          SizedBox(height: 80.h),
        ],
      ),
    );
  }

  Widget _buildStatusCarousel(ColorScheme cs) {
    final st = ref.watch(waStatusProvider);
    if (st.loading && st.feed.isEmpty && st.mine.isEmpty) {
      return SizedBox(
        height: 96.h,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final items = <_StatusRing>[];
    items.add(const _StatusRing(isMine: true, label: 'My Status', initial: '+'));
    for (final s in st.feed.take(12)) {
      final initial = s.text.isNotEmpty
          ? s.text.substring(0, 1).toUpperCase()
          : '?';
      items.add(
        _StatusRing(
          isMine: false,
          label: s.userId == 'me' ? 'You' : 'Status',
          initial: initial,
          viewed: true,
        ),
      );
    }

    return SizedBox(
      height: 96.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: PanAfricanSpacing.sm),
        itemBuilder: (context, index) {
          final status = items[index];
          final ringColor = status.isMine
              ? cs.outlineVariant
              : status.viewed
                  ? ModernGriotColors.secondary
                  : ModernGriotColors.primary;

          return GestureDetector(
            onTap: () {
              if (status.isMine) {
                Navigator.pushNamed(context, '/wa-status-create');
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58.r,
                  height: 58.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2.5.r),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 24.r,
                      backgroundColor: cs.surfaceContainerHigh,
                      child: status.isMine
                          ? Icon(Icons.add_rounded, size: 22.sp, color: ModernGriotColors.primary)
                          : Text(
                              status.initial,
                              style: ModernGriotTypography.titleSmall(color: cs.onSurface),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                SizedBox(
                  width: 60.w,
                  child: Text(
                    status.label,
                    style: ModernGriotTypography.labelSmall(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.lg,
        vertical: PanAfricanSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: cs.onSurfaceVariant),
          SizedBox(width: PanAfricanSpacing.xxs),
          Text(
            title.toUpperCase(),
            style: ModernGriotTypography.labelSmall(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(WaPrivateConversationRow chat, ColorScheme cs) {
    final hasUnread = chat.unreadCount > 0;
    final initial =
        chat.displayName.isNotEmpty ? chat.displayName[0].toUpperCase() : '?';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.xxxs,
      ),
      child: GriotCard(
        surfaceLevel: 1,
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.sm,
        ),
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => PrivateChatScreen(
                otherUserId: chat.otherUserId,
                otherDisplayName: chat.displayName,
                contact: {
                  'isOnline': false,
                  'initial': initial,
                },
              ),
            ),
          ).then((_) => _refreshChats());
        },
        child: Row(
          children: [
            GriotAvatar(
              size: 48,
              status: GriotAvatarStatus.offline,
              placeholder: CircleAvatar(
                radius: 24.r,
                backgroundColor: ModernGriotColors.primaryContainer.withAlpha(80),
                child: Text(
                  initial,
                  style: ModernGriotTypography.titleMedium(
                    color: ModernGriotColors.primary,
                  ),
                ),
              ),
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.displayName,
                    style: ModernGriotTypography.titleSmall(
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      if (chat.lastMessageFromMe) ...[
                        Icon(
                          chat.lastMessageRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14.sp,
                          color: ModernGriotColors.secondary,
                        ),
                        SizedBox(width: 4.w),
                      ],
                      Expanded(
                        child: Text(
                          chat.lastPreview,
                          style: ModernGriotTypography.bodySmall(
                            color: hasUnread ? cs.onSurface : cs.onSurfaceVariant,
                          ).copyWith(
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: PanAfricanSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(chat.lastAt),
                  style: ModernGriotTypography.labelSmall(
                    color: hasUnread
                        ? ModernGriotColors.primary
                        : cs.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4.h),
                if (hasUnread)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: ModernGriotColors.primary,
                      borderRadius: ModernGriotRadius.borderPill,
                    ),
                    child: Text(
                      chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: ModernGriotColors.onPrimary,
                      ),
                    ),
                  )
                else
                  SizedBox(height: 18.h),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTab(ColorScheme cs) {
    final st = ref.watch(waStatusProvider);
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(waStatusProvider.notifier).loadFeed();
        await ref.read(waStatusProvider.notifier).loadMine();
      },
      child: ListView(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        children: [
          Text('Your updates', style: ModernGriotTypography.titleSmall(color: cs.onSurface)),
          SizedBox(height: PanAfricanSpacing.sm),
          if (st.mine.isEmpty)
            Text(
              'You have no active status. Create one from the Chats tab (My Status) or WhatsApp-style status screens.',
              style: ModernGriotTypography.bodySmall(color: cs.onSurfaceVariant),
            )
          else
            ...st.mine.map(
              (s) => ListTile(
                title: Text(s.text.isNotEmpty ? s.text : s.mediaType),
                subtitle: Text(s.createdAt.toLocal().toString()),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusRing {
  const _StatusRing({
    required this.isMine,
    required this.label,
    required this.initial,
    this.viewed = false,
  });

  final bool isMine;
  final String label;
  final String initial;
  final bool viewed;
}

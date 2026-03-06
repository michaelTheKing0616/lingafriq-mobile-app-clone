import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/x_feed_provider.dart';
import 'package:lingafriq/screens/feed/ui/x_theme.dart';

class XNotificationsScreen extends ConsumerStatefulWidget {
  const XNotificationsScreen({super.key});

  @override
  ConsumerState<XNotificationsScreen> createState() => _XNotificationsScreenState();
}

class _XNotificationsScreenState extends ConsumerState<XNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xFeedProvider.notifier).loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(xFeedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final all = state.notifications;
    final mentions = all.where((item) => (item['type'] ?? '').toString() == 'mention').toList();

    return Scaffold(
      backgroundColor: XUi.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: XUi.scaffoldBg(isDark),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(xFeedProvider.notifier).loadNotifications(),
            child: Text('Refresh', style: TextStyle(color: XUi.accent())),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: XUi.accent(),
          tabs: const [Tab(text: 'All'), Tab(text: 'Mentions')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _NotifList(
            items: all,
            onTap: (id) => ref.read(xFeedProvider.notifier).markNotificationRead(id),
          ),
          _NotifList(
            items: mentions,
            onTap: (id) => ref.read(xFeedProvider.notifier).markNotificationRead(id),
          ),
        ],
      ),
    );
  }
}

class _NotifList extends StatelessWidget {
  const _NotifList({required this.items, required this.onTap});

  final List<Map<String, dynamic>> items;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (items.isEmpty) {
      return Center(
        child: Text('No notifications yet.', style: TextStyle(color: XUi.secondaryText(isDark))),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: XUi.divider(isDark)),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = (item['_id'] ?? '').toString();
        final type = (item['type'] ?? 'reply').toString();
        final unread = item['read'] != true;
        final actorMap = item['actor_id'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(item['actor_id'])
            : const <String, dynamic>{};
        final actor = (actorMap['username'] ?? actorMap['first_name'] ?? 'Learner').toString();

        return InkWell(
          onTap: id.isEmpty ? null : () => onTap(id),
          child: Container(
            color: unread ? XUi.accent().withValues(alpha: 0.08) : Colors.transparent,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _notifColor(type).withValues(alpha: 0.18),
                child: Icon(_notifIcon(type), color: _notifColor(type), size: 18),
              ),
              title: Text('$actor • $type'),
              subtitle: Text('Tap to mark as read', style: TextStyle(color: XUi.secondaryText(isDark))),
              trailing: unread
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: XUi.accent(), borderRadius: BorderRadius.circular(10)),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

Color _notifColor(String type) {
  switch (type) {
    case 'like':
      return const Color(0xFFE11D48);
    case 'repost':
      return const Color(0xFF16A34A);
    case 'mention':
      return XUi.accent();
    default:
      return const Color(0xFF7C3AED);
  }
}

IconData _notifIcon(String type) {
  switch (type) {
    case 'like':
      return Icons.favorite_rounded;
    case 'repost':
      return Icons.repeat_rounded;
    case 'mention':
      return Icons.alternate_email_rounded;
    default:
      return Icons.chat_bubble_rounded;
  }
}

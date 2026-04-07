// X-style notifications list (uses x_feed_provider notifications slice).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/api_contract.dart';
import '../../providers/x_feed_provider.dart';
import '../../utils/api_service.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import 'feed_post_thread_screen.dart';

class XNotificationsScreen extends ConsumerStatefulWidget {
  const XNotificationsScreen({super.key});

  @override
  ConsumerState<XNotificationsScreen> createState() => _XNotificationsScreenState();
}

class _XNotificationsScreenState extends ConsumerState<XNotificationsScreen> {
  String _tab = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xFeedProvider.notifier).loadNotifications();
    });
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> all) {
    if (_tab == 'All') return all;
    return all.where((n) => (n['type'] ?? '').toString() == 'mention').toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final feed = ref.watch(xFeedProvider);
    final items = _filtered(feed.notifications);

    return GriotScaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Notifications', style: ModernGriotTypography.titleLarge(context: context)),
        actions: [
          if (feed.notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                try {
                  await ApiService.post(ApiContract.url(ApiContract.feed.notificationsReadAll));
                  await ref.read(xFeedProvider.notifier).loadNotifications();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not mark all as read')),
                    );
                  }
                }
              },
              child: const Text('Mark all'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                GriotChip(
                  label: 'All',
                  selected: _tab == 'All',
                  onTap: () => setState(() => _tab = 'All'),
                ),
                SizedBox(width: 8.w),
                GriotChip(
                  label: 'Mentions',
                  selected: _tab == 'Mentions',
                  onTap: () => setState(() => _tab = 'Mentions'),
                ),
              ],
            ),
          ),
          if (feed.notificationsLoading && items.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (feed.notificationsError != null && items.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(feed.notificationsError!, textAlign: TextAlign.center),
                      SizedBox(height: 12.h),
                      FilledButton(
                        onPressed: () => ref.read(xFeedProvider.notifier).loadNotifications(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(xFeedProvider.notifier).loadNotifications(),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == items.length) return const _GrowTribeCard();
                    return _NotifCard(
                      raw: items[index],
                      onOpen: (id, postId) async {
                        HapticFeedback.lightImpact();
                        await ref.read(xFeedProvider.notifier).markNotificationRead(id);
                        if (!context.mounted) return;
                        if (postId != null && postId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => FeedPostThreadScreen(postId: postId),
                            ),
                          );
                        }
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

Map<String, dynamic>? _actorMap(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

String _notifId(Map<String, dynamic> n) {
  return (n['_id'] ?? n['id'] ?? '').toString();
}

String _postId(Map<String, dynamic> n) {
  final p = n['post_id'] ?? n['postId'];
  if (p is Map) return (p['_id'] ?? p['id'] ?? '').toString();
  return p?.toString() ?? '';
}

String _actorName(Map<String, dynamic> n) {
  final a = _actorMap(n['actor_id'] ?? n['actorId']);
  if (a == null) return 'Someone';
  final u = (a['username'] ?? '').toString().trim();
  final fn = (a['first_name'] ?? a['firstName'] ?? '').toString().trim();
  final ln = (a['last_name'] ?? a['lastName'] ?? '').toString().trim();
  final name = ('$fn $ln').trim();
  if (name.isNotEmpty) return name;
  if (u.isNotEmpty) return u;
  return 'Someone';
}

String _actorHandle(Map<String, dynamic> n) {
  final a = _actorMap(n['actor_id'] ?? n['actorId']);
  final u = (a?['username'] ?? '').toString().trim();
  return u.isNotEmpty ? '@$u' : '';
}

String _bodyForType(String type) {
  switch (type) {
    case 'like':
      return 'liked your post';
    case 'repost':
      return 'reposted your post';
    case 'reply':
      return 'replied to your post';
    case 'follow':
      return 'started following you';
    case 'mention':
      return 'mentioned you';
    default:
      return 'interacted with you';
  }
}

String _formatTime(DateTime? t) {
  if (t == null) return '';
  final diff = DateTime.now().difference(t.toLocal());
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${t.month}/${t.day}';
}

enum _NotifType { like, repost, reply, follow, mention }

_NotifType _parseType(String t) {
  switch (t) {
    case 'repost':
      return _NotifType.repost;
    case 'reply':
      return _NotifType.reply;
    case 'follow':
      return _NotifType.follow;
    case 'mention':
      return _NotifType.mention;
    case 'like':
    default:
      return _NotifType.like;
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.raw, required this.onOpen});

  final Map<String, dynamic> raw;
  final void Function(String id, String? postId) onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = _notifId(raw);
    if (id.isEmpty) return const SizedBox.shrink();

    final typeStr = (raw['type'] ?? '').toString();
    final type = _parseType(typeStr);
    final unread = raw['read'] != true;
    final created = DateTime.tryParse((raw['created_at'] ?? raw['createdAt'] ?? '').toString());
    final postId = _postId(raw);
    final name = _actorName(raw);
    final handle = _actorHandle(raw);
    final body = _bodyForType(typeStr);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GriotCard(
        surfaceLevel: unread ? 1 : 0,
        onTap: () => onOpen(id, postId.isEmpty ? null : postId),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarWithIcon(type: type),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: ModernGriotTypography.bodyMedium(context: context),
                            children: [
                              TextSpan(
                                text: name,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: ' $body'),
                              if (handle.isNotEmpty)
                                TextSpan(
                                  text: ' \u00B7 $handle',
                                  style: ModernGriotTypography.bodySmall(
                                    context: context,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8.r,
                          height: 8.r,
                          margin: EdgeInsets.only(left: 8.w),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatTime(created),
                    style: ModernGriotTypography.labelSmall(
                      context: context,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (postId.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      'Tap to open thread',
                      style: ModernGriotTypography.labelSmall(
                        context: context,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarWithIcon extends StatelessWidget {
  const _AvatarWithIcon({required this.type});
  final _NotifType type;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48.r,
      height: 48.r,
      child: Stack(
        children: [
          const GriotAvatar(size: 44),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20.r,
              height: 20.r,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(_icon, size: 10.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon => switch (type) {
        _NotifType.like => Icons.favorite_rounded,
        _NotifType.repost => Icons.repeat_rounded,
        _NotifType.reply => Icons.chat_bubble_rounded,
        _NotifType.follow => Icons.person_add_rounded,
        _NotifType.mention => Icons.alternate_email_rounded,
      };

  Color get _color => switch (type) {
        _NotifType.like => const Color(0xFFE11D48),
        _NotifType.repost => const Color(0xFF16A34A),
        _NotifType.reply => const Color(0xFF7C3AED),
        _NotifType.follow => const Color(0xFF2563EB),
        _NotifType.mention => ModernGriotColors.primary,
      };
}

class _GrowTribeCard extends StatefulWidget {
  const _GrowTribeCard();

  @override
  State<_GrowTribeCard> createState() => _GrowTribeCardState();
}

class _GrowTribeCardState extends State<_GrowTribeCard> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  final Set<String> _requested = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get(
        ApiContract.url(ApiContract.social.connectionsSearch),
        queryParameters: {'query': 'a', 'limit': '6'},
      );
      final raw = res.data;
      List<Map<String, dynamic>> rows;
      if (raw is Map && raw['data'] is List) {
        rows = (raw['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (raw is List) {
        rows = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        rows = [];
      }
      setState(() {
        _users = rows;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Could not load suggestions';
      });
    }
  }

  Future<void> _follow(Map<String, dynamic> user) async {
    final id = (user['_id'] ?? user['id'] ?? '').toString();
    if (id.isEmpty) return;
    HapticFeedback.mediumImpact();
    try {
      await ApiService.post(
        ApiContract.url(ApiContract.social.connectionRequest),
        data: {'connectedUserId': id},
      );
      setState(() => _requested.add(id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send request')),
        );
      }
    }
  }

  String _userLabel(Map<String, dynamic> u) {
    final fn = (u['first_name'] ?? u['firstName'] ?? '').toString().trim();
    final ln = (u['last_name'] ?? u['lastName'] ?? '').toString().trim();
    final name = ('$fn $ln').trim();
    final un = (u['username'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    if (un.isNotEmpty) return un;
    return 'Learner';
  }

  String _subtitle(Map<String, dynamic> u) {
    final un = (u['username'] ?? '').toString().trim();
    final status = (u['connectionStatus'] ?? u['connection_status'] ?? 'none').toString();
    final h = un.isNotEmpty ? '@$un' : '';
    return h.isNotEmpty ? '$h  $status' : status;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 24.h),
      child: GriotCard(
        surfaceLevel: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded, color: cs.primary, size: 22.sp),
                SizedBox(width: 8.w),
                Text(
                  'Grow Your Tribe',
                  style: ModernGriotTypography.titleSmall(context: context),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'Connect with native speakers and fellow learners',
              style: ModernGriotTypography.bodySmall(
                context: context,
                color: cs.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 12.h),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_error != null)
              Row(
                children: [
                  Expanded(child: Text(_error!, style: TextStyle(color: cs.error))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              )
            else if (_users.isEmpty)
              Text(
                'No suggestions right now. Try search from Chats.',
                style: ModernGriotTypography.bodySmall(
                  context: context,
                  color: cs.onSurfaceVariant,
                ),
              )
            else
              ..._users.map((u) {
                final id = (u['_id'] ?? u['id'] ?? '').toString();
                final status = (u['connectionStatus'] ?? u['connection_status'] ?? 'none').toString();
                final pending = status == 'pending' || _requested.contains(id);
                final connected = status == 'accepted';

                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Row(
                    children: [
                      const GriotAvatar(size: 36),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userLabel(u),
                              style: ModernGriotTypography.titleSmall(context: context),
                            ),
                            Text(
                              _subtitle(u),
                              style: ModernGriotTypography.labelSmall(
                                context: context,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GriotSecondaryButton(
                        label: connected
                            ? 'Friends'
                            : pending
                                ? 'Pending'
                                : 'Connect',
                        onPressed: (connected || pending) ? null : () => _follow(u),
                        width: 88,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

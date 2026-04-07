import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_contract.dart';
import '../../models/feed_post_model.dart';
import '../../providers/x_feed_provider.dart';
import '../../utils/api_service.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import 'feed_post_thread_screen.dart';

/// X-style community feed backed by `/api/feed/posts`.
class XFeedHomeScreen extends ConsumerStatefulWidget {
  const XFeedHomeScreen({super.key});

  @override
  ConsumerState<XFeedHomeScreen> createState() => _XFeedHomeScreenState();
}

class _XFeedHomeScreenState extends ConsumerState<XFeedHomeScreen> {
  /// UI label → backend `language_code` (aligned with feed posts / learning languages).
  static const _languageChips = <String, String?>{
    'All': null,
    'Yoruba': 'yoruba',
    'Swahili': 'swahili',
    'Wolof': 'wolof',
    'Twi': 'twi',
  };

  String _selectedLabel = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  Future<void> _reload() async {
    final code = _languageChips[_selectedLabel];
    await ref.read(xFeedProvider.notifier).loadTimeline(languageCode: code);
  }

  String _formatPostTime(DateTime? t) {
    if (t == null) return '';
    final local = t.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${local.month}/${local.day}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final feed = ref.watch(xFeedProvider);
    final posts = feed.posts;

    return GriotScaffold(
      floatingActionButton: GriotFab(
        icon: Icons.edit_note_rounded,
        onPressed: () => Navigator.pushNamed(context, '/x-compose'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'LingAfriq Feed',
                style: ModernGriotTypography.titleLarge(context: context),
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/x-notifications'),
                  icon: Icon(Icons.notifications_none_rounded, color: cs.onSurface),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(52.h),
                child: SizedBox(
                  height: 44.h,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    scrollDirection: Axis.horizontal,
                    itemCount: _languageChips.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (_, i) {
                      final label = _languageChips.keys.elementAt(i);
                      return GriotChip(
                        label: label,
                        selected: _selectedLabel == label,
                        onTap: () {
                          setState(() => _selectedLabel = label);
                          _reload();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            if (feed.timelineError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: Material(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              feed.timelineError!,
                              style: TextStyle(color: cs.onErrorContainer),
                            ),
                          ),
                          TextButton(onPressed: _reload, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (feed.timelineLoading && posts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!feed.timelineLoading && posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Text(
                      'No posts yet. Tap + to share something with the community.',
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.bodyMedium(
                        context: context,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                sliver: SliverList.builder(
                  itemCount: posts.length + (feed.timelineLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (feed.timelineLoading && index == posts.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    final post = posts[index];
                    return _PostCard(
                      post: post,
                      timeLabel: _formatPostTime(post.createdAt),
                      onOpenThread: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => FeedPostThreadScreen(
                              postId: post.id,
                              preview: post,
                            ),
                          ),
                        );
                      },
                      onLike: () {
                        HapticFeedback.lightImpact();
                        ref.read(xFeedProvider.notifier).toggleLike(post.id);
                      },
                      onRepost: () {
                        HapticFeedback.lightImpact();
                        ref.read(xFeedProvider.notifier).toggleRepost(post.id);
                      },
                      onShare: () {
                        Share.share(
                          '${post.content}\n\n— LingAfriq',
                          subject: 'LingAfriq feed post',
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.timeLabel,
    required this.onOpenThread,
    required this.onLike,
    required this.onRepost,
    required this.onShare,
  });

  final FeedPostModel post;
  final String timeLabel;
  final VoidCallback onOpenThread;
  final VoidCallback onLike;
  final VoidCallback onRepost;
  final VoidCallback onShare;

  Future<void> _openAudio(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final audioUrl = post.audioUrl?.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GriotCard(
        surfaceLevel: 1,
        onTap: onOpenThread,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GriotAvatar(size: 40),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.displayName,
                              style: ModernGriotTypography.titleSmall(context: context),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            post.handle,
                            style: ModernGriotTypography.bodySmall(
                              context: context,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        timeLabel,
                        style: ModernGriotTypography.labelSmall(
                          context: context,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                GriotBadgePill(label: post.languageChipLabel),
              ],
            ),
            SizedBox(height: 12.h),
            _HashtagText(text: post.content),
            if (post.hasAudio && audioUrl != null && audioUrl.isNotEmpty) ...[
              SizedBox(height: 12.h),
              InkWell(
                onTap: () => _openAudio(audioUrl),
                borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 12.w),
                      Icon(Icons.play_arrow_rounded, color: cs.primary, size: 24.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Play audio',
                          style: ModernGriotTypography.labelSmall(
                            context: context,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                  ),
                ),
              ),
            ],
            if (post.hasImage && post.mediaUrls.isNotEmpty) ...[
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                child: CachedNetworkImage(
                  imageUrl: post.mediaUrls.first,
                  height: 180.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180.h,
                    color: cs.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 180.h,
                    decoration: BoxDecoration(
                      gradient: ModernGriotGradients.sunsetWarm,
                      borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                    ),
                    child: Center(
                      child: Icon(Icons.image_rounded, size: 48.sp, color: cs.onSurfaceVariant.withAlpha(100)),
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                _EngageBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  count: post.replyCount,
                  onTap: onOpenThread,
                ),
                SizedBox(width: 20.w),
                _EngageBtn(
                  icon: Icons.repeat_rounded,
                  count: post.repostCount,
                  onTap: onRepost,
                ),
                SizedBox(width: 20.w),
                _EngageBtn(
                  icon: Icons.favorite_border_rounded,
                  count: post.likeCount,
                  tint: const Color(0xFFE11D48),
                  onTap: onLike,
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined, size: 16.sp, color: cs.onSurfaceVariant),
                    SizedBox(width: 4.w),
                    Text(
                      _fmt(post.viewCount),
                      style: ModernGriotTypography.labelSmall(
                        context: context,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    InkWell(
                      onTap: onShare,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: Icon(Icons.share_outlined, size: 18.sp, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EngageBtn extends StatelessWidget {
  const _EngageBtn({
    required this.icon,
    required this.count,
    this.tint,
    this.onTap,
  });

  final IconData icon;
  final int count;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = tint ?? cs.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            _fmt(count),
            style: ModernGriotTypography.labelSmall(
              context: context,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HashtagText extends StatelessWidget {
  const _HashtagText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = ModernGriotTypography.bodyMedium(context: context);
    final tagStyle = base.copyWith(color: cs.primary, fontWeight: FontWeight.w600);
    final spans = <TextSpan>[];
    final re = RegExp(r'(#\w+)');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(TextSpan(text: m.group(0), style: tagStyle));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return RichText(text: TextSpan(style: base, children: spans));
  }
}

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

// ---------------------------------------------------------------------------
// X notifications route (`/x-notifications`) lives in this library so CI and
// `my_app.dart` only depend on `screens/feed/x_feed_home_screen.dart`, which
// is already verified in workflows (avoids orphan `lib/*.dart` import issues).
// ---------------------------------------------------------------------------

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
                    if (index == items.length) return const _XNotifGrowTribeCard();
                    return _XNotifCard(
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

Map<String, dynamic>? _xNotifActorMap(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

String _xNotifId(Map<String, dynamic> n) {
  return (n['_id'] ?? n['id'] ?? '').toString();
}

String _xNotifPostId(Map<String, dynamic> n) {
  final p = n['post_id'] ?? n['postId'];
  if (p is Map) return (p['_id'] ?? p['id'] ?? '').toString();
  return p?.toString() ?? '';
}

String _xNotifActorName(Map<String, dynamic> n) {
  final a = _xNotifActorMap(n['actor_id'] ?? n['actorId']);
  if (a == null) return 'Someone';
  final u = (a['username'] ?? '').toString().trim();
  final fn = (a['first_name'] ?? a['firstName'] ?? '').toString().trim();
  final ln = (a['last_name'] ?? a['lastName'] ?? '').toString().trim();
  final name = ('$fn $ln').trim();
  if (name.isNotEmpty) return name;
  if (u.isNotEmpty) return u;
  return 'Someone';
}

String _xNotifActorHandle(Map<String, dynamic> n) {
  final a = _xNotifActorMap(n['actor_id'] ?? n['actorId']);
  final u = (a?['username'] ?? '').toString().trim();
  return u.isNotEmpty ? '@$u' : '';
}

String _xNotifBodyForType(String type) {
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

String _xNotifFormatTime(DateTime? t) {
  if (t == null) return '';
  final diff = DateTime.now().difference(t.toLocal());
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${t.month}/${t.day}';
}

enum _XNotifType { like, repost, reply, follow, mention }

_XNotifType _xNotifParseType(String t) {
  switch (t) {
    case 'repost':
      return _XNotifType.repost;
    case 'reply':
      return _XNotifType.reply;
    case 'follow':
      return _XNotifType.follow;
    case 'mention':
      return _XNotifType.mention;
    case 'like':
    default:
      return _XNotifType.like;
  }
}

class _XNotifCard extends StatelessWidget {
  const _XNotifCard({required this.raw, required this.onOpen});

  final Map<String, dynamic> raw;
  final void Function(String id, String? postId) onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = _xNotifId(raw);
    if (id.isEmpty) return const SizedBox.shrink();

    final typeStr = (raw['type'] ?? '').toString();
    final type = _xNotifParseType(typeStr);
    final unread = raw['read'] != true;
    final created = DateTime.tryParse((raw['created_at'] ?? raw['createdAt'] ?? '').toString());
    final postId = _xNotifPostId(raw);
    final name = _xNotifActorName(raw);
    final handle = _xNotifActorHandle(raw);
    final body = _xNotifBodyForType(typeStr);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GriotCard(
        surfaceLevel: unread ? 1 : 0,
        onTap: () => onOpen(id, postId.isEmpty ? null : postId),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _XNotifAvatarWithIcon(type: type),
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
                    _xNotifFormatTime(created),
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

class _XNotifAvatarWithIcon extends StatelessWidget {
  const _XNotifAvatarWithIcon({required this.type});
  final _XNotifType type;

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
        _XNotifType.like => Icons.favorite_rounded,
        _XNotifType.repost => Icons.repeat_rounded,
        _XNotifType.reply => Icons.chat_bubble_rounded,
        _XNotifType.follow => Icons.person_add_rounded,
        _XNotifType.mention => Icons.alternate_email_rounded,
      };

  Color get _color => switch (type) {
        _XNotifType.like => const Color(0xFFE11D48),
        _XNotifType.repost => const Color(0xFF16A34A),
        _XNotifType.reply => const Color(0xFF7C3AED),
        _XNotifType.follow => const Color(0xFF2563EB),
        _XNotifType.mention => ModernGriotColors.primary,
      };
}

class _XNotifGrowTribeCard extends StatefulWidget {
  const _XNotifGrowTribeCard();

  @override
  State<_XNotifGrowTribeCard> createState() => _XNotifGrowTribeCardState();
}

class _XNotifGrowTribeCardState extends State<_XNotifGrowTribeCard> {
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
    return h.isNotEmpty ? '$h · $status' : status;
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/feed_post_model.dart';
import '../../providers/x_feed_provider.dart';
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

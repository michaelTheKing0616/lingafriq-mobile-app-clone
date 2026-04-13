import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/x_feed_provider.dart';
import 'package:lingafriq/screens/feed/ui/x_theme.dart';
import 'package:lingafriq/theme/stitch_theme_extensions.dart';

/// Feed profile — data from `GET /api/feed/profile` (or `/api/feed/profile/:userId`).
class XProfileScreen extends ConsumerStatefulWidget {
  const XProfileScreen({
    super.key,
    this.appBarTitle = 'Profile',
    this.stitchCommunityChrome = false,
  });

  final String appBarTitle;
  final bool stitchCommunityChrome;

  @override
  ConsumerState<XProfileScreen> createState() => _XProfileScreenState();
}

class _XProfileScreenState extends ConsumerState<XProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xFeedProvider.notifier).loadProfile();
    });
  }

  Color _scaffoldBg(BuildContext context, bool isDark) {
    if (widget.stitchCommunityChrome && context.stitchCommunity != null) {
      return context.stitchCommunity!.warmCanvas;
    }
    return XUi.scaffoldBg(isDark);
  }

  Color _cardBg(BuildContext context, bool isDark) {
    if (widget.stitchCommunityChrome && context.stitchCommunity != null) {
      return context.stitchCommunity!.warmSurface;
    }
    return XUi.cardBg(isDark);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(xFeedProvider);
    final profile = state.profile;
    final bg = _scaffoldBg(context, isDark);
    final card = _cardBg(context, isDark);

    Widget body;
    if (profile != null) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: XUi.divider(isDark)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  child: Text(
                    profile.username.isNotEmpty ? profile.username[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName.isEmpty ? profile.username : profile.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '@${profile.username}',
                        style: TextStyle(color: XUi.secondaryText(isDark)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricCard(label: 'Posts', value: '${profile.postsCount}', cardBg: card, isDark: isDark),
              _MetricCard(label: 'Followers', value: '${profile.followersCount}', cardBg: card, isDark: isDark),
              _MetricCard(label: 'Following', value: '${profile.followingCount}', cardBg: card, isDark: isDark),
            ],
          ),
        ],
      );
    } else if (state.profileLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.profileError != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.profileError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(xFeedProvider.notifier).loadProfile(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(widget.appBarTitle),
      ),
      body: body,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.cardBg,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color cardBg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: XUi.divider(isDark)),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: XUi.secondaryText(isDark))),
          ],
        ),
      ),
    );
  }
}

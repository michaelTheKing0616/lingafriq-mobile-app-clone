import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/x_feed_provider.dart';
import 'package:lingafriq/screens/feed/ui/x_theme.dart';
import 'package:lingafriq/theme/stitch_theme_extensions.dart';

/// Explore / trending — data from `GET /api/feed/explore/trending` only (no mock lists).
class XExploreScreen extends ConsumerStatefulWidget {
  const XExploreScreen({
    super.key,
    this.appBarTitle = 'Explore',
    this.stitchCommunityChrome = false,
    this.onSearchTap,
  });

  final String appBarTitle;
  final bool stitchCommunityChrome;

  /// When set, the search field opens full search (e.g. `/search-community`). No dead CTA.
  final VoidCallback? onSearchTap;

  @override
  ConsumerState<XExploreScreen> createState() => _XExploreScreenState();
}

class _XExploreScreenState extends ConsumerState<XExploreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xFeedProvider.notifier).loadTrending();
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

  Color _accent(BuildContext context) {
    if (widget.stitchCommunityChrome && context.stitchCommunity != null) {
      return context.stitchCommunity!.accentCopper;
    }
    return XUi.accent();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(xFeedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = _scaffoldBg(context, isDark);
    final card = _cardBg(context, isDark);
    final accent = _accent(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(widget.appBarTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(xFeedProvider.notifier).loadTrending(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SearchRow(
                    isDark: isDark,
                    cardBg: card,
                    accent: accent,
                    onSearchTap: widget.onSearchTap,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trending now',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (state.trendingError != null)
                    _TrendingError(
                      message: state.trendingError!,
                      cardBg: card,
                      divider: XUi.divider(isDark),
                      secondary: XUi.secondaryText(isDark),
                      onRetry: () => ref.read(xFeedProvider.notifier).loadTrending(),
                    )
                  else if (state.trending.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        state.trendingLoading ? 'Loading trends…' : 'No trends yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    ...state.trending.map(
                      (item) {
                        final tag = (item['tag'] ?? '').toString();
                        final score = (item['score'] ?? 0).toString();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: XUi.divider(isDark)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: accent.withValues(alpha: 0.15),
                                child: Text('#', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tag.startsWith('#') ? tag : '#$tag',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text('$score score', style: TextStyle(color: XUi.secondaryText(isDark))),
                            ],
                          ),
                        );
                      },
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.isDark,
    required this.cardBg,
    required this.accent,
    this.onSearchTap,
  });

  final bool isDark;
  final Color cardBg;
  final Color accent;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Search hashtags, phrases, topics',
        prefixIcon: Icon(Icons.search, color: accent.withValues(alpha: 0.9)),
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );

    if (onSearchTap == null) {
      return field;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onSearchTap,
        child: IgnorePointer(child: field),
      ),
    );
  }
}

class _TrendingError extends StatelessWidget {
  const _TrendingError({
    required this.message,
    required this.cardBg,
    required this.divider,
    required this.secondary,
    required this.onRetry,
  });

  final String message;
  final Color cardBg;
  final Color divider;
  final Color secondary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

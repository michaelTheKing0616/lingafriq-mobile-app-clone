import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/x_feed_provider.dart';
import 'package:lingafriq/screens/feed/ui/x_theme.dart';

class XExploreScreen extends ConsumerStatefulWidget {
  const XExploreScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(xFeedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: XUi.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: XUi.scaffoldBg(isDark),
        title: const Text('Explore'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(xFeedProvider.notifier).loadTrending(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Search hashtags, phrases, topics',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: XUi.cardBg(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Trending Now',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (state.trending.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: XUi.cardBg(isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  state.loading ? 'Loading trends...' : 'No trends yet.',
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
                      color: XUi.cardBg(isDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: XUi.divider(isDark)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: XUi.accent().withValues(alpha: 0.15),
                          child: Text('#', style: TextStyle(color: XUi.accent(), fontWeight: FontWeight.w700)),
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
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/x_feed_provider.dart';
import 'package:lingafriq/screens/feed/ui/x_theme.dart';

/// Stitch mockup `search_community` — GET /api/feed/explore/search (`posts` | `users` | `hashtags`).
class SearchCommunityScreen extends ConsumerStatefulWidget {
  const SearchCommunityScreen({super.key});

  @override
  ConsumerState<SearchCommunityScreen> createState() => _SearchCommunityScreenState();
}

class _SearchCommunityScreenState extends ConsumerState<SearchCommunityScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _type = 'posts';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(xFeedProvider.notifier).loadFeedSearch(query: raw, type: _type);
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(xFeedProvider.notifier).loadFeedSearch(
          query: _controller.text,
          type: _type,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(xFeedProvider);

    return Scaffold(
      backgroundColor: XUi.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: XUi.scaffoldBg(isDark),
        title: const Text('Search community'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search posts, people, or hashtags',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: XUi.cardBg(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'posts', label: Text('Posts')),
                ButtonSegment(value: 'users', label: Text('People')),
                ButtonSegment(value: 'hashtags', label: Text('Tags')),
              ],
              selected: {_type},
              onSelectionChanged: (s) {
                setState(() => _type = s.first);
                _onQueryChanged(_controller.text);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: state.searchLoading && _controller.text.trim().isNotEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _buildResults(context, isDark, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, bool isDark, XFeedState state) {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Type to search the community feed.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: XUi.secondaryText(isDark)),
          ),
        ],
      );
    }

    if (state.searchError != null && !state.searchLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(state.searchError!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.read(xFeedProvider.notifier).loadFeedSearch(query: q, type: _type),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_type == 'users') {
      if (state.searchUsers.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                state.searchLoading ? 'Searching…' : 'No people found.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        );
      }
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: state.searchUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final u = state.searchUsers[i];
          final name = [
            u['first_name']?.toString() ?? '',
            u['last_name']?.toString() ?? '',
          ].where((e) => e.isNotEmpty).join(' ');
          final handle = u['username']?.toString() ?? '';
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: XUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: XUi.divider(isDark)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: XUi.accent().withValues(alpha: 0.12),
                  child: Text(
                    handle.isNotEmpty ? handle[0].toUpperCase() : '?',
                    style: TextStyle(color: XUi.accent(), fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : handle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (handle.isNotEmpty)
                        Text('@$handle', style: TextStyle(color: XUi.secondaryText(isDark))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (_type == 'hashtags') {
      if (state.searchHashtags.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                state.searchLoading ? 'Searching…' : 'No hashtags found.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        );
      }
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: state.searchHashtags.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final h = state.searchHashtags[i];
          final tag = (h['tag'] ?? '').toString();
          final score = (h['score'] ?? 0).toString();
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: XUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: XUi.divider(isDark)),
            ),
            child: Row(
              children: [
                Text(
                  tag.startsWith('#') ? tag : '#$tag',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(score, style: TextStyle(color: XUi.secondaryText(isDark))),
              ],
            ),
          );
        },
      );
    }

    if (state.searchPosts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              state.searchLoading ? 'Searching…' : 'No posts found.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: state.searchPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = state.searchPosts[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: XUi.cardBg(isDark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: XUi.divider(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.displayName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(p.handle, style: TextStyle(color: XUi.secondaryText(isDark), fontSize: 13)),
              const SizedBox(height: 8),
              Text(p.content, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }
}

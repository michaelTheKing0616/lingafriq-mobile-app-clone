import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/x_feed_provider.dart';
import 'package:lingafriq/screens/feed/ui/x_theme.dart';

class XPostDetailScreen extends ConsumerStatefulWidget {
  const XPostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<XPostDetailScreen> createState() => _XPostDetailScreenState();
}

class _XPostDetailScreenState extends ConsumerState<XPostDetailScreen> {
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xFeedProvider.notifier).loadTimeline(mode: 'for_you');
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(xFeedProvider);
    final selected = state.posts.where((p) => p.id == widget.postId).toList();
    final post = selected.isNotEmpty ? selected.first : null;

    return Scaffold(
      backgroundColor: XUi.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: XUi.scaffoldBg(isDark),
        title: const Text('Post'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: XUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: XUi.divider(isDark)),
            ),
            child: post == null
                ? state.timelineLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Post unavailable', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('ID: ${widget.postId}', style: TextStyle(color: XUi.secondaryText(isDark))),
                        ],
                      )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person_outline)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              post.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.handle,
                            style: TextStyle(color: XUi.secondaryText(isDark)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(post.content.isEmpty ? '(empty post)' : post.content, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Text(
                        '${post.likeCount} likes · ${post.replyCount} replies · ${post.viewCount} views',
                        style: TextStyle(color: XUi.secondaryText(isDark)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(onPressed: () => ref.read(xFeedProvider.notifier).toggleLike(post.id), icon: const Icon(Icons.favorite_border_rounded)),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.repeat_rounded)),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border_rounded)),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: XUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: XUi.divider(isDark)),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                      hintText: 'Post your reply',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    _replyController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply queued')));
                  },
                  style: FilledButton.styleFrom(backgroundColor: XUi.accent()),
                  child: const Text('Reply'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

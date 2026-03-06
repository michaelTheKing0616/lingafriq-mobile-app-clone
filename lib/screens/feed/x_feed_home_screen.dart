import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/x_feed_provider.dart';
import 'package:lingafriq/screens/feed/ui/x_theme.dart';

class XFeedHomeScreen extends ConsumerStatefulWidget {
  const XFeedHomeScreen({super.key});

  @override
  ConsumerState<XFeedHomeScreen> createState() => _XFeedHomeScreenState();
}

class _XFeedHomeScreenState extends ConsumerState<XFeedHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabs.indexIsChanging) return;
        final mode = _tabs.index == 0 ? 'for_you' : 'following';
        ref.read(xFeedProvider.notifier).loadTimeline(mode: mode);
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xFeedProvider.notifier).loadTimeline(mode: 'for_you');
      ref.read(xFeedProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(xFeedProvider);

    return Scaffold(
      backgroundColor: XUi.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: XUi.scaffoldBg(isDark),
        elevation: 0,
        title: const Text('LingAfriq Feed'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/x-profile'),
            icon: const Icon(Icons.person_outline_rounded),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/x-notifications'),
                icon: const Icon(Icons.notifications_none),
              ),
              if ((state.profile?.unreadNotifications ?? 0) > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.profile!.unreadNotifications}',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: XUi.accent(),
          tabs: const [Tab(text: 'For You'), Tab(text: 'Following')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/x-compose'),
        backgroundColor: XUi.accent(),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Post'),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          final mode = _tabs.index == 0 ? 'for_you' : 'following';
          return ref.read(xFeedProvider.notifier).loadTimeline(mode: mode);
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(state.errorMessage!),
              ),
            if (state.loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )),
            if (!state.loading && state.posts.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: XUi.cardBg(isDark), borderRadius: BorderRadius.circular(14)),
                child: const Text('Your feed is quiet. Create a post to start the conversation.'),
              ),
            ...state.posts.map(
              (post) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: XUi.cardBg(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: XUi.divider(isDark)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pushNamed(context, '/x-post-detail', arguments: {'postId': post.id}),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(radius: 16, child: Icon(Icons.person_outline, size: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(post.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            Text('${post.viewCount} views', style: TextStyle(color: XUi.secondaryText(isDark), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(post.content.isEmpty ? '(empty post)' : post.content),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => ref.read(xFeedProvider.notifier).toggleLike(post.id),
                              icon: const Icon(Icons.favorite_border_rounded),
                            ),
                            Text('${post.likeCount}', style: TextStyle(color: XUi.secondaryText(isDark))),
                            const SizedBox(width: 10),
                            const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                            const SizedBox(width: 4),
                            Text('${post.replyCount}', style: TextStyle(color: XUi.secondaryText(isDark))),
                            const Spacer(),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.repeat_rounded)),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

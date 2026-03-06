import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/x_feed_provider.dart';
import 'package:lingafriq/screens/feed/ui/x_theme.dart';

class XProfileScreen extends ConsumerStatefulWidget {
  const XProfileScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(xFeedProvider);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: XUi.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: XUi.scaffoldBg(isDark),
        title: const Text('Profile'),
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: XUi.cardBg(isDark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: XUi.divider(isDark)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 26, child: Icon(Icons.person_outline)),
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
                    _MetricCard(label: 'Posts', value: '${profile.postsCount}'),
                    _MetricCard(label: 'Followers', value: '${profile.followersCount}'),
                    _MetricCard(label: 'Following', value: '${profile.followingCount}'),
                  ],
                ),
              ],
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: XUi.cardBg(isDark),
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

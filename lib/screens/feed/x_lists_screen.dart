import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/x_feed_provider.dart';
import 'package:lingafriq/screens/feed/ui/x_theme.dart';

class XListsScreen extends ConsumerStatefulWidget {
  const XListsScreen({super.key});

  @override
  ConsumerState<XListsScreen> createState() => _XListsScreenState();
}

class _XListsScreenState extends ConsumerState<XListsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xFeedProvider.notifier).loadLists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(xFeedProvider);

    return Scaffold(
      backgroundColor: XUi.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: XUi.scaffoldBg(isDark),
        title: const Text('Lists'),
        actions: [
          IconButton(onPressed: () => ref.read(xFeedProvider.notifier).loadLists(), icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Curate your learning circles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Group people and topics into focused spaces for language practice.',
            style: TextStyle(color: XUi.secondaryText(isDark)),
          ),
          const SizedBox(height: 16),
          if (state.listsLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          if (state.listsError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: Text(state.listsError!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
                      TextButton(
                        onPressed: () => ref.read(xFeedProvider.notifier).loadLists(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!state.listsLoading && state.lists.isEmpty && state.listsError == null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: XUi.cardBg(isDark), borderRadius: BorderRadius.circular(14)),
              child: const Text('No lists yet. Create one from the backend to see it here.'),
            ),
          ...state.lists.map(
            (item) {
              final name = (item['name'] ?? 'Untitled list').toString();
              final description = (item['description'] ?? '').toString();
              final followers = (item['follower_ids'] is List) ? (item['follower_ids'] as List).length : 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: XUi.cardBg(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: XUi.divider(isDark)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        Text('$followers followers', style: TextStyle(color: XUi.secondaryText(isDark))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description.isEmpty ? 'No description yet.' : description,
                      style: TextStyle(color: XUi.secondaryText(isDark)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

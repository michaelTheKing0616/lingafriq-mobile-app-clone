import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/wa_status_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class WaStatusListScreen extends ConsumerStatefulWidget {
  const WaStatusListScreen({super.key});

  @override
  ConsumerState<WaStatusListScreen> createState() => _WaStatusListScreenState();
}

class _WaStatusListScreenState extends ConsumerState<WaStatusListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(waStatusProvider.notifier).loadMine();
      await ref.read(waStatusProvider.notifier).loadFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(waStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.cardLight;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? PanAfricanGradients.darkSurface : PanAfricanGradients.savannaGold,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(waStatusProvider.notifier).loadMine();
              await ref.read(waStatusProvider.notifier).loadFeed();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share moments with your learning circle.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (state.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(state.errorMessage!)),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/wa-status-create'),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Create status'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/wa-starred'),
                        icon: const Icon(Icons.star_border),
                        label: const Text('Starred'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/wa-media-gallery'),
                  icon: const Icon(Icons.collections_outlined),
                  label: const Text('Media gallery'),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'My status',
                  child: state.mine.isEmpty
                      ? const _EmptyLine(text: 'No active status yet.')
                      : Column(
                          children: state.mine
                              .map(
                                (status) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person_outline),
                                  ),
                                  title: Text(
                                    status.caption.isEmpty ? status.text : status.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(status.mediaType),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/wa-status-view',
                                    arguments: {'statusId': status.id},
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Recent updates',
                  child: state.loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : state.feed.isEmpty
                          ? const _EmptyLine(text: 'No updates from contacts right now.')
                          : Column(
                              children: state.feed
                                  .map(
                                    (status) => Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark
                                              ? PanAfricanColors.borderDark
                                              : PanAfricanColors.borderLight,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 22,
                                            child: Icon(Icons.person),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  status.caption.isEmpty
                                                      ? (status.text.isEmpty ? 'Status update' : status.text)
                                                      : status.caption,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(fontWeight: FontWeight.w700),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  status.mediaType.toUpperCase(),
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => Navigator.pushNamed(
                                              context,
                                              '/wa-status-view',
                                              arguments: {'statusId': status.id},
                                            ),
                                            icon: const Icon(Icons.play_arrow_rounded),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

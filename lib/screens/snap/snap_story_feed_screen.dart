import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/snap_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/empty_state_widget.dart';

class SnapStoryFeedScreen extends ConsumerStatefulWidget {
  const SnapStoryFeedScreen({super.key});

  @override
  ConsumerState<SnapStoryFeedScreen> createState() => _SnapStoryFeedScreenState();
}

class _SnapStoryFeedScreenState extends ConsumerState<SnapStoryFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(snapProvider.notifier).loadStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(snapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Stories')),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? PanAfricanGradients.darkSurface : PanAfricanGradients.sunset,
        ),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => ref.read(snapProvider.notifier).loadStories(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 4),
                Text(
                  'Language moments from your community.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/snap-camera'),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Create story'),
                ),
                const SizedBox(height: 12),
                if (state.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(state.errorMessage!),
                  ),
                if (state.loading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ))
                else if (state.stories.isEmpty)
                  const AppEmptyState(
                    icon: Icons.auto_stories_outlined,
                    title: 'No stories right now',
                    subtitle: 'Stories from friends will show up here.',
                  )
                else
                  ...state.stories.map(
                    (story) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? PanAfricanColors.surfaceContainerDark
                            : PanAfricanColors.cardLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.play_circle_outline_rounded)),
                        title: Text(story.caption.isEmpty ? 'Story update' : story.caption),
                        subtitle: Text(story.mediaType.toUpperCase()),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/snap-viewer',
                          arguments: {'storyId': story.id},
                        ),
                      ),
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

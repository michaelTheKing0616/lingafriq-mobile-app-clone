import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// copy_keys: stories.title, stories.copy.warning (P9-957).
const String kStoriesTitle = 'Circle stories';
const String kStoriesCopyWarning =
    'Stories disappear after 24 hours. Screenshots and reshares are not blocked — share thoughtfully.';
const String kStoriesEmpty =
    'No stories yet. Be the first to share a language moment with your circle.';
const String kStoriesOffline =
    'You are offline. Pull to refresh when you reconnect.';
const String kStoriesMemberOnly =
    'Only members of this circle can view these stories.';
const String kStoriesExpired = 'That story has expired.';

const List<String> kStoryLanguageTags = [
  'yo',
  'ig',
  'ha',
  'pcm',
  'sw',
  'zu',
  'xh',
  'tw',
  'am',
  'ti',
];

/// Circle-scoped disappearing stories — reference: WhatsApp Status + Instagram Close Friends.
class CircleStoriesScreen extends HookConsumerWidget {
  const CircleStoriesScreen({
    super.key,
    required this.circleId,
    this.circleName,
    this.storiesLoader,
    this.storyPoster,
  });

  final String circleId;
  final String? circleName;
  final Future<Map<String, dynamic>> Function(String circleId)? storiesLoader;
  final Future<Map<String, dynamic>> Function({
    required String circleId,
    required String languageTag,
    required String mediaKind,
    required List<int> mediaBytes,
    String caption,
  })? storyPoster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = useState<List<Map<String, dynamic>>>([]);
    final loading = useState(true);
    final error = useState<String?>(null);
    final viewerIndex = useState(0);
    final showViewer = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> load() async {
      loading.value = true;
      error.value = null;
      try {
        final res = storiesLoader != null
            ? await storiesLoader!(circleId)
            : (await ApiService.get('/api/v2/circle-stories/circle/$circleId')).data;
        if (res is! Map || res['ok'] != true) {
          error.value = kStoriesMemberOnly;
          stories.value = [];
          return;
        }
        final list = res['stories'];
        if (list is List) {
          stories.value =
              list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          stories.value = [];
        }
      } catch (_) {
        error.value = kStoriesOffline;
      } finally {
        loading.value = false;
      }
    }

    useEffect(() {
      load();
      return null;
    }, [circleId]);

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          circleName == null ? kStoriesTitle : '$kStoriesTitle · ${circleName!}',
          style: PanAfricanTypography.titleLarge(context),
        ),
      ),
      body: ResponsiveSafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Material(
                color: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.cardLight,
                borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                child: Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: PanAfricanColors.warning,
                        semanticLabel: 'Story privacy notice',
                      ),
                      SizedBox(width: PanAfricanSpacing.sm),
                      Expanded(
                        child: Text(
                          kStoriesCopyWarning,
                          style: PanAfricanTypography.bodyMedium(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: load,
                child: _body(
                  context,
                  loading.value,
                  error.value,
                  stories.value,
                  load,
                  onOpenStory: (index) {
                    viewerIndex.value = index;
                    showViewer.value = true;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openComposer(context, load),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add story'),
      ),
      bottomSheet: showViewer.value && stories.value.isNotEmpty
          ? _StoryViewerSheet(
              stories: stories.value,
              initialIndex: viewerIndex.value,
              onClose: () => showViewer.value = false,
            )
          : null,
    );
  }

  Future<void> _openComposer(BuildContext context, Future<void> Function() reload) async {
    String languageTag = kStoryLanguageTags.first;
    final captionCtrl = TextEditingController();
    final picked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: PanAfricanSpacing.lg,
            right: PanAfricanSpacing.lg,
            top: PanAfricanSpacing.md,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + PanAfricanSpacing.lg,
          ),
          child: StatefulBuilder(
            builder: (context, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Share a story', style: PanAfricanTypography.titleMedium(context)),
                  SizedBox(height: PanAfricanSpacing.md),
                  DropdownButtonFormField<String>(
                    value: languageTag,
                    decoration: const InputDecoration(labelText: 'Language tag'),
                    items: kStoryLanguageTags
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => languageTag = v);
                    },
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  TextField(
                    controller: captionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Caption (optional)',
                      hintText: 'What phrase are you practising?',
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Post demo photo'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    if (picked != true || !context.mounted) return;

    const demoBytes = [0xff, 0xd8, 0xff, 0xd9];
    try {
      final payload = {
        'circleId': circleId,
        'languageTag': languageTag,
        'caption': captionCtrl.text.trim(),
        'mediaKind': 'image',
        'mediaBase64': base64Encode(demoBytes),
      };
      if (storyPoster != null) {
        await storyPoster!(
          circleId: circleId,
          languageTag: languageTag,
          mediaKind: 'image',
          mediaBytes: demoBytes,
          caption: captionCtrl.text.trim(),
        );
      } else {
        await ApiService.post('/api/v2/circle-stories', data: payload);
      }
      await reload();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story shared with your circle.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(kStoriesOffline)),
        );
      }
    }
  }

  Widget _body(
    BuildContext context,
    bool loading,
    String? error,
    List<Map<String, dynamic>> items,
    Future<void> Function() reload, {
    required void Function(int index) onOpenStory,
  }) {
    if (loading && items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (error != null && items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        children: [
          Text(error, style: PanAfricanTypography.bodyLarge(context)),
          SizedBox(height: PanAfricanSpacing.md),
          FilledButton(onPressed: reload, child: const Text('Try again')),
        ],
      );
    }
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        children: [
          Text(kStoriesEmpty, style: PanAfricanTypography.bodyLarge(context)),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.md,
        vertical: PanAfricanSpacing.sm,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.sm),
      itemBuilder: (context, index) {
        final story = items[index];
        final tag = (story['language_tag'] as String? ?? '').toUpperCase();
        final name = story['uploader_display'] as String? ?? 'Learner';
        final caption = story['caption'] as String? ?? '';
        return Semantics(
          button: true,
          label: 'Open story from $name in $tag',
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              onTap: () => onOpenStory(index),
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(tag.isNotEmpty ? tag.characters.first : 'L'),
                    ),
                    SizedBox(width: PanAfricanSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: PanAfricanTypography.titleSmall(context)),
                          if (caption.isNotEmpty)
                            Text(
                              caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: PanAfricanTypography.bodyMedium(context),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StoryViewerSheet extends StatelessWidget {
  const _StoryViewerSheet({
    required this.stories,
    required this.initialIndex,
    required this.onClose,
  });

  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final story = stories[initialIndex.clamp(0, stories.length - 1)];
    final caption = story['caption'] as String? ?? '';
    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.72,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                tooltip: 'Close story',
              ),
            ),
            Expanded(
              child: Center(
                child: Icon(
                  story['media_kind'] == 'video'
                      ? Icons.play_circle_fill
                      : Icons.image_outlined,
                  size: 120,
                  semanticLabel: 'Story media preview',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Text(
                caption.isEmpty ? kStoriesTitle : caption,
                style: PanAfricanTypography.bodyLarge(context),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                PanAfricanSpacing.lg,
                0,
                PanAfricanSpacing.lg,
                PanAfricanSpacing.lg,
              ),
              child: Text(
                kStoriesCopyWarning,
                style: PanAfricanTypography.bodySmall(context).copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

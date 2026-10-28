import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/providers/tts_provider.dart';
import 'package:lingafriq/services/tts/dynamic_tts_label.dart';
import 'story_tts_policy.dart';
import 'story_types.dart';

enum StoryUiState { generating, ready, pendingReview, error }

/// P6-027: lexicon-grounded micro-stories via gateway (no on-device LLM).
class StoryModeScreen extends HookConsumerWidget {
  const StoryModeScreen({
    super.key,
    required this.session,
    this.onSubmitToSharedLibrary,
  });

  final StorySession session;
  final VoidCallback? onSubmitToSharedLibrary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGloss = useState<StoryGlossEntry?>(null);
    final quizIndex = useState<int?>(null);
    final uiState = useMemoized(() {
      switch (session.visibility) {
        case StoryVisibility.pendingShared:
          return StoryUiState.pendingReview;
        case StoryVisibility.personal:
        case StoryVisibility.sharedApproved:
          return StoryUiState.ready;
      }
    }, [session.visibility]);

    final ttsRoute = useMemoized(
      () => resolveStoryTtsRoute(session.language),
      [session.language],
    );

    Future<void> narrateParagraph(String text) async {
      if (!storyAudioUsesServerTts(ttsRoute)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ttsRoute.blockReason ?? 'Audio unavailable')),
          );
        }
        return;
      }
      await ref.read(ttsProvider.notifier).speak(
            text,
            languageName: session.language,
            speed: 0.9,
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(session.title),
        actions: [
          if (session.visibility == StoryVisibility.personal &&
              onSubmitToSharedLibrary != null)
            TextButton(
              onPressed: onSubmitToSharedLibrary,
              child: const Text('Share'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(session.aiGeneratedLabel),
                visualDensity: VisualDensity.compact,
              ),
              const DynamicTtsHonestyLabel(source: DynamicSpeechSource.polie),
            ],
          ),
          if (uiState == StoryUiState.pendingReview)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Pending human review — not visible in the shared library yet.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: session.paragraphs.length,
            itemBuilder: (context, index) {
              final paragraph = session.paragraphs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      paragraph,
                      onTap: () {
                        for (final gloss in session.glosses) {
                          if (paragraph.contains(gloss.surface)) {
                            selectedGloss.value = gloss;
                            HapticFeedback.selectionClick();
                            break;
                          }
                        }
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => narrateParagraph(paragraph),
                        icon: const Icon(Icons.volume_up, size: 18),
                        label: const Text('Listen'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (selectedGloss.value != null)
            Card(
              child: ListTile(
                title: Text(selectedGloss.value!.surface),
                subtitle: Text(selectedGloss.value!.glossL1),
                trailing: Text(
                  selectedGloss.value!.lexemeId,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Comprehension',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: session.comprehension.length,
            itemBuilder: (context, index) {
              final q = session.comprehension[index];
              return Card(
                child: ExpansionTile(
                  title: Text(q.questionL1),
                  onExpansionChanged: (open) {
                    quizIndex.value = open ? index : null;
                  },
                  children: q.optionsL1
                      .map(
                        (opt) => ListTile(
                          title: Text(opt),
                          onTap: () {
                            final correct = q.optionsL1[q.correctIndex] == opt;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(correct ? 'Correct' : 'Try again'),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(growable: false),
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

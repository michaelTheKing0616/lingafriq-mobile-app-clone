import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/quest_provider.dart';
import '../../models/quest_model.dart';

/// "The Great Journey" Quest/Story Mode Screen
class QuestScreen extends ConsumerWidget {
  const QuestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questProvider = ref.watch(questProvider.notifier);
    final chapters = questProvider.chapters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Great Journey'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('The Great Journey'),
                  content: const Text(
                    'Embark on an epic 12-chapter adventure across Africa! '
                    'Each chapter teaches you a new language and culture. '
                    'Complete lessons to unlock the next chapter and earn rewards!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          final progress = questProvider.getChapterProgress(chapter.id);

          return _ChapterCard(
            chapter: chapter,
            progress: progress,
            onTap: chapter.isUnlocked
                ? () {
                    // Navigate to chapter details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _ChapterDetailScreen(chapter: chapter),
                      ),
                    );
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final QuestChapter chapter;
  final double progress;
  final VoidCallback? onTap;

  const _ChapterCard({
    required this.chapter,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: chapter.isUnlocked ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: chapter.isUnlocked ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      chapter.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chapter ${chapter.chapterNumber}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            chapter.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (chapter.isCompleted)
                      const Icon(Icons.check_circle, color: Colors.green),
                    if (!chapter.isUnlocked)
                      const Icon(Icons.lock, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  chapter.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (chapter.isUnlocked && !chapter.isCompleted) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${chapter.lessons.where((l) => l.isCompleted).length}/${chapter.lessons.length} lessons',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (chapter.isUnlocked) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${chapter.xpReward} XP',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (chapter.badgeReward != null) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.workspace_premium, size: 16, color: Colors.purple),
                        const SizedBox(width: 4),
                        Text(
                          'Badge',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterDetailScreen extends ConsumerWidget {
  final QuestChapter chapter;

  const _ChapterDetailScreen({required this.chapter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chapter.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Chapter header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chapter.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (chapter.metadata != null) ...[
                    const SizedBox(height: 16),
                    ...chapter.metadata!.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text(
                                '${e.key}: ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(e.value.toString()),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lessons
          Text(
            'Lessons',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...chapter.lessons.map((lesson) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: lesson.isCompleted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    child: lesson.isCompleted
                        ? const Icon(Icons.check, color: Colors.white)
                        : Text(
                            '${lesson.order}',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                  title: Text(lesson.title),
                  subtitle: Text(lesson.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${lesson.xpReward} XP'),
                    ],
                  ),
                  onTap: lesson.isCompleted
                      ? null
                      : () {
                          // Start lesson
                          // TODO: Navigate to lesson screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Starting: ${lesson.title}'),
                            ),
                          );
                        },
                ),
              )),
        ],
      ),
    );
  }
}


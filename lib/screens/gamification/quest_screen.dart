import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/quest_provider.dart';
import '../../providers/gamification_services_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/ai_chat_provider_groq.dart';
import '../../models/quest_model.dart';
import '../../services/gamification/journey_service.dart';
import '../../services/gamification/polie_story_generator.dart';
import '../../widgets/error_boundary.dart';
import '../../screens/loading/dynamic_loading_screen.dart';

/// "The Great Journey" Quest/Story Mode Screen
class QuestScreen extends ConsumerStatefulWidget {
  const QuestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends ConsumerState<QuestScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to journey updates via Socket.io (if available)
    // Journey updates would come through user inbox notifications
  }

  @override
  Widget build(BuildContext context) {
    final questNotifier = ref.watch(questProvider.notifier);
    final chapters = questNotifier.chapters;

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
          final progress = questNotifier.getChapterProgress(chapter.id);

          return _ChapterCard(
            chapter: chapter,
            progress: progress,
            onTap: chapter.isUnlocked
                ? () {
                    // Navigate to chapter details
                    Navigator.push(
                      context,
                      SmoothPageRoute(
                        child: _ChapterDetailScreen(chapter: chapter),
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

class _ChapterDetailScreen extends ConsumerStatefulWidget {
  final QuestChapter chapter;

  const _ChapterDetailScreen({required this.chapter});

  @override
  ConsumerState<_ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends ConsumerState<_ChapterDetailScreen> {
  bool _isGeneratingStory = false;
  bool _isGeneratingLessons = false;
  ChapterStory? _generatedStory;
  List<QuestLesson> _generatedLessons = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateStoryAndLessons();
  }

  Future<void> _generateStoryAndLessons() async {
    setState(() {
      _isGeneratingStory = true;
      _isGeneratingLessons = true;
      _errorMessage = null;
    });

    try {
      final polieProvider = ref.read(groqChatProvider.notifier);
      final storyGenerator = PolieStoryGenerator(polieProvider);
      
      // Get target language from chapter metadata or default
      final targetLanguage = widget.chapter.metadata?['language']?.toString() ?? 'Yoruba';
      
      // Get user progress
      final questNotifier = ref.read(questProvider.notifier);
      final completedChapters = questNotifier.completedChapters;
      final progressText = completedChapters.map((c) => c.title).join(', ');
      
      // Generate story and lessons in parallel
      final results = await Future.wait([
        storyGenerator.generateChapterStory(
          chapter: widget.chapter,
          targetLanguage: targetLanguage,
          userProgress: progressText.isNotEmpty ? progressText : null,
        ),
        storyGenerator.generateChapterLessons(
          chapter: widget.chapter,
          targetLanguage: targetLanguage,
          lessonCount: widget.chapter.lessons.length,
        ),
      ]);

      if (mounted) {
        setState(() {
          _generatedStory = results[0] as ChapterStory;
          _generatedLessons = results[1] as List<QuestLesson>;
          _isGeneratingStory = false;
          _isGeneratingLessons = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating story/lessons: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate story. Please try again.';
          _isGeneratingStory = false;
          _isGeneratingLessons = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGeneratingStory || _isGeneratingLessons) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.chapter.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const DynamicLoadingScreen(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.chapter.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _generateStoryAndLessons,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Chapter header with generated story
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chapter.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.chapter.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (_generatedStory != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Story',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _generatedStory!.story,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_generatedStory!.vocabulary.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Key Vocabulary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ..._generatedStory!.vocabulary.map((vocab) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${vocab.word} - ${vocab.translation}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    if (_generatedStory!.culturalNotes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Cultural Notes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _generatedStory!.culturalNotes,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lessons (use generated lessons if available, otherwise fallback to chapter lessons)
          Text(
            'Lessons',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...(_generatedLessons.isNotEmpty ? _generatedLessons : widget.chapter.lessons).map((lesson) => Card(
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
                      : () async {
                          // Navigate to lesson screen (to be implemented)
                          // For now, complete lesson via quest provider
                          final questNotifier = ref.read(questProvider.notifier);
                          await questNotifier.completeLesson(lesson.id);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Completed: ${lesson.title}! +${lesson.xpReward} XP'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context); // Return to chapter list
                          }
                        },
                ),
              )),
        ],
      ),
    );
  }
}


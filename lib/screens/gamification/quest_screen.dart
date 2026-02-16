import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import '../../utils/error_handler.dart';
import '../../utils/performance_utils.dart';
import '../../providers/quest_provider.dart';
import '../../providers/ai_chat_provider_groq.dart';
import '../../models/quest_model.dart';
import '../../services/gamification/polie_story_generator.dart';
import '../../screens/loading/dynamic_loading_screen.dart';
import '../../widgets/animations/smooth_transitions.dart';

/// "The Great Journey" Quest/Story Mode Screen
class QuestScreen extends ConsumerStatefulWidget {
  const QuestScreen({super.key});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'The Great Journey',
          style: PanAfricanTypography.headlineMedium(context),
        ),
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          Semantics(
            label: 'About The Great Journey',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.info_outline, semanticLabel: 'Info'),
              onPressed: () {
              HapticFeedback.lightImpact();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: PanAfricanRadius.lgBR,
                  ),
                  title: Text(
                    'The Great Journey',
                    style: PanAfricanTypography.titleLarge(context),
                  ),
                  content: Text(
                    'Embark on an epic 12-chapter adventure across Africa! '
                    'Each chapter teaches you a new language and culture. '
                    'Complete lessons to unlock the next chapter and earn rewards!',
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Got it',
                        style: PanAfricanTypography.labelLarge(
                          context,
                          color: PanAfricanColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ),
        ],
      ),
      body: OptimizedListView.builder(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          final progress = questNotifier.getChapterProgress(chapter.id);

          return _ChapterCard(
            chapter: chapter,
            progress: progress,
            isDark: isDark,
            onTap: chapter.isUnlocked
                ? () {
                    HapticFeedback.lightImpact();
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
  final bool isDark;
  final VoidCallback? onTap;

  const _ChapterCard({
    required this.chapter,
    required this.progress,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chapter ${chapter.chapterNumber}: ${chapter.title}. ${chapter.isUnlocked ? (chapter.isCompleted ? "Completed" : "${(progress * 100).toStringAsFixed(0)}% progress") : "Locked"}',
      button: onTap != null,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.lgBR,
          border: Border.all(
            color: chapter.isCompleted
                ? PanAfricanColors.success
                : (isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
            width: chapter.isCompleted ? 2 : 1,
          ),
          boxShadow: chapter.isUnlocked ? PanAfricanShadows.md : PanAfricanShadows.sm,
        ),
        child: Opacity(
          opacity: chapter.isUnlocked ? 1.0 : 0.6,
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: chapter.isCompleted
                            ? PanAfricanColors.success.withOpacity(0.15)
                            : PanAfricanColors.primaryContainer,
                        borderRadius: PanAfricanRadius.mdBR,
                      ),
                      child: Center(
                        child: Text(
                          chapter.icon,
                          style: TextStyle(fontSize: 28.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chapter ${chapter.chapterNumber}',
                            style: PanAfricanTypography.labelSmall(context),
                          ),
                          Text(
                            chapter.title,
                            style: PanAfricanTypography.titleMedium(context),
                          ),
                        ],
                      ),
                    ),
                    if (chapter.isCompleted)
                      Container(
                        padding: EdgeInsets.all(PanAfricanSpacing.xxs),
                        decoration: BoxDecoration(
                          color: PanAfricanColors.success.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: PanAfricanColors.success,
                          size: 24.sp,
                        ),
                      ),
                    if (!chapter.isUnlocked)
                      Icon(
                        Icons.lock_rounded,
                        color: PanAfricanColors.neutralMedium,
                        size: 24.sp,
                      ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  chapter.description,
                  style: PanAfricanTypography.bodyMedium(context),
                ),
                if (chapter.isUnlocked && !chapter.isCompleted) ...[
                  SizedBox(height: PanAfricanSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: isDark
                                ? PanAfricanColors.surfaceContainerHighDark
                                : PanAfricanColors.surfaceContainerHighLight,
                            borderRadius: PanAfricanRadius.roundBR,
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: PanAfricanGradients.forest,
                                borderRadius: PanAfricanRadius.roundBR,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.xs),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: PanAfricanTypography.labelSmall(context),
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    '${chapter.lessons.where((l) => l.isCompleted).length}/${chapter.lessons.length} lessons',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ],
                if (chapter.isUnlocked) ...[
                  SizedBox(height: PanAfricanSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 18.sp,
                        color: PanAfricanColors.secondary,
                      ),
                      SizedBox(width: PanAfricanSpacing.xxs),
                      Text(
                        '${chapter.xpReward} XP',
                        style: PanAfricanTypography.labelSmall(
                          context,
                          color: PanAfricanColors.secondary,
                        ),
                      ),
                      if (chapter.badgeReward != null) ...[
                        SizedBox(width: PanAfricanSpacing.md),
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 18.sp,
                          color: PanAfricanColors.ankaraPurple,
                        ),
                        SizedBox(width: PanAfricanSpacing.xxs),
                        Text(
                          'Badge',
                          style: PanAfricanTypography.labelSmall(
                            context,
                            color: PanAfricanColors.ankaraPurple,
                          ),
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
      if (mounted) {
        ErrorHandler.showError(context, e);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isGeneratingStory || _isGeneratingLessons) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.chapter.title,
            style: PanAfricanTypography.headlineMedium(context),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        body: const DynamicLoadingScreen(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.chapter.title,
            style: PanAfricanTypography.headlineMedium(context),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64.sp,
                  color: PanAfricanColors.error,
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Text(
                  _errorMessage!,
                  style: PanAfricanTypography.bodyLarge(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: PanAfricanSpacing.lg),
                FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _generateStoryAndLessons();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chapter.title,
          style: PanAfricanTypography.headlineMedium(context),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter header with generated story
            Container(
              decoration: BoxDecoration(
                color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                borderRadius: PanAfricanRadius.lgBR,
                border: Border.all(
                  color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                ),
                boxShadow: PanAfricanShadows.sm,
              ),
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chapter.icon,
                    style: TextStyle(fontSize: 48.sp),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Text(
                    widget.chapter.description,
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                  if (_generatedStory != null) ...[
                    SizedBox(height: PanAfricanSpacing.md),
                    Divider(color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
                    SizedBox(height: PanAfricanSpacing.md),
                    Text(
                      'Story',
                      style: PanAfricanTypography.titleMedium(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(
                      _generatedStory!.story,
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                    if (_generatedStory!.vocabulary.isNotEmpty) ...[
                      SizedBox(height: PanAfricanSpacing.md),
                      Divider(color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
                      SizedBox(height: PanAfricanSpacing.sm),
                      Text(
                        'Key Vocabulary',
                        style: PanAfricanTypography.titleMedium(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                      ..._generatedStory!.vocabulary.map((vocab) => Padding(
                            padding: EdgeInsets.only(bottom: PanAfricanSpacing.xxs),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6.sp,
                                  color: PanAfricanColors.primary,
                                ),
                                SizedBox(width: PanAfricanSpacing.xs),
                                Expanded(
                                  child: Text(
                                    '${vocab.word} - ${vocab.translation}',
                                    style: PanAfricanTypography.bodySmall(context),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    if (_generatedStory!.culturalNotes.isNotEmpty) ...[
                      SizedBox(height: PanAfricanSpacing.md),
                      Divider(color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
                      SizedBox(height: PanAfricanSpacing.sm),
                      Text(
                        'Cultural Notes',
                        style: PanAfricanTypography.titleMedium(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                      Text(
                        _generatedStory!.culturalNotes,
                        style: PanAfricanTypography.bodySmall(context),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            // Lessons
            Text(
              'Lessons',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            ...(_generatedLessons.isNotEmpty ? _generatedLessons : widget.chapter.lessons).map((lesson) => _buildLessonCard(context, lesson, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, QuestLesson lesson, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: lesson.isCompleted
          ? null
          : () async {
              HapticFeedback.lightImpact();
              final questNotifier = ref.read(questProvider.notifier);
              await questNotifier.completeLesson(lesson.id);

              if (context.mounted) {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Completed: ${lesson.title}! +${lesson.xpReward} XP',
                      style: PanAfricanTypography.bodyMedium(context, color: colorScheme.onPrimary),
                    ),
                    backgroundColor: PanAfricanColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
                  ),
                );
                Navigator.pop(context);
              }
            },
      child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.lgBR,
          border: Border.all(
            color: lesson.isCompleted
                ? PanAfricanColors.success
                : (isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
          ),
          boxShadow: PanAfricanShadows.sm,
        ),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: lesson.isCompleted
                      ? PanAfricanColors.success
                      : PanAfricanColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: lesson.isCompleted
                      ? Icon(Icons.check_rounded, color: colorScheme.onPrimary, size: 20.sp)
                      : Text(
                          '${lesson.order}',
                          style: PanAfricanTypography.titleSmall(context, color: colorScheme.onPrimary),
                        ),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: PanAfricanTypography.titleSmall(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.xxxs),
                    Text(
                      lesson.description,
                      style: PanAfricanTypography.bodySmall(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 16.sp,
                    color: PanAfricanColors.secondary,
                  ),
                  SizedBox(width: PanAfricanSpacing.xxs),
                  Text(
                    '${lesson.xpReward} XP',
                    style: PanAfricanTypography.labelSmall(
                      context,
                      color: PanAfricanColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


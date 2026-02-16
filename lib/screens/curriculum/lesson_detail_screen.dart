import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:lingafriq/services/curriculum_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lingafriq/services/deep_link_service.dart';
import 'package:lingafriq/providers/offline_download_provider.dart';
import 'package:lingafriq/widgets/performance/optimized_list_view.dart';

/// Detailed lesson screen with AI-generated content
class LessonDetailScreen extends ConsumerStatefulWidget {
  final CurriculumLesson lesson;
  final String language;
  final String level;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.language,
    required this.level,
  });

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  Map<String, dynamic>? _generatedContent;
  bool _isGenerating = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _generateContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generateContent() async {
    setState(() {
      _isGenerating = true;
      _hasError = false;
      _errorMessage = null;
    });
    
    try {
      final curriculumService = ref.read(curriculumServiceProvider);
      final vocabObjects = widget.lesson.vocabObjects;
      final grammar = widget.lesson.grammar ?? const <String>[];
      
      // Add timeout to prevent endless loading
      final content = await curriculumService.generateLessonContent(
        language: widget.language,
        level: widget.level,
        lessonTitle: widget.lesson.title,
        vocab: vocabObjects.map((v) => v.toMap()).toList(),
        grammar: grammar,
        topic: widget.lesson.title,
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException('Content generation timed out');
        },
      );
      
      if (mounted) {
        setState(() {
          _generatedContent = content;
          _isGenerating = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasError = true;
          _errorMessage = 'Content generation is taking longer than expected. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasError = true;
          _errorMessage = 'Failed to generate lesson content. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lessonIdStr = widget.lesson.id.toString();
    final isDownloaded = lessonIdStr.isNotEmpty &&
        ref.watch(offlineDownloadProvider).downloadedLessonIds.contains(lessonIdStr);

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(widget.lesson.title)),
            if (isDownloaded)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Chip(
                  avatar: Icon(Icons.download_done, size: 16, color: Theme.of(context).colorScheme.primary),
                  label: Text('Offline', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        backgroundColor:
            isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        foregroundColor:
            isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
        actions: [
          Builder(
            builder: (context) {
              final offlineState = ref.watch(offlineDownloadProvider);
              final isDownloadingThis = offlineState.currentDownloadingLessonId == lessonIdStr;
              if (isDownloadingThis) {
                return IconButton(
                  icon: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onPressed: null,
                  tooltip: 'Downloading...',
                );
              }
              if (isDownloaded) {
                return IconButton(
                  icon: Icon(Icons.download_done, color: Theme.of(context).colorScheme.primary),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remove offline download?'),
                        content: const Text(
                          'This lesson will no longer be available offline.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    try {
                      await ref.read(offlineDownloadProvider.notifier).deleteLesson(lessonIdStr);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to remove download: $e')),
                        );
                      }
                    }
                  },
                  tooltip: 'Remove offline download',
                );
              }
              return IconButton(
                icon: const Icon(Icons.download_for_offline_outlined),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  try {
                    await ref.read(offlineDownloadProvider.notifier).downloadLesson(lessonIdStr);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Download failed: $e')),
                      );
                    }
                  }
                },
                tooltip: 'Download for offline',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final lessonId = widget.lesson.id.toString();
              final link = DeepLinkService.lessonLink(lessonId);
              Share.share('Check out this lesson on LingAfriq: ${widget.lesson.title}\n$link');
            },
            tooltip: 'Share lesson',
          ),
          if (_hasError || _generatedContent != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generateContent,
              tooltip: 'Regenerate content',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Semantics(
            label: 'Lesson tabs: Vocabulary, Grammar, Dialogue, Exercises',
            child: PanAfricanTabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Vocabulary', icon: Icon(Icons.book)),
                Tab(text: 'Grammar', icon: Icon(Icons.description)),
                Tab(text: 'Dialogue', icon: Icon(Icons.chat)),
                Tab(text: 'Exercises', icon: Icon(Icons.quiz)),
              ],
            ),
          ),
        ),
      ),
      body: _isGenerating
          ? _buildAfricanLoadingState(isDark)
          : _hasError
              ? _buildErrorState(isDark)
              : Column(
                  children: [
                    _buildLessonHero(context, isDark),
                    _buildGrammarTipsSection(isDark),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildVocabularyTab(isDark),
                          _buildGrammarTab(isDark),
                          _buildDialogueTab(isDark),
                          _buildExercisesTab(isDark),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Beautiful African-themed loading state
  Widget _buildAfricanLoadingState(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0D2818),
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                ]
              : [
                  PanAfricanColors.surfaceLight,
                  PanAfricanColors.surfaceContainerLight,
                  PanAfricanColors.surfaceLight,
                ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated pulsing icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 0.9 + (_pulseController.value * 0.2);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100.sp,
                    height: 100.sp,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          PanAfricanColors.secondary,
                          PanAfricanColors.tertiary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: PanAfricanColors.secondary.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_stories,
                      size: 48.sp,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 32.sp),
            Text(
              'Preparing your lesson...',
              style: PanAfricanTypography.titleLarge(context).copyWith(
                color: isDark ? Theme.of(context).colorScheme.onSurface : PanAfricanColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: 12.sp),
            SizedBox(
              width: 280.sp,
              child: Text(
                'Polie is generating personalized content for "${widget.lesson.title}" in ${widget.language}',
                textAlign: TextAlign.center,
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : PanAfricanColors.textSecondary,
                ),
              ),
            ),
            SizedBox(height: 24.sp),
            SizedBox(
              width: 200.sp,
              child: LinearProgressIndicator(
                backgroundColor: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.12) : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.secondary),
              ),
            ),
            SizedBox(height: 48.sp),
            // Quick tip
            Container(
              margin: EdgeInsets.symmetric(horizontal: 32.sp),
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: PanAfricanColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PanAfricanColors.secondary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: PanAfricanColors.secondary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.sp),
                  Flexible(
                    child: Text(
                      'Tip: Practice pronunciation by saying words aloud!',
                      style: PanAfricanTypography.bodySmall(context).copyWith(
                        color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : PanAfricanColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildGrammarTipsSection(bool isDark) {
    final grammar = widget.lesson.grammar ?? [];
    final explanations = _generatedContent?['grammar_explanations'] as List? ?? [];
    
    if (grammar.isEmpty && explanations.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        PanAfricanSpacing.md,
        PanAfricanSpacing.sm,
        PanAfricanSpacing.md,
        PanAfricanSpacing.sm,
      ),
      child: _GrammarTipsCard(
        grammar: grammar,
        explanations: explanations,
        isDark: isDark,
      ),
    );
  }

  Widget _buildLessonHero(BuildContext context, bool isDark) {
    final lessonTitle = widget.lesson.title;
    final vocabCount = widget.lesson.vocabObjects.length;
    final grammarCount = (widget.lesson.grammar ?? const <String>[]).length;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        PanAfricanSpacing.md,
        PanAfricanSpacing.md,
        PanAfricanSpacing.md,
        PanAfricanSpacing.sm,
      ),
      child: PanAfricanCard(
        hasGradientBorder: true,
        gradientStart: PanAfricanColors.secondary,
        gradientEnd: PanAfricanColors.tertiary,
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Row(
          children: [
            Hero(
              tag: 'lesson_icon_${widget.lesson.id}',
              child: Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  gradient: PanAfricanGradients.kenteVibrant,
                  borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                ),
                child: Icon(Icons.auto_stories_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 30.sp),
              ),
            ),
            SizedBox(width: PanAfricanSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lessonTitle,
                    style: PanAfricanTypography.titleLarge(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    '${widget.language.toUpperCase()} • ${widget.level}',
                    style: PanAfricanTypography.labelMedium(context).copyWith(
                      color: isDark
                          ? PanAfricanColors.textSecondaryDark
                          : PanAfricanColors.textSecondaryLight,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Row(
                    children: [
                      PanAfricanBadge(
                        label: '$vocabCount vocab',
                        color: PanAfricanColors.primary,
                        icon: Icons.translate_rounded,
                      ),
                      SizedBox(width: PanAfricanSpacing.sm),
                      PanAfricanBadge(
                        label: '$grammarCount grammar',
                        color: PanAfricanColors.secondary,
                        icon: Icons.menu_book_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
    );
  }

  /// Error state with retry option
  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: PanAfricanColors.error,
            ),
            SizedBox(height: 24.sp),
            Text(
              'Oops! Something went wrong',
              style: PanAfricanTypography.titleLarge(context).copyWith(
                color: isDark ? Theme.of(context).colorScheme.onSurface : PanAfricanColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.sp),
            Text(
              _errorMessage ?? 'Failed to generate lesson content.',
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : PanAfricanColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.sp),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _generateContent();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PanAfricanColors.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 16.sp),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16.sp),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Go Back',
                style: TextStyle(
                  color: isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : PanAfricanColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildVocabularyTab(bool isDark) {
    final vocab = widget.lesson.vocabObjects;
    
    return OptimizedListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: vocab.length,
      itemBuilder: (context, index) {
        final word = vocab[index];
        return Semantics(
          label: 'Vocabulary word: ${word.word}, meaning: ${word.meaning}',
          child: Card(
            margin: EdgeInsets.only(bottom: 12.sp),
            color: isDark ? const Color(0xFF1F3527) : Theme.of(context).colorScheme.surface,
            child: ListTile(
              title: Text(
                word.word,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4.sp),
                  Text(
                    word.meaning,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                if (word.pos != null) ...[
                  SizedBox(height: 4.sp),
                  Chip(
                    label: Text(word.pos!),
                    backgroundColor: PanAfricanColors.primary.withOpacity(0.2),
                  ),
                ],
                if (word.example != null) ...[
                  SizedBox(height: 8.sp),
                  Text(
                    'Example: ${word.example}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildGrammarTab(bool isDark) {
    final grammar = widget.lesson.grammar ?? [];
    final explanations = _generatedContent?['grammar_explanations'] as List? ?? [];
    
    return OptimizedListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: grammar.length,
      itemBuilder: (context, index) {
        final grammarPoint = grammar[index];
        final explanation = index < explanations.length
            ? ((explanations[index] as Map<String, dynamic>?)?['explanation'] as String?) ?? ''
            : '';
        
        return Semantics(
          label: 'Grammar point: $grammarPoint',
          child: Card(
            margin: EdgeInsets.only(bottom: 12.sp),
            color: isDark ? const Color(0xFF1F3527) : Theme.of(context).colorScheme.surface,
            child: ExpansionTile(
              title: Text(
                grammarPoint,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            children: [
              Padding(
                padding: EdgeInsets.all(16.sp),
                child: Text(
                  explanation.isNotEmpty
                      ? explanation
                      : 'Grammar explanation will be generated by Polie.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogueTab(bool isDark) {
    final dialogue = widget.lesson.dialogue;
    final generatedDialogue = _generatedContent?['dialogue'] as Map?;
    
    final script = dialogue?.script ?? generatedDialogue?['script'] as List? ?? [];
    
    return OptimizedListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: script.length,
      itemBuilder: (context, index) {
        final line = script[index] as Map;
        final speaker = line['speaker'] ?? 'A';
        final text = line['text'] ?? '';
        
        return Container(
          margin: EdgeInsets.only(bottom: 12.sp),
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: speaker == 'A'
                ? PanAfricanColors.primary.withOpacity(0.2)
                : (isDark ? const Color(0xFF2A4A35) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: PanAfricanColors.primary,
                child: Text(speaker),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExercisesTab(bool isDark) {
    final exercises = widget.lesson.exercises;
    final generatedExercises = _generatedContent?['exercises'] as List? ?? [];
    
    final allExercises = [
      ...exercises.map((e) => {'type': e.type, 'items': e.items}),
      ...generatedExercises,
    ];
    
    return OptimizedListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: allExercises.length,
      itemBuilder: (context, index) {
        final exercise = allExercises[index] as Map;
        final type = exercise['type'] ?? '';
        final items = exercise['items'] as List? ?? [];
        
        return Semantics(
          label: 'Exercise: $type',
          button: true,
          child: Card(
            margin: EdgeInsets.only(bottom: 12.sp),
            color: isDark ? const Color(0xFF1F3527) : Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: PanAfricanColors.primary,
                    ),
                  ),
                  SizedBox(height: 8.sp),
                  ...items.map((item) => Padding(
                        padding: EdgeInsets.only(bottom: 4.sp),
                        child: Text(
                          item.toString(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Collapsible grammar tips card shown before lesson tabs
class _GrammarTipsCard extends StatefulWidget {
  final List<String> grammar;
  final List explanations;
  final bool isDark;

  const _GrammarTipsCard({
    required this.grammar,
    required this.explanations,
    required this.isDark,
  });

  @override
  State<_GrammarTipsCard> createState() => _GrammarTipsCardState();
}

class _GrammarTipsCardState extends State<_GrammarTipsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.grammar.isNotEmpty || widget.explanations.isNotEmpty;
    if (!hasContent) return SizedBox.shrink();

    return Card(
      color: widget.isDark 
          ? PanAfricanColors.cardDark 
          : PanAfricanColors.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.lightbulb_outline,
          color: PanAfricanColors.secondary,
          size: 28.sp,
        ),
        title: Text(
          'Grammar Tips',
          style: PanAfricanTypography.titleMedium(context).copyWith(
            fontWeight: FontWeight.bold,
            color: PanAfricanColors.secondary,
          ),
        ),
        subtitle: Text(
          'Key points to remember before starting',
          style: PanAfricanTypography.bodySmall(context).copyWith(
            color: widget.isDark 
                ? Colors.grey[400] 
                : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: PanAfricanColors.secondary,
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
          HapticFeedback.lightImpact();
        },
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.grammar.isNotEmpty) ...[
                  Text(
                    'Key Grammar Points:',
                    style: PanAfricanTypography.titleSmall(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  ...widget.grammar.asMap().entries.map((entry) {
                    final index = entry.key;
                    final grammarPoint = entry.value;
                    final explanation = index < widget.explanations.length
                        ? ((widget.explanations[index] as Map<String, dynamic>?)?['explanation'] as String?) ?? ''
                        : '';
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 4.sp, right: PanAfricanSpacing.sm),
                            width: 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(
                              color: PanAfricanColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  grammarPoint,
                                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (explanation.isNotEmpty) ...[
                                  SizedBox(height: 4.sp),
                                  Text(
                                    explanation,
                                    style: PanAfricanTypography.bodySmall(context).copyWith(
                                      color: widget.isDark 
                                          ? Colors.grey[300] 
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else if (widget.explanations.isNotEmpty) ...[
                  ...widget.explanations.map((exp) {
                    final explanation = (exp as Map<String, dynamic>?)?['explanation'] ?? '';
                    final title = (exp)?['title'] ?? '';
                    return Padding(
                      padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title.isNotEmpty)
                            Text(
                              title,
                              style: PanAfricanTypography.bodyMedium(context).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (explanation.isNotEmpty) ...[
                            SizedBox(height: 4.sp),
                            Text(
                              explanation,
                              style: PanAfricanTypography.bodySmall(context).copyWith(
                                color: widget.isDark 
                                    ? Colors.grey[300] 
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


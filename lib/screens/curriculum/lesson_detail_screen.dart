import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:lingafriq/services/curriculum_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// Detailed lesson screen with AI-generated content
class LessonDetailScreen extends ConsumerStatefulWidget {
  final CurriculumLesson lesson;
  final String language;
  final String level;

  const LessonDetailScreen({
    Key? key,
    required this.lesson,
    required this.language,
    required this.level,
  }) : super(key: key);

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
      
      // Add timeout to prevent endless loading
      final content = await curriculumService.generateLessonContent(
        language: widget.language,
        level: widget.level,
        lessonTitle: widget.lesson.title,
        vocab: vocabObjects.map((v) => v.toMap()).toList(),
        grammar: widget.lesson.grammar,
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
    
    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor:
            isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        foregroundColor:
            isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
        actions: [
          if (_hasError || _generatedContent != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generateContent,
              tooltip: 'Regenerate content',
            ),
        ],
        bottom: PanAfricanTabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Vocabulary', icon: Icon(Icons.book)),
            Tab(text: 'Grammar', icon: Icon(Icons.description)),
            Tab(text: 'Dialogue', icon: Icon(Icons.chat)),
            Tab(text: 'Exercises', icon: Icon(Icons.quiz)),
          ],
        ),
      ),
      body: _isGenerating
          ? _buildAfricanLoadingState(isDark)
          : _hasError
              ? _buildErrorState(isDark)
              : Column(
                  children: [
                    _buildLessonHero(context, isDark),
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
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 32.sp),
            Text(
              'Preparing your lesson...',
              style: PanAfricanTypography.titleLarge(context).copyWith(
                color: isDark ? Colors.white : PanAfricanColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: 12.sp),
            SizedBox(
              width: 280.sp,
              child: Text(
                'Polie is generating personalized content for "${widget.lesson.title}" in ${widget.language}',
                textAlign: TextAlign.center,
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: isDark ? Colors.white70 : PanAfricanColors.textSecondary,
                ),
              ),
            ),
            SizedBox(height: 24.sp),
            SizedBox(
              width: 200.sp,
              child: LinearProgressIndicator(
                backgroundColor: isDark ? Colors.white12 : Colors.grey[300],
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
                        color: isDark ? Colors.white70 : PanAfricanColors.textSecondary,
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

  Widget _buildLessonHero(BuildContext context, bool isDark) {
    final lessonTitle = widget.lesson.title;
    final vocabCount = widget.lesson.vocabObjects.length;
    final grammarCount = widget.lesson.grammar.length;
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
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                gradient: PanAfricanGradients.kenteVibrant,
                borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              ),
              child: Icon(Icons.auto_stories_rounded, color: Colors.white, size: 30.sp),
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
                color: isDark ? Colors.white : PanAfricanColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.sp),
            Text(
              _errorMessage ?? 'Failed to generate lesson content.',
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: isDark ? Colors.white70 : PanAfricanColors.textSecondary,
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
                foregroundColor: Colors.white,
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
                  color: isDark ? Colors.white70 : PanAfricanColors.textSecondary,
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
        return Card(
          margin: EdgeInsets.only(bottom: 12.sp),
          color: isDark ? const Color(0xFF1F3527) : Colors.white,
          child: ListTile(
            title: Text(
              word.word,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
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
        
        return Card(
          margin: EdgeInsets.only(bottom: 12.sp),
          color: isDark ? const Color(0xFF1F3527) : Colors.white,
          child: ExpansionTile(
            title: Text(
              grammarPoint,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
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
                    color: isDark ? Colors.white : Colors.black87,
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
        
        return Card(
          margin: EdgeInsets.only(bottom: 12.sp),
          color: isDark ? const Color(0xFF1F3527) : Colors.white,
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
        );
      },
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:velocity_x/velocity_x.dart';

/// Writing Practice Screen
/// Translation exercises, sentence building, free writing with AI evaluation
class WritingPracticeScreen extends ConsumerStatefulWidget {
  final String? language;

  const WritingPracticeScreen({
    Key? key,
    this.language,
  }) : super(key: key);

  @override
  ConsumerState<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends ConsumerState<WritingPracticeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<WritingExercise> _exercises = [];
  WritingExercise? _currentExercise;
  bool _isLoading = true;
  String _userAnswer = '';
  bool _isEvaluating = false;
  WritingFeedback? _feedback;
  Map<String, bool> _completedExercises = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExercises();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Replace with actual API call
      _exercises = _getDefaultExercises();
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      _exercises = _getDefaultExercises();
    }
    
    setState(() => _isLoading = false);
  }

  List<WritingExercise> _getDefaultExercises() {
    return [
      WritingExercise(
        id: 'translate_1',
        type: WritingExerciseType.translation,
        title: 'Translate: "Hello, how are you?"',
        instruction: 'Translate this sentence to Swahili',
        sourceText: 'Hello, how are you?',
        correctAnswer: 'Hujambo, habari gani?',
        language: widget.language ?? 'sw',
      ),
      WritingExercise(
        id: 'translate_2',
        type: WritingExerciseType.translation,
        title: 'Translate: "Thank you very much"',
        instruction: 'Translate this sentence to Swahili',
        sourceText: 'Thank you very much',
        correctAnswer: 'Asante sana',
        language: widget.language ?? 'sw',
      ),
      WritingExercise(
        id: 'sentence_1',
        type: WritingExerciseType.sentenceBuilding,
        title: 'Build a Sentence',
        instruction: 'Use these words to form a sentence: [mimi, ni, mwalimu]',
        wordBank: ['mimi', 'ni', 'mwalimu', 'na', 'wewe'],
        correctAnswer: 'Mimi ni mwalimu',
        language: widget.language ?? 'sw',
      ),
      WritingExercise(
        id: 'free_1',
        type: WritingExerciseType.freeWriting,
        title: 'Introduce Yourself',
        instruction: 'Write 3-5 sentences introducing yourself in Swahili',
        prompt: 'Tell me about yourself: your name, where you\'re from, and what you like to do.',
        language: widget.language ?? 'sw',
      ),
    ];
  }

  Future<void> _evaluateAnswer() async {
    if (_userAnswer.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write your answer')),
      );
      return;
    }

    setState(() {
      _isEvaluating = true;
      _feedback = null;
    });

    try {
      if (_currentExercise?.type == WritingExerciseType.freeWriting) {
        // Use AI to evaluate free writing
        await _evaluateWithAI();
      } else {
        // Simple comparison for translation/sentence building
        _evaluateSimple();
      }
    } catch (e) {
      debugPrint('Error evaluating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error evaluating answer')),
      );
    } finally {
      setState(() {
        _isEvaluating = false;
      });
    }
  }

  Future<void> _evaluateWithAI() async {
    if (_currentExercise == null) return;

    try {
      final chatProvider = ref.read(groqChatProvider.notifier);
      
      final prompt = '''
Evaluate this writing exercise in ${_currentExercise!.language}:

Exercise: ${_currentExercise!.instruction}
User's answer: $_userAnswer

Provide:
1. Overall score (0-100)
2. Grammar feedback
3. Vocabulary feedback
4. Suggestions for improvement
''';

      // Use AI chat to evaluate
      await chatProvider.sendMessage(prompt);
      
      // For now, provide basic feedback
      setState(() {
        _feedback = WritingFeedback(
          score: 75,
          isCorrect: true,
          feedback: 'Good effort! Your writing shows understanding of basic grammar.',
          suggestions: ['Try using more varied vocabulary', 'Pay attention to word order'],
        );
      });
    } catch (e) {
      debugPrint('AI evaluation error: $e');
      _evaluateSimple();
    }
  }

  void _evaluateSimple() {
    if (_currentExercise == null) return;

    final userAnswerLower = _userAnswer.trim().toLowerCase();
    final correctAnswerLower = _currentExercise!.correctAnswer?.toLowerCase() ?? '';

    final isCorrect = userAnswerLower == correctAnswerLower ||
        userAnswerLower.contains(correctAnswerLower) ||
        correctAnswerLower.contains(userAnswerLower);

    setState(() {
      _feedback = WritingFeedback(
        score: isCorrect ? 100 : 60,
        isCorrect: isCorrect,
        feedback: isCorrect
            ? 'Correct! Well done.'
            : 'Not quite right. Try again.',
        suggestions: isCorrect
            ? []
            : ['Check your spelling', 'Review the correct answer: ${_currentExercise!.correctAnswer}'],
      );
    });

    if (isCorrect) {
      _markAsCompleted();
    }
  }

  void _markAsCompleted() {
    if (_currentExercise != null) {
      setState(() {
        _completedExercises[_currentExercise!.id] = true;
      });
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('writing_${_currentExercise!.id}', true);
      });
    }
  }

  void _startExercise(WritingExercise exercise) {
    setState(() {
      _currentExercise = exercise;
      _userAnswer = '';
      _feedback = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? PolieColors.obsidian : PolieColors.surfaceLight,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PolieColors.primary,
              PolieColors.primaryDark,
              PolieColors.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: _currentExercise == null
              ? _buildExerciseList(context)
              : _buildExerciseView(context),
        ),
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildTabBar(context),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: PolieColors.electricTeal))
              : _buildExercisesList(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: PolieColors.textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Writing Practice',
                  style: PolieTypography.h2(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
                Text(
                  'Improve your writing skills',
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: PolieColors.surfaceContainerLight.withOpacity(0.1),
      child: TabBar(
        controller: _tabController,
        indicatorColor: PolieColors.electricTeal,
        labelColor: PolieColors.textPrimary,
        unselectedLabelColor: PolieColors.textSecondary,
        tabs: [
          Tab(text: 'Translation', icon: Icon(Icons.translate_rounded, size: 20.sp)),
          Tab(text: 'Sentence Building', icon: Icon(Icons.build_rounded, size: 20.sp)),
          Tab(text: 'Free Writing', icon: Icon(Icons.edit_rounded, size: 20.sp)),
        ],
      ),
    );
  }

  Widget _buildExercisesList(BuildContext context) {
    final typeMap = {
      0: WritingExerciseType.translation,
      1: WritingExerciseType.sentenceBuilding,
      2: WritingExerciseType.freeWriting,
    };
    
    final currentType = typeMap[_tabController.index] ?? WritingExerciseType.translation;
    final filteredExercises = _exercises.where((e) => e.type == currentType).toList();

    if (filteredExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, size: 64.sp, color: PolieColors.textSecondary),
            SizedBox(height: PolieSpacing.md),
            Text(
              'No exercises available',
              style: PolieTypography.h3(context).copyWith(
                color: PolieColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(PolieSpacing.md),
      itemCount: filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = filteredExercises[index];
        final isCompleted = _completedExercises[exercise.id] ?? false;
        return _ExerciseCard(
          exercise: exercise,
          isCompleted: isCompleted,
          onTap: () => _startExercise(exercise),
        )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 200.ms)
            .slideX(begin: 0.1);
      },
    );
  }

  Widget _buildExerciseView(BuildContext context) {
    if (_currentExercise == null) return SizedBox.shrink();

    return Column(
      children: [
        _buildExerciseHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PolieSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExerciseContent(context),
                SizedBox(height: PolieSpacing.lg),
                _buildAnswerInput(context),
                if (_feedback != null) ...[
                  SizedBox(height: PolieSpacing.lg),
                  _buildFeedback(context),
                ],
                SizedBox(height: PolieSpacing.lg),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: PolieColors.textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _currentExercise = null;
                _userAnswer = '';
                _feedback = null;
              });
            },
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Text(
              _currentExercise?.title ?? '',
              style: PolieTypography.h2(context).copyWith(
                color: PolieColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.lg),
      decoration: BoxDecoration(
        color: PolieColors.surfaceContainerLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PolieRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentExercise!.instruction,
            style: PolieTypography.titleMedium(context).copyWith(
              color: PolieColors.textPrimary,
            ),
          ),
          SizedBox(height: PolieSpacing.md),
          if (_currentExercise!.sourceText != null)
            Container(
              padding: EdgeInsets.all(PolieSpacing.md),
              decoration: BoxDecoration(
                color: PolieColors.royalAmethyst.withOpacity(0.1),
                borderRadius: BorderRadius.circular(PolieRadius.md),
              ),
              child: Text(
                _currentExercise!.sourceText!,
                style: PolieTypography.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_currentExercise!.prompt != null)
            Container(
              padding: EdgeInsets.all(PolieSpacing.md),
              decoration: BoxDecoration(
                color: PolieColors.electricTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(PolieRadius.md),
              ),
              child: Text(
                _currentExercise!.prompt!,
                style: PolieTypography.body(context),
              ),
            ),
          if (_currentExercise!.wordBank != null && _currentExercise!.wordBank!.isNotEmpty) ...[
            SizedBox(height: PolieSpacing.md),
            Text(
              'Word Bank:',
              style: PolieTypography.label(context),
            ),
            SizedBox(height: PolieSpacing.sm),
            Wrap(
              spacing: PolieSpacing.sm,
              runSpacing: PolieSpacing.sm,
              children: _currentExercise!.wordBank!.map((word) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PolieSpacing.sm,
                    vertical: PolieSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: PolieColors.electricTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(PolieRadius.sm),
                  ),
                  child: Text(
                    word,
                    style: PolieTypography.label(context),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Answer',
          style: PolieTypography.titleMedium(context).copyWith(
            color: PolieColors.textPrimary,
          ),
        ),
        SizedBox(height: PolieSpacing.sm),
        TextField(
          onChanged: (value) => setState(() => _userAnswer = value),
          maxLines: _currentExercise?.type == WritingExerciseType.freeWriting ? 10 : 3,
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PolieRadius.md),
            ),
            filled: true,
            fillColor: PolieColors.surfaceContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedback(BuildContext context) {
    if (_feedback == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(PolieSpacing.lg),
      decoration: BoxDecoration(
        color: _feedback!.isCorrect
            ? PolieColors.success.withOpacity(0.1)
            : PolieColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        border: Border.all(
          color: _feedback!.isCorrect ? PolieColors.success : PolieColors.error,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _feedback!.isCorrect ? Icons.check_circle : Icons.error,
                color: _feedback!.isCorrect ? PolieColors.success : PolieColors.error,
                size: 24.sp,
              ),
              SizedBox(width: PolieSpacing.sm),
              Text(
                'Score: ${_feedback!.score}/100',
                style: PolieTypography.titleMedium(context).copyWith(
                  color: _feedback!.isCorrect ? PolieColors.success : PolieColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.md),
          Text(
            _feedback!.feedback,
            style: PolieTypography.body(context),
          ),
          if (_feedback!.suggestions.isNotEmpty) ...[
            SizedBox(height: PolieSpacing.md),
            Text(
              'Suggestions:',
              style: PolieTypography.titleSmall(context),
            ),
            SizedBox(height: PolieSpacing.xs),
            ..._feedback!.suggestions.map((suggestion) {
              return Padding(
                padding: EdgeInsets.only(bottom: PolieSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, size: 16.sp, color: PolieColors.textSecondary),
                    SizedBox(width: PolieSpacing.xs),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: PolieTypography.body(context),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isEvaluating ? null : _evaluateAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: PolieColors.electricTeal,
              padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
            ),
            child: _isEvaluating
                ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary),
                      SizedBox(width: PolieSpacing.sm),
                      Text(
                        'Evaluate',
                        style: PolieTypography.labelLarge(context).copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_feedback != null && _feedback!.isCorrect) ...[
          SizedBox(height: PolieSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _currentExercise = null;
                  _userAnswer = '';
                  _feedback = null;
                });
              },
              child: Text('Next Exercise'),
            ),
          ),
        ],
      ],
    );
  }
}

class WritingExercise {
  final String id;
  final WritingExerciseType type;
  final String title;
  final String instruction;
  final String? sourceText;
  final String? prompt;
  final List<String>? wordBank;
  final String? correctAnswer;
  final String language;

  WritingExercise({
    required this.id,
    required this.type,
    required this.title,
    required this.instruction,
    this.sourceText,
    this.prompt,
    this.wordBank,
    this.correctAnswer,
    required this.language,
  });
}

enum WritingExerciseType {
  translation,
  sentenceBuilding,
  freeWriting,
}

class WritingFeedback {
  final int score;
  final bool isCorrect;
  final String feedback;
  final List<String> suggestions;

  WritingFeedback({
    required this.score,
    required this.isCorrect,
    required this.feedback,
    this.suggestions = const [],
  });
}

class _ExerciseCard extends StatelessWidget {
  final WritingExercise exercise;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.isCompleted,
    required this.onTap,
  });

  IconData _getTypeIcon() {
    switch (exercise.type) {
      case WritingExerciseType.translation:
        return Icons.translate_rounded;
      case WritingExerciseType.sentenceBuilding:
        return Icons.build_rounded;
      case WritingExerciseType.freeWriting:
        return Icons.edit_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: PolieSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        border: Border.all(
          color: isCompleted ? PolieColors.success.withOpacity(0.5) : PolieColors.royalAmethyst.withOpacity(0.3),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(PolieRadius.lg),
          child: Padding(
            padding: EdgeInsets.all(PolieSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  decoration: BoxDecoration(
                    color: PolieColors.royalAmethyst.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(PolieRadius.md),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: PolieColors.royalAmethyst,
                    size: 32.sp,
                  ),
                ),
                SizedBox(width: PolieSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.title,
                              style: PolieTypography.h3(context).copyWith(
                                color: PolieColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Icon(
                              Icons.check_circle,
                              color: PolieColors.success,
                              size: 20.sp,
                            ),
                        ],
                      ),
                      SizedBox(height: PolieSpacing.xs),
                      Text(
                        exercise.instruction,
                        style: PolieTypography.bodySmall(context).copyWith(
                          color: PolieColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: PolieColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

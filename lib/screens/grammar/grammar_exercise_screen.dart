import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/widgets/polie/polie_components.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/services/sound_effects_service.dart';
import 'package:lingafriq/widgets/gamification/combo_tracker.dart';
import 'package:lingafriq/widgets/gamification/combo_display_widget.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Grammar exercise screen with 4 types:
/// - Fill-in-the-blank: Multiple choice to complete a sentence
/// - Word order: Rearrange words to form correct sentence
/// - Conjugation: Select correct verb form
/// - Error detection: Find grammatical error in sentence

enum ExerciseType {
  fillInTheBlank,
  wordOrder,
  conjugation,
  errorDetection,
}

class GrammarExercise {
  final String id;
  final ExerciseType type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final Map<String, dynamic>? metadata;

  GrammarExercise({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.metadata,
  });

  factory GrammarExercise.fromJson(Map<String, dynamic> json) {
    return GrammarExercise(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      type: _parseExerciseType(json['type']?.toString() ?? 'fill_in_blank'),
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      correctAnswer: json['correctAnswer']?.toString() ?? json['correct_answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static ExerciseType _parseExerciseType(String type) {
    switch (type.toLowerCase()) {
      case 'fill_in_blank':
      case 'fill_in_the_blank':
        return ExerciseType.fillInTheBlank;
      case 'word_order':
        return ExerciseType.wordOrder;
      case 'conjugation':
        return ExerciseType.conjugation;
      case 'error_detection':
        return ExerciseType.errorDetection;
      default:
        return ExerciseType.fillInTheBlank;
    }
  }
}

class GrammarExerciseScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topicName;

  const GrammarExerciseScreen({
    super.key,
    required this.topicId,
    required this.topicName,
  });

  @override
  ConsumerState<GrammarExerciseScreen> createState() => _GrammarExerciseScreenState();
}

class _GrammarExerciseScreenState extends ConsumerState<GrammarExerciseScreen> {
  late PageController _pageController;
  late ComboTracker _comboTracker;
  final List<GrammarExercise> _exercises = [];
  List<String?> _selectedAnswers = [];
  List<bool> _isAnswered = [];
  List<bool> _isCorrect = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showSummary = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _comboTracker = ComboTracker();
    _loadExercises();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _comboTracker.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(
        ApiContract.url('/api/grammar/exercises'),
        queryParameters: {'topicId': widget.topicId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<GrammarExercise> exercises = [];

        if (data is Map && data['exercises'] is List) {
          exercises = (data['exercises'] as List)
              .map((e) => GrammarExercise.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          exercises = data
              .map((e) => GrammarExercise.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        if (exercises.isEmpty) {
          exercises = _generateFallbackExercises();
        }

        setState(() {
          _exercises.addAll(exercises);
          _selectedAnswers = List.filled(exercises.length, null);
          _isAnswered = List.filled(exercises.length, false);
          _isCorrect = List.filled(exercises.length, false);
        });
      } else {
        setState(() {
          _exercises.addAll(_generateFallbackExercises());
          _selectedAnswers = List.filled(_exercises.length, null);
          _isAnswered = List.filled(_exercises.length, false);
          _isCorrect = List.filled(_exercises.length, false);
        });
      }
    } catch (e) {
      setState(() {
        _exercises.addAll(_generateFallbackExercises());
        _selectedAnswers = List.filled(_exercises.length, null);
        _isAnswered = List.filled(_exercises.length, false);
        _isCorrect = List.filled(_exercises.length, false);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<GrammarExercise> _generateFallbackExercises() {
    return [
      GrammarExercise(
        id: '1',
        type: ExerciseType.fillInTheBlank,
        question: 'Mo ___ ilé lónà.',
        options: ['wá', 'wọ', 'wáà', 'wọọ'],
        correctAnswer: 'wá',
        explanation: 'The correct form is "wá" (come) in this context.',
      ),
      GrammarExercise(
        id: '2',
        type: ExerciseType.wordOrder,
        question: 'Rearrange to form a correct sentence:',
        options: ['Mo', 'wá', 'ilé', 'lónà'],
        correctAnswer: 'Mo wá ilé lónà',
        explanation: 'The correct word order is: Subject + Verb + Object + Adverb.',
      ),
      GrammarExercise(
        id: '3',
        type: ExerciseType.conjugation,
        question: 'Select the correct conjugation for "wá" (come) with subject "Mo" (I):',
        options: ['wá', 'wáà', 'wọ', 'wọọ'],
        correctAnswer: 'wá',
        explanation: 'With first person singular "Mo", the verb "wá" stays in its base form.',
      ),
      GrammarExercise(
        id: '4',
        type: ExerciseType.errorDetection,
        question: 'Find the error: Mo wáà ilé lónà.',
        options: ['Mo', 'wáà', 'ilé', 'lónà'],
        correctAnswer: 'wáà',
        explanation: 'The correct form is "wá", not "wáà".',
      ),
    ];
  }

  void _selectAnswer(String answer) {
    if (_isAnswered[_currentIndex]) return;

    setState(() {
      _selectedAnswers[_currentIndex] = answer;
    });
  }

  Future<void> _checkAnswer() async {
    if (_selectedAnswers[_currentIndex] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an answer'),
          backgroundColor: PolieColors.error,
        ),
      );
      return;
    }

    final exercise = _exercises[_currentIndex];
    final isCorrect = _selectedAnswers[_currentIndex] == exercise.correctAnswer;
    final soundEffects = ref.read(soundEffectsProvider);

    setState(() {
      _isAnswered[_currentIndex] = true;
      _isCorrect[_currentIndex] = isCorrect;
      if (isCorrect) {
        _score++;
        _comboTracker.recordCorrect();
        soundEffects.playCorrect();
      } else {
        _comboTracker.recordIncorrect();
        soundEffects.playIncorrect();
      }
    });

    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 1500));

    if (_currentIndex < _exercises.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showFinalSummary();
    }
  }

  void _showFinalSummary() async {
    final multiplier = _comboTracker.currentMultiplier;

    await ref.read(gamificationProvider.notifier).awardXP(
      'grammar_exercise',
      multiplier: multiplier,
      sourceId: 'grammar_${widget.topicId}_${DateTime.now().millisecondsSinceEpoch}',
    );

    final soundEffects = ref.read(soundEffectsProvider);
    if (_score == _exercises.length) {
      soundEffects.playCelebration();
    } else {
      soundEffects.playCorrect();
    }

    setState(() {
      _showSummary = true;
    });
  }

  void _resetExercise() {
    setState(() {
      _currentIndex = 0;
      _showSummary = false;
      _score = 0;
      _selectedAnswers.fillRange(0, _selectedAnswers.length, null);
      _isAnswered.fillRange(0, _isAnswered.length, false);
      _isCorrect.fillRange(0, _isCorrect.length, false);
    });
    _comboTracker.reset();
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
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
          child: Center(
            child: CircularProgressIndicator(color: PolieColors.goldEmber),
          ),
        ),
      );
    }

    if (_showSummary) {
      return _buildSummaryScreen(context, isDark);
    }

    return Scaffold(
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
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, isDark),
                  _buildProgressBar(context, isDark),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemCount: _exercises.length,
                      itemBuilder: (context, index) {
                        return _buildExerciseWidget(context, _exercises[index], index, isDark);
                      },
                    ),
                  ),
                ],
              ),
              if (_comboTracker.hasCombo)
                ComboDisplayWidget(comboTracker: _comboTracker),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Row(
        children: [
          Semantics(
            label: 'Go back',
            button: true,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: PolieColors.textPrimary, semanticLabel: 'Back'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
          ),
          SizedBox(width: PolieSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topicName,
                  style: PolieTypography.h3(context).copyWith(
                    color: PolieColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: PolieSpacing.xs),
                Text(
                  'Exercise ${_currentIndex + 1} of ${_exercises.length}',
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PolieSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: PolieTypography.label(context).copyWith(
                  color: PolieColors.textSecondary,
                ),
              ),
              Text(
                '${_currentIndex + 1}/${_exercises.length}',
                style: PolieTypography.label(context).copyWith(
                  color: PolieColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: PolieSpacing.sm),
          Semantics(
            label: 'Exercise progress',
            value: '${_currentIndex + 1} of ${_exercises.length}',
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _exercises.length,
              backgroundColor: PolieColors.textSecondary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(PolieColors.goldEmber),
              minHeight: 6.h,
              borderRadius: BorderRadius.circular(PolieRadius.sm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseWidget(
    BuildContext context,
    GrammarExercise exercise,
    int index,
    bool isDark,
  ) {
    switch (exercise.type) {
      case ExerciseType.fillInTheBlank:
        return _buildFillInTheBlank(context, exercise, index, isDark);
      case ExerciseType.wordOrder:
        return _buildWordOrder(context, exercise, index, isDark);
      case ExerciseType.conjugation:
        return _buildConjugation(context, exercise, index, isDark);
      case ExerciseType.errorDetection:
        return _buildErrorDetection(context, exercise, index, isDark);
    }
  }

  Widget _buildFillInTheBlank(
    BuildContext context,
    GrammarExercise exercise,
    int index,
    bool isDark,
  ) {
    final isAnswered = _isAnswered[index];
    final isCorrect = _isCorrect[index];
    final selectedAnswer = _selectedAnswers[index];

    return SingleChildScrollView(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: PolieSpacing.xl),
          PolieGlassCard(
            padding: EdgeInsets.all(PolieSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fill in the blank',
                  style: PolieTypography.label(context).copyWith(
                    color: PolieColors.goldEmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: PolieSpacing.lg),
                Text(
                  exercise.question,
                  style: PolieTypography.h2(context).copyWith(
                    color: PolieColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: PolieSpacing.xl),
          ...exercise.options.map((option) {
            final isSelected = selectedAnswer == option;
            final showCorrect = isAnswered && option == exercise.correctAnswer;
            final showIncorrect = isAnswered && isSelected && !isCorrect;

            Color? backgroundColor;
            Color? borderColor;
            if (isAnswered) {
              if (showCorrect) {
                backgroundColor = PolieColors.success.withOpacity(0.2);
                borderColor = PolieColors.success;
              } else if (showIncorrect) {
                backgroundColor = PolieColors.error.withOpacity(0.2);
                borderColor = PolieColors.error;
              }
            } else if (isSelected) {
              backgroundColor = PolieColors.royalAmethyst.withOpacity(0.2);
              borderColor = PolieColors.royalAmethyst;
            }

            return Padding(
              padding: EdgeInsets.only(bottom: PolieSpacing.md),
              child: GestureDetector(
                onTap: isAnswered ? null : () {
                  HapticFeedback.selectionClick();
                  _selectAnswer(option);
                },
                child: Container(
                  padding: EdgeInsets.all(PolieSpacing.lg),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor ?? Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: PolieTypography.body(context).copyWith(
                            color: PolieColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (showCorrect)
                        Icon(Icons.check_circle, color: PolieColors.success),
                      if (showIncorrect)
                        Icon(Icons.cancel, color: PolieColors.error),
                    ],
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: PolieSpacing.xl),
          if (isAnswered)
            PolieGlassCard(
              padding: EdgeInsets.all(PolieSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'Correct!' : 'Incorrect',
                    style: PolieTypography.h3(context).copyWith(
                      color: isCorrect ? PolieColors.success : PolieColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.sm),
                  Text(
                    exercise.explanation,
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: PolieSpacing.lg),
          if (!isAnswered)
            Semantics(
              label: 'Check your answer',
              button: true,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _checkAnswer,
                  style: FilledButton.styleFrom(
                    backgroundColor: PolieColors.goldEmber,
                    padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PolieRadius.md),
                    ),
                  ),
                  child: Text(
                    'Check Answer',
                    style: PolieTypography.button(context).copyWith(
                      color: PolieColors.obsidian,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWordOrder(
    BuildContext context,
    GrammarExercise exercise,
    int index,
    bool isDark,
  ) {
    final isAnswered = _isAnswered[index];
    final selectedWords = useState<List<String>>([]);
    final availableWords = useState<List<String>>(List.from(exercise.options));

    if (isAnswered && selectedWords.value.isEmpty) {
      selectedWords.value = List.from(exercise.options);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: PolieSpacing.xl),
          PolieGlassCard(
            padding: EdgeInsets.all(PolieSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Word Order',
                  style: PolieTypography.label(context).copyWith(
                    color: PolieColors.goldEmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: PolieSpacing.lg),
                Text(
                  exercise.question,
                  style: PolieTypography.h3(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: PolieSpacing.xl),
          PolieGlassCard(
            padding: EdgeInsets.all(PolieSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your sentence:',
                  style: PolieTypography.label(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
                SizedBox(height: PolieSpacing.md),
                Wrap(
                  spacing: PolieSpacing.sm,
                  runSpacing: PolieSpacing.sm,
                  children: selectedWords.value.map((word) {
                    return Semantics(
                      label: 'Remove word: $word',
                      button: true,
                      enabled: !isAnswered,
                      child: GestureDetector(
                        onTap: isAnswered ? null : () {
                          setState(() {
                            selectedWords.value.remove(word);
                            availableWords.value.add(word);
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: Chip(
                        label: Text(word),
                        backgroundColor: PolieColors.royalAmethyst.withOpacity(0.3),
                        deleteIcon: isAnswered ? null : Icon(Icons.close, size: 16),
                        onDeleted: isAnswered ? null : () {
                          setState(() {
                            selectedWords.value.remove(word);
                            availableWords.value.add(word);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                if (selectedWords.value.isEmpty)
                  Text(
                    'Tap words below to build your sentence',
                    style: PolieTypography.bodySmall(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: PolieSpacing.lg),
          Text(
            'Available words:',
            style: PolieTypography.label(context).copyWith(
              color: PolieColors.textSecondary,
            ),
          ),
          SizedBox(height: PolieSpacing.sm),
          Wrap(
            spacing: PolieSpacing.sm,
            runSpacing: PolieSpacing.sm,
            children: availableWords.value.map((word) {
              return Semantics(
                label: 'Add word: $word',
                button: true,
                enabled: !isAnswered,
                child: GestureDetector(
                  onTap: isAnswered ? null : () {
                    setState(() {
                      availableWords.value.remove(word);
                      selectedWords.value.add(word);
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Chip(
                    label: Text(word),
                    backgroundColor: PolieColors.surfaceContainer,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: PolieSpacing.xl),
          if (isAnswered)
            PolieGlassCard(
              padding: EdgeInsets.all(PolieSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCorrect[index] ? 'Correct!' : 'Incorrect',
                    style: PolieTypography.h3(context).copyWith(
                      color: _isCorrect[index] ? PolieColors.success : PolieColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.sm),
                  Text(
                    'Correct answer: ${exercise.correctAnswer}',
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.sm),
                  Text(
                    exercise.explanation,
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: PolieSpacing.lg),
          if (!isAnswered)
            Semantics(
              label: 'Check your answer',
              button: true,
              enabled: selectedWords.value.isNotEmpty,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selectedWords.value.isEmpty ? null : () {
                    final answer = selectedWords.value.join(' ');
                    setState(() {
                      _selectedAnswers[index] = answer;
                    });
                    _checkAnswer();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: PolieColors.goldEmber,
                    padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PolieRadius.md),
                    ),
                  ),
                  child: Text(
                    'Check Answer',
                    style: PolieTypography.button(context).copyWith(
                      color: PolieColors.obsidian,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConjugation(
    BuildContext context,
    GrammarExercise exercise,
    int index,
    bool isDark,
  ) {
    final isAnswered = _isAnswered[index];
    final isCorrect = _isCorrect[index];
    final selectedAnswer = _selectedAnswers[index];

    return SingleChildScrollView(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: PolieSpacing.xl),
          PolieGlassCard(
            padding: EdgeInsets.all(PolieSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conjugation',
                  style: PolieTypography.label(context).copyWith(
                    color: PolieColors.goldEmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: PolieSpacing.lg),
                Text(
                  exercise.question,
                  style: PolieTypography.h3(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: PolieSpacing.xl),
          ...exercise.options.map((option) {
            final isSelected = selectedAnswer == option;
            final showCorrect = isAnswered && option == exercise.correctAnswer;
            final showIncorrect = isAnswered && isSelected && !isCorrect;

            Color? backgroundColor;
            Color? borderColor;
            if (isAnswered) {
              if (showCorrect) {
                backgroundColor = PolieColors.success.withOpacity(0.2);
                borderColor = PolieColors.success;
              } else if (showIncorrect) {
                backgroundColor = PolieColors.error.withOpacity(0.2);
                borderColor = PolieColors.error;
              }
            } else if (isSelected) {
              backgroundColor = PolieColors.royalAmethyst.withOpacity(0.2);
              borderColor = PolieColors.royalAmethyst;
            }

            return Padding(
              padding: EdgeInsets.only(bottom: PolieSpacing.md),
              child: Semantics(
                label: 'Conjugation option: $option',
                button: true,
                enabled: !isAnswered,
                child: GestureDetector(
                  onTap: isAnswered ? null : () {
                    HapticFeedback.selectionClick();
                    _selectAnswer(option);
                  },
                  child: Container(
                    padding: EdgeInsets.all(PolieSpacing.lg),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor ?? Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: PolieTypography.body(context).copyWith(
                              color: PolieColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (showCorrect)
                          Icon(Icons.check_circle, color: PolieColors.success, semanticLabel: 'Correct'),
                        if (showIncorrect)
                          Icon(Icons.cancel, color: PolieColors.error, semanticLabel: 'Incorrect'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: PolieSpacing.xl),
          if (isAnswered)
            PolieGlassCard(
              padding: EdgeInsets.all(PolieSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'Correct!' : 'Incorrect',
                    style: PolieTypography.h3(context).copyWith(
                      color: isCorrect ? PolieColors.success : PolieColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.sm),
                  Text(
                    exercise.explanation,
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: PolieSpacing.lg),
          if (!isAnswered)
            Semantics(
              label: 'Check your answer',
              button: true,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _checkAnswer,
                  style: FilledButton.styleFrom(
                    backgroundColor: PolieColors.goldEmber,
                    padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PolieRadius.md),
                    ),
                  ),
                  child: Text(
                    'Check Answer',
                    style: PolieTypography.button(context).copyWith(
                      color: PolieColors.obsidian,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorDetection(
    BuildContext context,
    GrammarExercise exercise,
    int index,
    bool isDark,
  ) {
    final isAnswered = _isAnswered[index];
    final isCorrect = _isCorrect[index];
    final selectedAnswer = _selectedAnswers[index];
    final words = exercise.question.split(' ');

    return SingleChildScrollView(
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: PolieSpacing.xl),
          PolieGlassCard(
            padding: EdgeInsets.all(PolieSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error Detection',
                  style: PolieTypography.label(context).copyWith(
                    color: PolieColors.goldEmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: PolieSpacing.lg),
                Text(
                  'Find the grammatical error in this sentence:',
                  style: PolieTypography.body(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
                SizedBox(height: PolieSpacing.md),
                Wrap(
                  spacing: PolieSpacing.sm,
                  runSpacing: PolieSpacing.sm,
                  children: words.map((word) {
                    final isSelected = selectedAnswer == word;
                    final showCorrect = isAnswered && word == exercise.correctAnswer;
                    final showIncorrect = isAnswered && isSelected && !isCorrect;

                    Color? backgroundColor;
                    Color? borderColor;
                    if (isAnswered) {
                      if (showCorrect) {
                        backgroundColor = PolieColors.success.withOpacity(0.2);
                        borderColor = PolieColors.success;
                      } else if (showIncorrect) {
                        backgroundColor = PolieColors.error.withOpacity(0.2);
                        borderColor = PolieColors.error;
                      }
                    } else if (isSelected) {
                      backgroundColor = PolieColors.royalAmethyst.withOpacity(0.2);
                      borderColor = PolieColors.royalAmethyst;
                    }

                    return Semantics(
                      label: 'Select word: $word',
                      button: true,
                      enabled: !isAnswered,
                      child: GestureDetector(
                        onTap: isAnswered ? null : () {
                          HapticFeedback.selectionClick();
                          _selectAnswer(word);
                        },
                        child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: PolieSpacing.md,
                          vertical: PolieSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: Border.all(
                            color: borderColor ?? Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(PolieRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              word,
                              style: PolieTypography.body(context).copyWith(
                                color: PolieColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (showCorrect) ...[
                              SizedBox(width: PolieSpacing.xs),
                              Icon(Icons.check_circle, color: PolieColors.success, size: 16),
                            ],
                            if (showIncorrect) ...[
                              SizedBox(width: PolieSpacing.xs),
                              Icon(Icons.cancel, color: PolieColors.error, size: 16),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: PolieSpacing.xl),
          if (isAnswered)
            PolieGlassCard(
              padding: EdgeInsets.all(PolieSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'Correct!' : 'Incorrect',
                    style: PolieTypography.h3(context).copyWith(
                      color: isCorrect ? PolieColors.success : PolieColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: PolieSpacing.sm),
                  Text(
                    exercise.explanation,
                    style: PolieTypography.body(context).copyWith(
                      color: PolieColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: PolieSpacing.lg),
          if (!isAnswered)
            Semantics(
              label: 'Check your answer',
              button: true,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _checkAnswer,
                  style: FilledButton.styleFrom(
                    backgroundColor: PolieColors.goldEmber,
                    padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PolieRadius.md),
                    ),
                  ),
                  child: Text(
                    'Check Answer',
                    style: PolieTypography.button(context).copyWith(
                      color: PolieColors.obsidian,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen(BuildContext context, bool isDark) {
    final multiplier = _comboTracker.currentMultiplier;
    final baseXP = _exercises.length * 10;
    final xpEarned = (baseXP * multiplier).round();
    final percentage = (_score / _exercises.length * 100).round();

    return Scaffold(
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PolieSpacing.xl),
            child: Column(
              children: [
                Icon(
                  _score == _exercises.length ? Icons.celebration : Icons.check_circle,
                  size: 80.sp,
                  color: PolieColors.goldEmber,
                ),
                SizedBox(height: PolieSpacing.xl),
                Text(
                  _score == _exercises.length ? 'Perfect Score!' : 'Exercise Complete!',
                  style: PolieTypography.h1(context).copyWith(
                    color: PolieColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: PolieSpacing.lg),
                PolieGlassCard(
                  padding: EdgeInsets.all(PolieSpacing.xl),
                  child: Column(
                    children: [
                      Text(
                        'Score: $_score/${_exercises.length}',
                        style: PolieTypography.h2(context).copyWith(
                          color: PolieColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: PolieSpacing.md),
                      Text(
                        '$percentage%',
                        style: PolieTypography.h1(context).copyWith(
                          color: PolieColors.goldEmber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: PolieSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                'XP Earned',
                                style: PolieTypography.label(context).copyWith(
                                  color: PolieColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: PolieSpacing.xs),
                              Text(
                                '+$xpEarned',
                                style: PolieTypography.h3(context).copyWith(
                                  color: PolieColors.goldEmber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (_comboTracker.maxCombo > 0)
                            Column(
                              children: [
                                Text(
                                  'Max Combo',
                                  style: PolieTypography.label(context).copyWith(
                                    color: PolieColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: PolieSpacing.xs),
                                Text(
                                  '${_comboTracker.maxCombo}x',
                                  style: PolieTypography.h3(context).copyWith(
                                    color: PolieColors.royalAmethyst,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: PolieSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Finish and return',
                        button: true,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                            side: BorderSide(color: PolieColors.goldEmber),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(PolieRadius.md),
                            ),
                          ),
                          child: Text(
                            'Done',
                            style: PolieTypography.button(context).copyWith(
                              color: PolieColors.goldEmber,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: PolieSpacing.md),
                    Expanded(
                      child: Semantics(
                        label: 'Restart exercise',
                        button: true,
                        child: FilledButton(
                          onPressed: _resetExercise,
                          style: FilledButton.styleFrom(
                            backgroundColor: PolieColors.goldEmber,
                            padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(PolieRadius.md),
                            ),
                          ),
                          child: Text(
                            'Try Again',
                            style: PolieTypography.button(context).copyWith(
                              color: PolieColors.obsidian,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

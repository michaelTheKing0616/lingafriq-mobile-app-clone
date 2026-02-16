import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/data/language_words.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/progress_integration.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/services/sound_effects_service.dart';

class FillInTheBlankGame extends ConsumerStatefulWidget {
  final Language language;

  const FillInTheBlankGame({
    super.key,
    required this.language,
  });

  @override
  ConsumerState<FillInTheBlankGame> createState() => _FillInTheBlankGameState();
}

class FillInTheBlankQuestion {
  final String sentence;
  final String blankWord;
  final String correctAnswer;
  final List<String> options;
  final String translation;

  FillInTheBlankQuestion({
    required this.sentence,
    required this.blankWord,
    required this.correctAnswer,
    required this.options,
    required this.translation,
  });
}

class _FillInTheBlankGameState extends ConsumerState<FillInTheBlankGame> {
  List<FillInTheBlankQuestion> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  int _score = 0;
  int _correctAnswers = 0;
  bool _gameComplete = false;
  bool _showResult = false;
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    final words = LanguageWords.getWordsForLanguage(widget.language.name);
    final shuffledWords = List<Map<String, String>>.from(words)..shuffle();
    
    // Create 10 fill-in-the-blank questions
    _questions = shuffledWords.take(10).map((word) {
      final englishWord = word['english']!;
      final translation = word['translation']!;
      
      // Create a simple sentence with blank
      final sentences = [
        'I want to learn _____ today.',
        'The word _____ means $translation.',
        'Can you say _____?',
        '_____ is an important word.',
        'Let\'s practice _____ together.',
      ];
      final sentence = sentences[Random().nextInt(sentences.length)];
      final sentenceWithBlank = sentence.replaceAll('_____', '_____');
      
      // Get wrong options
      final wrongOptions = shuffledWords
          .where((w) => w != word && w['english'] != englishWord)
          .take(3)
          .map((w) => w['english']!)
          .toList();
      
      final options = [englishWord, ...wrongOptions]..shuffle();
      
      return FillInTheBlankQuestion(
        sentence: sentenceWithBlank,
        blankWord: '_____',
        correctAnswer: englishWord,
        options: options,
        translation: translation,
      );
    }).toList();
    
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _gameComplete = false;
      _showResult = false;
      _selectedAnswer = null;
      _answerController.clear();
    });
  }

  void _selectAnswer(String answer) {
    if (_showResult) return;
    
    final isCorrect = answer == _questions[_currentIndex].correctAnswer;
    final soundEffects = ref.read(soundEffectsProvider);
    if (isCorrect) {
      soundEffects.playCorrect();
    } else {
      soundEffects.playIncorrect();
    }

    setState(() {
      _selectedAnswer = answer;
      _showResult = true;
      
      if (isCorrect) {
        _score += 10;
        _correctAnswers++;
      }
    });
    
    // Auto-advance after showing result
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showResult = false;
        _answerController.clear();
      });
    } else {
      _completeGame();
    }
  }

  Future<void> _completeGame() async {
    setState(() {
      _gameComplete = true;
    });
    if (_correctAnswers == _questions.length) {
      ref.read(soundEffectsProvider).playCelebration();
    } else {
      ref.read(soundEffectsProvider).playCorrect();
    }

    // Sync with backend: ProgressIntegration + gamification + learner activity
    try {
      await ProgressIntegration.onGameCompleted(
        ref as Ref,
        wordsLearned: _correctAnswers,
        pointsEarned: _score,
        perfect: _correctAnswers == _questions.length,
      );
      final api = ref.read(apiProvider.notifier);
      final user = ref.read(userProvider);
      if (user != null) {
        await api.recordLearnerActivity(
          userId: user.id.toString(),
          language: widget.language.name,
          activityType: 'fill_in_blank_game',
          metadata: {
            'score': _score,
            'correct_answers': _correctAnswers,
            'total_questions': _questions.length,
          },
        );
      }
    } catch (e) {
      debugPrint('Error syncing game progress: $e');
    }
  }

  void _restartGame() {
    _initializeGame();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_gameComplete) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Fill in the Blank - ${widget.language.name}'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PanAfricanColors.primary,
                  PanAfricanColors.secondary,
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey[900]!,
                      Colors.grey[800]!,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      PanAfricanColors.primary.withOpacity(0.1),
                      PanAfricanColors.secondary.withOpacity(0.1),
                    ],
                  ),
          ),
          child: Center(
              child: Semantics(
                label: 'Game complete. Score: $_score out of ${_questions.length * 10}. Correct: $_correctAnswers out of ${_questions.length}.',
                child: PanAfricanCard(
                child: Padding(
                padding: EdgeInsets.all(24.sp),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                      _score >= 70 ? Icons.celebration : Icons.check_circle,
                      size: 80.sp,
                      color: _score >= 70 ? PanAfricanColors.secondary : PanAfricanColors.primary,
                    ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Game Complete!',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: context.adaptive,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Score: $_score / ${_questions.length * 10}',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: PanAfricanColors.primary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Correct: $_correctAnswers / ${_questions.length}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: context.adaptive54,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Semantics(
                      label: 'Play again button',
                      button: true,
                      child: PanAfricanButton(
                        label: 'Play Again',
                        onPressed: _restartGame,
                        backgroundColor: PanAfricanColors.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Semantics(
                      label: 'Back to games',
                      button: true,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back to Games',
                          style: TextStyle(color: PanAfricanColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Fill in the Blank - ${widget.language.name}'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final question = _questions[_currentIndex];
    final isCorrect = _selectedAnswer == question.correctAnswer;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Fill in the Blank - ${widget.language.name}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PanAfricanColors.primary,
                PanAfricanColors.secondary,
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[900]!,
                    Colors.grey[800]!,
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.primary.withOpacity(0.1),
                    PanAfricanColors.secondary.withOpacity(0.1),
                  ],
                ),
        ),
        child: ResponsiveSafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      label: 'Question ${_currentIndex + 1} of ${_questions.length}',
                      child: Text(
                        'Question ${_currentIndex + 1} / ${_questions.length}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: context.adaptive,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Score: $_score',
                      child: Text(
                        'Score: $_score',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: PanAfricanColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Semantics(
                  label: 'Progress: ${((_currentIndex + 1) / _questions.length * 100).toInt()}%',
                  value: '${_currentIndex + 1} of ${_questions.length}',
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _questions.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
                  ),
                ),
                SizedBox(height: 32.h),
                
                // Question card
                PanAfricanCard(
                  child: Padding(
                    padding: EdgeInsets.all(20.sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete the sentence:',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: context.adaptive,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          question.sentence.replaceAll('_____', _showResult && isCorrect
                              ? question.correctAnswer
                              : _showResult && !isCorrect
                                  ? _selectedAnswer ?? '_____'
                                  : '_____'),
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w500,
                            color: _showResult
                                ? (isCorrect ? PanAfricanColors.primary : Colors.red)
                                : context.adaptive,
                          ),
                        ),
                        if (_showResult) ...[
                          SizedBox(height: 16.h),
                          Container(
                            padding: EdgeInsets.all(12.sp),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? PanAfricanColors.primary.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect ? PanAfricanColors.primary : Colors.red,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    isCorrect
                                        ? 'Correct! "$question.correctAnswer" means "$question.translation"'
                                        : 'Incorrect. The correct answer is "$question.correctAnswer" which means "$question.translation"',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: context.adaptive,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                
                // Answer options
                if (!_showResult) ...[
                  Text(
                    'Select the correct word:',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: context.adaptive,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ...question.options.map((option) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Semantics(
                        label: 'Answer option: $option',
                        button: true,
                        child: PanAfricanCard(
                          onTap: () => _selectAnswer(option),
                          child: Padding(
                            padding: EdgeInsets.all(16.sp),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w500,
                                      color: context.adaptive,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16.sp,
                                  color: context.adaptive54,
                                  semanticLabel: 'Select',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

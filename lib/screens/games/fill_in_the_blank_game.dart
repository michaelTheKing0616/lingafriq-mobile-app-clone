import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/data/language_words.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/progress_integration.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/modern_card.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FillInTheBlankGame extends ConsumerStatefulWidget {
  final Language language;

  const FillInTheBlankGame({
    Key? key,
    required this.language,
  }) : super(key: key);

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
    
    setState(() {
      _selectedAnswer = answer;
      _showResult = true;
      
      if (answer == _questions[_currentIndex].correctAnswer) {
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
    
    if (_gameComplete) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Fill in the Blank - ${widget.language.name}'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen,
                  AppColors.accentGold,
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
                      AppColors.primaryGreen.withOpacity(0.1),
                      AppColors.accentGold.withOpacity(0.1),
                    ],
                  ),
          ),
          child: Center(
            child: ModernCard(
              child: Padding(
                padding: EdgeInsets.all(24.sp),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _score >= 70 ? Icons.celebration : Icons.check_circle,
                      size: 80.sp,
                      color: _score >= 70 ? AppColors.accentGold : AppColors.primaryGreen,
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
                        color: AppColors.primaryGreen,
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
                    PrimaryButton(
                      text: 'Play Again',
                      onTap: _restartGame,
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Back to Games',
                        style: TextStyle(color: AppColors.primaryGreen),
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
                AppColors.primaryGreen,
                AppColors.accentGold,
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
                    AppColors.primaryGreen.withOpacity(0.1),
                    AppColors.accentGold.withOpacity(0.1),
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
                    Text(
                      'Question ${_currentIndex + 1} / ${_questions.length}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: context.adaptive,
                      ),
                    ),
                    Text(
                      'Score: $_score',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
                SizedBox(height: 32.h),
                
                // Question card
                ModernCard(
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
                                ? (isCorrect ? AppColors.primaryGreen : Colors.red)
                                : context.adaptive,
                          ),
                        ),
                        if (_showResult) ...[
                          SizedBox(height: 16.h),
                          Container(
                            padding: EdgeInsets.all(12.sp),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? AppColors.primaryGreen.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect ? AppColors.primaryGreen : Colors.red,
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
                      child: ModernCard(
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
                              ),
                            ],
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

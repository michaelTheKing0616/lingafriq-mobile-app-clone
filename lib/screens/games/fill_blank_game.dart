import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/data/language_words.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/modern_card.dart';
import 'package:lingafriq/widgets/primary_button.dart';

class FillBlankGame extends ConsumerStatefulWidget {
  final Language language;

  const FillBlankGame({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  ConsumerState<FillBlankGame> createState() => _FillBlankGameState();
}

class _FillBlankGameState extends ConsumerState<FillBlankGame> {
  List<FillBlankQuestion> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  int _score = 0;
  int _correctAnswers = 0;
  bool _gameComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    final words = LanguageWords.getWordsForLanguage(widget.language.name);
    final shuffledWords = List<Map<String, String>>.from(words)..shuffle();
    
    // Create 10 fill-in-the-blank questions
    _questions = shuffledWords.take(10).map((word) {
      // Create simple sentence templates
      final templates = [
        'I need some _____.',
        'This is a _____.',
        'I like _____.',
        'Where is the _____?',
        'Can I have some _____?',
      ];
      final template = templates[Random().nextInt(templates.length)];
      final sentence = template.replaceAll('_____', word['english']!);
      final options = [
        word['translation']!,
        ...shuffledWords.where((w) => w != word).take(3).map((w) => w['translation']!),
      ]..shuffle();
      
      return FillBlankQuestion(
        sentence: sentence.replaceAll(word['english']!, '_____'),
        correctAnswer: word['translation']!,
        options: options,
        englishWord: word['english']!,
      );
    }).toList();
    
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _gameComplete = false;
      _selectedAnswer = null;
    });
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswer = answer;
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) return;
    
    final isCorrect = _selectedAnswer == _questions[_currentIndex].correctAnswer;
    
    if (isCorrect) {
      setState(() {
        _correctAnswers++;
        _score += 1;
      });
    }
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        if (_currentIndex < _questions.length - 1) {
          setState(() {
            _currentIndex++;
            _selectedAnswer = null;
          });
        } else {
          // Game complete
          final finalScore = (10 * (_correctAnswers / _questions.length)).round();
          setState(() {
            _gameComplete = true;
            _score = finalScore;
          });
          _updateUserPoints(_score);
        }
      }
    });
  }

  Future<void> _updateUserPoints(int points) async {
    try {
      final user = ref.read(userProvider);
      if (user != null) {
        await ref.read(apiProvider.notifier).getProfileUser(user.id);
      }
    } catch (e) {
      debugPrint('Failed to update user points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameComplete) {
      return _buildGameComplete();
    }
    
    final question = _questions[_currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Fill in the Blank - ${widget.language.name}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accentGold, AppColors.primaryOrange],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            children: [
              // Progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentIndex + 1}/${_questions.length}',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Score: $_score',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8.sp),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: context.adaptive12,
                color: AppColors.accentGold,
              ),
              SizedBox(height: 24.sp),
              
              // Question
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      question.sentence,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: context.adaptive,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.sp),
                    
                    // Options
                    ...question.options.map((option) {
                      final isSelected = _selectedAnswer == option;
                      final isCorrect = option == question.correctAnswer;
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.sp),
                        child: ModernCard(
                          onTap: () => _selectAnswer(option),
                          child: Container(
                            padding: EdgeInsets.all(16.sp),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isCorrect 
                                      ? AppColors.success.withOpacity(0.2)
                                      : AppColors.red.withOpacity(0.2))
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? (isCorrect ? AppColors.success : AppColors.red)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.adaptive,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    isCorrect ? Icons.check_circle : Icons.cancel,
                                    color: isCorrect ? AppColors.success : AppColors.red,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              // Submit button
              PrimaryButton(
                onTap: _selectedAnswer != null ? _submitAnswer : null,
                text: _currentIndex < _questions.length - 1 ? 'Next' : 'Finish',
                color: AppColors.accentGold,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameComplete() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Complete'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accentGold, AppColors.primaryOrange],
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(32.sp),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentGold, AppColors.primaryOrange],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.celebration, color: Colors.white, size: 64.sp),
              ),
              SizedBox(height: 24.sp),
              Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: context.adaptive,
                ),
              ),
              SizedBox(height: 12.sp),
              Text(
                'You completed the game!',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: context.adaptive54,
                ),
              ),
              SizedBox(height: 8.sp),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentGold, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: AppColors.accentGold, size: 24.sp),
                    SizedBox(width: 8),
                    Text(
                      '+$_score Points Earned!',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.sp),
              PrimaryButton(
                onTap: () {
                  Navigator.pop(context);
                },
                text: 'Back to Games',
                color: AppColors.accentGold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FillBlankQuestion {
  final String sentence;
  final String correctAnswer;
  final List<String> options;
  final String englishWord;

  FillBlankQuestion({
    required this.sentence,
    required this.correctAnswer,
    required this.options,
    required this.englishWord,
  });
}


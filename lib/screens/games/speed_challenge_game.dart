import 'dart:async';
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

class SpeedChallengeGame extends ConsumerStatefulWidget {
  final Language language;

  const SpeedChallengeGame({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  ConsumerState<SpeedChallengeGame> createState() => _SpeedChallengeGameState();
}

class _SpeedChallengeGameState extends ConsumerState<SpeedChallengeGame> {
  List<SpeedQuestion> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  int _score = 0;
  int _correctAnswers = 0;
  int _timeRemaining = 60; // 60 seconds
  bool _gameStarted = false;
  bool _gameComplete = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    final words = LanguageWords.getWordsForLanguage(widget.language.name);
    final shuffledWords = List<Map<String, String>>.from(words)..shuffle();
    
    // Create 20 quick questions
    _questions = shuffledWords.take(20).map((word) {
      final wrongOptions = shuffledWords
          .where((w) => w != word)
          .take(3)
          .map((w) => w['translation']!)
          .toList();
      final options = [word['translation']!, ...wrongOptions]..shuffle();
      
      return SpeedQuestion(
        englishWord: word['english']!,
        correctAnswer: word['translation']!,
        options: options,
      );
    }).toList();
    
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _timeRemaining = 60;
      _gameStarted = false;
      _gameComplete = false;
      _selectedAnswer = null;
    });
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeRemaining--;
          if (_timeRemaining <= 0) {
            _endGame();
          }
        });
      }
    });
  }

  void _endGame() {
    _timer?.cancel();
    final finalScore = (10 * (_correctAnswers / _questions.length)).round();
    setState(() {
      _gameComplete = true;
      _score = finalScore;
    });
    _updateUserPoints(_score);
  }

  void _selectAnswer(String answer) {
    if (!_gameStarted || _gameComplete) return;
    
    setState(() {
      _selectedAnswer = answer;
    });
    
    final isCorrect = answer == _questions[_currentIndex].correctAnswer;
    
    if (isCorrect) {
      setState(() {
        _correctAnswers++;
      });
    }
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_gameComplete) {
        if (_currentIndex < _questions.length - 1) {
          setState(() {
            _currentIndex++;
            _selectedAnswer = null;
          });
        } else {
          _endGame();
        }
      }
    });
  }

  Future<void> _updateUserPoints(int points) async {
    try {
      debugPrint('Updating user points: $points (correct: $_correctAnswers, total: ${_questions.length})');
      
      final user = ref.read(userProvider);
      if (user != null) {
        final oldPoints = user.completed_point;
        debugPrint('User points before update: $oldPoints');
        
        // Submit game completion
        final gameSuccess = await ref.read(apiProvider.notifier).submitGameCompletion(
          gameType: 'speed_challenge',
          languageId: widget.language.id,
          points: points,
          score: _correctAnswers,
        );
        
        final updateSuccess = await ref.read(apiProvider.notifier).accountUpdate();
        debugPrint('Account update success: $updateSuccess');
        
        if (updateSuccess) {
          await Future.delayed(const Duration(milliseconds: 1500));
          
          try {
            final updatedUser = await ref.read(apiProvider.notifier).getProfileUser(user.id);
            if (updatedUser != null) {
              final newPoints = updatedUser.completed_point;
              debugPrint('User points after update: $newPoints (increase: ${newPoints - oldPoints})');
              ref.read(userProvider.notifier).overrideUser(updatedUser);
              
              if (newPoints > oldPoints) {
                debugPrint('✅ Game points successfully added!');
              } else {
                debugPrint('⚠️ Points may not have been added. Backend may need game completion endpoint.');
              }
            }
          } catch (e) {
            debugPrint('Error refreshing user profile: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to update user points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop && !_gameComplete && _gameStarted) {
            final shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit Game?'),
                content: const Text('Are you sure you want to exit? Your progress will not be saved.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Exit'),
                  ),
                ],
              ),
            );
            if (shouldPop == true && context.mounted) {
              Navigator.pop(context);
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () async {
                  if (!_gameComplete && _gameStarted) {
                    final shouldPop = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Exit Game?'),
                        content: const Text('Are you sure you want to exit? Your progress will not be saved.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Exit'),
                          ),
                        ],
                      ),
                    );
                    if (shouldPop == true && context.mounted) {
                      Navigator.pop(context);
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          title: Text('Speed Challenge - ${widget.language.name}'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.oceanBlue, AppColors.primaryGreen],
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
                Icon(Icons.flash_on, size: 80.sp, color: AppColors.oceanBlue),
                SizedBox(height: 24.sp),
                Text(
                  'Speed Challenge',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: context.adaptive,
                  ),
                ),
                SizedBox(height: 12.sp),
                Text(
                  'Answer as many questions as you can in 60 seconds!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: context.adaptive54,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.sp),
                SafeArea(
                  top: false,
                  minimum: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewPadding.bottom,
                    ),
                    child: PrimaryButton(
                      onTap: _startGame,
                      text: 'Start Game',
                      color: AppColors.oceanBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_gameComplete) {
      return _buildGameComplete();
    }
    
    final question = _questions[_currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Speed Challenge'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.oceanBlue, AppColors.primaryGreen],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            children: [
              // Timer and score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _timeRemaining <= 10 
                          ? AppColors.red.withOpacity(0.2)
                          : AppColors.oceanBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _timeRemaining <= 10 
                            ? AppColors.red
                            : AppColors.oceanBlue,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: _timeRemaining <= 10 
                              ? AppColors.red
                              : AppColors.oceanBlue,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '$_timeRemaining',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: _timeRemaining <= 10 
                                ? AppColors.red
                                : AppColors.oceanBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryGreen, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: AppColors.accentGold, size: 20.sp),
                        SizedBox(width: 8),
                        Text(
                          '$_correctAnswers',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.sp),
              
              // Question
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'What is "${question.englishWord}"?',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: context.adaptive,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.sp),
                    
                    // Options
                    ...question.options.map((option) {
                      final isSelected = _selectedAnswer == option;
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.sp),
                        child: ModernCard(
                          onTap: () => _selectAnswer(option),
                          child: Container(
                            padding: EdgeInsets.all(16.sp),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.oceanBlue.withOpacity(0.2)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.oceanBlue
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: context.adaptive,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
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
              colors: [AppColors.oceanBlue, AppColors.primaryGreen],
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
                    colors: [AppColors.oceanBlue, AppColors.primaryGreen],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.celebration, color: Colors.white, size: 64.sp),
              ),
              SizedBox(height: 24.sp),
              Text(
                'Time\'s Up!',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: context.adaptive,
                ),
              ),
              SizedBox(height: 12.sp),
              Text(
                'You answered $_correctAnswers out of ${_questions.length} questions',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: context.adaptive54,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.sp),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.oceanBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.oceanBlue, width: 2),
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
                        color: AppColors.oceanBlue,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.sp),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    onTap: () {
                      // Restart the game
                      setState(() {
                        _gameComplete = false;
                        _gameStarted = false;
                        _currentIndex = 0;
                        _correctAnswers = 0;
                        _selectedAnswer = null;
                        _score = 0;
                        _timeRemaining = 30;
                      });
                      _initializeGame();
                    },
                    text: 'Play Again',
                    color: AppColors.oceanBlue,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    text: 'Return to Games',
                    color: AppColors.oceanBlue.withOpacity(0.7),
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

class SpeedQuestion {
  final String englishWord;
  final String correctAnswer;
  final List<String> options;

  SpeedQuestion({
    required this.englishWord,
    required this.correctAnswer,
    required this.options,
  });
}


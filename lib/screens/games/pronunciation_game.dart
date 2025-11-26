import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/data/language_words.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/tts_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/modern_card.dart';
import 'package:lingafriq/widgets/primary_button.dart';

class PronunciationGame extends ConsumerStatefulWidget {
  final Language language;

  const PronunciationGame({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  ConsumerState<PronunciationGame> createState() => _PronunciationGameState();
}

class _PronunciationGameState extends ConsumerState<PronunciationGame> {
  List<PronunciationQuestion> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  int _score = 0;
  int _correctAnswers = 0;
  bool _isPlaying = false;
  bool _gameComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    final words = LanguageWords.getWordsForLanguage(widget.language.name);
    final shuffledWords = List<Map<String, String>>.from(words)..shuffle();
    
    // Create 10 pronunciation questions
    _questions = shuffledWords.take(10).map((word) {
      final wrongOptions = shuffledWords
          .where((w) => w != word)
          .take(3)
          .map((w) => w['english']!)
          .toList();
      final options = [word['english']!, ...wrongOptions]..shuffle();
      
      return PronunciationQuestion(
        wordToPronounce: word['translation']!,
        correctAnswer: word['english']!,
        options: options,
        translation: word['translation']!,
      );
    }).toList();
    
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _gameComplete = false;
      _selectedAnswer = null;
      _isPlaying = false;
    });
  }

  Future<void> _playPronunciation() async {
    if (_isPlaying) return;
    
    setState(() {
      _isPlaying = true;
    });
    
    try {
      final question = _questions[_currentIndex];
      // Pass language name for proper TTS language selection
      await ref.read(ttsProvider.notifier).speak(
        question.wordToPronounce,
        languageName: widget.language.name,
      );
      
      // Wait a bit before allowing replay
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      setState(() {
        _isPlaying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing pronunciation: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
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
          // Auto-play next pronunciation
          _playPronunciation();
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
      // Points are already calculated: max 10 points for perfect game
      // Formula: 10 * (correct_answers / total_questions)
      // Update user points using the same pattern as quizzes/lessons
      final user = ref.read(userProvider);
      if (user != null) {
        // First, call accountUpdate which may trigger server-side point updates
        final updateSuccess = await ref.read(apiProvider.notifier).accountUpdate();
        
        if (updateSuccess) {
          // Wait a bit for server to process
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Refresh user profile to get latest points (same as quizzes/lessons)
          final updatedUser = await ref.read(apiProvider.notifier).getProfileUser(user.id);
          if (updatedUser != null) {
            ref.read(userProvider.notifier).overrideUser(updatedUser);
            debugPrint('Game points updated successfully. New total: ${updatedUser.completedPoint}');
          }
        }
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
        title: Text('Pronunciation Practice - ${widget.language.name}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accentOrange, AppColors.red],
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
                color: AppColors.accentOrange,
              ),
              SizedBox(height: 24.sp),
              
              // Pronunciation area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play button
                    GestureDetector(
                      onTap: _playPronunciation,
                      child: Container(
                        width: 120.sp,
                        height: 120.sp,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.accentOrange, AppColors.red],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentOrange.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: _isPlaying
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                Icons.volume_up,
                                color: Colors.white,
                                size: 48.sp,
                              ),
                      ),
                    ),
                    SizedBox(height: 24.sp),
                    Text(
                      'Tap to hear pronunciation',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: context.adaptive54,
                      ),
                    ),
                    SizedBox(height: 8.sp),
                    Text(
                      question.translation,
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: context.adaptive,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.sp),
                    Text(
                      'What word did you hear?',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: context.adaptive,
                      ),
                    ),
                    SizedBox(height: 16.sp),
                    
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
              
              // Submit button with safe bottom padding
              SafeArea(
                top: false,
                minimum: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: PrimaryButton(
                    onTap: _submitAnswer,
                    enabled: _selectedAnswer != null,
                    text: _currentIndex < _questions.length - 1 ? 'Next' : 'Finish',
                    color: AppColors.accentOrange,
                  ),
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
              colors: [AppColors.accentOrange, AppColors.red],
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
                    colors: [AppColors.accentOrange, AppColors.red],
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
                'You completed the pronunciation practice!',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: context.adaptive54,
                ),
              ),
              SizedBox(height: 8.sp),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentOrange, width: 2),
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
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PrimaryButton(
                    onTap: () {
                      // Restart the game
                      setState(() {
                        _gameComplete = false;
                        _currentIndex = 0;
                        _correctAnswers = 0;
                        _selectedAnswer = null;
                        _score = 0;
                      });
                      _initializeGame();
                    },
                    text: 'Play Again',
                    color: AppColors.accentOrange,
                  ),
                  SizedBox(width: 16),
                  PrimaryButton(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    text: 'Back to Games',
                    color: AppColors.accentOrange.withOpacity(0.5),
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

class PronunciationQuestion {
  final String wordToPronounce;
  final String correctAnswer;
  final List<String> options;
  final String translation;

  PronunciationQuestion({
    required this.wordToPronounce,
    required this.correctAnswer,
    required this.options,
    required this.translation,
  });
}


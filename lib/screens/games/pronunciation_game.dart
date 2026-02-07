import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lingafriq/data/language_words.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/progress_integration.dart';
import 'package:lingafriq/providers/tts_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

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
            backgroundColor: PanAfricanColors.error,
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
      debugPrint('Updating user points: $points (correct: $_correctAnswers, total: ${_questions.length})');
      
      final user = ref.read(userProvider);
      if (user != null) {
        final oldPoints = user.completed_point;
        debugPrint('User points before update: $oldPoints');
        
        // Submit game completion
        final gameSuccess = await ref.read(apiProvider.notifier).submitGameCompletion(
          gameType: 'pronunciation',
          languageId: widget.language.id,
          points: points,
          score: _correctAnswers,
        );
        if (gameSuccess) {
          await ProgressIntegration.onGameCompleted(ref as Ref, wordsLearned: _correctAnswers, pointsEarned: points);
          ref.read(userProvider.notifier).addPoints(points);
        }
        
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
    if (_gameComplete) {
      return _buildGameComplete();
    }
    
    final question = _questions[_currentIndex];
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleExitRequest();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _handleExitRequest,
            ),
          ),
        title: Text('Pronunciation Practice - ${widget.language.name}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [PanAfricanColors.tertiary, PanAfricanColors.error],
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
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: context.adaptive),
                    onPressed: _handleExitRequest,
                  ),
                  Expanded(
                    child: Text(
                      'Question ${_currentIndex + 1}/${_questions.length}',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
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
                color: PanAfricanColors.tertiary,
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
                            colors: [PanAfricanColors.tertiary, PanAfricanColors.error],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: PanAfricanColors.tertiary.withOpacity(0.4),
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
                        child: PanAfricanCard(
                          onTap: () => _selectAnswer(option),
                          child: Container(
                            padding: EdgeInsets.all(16.sp),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isCorrect 
                                      ? PanAfricanColors.success.withOpacity(0.2)
                                      : PanAfricanColors.error.withOpacity(0.2))
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? (isCorrect ? PanAfricanColors.success : PanAfricanColors.error)
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
                                    color: isCorrect ? PanAfricanColors.success : PanAfricanColors.error,
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
                  child: PanAfricanButton(
                    onPressed: _selectedAnswer != null ? _submitAnswer : null,
                    label: _currentIndex < _questions.length - 1 ? 'Next' : 'Finish',
                    backgroundColor: _selectedAnswer != null
                        ? PanAfricanColors.tertiary
                        : PanAfricanColors.tertiary.withOpacity(0.5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
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
              colors: [PanAfricanColors.tertiary, PanAfricanColors.error],
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
                    colors: [PanAfricanColors.tertiary, PanAfricanColors.error],
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
                  color: PanAfricanColors.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PanAfricanColors.tertiary, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: PanAfricanColors.secondary, size: 24.sp),
                    SizedBox(width: 8),
                    Text(
                      '+$_score Points Earned!',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: PanAfricanColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.sp),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PanAfricanButton(
                    onPressed: () {
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
                    label: 'Play Again',
                    backgroundColor: PanAfricanColors.tertiary,
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  PanAfricanButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    label: 'Return to Games',
                    backgroundColor: PanAfricanColors.tertiary.withOpacity(0.7),
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExitRequest() async {
    if (_gameComplete) {
      if (mounted) Navigator.pop(context);
      return;
    }
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
    if (shouldPop == true && mounted) {
      Navigator.pop(context);
    }
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


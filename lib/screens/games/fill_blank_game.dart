import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/data/language_words.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/design_system.dart';
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
    
    // Emoji mapping for common words to provide visual context
    final emojiMap = {
      'Water': '💧',
      'Food': '🍽️',
      'Friend': '👫',
      'House': '🏠',
      'Book': '📚',
      'School': '🏫',
      'Teacher': '👨‍🏫',
      'Student': '👨‍🎓',
      'Mother': '👩',
      'Father': '👨',
      'Child': '👶',
      'Good': '👍',
      'Bad': '👎',
      'Big': '🔵',
      'Small': '🔴',
      'Hot': '🔥',
      'Cold': '❄️',
      'Day': '☀️',
      'Night': '🌙',
      'Sun': '☀️',
      'Moon': '🌙',
      'Star': '⭐',
      'Tree': '🌳',
      'Bird': '🐦',
      'Dog': '🐕',
      'Cat': '🐱',
      'Money': '💰',
      'Hello': '👋',
      'Thank you': '🙏',
      'Goodbye': '👋',
    };
    
    // Create 10 fill-in-the-blank questions with better context
    _questions = shuffledWords.take(10).map((word) {
      final englishWord = word['english']!;
      final emoji = emojiMap[englishWord] ?? '📝';
      
      // Create contextual sentence templates with emoji
      final templates = [
        'I need some $emoji _____.',
        'This is a $emoji _____.',
        'I like $emoji _____.',
        'Where is the $emoji _____?',
        'Can I have some $emoji _____?',
        'Look at the $emoji _____.',
        'I see a $emoji _____.',
        'The $emoji _____ is here.',
      ];
      final template = templates[Random().nextInt(templates.length)];
      final sentence = template.replaceAll('_____', englishWord);
      final options = [
        word['translation']!,
        ...shuffledWords.where((w) => w != word).take(3).map((w) => w['translation']!),
      ]..shuffle();
      
      return FillBlankQuestion(
        sentence: sentence.replaceAll(englishWord, '_____'),
        correctAnswer: word['translation']!,
        options: options,
        englishWord: englishWord,
        emoji: emoji,
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
      // Points are already calculated: max 10 points for perfect game
      // Formula: 10 * (correct_answers / total_questions)
      // Update user points using the same pattern as quizzes/lessons
      final user = ref.read(userProvider);
      if (user != null) {
        // Call accountUpdate which may trigger server-side point updates
        await ref.read(apiProvider.notifier).accountUpdate();
        
        // Refresh user profile to get latest points (same as quizzes/lessons)
        final updatedUser = await ref.read(apiProvider.notifier).getProfileUser(user.id);
        ref.read(userProvider.notifier).overrideUser(updatedUser);
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
    
    final isDark = context.isDarkMode;
    final progress = (_currentIndex + 1) / _questions.length;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.stitchBackgroundDark : AppColors.stitchBackgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.stitchTextDark : AppColors.stitchTextLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fill in the Blank',
          style: TextStyle(
            color: isDark ? AppColors.stitchTextDark : AppColors.stitchTextLight,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar (Stitch style)
            Padding(
              padding: EdgeInsets.all(DesignSystem.spacingM),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentIndex + 1} of ${_questions.length}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.stitchTextDark : AppColors.stitchTextLight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.spacingS),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.stitchPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(DesignSystem.spacingM),
                child: Column(
                  children: [
                    // Emoji/Illustration Area
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.stitchPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                      ),
                      child: Center(
                        child: Text(
                          question.emoji ?? '📝',
                          style: TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                    SizedBox(height: DesignSystem.spacingL),
                    
                    // Sentence Display
                    Column(
                      children: [
                        Text(
                          question.sentence,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.stitchTextDark : AppColors.stitchTextLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: DesignSystem.spacingS),
                        TextButton.icon(
                          onPressed: () {
                            // Show translation
                          },
                          icon: Icon(Icons.translate, size: 16),
                          label: Text('Show translation'),
                          style: TextButton.styleFrom(
                            foregroundColor: (isDark ? AppColors.stitchTextDark : AppColors.stitchTextLight)
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignSystem.spacingL),
                    
                    // Answer Options (Stitch style with borders)
                    ...question.options.map((option) {
                      final isSelected = _selectedAnswer == option;
                      final isCorrect = option == question.correctAnswer;
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: DesignSystem.spacingM),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectAnswer(option),
                            borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isCorrect 
                                        ? AppColors.stitchPrimary.withOpacity(0.2)
                                        : AppColors.stitchDanger.withOpacity(0.2))
                                    : (isDark ? AppColors.stitchCardDark : AppColors.stitchCardLight),
                                borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                                border: Border.all(
                                  color: isSelected
                                      ? (isCorrect ? AppColors.stitchPrimary : AppColors.stitchDanger)
                                      : (isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight),
                                  width: 2,
                                ),
                                boxShadow: isSelected ? DesignSystem.shadowSmall : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? (isCorrect ? AppColors.stitchPrimary : AppColors.stitchDanger)
                                            : (isDark ? AppColors.stitchTextDark : AppColors.stitchTextLight),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      isCorrect ? Icons.check_circle : Icons.cancel,
                                      color: isCorrect ? AppColors.stitchPrimary : AppColors.stitchDanger,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Footer with Action Button (Stitch style)
            Container(
              padding: EdgeInsets.only(
                left: DesignSystem.spacingM,
                right: DesignSystem.spacingM,
                top: DesignSystem.spacingM,
                bottom: DesignSystem.spacingM + MediaQuery.of(context).viewPadding.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.stitchBackgroundDark : AppColors.stitchBackgroundLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                minimum: EdgeInsets.zero,
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    onTap: _submitAnswer,
                    enabled: _selectedAnswer != null,
                    text: 'Check Answer',
                    color: AppColors.stitchPrimary,
                  ),
                ),
              ),
            ),
          ],
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
  final String? emoji;

  FillBlankQuestion({
    required this.sentence,
    required this.correctAnswer,
    required this.options,
    required this.englishWord,
    this.emoji,
  });
}


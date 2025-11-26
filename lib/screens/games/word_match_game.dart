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

class WordMatchGame extends ConsumerStatefulWidget {
  final Language language;

  const WordMatchGame({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  ConsumerState<WordMatchGame> createState() => _WordMatchGameState();
}

class _WordMatchGameState extends ConsumerState<WordMatchGame> {
  List<WordPair> _wordPairs = [];
  List<WordCard> _leftCards = [];
  List<WordCard> _rightCards = [];
  WordCard? _selectedLeft;
  WordCard? _selectedRight;
  int _score = 0;
  int _matches = 0;
  int _totalPairs = 0;
  bool _gameComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Get language-specific words
    final words = LanguageWords.getWordsForLanguage(widget.language.name);
    
    // Shuffle and take 8-12 words for variety
    final shuffledWords = List<Map<String, String>>.from(words)..shuffle();
    final selectedWords = shuffledWords.take(10).toList();
    
    // Create word pairs
    _wordPairs = selectedWords
        .map((w) => WordPair(
              english: w['english']!,
              translation: w['translation']!,
            ))
        .toList();
    
    _totalPairs = _wordPairs.length;

    // Shuffle and create cards
    final shuffledPairs = List<WordPair>.from(_wordPairs)..shuffle();
    _leftCards = shuffledPairs
        .map((pair) => WordCard(
              text: pair.english,
              pair: pair,
              isLeft: true,
            ))
        .toList();

    final shuffledTranslations = List<WordPair>.from(_wordPairs)..shuffle();
    _rightCards = shuffledTranslations
        .map((pair) => WordCard(
              text: pair.translation,
              pair: pair,
              isLeft: false,
            ))
        .toList();

    setState(() {
      _score = 0;
      _matches = 0;
      _gameComplete = false;
      _selectedLeft = null;
      _selectedRight = null;
    });
  }

  void _selectCard(WordCard card) {
    if (card.isMatched) return;

    setState(() {
      if (card.isLeft) {
        if (_selectedLeft == card) {
          _selectedLeft = null;
        } else {
          _selectedLeft = card;
          if (_selectedRight != null) {
            _checkMatch();
          }
        }
      } else {
        if (_selectedRight == card) {
          _selectedRight = null;
        } else {
          _selectedRight = card;
          if (_selectedLeft != null) {
            _checkMatch();
          }
        }
      }
    });
  }

  void _checkMatch() {
    if (_selectedLeft == null || _selectedRight == null) return;

    final isMatch = _selectedLeft!.pair == _selectedRight!.pair;

    if (isMatch) {
      setState(() {
        _selectedLeft!.isMatched = true;
        _selectedRight!.isMatched = true;
        _matches++;
        _selectedLeft = null;
        _selectedRight = null;

        if (_matches == _wordPairs.length) {
          _gameComplete = true;
          // Calculate final score: max 10 points, reduced by wrong attempts
          // For now, perfect game = 10 points (can be adjusted based on attempts)
          _score = 10;
          _updateUserPoints(_score);
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _selectedLeft = null;
            _selectedRight = null;
          });
        }
      });
    }
  }

  Future<void> _updateUserPoints(int points) async {
    try {
      // Calculate points: max 10 points for perfect game
      // Formula: 10 * (correct_matches / total_pairs)
      final calculatedPoints = _totalPairs > 0 
          ? (10 * (_matches / _totalPairs)).round()
          : 0;
      
      // Update user points using the same pattern as quizzes/lessons
      // Call accountUpdate to trigger server-side point calculation, then refresh profile
      final user = ref.read(userProvider);
      if (user != null) {
        // Call accountUpdate which may trigger server-side point updates
        await ref.read(apiProvider.notifier).accountUpdate();
        
        // Refresh user profile to get latest points (same as quizzes/lessons)
        final updatedUser = await ref.read(apiProvider.notifier).getProfileUser(user.id);
        ref.read(userProvider.notifier).overrideUser(updatedUser);
      }
    } catch (e) {
      // Log error but don't block game completion
      debugPrint('Failed to update user points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _gameComplete
            ? _buildGameComplete()
            : Column(
                children: [
                  _buildScoreBar(),
                  Padding(
                    padding: EdgeInsets.all(DesignSystem.spacingM),
                    child: Text(
                      'Match the pairs',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: context.isDarkMode ? AppColors.stitchTextDark : AppColors.stitchTextLight,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive layout: stack on small screens, side-by-side on larger
                        if (screenWidth < 400) {
                          return Column(
                            children: [
                              Expanded(
                                child: _buildCardColumn(_leftCards, true),
                              ),
                              SizedBox(height: DesignSystem.spacingM),
                              Expanded(
                                child: _buildCardColumn(_rightCards, false),
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildCardColumn(_leftCards, true),
                              ),
                              SizedBox(width: DesignSystem.spacingM),
                              Expanded(
                                child: _buildCardColumn(_rightCards, false),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildScoreBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;
    final isDark = context.isDarkMode;
    final progress = _wordPairs.isNotEmpty ? _matches / _wordPairs.length : 0.0;
    
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.stitchBackgroundDark : AppColors.stitchBackgroundLight,
        boxShadow: DesignSystem.shadowSmall,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.close, color: isDark ? AppColors.stitchTextDark : AppColors.stitchTextLight),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.stitchPrimaryGame,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Text(
                '$_matches/${_wordPairs.length}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.stitchPrimaryGame,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(IconData icon, String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: isSmall ? 20.sp : 24.sp),
        SizedBox(height: isSmall ? 2 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmall ? 18.sp : 20.sp,
            fontWeight: FontWeight.bold,
            color: context.adaptive,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 10.sp : 12.sp,
            color: context.adaptive54,
          ),
        ),
      ],
    );
  }

  Widget _buildCardColumn(List<WordCard> cards, bool isLeft) {
    final isDark = context.isDarkMode;
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final isSelected = (isLeft && _selectedLeft == card) ||
            (!isLeft && _selectedRight == card);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectCard(card),
              borderRadius: BorderRadius.circular(DesignSystem.radiusM),
              child: Container(
                height: 64,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: card.isMatched
                      ? AppColors.stitchPrimary.withOpacity(0.2)
                      : isSelected
                          ? AppColors.stitchSecondary.withOpacity(0.1)
                          : (isDark ? AppColors.stitchCardDark : AppColors.stitchCardLight),
                  borderRadius: BorderRadius.circular(DesignSystem.radiusM),
                  border: Border(
                    bottom: BorderSide(
                      color: card.isMatched
                          ? AppColors.stitchPrimary
                          : isSelected
                              ? AppColors.stitchSecondary
                              : (isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight),
                      width: 4,
                    ),
                    left: BorderSide(
                      color: card.isMatched
                          ? AppColors.stitchPrimary
                          : isSelected
                              ? AppColors.stitchSecondary
                              : (isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight),
                      width: 2,
                    ),
                    right: BorderSide(
                      color: card.isMatched
                          ? AppColors.stitchPrimary
                          : isSelected
                              ? AppColors.stitchSecondary
                              : (isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight),
                      width: 2,
                    ),
                    top: BorderSide(
                      color: card.isMatched
                          ? AppColors.stitchPrimary
                          : isSelected
                              ? AppColors.stitchSecondary
                              : (isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (card.isMatched)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.stitchPrimary,
                        size: 20.sp,
                      ),
                    if (card.isMatched) const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        card.text,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: card.isMatched
                              ? AppColors.stitchPrimary
                              : isSelected
                                  ? AppColors.stitchSecondary
                                  : (isDark ? AppColors.stitchTextDark : AppColors.stitchTextLight),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameComplete() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.accentGold,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration,
                color: Colors.white,
                size: 64.sp,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: context.adaptive,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You matched all words!',
              style: TextStyle(
                fontSize: 18.sp,
                color: context.adaptive54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGreen, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: AppColors.accentGold, size: 24.sp),
                  const SizedBox(width: 8),
                  Text(
                    '+$_score Points Earned!',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Perfect Match! All $_totalPairs pairs found',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SafeArea(
              top: false,
              minimum: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewPadding.bottom,
                ),
                child: PrimaryButton(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  text: 'Play Again',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WordPair {
  final String english;
  final String translation;

  WordPair({required this.english, required this.translation});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordPair &&
          runtimeType == other.runtimeType &&
          english == other.english &&
          translation == other.translation;

  @override
  int get hashCode => english.hashCode ^ translation.hashCode;
}

class WordCard {
  final String text;
  final WordPair pair;
  final bool isLeft;
  bool isMatched;

  WordCard({
    required this.text,
    required this.pair,
    required this.isLeft,
    this.isMatched = false,
  });
}


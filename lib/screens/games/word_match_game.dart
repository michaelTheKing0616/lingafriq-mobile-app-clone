import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/utils/app_colors.dart';
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
  bool _gameComplete = false;

  // Sample word pairs - In production, these would come from API
  final List<Map<String, String>> _sampleWords = [
    {'english': 'Hello', 'translation': 'Sannu'},
    {'english': 'Thank you', 'translation': 'Na gode'},
    {'english': 'Goodbye', 'translation': 'Sai an jima'},
    {'english': 'Water', 'translation': 'Ruwa'},
    {'english': 'Food', 'translation': 'Abinci'},
    {'english': 'Friend', 'translation': 'Aboki'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Create word pairs
    _wordPairs = _sampleWords
        .map((w) => WordPair(
              english: w['english']!,
              translation: w['translation']!,
            ))
        .toList();

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
        _score += 10;
        _matches++;
        _selectedLeft = null;
        _selectedRight = null;

        if (_matches == _wordPairs.length) {
          _gameComplete = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Word Match - ${widget.language.name}'),
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
      body: _gameComplete
          ? _buildGameComplete()
          : Column(
              children: [
                _buildScoreBar(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCardColumn(_leftCards, true),
                      ),
                      Container(
                        width: 2,
                        color: context.adaptive12,
                      ),
                      Expanded(
                        child: _buildCardColumn(_rightCards, false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildScoreBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.adaptive12,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreItem(Icons.star, 'Score', _score.toString()),
          _buildScoreItem(
            Icons.check_circle,
            'Matches',
            '$_matches/${_wordPairs.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 24.sp),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: context.adaptive,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: context.adaptive54,
          ),
        ),
      ],
    );
  }

  Widget _buildCardColumn(List<WordCard> cards, bool isLeft) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final isSelected = (isLeft && _selectedLeft == card) ||
            (!isLeft && _selectedRight == card);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ModernCard(
            onTap: () => _selectCard(card),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card.isMatched
                    ? AppColors.success.withOpacity(0.2)
                    : isSelected
                        ? AppColors.primaryGreen.withOpacity(0.2)
                        : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: card.isMatched
                      ? AppColors.success
                      : isSelected
                          ? AppColors.primaryGreen
                          : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (card.isMatched)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20.sp,
                    ),
                  if (card.isMatched) const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      card.text,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: context.adaptive,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
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
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Final Score: $_score',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              onTap: () {
                Navigator.pop(context);
              },
              text: 'Play Again',
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


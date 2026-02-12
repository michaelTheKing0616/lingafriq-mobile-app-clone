import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/gamification/combo_tracker.dart';
import 'package:lingafriq/widgets/gamification/combo_display_widget.dart';
import 'package:lingafriq/services/sound_effects_service.dart';
import 'package:lingafriq/providers/gamification_provider.dart';

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
  late final ComboTracker _comboTracker;

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
    _comboTracker = ComboTracker();
    _initializeGame();
  }
  
  @override
  void dispose() {
    _comboTracker.dispose();
    super.dispose();
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
    final soundEffects = ref.read(soundEffectsProvider);

    if (isMatch) {
      // Play correct sound and track combo
      soundEffects.playCorrect();
      _comboTracker.recordCorrect();
      
      setState(() {
        _selectedLeft!.isMatched = true;
        _selectedRight!.isMatched = true;
        _score += 10;
        _matches++;
        _selectedLeft = null;
        _selectedRight = null;

        if (_matches == _wordPairs.length) {
          _gameComplete = true;
          // Award XP with combo multiplier
          _awardGameXP();
          soundEffects.playCelebration();
        }
      });
    } else {
      // Play incorrect sound and reset combo
      soundEffects.playIncorrect();
      _comboTracker.recordIncorrect();
      
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
  
  Future<void> _awardGameXP() async {
    final multiplier = _comboTracker.currentMultiplier;
    await ref.read(gamificationProvider.notifier).awardXP(
      'game_complete',
      multiplier: multiplier,
      sourceId: 'word_match_${widget.language.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
    _comboTracker.reset();
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
                PanAfricanColors.primary,
                PanAfricanColors.secondary,
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _gameComplete
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
          // Combo display widget
          if (!_gameComplete)
            ComboDisplayWidget(comboTracker: _comboTracker),
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
        Icon(icon, color: PanAfricanColors.primary, size: 24.sp),
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
          child: PanAfricanCard(
            onTap: () => _selectCard(card),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card.isMatched
                    ? PanAfricanColors.success.withOpacity(0.2)
                    : isSelected
                        ? PanAfricanColors.primary.withOpacity(0.2)
                        : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: card.isMatched
                      ? PanAfricanColors.success
                      : isSelected
                          ? PanAfricanColors.primary
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
                      color: PanAfricanColors.success,
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
    final colorScheme = Theme.of(context).colorScheme;

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
                    PanAfricanColors.primary,
                    PanAfricanColors.secondary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration,
                color: colorScheme.onPrimary,
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
                color: PanAfricanColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Final Score: $_score',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: PanAfricanColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            PanAfricanButton(
              onPressed: () {
                _comboTracker.reset();
                _initializeGame();
              },
              label: 'Play Again',
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


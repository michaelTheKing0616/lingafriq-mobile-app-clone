import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/game_ui/index.dart';

/// Speed Round Remix - Adaptive rapid-fire questions
class SpeedRoundGame extends BaseGameScreen {
  const SpeedRoundGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.speedRoundRemix;

  @override
  ConsumerState<SpeedRoundGame> createState() => _SpeedRoundGameState();
}

class _SpeedRoundGameState extends BaseGameScreenState<SpeedRoundGame> {
  PhraseCard? _currentCard;
  int _currentCardIndex = 0;
  final List<PhraseCard> _cards = [];
  final List<String> _options = [];
  String? _selectedAnswer;
  int _score = 0;
  int _streak = 0;
  Timer? _timer;
  int _timeLeft = 60; // 60 seconds
  bool _gameOver = false;

  @override
  int getCardCount() => 20;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isNotEmpty) {
      _loadNextCard();
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _loadNextCard() {
    if (_currentCardIndex >= _cards.length) {
      _endGame();
      return;
    }

    setState(() {
      _currentCard = _cards[_currentCardIndex];
      _selectedAnswer = null;
      _generateOptions();
    });
  }

  void _generateOptions() {
    if (_currentCard == null) return;
    _options.clear();
    _options.add(_currentCard!.gloss); // Correct answer
    
    // Add distractors
    final otherCards = _cards.where((c) => c.cardId != _currentCard!.cardId).toList();
    otherCards.shuffle(Random());
    for (var i = 0; i < 3 && i < otherCards.length; i++) {
      _options.add(otherCards[i].gloss);
    }
    _options.shuffle(Random());
  }

  Future<void> _selectAnswer(String answer) async {
    if (_selectedAnswer != null || _gameOver) return;

    final correct = answer == _currentCard!.gloss;
    setState(() {
      _selectedAnswer = answer;
      if (correct) {
        _score++;
        _streak++;
      } else {
        _streak = 0;
      }
    });

    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    await completeTurn(
      cardId: _currentCard!.cardId,
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      confidence: correct ? 1.0 : 0.0,
    );

    // Auto-advance after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_gameOver) {
        _currentCardIndex++;
        _loadNextCard();
      }
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() => _gameOver = true);
    finishGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  List<Widget>? get appBarActions {
    if (_gameOver || _currentCard == null) return null;
    return [
      Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Time remaining: $_timeLeft seconds',
              child: Text(
                '$_timeLeft',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft < 10 ? Colors.red : Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            Semantics(
              label: 'Score: $_score',
              child: Text(
                'Score: $_score',
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget buildGameContent(BuildContext context) {
    try {
      if (_gameOver) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Time\'s up',
                child: Text(
                  'Time\'s Up!',
                  style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 2.h),
              Semantics(label: 'Score: $_score', child: Text(
                'Score: $_score',
                style: TextStyle(fontSize: 24.sp),
              )),
              Semantics(label: 'Best streak: $_streak', child: Text(
                'Best Streak: $_streak',
                style: TextStyle(fontSize: 20.sp),
              )),
            ],
          ),
        );
      }

      if (_currentCard == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          children: [
            if (_streak > 0)
              StreakBadge(streak: _streak),
            SizedBox(height: 12.h),
            GameCard(
              child: Column(
                children: [
                  Text(
                    'What does this mean?',
                    style: TextStyle(fontSize: 18.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _currentCard!.text,
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: ListView.builder(
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final option = _options[index];
                  final isSelected = _selectedAnswer == option;
                  final isCorrect = option == _currentCard!.gloss;
                  final showResult = _selectedAnswer != null;

                  GameCardState cardState = GameCardState.normal;
                  if (showResult) {
                    if (isCorrect) {
                      cardState = GameCardState.correct;
                    } else if (isSelected) {
                      cardState = GameCardState.incorrect;
                    } else {
                      cardState = GameCardState.disabled;
                    }
                  } else if (isSelected) {
                    cardState = GameCardState.selected;
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Semantics(
                      label: 'Answer option: $option',
                      button: true,
                      selected: isSelected,
                      child: GameCard(
                        state: cardState,
                        onTap: () => _selectAnswer(option),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (showResult && isCorrect)
                              const Icon(Icons.check_circle, color: Colors.green, semanticLabel: 'Correct'),
                            if (showResult && isSelected && !isCorrect)
                              const Icon(Icons.cancel, color: Colors.red, semanticLabel: 'Incorrect'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('SpeedRoundGame buildGameContent: $e $st');
      rethrow;
    }
  }
}


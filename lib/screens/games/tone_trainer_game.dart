import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tone Trainer - Tonal language pitch visualization
class ToneTrainerGame extends BaseGameScreen {
  const ToneTrainerGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.toneTrainer;

  @override
  ConsumerState<ToneTrainerGame> createState() => _ToneTrainerGameState();
}

class _ToneTrainerGameState extends BaseGameScreenState<ToneTrainerGame> {
  PhraseCard? _currentCard;
  int _currentCardIndex = 0;
  final List<PhraseCard> _cards = [];
  final List<int> _userTones = []; // 0=low, 1=mid, 2=high
  final List<int> _targetTones = [];
  bool _showResult = false;

  @override
  int getCardCount() => 5;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isNotEmpty) {
      _currentCard = _cards[0];
      _generateTargetTones();
    }
  }

  void _generateTargetTones() {
    if (_currentCard == null) return;
    // Mock tone pattern - in production, extract from IPA or audio analysis
    final word = _currentCard!.text;
    _targetTones.clear();
    for (int i = 0; i < word.length; i++) {
      // Simple heuristic: vowels with diacritics indicate tones
      final char = word[i];
      if (char.contains(RegExp(r'[áéíóú]'))) {
        _targetTones.add(2); // High
      } else if (char.contains(RegExp(r'[àèìòù]'))) {
        _targetTones.add(0); // Low
      } else {
        _targetTones.add(1); // Mid
      }
    }
    _userTones.clear();
    _userTones.addAll(List.filled(_targetTones.length, 1)); // Default to mid
  }

  void _setTone(int index, int tone) {
    setState(() {
      _userTones[index] = tone;
      _showResult = false;
    });
  }

  void _checkAnswer() {
    int correct = 0;
    for (int i = 0; i < _targetTones.length; i++) {
      if (_userTones[i] == _targetTones[i]) correct++;
    }

    final accuracy = correct / _targetTones.length;
    final result = accuracy >= 0.8
        ? GameResult.correct
        : accuracy >= 0.5
            ? GameResult.partial
            : GameResult.incorrect;

    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    completeTurn(
      cardId: _currentCard!.cardId,
      result: result,
      durationMs: duration,
      confidence: accuracy,
      feedback: {
        'correct_tones': correct,
        'total_tones': _targetTones.length,
        'accuracy': accuracy,
      },
    );

    setState(() => _showResult = true);
  }

  void _nextCard() {
    if (_currentCardIndex < _cards.length - 1) {
      setState(() {
        _currentCardIndex++;
        _currentCard = _cards[_currentCardIndex];
        _generateTargetTones();
        _showResult = false;
      });
    } else {
      finishGame();
    }
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (_currentCard == null) {
      return const Center(child: Text('No cards available'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.getGameType().displayName} (${_currentCardIndex + 1}/${_cards.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentCardIndex + 1) / _cards.length,
            ),
            SizedBox(height: 4.h),
            // Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Text(
                      _currentCard!.text,
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currentCard!.gloss,
                      style: TextStyle(
                        fontSize: 18.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            // Tone visualization
            Text(
              'Match the tone pattern:',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            // Target tone pattern
            if (_showResult)
              Column(
                children: [
                  Text('Target:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 1.h),
                  _TonePattern(
                    tones: _targetTones,
                    isTarget: true,
                  ),
                ],
              ),
            SizedBox(height: 2.h),
            // User tone selection
            _TonePattern(
              tones: _userTones,
              isTarget: false,
              onToneChanged: _setTone,
            ),
            SizedBox(height: 4.h),
            if (!_showResult)
              FilledButton(
                onPressed: _checkAnswer,
                child: const Text('Check Answer'),
              )
            else
              Column(
                children: [
                  Text(
                    _userTones.asMap().entries.every((entry) => entry.value == _targetTones[entry.key])
                        ? 'Perfect! 🎉'
                        : 'Good try!',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: _userTones.asMap().entries.every((entry) => entry.value == _targetTones[entry.key])
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  FilledButton(
                    onPressed: _nextCard,
                    child: Text(_currentCardIndex < _cards.length - 1
                        ? 'Next Card'
                        : 'Finish'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TonePattern extends StatelessWidget {
  final List<int> tones;
  final bool isTarget;
  final Function(int, int)? onToneChanged;

  const _TonePattern({
    required this.tones,
    this.isTarget = false,
    this.onToneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2.w,
      children: tones.asMap().entries.map((entry) {
        final index = entry.key;
        final tone = entry.value;
        return GestureDetector(
          onTap: isTarget ? null : () => onToneChanged?.call(index, (tone + 1) % 3),
          child: Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: _getToneColor(tone),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isTarget ? Colors.transparent : Colors.grey,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getToneLabel(tone),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getToneColor(int tone) {
    switch (tone) {
      case 0:
        return Colors.blue; // Low
      case 1:
        return Colors.green; // Mid
      case 2:
        return Colors.red; // High
      default:
        return Colors.grey;
    }
  }

  String _getToneLabel(int tone) {
    switch (tone) {
      case 0:
        return 'L';
      case 1:
        return 'M';
      case 2:
        return 'H';
      default:
        return '?';
    }
  }
}


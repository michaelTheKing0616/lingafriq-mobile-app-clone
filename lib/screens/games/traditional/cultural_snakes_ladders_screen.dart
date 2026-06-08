// Cultural Snakes & Ladders — a language-learning twist on the classic. The
// 10x10 board has 100 squares numbered 1..100. Ladders are anchored on
// "proverb squares" that surface a real African proverb; if the player can
// answer a proverb-meaning MCQ correctly, the ladder lifts them up. Snakes
// are anchored on "mistake squares" that confront the player with a common
// learner mistake; tapping the correct fix neutralises the snake (otherwise
// the snake bites and the token slides down).
//
// 2-player: you vs. an AI (the AI just rolls + moves; no MCQ gates).

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:lingafriq/models/game/game_content_models.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/screens/games/base_game_screen.dart';
import 'package:lingafriq/screens/games/game_scenario_loader.dart';
import 'package:lingafriq/services/audio/african_tts_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class CulturalSnakesLaddersGame extends BaseGameScreen {
  const CulturalSnakesLaddersGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.snakesAndLaddersCultural;

  @override
  ConsumerState<CulturalSnakesLaddersGame> createState() =>
      _CulturalSnakesLaddersGameState();
}

class _CulturalSnakesLaddersGameState
    extends BaseGameScreenState<CulturalSnakesLaddersGame> {
  // Fixed ladder/snake topology — culturally meaningful: 1->38 is the "elder's
  // wisdom" ladder, 36->6 is the "haste" snake, etc.
  static const Map<int, int> _ladders = {
    1: 38,
    4: 14,
    9: 31,
    21: 42,
    28: 84,
    51: 67,
    71: 91,
    80: 100,
  };
  static const Map<int, int> _snakes = {
    98: 78,
    95: 75,
    93: 73,
    87: 24,
    62: 19,
    56: 53,
    49: 11,
    36: 6,
  };

  int _player = 1;
  int _ai = 1;
  int _turn = 0; // 0 = user, 1 = ai
  int? _lastRoll;
  bool _busy = false;
  String? _status;
  List<GameProverb> _proverbs = const [];
  List<GameWord> _vocab = const [];
  int _correctChecks = 0;
  int _missedChecks = 0;
  final Random _rng = Random();

  @override
  bool get requiresPhraseCards => false;

  @override
  String? get shellScoreLabel => 'You $_player · AI $_ai';

  @override
  Future<void> onGameInitialized() async {
    final p = await loadBundledProverbsAsync(
      ref,
      language: widget.language,
      max: 24,
    );
    final w = await loadBundledGameWordsAsync(
      ref,
      language: widget.language,
      gameTag: 'snakes_ladders',
      max: 32,
    );
    setState(() {
      _proverbs = p;
      _vocab = w.isEmpty
          ? List<GameWord>.empty(growable: true)
          : List<GameWord>.from(w);
    });
  }

  Future<void> _userRoll() async {
    if (_busy || _turn != 0) return;
    final roll = _rng.nextInt(6) + 1;
    setState(() {
      _lastRoll = roll;
      _status = 'You rolled $roll';
    });
    HapticFeedback.lightImpact();
    final target = (_player + roll).clamp(1, 100);
    if (target > 100) {
      setState(() => _status = 'Roll too high — try again next turn.');
      _turn = 1;
      await _aiTurn();
      return;
    }
    // Ladder check
    if (_ladders.containsKey(target)) {
      final ok = await _askLadderChallenge(target);
      if (ok) {
        setState(() {
          _player = _ladders[target]!;
          _status = 'Wisdom ladder! Climbed to ${_player}.';
          _correctChecks++;
        });
        await completeTurn(
          cardId: 'snakes_ladder_$target',
          result: GameResult.correct,
          durationMs: _elapsed(),
          feedback: {'game': 'snakes_ladders', 'event': 'ladder_climbed'},
        );
      } else {
        setState(() {
          _player = target;
          _status = 'Ladder slipped — you stop at $_player.';
          _missedChecks++;
        });
        await completeTurn(
          cardId: 'snakes_ladder_$target',
          result: GameResult.incorrect,
          durationMs: _elapsed(),
          feedback: {'game': 'snakes_ladders', 'event': 'ladder_missed'},
        );
      }
    } else if (_snakes.containsKey(target)) {
      final ok = await _askSnakeChallenge(target);
      if (ok) {
        setState(() {
          _player = target;
          _status = 'Snake dodged — you stay at $_player.';
          _correctChecks++;
        });
        await completeTurn(
          cardId: 'snakes_snake_$target',
          result: GameResult.correct,
          durationMs: _elapsed(),
          feedback: {'game': 'snakes_ladders', 'event': 'snake_dodged'},
        );
      } else {
        setState(() {
          _player = _snakes[target]!;
          _status = 'Snake bite! Slid down to $_player.';
          _missedChecks++;
        });
        await completeTurn(
          cardId: 'snakes_snake_$target',
          result: GameResult.incorrect,
          durationMs: _elapsed(),
          feedback: {'game': 'snakes_ladders', 'event': 'snake_bit'},
        );
      }
    } else {
      setState(() {
        _player = target;
        _status = 'Moved to $_player.';
      });
    }
    if (_player >= 100) {
      _player = 100;
      await _finish(win: true);
      return;
    }
    _turn = 1;
    await _aiTurn();
  }

  Future<void> _aiTurn() async {
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final roll = _rng.nextInt(6) + 1;
    setState(() => _status = 'AI rolled $roll');
    var target = _ai + roll;
    if (target > 100) {
      // AI must roll exactly to land on 100.
      setState(() => _status = 'AI rolled too high — stays at $_ai.');
    } else {
      if (_ladders.containsKey(target)) {
        target = _ladders[target]!;
        setState(() => _status = 'AI climbed a ladder to $target.');
      } else if (_snakes.containsKey(target)) {
        target = _snakes[target]!;
        setState(() => _status = 'AI hit a snake — slid to $target.');
      }
      _ai = target;
    }
    if (_ai >= 100) {
      _ai = 100;
      await _finish(win: false);
      return;
    }
    _turn = 0;
    setState(() => _lastRoll = null);
  }

  Future<bool> _askLadderChallenge(int square) async {
    if (_proverbs.length < 4) return true;
    final target = _proverbs[Random().nextInt(_proverbs.length)];
    unawaited(AfricanTtsService().speak(
      language: widget.language,
      text: target.original,
    ));
    final pool = List<GameProverb>.from(_proverbs)
      ..removeWhere((p) => p.translation == target.translation)
      ..shuffle();
    final distractors = pool.take(3).toList();
    final options = [target, ...distractors]..shuffle();
    return await _confirm(
      title: 'Wisdom ladder',
      prompt:
          'Pick the meaning of the proverb "${target.original}" to climb the ladder.',
      options: options.map((o) => o.translation).toList(),
      correctIndex: options.indexOf(target),
    );
  }

  Future<bool> _askSnakeChallenge(int square) async {
    if (_vocab.length < 4) return true;
    final target = _vocab[Random().nextInt(_vocab.length)];
    unawaited(AfricanTtsService().speak(
      language: widget.language,
      text: target.word,
    ));
    final pool = List<GameWord>.from(_vocab)
      ..removeWhere((w) => w.englishMeaning == target.englishMeaning)
      ..shuffle();
    final distractors = pool.take(3).toList();
    final options = [target, ...distractors]..shuffle();
    return await _confirm(
      title: 'Mistake correction',
      prompt:
          'Pick the correct meaning of "${target.word}" to dodge the snake.',
      options: options.map((o) => o.englishMeaning).toList(),
      correctIndex: options.indexOf(target),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String prompt,
    required List<String> options,
    required int correctIndex,
  }) async {
    setState(() => _busy = true);
    final res = await showModalBottomSheet<int>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 28).copyWith(
          bottom: 28 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: PanAfricanTypography.labelLarge(ctx)),
            const SizedBox(height: 4),
            Text(prompt, style: PanAfricanTypography.bodyMedium(ctx)),
            const SizedBox(height: 14),
            for (var i = 0; i < options.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(i),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(options[i]),
                ),
              ),
          ],
        ),
      ),
    );
    setState(() => _busy = false);
    return res == correctIndex;
  }

  int _elapsed() =>
      DateTime.now().difference(startTime ?? DateTime.now()).inMilliseconds;

  Future<void> _finish({required bool win}) async {
    await completeTurn(
      cardId: 'snakes_ladders_outcome',
      result: win ? GameResult.correct : GameResult.incorrect,
      durationMs: _elapsed(),
      feedback: {
        'game': 'snakes_ladders',
        'event': 'match_complete',
        'correct': _correctChecks,
        'missed': _missedChecks,
      },
    );
    await finishGame();
  }

  @override
  Widget buildGameContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _turn == 0
                        ? 'Your turn — roll the die.'
                        : 'AI is thinking…',
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      _turn == 0 && !_busy ? _userRoll : null,
                  icon: const Icon(Icons.casino_outlined),
                  label: Text(_lastRoll == null ? 'Roll' : 'Rolled $_lastRoll'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_status != null)
              Text(_status!,
                  style: PanAfricanTypography.labelMedium(context)),
            const SizedBox(height: 10),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: _BoardGrid(
                  playerSquare: _player,
                  aiSquare: _ai,
                  ladders: _ladders,
                  snakes: _snakes,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardGrid extends StatelessWidget {
  final int playerSquare;
  final int aiSquare;
  final Map<int, int> ladders;
  final Map<int, int> snakes;
  const _BoardGrid({
    required this.playerSquare,
    required this.aiSquare,
    required this.ladders,
    required this.snakes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PanAfricanColors.kenteGold.withOpacity(0.08),
        border: Border.all(color: PanAfricanColors.kenteGold, width: 1.0),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(6),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 100,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (ctx, index) {
          // Snake-and-ladder boards traditionally count from the bottom-left
          // boustrophedon. We replicate that with index math.
          final row = index ~/ 10;
          final col = index % 10;
          final boardRow = 9 - row;
          final boardSquare = boardRow.isEven
              ? boardRow * 10 + col + 1
              : boardRow * 10 + (9 - col) + 1;
          final isPlayer = playerSquare == boardSquare;
          final isAi = aiSquare == boardSquare;
          final isLadder = ladders.containsKey(boardSquare);
          final isSnake = snakes.containsKey(boardSquare);
          Color bg = Colors.white.withOpacity(0.85);
          if (isLadder) bg = Colors.green.withOpacity(0.18);
          if (isSnake) bg = PanAfricanColors.kenteRed.withOpacity(0.18);
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isLadder
                    ? Colors.green
                    : isSnake
                        ? PanAfricanColors.kenteRed
                        : PanAfricanColors.kenteGold.withOpacity(0.6),
                width: isLadder || isSnake ? 1.4 : 0.6,
              ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$boardSquare',
                  style: PanAfricanTypography.labelSmall(ctx),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPlayer)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (isAi)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: PanAfricanColors.kenteRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

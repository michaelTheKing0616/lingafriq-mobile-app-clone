// Suwe — West-African hopscotch language game.
//
// Traditional Suwe (Yoruba) and its cousins (Igbo Ojugbe, Hausa Langa) use a
// chalk grid of nine squares plus a small stone. The player tosses the stone
// onto a target square, hops the grid avoiding that square, and brings the
// stone back. We adapt this for language learning:
//
//   - Each square shows a target-language word.
//   - The user "tosses" by dragging the stone onto a square (or tapping the
//     square as a quick-toss). The stone lands on square N for round N (1..9).
//   - The user then hops through every square except the stone's square. At
//     each hop they must pick the correct English meaning of the square's
//     word from a 4-option MCQ. A wrong answer = "lose balance"; the round
//     restarts with a heart penalty.
//   - When all hops complete, the user taps the stone's square to "pick up"
//     and advances to the next round.
//   - Winning all 9 rounds finishes the game.
//
// We integrate `AfricanTtsService` for word pronunciation and gate progress
// behind `BaseGameScreen` so the standard XP / hearts / streak loop applies.

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

class SuweHopscotchGame extends BaseGameScreen {
  const SuweHopscotchGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.suweHopscotch;

  @override
  ConsumerState<SuweHopscotchGame> createState() => _SuweHopscotchGameState();
}

class _SuweHopscotchGameState extends BaseGameScreenState<SuweHopscotchGame> {
  static const int _squareCount = 9;

  List<GameWord> _vocab = const [];
  // square index (1..9) -> assigned vocab word
  final Map<int, GameWord> _wordPerSquare = {};
  int _round = 1;                    // current round (1..9)
  int? _stoneSquare;                 // null = stone not yet tossed
  Set<int> _hopped = {};             // squares already hopped this round
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  bool _busy = false;

  @override
  bool get requiresPhraseCards => false;

  @override
  String? get shellProgressLabel => 'Round $_round/9';

  @override
  Future<void> onGameInitialized() async {
    final words = await loadBundledGameWordsAsync(
      ref,
      language: widget.language,
      gameTag: 'hopscotch',
      max: 36,
    );
    final pool = words.isNotEmpty
        ? words
        : await loadBundledGameWordsAsync(
            ref,
            language: widget.language,
            gameTag: 'vocabulary',
            max: 36,
          );
    setState(() {
      _vocab = pool;
      _assignWordsToSquares();
    });
  }

  void _assignWordsToSquares() {
    _wordPerSquare.clear();
    if (_vocab.isEmpty) return;
    final pool = List<GameWord>.from(_vocab)..shuffle(Random());
    for (var i = 1; i <= _squareCount; i++) {
      _wordPerSquare[i] = pool[(i - 1) % pool.length];
    }
  }

  void _resetRound({bool advance = false}) {
    setState(() {
      if (advance) _round = (_round < _squareCount) ? _round + 1 : _round;
      _stoneSquare = null;
      _hopped = {};
    });
  }

  Future<void> _onTossStone(int square) async {
    if (_busy) return;
    if (_stoneSquare != null) return;
    if (square != _round) {
      HapticFeedback.selectionClick();
      _flashSnack('Aim for square $_round in this round.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _stoneSquare = square);
  }

  Future<void> _onHopOrPickup(int square) async {
    if (_busy) return;
    if (_stoneSquare == null) {
      _flashSnack('Toss the stone first onto square $_round.');
      return;
    }
    if (square == _stoneSquare && _hopped.length == _squareCount - 1) {
      // Pick up the stone — round complete.
      HapticFeedback.mediumImpact();
      _flashSnack('Round $_round cleared!');
      if (_round == _squareCount) {
        await _finishMatch(win: true);
      } else {
        _resetRound(advance: true);
      }
      return;
    }
    if (square == _stoneSquare) {
      _flashSnack('Cannot hop on the stone — clear other squares first.');
      return;
    }
    if (_hopped.contains(square)) {
      _flashSnack('Already hopped on that square. Pick another.');
      return;
    }
    final word = _wordPerSquare[square];
    if (word == null) return;
    setState(() => _busy = true);
    final correct = await _challenge(word);
    if (!mounted) return;
    setState(() => _busy = false);
    final cardId = 'suwe_${word.id}_round$_round';
    final durationMs = DateTime.now()
        .difference(startTime ?? DateTime.now())
        .inMilliseconds;
    if (correct) {
      _correctAnswers++;
      setState(() => _hopped = {..._hopped, square});
      await completeTurn(
        cardId: cardId,
        result: GameResult.correct,
        durationMs: durationMs,
        feedback: {'game': 'suwe', 'round': _round, 'square': square},
      );
    } else {
      _incorrectAnswers++;
      await completeTurn(
        cardId: cardId,
        result: GameResult.incorrect,
        durationMs: durationMs,
        feedback: {'game': 'suwe', 'round': _round, 'square': square},
      );
      _flashSnack('Lost balance — restarting round $_round.');
      _resetRound(advance: false);
    }
  }

  /// Renders the multiple-choice gloss challenge. The user must tap the
  /// English meaning of the target word to confirm the hop.
  Future<bool> _challenge(GameWord word) async {
    unawaited(AfricanTtsService().speak(
      language: widget.language,
      text: word.word,
    ));
    if (_vocab.length < 4) {
      // Without enough distractors, accept any tap as confirmation so the user
      // can still progress (real content will arrive once Track 5 publishes).
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return true;
    }
    final distractors = (List<GameWord>.from(_vocab)..shuffle(Random()))
        .where((w) => w.englishMeaning != word.englishMeaning)
        .take(3)
        .toList();
    final options = [word, ...distractors]..shuffle(Random());
    final result = await showModalBottomSheet<bool>(
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
            Text('Hop challenge',
                style: PanAfricanTypography.labelLarge(ctx)),
            const SizedBox(height: 4),
            Text(
              'Pick the meaning of "${word.word}" to stay balanced.',
              style: PanAfricanTypography.bodyMedium(ctx),
            ),
            const SizedBox(height: 14),
            ...options.map(
              (opt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(
                    opt.englishMeaning == word.englishMeaning,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(opt.englishMeaning),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _finishMatch({required bool win}) async {
    await completeTurn(
      cardId: 'suwe_match_outcome',
      result: win ? GameResult.correct : GameResult.incorrect,
      durationMs: DateTime.now()
          .difference(startTime ?? DateTime.now())
          .inMilliseconds,
      feedback: {
        'game': 'suwe',
        'event': 'match_complete',
        'correct': _correctAnswers,
        'incorrect': _incorrectAnswers,
      },
    );
    await finishGame();
  }

  void _flashSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  Widget buildGameContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _IntroBanner(round: _round, stonePlaced: _stoneSquare != null),
            const SizedBox(height: 12),
            Expanded(child: _buildGrid(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    // Standard 9-square hopscotch layout:
    //
    //   row1:   [9]
    //   row2: [7][8]
    //   row3:   [6]
    //   row4: [4][5]
    //   row5:   [3]
    //   row6: [1][2]
    //
    // The grid is read bottom-up so players "climb" while playing. We render
    // top-down which is the visual convention on phones.

    Widget single(int n) => _SuweTile(
          number: n,
          word: _wordPerSquare[n],
          isStone: _stoneSquare == n,
          hopped: _hopped.contains(n),
          interactive: !_busy,
          onTap: () {
            if (_stoneSquare == null) {
              _onTossStone(n);
            } else {
              _onHopOrPickup(n);
            }
          },
        );

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Center(child: SizedBox(width: 130, child: single(9))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 130, child: single(7)),
          const SizedBox(width: 8),
          SizedBox(width: 130, child: single(8)),
        ]),
        const SizedBox(height: 8),
        Center(child: SizedBox(width: 130, child: single(6))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 130, child: single(4)),
          const SizedBox(width: 8),
          SizedBox(width: 130, child: single(5)),
        ]),
        const SizedBox(height: 8),
        Center(child: SizedBox(width: 130, child: single(3))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 130, child: single(1)),
          const SizedBox(width: 8),
          SizedBox(width: 130, child: single(2)),
        ]),
      ],
    );
  }
}

class _IntroBanner extends StatelessWidget {
  final int round;
  final bool stonePlaced;
  const _IntroBanner({required this.round, required this.stonePlaced});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PanAfricanColors.kenteGold.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PanAfricanColors.kenteGold, width: 1.0),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.gesture_outlined,
              color: PanAfricanColors.kenteGold, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stonePlaced
                  ? 'Tap each square to hop. Avoid square $round (the stone). Pick up the stone to advance.'
                  : 'Round $round — tap square $round to toss the stone.',
              style: PanAfricanTypography.bodyMedium(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuweTile extends StatelessWidget {
  final int number;
  final GameWord? word;
  final bool isStone;
  final bool hopped;
  final bool interactive;
  final VoidCallback onTap;
  const _SuweTile({
    required this.number,
    required this.word,
    required this.isStone,
    required this.hopped,
    required this.interactive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    if (isStone) {
      bg = PanAfricanColors.kenteRed.withOpacity(0.22);
      border = PanAfricanColors.kenteRed;
    } else if (hopped) {
      bg = PanAfricanColors.kenteGold.withOpacity(0.30);
      border = PanAfricanColors.kenteGold;
    } else {
      bg = Colors.white.withOpacity(0.86);
      border = PanAfricanColors.kenteGold;
    }
    return GestureDetector(
      onTap: interactive ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 78,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1.4),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$number', style: PanAfricanTypography.labelLarge(context)),
                if (isStone) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.circle, size: 12),
                ],
                if (hopped) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check, size: 14),
                ],
              ],
            ),
            const SizedBox(height: 4),
            if (word != null)
              Text(
                word!.word,
                style: PanAfricanTypography.labelSmall(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
          ],
        ),
      ),
    );
  }
}

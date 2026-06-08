// Ayo Mancala — language-learning variant.
//
// The board renders 12 small pits with seed counts. Each pit displays a
// vocabulary word drawn from the bundled `game_content.json`. On capture, the
// player must select the correct gloss to confirm the capture (otherwise the
// captured seeds flow to the opponent). When a pit is sown into, the word's
// audio plays via [AfricanTtsService] so the user hears authentic
// African-accented pronunciation during normal play.
//
// AI difficulty scales with [BaseGameScreen.level] so beginners get an
// approachable opponent while advanced learners face a strong adversary.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:lingafriq/games/traditional/ayo_engine.dart';
import 'package:lingafriq/models/game/game_content_models.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/providers/game_content_provider.dart';
import 'package:lingafriq/screens/games/base_game_screen.dart';
import 'package:lingafriq/screens/games/game_scenario_loader.dart';
import 'package:lingafriq/services/audio/african_tts_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class AyoMancalaGame extends BaseGameScreen {
  const AyoMancalaGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.ayoMancala;

  @override
  ConsumerState<AyoMancalaGame> createState() => _AyoMancalaGameState();
}

class _AyoMancalaGameState extends BaseGameScreenState<AyoMancalaGame> {
  AyoBoard _board = AyoBoard.initial();
  late AyoAi _ai;
  bool _animating = false;
  String? _statusMessage;
  List<GameWord> _vocabulary = const [];
  // Per-pit vocab assignment (stable for the duration of the game).
  final List<GameWord?> _pitVocab = List<GameWord?>.filled(14, null);
  int _userCaptures = 0;
  int _aiCaptures = 0;
  int _correctCaptureConfirmations = 0;
  int _missedCaptureConfirmations = 0;

  @override
  bool get requiresPhraseCards => false;

  @override
  String? get shellScoreLabel => '${_board.storeFor(AyoPlayer.south)}–'
      '${_board.storeFor(AyoPlayer.north)}';

  @override
  void initState() {
    super.initState();
    _ai = AyoAi(difficulty: _difficultyFromLevel(widget.level));
  }

  AyoAiDifficulty _difficultyFromLevel(String? level) {
    switch ((level ?? 'A1').toUpperCase()) {
      case 'A1':
      case 'A2':
        return AyoAiDifficulty.easy;
      case 'B1':
        return AyoAiDifficulty.medium;
      case 'B2':
        return AyoAiDifficulty.hard;
      case 'C1':
      case 'C2':
        return AyoAiDifficulty.expert;
      default:
        return AyoAiDifficulty.medium;
    }
  }

  @override
  Future<void> onGameInitialized() async {
    final words = await loadBundledGameWordsAsync(
      ref,
      language: widget.language,
      gameTag: 'mancala',
      max: 24,
    );
    final pool = words.isEmpty
        ? await loadBundledGameWordsAsync(
            ref,
            language: widget.language,
            gameTag: 'vocabulary',
            max: 24,
          )
        : words;
    setState(() {
      _vocabulary = pool;
      _assignVocabularyToPits();
    });
  }

  void _assignVocabularyToPits() {
    if (_vocabulary.isEmpty) return;
    final rng = Random(widget.language.hashCode);
    final pool = List<GameWord>.from(_vocabulary)..shuffle(rng);
    var k = 0;
    for (var pit = 0; pit < 14; pit++) {
      if (pit == 6 || pit == 13) continue; // stores
      _pitVocab[pit] = pool[k % pool.length];
      k++;
    }
  }

  Future<void> _handleUserTap(int pit) async {
    if (_animating) return;
    if (_board.turn != AyoPlayer.south) return;
    if (!_board.legalMoves().contains(pit)) {
      HapticFeedback.lightImpact();
      setState(() => _statusMessage = 'That pit is empty. Choose another.');
      return;
    }
    setState(() {
      _animating = true;
      _statusMessage = null;
    });
    await _applyMove(pit, isUser: true);
    if (mounted && !_board.isGameOver() && _board.turn == AyoPlayer.north) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      while (mounted && !_board.isGameOver() && _board.turn == AyoPlayer.north) {
        final aiMove = _ai.chooseMove(_board);
        if (aiMove < 0) break;
        await _applyMove(aiMove, isUser: false);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    if (mounted) {
      setState(() => _animating = false);
      if (_board.isGameOver()) {
        await _finishMatch();
      }
    }
  }

  Future<void> _applyMove(int pit, {required bool isUser}) async {
    final (next, move) = _board.play(pit);

    // Animate sowing one pit at a time. We mutate a local working board so
    // the UI can render intermediate states without temporarily showing the
    // post-capture board state.
    final workingPits = List<int>.from(_board.pits);
    workingPits[pit] = 0;
    setState(() => _board = AyoBoard.fromState(pits: workingPits, turn: _board.turn));
    for (final landed in move.sowingPath) {
      workingPits[landed] += 1;
      if (isUser) {
        final word = _pitVocab[landed];
        if (word != null) {
          unawaited(
            AfricanTtsService().speak(
              language: widget.language,
              text: word.word,
              speed: 1.0,
            ),
          );
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 110));
      if (!mounted) return;
      setState(() => _board = AyoBoard.fromState(pits: List<int>.from(workingPits), turn: _board.turn));
    }

    _board = next;
    if (move.capturedSeeds > 0) {
      _lastCaptureSize = move.capturedSeeds;
      if (isUser) {
        _userCaptures += move.capturedSeeds;
      } else {
        _aiCaptures += move.capturedSeeds;
      }
      if (isUser && move.capturedFromPit != null) {
        final captured = _pitVocab[move.capturedFromPit!];
        if (captured != null) {
          await _runCaptureChallenge(captured);
        }
      }
    }
    setState(() {});
  }

  /// Pop a quick MCQ challenge: select the correct gloss for the captured
  /// pit's word. Correct answer keeps the captured seeds; wrong answer
  /// forfeits them to the opponent.
  Future<void> _runCaptureChallenge(GameWord captured) async {
    if (_vocabulary.isEmpty || _vocabulary.length < 4) {
      _correctCaptureConfirmations++;
      return;
    }
    final pool = List<GameWord>.from(_vocabulary)
      ..shuffle(Random())
      ..removeWhere((w) => w.englishMeaning == captured.englishMeaning);
    final distractors = pool.take(3).toList();
    final options = [captured, ...distractors]..shuffle(Random());
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 28).copyWith(
          bottom: 28 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capture challenge',
              style: PanAfricanTypography.labelLarge(ctx),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the meaning of "${captured.word}" to keep your capture.',
              style: PanAfricanTypography.bodyMedium(ctx),
            ),
            const SizedBox(height: 14),
            ...options.map(
              (opt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx)
                      .pop(opt.englishMeaning == captured.englishMeaning),
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
    final cardId = 'ayo_capture_${captured.id}';
    final durationMs =
        DateTime.now().difference(startTime ?? DateTime.now()).inMilliseconds;
    if (result == true) {
      _correctCaptureConfirmations++;
      await completeTurn(
        cardId: cardId,
        result: GameResult.correct,
        durationMs: durationMs,
        feedback: {'game': 'ayo', 'event': 'capture_confirmed'},
      );
    } else {
      _missedCaptureConfirmations++;
      _forfeitLastCaptureToOpponent();
      setState(() => _statusMessage =
          'Missed gloss — capture forfeited to the opponent.');
      await completeTurn(
        cardId: cardId,
        result: GameResult.incorrect,
        durationMs: durationMs,
        feedback: {'game': 'ayo', 'event': 'capture_forfeited'},
      );
    }
  }

  /// We track the size of the most recent capture in [_lastCaptureSize] so
  /// the forfeit math stays exact (rather than guessing from totals).
  int _lastCaptureSize = 0;
  void _forfeitLastCaptureToOpponent() {
    if (_lastCaptureSize <= 0) return;
    final pits = List<int>.from(_board.pits);
    final amount = _lastCaptureSize.clamp(0, pits[6]);
    pits[6] -= amount;
    pits[13] += amount;
    _board = AyoBoard.fromState(pits: pits, turn: _board.turn);
    _userCaptures = (_userCaptures - amount).clamp(0, 48);
    _aiCaptures += amount;
    _lastCaptureSize = 0;
  }

  Future<void> _finishMatch() async {
    // Record a final synthetic turn reflecting overall match outcome so the
    // session accuracy + telemetry properly capture match wins. Then defer
    // to the shared `finishGame()` completion flow (handles XP, sound, dialog).
    final winner = _board.winner();
    final youWin = winner == AyoPlayer.south;
    await completeTurn(
      cardId: 'ayo_match_outcome',
      result: youWin ? GameResult.correct : GameResult.incorrect,
      durationMs: DateTime.now()
          .difference(startTime ?? DateTime.now())
          .inMilliseconds,
      feedback: {
        'game': 'ayo',
        'event': 'match_complete',
        'south_store': _board.storeFor(AyoPlayer.south),
        'north_store': _board.storeFor(AyoPlayer.north),
        'captures_correct': _correctCaptureConfirmations,
        'captures_missed': _missedCaptureConfirmations,
      },
    );
    await finishGame();
  }

  @override
  Widget buildGameContent(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _statusMessage!,
                style: PanAfricanTypography.bodyMedium(
                  context,
                  color: PanAfricanColors.kenteRed,
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AyoBoardView(
                board: _board,
                vocab: _pitVocab,
                interactivePlayer: _animating || _board.isGameOver()
                    ? null
                    : AyoPlayer.south,
                onPitTap: _handleUserTap,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScorePanel(label: 'You', value: _board.storeFor(AyoPlayer.south)),
                _ScorePanel(label: 'AI', value: _board.storeFor(AyoPlayer.north)),
                _ScorePanel(label: 'Captures', value: _userCaptures),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  final String label;
  final int value;
  const _ScorePanel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: PanAfricanTypography.labelMedium(context)),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: PanAfricanTypography.titleLarge(context),
        ),
      ],
    );
  }
}

class AyoBoardView extends StatelessWidget {
  final AyoBoard board;
  final List<GameWord?> vocab;
  final AyoPlayer? interactivePlayer;
  final ValueChanged<int> onPitTap;

  const AyoBoardView({
    super.key,
    required this.board,
    required this.vocab,
    required this.interactivePlayer,
    required this.onPitTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final pitSize = (c.maxWidth - 32) / 6;
        return Container(
          decoration: BoxDecoration(
            color: PanAfricanColors.kenteGold.withOpacity(0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: PanAfricanColors.kenteGold,
              width: 2.0,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // North row (player 1's pits — visually reversed since seeds flow
              // counter-clockwise).
              Row(
                children: [
                  for (var i = 12; i >= 7; i--)
                    Expanded(
                      child: _PitTile(
                        seeds: board.pits[i],
                        word: vocab[i],
                        interactive: false,
                        pitSize: pitSize,
                        onTap: () => onPitTap(i),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Stores
              Row(
                children: [
                  _StoreTile(label: 'AI store', seeds: board.pits[13]),
                  const Spacer(),
                  _StoreTile(label: 'Your store', seeds: board.pits[6]),
                ],
              ),
              const SizedBox(height: 14),
              // South row (player 0's pits).
              Row(
                children: [
                  for (var i = 0; i <= 5; i++)
                    Expanded(
                      child: _PitTile(
                        seeds: board.pits[i],
                        word: vocab[i],
                        interactive: interactivePlayer == AyoPlayer.south &&
                            board.pits[i] > 0,
                        pitSize: pitSize,
                        onTap: () => onPitTap(i),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PitTile extends StatelessWidget {
  final int seeds;
  final GameWord? word;
  final bool interactive;
  final double pitSize;
  final VoidCallback onTap;
  const _PitTile({
    required this.seeds,
    required this.word,
    required this.interactive,
    required this.pitSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: interactive ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: pitSize.clamp(56, 92).toDouble(),
          decoration: BoxDecoration(
            color: interactive
                ? PanAfricanColors.kenteRed.withOpacity(0.18)
                : Colors.white.withOpacity(0.78),
            border: Border.all(
              color: interactive
                  ? PanAfricanColors.kenteRed
                  : PanAfricanColors.kenteGold,
              width: interactive ? 1.6 : 1.0,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$seeds',
                style: PanAfricanTypography.titleMedium(context),
              ),
              if (word != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    word!.word,
                    style: PanAfricanTypography.labelSmall(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  final String label;
  final int seeds;
  const _StoreTile({required this.label, required this.seeds});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 70,
      decoration: BoxDecoration(
        color: PanAfricanColors.primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PanAfricanColors.primary,
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$seeds', style: PanAfricanTypography.titleLarge(context)),
          Text(label, style: PanAfricanTypography.labelSmall(context)),
        ],
      ),
    );
  }
}


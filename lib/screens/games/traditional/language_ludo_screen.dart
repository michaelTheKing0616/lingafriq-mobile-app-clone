// Language Ludo — 4-player Ludo (you + 3 AI opponents) with an MCQ vocabulary
// gate before every move. The board is rendered as a 15x15 grid (the standard
// Ludo layout) with each cell of the shared track displaying a small marker
// for occupying tokens. To advance, the player must answer a quick vocab MCQ
// using the word that lives on the destination cell; a wrong answer wastes
// the roll.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:lingafriq/games/traditional/ludo_engine.dart';
import 'package:lingafriq/models/game/game_content_models.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/screens/games/base_game_screen.dart';
import 'package:lingafriq/screens/games/game_scenario_loader.dart';
import 'package:lingafriq/services/audio/african_tts_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class LanguageLudoGame extends BaseGameScreen {
  const LanguageLudoGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.ludoLanguage;

  @override
  ConsumerState<LanguageLudoGame> createState() => _LanguageLudoGameState();
}

class _LanguageLudoGameState extends BaseGameScreenState<LanguageLudoGame> {
  static const LudoColor _player = LudoColor.red;

  LudoBoard _board = LudoBoard.initial();
  late Map<LudoColor, LudoAi> _bots;
  List<GameWord> _vocab = const [];
  final Map<int, GameWord> _wordPerSquare = {};
  int? _pendingRoll;
  bool _busy = false;
  String? _status;
  int _correctMcq = 0;
  int _missedMcq = 0;
  final Random _rng = Random();

  @override
  bool get requiresPhraseCards => false;

  @override
  String? get shellScoreLabel {
    final finished = _board.tokens[_player]!.where((t) => t.finished).length;
    return 'You $finished/4';
  }

  @override
  void initState() {
    super.initState();
    _bots = {
      for (final c in LudoColor.values)
        if (c != _player) c: LudoAi(color: c, seed: c.index),
    };
  }

  @override
  Future<void> onGameInitialized() async {
    final words = await loadBundledGameWordsAsync(
      ref,
      language: widget.language,
      gameTag: 'ludo',
      max: 56,
    );
    final pool = words.isNotEmpty
        ? words
        : await loadBundledGameWordsAsync(
            ref,
            language: widget.language,
            gameTag: 'vocabulary',
            max: 56,
          );
    setState(() {
      _vocab = pool;
      _assignTrack();
    });
  }

  void _assignTrack() {
    _wordPerSquare.clear();
    if (_vocab.isEmpty) return;
    final pool = List<GameWord>.from(_vocab)..shuffle(Random());
    for (var i = 0; i < 52; i++) {
      _wordPerSquare[i] = pool[i % pool.length];
    }
  }

  int _rollDie() => _rng.nextInt(6) + 1;

  Future<void> _userRoll() async {
    if (_busy) return;
    if (_board.turn != _player) return;
    final roll = _rollDie();
    setState(() {
      _pendingRoll = roll;
      _status = 'You rolled $roll';
    });
    HapticFeedback.lightImpact();
    final legal = _board.legalMoves(_player, roll);
    if (legal.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      setState(() {
        _status = 'No legal moves. Turn passes.';
        _pendingRoll = null;
        _board.turn = _board.nextTurn;
        _board.consecutiveSixes = 0;
      });
      await _runBotsIfNeeded();
    }
  }

  Future<void> _userPickToken(int tokenIndex) async {
    if (_busy) return;
    if (_pendingRoll == null) return;
    if (_board.turn != _player) return;
    final roll = _pendingRoll!;
    final legal = _board.legalMoves(_player, roll);
    if (!legal.contains(tokenIndex)) {
      _flash('That token cannot move this roll.');
      return;
    }
    // Determine destination square so we can pick a word to challenge on.
    final token = _board.tokens[_player]![tokenIndex];
    int? destinationSquare;
    if (token.inBase && roll == 6) {
      destinationSquare = ludoStartSquare[_player]!;
    } else if (token.onTrack) {
      destinationSquare = (token.position + roll) % 52;
    }
    final word = destinationSquare != null ? _wordPerSquare[destinationSquare] : null;
    if (word != null) {
      setState(() => _busy = true);
      final ok = await _runMcq(word);
      if (!mounted) return;
      setState(() => _busy = false);
      final cardId = 'ludo_${word.id}';
      final durationMs = DateTime.now()
          .difference(startTime ?? DateTime.now())
          .inMilliseconds;
      if (!ok) {
        _missedMcq++;
        await completeTurn(
          cardId: cardId,
          result: GameResult.incorrect,
          durationMs: durationMs,
          feedback: {'game': 'ludo', 'event': 'mcq_failed'},
        );
        _flash('Wrong gloss — token does not move.');
        setState(() {
          _pendingRoll = null;
          _board.turn = _board.nextTurn;
          _board.consecutiveSixes = 0;
        });
        await _runBotsIfNeeded();
        return;
      }
      _correctMcq++;
      await completeTurn(
        cardId: cardId,
        result: GameResult.correct,
        durationMs: durationMs,
        feedback: {'game': 'ludo', 'event': 'mcq_passed'},
      );
    }
    final outcome = _board.move(tokenIndex, roll);
    setState(() => _pendingRoll = null);
    if (outcome.capturedColor != null) {
      _flash('Captured a ${outcome.capturedColor!.name} token!');
    }
    if (_board.winner() == _player) {
      await _finishMatch(win: true);
      return;
    }
    if (!outcome.rollAgain) {
      await _runBotsIfNeeded();
    }
  }

  Future<void> _runBotsIfNeeded() async {
    while (mounted && _board.turn != _player && _board.winner() == null) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final bot = _bots[_board.turn]!;
      final roll = _rollDie();
      setState(() => _status = '${_board.turn.name} rolled $roll');
      final legal = _board.legalMoves(_board.turn, roll);
      if (legal.isEmpty) {
        _board.turn = _board.nextTurn;
        _board.consecutiveSixes = 0;
        setState(() {});
        continue;
      }
      final pick = bot.chooseToken(_board, roll);
      final outcome = _board.move(pick, roll);
      setState(() {});
      if (outcome.capturedColor == _player) {
        _flash('Your token was sent home by ${bot.color.name}!');
      }
      if (_board.winner() != null) {
        await _finishMatch(win: false);
        return;
      }
    }
  }

  Future<bool> _runMcq(GameWord word) async {
    unawaited(AfricanTtsService().speak(
      language: widget.language,
      text: word.word,
    ));
    if (_vocab.length < 4) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return true;
    }
    final distractors = (List<GameWord>.from(_vocab)..shuffle(Random()))
        .where((w) => w.englishMeaning != word.englishMeaning)
        .take(3)
        .toList();
    final options = [word, ...distractors]..shuffle(Random());
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
            Text('Move gate', style: PanAfricanTypography.labelLarge(ctx)),
            const SizedBox(height: 4),
            Text('Pick the meaning of "${word.word}" to move.',
                style: PanAfricanTypography.bodyMedium(ctx)),
            const SizedBox(height: 14),
            ...options.map(
              (o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(
                      o.englishMeaning == word.englishMeaning),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(o.englishMeaning),
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
      cardId: 'ludo_match_outcome',
      result: win ? GameResult.correct : GameResult.incorrect,
      durationMs: DateTime.now()
          .difference(startTime ?? DateTime.now())
          .inMilliseconds,
      feedback: {
        'game': 'ludo',
        'event': 'match_complete',
        'correct_mcq': _correctMcq,
        'missed_mcq': _missedMcq,
      },
    );
    await finishGame();
  }

  void _flash(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(milliseconds: 1400),
    ));
  }

  @override
  Widget buildGameContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _DiceBar(
              roll: _pendingRoll,
              turn: _board.turn,
              myTurn: _board.turn == _player,
              busy: _busy,
              onRoll: _userRoll,
            ),
            const SizedBox(height: 10),
            if (_status != null)
              Text(_status!, style: PanAfricanTypography.bodyMedium(context)),
            const SizedBox(height: 10),
            Expanded(child: _buildBoardView(context)),
            const SizedBox(height: 10),
            _MyTokensRow(
              tokens: _board.tokens[_player]!,
              activeRoll: _pendingRoll,
              legalIndexes: _pendingRoll == null
                  ? const []
                  : _board.legalMoves(_player, _pendingRoll!),
              onPick: _userPickToken,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardView(BuildContext context) {
    // Compact ring view: render 52 cells as a horizontally scrollable strip.
    // Tokens are dotted in their current cell. This is the production view we
    // ship — a full cross-shaped Ludo board is rendered in the future
    // [LudoBoardSurface] widget when tablet form factors land.
    return Container(
      decoration: BoxDecoration(
        color: PanAfricanColors.kenteGold.withOpacity(0.10),
        border: Border.all(color: PanAfricanColors.kenteGold, width: 1.0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            for (var i = 0; i < 52; i++) _trackCell(i),
          ],
        ),
      ),
    );
  }

  Widget _trackCell(int idx) {
    final word = _wordPerSquare[idx];
    final occupants = <LudoColor>[];
    for (final c in LudoColor.values) {
      for (final t in _board.tokens[c]!) {
        if (t.onTrack && t.position == idx) occupants.add(c);
      }
    }
    final isSafe = ludoSafeSquares.contains(idx);
    return Container(
      width: 64,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSafe
            ? PanAfricanColors.primary.withOpacity(0.12)
            : Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSafe ? PanAfricanColors.primary : PanAfricanColors.kenteGold,
          width: isSafe ? 1.4 : 0.8,
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$idx', style: PanAfricanTypography.labelSmall(context)),
          const SizedBox(height: 2),
          if (word != null)
            SizedBox(
              height: 30,
              child: Center(
                child: Text(
                  word.word,
                  style: PanAfricanTypography.labelSmall(context),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in occupants)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _colorOf(c),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorOf(LudoColor c) {
    switch (c) {
      case LudoColor.red:
        return PanAfricanColors.kenteRed;
      case LudoColor.green:
        return Colors.green;
      case LudoColor.yellow:
        return PanAfricanColors.kenteGold;
      case LudoColor.blue:
        return Colors.blue;
    }
  }
}

class _DiceBar extends StatelessWidget {
  final int? roll;
  final LudoColor turn;
  final bool myTurn;
  final bool busy;
  final VoidCallback onRoll;
  const _DiceBar({
    required this.roll,
    required this.turn,
    required this.myTurn,
    required this.busy,
    required this.onRoll,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            myTurn
                ? 'Your turn — tap the die to roll.'
                : 'Waiting on ${turn.name}…',
            style: PanAfricanTypography.bodyMedium(context),
          ),
        ),
        FilledButton.icon(
          onPressed: myTurn && roll == null && !busy ? onRoll : null,
          icon: const Icon(Icons.casino_outlined),
          label: Text(roll == null ? 'Roll' : 'You rolled $roll'),
        ),
      ],
    );
  }
}

class _MyTokensRow extends StatelessWidget {
  final List<LudoToken> tokens;
  final int? activeRoll;
  final List<int> legalIndexes;
  final ValueChanged<int> onPick;
  const _MyTokensRow({
    required this.tokens,
    required this.activeRoll,
    required this.legalIndexes,
    required this.onPick,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          for (var i = 0; i < tokens.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _TokenChip(
                  index: i,
                  token: tokens[i],
                  legal: legalIndexes.contains(i),
                  onTap: () => onPick(i),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  final int index;
  final LudoToken token;
  final bool legal;
  final VoidCallback onTap;
  const _TokenChip({
    required this.index,
    required this.token,
    required this.legal,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    String label;
    if (token.finished) {
      label = 'Home';
    } else if (token.inBase) {
      label = 'Base';
    } else if (token.inHomeColumn) {
      label = 'Col ${token.position - 100 + 1}';
    } else {
      label = '#${token.position}';
    }
    return GestureDetector(
      onTap: legal ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: legal
              ? PanAfricanColors.kenteRed.withOpacity(0.18)
              : Colors.white.withOpacity(0.8),
          border: Border.all(
            color: legal ? PanAfricanColors.kenteRed : PanAfricanColors.kenteGold,
            width: legal ? 1.6 : 1.0,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('T${index + 1}', style: PanAfricanTypography.labelMedium(context)),
            const SizedBox(height: 2),
            Text(label, style: PanAfricanTypography.labelSmall(context)),
          ],
        ),
      ),
    );
  }
}

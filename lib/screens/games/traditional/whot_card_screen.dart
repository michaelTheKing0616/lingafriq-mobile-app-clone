// Whot — Nigerian card game with language-learning gates.
//
// Each of the four suits maps to a vocabulary category drawn from
// `game_content.json`:
//   - Circle  → greetings
//   - Cross   → market
//   - Square  → travel
//   - Star    → numbers
// Whot (wild) → free play, demands a suit
//
// Before playing a card, the user must pass an MCQ on the destination suit's
// vocab. Failing the MCQ forces a market pickup instead of a play.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:lingafriq/games/traditional/whot_engine.dart';
import 'package:lingafriq/models/game/game_content_models.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/screens/games/base_game_screen.dart';
import 'package:lingafriq/screens/games/game_scenario_loader.dart';
import 'package:lingafriq/services/audio/african_tts_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class WhotCardGame extends BaseGameScreen {
  const WhotCardGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.whotCardGame;

  @override
  ConsumerState<WhotCardGame> createState() => _WhotCardGameState();
}

class _WhotCardGameState extends BaseGameScreenState<WhotCardGame> {
  static const _humanPlayer = 0;
  static const _numPlayers = 4;

  final WhotEngine _engine = WhotEngine();
  late WhotAi _ai;
  late WhotState _state;
  Map<WhotSuit, List<GameWord>> _vocabBySuit = {};
  bool _busy = false;
  String? _status;
  int _correctMcq = 0;
  int _missedMcq = 0;

  @override
  bool get requiresPhraseCards => false;

  @override
  String? get shellScoreLabel =>
      'Hand ${_state.hands[_humanPlayer].length} · Market ${_state.deck.length}';

  @override
  void initState() {
    super.initState();
    _ai = WhotAi();
    _state = _engine.deal(players: _numPlayers);
  }

  @override
  Future<void> onGameInitialized() async {
    final greetings = await loadBundledGameWordsAsync(
      ref,
      language: widget.language,
      gameTag: 'greetings',
      max: 12,
    );
    final market = await loadBundledGameWordsAsync(
      ref,
      language: widget.language,
      gameTag: 'market',
      max: 12,
    );
    final travel = await loadBundledGameWordsAsync(
      ref,
      language: widget.language,
      gameTag: 'travel',
      max: 12,
    );
    final numbers = await loadBundledGameWordsAsync(
      ref,
      language: widget.language,
      gameTag: 'numbers',
      max: 12,
    );
    final fallback = await loadBundledGameWordsAsync(
      ref,
      language: widget.language,
      gameTag: 'vocabulary',
      max: 24,
    );
    setState(() {
      _vocabBySuit = {
        WhotSuit.circle: greetings.isNotEmpty ? greetings : fallback,
        WhotSuit.cross: market.isNotEmpty ? market : fallback,
        WhotSuit.square: travel.isNotEmpty ? travel : fallback,
        WhotSuit.star: numbers.isNotEmpty ? numbers : fallback,
        WhotSuit.whot: fallback,
      };
    });
  }

  Future<void> _onCardTap(int cardIndex) async {
    if (_busy) return;
    if (_state.turn != _humanPlayer) return;
    final legal = _engine.legalIndexes(_state, _humanPlayer);
    if (!legal.contains(cardIndex)) {
      _flash('That card cannot be played on the current top.');
      return;
    }
    final card = _state.hands[_humanPlayer][cardIndex];
    WhotSuit suitForVocab = card.isWhot ? WhotSuit.circle : card.suit;
    if (card.isWhot) {
      // Ask which suit to demand
      final demand = await _askDemandSuit();
      if (demand == null) return;
      suitForVocab = demand;
    }
    final vocabPool = _vocabBySuit[suitForVocab] ?? const <GameWord>[];
    if (vocabPool.length < 4) {
      // Not enough distractors — play the card directly, no MCQ.
      setState(() => _state = _engine.play(_state, _humanPlayer, cardIndex,
          demandSuit: card.isWhot ? suitForVocab : null));
      await _afterUserTurn();
      return;
    }
    final ok = await _runMcq(vocabPool);
    final cardId = 'whot_${card.suit.name}_${card.rank}';
    final durationMs = DateTime.now()
        .difference(startTime ?? DateTime.now())
        .inMilliseconds;
    if (!ok) {
      _missedMcq++;
      await completeTurn(
        cardId: cardId,
        result: GameResult.incorrect,
        durationMs: durationMs,
        feedback: {'game': 'whot', 'event': 'mcq_failed'},
      );
      _flash('Wrong gloss — you draw from market instead.');
      setState(() => _state = _engine.marketDraw(_state, _humanPlayer));
      await _afterUserTurn();
      return;
    }
    _correctMcq++;
    await completeTurn(
      cardId: cardId,
      result: GameResult.correct,
      durationMs: durationMs,
      feedback: {'game': 'whot', 'event': 'mcq_passed'},
    );
    setState(() => _state = _engine.play(_state, _humanPlayer, cardIndex,
        demandSuit: card.isWhot ? suitForVocab : null));
    await _afterUserTurn();
  }

  Future<void> _onMarketTap() async {
    if (_busy) return;
    if (_state.turn != _humanPlayer) return;
    setState(() {
      _state = _engine.resolvePicks(_state, _humanPlayer);
      _state = _engine.marketDraw(_state, _humanPlayer);
    });
    await _afterUserTurn();
  }

  Future<void> _afterUserTurn() async {
    final winner = _engine.checkWinner(_state);
    if (winner != null) {
      await _finish(win: winner == _humanPlayer);
      return;
    }
    await _runBots();
  }

  Future<void> _runBots() async {
    while (mounted && _state.turn != _humanPlayer) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      // If pick-2 chain hits the bot and it has no '2', it picks.
      _state = _engine.resolvePicks(_state, _state.turn);
      final (cardIndex, demanded) = _ai.chooseMove(_engine, _state, _state.turn);
      setState(() {});
      if (cardIndex == -1) {
        _state = _engine.marketDraw(_state, _state.turn);
        setState(() => _status = 'Player ${_state.turn} drew from market.');
      } else {
        _state = _engine.play(_state, _state.turn, cardIndex,
            demandSuit: demanded);
        setState(() => _status = 'Player ${_state.turn} played a card.');
      }
      final winner = _engine.checkWinner(_state);
      if (winner != null) {
        await _finish(win: winner == _humanPlayer);
        return;
      }
    }
  }

  Future<WhotSuit?> _askDemandSuit() async {
    return showModalBottomSheet<WhotSuit>(
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
            Text('Demand a suit',
                style: PanAfricanTypography.labelLarge(ctx)),
            const SizedBox(height: 12),
            for (final s in [
              WhotSuit.circle,
              WhotSuit.cross,
              WhotSuit.square,
              WhotSuit.star
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(s),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(s.name.toUpperCase()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _runMcq(List<GameWord> pool) async {
    final target = pool[Random().nextInt(pool.length)];
    unawaited(AfricanTtsService().speak(
      language: widget.language,
      text: target.word,
    ));
    setState(() => _busy = true);
    final distractors = (List<GameWord>.from(pool)..shuffle(Random()))
        .where((w) => w.englishMeaning != target.englishMeaning)
        .take(3)
        .toList();
    final options = [target, ...distractors]..shuffle(Random());
    final res = await showModalBottomSheet<bool>(
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
            Text('Card gate', style: PanAfricanTypography.labelLarge(ctx)),
            const SizedBox(height: 4),
            Text('Pick the meaning of "${target.word}" to play this card.',
                style: PanAfricanTypography.bodyMedium(ctx)),
            const SizedBox(height: 14),
            for (final o in options)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(
                      o.englishMeaning == target.englishMeaning),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(o.englishMeaning),
                ),
              ),
          ],
        ),
      ),
    );
    setState(() => _busy = false);
    return res ?? false;
  }

  Future<void> _finish({required bool win}) async {
    await completeTurn(
      cardId: 'whot_match_outcome',
      result: win ? GameResult.correct : GameResult.incorrect,
      durationMs: DateTime.now()
          .difference(startTime ?? DateTime.now())
          .inMilliseconds,
      feedback: {
        'game': 'whot',
        'event': 'match_complete',
        'correct_mcq': _correctMcq,
        'missed_mcq': _missedMcq,
      },
    );
    await finishGame();
  }

  void _flash(String msg) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(milliseconds: 1400),
    ));
  }

  @override
  Widget buildGameContent(BuildContext context) {
    final myHand = _state.hands[_humanPlayer];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _OpponentsRow(state: _state, humanPlayer: _humanPlayer),
            const SizedBox(height: 12),
            Expanded(child: _TableArea(
              state: _state,
              onMarketTap: _onMarketTap,
            )),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(_status!,
                    style: PanAfricanTypography.labelMedium(context)),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: myHand.length,
                itemBuilder: (ctx, i) {
                  final legal = _state.turn == _humanPlayer &&
                      _engine.legalIndexes(_state, _humanPlayer).contains(i);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _CardWidget(
                      card: myHand[i],
                      legal: legal,
                      onTap: () => _onCardTap(i),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpponentsRow extends StatelessWidget {
  final WhotState state;
  final int humanPlayer;
  const _OpponentsRow({required this.state, required this.humanPlayer});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (var p = 0; p < state.numPlayers; p++)
          if (p != humanPlayer)
            Column(
              children: [
                Icon(
                  state.turn == p
                      ? Icons.person_search
                      : Icons.person_outline,
                  color: state.turn == p
                      ? PanAfricanColors.kenteRed
                      : null,
                ),
                Text('P$p',
                    style: PanAfricanTypography.labelSmall(context)),
                Text('${state.hands[p].length}',
                    style: PanAfricanTypography.titleSmall(context)),
              ],
            ),
      ],
    );
  }
}

class _TableArea extends StatelessWidget {
  final WhotState state;
  final VoidCallback onMarketTap;
  const _TableArea({required this.state, required this.onMarketTap});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Pile', style: PanAfricanTypography.labelMedium(context)),
            const SizedBox(height: 6),
            _CardWidget(card: state.topCard, legal: false, onTap: () {}),
            if (state.demandedSuit != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Demand: ${state.demandedSuit!.name.toUpperCase()}',
                  style: PanAfricanTypography.labelSmall(context),
                ),
              ),
            if (state.pickStack > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Pick ${state.pickStack}',
                  style: PanAfricanTypography.labelSmall(
                    context,
                    color: PanAfricanColors.kenteRed,
                  ),
                ),
              ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Market',
                style: PanAfricanTypography.labelMedium(context)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onMarketTap,
              child: Container(
                width: 76,
                height: 110,
                decoration: BoxDecoration(
                  color: PanAfricanColors.primary.withOpacity(0.18),
                  border: Border.all(
                    color: PanAfricanColors.primary,
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text('${state.deck.length}',
                    style: PanAfricanTypography.titleLarge(context)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardWidget extends StatelessWidget {
  final WhotCard card;
  final bool legal;
  final VoidCallback onTap;
  const _CardWidget({
    required this.card,
    required this.legal,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final color = _suitColor(card.suit);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 76,
        height: 110,
        decoration: BoxDecoration(
          color: legal ? color.withOpacity(0.30) : color.withOpacity(0.12),
          border: Border.all(
            color: legal ? PanAfricanColors.kenteRed : color,
            width: legal ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_suitIcon(card.suit), color: color, size: 28),
            const SizedBox(height: 6),
            Text(card.isWhot ? 'WHOT' : '${card.rank}',
                style: PanAfricanTypography.titleMedium(context)),
          ],
        ),
      ),
    );
  }

  IconData _suitIcon(WhotSuit suit) {
    switch (suit) {
      case WhotSuit.circle:
        return Icons.circle_outlined;
      case WhotSuit.cross:
        return Icons.add;
      case WhotSuit.square:
        return Icons.square_outlined;
      case WhotSuit.star:
        return Icons.star_outline;
      case WhotSuit.whot:
        return Icons.style;
    }
  }

  Color _suitColor(WhotSuit suit) {
    switch (suit) {
      case WhotSuit.circle:
        return Colors.blue;
      case WhotSuit.cross:
        return PanAfricanColors.kenteRed;
      case WhotSuit.square:
        return Colors.green;
      case WhotSuit.star:
        return PanAfricanColors.kenteGold;
      case WhotSuit.whot:
        return PanAfricanColors.accent;
    }
  }
}

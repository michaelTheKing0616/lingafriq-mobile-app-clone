import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/game/game_session_model.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/pan_african_components.dart';
import 'base_game_screen.dart';

class MarketMonopolyChallengeGame extends BaseGameScreen {
  const MarketMonopolyChallengeGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.marketMonopolyChallenge;

  @override
  ConsumerState<MarketMonopolyChallengeGame> createState() =>
      _MarketMonopolyChallengeGameState();
}

class _MarketMonopolyChallengeGameState
    extends BaseGameScreenState<MarketMonopolyChallengeGame> {
  static const _maxRounds = 7;
  final _random = Random();

  int _round = 1;
  int _bank = 180;
  int _bid = 20;
  String _marketEvent = '';
  String _feedback = '';
  bool _resolvedRound = false;

  @override
  int getCardCount() => _maxRounds;

  @override
  Future<void> onGameInitialized() async {
    _prepareRound();
  }

  void _prepareRound() {
    final events = [
      'Rainy season supply drop',
      'Festival demand spike',
      'Neighbor market undercuts price',
      'Tourist route opens today',
      'Fresh produce arrives early',
      'Transport strike limits stock',
      'Community fair boosts traffic',
    ];
    setState(() {
      _marketEvent = events[_random.nextInt(events.length)];
      _bid = 20 + _random.nextInt(35);
      _feedback = '';
      _resolvedRound = false;
    });
  }

  Future<void> _submitBid() async {
    if (_resolvedRound) return;
    HapticFeedback.lightImpact();
    final target = 24 + _random.nextInt(40);
    final difference = (_bid - target).abs();
    final result = difference <= 5
        ? GameResult.correct
        : (difference <= 12 ? GameResult.partial : GameResult.incorrect);
    final profit = switch (result) {
      GameResult.correct => 34,
      GameResult.partial => 12,
      _ => -18,
    };
    _bank += profit;

    await completeTurn(
      cardId: 'market_monopoly_$_round',
      result: result,
      durationMs: 1200 + _random.nextInt(1600),
      confidence: result == GameResult.correct
          ? 0.95
          : (result == GameResult.partial ? 0.6 : 0.25),
      feedback: {
        'market_event': _marketEvent,
        'target_bid': target,
        'player_bid': _bid,
        'bank_after_round': _bank,
      },
      userAction: 'set_bid_$_bid',
    );

    if (!mounted) return;
    setState(() {
      _resolvedRound = true;
      _feedback = result == GameResult.correct
          ? 'Strong trade. You negotiated an excellent margin.'
          : result == GameResult.partial
              ? 'Decent deal. You stayed competitive.'
              : 'Tough round. Margin slipped this time.';
    });
  }

  Future<void> _nextRound() async {
    if (_round >= _maxRounds) {
      await finishGame();
      return;
    }
    setState(() {
      _round += 1;
    });
    _prepareRound();
  }

  @override
  String? get appBarTitle =>
      '${widget.getGameType().displayName} ($_round/$_maxRounds)';

  @override
  Widget buildGameContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanAfricanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Market event', style: PanAfricanTypography.labelLarge(context)),
                SizedBox(height: PanAfricanSpacing.xs),
                Text(_marketEvent, style: PanAfricanTypography.titleMedium(context)),
                SizedBox(height: PanAfricanSpacing.sm),
                Text('Market Bank: $_bank cowries',
                    style: PanAfricanTypography.bodyLarge(context)),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          PanAfricanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set your bid',
                    style: PanAfricanTypography.titleSmall(context)),
                Slider(
                  value: _bid.toDouble(),
                  min: 10,
                  max: 70,
                  divisions: 60,
                  label: '$_bid',
                  onChanged: _resolvedRound
                      ? null
                      : (v) => setState(() => _bid = v.round()),
                ),
                Text('Bid: $_bid',
                    style: PanAfricanTypography.bodyMedium(context)),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          FilledButton.icon(
            onPressed: _resolvedRound ? null : _submitBid,
            icon: const Icon(Icons.local_atm_rounded),
            label: const Text('Place Bid'),
          ),
          if (_feedback.isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.sm),
            Text(_feedback, style: PanAfricanTypography.bodyMedium(context)),
            SizedBox(height: PanAfricanSpacing.sm),
            OutlinedButton(
              onPressed: _nextRound,
              child: Text(_round >= _maxRounds ? 'Finish Game' : 'Next Round'),
            ),
          ],
        ],
      ),
    );
  }
}

class ScrabbleSprintArenaGame extends BaseGameScreen {
  const ScrabbleSprintArenaGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.scrabbleSprintArena;

  @override
  ConsumerState<ScrabbleSprintArenaGame> createState() => _ScrabbleSprintArenaGameState();
}

class _ScrabbleSprintArenaGameState
    extends BaseGameScreenState<ScrabbleSprintArenaGame> {
  static const _maxRounds = 8;
  final _random = Random();
  final _controller = TextEditingController();

  int _round = 1;
  String _letters = '';
  String _hint = '';
  String _resultText = '';
  bool _locked = false;

  @override
  int getCardCount() => _maxRounds;

  @override
  Future<void> onGameInitialized() async {
    _prepareRound();
  }

  void _prepareRound() {
    const seeds = [
      ('A M A N I', 'peace'),
      ('U M O J A', 'unity'),
      ('B A R A K A', 'blessing'),
      ('S A F A R I', 'journey'),
      ('M A J I', 'water'),
      ('J A M I I', 'community'),
    ];
    final (letters, hint) = seeds[_random.nextInt(seeds.length)];
    setState(() {
      _letters = letters;
      _hint = hint;
      _resultText = '';
      _controller.clear();
      _locked = false;
    });
  }

  Future<void> _checkWord() async {
    if (_locked) return;
    final answer = _controller.text.trim().toLowerCase();
    if (answer.isEmpty) return;
    HapticFeedback.selectionClick();

    final normalizedLetters = _letters.replaceAll(' ', '').toLowerCase().split('');
    final guessLetters = answer.split('');
    final canBuild = _canBuildWord(guessLetters, normalizedLetters);
    final lengthBonus = answer.length >= 5;
    final result = canBuild && lengthBonus
        ? GameResult.correct
        : (canBuild ? GameResult.partial : GameResult.incorrect);

    await completeTurn(
      cardId: 'scrabble_sprint_$_round',
      result: result,
      durationMs: 1000 + _random.nextInt(1800),
      feedback: {
        'letters': _letters,
        'hint': _hint,
        'answer': answer,
      },
      userAction: 'submit_word',
    );

    if (!mounted) return;
    setState(() {
      _locked = true;
      _resultText = result == GameResult.correct
          ? 'Brilliant word build.'
          : result == GameResult.partial
              ? 'Valid build. Push for a longer word.'
              : 'Letters do not match this board.';
    });
  }

  bool _canBuildWord(List<String> guess, List<String> pool) {
    final mutablePool = [...pool];
    for (final letter in guess) {
      final idx = mutablePool.indexOf(letter);
      if (idx == -1) return false;
      mutablePool.removeAt(idx);
    }
    return true;
  }

  Future<void> _continue() async {
    if (_round >= _maxRounds) {
      await finishGame();
      return;
    }
    setState(() => _round += 1);
    _prepareRound();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String? get appBarTitle =>
      '${widget.getGameType().displayName} ($_round/$_maxRounds)';

  @override
  Widget buildGameContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanAfricanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Board letters',
                    style: PanAfricanTypography.labelLarge(context)),
                SizedBox(height: PanAfricanSpacing.xs),
                Text(
                  _letters,
                  style: PanAfricanTypography.headlineSmall(context),
                ),
                SizedBox(height: PanAfricanSpacing.xs),
                Text('Hint: $_hint',
                    style: PanAfricanTypography.bodyMedium(context)),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          TextField(
            controller: _controller,
            enabled: !_locked,
            decoration: const InputDecoration(
              labelText: 'Build a valid word',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _checkWord(),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          FilledButton.icon(
            onPressed: _locked ? null : _checkWord,
            icon: const Icon(Icons.spellcheck_rounded),
            label: const Text('Check Word'),
          ),
          if (_resultText.isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.sm),
            Text(_resultText, style: PanAfricanTypography.bodyMedium(context)),
            SizedBox(height: PanAfricanSpacing.sm),
            OutlinedButton(
              onPressed: _continue,
              child: Text(_round >= _maxRounds ? 'Finish Game' : 'Next Board'),
            ),
          ],
        ],
      ),
    );
  }
}

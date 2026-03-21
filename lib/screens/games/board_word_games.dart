import 'dart:async';
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
  String? get appBarTitle => widget.getGameType().displayName;

  @override
  String? get shellProgressLabel => '$_round/$_maxRounds';

  @override
  String? get shellScoreLabel => '$_bank cowries';

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
  ConsumerState<ScrabbleSprintArenaGame> createState() =>
      _ScrabbleSprintArenaGameState();
}

/// Word seed: spaced letters, the target word, and a category-style hint that
/// does NOT reveal the meaning directly.
typedef _WordSeed = ({String letters, String word, String hint});

/// Language-keyed word banks. Each entry provides scrambled letters, the
/// expected answer, and an indirect clue (category / usage context).
const Map<String, List<_WordSeed>> _scrabbleWordBanks = {
  'swahili': [
    (letters: 'A M A N I', word: 'AMANI', hint: 'A feeling people seek after conflict'),
    (letters: 'U M O J A', word: 'UMOJA', hint: 'A principle celebrated on Kwanzaa'),
    (letters: 'B A R A K A', word: 'BARAKA', hint: 'Something an elder might bestow'),
    (letters: 'S A F A R I', word: 'SAFARI', hint: 'An activity tourists love in East Africa'),
    (letters: 'M A J I', word: 'MAJI', hint: 'Essential for life, flows in rivers'),
    (letters: 'J A M I I', word: 'JAMII', hint: 'People living and working together'),
    (letters: 'R A F I K I', word: 'RAFIKI', hint: 'Someone you trust and confide in'),
    (letters: 'S H U L E', word: 'SHULE', hint: 'Where children go to learn'),
  ],
  'yoruba': [
    (letters: 'A L A F I A', word: 'ALAFIA', hint: 'A greeting wishing wellness'),
    (letters: 'O M O', word: 'OMO', hint: 'What parents call their young one'),
    (letters: 'I F E', word: 'IFE', hint: 'A deep emotion of the heart'),
    (letters: 'O R I S A', word: 'ORISA', hint: 'A spiritual being in Yoruba belief'),
    (letters: 'O N I L E', word: 'ONILE', hint: 'The person who owns a dwelling'),
    (letters: 'A G B A R A', word: 'AGBARA', hint: 'What powers machines and muscles'),
    (letters: 'I L E R A', word: 'ILERA', hint: 'Doctors help you maintain this'),
  ],
  'hausa': [
    (letters: 'L A F I Y A', word: 'LAFIYA', hint: 'How you say you are fine'),
    (letters: 'R U W A', word: 'RUWA', hint: 'It falls from clouds and fills wells'),
    (letters: 'G I D A', word: 'GIDA', hint: 'Where a family lives'),
    (letters: 'A B O K I', word: 'ABOKI', hint: 'Someone you share good times with'),
    (letters: 'K A S U W A', word: 'KASUWA', hint: 'A place to buy and sell goods'),
    (letters: 'M A K A R A N T A', word: 'MAKARANTA', hint: 'Where students study'),
    (letters: 'H A N K A L I', word: 'HANKALI', hint: 'Think before you act — use this'),
  ],
  'igbo': [
    (letters: 'U D O', word: 'UDO', hint: 'Absence of conflict'),
    (letters: 'N W A N N E', word: 'NWANNE', hint: 'A person from the same parents'),
    (letters: 'I F U N A N Y A', word: 'IFUNANYA', hint: 'A deep feeling between two people'),
    (letters: 'A H I A', word: 'AHIA', hint: 'A busy place where traders gather'),
    (letters: 'M M I R I', word: 'MMIRI', hint: 'Flows in streams, fills the ocean'),
    (letters: 'E Z I G B O', word: 'EZIGBO', hint: 'Describes someone with fine character'),
    (letters: 'U L O', word: 'ULO', hint: 'A structure people live inside'),
  ],
  'zulu': [
    (letters: 'U K U T H U L A', word: 'UKUTHULA', hint: 'A calm state societies strive for'),
    (letters: 'A M A N Z I', word: 'AMANZI', hint: 'Fills lakes and quenches thirst'),
    (letters: 'U M U Z I', word: 'UMUZI', hint: 'A cluster of dwellings in a homestead'),
    (letters: 'I S I K O L E', word: 'ISIKOLE', hint: 'Children attend this to learn'),
    (letters: 'U M N T W A N A', word: 'UMNTWANA', hint: 'A young person not yet grown'),
    (letters: 'U B U N T U', word: 'UBUNTU', hint: 'I am because we are — a philosophy'),
    (letters: 'I N D L E L A', word: 'INDLELA', hint: 'You walk or drive along it'),
  ],
};

/// Fallback when language has no dedicated bank.
const List<_WordSeed> _fallbackBank = [
  (letters: 'A M A N I', word: 'AMANI', hint: 'A feeling people seek after conflict'),
  (letters: 'U M O J A', word: 'UMOJA', hint: 'A principle celebrated on Kwanzaa'),
  (letters: 'B A R A K A', word: 'BARAKA', hint: 'Something an elder might bestow'),
  (letters: 'S A F A R I', word: 'SAFARI', hint: 'An activity tourists love in East Africa'),
  (letters: 'M A J I', word: 'MAJI', hint: 'Essential for life, flows in rivers'),
  (letters: 'J A M I I', word: 'JAMII', hint: 'People living and working together'),
];

class _ScrabbleSprintArenaGameState
    extends BaseGameScreenState<ScrabbleSprintArenaGame> {
  static const _maxRounds = 8;
  static const _sprintDurationSecs = 60;

  final _random = Random();
  final _controller = TextEditingController();

  int _round = 1;
  String _letters = '';
  String _targetWord = '';
  String _hint = '';
  String _resultText = '';
  bool _locked = false;

  int _secondsLeft = _sprintDurationSecs;
  Timer? _timer;
  bool _timerExpired = false;

  List<_WordSeed> get _seeds {
    final key = widget.language.toLowerCase().trim();
    return _scrabbleWordBanks[key] ?? _fallbackBank;
  }

  @override
  int getCardCount() => _maxRounds;

  @override
  Future<void> onGameInitialized() async {
    _startTimer();
    _prepareRound();
  }

  void _startTimer() {
    _secondsLeft = _sprintDurationSecs;
    _timerExpired = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _secondsLeft = 0;
          _timerExpired = true;
          t.cancel();
          _onTimerExpired();
        }
      });
    });
  }

  Future<void> _onTimerExpired() async {
    HapticFeedback.heavyImpact();
    await finishGame();
  }

  void _prepareRound() {
    final seeds = _seeds;
    final seed = seeds[_random.nextInt(seeds.length)];
    setState(() {
      _letters = seed.letters;
      _targetWord = seed.word;
      _hint = seed.hint;
      _resultText = '';
      _controller.clear();
      _locked = false;
    });
  }

  Future<void> _checkWord() async {
    if (_locked || _timerExpired) return;
    final answer = _controller.text.trim().toLowerCase();
    if (answer.isEmpty) return;
    HapticFeedback.selectionClick();

    final normalizedLetters =
        _letters.replaceAll(' ', '').toLowerCase().split('');
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
        'target': _targetWord,
        'answer': answer,
      },
      userAction: 'submit_word',
    );

    if (!mounted) return;
    setState(() {
      _locked = true;
      _resultText = result == GameResult.correct
          ? 'Brilliant word build!'
          : result == GameResult.partial
              ? 'Valid build — push for a longer word next time.'
              : 'Those letters don\'t match this board.';
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
    if (_timerExpired || _round >= _maxRounds) {
      await finishGame();
      return;
    }
    setState(() => _round += 1);
    _prepareRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  String? get appBarTitle => widget.getGameType().displayName;

  @override
  String? get shellProgressLabel => '$_round/$_maxRounds · ${_secondsLeft}s';

  Color _timerColor(BuildContext context) {
    if (_secondsLeft <= 10) return PanAfricanColors.error;
    if (_secondsLeft <= 20) return PanAfricanColors.warning;
    return PanAfricanColors.primary;
  }

  @override
  Widget buildGameContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timer bar
          PanAfricanCard(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md,
              vertical: PanAfricanSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.timer_rounded,
                    size: 22.sp, color: _timerColor(context)),
                SizedBox(width: PanAfricanSpacing.xs),
                Text(
                  '${_secondsLeft}s',
                  style: PanAfricanTypography.titleMedium(context,
                      color: _timerColor(context)),
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: PanAfricanRadius.smBR,
                    child: LinearProgressIndicator(
                      value: _secondsLeft / _sprintDurationSecs,
                      minHeight: 6.h,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHigh,
                      valueColor:
                          AlwaysStoppedAnimation(_timerColor(context)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),

          // Rules reminder
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xs),
            child: Text(
              'Form a word using only the letters shown. '
              'Longer words (5+ letters) earn full marks!',
              style: PanAfricanTypography.bodySmall(context),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),

          // Board letters + hint
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
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 16.sp, color: PanAfricanColors.secondary),
                    SizedBox(width: PanAfricanSpacing.xxs),
                    Expanded(
                      child: Text(
                        _hint,
                        style: PanAfricanTypography.bodyMedium(context,
                            color: PanAfricanColors.secondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),

          // Input
          TextField(
            controller: _controller,
            enabled: !_locked && !_timerExpired,
            decoration: const InputDecoration(
              labelText: 'Build a valid word',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _checkWord(),
          ),
          SizedBox(height: PanAfricanSpacing.md),

          FilledButton.icon(
            onPressed: (_locked || _timerExpired) ? null : _checkWord,
            icon: const Icon(Icons.spellcheck_rounded),
            label: const Text('Check Word'),
          ),

          if (_resultText.isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.sm),
            Text(_resultText,
                style: PanAfricanTypography.bodyMedium(context)),
            SizedBox(height: PanAfricanSpacing.sm),
            OutlinedButton(
              onPressed: _continue,
              child:
                  Text(_round >= _maxRounds ? 'Finish Game' : 'Next Board'),
            ),
          ],
        ],
      ),
    );
  }
}

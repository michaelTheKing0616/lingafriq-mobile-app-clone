import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../avatars/games/game_avatar_widget.dart';
import '../../avatars/personality_system.dart';
import '../../games/gamekit/game_scoring.dart';
import '../../services/audio/african_tts_service.dart';
import '../../services/feature_flag_service.dart';
import '../../utils/pan_african_design_system.dart';
import 'greeting_gauntlet_game.dart';
import 'scenario_matrix.dart';

enum GreetingGauntletPhase {
  loading,
  ready,
  playing,
  correct,
  wrong,
  whyWrong,
  results,
  error,
  offline,
  practiceMode,
  gesturePlaying,
}

/// Flagship Greeting Gauntlet (P8-928).
class GreetingGauntletScreen extends ConsumerStatefulWidget {
  const GreetingGauntletScreen({
    super.key,
    required this.language,
    this.onBack,
    this.initialPhase,
    this.previewRound,
  });

  static const title = 'Greeting Gauntlet';
  static const instructions =
      'Read the scene, pick the greeting and gesture that fit — before the timer runs out.';
  static const whyWrongCopy =
      'Listen to why that greeting or gesture did not match the moment.';
  static const practiceLabel =
      'Practice — cultural rounds do not affect rank until scoring is verified.';
  static const errorCopy =
      'We could not load greeting scenarios for this language yet. Try again when you are online.';

  final String language;
  final VoidCallback? onBack;
  final GreetingGauntletPhase? initialPhase;
  final GauntletRound? previewRound;

  @override
  ConsumerState<GreetingGauntletScreen> createState() =>
      _GreetingGauntletScreenState();
}

class _GreetingGauntletScreenState extends ConsumerState<GreetingGauntletScreen> {
  GreetingGauntletPhase _phase = GreetingGauntletPhase.loading;
  final GameAvatarController _avatar = GameAvatarController(GameCategory.cultural);
  final AfricanTtsService _tts = AfricanTtsService();

  List<GauntletRound> _rounds = const [];
  int _roundIndex = 0;
  int _score = 0;
  GauntletRound? _current;
  int? _selected;
  Timer? _timer;
  int _secondsLeft = kGauntletRoundSeconds;
  bool _practiceNotScored = true;
  String? _loadError;
  GauntletRoundScore? _lastScore;

  @override
  void initState() {
    super.initState();
    unawaited(_avatar.initialize());
    _resolvePracticeMode();
    if (widget.initialPhase != null && widget.previewRound != null) {
      _phase = widget.initialPhase!;
      _current = widget.previewRound;
      return;
    }
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _avatar.dispose();
    super.dispose();
  }

  void _resolvePracticeMode() {
    final flagOn = FeatureFlagService(safeDefault: false).isOn(
      gameKitRealSpeakingScorerFlagKey,
      DateTime.now(),
    );
    final live = gameKitRealScorerLiveForGame(
      featureFlagOn: flagOn,
      gameId: 'greeting_diplomacy_challenge',
      isSpeakingGame: false,
    );
    _practiceNotScored = gameKitPracticeNotScoredMode(
      isSpeakingGame: false,
      realScorerLive: live,
    );
  }

  Future<void> _bootstrap() async {
    try {
      final rounds = await loadGauntletRoundsForLanguage(widget.language);
      if (rounds.isEmpty) {
        setState(() {
          _phase = GreetingGauntletPhase.error;
          _loadError = GreetingGauntletScreen.errorCopy;
        });
        return;
      }
      _rounds = rounds;
      await _startRound();
    } catch (_) {
      setState(() {
        _phase = GreetingGauntletPhase.error;
        _loadError = GreetingGauntletScreen.errorCopy;
      });
    }
  }

  Future<void> _startRound() async {
    _timer?.cancel();
    if (_roundIndex >= _rounds.length) {
      setState(() => _phase = GreetingGauntletPhase.results);
      return;
    }
    _current = _rounds[_roundIndex];
    _roundIndex++;
    _selected = null;
    _secondsLeft = kGauntletRoundSeconds;
    _lastScore = null;
    setState(() {
      _phase = _practiceNotScored
          ? GreetingGauntletPhase.practiceMode
          : GreetingGauntletPhase.ready;
    });
  }

  void _beginTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_phase != GreetingGauntletPhase.playing &&
          _phase != GreetingGauntletPhase.practiceMode &&
          _phase != GreetingGauntletPhase.ready) {
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          t.cancel();
          _onSubmit(timedOut: true);
        }
      });
    });
  }

  void _onPlayTap() {
    if (_phase == GreetingGauntletPhase.ready ||
        _phase == GreetingGauntletPhase.practiceMode) {
      setState(() => _phase = GreetingGauntletPhase.playing);
      _beginTimer();
    }
  }

  void _onPick(int index) {
    if (_phase != GreetingGauntletPhase.playing &&
        _phase != GreetingGauntletPhase.practiceMode) {
      return;
    }
    setState(() => _selected = index);
    _onSubmit(timedOut: false);
  }

  Future<void> _onSubmit({required bool timedOut}) async {
    _timer?.cancel();
    final round = _current;
    if (round == null) return;
    final result = scoreGauntletPick(
      round: round,
      selectedIndex: _selected,
      timedOut: timedOut,
    );
    _lastScore = result;
    if (result.correct) {
      _score++;
      setState(() => _phase = GreetingGauntletPhase.gesturePlaying);
      _avatar.performCulturalGesture(round.correctGesture);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _avatar.reactToCorrectAnswer();
      setState(() => _phase = GreetingGauntletPhase.correct);
    } else {
      _avatar.reactToIncorrectAnswer();
      setState(() => _phase = GreetingGauntletPhase.wrong);
      if (result.explanation != null) {
        unawaited(_speakExplanation(result.explanation!));
      }
    }
  }

  Future<void> _speakExplanation(String text) async {
    try {
      await _tts.speak(
        text: text,
        language: widget.language,
      );
    } catch (_) {
      setState(() => _phase = GreetingGauntletPhase.offline);
    }
  }

  void _showWhyWrong() {
    setState(() => _phase = GreetingGauntletPhase.whyWrong);
    final round = _current;
    if (round != null) {
      unawaited(_speakExplanation(round.whyWrongEn));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: PanAfricanColors.surface,
      appBar: AppBar(
        title: const Text(GreetingGauntletScreen.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: switch (_phase) {
          GreetingGauntletPhase.loading => const Center(
              child: CircularProgressIndicator(),
            ),
          GreetingGauntletPhase.error => _StateMessage(
              message: _loadError ?? GreetingGauntletScreen.errorCopy,
              actionLabel: 'Try again',
              onAction: () {
                setState(() => _phase = GreetingGauntletPhase.loading);
                unawaited(_bootstrap());
              },
            ),
          GreetingGauntletPhase.offline => _StateMessage(
              message:
                  'Audio needs a connection. You can still read the explanation below.',
              actionLabel: 'Continue',
              onAction: _showWhyWrong,
            ),
          GreetingGauntletPhase.results => _buildResults(context),
          _ => _buildRound(context, reduceMotion),
        },
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final total = _rounds.length;
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Round complete',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Text('You matched $score of $total scenes.'),
          if (_practiceNotScored)
            Padding(
              padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
              child: Text(
                GreetingGauntletScreen.practiceLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const Spacer(),
          FilledButton(
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  int get score => _score;

  Widget _buildRound(BuildContext context, bool reduceMotion) {
    final round = _current;
    if (round == null) {
      return const SizedBox.shrink();
    }
    final showTimer = _phase == GreetingGauntletPhase.playing ||
        _phase == GreetingGauntletPhase.practiceMode ||
        _phase == GreetingGauntletPhase.ready;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_practiceNotScored)
            Semantics(
              label: GreetingGauntletScreen.practiceLabel,
              child: Text(
                GreetingGauntletScreen.practiceLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          SizedBox(height: PanAfricanSpacing.sm),
          if (showTimer)
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  semanticLabel: 'Time remaining',
                ),
                SizedBox(width: PanAfricanSpacing.xs),
                Text('${_secondsLeft}s'),
              ],
            ),
          SizedBox(height: PanAfricanSpacing.sm),
          _SceneCard(round: round),
          SizedBox(height: PanAfricanSpacing.md),
          Center(
            child: GameAvatarWidget(
              category: GameCategory.cultural,
              size: 100.w,
              message: _phase == GreetingGauntletPhase.gesturePlaying
                  ? gestureLabel(round.correctGesture)
                  : null,
              showSpeechBubble: _phase == GreetingGauntletPhase.gesturePlaying,
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Expanded(child: _phaseBody(context, round, reduceMotion)),
        ],
      ),
    );
  }

  Widget _phaseBody(
    BuildContext context,
    GauntletRound round,
    bool reduceMotion,
  ) {
    switch (_phase) {
      case GreetingGauntletPhase.ready:
      case GreetingGauntletPhase.practiceMode:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(GreetingGauntletScreen.instructions),
            const Spacer(),
            FilledButton(
              onPressed: _onPlayTap,
              child: const Text('Start scene'),
            ),
          ],
        );
      case GreetingGauntletPhase.playing:
        return _ChoiceGrid(
          round: round,
          selected: _selected,
          onPick: _onPick,
        );
      case GreetingGauntletPhase.correct:
        return _FeedbackPane(
          icon: Icons.check_circle,
          iconLabel: 'Correct',
          title: 'Well matched',
          body: 'You chose ${round.correctPhraseForAudio} with ${gestureLabel(round.correctGesture).toLowerCase()}.',
          actionLabel: 'Next scene',
          onAction: _startRound,
        );
      case GreetingGauntletPhase.wrong:
        return _FeedbackPane(
          icon: Icons.cancel,
          iconLabel: 'Incorrect',
          title: 'Not quite',
          body: _lastScore?.explanation ?? round.whyWrongEn,
          actionLabel: GreetingGauntletScreen.whyWrongCopy,
          onAction: _showWhyWrong,
          secondaryLabel: 'Skip',
          onSecondary: _startRound,
        );
      case GreetingGauntletPhase.whyWrong:
        return _FeedbackPane(
          icon: Icons.info_outline,
          iconLabel: 'Explanation',
          title: 'Why it missed',
          body: round.whyWrongEn,
          actionLabel: 'Next scene',
          onAction: _startRound,
        );
      case GreetingGauntletPhase.gesturePlaying:
        return Center(
          child: Text(
            gestureLabel(round.correctGesture),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.round});

  final GauntletRound round;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              round.promptEn,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (round.culturalReviewFlag)
              Padding(
                padding: EdgeInsets.only(top: PanAfricanSpacing.xs),
                child: Text(
                  'Honorific register — expert reviewed',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.round,
    required this.selected,
    required this.onPick,
  });

  final GauntletRound round;
  final int? selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: round.choices.length,
      separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.sm),
      itemBuilder: (context, index) {
        final choice = round.choices[index];
        final gesture = gestureLabel(choice.gesture);
        return Semantics(
          button: true,
          label: '${choice.text}. $gesture. ${choice.translationEn}',
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: () => onPick(index),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(choice.text, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      '$gesture · ${choice.translationEn}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeedbackPane extends StatelessWidget {
  const _FeedbackPane({
    required this.icon,
    required this.iconLabel,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String iconLabel;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, semanticLabel: iconLabel),
            SizedBox(width: PanAfricanSpacing.xs),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(body),
        const Spacer(),
        FilledButton(onPressed: onAction, child: Text(actionLabel)),
        if (secondaryLabel != null && onSecondary != null) ...[
          SizedBox(height: PanAfricanSpacing.sm),
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
        ],
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: PanAfricanSpacing.md),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

/// Key states for goldens (P8-928).
class GreetingGauntletPreview extends StatelessWidget {
  const GreetingGauntletPreview({
    super.key,
    required this.phaseLabel,
    required this.body,
  });

  final String phaseLabel;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(phaseLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

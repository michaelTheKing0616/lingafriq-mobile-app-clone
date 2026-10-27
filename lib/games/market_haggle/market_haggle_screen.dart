import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../games/gamekit/game_scoring.dart';
import '../../screens/pronunciation/tone_overlay_view.dart';
import '../../providers/dio_provider.dart' show client;
import '../../services/ai_gateway_client.dart';
import '../../services/feature_flag_service.dart';
import '../../services/lens/lens_scoring_client.dart';
import '../../services/voice/audio_recording_service.dart';
import '../../utils/pan_african_design_system.dart';
import 'haggle_rubric.dart';
import 'market_haggle_game.dart';
import 'trader_personalities.dart';

enum MarketHagglePhase {
  loading,
  ready,
  playing,
  counter,
  speak,
  correct,
  wrong,
  whyWrong,
  results,
  error,
  offline,
  practiceMode,
  traderThinking,
  scorerUnsure,
}

/// Flagship Market Haggle (P8-922): voice + register phrases + price rubric.
class MarketHaggleScreen extends ConsumerStatefulWidget {
  const MarketHaggleScreen({
    super.key,
    required this.language,
    this.onBack,
  });

  final String language;
  final VoidCallback? onBack;

  @override
  ConsumerState<MarketHaggleScreen> createState() => _MarketHaggleScreenState();
}

class _MarketHaggleScreenState extends ConsumerState<MarketHaggleScreen> {
  static const title = 'Market Haggle';
  static const instructions =
      'Greet the trader respectfully, then offer a fair price in numbers.';
  static const whyWrongCopy =
      'Elders expect honorific greetings before business. Try the formal line.';
  static const practiceLabel =
      'Practice — pronunciation scores do not count until the scorer is live.';
  static const errorCopy =
      'We could not load this market round. Check your connection and try again.';

  final AudioRecordingService _recorder = AudioRecordingService();
  MarketHagglePhase _phase = MarketHagglePhase.loading;
  String? _loadError;
  List<HagglePhraseChoice> _phrases = const [];
  MarketHaggleRoundPlan? _plan;
  PriceHaggleState? _priceState;
  HagglePhraseChoice? _greetingPick;
  int? _counterPick;
  HaggleRoundScore? _lastScore;
  String _traderLine = '';
  bool _traderLineIsAi = false;
  bool _practiceNotScored = true;
  bool _scorerUnsure = false;
  List<int> _counterOptions = const [];
  int _round = 0;
  static const _maxRounds = 3;

  @override
  void initState() {
    super.initState();
    _resolvePracticeMode();
    unawaited(_bootstrap());
  }

  void _resolvePracticeMode() {
    final flagOn = FeatureFlagService(safeDefault: false).isOn(
      gameKitRealSpeakingScorerFlagKey,
      DateTime.now(),
    );
    final live = gameKitRealScorerLiveForGame(
      featureFlagOn: flagOn,
      gameId: 'market_bargaining_simulator',
      isSpeakingGame: true,
    );
    _practiceNotScored = gameKitPracticeNotScoredMode(
      isSpeakingGame: true,
      realScorerLive: live,
    );
  }

  Future<void> _bootstrap() async {
    try {
      _phrases = await loadHagglePhrasesForLanguage(widget.language);
      if (_phrases.length < 2) {
        setState(() {
          _phase = MarketHagglePhase.error;
          _loadError = 'Register phrases are not ready for this language yet.';
        });
        return;
      }
      await _startRound();
    } catch (_) {
      setState(() {
        _phase = MarketHagglePhase.error;
        _loadError = errorCopy;
      });
    }
  }

  Future<void> _startRound() async {
    if (_round >= _maxRounds) {
      setState(() => _phase = MarketHagglePhase.results);
      return;
    }
    _round++;
    final plan = buildRoundPlan(
      languageCode: widget.language,
      phrases: _phrases,
      rng: Random(),
    );
    _plan = plan;
    _priceState = initialPriceState(
      trader: plan.trader,
      floorPrice: plan.floorPrice,
      learnerBudget: plan.learnerBudget,
    );
    _greetingPick = null;
    _counterPick = null;
    _lastScore = null;
    _scorerUnsure = false;
    _traderLine = plan.trader.openingLineEn;
    _traderLineIsAi = false;
    setState(() {
      _phase = _practiceNotScored
          ? MarketHagglePhase.practiceMode
          : MarketHagglePhase.ready;
    });
    unawaited(_maybeFetchAiTraderLine(plan));
  }

  Future<void> _maybeFetchAiTraderLine(MarketHaggleRoundPlan plan) async {
    setState(() => _phase = MarketHagglePhase.traderThinking);
    try {
      final dio = ref.read(client);
      final gateway = AiGatewayClient(dio);
      final data = await gateway.completeChat(
        mode: AiGatewayClient.gatewayModeForPolie('roleplay'),
        messages: [
          {
            'role': 'user',
            'content':
                'You are ${plan.trader.displayNameEn} at a market stall. '
                'Reply in one short English sentence inviting a respectful greeting '
                'before discussing price. JSON: {"line":"..."}',
          },
        ],
        languageCode: widget.language,
        maxTokens: 120,
      );
      final content = gateway.extractContent(data);
      if (content.trim().isNotEmpty) {
        setState(() {
          _traderLine = content.trim();
          _traderLineIsAi = true;
          _phase = MarketHagglePhase.playing;
        });
        return;
      }
    } catch (_) {
      // Scripted fallback (AC5 labels AI only when gateway succeeds).
    }
    if (mounted) {
      setState(() => _phase = MarketHagglePhase.playing);
    }
  }

  void _pickGreeting(HagglePhraseChoice choice) {
    if (_phase != MarketHagglePhase.playing && _phase != MarketHagglePhase.practiceMode) {
      return;
    }
    HapticFeedback.selectionClick();
    final plan = _plan!;
    final state = _priceState!;
    final next = applyGreetingMove(
      state: state,
      choice: choice,
      trader: plan.trader,
    );
    _greetingPick = choice;
    _priceState = next;
    _counterOptions = buildCounterOffers(
      currentAsk: next.currentAsk,
      floorPrice: next.floorPrice,
      learnerBudget: next.learnerBudget,
    );
    setState(() => _phase = MarketHagglePhase.counter);
  }

  void _pickCounter(int offer) {
    final plan = _plan!;
    final state = _priceState!;
    final next = applyCounterOffer(state: state, offerNaira: offer);
    _counterPick = offer;
    _priceState = next;
    setState(() => _phase = MarketHagglePhase.speak);
  }

  Future<void> _holdSpeakStart() async {
    final granted = await _recorder.requestPermission();
    if (!granted) {
      setState(() {
        _phase = MarketHagglePhase.error;
        _loadError = 'Microphone access is needed to practice speaking.';
      });
      return;
    }
    await _recorder.startRecording();
  }

  Future<void> _finishSpeak() async {
    final path = await _recorder.stopRecording();
    final greeting = _greetingPick;
    if (greeting == null) return;

    if (_practiceNotScored) {
      _finishRoundWithoutScorer(greeting);
      return;
    }

    if (path == null) {
      setState(() {
        _scorerUnsure = true;
        _phase = MarketHagglePhase.scorerUnsure;
      });
      return;
    }

    final scorer = LensScoringClient();
    final dio = ref.read(client);
    final outcome = await scorer.scoreUtterance(
      post: (p, data) => dio.post(p, data: data),
      audioPath: path,
      expectedText: greeting.phraseText,
      language: widget.language,
    );
    if (outcome.phase == ToneOverlayStatus.unsure) {
      setState(() {
        _scorerUnsure = true;
        _phase = MarketHagglePhase.scorerUnsure;
      });
      return;
    }
    if (outcome.phase == ToneOverlayStatus.error) {
      setState(() => _phase = MarketHagglePhase.offline);
      return;
    }
    _finishRoundWithoutScorer(greeting);
  }

  void _finishRoundWithoutScorer(HagglePhraseChoice greeting) {
    final score = scoreRound(
      finalState: _priceState!,
      greetingChoice: greeting,
      counterOffer: _counterPick,
    );
    _lastScore = score;
    final politeFail = score.impolitePhraseNamed != null;
    setState(() {
      _phase = politeFail
          ? MarketHagglePhase.whyWrong
          : (score.goalAchieved >= 1 ? MarketHagglePhase.correct : MarketHagglePhase.wrong);
    });
  }

  void _advanceRound() {
    unawaited(_startRound());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('$title · $_round / $_maxRounds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: switch (_phase) {
        MarketHagglePhase.loading ||
        MarketHagglePhase.traderThinking =>
          const Center(child: CircularProgressIndicator()),
        MarketHagglePhase.error => _StateMessage(
            message: _loadError ?? errorCopy,
            actionLabel: 'Try again',
            onAction: () {
              setState(() => _phase = MarketHagglePhase.loading);
              unawaited(_bootstrap());
            },
          ),
        MarketHagglePhase.offline => _StateMessage(
            message:
                'Pronunciation scoring is unavailable. You can keep practising without a ranked score.',
            actionLabel: 'Continue',
            onAction: _advanceRound,
          ),
        MarketHagglePhase.scorerUnsure => _StateMessage(
            message:
                'We are not sure about that pronunciation yet. No score was saved — try again or continue practising.',
            actionLabel: 'Continue',
            onAction: _advanceRound,
          ),
        MarketHagglePhase.results => _buildResults(context),
        _ => Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_practiceNotScored) const _PracticeBanner(label: practiceLabel),
                Text(
                  instructions,
                  style: PanAfricanTypography.bodyMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                _TraderBubble(
                  line: _traderLine,
                  showAiLabel: _traderLineIsAi,
                  ask: _priceState?.currentAsk,
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Expanded(child: _bodyForPhase(context)),
              ],
            ),
          ),
      },
    );
  }

  Widget _bodyForPhase(BuildContext context) {
    switch (_phase) {
      case MarketHagglePhase.playing:
      case MarketHagglePhase.practiceMode:
      case MarketHagglePhase.ready:
        return _greetingPicker(context);
      case MarketHagglePhase.counter:
        return _counterPicker(context);
      case MarketHagglePhase.speak:
        return _speakStep(context);
      case MarketHagglePhase.whyWrong:
        return _whyWrong(context);
      case MarketHagglePhase.correct:
      case MarketHagglePhase.wrong:
        return _roundSummary(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _greetingPicker(BuildContext context) {
    final options = _plan?.greetingOptions ?? const [];
    return ListView(
      children: [
        Text(
          'How do you greet the trader first?',
          style: PanAfricanTypography.titleMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        ...options.map((opt) {
          return Padding(
            padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
            child: Semantics(
              button: true,
              label: '${opt.phraseText}. ${opt.translationEn}',
              child: FilledButton.tonal(
                onPressed: () => _pickGreeting(opt),
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(48.h),
                ),
                child: Column(
                  children: [
                    Text(opt.phraseText, textAlign: TextAlign.center),
                    Text(
                      opt.translationEn,
                      style: PanAfricanTypography.bodySmall(context),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _counterPicker(BuildContext context) {
    return ListView(
      children: [
        Text(
          'Offer a price (₦) within your budget of ₦${_priceState?.learnerBudget ?? 0}',
          style: PanAfricanTypography.titleMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        ..._counterOptions.map((offer) {
          return Padding(
            padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
            child: Semantics(
              button: true,
              label: 'Offer ₦$offer',
              child: FilledButton(
                onPressed: () => _pickCounter(offer),
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(48.h),
                ),
                child: Text('₦$offer'),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _speakStep(BuildContext context) {
    final text = _greetingPick?.phraseText ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Say your greeting out loud',
          style: PanAfricanTypography.titleMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(text, style: PanAfricanTypography.headlineSmall(context), textAlign: TextAlign.center),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Hold to speak greeting',
          child: Listener(
            onPointerDown: (_) => unawaited(_holdSpeakStart()),
            onPointerUp: (_) => unawaited(_finishSpeak()),
            onPointerCancel: (_) => unawaited(_finishSpeak()),
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.mic),
              label: const Text('Hold to speak'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _whyWrong(BuildContext context) {
    final named = _lastScore?.impolitePhraseNamed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(whyWrongCopy, style: PanAfricanTypography.bodyMedium(context)),
        if (named != null) ...[
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            '“$named” sounded too informal for an elder trader.',
            style: PanAfricanTypography.bodySmall(context),
          ),
        ],
        const Spacer(),
        FilledButton(
          onPressed: _advanceRound,
          child: const Text('Next stall'),
        ),
      ],
    );
  }

  Widget _roundSummary(BuildContext context) {
    final score = _lastScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (score != null) ...[
          _ScoreRow(label: 'Goal', value: score.goalAchieved),
          _ScoreRow(label: 'Politeness', value: score.politeness),
          _ScoreRow(label: 'Correctness', value: score.correctness),
        ],
        if (_scorerUnsure)
          Text(
            'Pronunciation: unsure — no number stored.',
            style: PanAfricanTypography.bodySmall(context),
          ),
        const Spacer(),
        FilledButton(
          onPressed: _advanceRound,
          child: const Text('Next stall'),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    return _StateMessage(
      message: 'You worked the market with respect and clear numbers. Well done.',
      actionLabel: 'Done',
      onAction: widget.onBack ?? () => Navigator.of(context).pop(),
    );
  }
}

class _TraderBubble extends StatelessWidget {
  const _TraderBubble({
    required this.line,
    required this.showAiLabel,
    this.ask,
  });

  final String line;
  final bool showAiLabel;
  final int? ask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAiLabel)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'AI trader voice',
                  style: theme.labelSmall,
                ),
              ),
            Text(line, style: theme.bodyLarge),
            if (ask != null) ...[
              const SizedBox(height: 4),
              Text('Ask: ₦$ask', style: theme.titleSmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$pct%'),
        ],
      ),
    );
  }
}

class _PracticeBanner extends StatelessWidget {
  const _PracticeBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Text(
        label,
        style: PanAfricanTypography.labelMedium(context),
      ),
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

/// Key states for goldens (P8-922).
class MarketHagglePreview extends StatelessWidget {
  const MarketHagglePreview({
    super.key,
    required this.phaseLabel,
    required this.traderLine,
    required this.showAi,
    required this.ask,
    required this.body,
  });

  final String phaseLabel;
  final String traderLine;
  final bool showAi;
  final int ask;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(phaseLabel, style: titleStyle),
            _TraderBubble(line: traderLine, showAiLabel: showAi, ask: ask),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

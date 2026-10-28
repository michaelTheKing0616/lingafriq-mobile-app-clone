import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../games/gamekit/all_games_registry.dart';
import '../../games/gamekit/game_difficulty.dart';
import '../../games/gamekit/game_feedback.dart';
import '../../games/gamekit/game_result.dart';
import '../../games/gamekit/game_scoring.dart';
import '../../screens/pronunciation/tone_overlay_view.dart';
import '../../games/gamekit/game_session.dart' as gamekit_session;
import '../../games/gamekit/game_turn_context.dart';
import '../../learning/pronunciation/tone_models.dart';
import '../../providers/dio_provider.dart' show client;
import '../../services/feature_flag_service.dart';
import '../../services/lens/lens_scoring_client.dart';
import '../../services/voice/audio_recording_service.dart';
import '../../utils/pan_african_design_system.dart';
import '../tone_forge/tone_forge_models.dart';
import 'contour_overlay.dart';
import 'drum_timbre_synth.dart';
import 'talking_drum_game.dart';

enum _TalkingDrumPhase { loading, perception, whyWrong, production, results, error, offline }

/// Flagship Talking Drum — lexicon tones + real scorer overlay (P8-920).
class TalkingDrumScreen extends ConsumerStatefulWidget {
  const TalkingDrumScreen({
    super.key,
    required this.language,
    this.level,
    this.onBack,
  });

  final String language;
  final String? level;
  final VoidCallback? onBack;

  @override
  ConsumerState<TalkingDrumScreen> createState() => _TalkingDrumScreenState();
}

class _TalkingDrumScreenState extends ConsumerState<TalkingDrumScreen> {
  final DrumTimbreSynth _synth = DrumTimbreSynth();
  final AudioRecordingService _recorder = AudioRecordingService();
  final GameKitLearnerGraphWriter _graphWriter = GameKitLearnerGraphWriter();

  _TalkingDrumPhase _phase = _TalkingDrumPhase.loading;
  String? _loadError;
  ToneLanguageModel? _inventory;
  List<ToneGameLexeme> _pool = const [];
  TalkingDrumPerceptionTurn? _turn;
  ToneGameLexeme? _currentLexeme;
  String? _selectedId;
  bool _showVerdict = false;
  bool _lastCorrect = false;
  List<double>? _learnerContour;
  bool _scorerUnsure = false;
  bool _practiceNotScored = true;
  int _round = 0;
  static const int _maxRounds = 5;
  late gamekit_session.GameSession _kitSession;
  int _turnCounter = 0;

  @override
  void initState() {
    super.initState();
    _kitSession = gamekit_session.GameSession(
      sessionId: 'talking_drum_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'local',
      gameId: AllGamesRegistry.talkingDrumGameId,
      language: widget.language,
      startTime: DateTime.now(),
    );
    _resolvePracticeMode();
    _bootstrap();
  }

  @override
  void dispose() {
    _synth.cancel();
    super.dispose();
  }

  void _resolvePracticeMode() {
    final flagOn = FeatureFlagService(safeDefault: false).isOn(
      gameKitRealSpeakingScorerFlagKey,
      DateTime.now(),
    );
    final live = gameKitRealScorerLiveForGame(
      featureFlagOn: flagOn,
      gameId: AllGamesRegistry.talkingDrumGameId,
      isSpeakingGame: true,
    );
    _practiceNotScored = gameKitPracticeNotScoredMode(
      isSpeakingGame: true,
      realScorerLive: live,
    );
  }

  Future<void> _bootstrap() async {
    try {
      final lang = widget.language.toLowerCase();
      final catalog = await loadToneModelsCatalogFromAsset();
      if (!isToneTrainerAvailable(catalog, lang)) {
        setState(() {
          _phase = _TalkingDrumPhase.error;
          _loadError = 'Talking Drum is not available for this language yet.';
        });
        return;
      }
      final pool = await buildToneGamePool(
        catalog: catalog,
        languageCode: lang,
        fetchLimit: 40,
      );
      _inventory = pool.inventory;
      _pool = pool.lexemes;
      if (_pool.length < 3 || _inventory == null) {
        setState(() {
          _phase = _TalkingDrumPhase.error;
          _loadError =
              'No verified tone-marked phrases are ready yet. Check back after more lexicon review.';
        });
        return;
      }
      await _loadNextTurn();
    } catch (_) {
      setState(() {
        _phase = _TalkingDrumPhase.error;
        _loadError = 'We could not load Talking Drum. Check your connection and try again.';
      });
    }
  }

  Future<void> _loadNextTurn() async {
    if (_round >= _maxRounds) {
      setState(() => _phase = _TalkingDrumPhase.results);
      return;
    }
    final rng = Random();
    final lexeme = _pool[rng.nextInt(_pool.length)];
    final turn = buildTalkingDrumPerceptionTurn(
      lexeme: lexeme,
      pool: _pool,
      inventory: _inventory!,
      rng: rng,
    );
    if (turn == null) {
      setState(() {
        _phase = _TalkingDrumPhase.error;
        _loadError = 'Could not build a tone-safe drum round.';
      });
      return;
    }
    _round++;
    _currentLexeme = lexeme;
    _turn = turn;
    _selectedId = null;
    _showVerdict = false;
    _learnerContour = null;
    _scorerUnsure = false;
    setState(() => _phase = _TalkingDrumPhase.perception);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    await _synth.playContour(turn.contour, reducedMotion: reduceMotion);
  }

  void _pickCandidate(String lexemeId) {
    if (_showVerdict || _turn == null) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedId = lexemeId);
    final correct = talkingDrumPerceptionIsCorrect(
      selectedLexemeId: lexemeId,
      correctLexemeId: _turn!.correctLexemeId,
    );
    final started = DateTime.now();
    scheduleMicrotask(() {
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      assert(elapsed <= GameKitFeedbackBudget.tapToFeedbackP95Ms + 50);
      setState(() {
        _lastCorrect = correct;
        _showVerdict = true;
        _phase = correct ? _TalkingDrumPhase.production : _TalkingDrumPhase.whyWrong;
      });
      _recordPerceptionTurn(correct);
    });
  }

  Future<void> _recordPerceptionTurn(bool correct) async {
    final q = _currentLexeme;
    if (q == null) return;
    final score = correct
        ? GameScore.correct(accuracy: 1)
        : GameScore.incorrect(accuracy: 0);
    final context = GameTurnContext(
      content: q,
      input: _selectedId,
      session: _kitSession,
      metadata: {
        'itemId': q.lexemeId,
        'skillId': 'tone:${q.language}',
        'gameCategory': 'listening',
      },
    );
    final result = GameTurnResult(
      score: _practiceNotScored && !correct
          ? GameScore.honestPractice(message: 'Practice — scores are not ranked yet.')
          : score,
      feedback: GameFeedback.neutral(
        message: correct ? 'You heard the contour.' : 'Listen to the drum tones again.',
        animationEvent: AnimationEvent.listening,
      ),
      difficultyUpdate: GameDifficultyUpdate.maintain(),
      timestamp: DateTime.now(),
    );
    _kitSession = await _graphWriter.recordTurn(
      session: _kitSession,
      context: context,
      result: result,
      turnId: 'td_${_turnCounter++}',
      queueOnly: true,
    );
  }

  Future<void> _startProduction() async {
    if (_currentLexeme == null) return;
    final granted = await _recorder.requestPermission();
    if (!granted) {
      setState(() {
        _phase = _TalkingDrumPhase.error;
        _loadError = 'Microphone access is needed to practice speaking.';
      });
      return;
    }
    setState(() => _phase = _TalkingDrumPhase.production);
  }

  Future<void> _finishRecording() async {
    final path = await _recorder.stopRecording();
    final lexeme = _currentLexeme;
    if (path == null || lexeme == null) {
      setState(() {
        _scorerUnsure = true;
        _phase = _TalkingDrumPhase.production;
      });
      return;
    }
    final scorer = const LensScoringClient();
    final dio = ref.read(client);
    final outcome = await scorer.scoreUtterance(
      post: (p, data) => dio.post(p, data: data),
      audioPath: path,
      expectedText: lexeme.toneMarkedForm,
      language: lexeme.language,
    );
    if (outcome.phase == ToneOverlayStatus.unsure) {
      setState(() {
        _scorerUnsure = true;
        _learnerContour = null;
      });
      return;
    }
    if (outcome.phase == ToneOverlayStatus.error) {
      setState(() {
        _scorerUnsure = true;
        _phase = _TalkingDrumPhase.offline;
      });
      return;
    }
    final heights = <double>[];
    for (final s in outcome.syllables) {
      if (s.learnerContour.isEmpty) {
        heights.add(0.5);
      } else {
        final sum = s.learnerContour.fold<double>(0, (a, b) => a + b);
        heights.add(sum / s.learnerContour.length);
      }
    }
    setState(() {
      _learnerContour = learnerContourFromSyllableHeights(heights);
      _scorerUnsure = false;
    });
  }

  Future<void> _holdSpeakStart() async {
    await _recorder.startRecording();
  }

  @override
  Widget build(BuildContext context) {
    final l10nTitle = 'Talking Drum';
    return Scaffold(
      appBar: AppBar(
        title: Text('$l10nTitle · $_round / $_maxRounds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: switch (_phase) {
        _TalkingDrumPhase.loading => const Center(child: CircularProgressIndicator()),
        _TalkingDrumPhase.error => _MessageState(message: _loadError ?? 'Something went wrong.'),
        _TalkingDrumPhase.offline => _MessageState(
            message:
                'Pronunciation scoring is unavailable. Practice mode only — no ranked score.',
            actionLabel: 'Continue',
            onAction: _loadNextTurn,
          ),
        _TalkingDrumPhase.results => _MessageState(
            message: 'Nice work — your ear and voice are getting sharper.',
            actionLabel: 'Done',
            onAction: () => Navigator.of(context).pop(),
          ),
        _ => Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_practiceNotScored) const _PracticeBanner(),
                if (_turn != null) ...[
                  Text(
                    _turn!.rhythmCue,
                    style: PanAfricanTypography.labelLarge(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  TalkingDrumContourOverlay(
                    nativeContour: _turn!.contour,
                    learnerContour: _learnerContour,
                    unsure: _scorerUnsure,
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                ],
                Expanded(child: _bodyForPhase(context)),
              ],
            ),
          ),
      },
    );
  }

  Widget _bodyForPhase(BuildContext context) {
    switch (_phase) {
      case _TalkingDrumPhase.perception:
        return _buildPerception(context);
      case _TalkingDrumPhase.whyWrong:
        return _buildWhyWrong(context);
      case _TalkingDrumPhase.production:
        return _buildProduction(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPerception(BuildContext context) {
    final turn = _turn!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Which phrase matches the drum tones?',
          style: PanAfricanTypography.titleMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        ...turn.candidates.map((c) {
          final selected = _selectedId == c.lexemeId;
          return Padding(
            padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
            child: Semantics(
              button: true,
              label: c.label,
              child: FilledButton.tonal(
                onPressed: _showVerdict ? null : () => _pickCandidate(c.lexemeId),
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(48.h),
                  backgroundColor: selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                child: Text(c.label, textAlign: TextAlign.center),
              ),
            ),
          );
        }),
        if (_showVerdict && _lastCorrect)
          FilledButton(
            onPressed: _startProduction,
            child: const Text('Speak the phrase'),
          ),
      ],
    );
  }

  Widget _buildWhyWrong(BuildContext context) {
    final correct = _currentLexeme?.toneMarkedForm ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.hearing_rounded, size: 40.sp, color: PanAfricanColors.primary),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(
          'The drum was asking for:',
          style: PanAfricanTypography.titleSmall(context),
        ),
        Text(
          correct,
          style: PanAfricanTypography.headlineSmall(context),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: PanAfricanSpacing.md),
        FilledButton(
          onPressed: _loadNextTurn,
          child: const Text('Try another contour'),
        ),
      ],
    );
  }

  Widget _buildProduction(BuildContext context) {
    final lexeme = _currentLexeme!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lexeme.toneMarkedForm,
          style: PanAfricanTypography.displaySmall(context),
          textAlign: TextAlign.center,
        ),
        if (lexeme.englishGloss != null)
          Text(
            lexeme.englishGloss!,
            textAlign: TextAlign.center,
            style: PanAfricanTypography.bodyMedium(context),
          ),
        SizedBox(height: PanAfricanSpacing.lg),
        Semantics(
          button: true,
          label: 'Hold to speak the phrase',
          child: Listener(
            onPointerDown: (_) => _holdSpeakStart(),
            onPointerUp: (_) => _finishRecording(),
            onPointerCancel: (_) => _finishRecording(),
            child: Container(
              height: 56.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              ),
              child: Text(
                'Hold to speak',
                style: PanAfricanTypography.labelLarge(context).copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
        if (_scorerUnsure)
          Padding(
            padding: EdgeInsets.only(top: PanAfricanSpacing.md),
            child: Text(
              'We could not score this clearly. Practice mode — try again when you are ready.',
              style: PanAfricanTypography.bodySmall(context),
            ),
          ),
        SizedBox(height: PanAfricanSpacing.md),
        OutlinedButton(
          onPressed: _loadNextTurn,
          child: const Text('Next drum'),
        ),
      ],
    );
  }
}

class _PracticeBanner extends StatelessWidget {
  const _PracticeBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Text(
        'Practice mode — ranked scores unlock when the live scorer is on.',
        style: PanAfricanTypography.labelMedium(context),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: PanAfricanSpacing.md),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

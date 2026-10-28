import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../talking_drum/contour_overlay.dart';
import 'echo_karaoke_game.dart';
import 'pitch_line_view.dart';
import 'song_catalog.dart';

enum EchoKaraokePhase {
  loading,
  songsPending,
  ready,
  playing,
  whyWrong,
  results,
  error,
  offline,
  practiceMode,
  scorerUnsure,
}

/// Flagship Echo Karaoke (P8-929).
class EchoKaraokeScreen extends ConsumerStatefulWidget {
  const EchoKaraokeScreen({
    super.key,
    required this.language,
    this.onBack,
    this.initialPhase,
    this.previewPiece,
  });

  static const title = 'Echo Karaoke';
  static const instructions =
      'Follow the pitch line and sing the phrase with the scrolling words.';
  static const whyWrongCopy =
      'Your pitch drifted from the target contour — listen and try a smoother line.';
  static const practiceLabel =
      'Practice — ranked scores need a verified pronunciation check.';
  static const errorCopy =
      'We could not load songs for this language yet. Check your connection and try again.';
  static const songsPendingCopy =
      'Licensed songs are on the way. You can still practice with cleared study phrases when they appear here.';

  final String language;
  final VoidCallback? onBack;
  final EchoKaraokePhase? initialPhase;
  final EchoKaraokePiece? previewPiece;

  @override
  ConsumerState<EchoKaraokeScreen> createState() => _EchoKaraokeScreenState();
}

class _EchoKaraokeScreenState extends ConsumerState<EchoKaraokeScreen> {
  final AudioRecordingService _recorder = AudioRecordingService();
  final GameKitLearnerGraphWriter _graphWriter = GameKitLearnerGraphWriter();

  EchoKaraokePhase _phase = EchoKaraokePhase.loading;
  List<EchoKaraokePiece> _catalog = const [];
  EchoKaraokePiece? _piece;
  ToneLanguageModel? _toneModel;
  List<double> _targetContour = const [];
  double _scrollProgress = 0;
  Timer? _scrollTimer;
  StreamSubscription<double>? _ampSub;
  List<double> _liveSamples = const [];
  List<double>? _learnerContour;
  EchoRoundScores? _scores;
  bool _practiceNotScored = true;
  bool _scorerUnsure = false;
  String? _loadError;
  late gamekit_session.GameSession _kitSession;
  int _turnCounter = 0;

  @override
  void initState() {
    super.initState();
    _kitSession = gamekit_session.GameSession(
      sessionId: 'echo_karaoke_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'local',
      gameId: AllGamesRegistry.echoKaraokeGameId,
      language: widget.language,
      startTime: DateTime.now(),
    );
    if (widget.initialPhase != null) {
      _phase = widget.initialPhase!;
      _piece = widget.previewPiece;
      if (_piece != null) {
        _targetContour = List<double>.filled(_piece!.tonePattern.length, 0.5);
      }
    } else {
      _resolvePracticeMode();
      unawaited(_bootstrap());
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void _resolvePracticeMode() {
    final flagOn = FeatureFlagService(safeDefault: false).isOn(
      gameKitRealSpeakingScorerFlagKey,
      DateTime.now(),
    );
    final live = gameKitRealScorerLiveForGame(
      featureFlagOn: flagOn,
      gameId: AllGamesRegistry.echoKaraokeGameId,
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
      final toneCatalog = await loadToneModelsCatalogFromAsset();
      if (!isToneTrainerAvailable(toneCatalog, lang)) {
        setState(() {
          _phase = EchoKaraokePhase.songsPending;
          _catalog = licensedPiecesForLanguage(lang);
        });
        return;
      }
      _toneModel = resolveToneModel(toneCatalog, lang);
      _catalog = licensedPiecesForLanguage(lang);
      if (_catalog.isEmpty) {
        setState(() => _phase = EchoKaraokePhase.songsPending);
        return;
      }
      _piece = _catalog.first;
      _targetContour = targetContourForPiece(_piece!, _toneModel!);
      setState(() {
        _phase = _practiceNotScored
            ? EchoKaraokePhase.practiceMode
            : EchoKaraokePhase.ready;
      });
    } catch (e) {
      setState(() {
        _phase = EchoKaraokePhase.error;
        _loadError = EchoKaraokeScreen.errorCopy;
      });
    }
  }

  void _startRound() {
    final piece = _piece;
    if (piece == null) return;
    setState(() {
      _phase = EchoKaraokePhase.playing;
      _scrollProgress = 0;
      _liveSamples = const [];
      _learnerContour = null;
      _scores = null;
      _scorerUnsure = false;
    });
    _scrollTimer?.cancel();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduceMotion) {
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 80), (t) {
        if (!mounted) return;
        setState(() {
          _scrollProgress = (_scrollProgress + 0.02).clamp(0.0, 1.0);
          if (_scrollProgress >= 1.0) {
            t.cancel();
          }
        });
      });
    } else {
      setState(() => _scrollProgress = 1.0);
    }
  }

  Future<void> _holdMicDown() async {
    HapticFeedback.lightImpact();
    final granted = await _recorder.requestPermission();
    if (!granted) {
      setState(() {
        _phase = EchoKaraokePhase.error;
        _loadError = 'Microphone access is needed to sing along.';
      });
      return;
    }
    await _recorder.startRecording();
    _ampSub?.cancel();
    _ampSub = _recorder.amplitudeStream.listen((amp) {
      if (!mounted) return;
      final idx = playheadIndexForProgress(
        progress: _scrollProgress,
        syllableCount: _piece?.tonePattern.length ?? 1,
      );
      final targetSlice = _targetContour.isEmpty
          ? const <double>[0.5]
          : [_targetContour[idx.clamp(0, _targetContour.length - 1)]];
      setState(() {
        _liveSamples = appendLivePitchSample(
          samples: _liveSamples,
          normalisedAmplitude: amp,
          targetAtPlayhead: targetSlice,
        );
      });
    });
  }

  Future<void> _releaseMic() async {
    _ampSub?.cancel();
    final path = await _recorder.stopRecording();
    final piece = _piece;
    final model = _toneModel;
    if (path == null || piece == null || model == null) {
      setState(() {
        _scorerUnsure = true;
        _phase = EchoKaraokePhase.scorerUnsure;
      });
      return;
    }

    final scorer = const LensScoringClient();
    final dio = ref.read(client);
    final outcome = await scorer.scoreUtterance(
      post: (p, data) => dio.post(p, data: data),
      audioPath: path,
      expectedText: piece.lyrics,
      language: piece.languageCode,
    );

    if (outcome.phase == ToneOverlayStatus.error) {
      setState(() => _phase = EchoKaraokePhase.offline);
      return;
    }

    if (outcome.phase == ToneOverlayStatus.unsure) {
      setState(() {
        _scorerUnsure = true;
        _scores = scoresFromScorerAccuracy(
          accuracy: 0,
          practiceOnly: true,
        );
        _phase = EchoKaraokePhase.scorerUnsure;
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
    final learner = learnerContourFromSyllableHeights(heights);
    final aligned = resampleContour(learner, _targetContour.length);
    final alignment = pitchAlignmentScore(target: _targetContour, learner: aligned);

    final gameScore = gameScoreFromScorerResponse(
      body: const {},
      outcome: outcome,
    );
    final practice = _practiceNotScored || gameScore.source != GameScoreSource.realScorer;
    _scores = scoresFromScorerAccuracy(
      accuracy: gameScore.accuracy,
      practiceOnly: practice,
    );

    setState(() {
      _learnerContour = aligned;
      _scorerUnsure = gameScore.isUnsure;
    });

    await _recordGraphTurn(gameScore, alignment);

    if (!gameScore.isUnsure && gameScore.accuracy < 0.55) {
      setState(() => _phase = EchoKaraokePhase.whyWrong);
    } else {
      setState(() => _phase = EchoKaraokePhase.results);
    }
  }

  Future<void> _recordGraphTurn(GameScore gameScore, double alignment) async {
    final piece = _piece;
    if (piece == null) return;
    final turnId = 'ek_${_turnCounter++}';
    final context = GameTurnContext(
      content: piece.lyrics,
      input: alignment.toStringAsFixed(2),
      session: _kitSession,
      metadata: {
        'itemId': piece.id,
        'skillId': 'speaking:${piece.languageCode}',
        'gameCategory': 'speaking',
        'requiresServerScoring': true,
      },
    );
    final result = GameTurnResult(
      score: _practiceNotScored
          ? GameScore.honestPractice(
              message: EchoKaraokeScreen.practiceLabel,
            )
          : gameScore,
      feedback: GameFeedback.neutral(
        message: 'Nice effort on the pitch line.',
        animationEvent: AnimationEvent.speaking,
      ),
      difficultyUpdate: GameDifficultyUpdate.maintain(),
      timestamp: DateTime.now(),
    );
    _kitSession = await _graphWriter.recordTurn(
      session: _kitSession,
      context: context,
      result: result,
      turnId: turnId,
      queueOnly: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: PanAfricanColors.surface,
      appBar: AppBar(
        title: const Text(EchoKaraokeScreen.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: switch (_phase) {
          EchoKaraokePhase.loading => const Center(child: CircularProgressIndicator()),
          EchoKaraokePhase.songsPending => _StateMessage(
              message: EchoKaraokeScreen.songsPendingCopy,
              actionLabel: 'Go back',
              onAction: widget.onBack ?? () => Navigator.of(context).maybePop(),
            ),
          EchoKaraokePhase.error => _StateMessage(
              message: _loadError ?? EchoKaraokeScreen.errorCopy,
              actionLabel: 'Try again',
              onAction: () {
                setState(() => _phase = EchoKaraokePhase.loading);
                unawaited(_bootstrap());
              },
            ),
          EchoKaraokePhase.offline => _StateMessage(
              message:
                  'Pronunciation scoring is offline. Practice only — no ranked score.',
              actionLabel: 'Continue',
              onAction: () => setState(() => _phase = EchoKaraokePhase.results),
            ),
          EchoKaraokePhase.results => _buildResults(context),
          EchoKaraokePhase.whyWrong => _buildWhyWrong(context, reduceMotion),
          _ => _buildPlaying(context, reduceMotion),
        },
      ),
    );
  }

  Widget _buildPlaying(BuildContext context, bool reduceMotion) {
    final piece = _piece;
    if (piece == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_practiceNotScored)
            Padding(
              padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
              child: Text(
                EchoKaraokeScreen.practiceLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Text(
            EchoKaraokeScreen.instructions,
            style: PanAfricanTypography.bodyMedium(context),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          Text(
            piece.translationEn,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          PitchLineView(
            lyrics: piece.lyrics,
            targetContour: _targetContour,
            learnerContour: _learnerContour,
            liveSamples: _liveSamples,
            progress: _scrollProgress,
            unsure: _scorerUnsure,
            reduceMotion: reduceMotion,
          ),
          const Spacer(),
          if (_phase == EchoKaraokePhase.ready ||
              _phase == EchoKaraokePhase.practiceMode)
            FilledButton(
              onPressed: _startRound,
              child: const Text('Start phrase'),
            )
          else ...[
            Semantics(
              button: true,
              label: 'Hold to sing along',
              child: Listener(
                onPointerDown: (_) => unawaited(_holdMicDown()),
                onPointerUp: (_) => unawaited(_releaseMic()),
                onPointerCancel: (_) => unawaited(_releaseMic()),
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.mic),
                    label: const Text('Hold to sing'),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWhyWrong(BuildContext context, bool reduceMotion) {
    final piece = _piece!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            EchoKaraokeScreen.whyWrongCopy,
            style: PanAfricanTypography.bodyLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          PitchLineView(
            lyrics: piece.lyrics,
            targetContour: _targetContour,
            learnerContour: _learnerContour,
            unsure: _scorerUnsure,
            progress: 1,
            reduceMotion: reduceMotion,
          ),
          SizedBox(height: PanAfricanSpacing.xl),
          FilledButton(
            onPressed: () => setState(() => _phase = EchoKaraokePhase.results),
            child: const Text('See results'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final scores = _scores;
    return SingleChildScrollView(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Phrase complete',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (scores != null) ...[
            SizedBox(height: PanAfricanSpacing.md),
            _ScoreRow(label: 'Tone', value: scores.tone),
            _ScoreRow(label: 'Rhythm', value: scores.rhythm),
            _ScoreRow(label: 'Fluency', value: scores.fluency),
          ],
          if (_practiceNotScored || scores?.practiceOnly == true)
            Padding(
              padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
              child: Text(
                EchoKaraokeScreen.practiceLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          SizedBox(height: PanAfricanSpacing.xl),
          FilledButton(
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
            child: const Text('Done'),
          ),
        ],
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
          SizedBox(height: PanAfricanSpacing.lg),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

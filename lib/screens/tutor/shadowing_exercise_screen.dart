import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/games/gamekit/game_scoring.dart';
import 'package:lingafriq/games/gamekit/game_session.dart';
import 'package:lingafriq/games/gamekit/game_turn_context.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/services/lens/lens_scoring_client.dart';

/// copy_keys: rev.rv_shadow.*
///
/// A native line to shadow. An empty [text] is treated as no clip.
class ShadowingClip {
  const ShadowingClip({
    required this.id,
    required this.text,
    required this.language,
  });

  final String id;
  final String text;
  final String language;
}

/// One spoken attempt. The path is audio the real scorer can read.
class ShadowingAttempt {
  const ShadowingAttempt({required this.audioPath});

  final String audioPath;
}

/// A load that failed because the phone is offline, or for another reason.
class ShadowingUnavailable implements Exception {
  const ShadowingUnavailable({this.offline = false});

  final bool offline;
}

/// What the shadowing page is showing.
enum ShadowingPageStatus {
  loading,
  empty,
  error,
  offline,
  scored,
  unsure,
  practice,
}

/// Percent from a real scorer result. Unsure, practice, and any other
/// source return null so the page cannot paint a stand-in number.
int? shadowingShownPercent(GameScore score) {
  if (score.source != GameScoreSource.realScorer) return null;
  if (score.isUnsure || score.honestPracticeMode) return null;
  final double accuracy = score.accuracy;
  if (!accuracy.isFinite || accuracy < 0 || accuracy > 1) return null;
  return (accuracy * 100).round();
}

/// Page status for one scorer result. A missing real percent is practice.
ShadowingPageStatus shadowingStatusForScore(GameScore score) {
  if (score.isUnsure) return ShadowingPageStatus.unsure;
  if (score.honestPracticeMode ||
      score.source == GameScoreSource.honestPractice ||
      score.source == GameScoreSource.scorerUnavailable) {
    return ShadowingPageStatus.practice;
  }
  if (shadowingShownPercent(score) == null) return ShadowingPageStatus.practice;
  return ShadowingPageStatus.scored;
}

/// Posts the attempt to [RealScorerSpeakingEngine]. The number on screen
/// comes only from that result.
Future<GameScore> scoreShadowingAttempt({
  required ShadowingClip clip,
  required ShadowingAttempt attempt,
  required LensScorePost post,
}) {
  final RealScorerSpeakingEngine engine = RealScorerSpeakingEngine(post: post);
  return engine.score(
    GameTurnContext(
      content: <String, String>{'expectedText': clip.text},
      input: GameSpeakingTurnInput(
        audioPath: attempt.audioPath,
        expectedText: clip.text,
        language: clip.language,
      ),
      session: GameSession(
        sessionId: 'shadowing',
        userId: 'learner',
        gameId: 'shadowing',
        language: clip.language,
        startTime: DateTime.now(),
        metadata: const <String, dynamic>{'core_verb': 'speak'},
      ),
      metadata: const <String, dynamic>{
        'requiresServerScoring': true,
        'coreVerb': 'speak',
      },
    ),
  );
}

/// Gateway post from the app container. Missing scope means no scorer.
LensScorePost? shadowingGatewayPost(BuildContext context) {
  try {
    final ProviderContainer container = ProviderScope.containerOf(
      context,
      listen: false,
    );
    final Dio dio = container.read(client);
    return (String path, FormData data) {
      return dio.post<dynamic>(path, data: data);
    };
  } catch (_) {
    return null;
  }
}

/// Listen-and-repeat shadowing.
///
/// No clip, or a clip with no attempt, shows [LingEmptyState]. A load or
/// score failure shows [LingErrorState] and drops the attempt that was
/// on screen. A percent is painted only when [shadowingShownPercent] has one.
class ShadowingExerciseScreen extends StatefulWidget {
  const ShadowingExerciseScreen({
    super.key,
    this.loadClip,
    this.readAttempt,
    this.scoreAttempt,
    this.post,
  });

  /// App route `/speak/shadowing`. The map key drops the leading slash.
  static const String routePath = '/speak/shadowing';

  static const String routeKey = 'speak/shadowing';

  static const Key emptyKey = ValueKey<String>('speak-shadow-empty');

  static const Key errorKey = ValueKey<String>('speak-shadow-error');

  static const Key offlineKey = ValueKey<String>('speak-shadow-offline');

  static const Key scoreKey = ValueKey<String>('speak-shadow-score');

  static const Key unsureKey = ValueKey<String>('speak-shadow-unsure');

  static const Key practiceKey = ValueKey<String>('speak-shadow-practice');

  static const Key attemptKey = ValueKey<String>('speak-shadow-attempt');

  static const Key clipKey = ValueKey<String>('speak-shadow-clip');

  static const Key recordKey = ValueKey<String>('speak-shadow-record');

  static const Key backKey = ValueKey<String>('speak-shadow-back');

  /// Loads the clip. Null means this open has no clip.
  final Future<ShadowingClip?> Function()? loadClip;

  /// Reads the spoken attempt. Null, or a null result, means no attempt.
  final Future<ShadowingAttempt?> Function()? readAttempt;

  /// Scores one attempt. Null uses [post] or the app gateway.
  final Future<GameScore> Function(
    ShadowingClip clip,
    ShadowingAttempt attempt,
  )?
  scoreAttempt;

  /// Real scorer post. Used when [scoreAttempt] is null.
  final LensScorePost? post;

  @override
  State<ShadowingExerciseScreen> createState() =>
      _ShadowingExerciseScreenState();
}

class _ShadowingExerciseScreenState extends State<ShadowingExerciseScreen> {
  ShadowingPageStatus _status = ShadowingPageStatus.loading;
  ShadowingClip? _clip;
  ShadowingAttempt? _attempt;
  int? _percent;
  bool _scoreFault = false;

  @override
  void initState() {
    super.initState();
    if (widget.loadClip == null) {
      _status = ShadowingPageStatus.empty;
      return;
    }
    _status = ShadowingPageStatus.loading;
    _run(initial: true);
  }

  @override
  void didUpdateWidget(ShadowingExerciseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.loadClip, widget.loadClip) ||
        !identical(oldWidget.readAttempt, widget.readAttempt) ||
        !identical(oldWidget.scoreAttempt, widget.scoreAttempt) ||
        !identical(oldWidget.post, widget.post)) {
      _percent = null;
      _attempt = null;
      _run();
    }
  }

  Future<void> _run({bool initial = false}) async {
    final Future<ShadowingClip?> Function()? load = widget.loadClip;
    if (load == null) {
      if (!mounted) return;
      setState(_clearTo(ShadowingPageStatus.empty, clip: null));
      return;
    }
    if (!initial) {
      setState(() {
        _status = ShadowingPageStatus.loading;
        _attempt = null;
        _percent = null;
        _scoreFault = false;
      });
    }
    try {
      final ShadowingClip? clip = await load();
      if (!mounted) return;
      if (clip == null || clip.text.trim().isEmpty) {
        setState(_clearTo(ShadowingPageStatus.empty, clip: null));
        return;
      }
      final Future<ShadowingAttempt?> Function()? read = widget.readAttempt;
      if (read == null) {
        setState(_clearTo(ShadowingPageStatus.empty, clip: clip));
        return;
      }
      final ShadowingAttempt? attempt = await read();
      if (!mounted) return;
      if (attempt == null || attempt.audioPath.trim().isEmpty) {
        setState(_clearTo(ShadowingPageStatus.empty, clip: clip));
        return;
      }
      await _applyScore(clip, attempt);
    } on ShadowingUnavailable catch (error) {
      if (!mounted) return;
      setState(
        _clearTo(
          error.offline
              ? ShadowingPageStatus.offline
              : ShadowingPageStatus.error,
          clip: _clip,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(_clearTo(ShadowingPageStatus.error, clip: _clip));
    }
  }

  Future<void> _record() async {
    final ShadowingClip? clip = _clip;
    if (clip == null) {
      _back();
      return;
    }
    setState(() {
      _status = ShadowingPageStatus.loading;
      _attempt = null;
      _percent = null;
      _scoreFault = false;
    });
    final Future<ShadowingAttempt?> Function()? read = widget.readAttempt;
    if (read == null) {
      if (!mounted) return;
      setState(_clearTo(ShadowingPageStatus.empty, clip: clip));
      return;
    }
    try {
      final ShadowingAttempt? attempt = await read();
      if (!mounted) return;
      if (attempt == null || attempt.audioPath.trim().isEmpty) {
        setState(_clearTo(ShadowingPageStatus.empty, clip: clip));
        return;
      }
      await _applyScore(clip, attempt);
    } on ShadowingUnavailable catch (error) {
      if (!mounted) return;
      setState(
        _clearTo(
          error.offline
              ? ShadowingPageStatus.offline
              : ShadowingPageStatus.error,
          clip: clip,
          scoreFault: true,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        _clearTo(ShadowingPageStatus.error, clip: clip, scoreFault: true),
      );
    }
  }

  Future<void> _applyScore(ShadowingClip clip, ShadowingAttempt attempt) async {
    try {
      final GameScore score = await _score(clip, attempt);
      if (!mounted) return;
      final ShadowingPageStatus status = shadowingStatusForScore(score);
      final int? percent = shadowingShownPercent(score);
      setState(() {
        _clip = clip;
        _scoreFault = false;
        if (status == ShadowingPageStatus.scored && percent != null) {
          _status = ShadowingPageStatus.scored;
          _attempt = attempt;
          _percent = percent;
          return;
        }
        _attempt = null;
        _percent = null;
        _status = status == ShadowingPageStatus.unsure
            ? ShadowingPageStatus.unsure
            : ShadowingPageStatus.practice;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        _clearTo(ShadowingPageStatus.error, clip: clip, scoreFault: true),
      );
    }
  }

  Future<GameScore> _score(ShadowingClip clip, ShadowingAttempt attempt) {
    final Future<GameScore> Function(ShadowingClip, ShadowingAttempt)? custom =
        widget.scoreAttempt;
    if (custom != null) return custom(clip, attempt);
    final LensScorePost? post = widget.post ?? shadowingGatewayPost(context);
    if (post == null) {
      return Future<GameScore>.value(
        GameScore.honestPractice(message: 'unavailable'),
      );
    }
    return scoreShadowingAttempt(clip: clip, attempt: attempt, post: post);
  }

  VoidCallback _clearTo(
    ShadowingPageStatus status, {
    required ShadowingClip? clip,
    bool scoreFault = false,
  }) {
    return () {
      _status = status;
      _clip = clip;
      _attempt = null;
      _percent = null;
      _scoreFault = scoreFault;
    };
  }

  void _back() {
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final bool clipVisible =
        _clip != null &&
        (_status == ShadowingPageStatus.empty ||
            _status == ShadowingPageStatus.scored ||
            _status == ShadowingPageStatus.unsure ||
            _status == ShadowingPageStatus.practice);
    final bool backInEmpty =
        _status == ShadowingPageStatus.empty && _clip == null;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.hubHSpeakShadowing,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            if (clipVisible) ...<Widget>[
              Text(
                _clip!.text,
                key: ShadowingExerciseScreen.clipKey,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
            ],
            _body(l10n, palette),
            if (_status == ShadowingPageStatus.scored ||
                _status == ShadowingPageStatus.unsure ||
                _status == ShadowingPageStatus.practice) ...<Widget>[
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                key: ShadowingExerciseScreen.recordKey,
                label: l10n.revRvShadowRecord,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: _record,
              ),
            ],
            if (!backInEmpty) ...<Widget>[
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                key: ShadowingExerciseScreen.backKey,
                label: l10n.hubHSpeakBack,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: _back,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, LingPalette palette) {
    switch (_status) {
      case ShadowingPageStatus.loading:
        return Text(
          l10n.loading,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        );
      case ShadowingPageStatus.empty:
        final bool noClip = _clip == null;
        return LingEmptyState(
          key: ShadowingExerciseScreen.emptyKey,
          title: l10n.hubHSpeakShadowing,
          whatHappened: noClip
              ? l10n.revRvShadowEmptyWhat
              : l10n.revRvShadowNoAttemptWhat,
          why: noClip ? l10n.revRvShadowEmptyWhy : l10n.revRvShadowNoAttemptWhy,
          whatToDo: noClip
              ? l10n.revRvShadowEmptyNext
              : l10n.revRvShadowNoAttemptNext,
          actionLabel: noClip ? l10n.hubHSpeakBack : l10n.revRvShadowRecord,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: noClip ? _back : _record,
        );
      case ShadowingPageStatus.error:
        return LingErrorState(
          key: ShadowingExerciseScreen.errorKey,
          whatHappened: _scoreFault
              ? l10n.revRvShadowScoreErrorWhat
              : l10n.revRvShadowErrorWhat,
          why: _scoreFault
              ? l10n.revRvShadowScoreErrorWhy
              : l10n.revRvShadowErrorWhy,
          whatToDo: l10n.revRvShadowErrorNext,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: () {
            _run();
          },
        );
      case ShadowingPageStatus.offline:
        return LingOfflineState(
          key: ShadowingExerciseScreen.offlineKey,
          whatHappened: l10n.shellOfflineWhat,
          why: l10n.revRvShadowOfflineWhy,
          whatToDo: l10n.shellOfflineNext,
          queuedActions: 0,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: () {
            _run();
          },
        );
      case ShadowingPageStatus.scored:
        final int? percent = _percent;
        if (percent == null) return _practice(l10n, palette);
        final String value = l10n.revRvShadowScoreValue(percent);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.revRvShadowScoreLabel,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Semantics(
              container: true,
              label: value,
              child: Text(
                value,
                key: ShadowingExerciseScreen.scoreKey,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
            if (_attempt != null)
              const SizedBox(
                key: ShadowingExerciseScreen.attemptKey,
                height: 0,
              ),
          ],
        );
      case ShadowingPageStatus.unsure:
        return Text(
          l10n.revRvShadowUnsure,
          key: ShadowingExerciseScreen.unsureKey,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        );
      case ShadowingPageStatus.practice:
        return _practice(l10n, palette);
    }
  }

  Widget _practice(AppLocalizations l10n, LingPalette palette) {
    return Text(
      l10n.revRvShadowPractice,
      key: ShadowingExerciseScreen.practiceKey,
      style: lingBody(palette.onSurface),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }
}

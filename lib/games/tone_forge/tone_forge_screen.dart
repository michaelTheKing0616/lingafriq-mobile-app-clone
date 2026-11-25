import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../design/components/ling_button.dart';
import '../../design/components/ling_state.dart';
import '../../design/states/empty_state.dart';
import '../../design/states/error_state.dart';
import '../../design/states/offline_state.dart';
import '../../design/tokens.g.dart';
import '../../games/gamekit/all_games_registry.dart';
import '../../games/gamekit/game_difficulty.dart';
import '../../games/gamekit/game_feedback.dart';
import '../../games/gamekit/game_result.dart';
import '../../games/gamekit/game_scoring.dart';
import '../../games/gamekit/game_session.dart' as gamekit_session;
import '../../games/gamekit/game_turn_context.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/l10n_of.dart';
import '../../learning/pronunciation/tone_models.dart';
import '../../services/feature_flag_service.dart';
import '../../services/lens/lens_scoring_client.dart';
import '../../services/offline/tone_trainer_queue_service.dart';
import '../../utils/pan_african_design_system.dart';
import 'tone_forge_feedback.dart';
import 'tone_forge_models.dart';
import 'tone_forge_scoring.dart';

/// One word the learner can try. An empty [word] is no round.
class ToneForgeRound {
  const ToneForgeRound({
    required this.word,
    required this.audioPath,
    required this.language,
  });

  final String word;
  final String audioPath;
  final String language;
}

/// A load that failed because the phone is offline, or for another reason.
class ToneForgeUnavailable implements Exception {
  const ToneForgeUnavailable({this.offline = false});

  final bool offline;
}

/// What the Play route is showing.
enum ToneForgePageStatus { loading, empty, error, offline, scored, unsure }

/// Featured tone game. Lexicon inventory plus GameKit graph writes.
///
/// [ToneForgeScreen.play] is the Play route. With no loader the page is empty.
/// A failed load clears the previous word and any score. A percent is painted
/// only when [toneForgeShownPercent] has one.
class ToneForgeScreen extends StatefulWidget {
  const ToneForgeScreen({
    super.key,
    required this.language,
    this.level,
    this.onBack,
  }) : loadRound = null,
       scoreAttempt = null,
       post = null,
       routeEntry = false;

  const ToneForgeScreen.play({
    super.key,
    this.loadRound,
    this.scoreAttempt,
    this.post,
    this.onBack,
  }) : language = 'yo',
       level = null,
       routeEntry = true;

  /// App route `/play/tone-forge`. The map key drops the leading slash.
  static const String routePath = '/play/tone-forge';

  static const String routeKey = 'play/tone-forge';

  static const Key emptyKey = ValueKey<String>('play-tone-forge-empty');

  static const Key errorKey = ValueKey<String>('play-tone-forge-error');

  static const Key offlineKey = ValueKey<String>('play-tone-forge-offline');

  static const Key scoreKey = ValueKey<String>('play-tone-forge-score');

  static const Key unsureKey = ValueKey<String>('play-tone-forge-unsure');

  static const Key wordKey = ValueKey<String>('play-tone-forge-word');

  final String language;
  final String? level;
  final VoidCallback? onBack;
  final bool routeEntry;

  /// Loads a round. Null on the route means this open has no word.
  final Future<ToneForgeRound?> Function()? loadRound;

  /// Scores one round. Null uses [post] or an unsure result.
  final Future<GameScore> Function(ToneForgeRound round)? scoreAttempt;

  /// Real scorer post. Used when [scoreAttempt] is null.
  final LensScorePost? post;

  @override
  State<ToneForgeScreen> createState() => _ToneForgeScreenState();
}

class _ToneForgeScreenState extends State<ToneForgeScreen> {
  final List<_ForgeQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedTone;
  bool _answered = false;
  int? _shownPercent;
  ToneLanguageModel? _inventory;
  _ForgeLoad _load = _ForgeLoad.loading;
  bool _practiceNotScored = true;
  late gamekit_session.GameSession _kitSession;
  final GameKitLearnerGraphWriter _graphWriter = GameKitLearnerGraphWriter();
  int _turnCounter = 0;

  ToneForgePageStatus _routeStatus = ToneForgePageStatus.loading;
  String? _routeWord;
  bool _scoreFault = false;

  static const int _cardCount = 10;

  @override
  void initState() {
    super.initState();
    _kitSession = gamekit_session.GameSession(
      sessionId: 'tone_forge_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'local',
      gameId: AllGamesRegistry.toneForgeGameId,
      language: widget.language,
      startTime: DateTime.now(),
    );
    if (widget.routeEntry) {
      if (widget.loadRound == null) {
        _routeStatus = ToneForgePageStatus.empty;
        return;
      }
      _routeStatus = ToneForgePageStatus.loading;
      _loadRoute(initial: true);
      return;
    }
    _resolvePracticeMode();
    _bootstrap(initial: true);
  }

  @override
  void didUpdateWidget(ToneForgeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.routeEntry) return;
    if (identical(oldWidget.loadRound, widget.loadRound) &&
        identical(oldWidget.scoreAttempt, widget.scoreAttempt) &&
        identical(oldWidget.post, widget.post)) {
      return;
    }
    _shownPercent = null;
    _routeWord = null;
    _scoreFault = false;
    if (widget.loadRound == null) {
      _routeStatus = ToneForgePageStatus.empty;
      return;
    }
    _routeStatus = ToneForgePageStatus.loading;
    _loadRoute();
  }

  void _resolvePracticeMode() {
    final flagOn = FeatureFlagService(
      safeDefault: false,
    ).isOn(gameKitRealSpeakingScorerFlagKey, DateTime.now());
    final live = gameKitRealScorerLiveForGame(
      featureFlagOn: flagOn,
      gameId: AllGamesRegistry.toneForgeGameId,
      isSpeakingGame: true,
    );
    _practiceNotScored = gameKitPracticeNotScoredMode(
      isSpeakingGame: true,
      realScorerLive: live,
    );
  }

  Future<void> _bootstrap({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _load = _ForgeLoad.loading;
        _clearGameResult();
      });
    } else {
      _clearGameResult();
    }
    try {
      final lang = widget.language.toLowerCase();
      final catalog = await loadToneModelsCatalogFromAsset();
      if (!mounted) return;
      if (!isToneTrainerAvailable(catalog, lang)) {
        setState(() {
          _clearGameResult();
          _load = _ForgeLoad.empty;
        });
        return;
      }

      final pool = await buildToneGamePool(
        catalog: catalog,
        languageCode: lang,
        fetchLimit: 48,
      );
      if (!mounted) return;
      ToneTrainerQueueService.instance.recordPoolDiagnostics(
        pool.diagnostics.formatLine(),
      );
      _inventory = pool.inventory;

      if (pool.lexemes.isEmpty ||
          pool.options.isEmpty ||
          pool.inventory == null) {
        setState(() {
          _clearGameResult();
          _load = _ForgeLoad.empty;
        });
        return;
      }

      final rng = Random();
      final shuffled = List<ToneGameLexeme>.from(pool.lexemes)..shuffle(rng);
      for (final lexeme in shuffled.take(_cardCount)) {
        final syllableIndex = lexeme.tonePattern.length == 1
            ? 0
            : rng.nextInt(lexeme.tonePattern.length);
        final spec = toneTrainerQuestionFromLexeme(
          lexeme: lexeme,
          options: pool.options,
          inventory: pool.inventory!,
          syllableIndex: syllableIndex,
        );
        if (spec == null) continue;
        _questions.add(_ForgeQuestion.fromSpec(spec));
      }
      setState(() {
        _load = _questions.isEmpty ? _ForgeLoad.empty : _ForgeLoad.ready;
        if (_load == _ForgeLoad.empty) _clearGameResult();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _clearGameResult();
        _load = _ForgeLoad.error;
      });
    }
  }

  void _clearGameResult() {
    _questions.clear();
    _currentIndex = 0;
    _selectedTone = null;
    _answered = false;
    _shownPercent = null;
    _inventory = null;
  }

  Future<void> _loadRoute({bool initial = false}) async {
    final Future<ToneForgeRound?> Function()? load = widget.loadRound;
    if (load == null) {
      if (!mounted) return;
      setState(_clearRoute(ToneForgePageStatus.empty));
      return;
    }
    if (!initial) {
      setState(() {
        _routeStatus = ToneForgePageStatus.loading;
        _shownPercent = null;
        _routeWord = null;
        _scoreFault = false;
      });
    }
    try {
      final ToneForgeRound? round = await load();
      if (!mounted) return;
      if (round == null || round.word.trim().isEmpty) {
        setState(_clearRoute(ToneForgePageStatus.empty));
        return;
      }
      await _applyRoundScore(round);
    } on ToneForgeUnavailable catch (error) {
      if (!mounted) return;
      setState(
        _clearRoute(
          error.offline
              ? ToneForgePageStatus.offline
              : ToneForgePageStatus.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(_clearRoute(ToneForgePageStatus.error));
    }
  }

  Future<void> _applyRoundScore(ToneForgeRound round) async {
    try {
      final GameScore score = await _scoreRound(round);
      if (!mounted) return;
      final GameFeedback feedback = await const ToneForgeFeedbackEngine()
          .generate(_feedbackContext(round.word), score);
      if (!mounted) return;
      final int? percent = toneForgeShownPercent(score);
      final bool measured =
          percent != null && RegExp(r'\d').hasMatch(feedback.message);
      setState(() {
        _scoreFault = false;
        if (measured &&
            toneForgeScoreView(score) == ToneForgeScoreView.scored) {
          _routeStatus = ToneForgePageStatus.scored;
          _shownPercent = percent;
          _routeWord = round.word;
          return;
        }
        _shownPercent = null;
        _routeWord = round.word;
        _routeStatus = ToneForgePageStatus.unsure;
      });
    } catch (_) {
      if (!mounted) return;
      setState(_clearRoute(ToneForgePageStatus.error, scoreFault: true));
    }
  }

  Future<GameScore> _scoreRound(ToneForgeRound round) {
    final Future<GameScore> Function(ToneForgeRound)? custom =
        widget.scoreAttempt;
    if (custom != null) return custom(round);
    final LensScorePost? post = widget.post;
    if (post == null) {
      return Future<GameScore>.value(GameScore.unsure(message: 'unsure'));
    }
    return scoreToneForgeAttempt(
      word: round.word,
      audioPath: round.audioPath,
      language: round.language,
      post: post,
    );
  }

  GameTurnContext _feedbackContext(String word) {
    return GameTurnContext(content: word, input: word, session: _kitSession);
  }

  VoidCallback _clearRoute(
    ToneForgePageStatus status, {
    bool scoreFault = false,
  }) {
    return () {
      _routeStatus = status;
      _routeWord = null;
      _shownPercent = null;
      _scoreFault = scoreFault;
    };
  }

  _ForgeQuestion? get _current =>
      _currentIndex < _questions.length ? _questions[_currentIndex] : null;

  Future<void> _selectTone(int index) async {
    if (_answered || _inventory == null) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedTone = index);
  }

  Future<void> _submit() async {
    if (_selectedTone == null || _answered || _inventory == null) return;
    final q = _current!;
    HapticFeedback.mediumImpact();

    final GameScore gameScore = scoreToneInventoryChoice(
      inventory: _inventory!,
      lexiconTonePattern: q.lexeme.tonePattern,
      syllableIndex: q.syllableIndex,
      selectedInventoryIndex: _selectedTone!,
    );
    final GameFeedback feedback = await const ToneForgeFeedbackEngine()
        .generate(_feedbackContext(q.lexeme.toneMarkedForm), gameScore);
    final int? percent = toneForgeShownPercent(gameScore);
    final bool measured =
        percent != null && RegExp(r'\d').hasMatch(feedback.message);

    final turnId = 'tf_${_turnCounter++}';
    final context = GameTurnContext(
      content: q,
      input: _selectedTone,
      session: _kitSession,
      metadata: {
        'itemId': q.lexeme.lexemeId,
        'skillId': 'tone:${q.lexeme.language}',
        'gameCategory': 'pronunciation',
      },
    );
    final result = GameTurnResult(
      score: gameScore,
      feedback: feedback,
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

    if (!mounted) return;
    setState(() {
      _answered = true;
      _shownPercent = measured ? percent : null;
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedTone = null;
        _answered = false;
        _shownPercent = null;
      });
    } else {
      _back();
    }
  }

  void _back() {
    final VoidCallback? onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routeEntry) return _routeScaffold(context);
    return _gameScaffold(context);
  }

  Widget _routeScaffold(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final bool wordVisible =
        _routeWord != null &&
        (_routeStatus == ToneForgePageStatus.scored ||
            _routeStatus == ToneForgePageStatus.unsure);
    final bool backInEmpty = _routeStatus == ToneForgePageStatus.empty;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.hubHPlayToneForge,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            if (wordVisible) ...<Widget>[
              Text(
                _routeWord!,
                key: ToneForgeScreen.wordKey,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
            ],
            _routeBody(l10n, palette),
            if (!backInEmpty) ...<Widget>[
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                label: l10n.hubHPlayBack,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: _back,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routeBody(AppLocalizations l10n, LingPalette palette) {
    switch (_routeStatus) {
      case ToneForgePageStatus.loading:
        return Text(
          l10n.loading,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        );
      case ToneForgePageStatus.empty:
        return LingEmptyState(
          key: ToneForgeScreen.emptyKey,
          title: l10n.hubHPlayToneForge,
          whatHappened: l10n.revRvPlayEmptyWhat,
          why: l10n.revRvPlayEmptyWhy,
          whatToDo: l10n.revRvPlayEmptyNext,
          actionLabel: l10n.hubHPlayBack,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _back,
        );
      case ToneForgePageStatus.error:
        return LingErrorState(
          key: ToneForgeScreen.errorKey,
          whatHappened: _scoreFault
              ? l10n.revRvPlayScoreErrorWhat
              : l10n.revRvPlayErrorWhat,
          why: _scoreFault
              ? l10n.revRvPlayScoreErrorWhy
              : l10n.revRvPlayErrorWhy,
          whatToDo: l10n.revRvPlayErrorNext,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _loadRoute,
        );
      case ToneForgePageStatus.offline:
        return LingOfflineState(
          key: ToneForgeScreen.offlineKey,
          whatHappened: l10n.shellOfflineWhat,
          why: l10n.revRvPlayOfflineWhy,
          whatToDo: l10n.shellOfflineNext,
          queuedActions: 0,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _loadRoute,
        );
      case ToneForgePageStatus.scored:
        final int? percent = _shownPercent;
        if (percent == null) return _unsure(l10n, palette);
        final String value = l10n.revRvPlayScoreValue(percent);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.revRvPlayScoreLabel,
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
                key: ToneForgeScreen.scoreKey,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        );
      case ToneForgePageStatus.unsure:
        return _unsure(l10n, palette);
    }
  }

  Widget _unsure(AppLocalizations l10n, LingPalette palette) {
    return Text(
      l10n.revRvPlayUnsure,
      key: ToneForgeScreen.unsureKey,
      style: lingBody(palette.onSurface),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  Widget _gameScaffold(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final cs = Theme.of(context).colorScheme;
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text(l10n.hubHPlayToneForge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: switch (_load) {
        _ForgeLoad.loading => const Center(child: CircularProgressIndicator()),
        _ForgeLoad.error => _gameError(l10n),
        _ForgeLoad.empty => _gameEmpty(l10n),
        _ForgeLoad.ready => Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_practiceNotScored) const _PracticeBanner(),
              Text(
                'Which tone is on the highlighted syllable?',
                style: PanAfricanTypography.titleMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                '${_currentIndex + 1} / ${_questions.length}',
                style: PanAfricanTypography.labelMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Expanded(child: _buildQuestion(context, cs)),
              if (_answered) ...[
                SizedBox(height: PanAfricanSpacing.md),
                _shownPercent == null
                    ? _unsure(l10n, palette)
                    : Text(
                        l10n.revRvPlayScoreValue(_shownPercent!),
                        key: ToneForgeScreen.scoreKey,
                        style: lingBody(palette.onSurface),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
              ],
              SizedBox(height: PanAfricanSpacing.md),
              if (!_answered)
                FilledButton(
                  onPressed: _selectedTone == null ? null : _submit,
                  child: const Text('Check tone'),
                )
              else
                FilledButton(
                  onPressed: _next,
                  child: Text(
                    _currentIndex < _questions.length - 1
                        ? 'Next word'
                        : 'Finish',
                  ),
                ),
            ],
          ),
        ),
      },
    );
  }

  Widget _gameEmpty(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
      children: <Widget>[
        LingEmptyState(
          key: ToneForgeScreen.emptyKey,
          title: l10n.hubHPlayToneForge,
          whatHappened: l10n.revRvPlayEmptyWhat,
          why: l10n.revRvPlayEmptyWhy,
          whatToDo: l10n.revRvPlayEmptyNext,
          actionLabel: l10n.hubHPlayBack,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _back,
        ),
      ],
    );
  }

  Widget _gameError(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
      children: <Widget>[
        LingErrorState(
          key: ToneForgeScreen.errorKey,
          whatHappened: l10n.revRvPlayErrorWhat,
          why: l10n.revRvPlayErrorWhy,
          whatToDo: l10n.revRvPlayErrorNext,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: () {
            _bootstrap();
          },
        ),
      ],
    );
  }

  Widget _buildQuestion(BuildContext context, ColorScheme cs) {
    final q = _current!;
    final options = q.options;
    return Column(
      children: [
        Text(
          q.lexeme.toneMarkedForm,
          style: PanAfricanTypography.displaySmall(context),
          textAlign: TextAlign.center,
        ),
        if (q.lexeme.englishGloss != null) ...[
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            q.lexeme.englishGloss!,
            style: PanAfricanTypography.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: PanAfricanSpacing.lg),
        ...List.generate(options.length, (i) {
          final opt = options[i];
          final selected = _selectedTone == i;
          return Padding(
            padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
            child: Semantics(
              button: true,
              label: 'Tone ${opt.label}',
              child: Material(
                color: selected
                    ? cs.primaryContainer
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                child: InkWell(
                  onTap: _answered ? null : () => _selectTone(i),
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  child: SizedBox(
                    height: 48.h,
                    child: Center(
                      child: Text(
                        '${opt.symbol} ${opt.label}',
                        style: PanAfricanTypography.titleSmall(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

enum _ForgeLoad { loading, ready, empty, error }

class _ForgeQuestion {
  _ForgeQuestion({
    required this.lexeme,
    required this.syllableIndex,
    required this.correctInventoryIndex,
    required this.options,
  });

  final ToneGameLexeme lexeme;
  final int syllableIndex;
  final int correctInventoryIndex;
  final List<ToneInventoryOption> options;

  factory _ForgeQuestion.fromSpec(ToneTrainerQuestionSpec spec) {
    return _ForgeQuestion(
      lexeme: spec.lexeme,
      syllableIndex: spec.syllableIndex,
      correctInventoryIndex: spec.correctInventoryIndex,
      options: spec.options,
    );
  }
}

class _PracticeBanner extends StatelessWidget {
  const _PracticeBanner();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      child: Material(
        color: PanAfricanColors.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.school_outlined, size: 20.sp),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: Text(
                  l10n.revRvPlayPractice,
                  style: PanAfricanTypography.bodySmall(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tone shelf strip for the Arcade hub.
class ToneForgeArcadeShelfStrip extends StatelessWidget {
  const ToneForgeArcadeShelfStrip({
    super.key,
    required this.language,
    required this.onOpenToneForge,
  });

  final String language;
  final VoidCallback onOpenToneForge;

  @override
  Widget build(BuildContext context) {
    final featured = AllGamesRegistry.featuredOnShelf(ArcadeSkillShelf.tone);
    if (featured == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        PanAfricanSpacing.md,
        PanAfricanSpacing.sm,
        PanAfricanSpacing.md,
        PanAfricanSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ArcadeSkillShelf.tone.title,
            style: PanAfricanTypography.titleSmall(context),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Semantics(
            button: true,
            label: 'Featured game Tone Forge',
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
              color: PanAfricanColors.primaryContainer,
              child: InkWell(
                onTap: onOpenToneForge,
                borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    child: Row(
                      children: [
                        Icon(Icons.graphic_eq, size: 32.sp),
                        SizedBox(width: PanAfricanSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Tone Forge',
                                    style: PanAfricanTypography.titleMedium(
                                      context,
                                    ),
                                  ),
                                  SizedBox(width: PanAfricanSpacing.xs),
                                  Chip(
                                    label: Text(
                                      'Featured',
                                      style: PanAfricanTypography.labelSmall(
                                        context,
                                      ),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              Text(
                                'Hear the word, pick the tone on the syllable.',
                                style: PanAfricanTypography.bodySmall(context),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

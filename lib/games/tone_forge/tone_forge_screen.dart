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
import '../../games/gamekit/game_session.dart' as gamekit_session;
import '../../games/gamekit/game_turn_context.dart';
import '../../learning/pronunciation/tone_models.dart';
import '../../services/feature_flag_service.dart';
import '../../services/offline/tone_trainer_queue_service.dart';
import '../../utils/pan_african_design_system.dart';
import 'tone_forge_models.dart';
import 'tone_forge_scoring.dart';

/// Featured tone game — lexicon inventory + GameKit graph writes (P8-914).
class ToneForgeScreen extends ConsumerStatefulWidget {
  const ToneForgeScreen({
    super.key,
    required this.language,
    this.level,
    this.onBack,
  });

  final String language;
  final String? level;
  final VoidCallback? onBack;

  @override
  ConsumerState<ToneForgeScreen> createState() => _ToneForgeScreenState();
}

class _ToneForgeScreenState extends ConsumerState<ToneForgeScreen> {
  final List<_ForgeQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedTone;
  bool _answered = false;
  int _score = 0;
  ToneLanguageModel? _inventory;
  bool _loading = true;
  String? _loadError;
  bool _practiceNotScored = true;
  late gamekit_session.GameSession _kitSession;
  final GameKitLearnerGraphWriter _graphWriter = GameKitLearnerGraphWriter();
  int _turnCounter = 0;

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
    _resolvePracticeMode();
    _bootstrap();
  }

  void _resolvePracticeMode() {
    final flagOn = FeatureFlagService(safeDefault: false).isOn(
      gameKitRealSpeakingScorerFlagKey,
      DateTime.now(),
    );
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

  Future<void> _bootstrap() async {
    try {
      final lang = widget.language.toLowerCase();
      final catalog = await loadToneModelsCatalogFromAsset();
      if (!isToneTrainerAvailable(catalog, lang)) {
        setState(() {
          _loading = false;
          _loadError = 'Tone Forge is not available for this language yet.';
        });
        return;
      }

      final pool = await buildToneGamePool(
        catalog: catalog,
        languageCode: lang,
        fetchLimit: 48,
      );
      ToneTrainerQueueService.instance
          .recordPoolDiagnostics(pool.diagnostics.formatLine());
      _inventory = pool.inventory;

      if (pool.lexemes.isEmpty ||
          pool.options.isEmpty ||
          pool.inventory == null) {
        setState(() {
          _loading = false;
          _loadError =
              'No verified tonal words are ready yet. Check back after more lexicon review.';
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
      setState(() => _loading = false);
    } catch (_) {
      setState(() {
        _loading = false;
        _loadError = 'We could not load Tone Forge. Check your connection and try again.';
      });
    }
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

    final gameScore = scoreToneInventoryChoice(
      inventory: _inventory!,
      lexiconTonePattern: q.lexeme.tonePattern,
      syllableIndex: q.syllableIndex,
      selectedInventoryIndex: _selectedTone!,
    );

    final score = _practiceNotScored && !gameScore.isCorrect
        ? GameScore.honestPractice(message: 'Practice — tone scores are not ranked yet.')
        : gameScore;

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
      score: score,
      feedback: GameFeedback.neutral(
        message: score.isCorrect ? 'Well heard.' : 'Listen again to the pitch.',
        animationEvent: AnimationEvent.listening,
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

    if (gameScore.isCorrect) _score++;

    setState(() => _answered = true);
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedTone = null;
        _answered = false;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_questions.isEmpty ? 'Tone Forge' : 'Tone Forge · $_score'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _ToneForgeStateMessage(message: _loadError!)
              : _questions.isEmpty
                  ? const _ToneForgeStateMessage(
                      message:
                          'No verified tonal words are ready yet. Check back after more lexicon review.',
                    )
                  : Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_practiceNotScored)
                            const _PracticeBanner(),
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
                          SizedBox(height: PanAfricanSpacing.md),
                          if (!_answered)
                            FilledButton(
                              onPressed:
                                  _selectedTone == null ? null : _submit,
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
                  'Practice mode — tone scores are for learning only until the live scorer is enabled.',
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

class _ToneForgeStateMessage extends StatelessWidget {
  const _ToneForgeStateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Text(
          message,
          style: PanAfricanTypography.bodyLarge(context),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Tone shelf strip for the Arcade hub (AC1).
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
    final featured =
        AllGamesRegistry.featuredOnShelf(ArcadeSkillShelf.tone);
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
                                    style:
                                        PanAfricanTypography.titleMedium(context),
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

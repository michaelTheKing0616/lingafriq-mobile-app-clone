import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../screens/games/base_game_screen.dart';
import '../../services/polie_game_client.dart';
import '../../models/game/game_session_model.dart' show GameType, GameResult;
import '../../l10n/generated/app_localizations.dart';
import 'generic_game_template.dart';
import 'game_session.dart';
import 'all_games_registry.dart';
import '../widgets/game_answer_tile.dart';
import '../widgets/progress_meter.dart';
import '../widgets/streak_indicator.dart';
import 'game_feedback.dart';
import 'game_result.dart';
import 'game_turn_context.dart';
import 'game_scoring.dart';
import 'game_engine.dart';
import '../../services/feature_flag_service.dart';
import '../../avatars/avatars.dart';
import '../../learning/learner_model/error_taxonomy.dart';
import '../../models/game/game_content_models.dart';
import '../../screens/games/game_mastery_results_screen.dart';
import '../../providers/dio_provider.dart';
import '../../providers/game_provider.dart';

/// Universal game screen that works for any game using GenericGame
/// This allows all 37+ games to use the same GameKit implementation
class UniversalGameScreen extends BaseGameScreen {
  final String gameId;

  const UniversalGameScreen({
    super.key,
    required super.language,
    required this.gameId,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() {
    // Map gameId to GameType - this is a fallback
    // Individual games can override
    return GameType.proverbUnlocker; // Default
  }

  @override
  ConsumerState<UniversalGameScreen> createState() => _UniversalGameScreenState();
}

class _UniversalGameScreenState extends BaseGameScreenState<UniversalGameScreen> {
  late GenericGame _game;
  GenericGameContent? _currentContent;
  String? _selectedAnswer;
  String? _textInput;
  bool _showResult = false;
  GameTurnResult? _lastResult;
  int _score = 0;
  int _correctStreak = 0;
  int _round = 0;
  final int _maxRounds = 10;
  GameKitFeedbackPhase _feedbackPhase = GameKitFeedbackPhase.idle;
  GameKitFeedbackTiming? _feedbackTiming;
  Timer? _pendingFeedbackTimer;
  bool _showCelebration = false;
  bool? _immediateLocalCorrect;
  String? _wrongAnswerErrorTypeId;
  final GameKitLearnerGraphWriter _learnerGraphWriter = GameKitLearnerGraphWriter();
  GameSession? _kitSession;
  final FeatureFlagService _featureFlags = FeatureFlagService(safeDefault: false);
  bool _practiceNotScored = false;
  String? _lastLearnerRecordingPath;

  // Game avatar controller
  GameAvatarController? _avatarController;
  GameCategory _gameCategory = GameCategory.vocabulary;
  final GlobalKey<State<GameAvatarWidget>> _avatarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _game = AllGamesRegistry.createGame(ref, widget.gameId);
    _resolvePracticeMode();
    _initializeAvatar();
  }

  void _resolvePracticeMode() {
    final definition = AllGamesRegistry.getGame(widget.gameId);
    final isSpeaking = definition?.coreVerb == GameCoreVerb.speak;
    final flagOn = _featureFlags.isOn(
      gameKitRealSpeakingScorerFlagKey,
      DateTime.now(),
    );
    final live = gameKitRealScorerLiveForGame(
      featureFlagOn: flagOn,
      gameId: widget.gameId,
      isSpeakingGame: isSpeaking,
    );
    _practiceNotScored = gameKitPracticeNotScoredMode(
      isSpeakingGame: isSpeaking,
      realScorerLive: live,
    );
  }
  
  void _initializeAvatar() {
    // Determine game category based on gameId
    _gameCategory = _getCategoryForGame(widget.gameId);
    _avatarController = GameAvatarController(_gameCategory);
    _avatarController?.initialize();
  }
  
  GameCategory _getCategoryForGame(String gameId) {
    // Map game IDs to categories
    if (gameId.contains('vocab') || gameId.contains('word') || gameId.contains('match')) {
      return GameCategory.vocabulary;
    } else if (gameId.contains('tone') || gameId.contains('pronunciation') || gameId.contains('sound')) {
      return GameCategory.pronunciation;
    } else if (gameId.contains('culture') || gameId.contains('proverb') || gameId.contains('story')) {
      return GameCategory.cultural;
    } else if (gameId.contains('grammar') || gameId.contains('sentence') || gameId.contains('fill')) {
      return GameCategory.grammar;
    }
    return GameCategory.vocabulary; // Default
  }
  
  @override
  void dispose() {
    _pendingFeedbackTimer?.cancel();
    _avatarController?.dispose();
    super.dispose();
  }

  @override
  Future<void> onGameInitialized() async {
    await _loadNewContent();
  }

  GameSession _baseKitSession() {
    final upstreamMetadata = Map<String, dynamic>.from(session?.metadata ?? const {});
    return GameSession(
      sessionId: session!.sessionId,
      userId: session!.userId,
      gameId: widget.gameId,
      language: widget.language,
      level: widget.level,
      startTime: session!.startTime,
      turns: _kitSession?.turns ?? const [],
      metadata: {
        ...upstreamMetadata,
        ...?_kitSession?.metadata,
        if (_practiceNotScored) 'practice_not_scored': true,
      },
    );
  }

  GamekitDuelOpponentStrip? _duelOpponentStrip() {
    final kit = _kitSession;
    if (kit == null) return null;
    final levelLabel = (kit.duelOpponentLevelLabel ?? '').trim();
    if (levelLabel.isEmpty) return null;
    return GamekitDuelOpponentStrip(
      isBot: kit.duelOpponentIsBot,
      levelLabel: levelLabel,
      phase: GamekitDuelSurfacePhase.playing,
      selfScore: _score,
    );
  }

  Future<void> _loadNewContent() async {
    if (session == null) return;
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      _showResult = false;
      _selectedAnswer = null;
      _textInput = null;
      _lastResult = null;
      _feedbackPhase = GameKitFeedbackPhase.idle;
      _feedbackTiming = null;
      _immediateLocalCorrect = null;
      _showCelebration = false;
      _wrongAnswerErrorTypeId = null;
    });

    try {
      _kitSession = _baseKitSession();

      _currentContent = await _game.loadContent(_kitSession!);
      _round++;
      setState(() {});
    } catch (e) {
      debugPrint('Error loading content: $e');
      setError('Failed to load content. Please try again.');
    }
  }

  Future<void> _submitAnswer(String? answer, String? textInput) async {
    if (_showResult || _currentContent == null || session == null) return;

    final tappedAt = DateTime.now();
    final correctAnswer = _currentContent!.correctAnswer;
    final locallyVerifiable = gameKitIsLocallyVerifiable(
      selectedAnswer: answer,
      correctAnswer: correctAnswer,
      requiresServerScoring: textInput != null && textInput.isNotEmpty,
    );
    final localCorrect = locallyVerifiable && answer != null && correctAnswer != null
        ? gameKitLocalVerdict(selectedAnswer: answer, correctAnswer: correctAnswer)
        : null;

    _pendingFeedbackTimer?.cancel();
    _feedbackTiming = GameKitFeedbackTiming(
      tappedAt: tappedAt,
      locallyVerifiable: locallyVerifiable,
      localCorrect: localCorrect,
    );

    setState(() {
      _selectedAnswer = answer;
      _textInput = textInput;
      _immediateLocalCorrect = localCorrect;
      if (locallyVerifiable) {
        _feedbackPhase = GameKitFeedbackPhase.localVerdict;
      } else {
        _feedbackPhase = GameKitFeedbackPhase.idle;
      }
    });

    if (!locallyVerifiable) {
      _pendingFeedbackTimer = Timer(
        const Duration(milliseconds: GameKitFeedbackBudget.tapToFeedbackP95Ms),
        () {
          if (!mounted || _showResult) return;
          setState(() => _feedbackPhase = GameKitFeedbackPhase.pending);
        },
      );
    }

    try {
      _kitSession = _baseKitSession();
      final gameSession = _kitSession!;

      final input = GenericGameInput(
        selectedAnswer: answer,
        textInput: textInput,
      );

      final result = await _game.playTurn(_currentContent!, input, gameSession);

      _pendingFeedbackTimer?.cancel();

      final wrongErrorId = result.score.isCorrect
          ? null
          : gameKitInferWrongAnswerErrorType(
              metadata: _currentContent!.metadata,
              gameCategory: _gameCategory.name,
              languageCode: widget.language,
            );

      final practiceTurn = _practiceNotScored || result.score.honestPracticeMode;
      if (practiceTurn) {
        _lastLearnerRecordingPath = textInput;
      }

      setState(() {
        _lastResult = result;
        _showResult = true;
        _feedbackPhase = practiceTurn
            ? GameKitFeedbackPhase.finalVerdict
            : GameKitFeedbackPhase.finalVerdict;
        _wrongAnswerErrorTypeId = practiceTurn ? null : wrongErrorId;
        if (!practiceTurn) {
          if (result.score.isCorrect) {
            _score++;
            _correctStreak++;
            _avatarController?.reactToCorrectAnswer(isPerfect: result.score.accuracy >= 1.0);
            (_avatarKey.currentState as dynamic)?.celebrate();
            if (gameKitShouldTriggerCelebration(_correctStreak)) {
              _showCelebration = true;
            }
          } else {
            _correctStreak = 0;
            _avatarController?.reactToIncorrectAnswer();
            (_avatarKey.currentState as dynamic)?.showDisappointment();
          }
        }
      });

      final turnContext = GameTurnContext(
        content: _currentContent,
        input: input,
        session: gameSession,
        metadata: {
          'itemId': _currentContent!.contentId,
          'skillId': _currentContent!.contentId,
          'gameCategory': _gameCategory.name,
          if (wrongErrorId != null) 'errorTypeIds': [wrongErrorId],
        },
      );
      if (!practiceTurn) {
        _kitSession = await _learnerGraphWriter.recordTurn(
          session: gameSession,
          context: turnContext,
          result: result,
          turnId: '${gameSession.sessionId}_${_round}_${_currentContent!.contentId}',
        );

        await completeTurn(
          cardId: _currentContent!.contentId,
          result: result.score.isCorrect ? GameResult.correct : GameResult.incorrect,
          durationMs: 5000,
          confidence: result.score.accuracy,
          feedback: {
            'selected': answer ?? textInput ?? '',
            'correct': _currentContent!.correctAnswer ?? '',
            'accuracy': result.score.accuracy,
          },
        );
      }

      // Auto-advance after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _loadNewContent();
        }
      });
    } on GameEvaluationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      debugPrint('Error processing answer: $e');
      setError('Failed to process answer. Please try again.');
    }
  }

  Future<void> _endGame() async {
    final kit = _kitSession ?? _baseKitSession();
    int? serverXp;
    if (!_practiceNotScored && session != null) {
      try {
        final gameProv = ref.read(gameProvider.notifier);
        final ended = await gameProv.endGame();
        final claim = await claimGameSessionRewardVerified(
          dio: ref.read(client),
          session: ended,
        );
        serverXp = claim?.xpAwarded;
      } catch (_) {
        serverXp = null;
      }
    }

    if (!mounted) return;
    final payload = GameMasteryResultsPayload.fromSession(
      kit.copyWith(turns: kit.turns),
      serverXpAwarded: serverXp,
    );
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameMasteryResultsScreen(
          payload: payload,
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (isLoading || _currentContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!),
            SizedBox(height: 2.h),
            FilledButton(
              onPressed: () => _loadNewContent(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_round > _maxRounds) {
      return const Center(child: Text('Game Complete!'));
    }

    final definition = AllGamesRegistry.getGame(widget.gameId);
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(definition?.displayName ?? widget.gameId),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        actions: [
          GameAvatarWidget(
            key: _avatarKey,
            category: _gameCategory,
            size: 40,
            isMinimized: true,
          ),
          if (!_practiceNotScored)
            Padding(
              padding: EdgeInsets.all(8.sp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StreakIndicator(streak: _correctStreak),
                  Text('Score: $_score/$_maxRounds', style: TextStyle(fontSize: 12.sp)),
                  Text('Round: $_round/$_maxRounds', style: TextStyle(fontSize: 10.sp)),
                ],
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_practiceNotScored) ...[
              Semantics(
                label: l10n.gamekitPracticeModePracticeLabel,
                child: MaterialBanner(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  content: Text(
                    l10n.gamekitPracticeModePracticeLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  leading: const Icon(Icons.hearing_outlined),
                  actions: const [SizedBox.shrink()],
                ),
              ),
              SizedBox(height: 2.h),
            ],
            SizedBox(height: 4.h),
            // Progress Meter
            ProgressMeter(
              progress: _round / _maxRounds,
              label: 'Progress',
              duelOpponent: _duelOpponentStrip(),
            ),
            SizedBox(height: 4.h),
            // Content Display
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Text(
                      _currentContent!.text,
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (_currentContent!.metadata.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        _currentContent!.metadata.toString(),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            // Options (if available)
            if (_currentContent!.options != null && _currentContent!.options!.isNotEmpty) ...[
              Text(
                'Select the correct answer:',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              ..._currentContent!.options!.map((option) {
                final isSelected = _selectedAnswer == option;
                final isCorrectOption = option == _currentContent!.correctAnswer;

                return GameAnswerTile(
                  text: option,
                  isCorrect: isCorrectOption,
                  isSelected: isSelected,
                  showResult: _showResult,
                  showImmediateLocal: _feedbackPhase == GameKitFeedbackPhase.localVerdict &&
                      isSelected,
                  immediateLocalCorrect: isSelected ? _immediateLocalCorrect : null,
                  onTap: () => _submitAnswer(option, null),
                );
              }),
            ] else ...[
              // Text input
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Enter your answer',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _textInput = value,
                onSubmitted: (value) => _submitAnswer(null, value),
              ),
              SizedBox(height: 2.h),
              FilledButton(
                onPressed: _textInput != null && _textInput!.isNotEmpty
                    ? () => _submitAnswer(null, _textInput)
                    : null,
                child: const Text('Submit'),
              ),
            ],
            if (!_practiceNotScored)
              GameKitVerdictSlot(
                phase: _feedbackPhase,
                isCorrect: _lastResult?.score.isCorrect ?? (_immediateLocalCorrect ?? false),
                correctLabel: l10n.gamekitFeedbackCorrect,
                wrongLabel: l10n.gamekitFeedbackWrong,
                pendingLabel: l10n.gamekitFeedbackPending,
                detailMessage: _showResult ? _lastResult?.feedback.message : null,
              ),
            if (_practiceNotScored && _showResult) ...[
              SizedBox(height: 2.h),
              Text(
                l10n.gamekitPracticeModeInstructions,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 2.h),
              GameKitPracticeReplayPanel(
                modelAudio: GameKitCorrectItemAudio.fromMetadata(
                  _currentContent!.metadata,
                  tonalLanguage: gameKitLanguageIsTonal(widget.language),
                ),
                learnerRecordingPath: _lastLearnerRecordingPath,
                playModelLabel: l10n.gamekitFeedbackTitle,
                playYoursLabel: l10n.gamekitPracticeModeTitle,
                noAudioLabel: l10n.gamekitPracticeModeError,
              ),
            ],
            if (_showResult &&
                !_practiceNotScored &&
                _lastResult != null &&
                !_lastResult!.score.isCorrect &&
                _wrongAnswerErrorTypeId != null &&
                _currentContent != null) ...[
              SizedBox(height: 2.h),
              GameKitWhyWrongPanel(
                errorTypeId: _wrongAnswerErrorTypeId!,
                correctAnswerText: _currentContent!.correctAnswer ?? '',
                audio: GameKitCorrectItemAudio.fromMetadata(
                  _currentContent!.metadata,
                  tonalLanguage: gameKitLanguageIsTonal(widget.language),
                ),
                title: l10n.gamekitFeedbackTitle,
                whyWrongLabel: l10n.gamekitFeedbackWhyWrong,
                playAudioLabel: l10n.gamekitFeedbackTitle,
                noAudioLabel: 'No audio yet for this answer',
                loadingLabel: l10n.gamekitFeedbackPending,
              ),
            ],
            if (!_practiceNotScored && _showCelebration && reduceMotion)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: GameKitStaticCelebrationChip(
                  message: l10n.gamekitFeedbackStreak(_correctStreak),
                ),
              ),
          ],
        ),
      ),
          if (!_practiceNotScored && _showCelebration && !reduceMotion)
            Positioned(
              top: 8.h,
              left: 0,
              right: 0,
              child: GameKitStreakCelebration(
                streak: _correctStreak,
                message: l10n.gamekitFeedbackStreak(_correctStreak),
                reduceMotion: reduceMotion,
                onFinished: () {
                  if (mounted) setState(() => _showCelebration = false);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Compare model vs learner audio without correctness claims (P8-911 AC3).
class GameKitPracticeReplayPanel extends StatelessWidget {
  const GameKitPracticeReplayPanel({
    super.key,
    required this.modelAudio,
    required this.learnerRecordingPath,
    required this.playModelLabel,
    required this.playYoursLabel,
    required this.noAudioLabel,
  });

  final GameKitCorrectItemAudio modelAudio;
  final String? learnerRecordingPath;
  final String playModelLabel;
  final String playYoursLabel;
  final String noAudioLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FilledButton.tonal(
          onPressed: modelAudio.hasPlayableAudio
              ? () => gameKitPlayExplanationAudio(modelAudio.uri!)
              : null,
          child: Text(playModelLabel),
        ),
        FilledButton.tonal(
          onPressed: learnerRecordingPath != null && learnerRecordingPath!.isNotEmpty
              ? () => gameKitPlayExplanationAudio(learnerRecordingPath!)
              : null,
          child: Text(playYoursLabel),
        ),
      ],
    );
  }
}


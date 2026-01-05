import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../screens/games/base_game_screen.dart';
import '../../models/game/game_session_model.dart';
import '../../services/polie_game_client.dart';
import '../../services/rive_gamification_service.dart';
import '../gamekit/game_session.dart';
import '../gamekit/game_animation_bridge.dart';
import '../animation/rive_game_guide.dart';
import 'drum_rhythm_game.dart';
import 'drum_rhythm_models.dart';
import '../../games/widgets/game_answer_tile.dart';
import '../../games/widgets/streak_indicator.dart';
import '../../games/widgets/progress_meter.dart';

/// Drum Rhythm game screen - Migrated to GameKit
class DrumRhythmScreen extends BaseGameScreen {
  const DrumRhythmScreen({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.drumRhythmShadowing;

  @override
  ConsumerState<DrumRhythmScreen> createState() => _DrumRhythmScreenState();
}

class _DrumRhythmScreenState extends BaseGameScreenState<DrumRhythmScreen> {
  late DrumRhythmGame _game;
  late PolieGameClient _polieClient;
  late GameAnimationBridge _animationBridge;
  late RiveGameGuideController _guideController;
  
  DrumRhythmContent? _currentContent;
  String? _selectedWord;
  bool _showResult = false;
  GameTurnResult? _lastResult;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;

  @override
  void initState() {
    super.initState();
    _guideController = RiveGameGuideController();
    _animationBridge = GameAnimationBridge(guideController: _guideController);
    _polieClient = PolieGameClient();
    _game = DrumRhythmGameFactory.create(
      polieClient: _polieClient,
      animationBridge: _animationBridge,
    );
    
    // Initialize Rive controller after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final riveService = ref.read(riveGamificationServiceProvider);
      riveService.setController(_guideController);
    });
  }

  @override
  Future<void> onGameInitialized() async {
    await _loadNewRhythm();
  }

  Future<void> _loadNewRhythm() async {
    if (session == null) return;
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      _showResult = false;
      _selectedWord = null;
      _lastResult = null;
    });

    try {
      final gameSession = GameSession(
        sessionId: session!.sessionId,
        userId: session!.userId,
        gameId: _game.config.gameId,
        language: widget.language,
        level: widget.level,
        startTime: session!.startTime,
        turns: [],
      );

      _currentContent = await _game.loadContent(gameSession);
      _round++;
      setState(() {});
    } catch (e) {
      debugPrint('Error loading rhythm: $e');
    }
  }

  Future<void> _selectWord(String word) async {
    if (_showResult || _currentContent == null || session == null) return;

    setState(() {
      _selectedWord = word;
    });

    try {
      final gameSession = GameSession(
        sessionId: session!.sessionId,
        userId: session!.userId,
        gameId: _game.config.gameId,
        language: widget.language,
        level: widget.level,
        startTime: session!.startTime,
        turns: [],
      );

      final input = DrumRhythmInput(selectedWord: word);
      final result = await _game.playTurn(_currentContent!, input, gameSession);

      setState(() {
        _lastResult = result;
        _showResult = true;
        if (result.score.isCorrect) {
          _score++;
        }
      });

      // Record turn
      await completeTurn(
        cardId: _currentContent!.contentId,
        result: result.score.isCorrect ? GameResult.correct : GameResult.incorrect,
        durationMs: 5000,
        confidence: result.score.accuracy,
        feedback: {
          'pattern': _currentContent!.pattern,
          'selected': word,
          'correct': _currentContent!.correctWord,
          'accuracy': result.score.accuracy,
        },
      );

      // Auto-advance after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _loadNewRhythm();
        }
      });
    } catch (e) {
      debugPrint('Error processing word selection: $e');
    }
  }

  Future<void> _endGame() async {
    final accuracy = _score / _maxRounds;
    await finishGame();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Game Complete!'),
          content: Text('You scored $_score out of $_maxRounds!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
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
              onPressed: () => _loadNewRhythm(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_round > _maxRounds) {
      return const Center(child: Text('Game Complete!'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.getGameType().displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(8.sp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Score: $_score/$_maxRounds', style: TextStyle(fontSize: 12.sp)),
                Text('Round: $_round/$_maxRounds', style: TextStyle(fontSize: 10.sp)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 4.h),
            // Rive Guide Character
            Center(
              child: RiveGameGuide(
                controller: _guideController,
                width: 120.w,
                height: 120.h,
              ),
            ),
            SizedBox(height: 4.h),
            // Progress Meter
            ProgressMeter(
              progress: _round / _maxRounds,
              label: 'Progress',
            ),
            SizedBox(height: 4.h),
            // Rhythm Pattern Display
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Icon(Icons.music_note, size: 48.sp, color: Colors.orange),
                    SizedBox(height: 2.h),
                    Text(
                      'Drum Rhythm Pattern',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _currentContent!.pattern,
                      style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600, letterSpacing: 2),
                      textAlign: TextAlign.center,
                    ),
                    if (_currentContent!.context.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        _currentContent!.context,
                        style: TextStyle(fontSize: 12.sp),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Which word matches this rhythm?',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            // Word Options using GameAnswerTile
            ..._currentContent!.options.map((word) {
              final isSelected = _selectedWord == word;
              final isCorrectOption = word == _currentContent!.correctWord;

              return GameAnswerTile(
                text: word.toUpperCase(),
                isCorrect: isCorrectOption,
                isSelected: isSelected,
                showResult: _showResult,
                icon: Icons.volume_up,
                onTap: () => _selectWord(word),
              );
            }),
            if (_showResult && _lastResult != null) ...[
              SizedBox(height: 2.h),
              Card(
                color: _lastResult!.score.isCorrect
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      Icon(
                        _lastResult!.score.isCorrect ? Icons.check_circle : Icons.cancel,
                        color: _lastResult!.score.isCorrect ? Colors.green : Colors.red,
                        size: 32.sp,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _lastResult!.feedback.message,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: _lastResult!.score.isCorrect ? Colors.green : Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


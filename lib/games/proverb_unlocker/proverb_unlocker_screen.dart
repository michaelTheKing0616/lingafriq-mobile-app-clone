import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../screens/games/base_game_screen.dart';
import '../../models/game/game_session_model.dart';
import '../../services/polie_game_client.dart';
import '../gamekit/game_session.dart';
import '../gamekit/game_animation_bridge.dart';
import '../animation/rive_game_guide.dart';
import 'proverb_unlocker_game.dart';
import 'proverb_unlocker_models.dart';
import 'dart:math';

/// ProverbUnlocker game screen - Refactored to use GameKit
/// This replaces the old implementation with random logic
class ProverbUnlockerScreen extends BaseGameScreen {
  const ProverbUnlockerScreen({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.proverbUnlocker;

  @override
  ConsumerState<ProverbUnlockerScreen> createState() => _ProverbUnlockerScreenState();
}

class _ProverbUnlockerScreenState extends BaseGameScreenState<ProverbUnlockerScreen> {
  late ProverbUnlockerGame _game;
  late PolieGameClient _polieClient;
  late GameAnimationBridge _animationBridge;
  late RiveGameGuideController _guideController;
  
  ProverbUnlockerContent? _currentContent;
  String? _selectedAnswer;
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
    _game = ProverbUnlockerGameFactory.create(
      polieClient: _polieClient,
      animationBridge: _animationBridge,
    );
  }

  @override
  Future<void> onGameInitialized() async {
    await _loadNewProverb();
  }

  Future<void> _loadNewProverb() async {
    if (session == null) return;
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      _showResult = false;
      _selectedAnswer = null;
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
      debugPrint('Error loading proverb: $e');
    }
  }

  Future<void> _selectAnswer(String answer) async {
    if (_showResult || _currentContent == null || session == null) return;

    setState(() {
      _selectedAnswer = answer;
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

      final input = ProverbUnlockerInput(selectedAnswer: answer);
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
          'proverb': _currentContent!.proverb,
          'selected': answer,
          'correct': _currentContent!.correctAnswer,
          'accuracy': result.score.accuracy,
        },
      );

      // Auto-advance after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _loadNewProverb();
        }
      });
    } catch (e) {
      debugPrint('Error processing answer: $e');
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
              onPressed: () => _loadNewProverb(),
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
            // Proverb Display
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Icon(Icons.lightbulb, size: 48.sp, color: Colors.amber),
                    SizedBox(height: 2.h),
                    Text(
                      'Proverb in ${widget.language}',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _currentContent!.proverb,
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    if (_currentContent!.translation.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        _currentContent!.translation,
                        style: TextStyle(fontSize: 14.sp, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'What does this proverb mean?',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            // Multiple Choice Options
            ..._currentContent!.options.map((option) {
              final isSelected = _selectedAnswer == option;
              final isCorrectOption = option == _currentContent!.correctAnswer;
              
              Color? backgroundColor;
              if (_showResult) {
                if (isCorrectOption) {
                  backgroundColor = Colors.green.withOpacity(0.3);
                } else if (isSelected && !isCorrectOption) {
                  backgroundColor = Colors.red.withOpacity(0.3);
                }
              } else if (isSelected) {
                backgroundColor = Colors.blue.withOpacity(0.3);
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Card(
                  color: backgroundColor,
                  child: ListTile(
                    title: Text(option),
                    trailing: _showResult && isCorrectOption
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrectOption
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectAnswer(option),
                  ),
                ),
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
            ],
          ],
        ),
      ),
    );
  }
}


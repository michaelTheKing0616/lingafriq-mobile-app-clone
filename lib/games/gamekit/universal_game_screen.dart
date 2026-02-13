import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../screens/games/base_game_screen.dart';
import '../../services/polie_game_client.dart';
import '../../models/game/game_session_model.dart' show GameType, GameResult;
import 'generic_game_template.dart';
import 'game_session.dart';
import 'all_games_registry.dart';
import '../widgets/game_answer_tile.dart';
import '../widgets/progress_meter.dart';
import 'game_result.dart';
import '../../avatars/avatars.dart';

/// Universal game screen that works for any game using GenericGame
/// This allows all 37+ games to use the same GameKit implementation
class UniversalGameScreen extends BaseGameScreen {
  final String gameId;

  const UniversalGameScreen({
    Key? key,
    required super.language,
    required this.gameId,
    super.level,
    super.onBack,
  }) : super(key: key);

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
  int _round = 0;
  final int _maxRounds = 10;
  
  // Game avatar controller
  GameAvatarController? _avatarController;
  GameCategory _gameCategory = GameCategory.vocabulary;
  final GlobalKey<State<GameAvatarWidget>> _avatarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _game = AllGamesRegistry.createGame(ref, widget.gameId);
    _initializeAvatar();
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
    _avatarController?.dispose();
    super.dispose();
  }

  @override
  Future<void> onGameInitialized() async {
    await _loadNewContent();
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
    });

    try {
      final gameSession = GameSession(
        sessionId: session!.sessionId,
        userId: session!.userId,
        gameId: widget.gameId,
        language: widget.language,
        level: widget.level,
        startTime: session!.startTime,
        turns: [],
      );

      _currentContent = await _game.loadContent(gameSession);
      _round++;
      setState(() {});
    } catch (e) {
      debugPrint('Error loading content: $e');
      setError('Failed to load content. Please try again.');
    }
  }

  Future<void> _submitAnswer(String? answer, String? textInput) async {
    if (_showResult || _currentContent == null || session == null) return;

    setState(() {
      _selectedAnswer = answer;
      _textInput = textInput;
    });

    try {
      final gameSession = GameSession(
        sessionId: session!.sessionId,
        userId: session!.userId,
        gameId: widget.gameId,
        language: widget.language,
        level: widget.level,
        startTime: session!.startTime,
        turns: [],
      );

      final input = GenericGameInput(
        selectedAnswer: answer,
        textInput: textInput,
      );

      final result = await _game.playTurn(_currentContent!, input, gameSession);

      setState(() {
        _lastResult = result;
        _showResult = true;
        if (result.score.isCorrect) {
          _score++;
          // Avatar celebrates correct answer
          _avatarController?.reactToCorrectAnswer(isPerfect: result.score.accuracy >= 1.0);
          (_avatarKey.currentState as dynamic)?.celebrate();
        } else {
          // Avatar shows encouragement for incorrect answer
          _avatarController?.reactToIncorrectAnswer();
          (_avatarKey.currentState as dynamic)?.showDisappointment();
        }
      });

      // Record turn
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

    return Scaffold(
      appBar: AppBar(
        title: Text(definition?.displayName ?? widget.gameId),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        actions: [
          // Game Avatar in app bar
          GameAvatarWidget(
            key: _avatarKey,
            category: _gameCategory,
            size: 40,
            isMinimized: true,
          ),
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
            // Progress Meter
            ProgressMeter(
              progress: _round / _maxRounds,
              label: 'Progress',
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


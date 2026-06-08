import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/game/game_session_model.dart';
import '../../../models/game/game_content_models.dart';
import '../../../services/polie_content_generator.dart';
import '../game_scenario_loader.dart';
import '../../../widgets/error_boundary.dart';
import '../../loading/dynamic_loading_screen.dart';
import '../base_game_screen.dart';
import '../mixins/round_progress_shell_mixin.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Rhythm Typing Game
class RhythmTypingGame extends BaseGameScreen {
  const RhythmTypingGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.rhythmTyping;

  @override
  ConsumerState<RhythmTypingGame> createState() => _RhythmTypingGameState();
}

class _RhythmTypingGameState extends BaseGameScreenState<RhythmTypingGame>
    with RoundProgressGameShellMixin<RhythmTypingGame> {

  Future<void> _initializeGame() async {
    setLoading(true); setError(null);
    try {
      ref.read(polieContentGeneratorProvider);
      // Initialize game content
      setLoading(false);
    } catch (e) {
      setLoading(false); setError(e.toString());
    }
  }
  String? _targetText;
  String? _rhythmPattern;
  final TextEditingController _inputController = TextEditingController();
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;

  @override
  int get gameRound => _round;

  @override
  int get gameMaxRounds => _maxRounds;

  @override
  int get gameScore => _score;
  
  bool _isComplete = false;
  List<GameWord> _bundledWords = [];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  bool get requiresPhraseCards => false;

  @override
  Future<void> onGameInitialized() async {
    _bundledWords = loadBundledGameWords(
      ref,
      language: widget.language,
      gameTag: 'SpeedRound',
      max: 24,
    );
    await _loadNewChallenge();
  }

  Future<void> _loadNewChallenge() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _isComplete = false;
      _inputController.clear();
    });

    if (_bundledWords.isNotEmpty) {
      final w = _bundledWords[_round % _bundledWords.length];
      setState(() {
        _round++;
        _targetText = w.word;
        _rhythmPattern = w.tonalNote ?? 'DUM · da · DUM';
        setLoading(false);
      });
      return;
    }

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateRhythmTyping(widget.language);

      final content = gameContent['content']?.toString() ?? '';
      final parsed = _parseChallenge(content);

      setState(() {
        _round++;
        _targetText = parsed['text'];
        _rhythmPattern = parsed['rhythm'];
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading challenge: $e');
      // Use fallback content so game is still playable
      setState(() {
        _round++;
        _targetText = _getFallbackText();
        _rhythmPattern = 'DUM da-da DUM';
        setLoading(false);
      });
    }
  }

  Map<String, dynamic> _parseChallenge(String content) {
    final lines = content.split('\n');
    String? text;
    String? rhythm;

    for (var line in lines) {
      if (line.toLowerCase().contains('text:') || line.toLowerCase().contains('word:')) {
        text = line.split(':').skip(1).join(':').trim();
      }
      if (line.toLowerCase().contains('rhythm:') || line.toLowerCase().contains('pattern:')) {
        rhythm = line.split(':').skip(1).join(':').trim();
      }
    }

    return {
      'text': text ?? _getFallbackText(),
      'rhythm': rhythm ?? 'DUM da-da DUM',
    };
  }

  String _getFallbackText() {
    final texts = {
      'Yoruba': 'Bàwo ni?',
      'Swahili': 'Habari?',
      'Hausa': 'Yaya kake?',
      'Igbo': 'Kedu?',
    };
    return texts[widget.language] ?? 'Hello';
  }

  void _checkInput() {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    final isCorrect = input.toLowerCase() == _targetText?.toLowerCase();

    if (isCorrect && !_isComplete) {
      setState(() {
        _isComplete = true;
        _score++;
      });

      completeTurn(
        cardId: 'typing_$_round',
        result: GameResult.correct,
        durationMs: 2000,
        confidence: 1.0,
        feedback: {'text': _targetText, 'input': input},
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _loadNewChallenge();
        }
      });
    }
  }

  Future<void> _endGame() async {
    await finishGame();

    if (mounted) {
      final accuracy = _score / _maxRounds;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Typing Complete!'),
          content: Text('You typed $_score out of $_maxRounds correctly!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
    try {
      if (isLoading) {
        return DynamicLoadingScreen();
      }

      if (error != null) {
      return ErrorBoundary(
        errorMessage: error!,
        onRetry: () => _initializeGame(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!),
              SizedBox(height: 2.h),
              FilledButton(
                onPressed: () => _initializeGame(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_round > _maxRounds) {
      return const Center(child: Text('Game Complete!'));
    }

    return SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 4.h),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Icon(Icons.keyboard, size: 48.sp, color: Colors.purple),
                    SizedBox(height: 2.h),
                    if (_rhythmPattern != null) ...[
                      Text(
                        'Rhythm: $_rhythmPattern',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                    ],
                    Text(
                      'Type this text:',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      child: Text(
                        _targetText ?? '',
                        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: 'Type the text above',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _checkInput,
                ),
              ),
              onSubmitted: (_) => _checkInput(),
              enabled: !_isComplete,
            ),
            if (_isComplete) ...[
              SizedBox(height: 2.h),
              Card(
                color: Colors.green.withOpacity(0.2),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 32),
                      SizedBox(height: 1.h),
                      Text(
                        'Correct!',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
    );
    } catch (e, st) {
      debugPrint('RhythmTypingGame buildGameContent: $e $st');
      rethrow;
    }
  }
}







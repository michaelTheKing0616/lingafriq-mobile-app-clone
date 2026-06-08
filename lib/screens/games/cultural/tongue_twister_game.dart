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

/// Rapid Tongue Twister Race Game
class TongueTwisterGame extends BaseGameScreen {
  const TongueTwisterGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.rapidTongueTwisterRace;

  @override
  ConsumerState<TongueTwisterGame> createState() => _TongueTwisterGameState();
}

class _TongueTwisterGameState extends BaseGameScreenState<TongueTwisterGame>
    with RoundProgressGameShellMixin<TongueTwisterGame> {

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
  String? _currentTwister;
  String? _pronunciationGuide;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;

  @override
  int get gameRound => _round;

  @override
  int get gameMaxRounds => _maxRounds;

  @override
  int get gameScore => _score;
  
  bool _hasCompleted = false;
  int _attempts = 0;

  List<GameProverb> _bundledProverbs = [];

  @override
  bool get requiresPhraseCards => false;

  @override
  Future<void> onGameInitialized() async {
    _bundledProverbs = loadBundledProverbs(
      ref,
      language: widget.language,
      gameTag: 'ProverbUnlocker',
      max: 12,
    );
    await _loadNewTwister();
  }

  Future<void> _loadNewTwister() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _hasCompleted = false;
      _attempts = 0;
    });

    if (_bundledProverbs.isNotEmpty) {
      final p = _bundledProverbs[_round % _bundledProverbs.length];
      setState(() {
        _round++;
        _currentTwister = p.original;
        _pronunciationGuide = p.meaning ?? p.translation;
        setLoading(false);
      });
      return;
    }

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateTongueTwister(widget.language);

      final content = gameContent['content']?.toString() ?? '';
      final parsed = _parseTwister(content);

      setState(() {
        _round++;
        _currentTwister = parsed['twister'];
        _pronunciationGuide = parsed['guide'];
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading tongue twister: $e');
      // Use fallback content so game is still playable
      setState(() {
        _round++;
        _currentTwister = _getFallbackTwister();
        _pronunciationGuide = 'Practice saying this quickly!';
        setLoading(false);
      });
    }
  }

  Map<String, dynamic> _parseTwister(String content) {
    final lines = content.split('\n');
    String? twister;
    String? guide;

    for (var line in lines) {
      if (line.toLowerCase().contains('twister:') || line.toLowerCase().contains('phrase:')) {
        twister = line.split(':').skip(1).join(':').trim();
      }
      if (line.toLowerCase().contains('pronunciation:') || line.toLowerCase().contains('guide:')) {
        guide = line.split(':').skip(1).join(':').trim();
      }
    }

    return {
      'twister': twister ?? _getFallbackTwister(),
      'guide': guide ?? 'Practice saying this quickly!',
    };
  }

  String _getFallbackTwister() {
    final twisters = {
      'Yoruba': 'Bàbá bá bàbá bá bàbá bá bàbá',
      'Swahili': 'Kaka kuku kaka kuku',
      'Hausa': 'Kaka kaka kaka',
      'Igbo': 'Nne nne nne',
    };
    return twisters[widget.language] ?? 'Practice makes perfect';
  }

  void _markComplete() {
    if (_hasCompleted) return;

    setState(() {
      _hasCompleted = true;
      _score++;
      _attempts++;
    });

    completeTurn(
      cardId: 'twister_$_round',
      result: GameResult.correct,
      durationMs: 2000,
      confidence: 1.0,
      feedback: {'twister': _currentTwister, 'attempts': _attempts},
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _loadNewTwister();
      }
    });
  }

  void _addAttempt() {
    setState(() {
      _attempts++;
    });
  }

  Future<void> _endGame() async {
    await finishGame();

    if (mounted) {
      final accuracy = _score / _maxRounds;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Race Complete!'),
          content: Text('You completed $_score out of $_maxRounds tongue twisters!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
                    Icon(Icons.speed, size: 48.sp, color: Colors.red),
                    SizedBox(height: 2.h),
                    Text(
                      'Say this as fast as you can:',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _currentTwister ?? '',
                        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (_pronunciationGuide != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        _pronunciationGuide!,
                        style: TextStyle(fontSize: 14.sp, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _hasCompleted ? null : _addAttempt,
                    icon: const Icon(Icons.repeat),
                    label: Text('Try Again (Attempts: $_attempts)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 3.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _hasCompleted ? null : _markComplete,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('I Did It!'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 3.h),
                    ),
                  ),
                ),
              ],
            ),
            if (_hasCompleted) ...[
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
                        'Great job!',
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
      debugPrint('TongueTwisterGame buildGameContent: $e $st');
      rethrow;
    }
  }
}







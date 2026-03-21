import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/game/game_session_model.dart';
import '../../../services/polie_content_generator.dart';
import '../../../widgets/error_boundary.dart';
import '../../loading/dynamic_loading_screen.dart';
import '../base_game_screen.dart';
import '../mixins/round_progress_shell_mixin.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

/// Drum-to-Word Matching Game
class DrumWordGame extends BaseGameScreen {
  const DrumWordGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.drumToWordMatching;

  @override
  ConsumerState<DrumWordGame> createState() => _DrumWordGameState();
}

class _DrumWordGameState extends BaseGameScreenState<DrumWordGame>
    with RoundProgressGameShellMixin<DrumWordGame> {

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
  String? _rhythmPattern;
  List<String> _wordOptions = [];
  String? _selectedWord;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;

  @override
  int get gameRound => _round;

  @override
  int get gameMaxRounds => _maxRounds;

  @override
  int get gameScore => _score;
  
  String _correctWord = '';

  @override
  Future<void> onGameInitialized() async {
    await _loadNewChallenge();
  }

  Future<void> _loadNewChallenge() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _showResult = false;
      _selectedWord = null;
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateDrumWordMatching(widget.language);

      final content = gameContent['content']?.toString() ?? '';
      final parsed = _parseChallenge(content);

      setState(() {
        _round++;
        _rhythmPattern = parsed['rhythm'];
        _correctWord = parsed['word'];
        _wordOptions = parsed['words'];
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading challenge: $e');
      setState(() {
        setLoading(false);
        _rhythmPattern = 'DUM da-da DUM';
        _correctWord = 'Bàtà';
        _wordOptions = ['Bàtà', 'Ọmọ', 'Ìyá', 'Bàbá'];
        _wordOptions.shuffle(Random());
      });
    }
  }

  Map<String, dynamic> _parseChallenge(String content) {
    final lines = content.split('\n');
    String? rhythm;
    String? word;
    final words = <String>[];

    for (var line in lines) {
      if (line.toLowerCase().contains('rhythm:') || line.toLowerCase().contains('pattern:')) {
        rhythm = line.split(':').skip(1).join(':').trim();
      }
      if (line.toLowerCase().contains('word:') || line.toLowerCase().contains('phrase:')) {
        word = line.split(':').skip(1).join(':').trim();
      }
      if (line.trim().startsWith(RegExp(r'[A-D]\.|1\.|2\.|3\.|4\.'))) {
        words.add(line.replaceFirst(RegExp(r'^[A-D1-4]\.\s*'), '').trim());
      }
    }

    if (words.length < 4) {
      words.addAll(['Bàtà', 'Ọmọ', 'Ìyá', 'Bàbá']);
    }

    return {
      'rhythm': rhythm ?? 'DUM da-da DUM',
      'word': word ?? words.first,
      'words': words.take(4).toList(),
    };
  }

  void _selectWord(String word) {
    if (_showResult) return;

    final isCorrect = word == _correctWord;

    setState(() {
      _selectedWord = word;
      _isCorrect = isCorrect;
      _showResult = true;

      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'drum_word_$_round',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 3000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {'rhythm': _rhythmPattern, 'word': word},
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadNewChallenge();
      }
    });
  }

  Future<void> _endGame() async {
    await finishGame();

    if (mounted) {
      final accuracy = _score / _maxRounds;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Matching Complete!'),
          content: Text('You matched $_score out of $_maxRounds drum patterns!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
                    Icon(Icons.music_note, size: 48.sp, color: Colors.brown),
                    SizedBox(height: 2.h),
                    Text(
                      'Drum Rhythm Pattern:',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.brown[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.brown[200]!),
                      ),
                      child: Text(
                        _rhythmPattern ?? '',
                        style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Which word matches this rhythm?',
                      style: TextStyle(fontSize: 14.sp),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Select the matching word:',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ..._wordOptions.map((word) {
              final isSelected = _selectedWord == word;
              final isCorrect = word == _correctWord;

              Color? backgroundColor;
              if (_showResult) {
                if (isCorrect) {
                  backgroundColor = Colors.green.withOpacity(0.3);
                } else if (isSelected && !isCorrect) {
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
                    leading: Icon(Icons.music_note, color: Colors.brown),
                    title: Text(word, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600)),
                    trailing: _showResult && isCorrect
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrect
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectWord(word),
                  ),
                ),
              );
            }),
            if (_showResult) ...[
              SizedBox(height: 2.h),
              Card(
                color: _isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      Icon(
                        _isCorrect ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect ? Colors.green : Colors.red,
                        size: 32.sp,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _isCorrect ? 'Perfect match!' : 'Not matching',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: _isCorrect ? Colors.green : Colors.red,
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
      debugPrint('DrumWordGame buildGameContent: $e $st');
      rethrow;
    }
  }
}







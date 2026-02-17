import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/game/game_session_model.dart';
import '../../../services/polie_content_generator.dart';
import '../../../widgets/error_boundary.dart';
import '../../loading/dynamic_loading_screen.dart';
import '../base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

/// Accent Decoding Puzzle Game
class AccentPuzzleGame extends BaseGameScreen {
  const AccentPuzzleGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.accentDecodingPuzzle;

  @override
  ConsumerState<AccentPuzzleGame> createState() => _AccentPuzzleGameState();
}

class _AccentPuzzleGameState extends BaseGameScreenState<AccentPuzzleGame> {

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
  String? _targetWord;
  List<String> _regionOptions = [];
  String? _selectedRegion;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  
  String _correctRegion = '';

  @override
  Future<void> onGameInitialized() async {
    await _loadNewPuzzle();
  }

  Future<void> _loadNewPuzzle() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _showResult = false;
      _selectedRegion = null;
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateAccentPuzzle(widget.language);

      final content = gameContent['content']?.toString() ?? '';
      final parsed = _parsePuzzle(content);

      setState(() {
        _round++;
        _targetWord = parsed['word'];
        _correctRegion = parsed['correctRegion'];
        _regionOptions = parsed['regions'];
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading puzzle: $e');
      // Use fallback content so game is still playable
      final regions = ['Northern', 'Southern', 'Central', 'Eastern']..shuffle(Random());
      setState(() {
        _round++;
        _targetWord = _getFallbackWord();
        _correctRegion = 'Central';
        _regionOptions = regions;
        setLoading(false);
      });
    }
  }

  Map<String, dynamic> _parsePuzzle(String content) {
    final lines = content.split('\n');
    String? word;
    String? correctRegion;
    final regions = <String>[];

    for (var line in lines) {
      if (line.toLowerCase().contains('word:') || line.toLowerCase().contains('phrase:')) {
        word = line.split(':').skip(1).join(':').trim();
      }
      if (line.toLowerCase().contains('region:') || line.toLowerCase().contains('correct:')) {
        correctRegion = line.split(':').skip(1).join(':').trim();
      }
      if (line.trim().startsWith(RegExp(r'[A-D]\.|1\.|2\.|3\.|4\.'))) {
        regions.add(line.replaceFirst(RegExp(r'^[A-D1-4]\.\s*'), '').trim());
      }
    }

    if (regions.length < 4) {
      regions.addAll(['Northern', 'Southern', 'Central', 'Eastern']);
    }

    return {
      'word': word ?? _getFallbackWord(),
      'correctRegion': correctRegion ?? regions.first,
      'regions': regions.take(4).toList()..shuffle(Random()),
    };
  }

  String _getFallbackWord() {
    final words = {
      'Yoruba': 'Bàtà',
      'Swahili': 'Jambo',
      'Hausa': 'Sannu',
      'Igbo': 'Kedu',
    };
    return words[widget.language] ?? 'Hello';
  }

  void _selectRegion(String region) {
    if (_showResult) return;

    final isCorrect = region == _correctRegion;

    setState(() {
      _selectedRegion = region;
      _isCorrect = isCorrect;
      _showResult = true;

      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'puzzle_$_round',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 3000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {'word': _targetWord, 'region': region},
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadNewPuzzle();
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
          title: const Text('Puzzle Complete!'),
          content: Text('You matched $_score out of $_maxRounds accents!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
  List<Widget>? get appBarActions {
    if (isLoading || _round > _maxRounds) return null;
    return [
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
    ];
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
                    Icon(Icons.language, size: 48.sp, color: Colors.blue),
                    SizedBox(height: 2.h),
                    Text(
                      'Match the accent to its region:',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        _targetWord ?? '',
                        style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Select the correct region:',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ..._regionOptions.map((region) {
              final isSelected = _selectedRegion == region;
              final isCorrect = region == _correctRegion;

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
                    leading: Icon(Icons.location_on, color: Colors.blue),
                    title: Text(region),
                    trailing: _showResult && isCorrect
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrect
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectRegion(region),
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
                        _isCorrect ? 'Correct region!' : 'Wrong region',
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
      ),
    );
    } catch (e, st) {
      debugPrint('AccentPuzzleGame buildGameContent: $e $st');
      rethrow;
    }
  }
}







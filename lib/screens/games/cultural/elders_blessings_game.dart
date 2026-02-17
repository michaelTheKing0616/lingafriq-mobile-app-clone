import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/game/game_session_model.dart';
import '../../../services/polie_content_generator.dart';
import '../../../widgets/error_boundary.dart';
import '../../loading/dynamic_loading_screen.dart';
import '../base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

/// Elders' Blessings Challenge Game
class EldersBlessingsGame extends BaseGameScreen {
  const EldersBlessingsGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.eldersBlessingsChallenge;

  @override
  ConsumerState<EldersBlessingsGame> createState() => _EldersBlessingsGameState();
}

class _EldersBlessingsGameState extends BaseGameScreenState<EldersBlessingsGame> {

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
  // ignore: unused_field
  Map<String, dynamic>? _currentBlessing;
  List<String> _meaningOptions = [];
  String? _selectedMeaning;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  
  String _blessingText = '';
  String _correctMeaning = '';

  @override
  Future<void> onGameInitialized() async {
    await _loadNewBlessing();
  }

  Future<void> _loadNewBlessing() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _showResult = false;
      _selectedMeaning = null;
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateEldersBlessings(widget.language);

      final content = gameContent['content']?.toString() ?? '';
      final parsed = _parseBlessing(content);

      setState(() {
        _currentBlessing = gameContent;
        _round++;
        _blessingText = parsed['blessing'];
        _correctMeaning = parsed['meaning'];
        _meaningOptions = parsed['options'];
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading blessing: $e');
      // Use fallback content so game is still playable
      final options = ['May you have long life and prosperity', 'Good luck', 'Stay safe', 'Be happy']..shuffle(Random());
      setState(() {
        _currentBlessing = {'content': _getFallbackBlessing()};
        _round++;
        _blessingText = _getFallbackBlessing();
        _correctMeaning = 'May you have long life and prosperity';
        _meaningOptions = options;
        setLoading(false);
      });
    }
  }

  Map<String, dynamic> _parseBlessing(String content) {
    final lines = content.split('\n');
    String? blessing;
    String? meaning;
    final options = <String>[];

    for (var line in lines) {
      if (line.toLowerCase().contains('blessing:') || line.toLowerCase().contains('phrase:')) {
        blessing = line.split(':').skip(1).join(':').trim();
      }
      if (line.toLowerCase().contains('meaning:') || line.toLowerCase().contains('translation:')) {
        meaning = line.split(':').skip(1).join(':').trim();
      }
      if (line.trim().startsWith(RegExp(r'[A-D]\.|1\.|2\.|3\.|4\.'))) {
        options.add(line.replaceFirst(RegExp(r'^[A-D1-4]\.\s*'), '').trim());
      }
    }

    if (options.length < 4) {
      options.addAll(['May you have long life and prosperity', 'Good luck', 'Stay safe', 'Be happy']);
    }

    return {
      'blessing': blessing ?? _getFallbackBlessing(),
      'meaning': meaning ?? options.first,
      'options': options.take(4).toList()..shuffle(Random()),
    };
  }

  String _getFallbackBlessing() {
    final blessings = {
      'Yoruba': 'Àṣẹ pẹlẹ́',
      'Swahili': 'Baraka',
      'Hausa': 'Albarka',
      'Igbo': 'Ngozi',
    };
    return blessings[widget.language] ?? 'Blessing';
  }

  void _selectMeaning(String meaning) {
    if (_showResult) return;

    final isCorrect = meaning == _correctMeaning || meaning == _meaningOptions.first;

    setState(() {
      _selectedMeaning = meaning;
      _isCorrect = isCorrect;
      _showResult = true;

      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'blessing_$_round',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 3000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {'blessing': _blessingText, 'meaning': meaning},
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadNewBlessing();
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
          title: const Text('Blessings Complete!'),
          content: Text('You learned $_score out of $_maxRounds blessings!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
                    Icon(Icons.favorite, size: 48.sp, color: Colors.pink),
                    SizedBox(height: 2.h),
                    Text(
                      'Elder\'s Blessing:',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink[200]!),
                      ),
                      child: Text(
                        _blessingText,
                        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'What does this blessing mean?',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ..._meaningOptions.map((meaning) {
              final isSelected = _selectedMeaning == meaning;
              final isCorrect = meaning == _correctMeaning || meaning == _meaningOptions.first;

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
                    leading: Icon(Icons.favorite, color: Colors.pink),
                    title: Text(meaning),
                    trailing: _showResult && isCorrect
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrect
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectMeaning(meaning),
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
                        _isCorrect ? 'Correct!' : 'Incorrect',
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
      debugPrint('EldersBlessingsGame buildGameContent: $e $st');
      rethrow;
    }
  }
}







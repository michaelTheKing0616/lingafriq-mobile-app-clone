import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import '../../services/polie_content_generator.dart';
import '../../widgets/error_boundary.dart';
import '../../screens/loading/dynamic_loading_screen.dart';
import '../base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

/// Flashcard Safari Game - AR vocabulary scanning
class FlashcardSafariGame extends BaseGameScreen {
  const FlashcardSafariGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.flashcardSafari;

  @override
  ConsumerState<FlashcardSafariGame> createState() => _FlashcardSafariGameState();
}

class _FlashcardSafariGameState extends BaseGameScreenState<FlashcardSafariGame> {
  Map<String, dynamic>? _currentCard;
  List<String> _translationOptions = [];
  String? _selectedTranslation;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  bool _isLoading = false;
  String _word = '';
  bool _showWord = true;

  @override
  Future<void> onGameInitialized() async {
    await _loadNewCard();
  }

  Future<void> _loadNewCard() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      _isLoading = true;
      _showResult = false;
      _selectedTranslation = null;
      _showWord = true;
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateGameContent(
        gameType: 'flashcard_safari',
        language: widget.language,
      );

      final content = gameContent['content']?.toString() ?? '';
      final parsed = _parseCard(content);

      setState(() {
        _currentCard = gameContent;
        _round++;
        _word = parsed['word'];
        _translationOptions = parsed['options'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading card: $e');
      setState(() {
        _isLoading = false;
        _word = _getFallbackWord();
        _translationOptions = _getFallbackTranslations();
      });
    }
  }

  Map<String, dynamic> _parseCard(String content) {
    final lines = content.split('\n');
    String? word;
    final options = <String>[];

    for (var line in lines) {
      if (line.toLowerCase().contains('word:') || line.toLowerCase().contains('vocabulary:')) {
        word = line.split(':').skip(1).join(':').trim();
      }
      if (line.trim().startsWith(RegExp(r'[A-D]\.|1\.|2\.|3\.|4\.'))) {
        options.add(line.replaceFirst(RegExp(r'^[A-D1-4]\.\s*'), '').trim());
      }
    }

    if (options.length < 4) {
      options.addAll(_getFallbackTranslations());
    }

    return {
      'word': word ?? _getFallbackWord(),
      'options': options.take(4).toList()..shuffle(Random()),
    };
  }

  String _getFallbackWord() {
    final words = {
      'Yoruba': 'Ọmọ',
      'Swahili': 'Mtoto',
      'Hausa': 'Yaro',
      'Igbo': 'Nwa',
    };
    return words[widget.language] ?? 'Child';
  }

  List<String> _getFallbackTranslations() {
    return ['Child', 'Friend', 'Teacher', 'Student'];
  }

  void _selectTranslation(String translation) {
    if (_showResult) return;

    final isCorrect = translation == _translationOptions.first;

    setState(() {
      _selectedTranslation = translation;
      _isCorrect = isCorrect;
      _showResult = true;

      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'card_${_round}',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 3000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {'word': _word, 'translation': translation},
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadNewCard();
      }
    });
  }

  void _flipCard() {
    setState(() {
      _showWord = !_showWord;
    });
  }

  Future<void> _endGame() async {
    await finishGame();

    if (mounted) {
      final accuracy = _score / _maxRounds;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Safari Complete!'),
          content: Text('You captured $_score out of $_maxRounds words!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
    if (isLoading || _isLoading) {
      return const DynamicLoadingScreen();
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
            GestureDetector(
              onTap: _flipCard,
              child: Card(
                elevation: 8,
                child: Container(
                  height: 40.h,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _showWord ? [Colors.orange[100]!, Colors.orange[300]!] : [Colors.green[100]!, Colors.green[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showWord ? Icons.camera_alt : Icons.translate,
                          size: 64.sp,
                          color: Colors.brown,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _showWord ? _word : 'Tap to see word',
                          style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          _showWord ? 'Tap to flip' : 'Tap to see word',
                          style: TextStyle(fontSize: 14.sp, color: Colors.brown[700]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Select the correct translation:',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ..._translationOptions.map((translation) {
              final isSelected = _selectedTranslation == translation;
              final isCorrect = translation == _translationOptions.first;

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
                    leading: Icon(Icons.camera_alt, color: Colors.orange),
                    title: Text(translation),
                    trailing: _showResult && isCorrect
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrect
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectTranslation(translation),
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
  }
}


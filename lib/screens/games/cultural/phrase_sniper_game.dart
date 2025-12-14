import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/game/game_session_model.dart';
import '../../../services/polie_content_generator.dart';
import '../../../widgets/error_boundary.dart';
import '../../loading/dynamic_loading_screen.dart';
import '../base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

/// Phrase Sniper Game
class PhraseSniperGame extends BaseGameScreen {
  const PhraseSniperGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.phraseSniper;

  @override
  ConsumerState<PhraseSniperGame> createState() => _PhraseSniperGameState();
}

class _PhraseSniperGameState extends BaseGameScreenState<PhraseSniperGame> {

  Future<void> _initializeGame() async {
    setLoading(true); setError(null);
    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      // Initialize game content
      setLoading(false);
    } catch (e) {
      setLoading(false); setError(e.toString());
    }
  }
  Map<String, dynamic>? _currentPhrase;
  List<String> _translationOptions = [];
  String? _selectedTranslation;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  bool setLoading(false);
  String _targetPhrase = '';

  @override
  Future<void> onGameInitialized() async {
    await _loadNewPhrase();
  }

  Future<void> _loadNewPhrase() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _showResult = false;
      _selectedTranslation = null;
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateGameContent(
        gameType: 'phrase_sniper',
        language: widget.language,
      );

      final content = gameContent['content']?.toString() ?? '';
      final translations = _extractTranslations(content);

      setState(() {
        _currentPhrase = gameContent;
        _round++;
        _targetPhrase = _extractPhrase(content);
        _translationOptions = translations;
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading phrase: $e');
      setState(() {
        setLoading(false);
        _translationOptions = _getFallbackTranslations();
        _targetPhrase = _getFallbackPhrase();
      });
    }
  }

  List<String> _extractTranslations(String content) {
    final translations = <String>[];
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains('translation:') || 
          (line.length < 50 && line.isNotEmpty)) {
        final translation = line.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (translation.isNotEmpty) {
          translations.add(translation);
        }
      }
    }
    
    if (translations.length < 4) {
      translations.addAll(_getFallbackTranslations());
    }
    
    return translations.take(4).toList()..shuffle(Random());
  }

  List<String> _getFallbackTranslations() {
    return ['Hello', 'Thank you', 'Goodbye', 'Please'];
  }

  String _extractPhrase(String content) {
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains('phrase:') || 
          line.length < 30) {
        return line.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      }
    }
    return _getFallbackPhrase();
  }

  String _getFallbackPhrase() {
    final phrases = {
      'Yoruba': 'Bawo ni?',
      'Swahili': 'Habari?',
      'Hausa': 'Yaya kake?',
      'Igbo': 'Kedu?',
    };
    return phrases[widget.language] ?? 'Hello';
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
      cardId: 'phrase_${_round}',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 3000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {'phrase': _targetPhrase, 'translation': translation},
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _loadNewPhrase();
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
          title: const Text('Sniper Complete!'),
          content: Text('You sniped $_score out of $_maxRounds phrases!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
      return DynamicLoadingScreen();
    }

    if (error != null) {
      return ErrorBoundary(
        errorMessage: error!,
        onRetry: () {
          _initializeGame();
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!),
              SizedBox(height: 2.h),
              FilledButton(
                onPressed: () {
                  _initializeGame();
                },
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
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Icon(Icons.speed, size: 48.sp, color: Colors.red),
                    SizedBox(height: 2.h),
                    Text(
                      'Quick! Translate:',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _targetPhrase,
                      style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
              final isCorrectOption = translation == _translationOptions.first;
              
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
                    leading: Icon(Icons.translate, color: Colors.red),
                    title: Text(translation),
                    trailing: _showResult && isCorrectOption
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrectOption
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
                        _isCorrect ? 'Bullseye!' : 'Missed',
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






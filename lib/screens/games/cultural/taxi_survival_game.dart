import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/game/game_session_model.dart';
import '../../../services/polie_content_generator.dart';
import '../../../widgets/error_boundary.dart';
import '../../loading/dynamic_loading_screen.dart';
import '../base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

/// Taxi & Bus Stop Survival Game
class TaxiSurvivalGame extends BaseGameScreen {
  const TaxiSurvivalGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.taxiBusStopSurvival;

  @override
  ConsumerState<TaxiSurvivalGame> createState() => _TaxiSurvivalGameState();
}

class _TaxiSurvivalGameState extends BaseGameScreenState<TaxiSurvivalGame> {

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
  Map<String, dynamic>? _currentScenario;
  List<String> _phraseOptions = [];
  String? _selectedPhrase;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  
  String _scenarioText = '';

  @override
  Future<void> onGameInitialized() async {
    await _loadNewScenario();
  }

  Future<void> _loadNewScenario() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _showResult = false;
      _selectedPhrase = null;
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateGameContent(
        gameType: 'taxi_survival',
        language: widget.language,
      );

      final content = gameContent['content']?.toString() ?? '';
      final phrases = _extractPhrases(content);

      setState(() {
        _currentScenario = gameContent;
        _round++;
        _scenarioText = _extractScenario(content);
        _phraseOptions = phrases;
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading scenario: $e');
      // Use fallback content so game is still playable
      final fallbackPhrases = _getFallbackPhrases();
      setState(() {
        _currentScenario = {'content': 'You need to take a taxi to the market'};
        _round++;
        _scenarioText = 'You need to take a taxi to the market';
        _phraseOptions = fallbackPhrases;
        setLoading(false);
      });
    }
  }

  List<String> _extractPhrases(String content) {
    final phrases = <String>[];
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains('phrase:') || 
          (line.length < 50 && line.isNotEmpty)) {
        final phrase = line.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (phrase.isNotEmpty) {
          phrases.add(phrase);
        }
      }
    }
    
    if (phrases.length < 4) {
      phrases.addAll(_getFallbackPhrases());
    }
    
    return phrases.take(4).toList()..shuffle(Random());
  }

  List<String> _getFallbackPhrases() {
    final allPhrases = {
      'Yoruba': ['Bawo ni owo?', 'Mo fe lo', 'Nibo ni?', 'E se'],
      'Swahili': ['Bei gani?', 'Nataka kwenda', 'Wapi?', 'Asante'],
      'Hausa': ['Nawa ne?', 'Ina so in tafi', 'Ina?', 'Na gode'],
      'Igbo': ['Ego ole?', 'Achọrọ m ịga', 'Ebe ole?', 'Daalụ'],
    };
    return allPhrases[widget.language] ?? ['How much?', 'I want to go', 'Where?', 'Thank you'];
  }

  String _extractScenario(String content) {
    final sentences = content.split('.');
    if (sentences.isNotEmpty) {
      return sentences.first.trim();
    }
    return 'Transport scenario';
  }

  void _selectPhrase(String phrase) {
    if (_showResult) return;
    
    final isCorrect = phrase == _phraseOptions.first;
    
    setState(() {
      _selectedPhrase = phrase;
      _isCorrect = isCorrect;
      _showResult = true;
      
      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'taxi_$_round',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 5000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {'phrase': phrase, 'scenario': _scenarioText},
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadNewScenario();
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
          title: const Text('Survival Complete!'),
          content: Text('You navigated $_score out of $_maxRounds scenarios!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
    if (isLoading) {
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
                    Icon(Icons.directions_bus, size: 48.sp, color: Colors.blue),
                    SizedBox(height: 2.h),
                    Text(
                      _scenarioText,
                      style: TextStyle(fontSize: 16.sp),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'What should you say?',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ..._phraseOptions.map((phrase) {
              final isSelected = _selectedPhrase == phrase;
              final isCorrectOption = phrase == _phraseOptions.first;
              
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
                    leading: Icon(Icons.chat, color: Colors.blue),
                    title: Text(phrase),
                    trailing: _showResult && isCorrectOption
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrectOption
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectPhrase(phrase),
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
                        _isCorrect ? 'Perfect!' : 'Try Again',
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







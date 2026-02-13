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

/// Liar Liar Game - Detect grammatical errors
class LiarLiarGame extends BaseGameScreen {
  const LiarLiarGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.liarLiar;

  @override
  ConsumerState<LiarLiarGame> createState() => _LiarLiarGameState();
}

class _LiarLiarGameState extends BaseGameScreenState<LiarLiarGame> {

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
  String? _currentSentence;
  bool? _hasError;
  String? _errorExplanation;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  
  bool _showResult = false;
  bool _userSelected = false;

  @override
  Future<void> onGameInitialized() async {
    await _loadNewSentence();
  }

  Future<void> _loadNewSentence() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _showResult = false;
      _userSelected = false;
      _hasError = null;
      _errorExplanation = null;
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateGameContent(
        gameType: 'liar_liar',
        language: widget.language,
      );

      final content = gameContent['content']?.toString() ?? '';
      final parsed = _parseSentence(content);

      setState(() {
        _round++;
        _currentSentence = parsed['sentence'];
        _hasError = parsed['hasError'] as bool?;
        _errorExplanation = parsed['explanation'];
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading sentence: $e');
      // Use fallback content so game is still playable
      setState(() {
        _round++;
        _currentSentence = _getFallbackSentence();
        _hasError = Random().nextBool();
        _errorExplanation = 'Check grammar, word order, and verb conjugation.';
        setLoading(false);
      });
    }
  }

  Map<String, dynamic> _parseSentence(String content) {
    final lines = content.split('\n');
    String? sentence;
    bool? hasError;
    String? explanation;

    for (var line in lines) {
      if (line.toLowerCase().contains('sentence:') || 
          (line.length > 10 && line.length < 100 && !line.toLowerCase().contains('error'))) {
        sentence = line.replaceAll(RegExp(r'^[^\w]*'), '').trim();
      }
      if (line.toLowerCase().contains('error:') || line.toLowerCase().contains('has error:')) {
        hasError = line.toLowerCase().contains('yes') || line.toLowerCase().contains('true');
      }
      if (line.toLowerCase().contains('explanation:') || line.toLowerCase().contains('reason:')) {
        explanation = line.split(':').skip(1).join(':').trim();
      }
    }

    return {
      'sentence': sentence ?? _getFallbackSentence(),
      'hasError': hasError ?? Random().nextBool(),
      'explanation': explanation ?? 'Check grammar carefully.',
    };
  }

  String _getFallbackSentence() {
    final sentences = {
      'Yoruba': 'Mo wa ile naa.',
      'Swahili': 'Mimi ni mwalimu.',
      'Hausa': 'Ina son karatu.',
      'Igbo': 'Achọrọ m ịgụ akwụkwọ.',
    };
    return sentences[widget.language] ?? 'Hello, how are you?';
  }

  void _selectAnswer(bool hasError) {
    if (_showResult) return;

    final isCorrect = hasError == _hasError;

    setState(() {
      _userSelected = true;
      _showResult = true;
      
      if (isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'sentence_${_round}',
      result: isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 3000,
      confidence: isCorrect ? 1.0 : 0.0,
      feedback: {'sentence': _currentSentence, 'hasError': hasError},
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadNewSentence();
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
          title: const Text('Game Complete!'),
          content: Text('You detected $_score out of $_maxRounds sentences correctly!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Icon(Icons.psychology, size: 48.sp, color: Colors.orange),
                    SizedBox(height: 2.h),
                    Text(
                      'Does this sentence have a grammatical error?',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentSentence ?? '',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showResult ? null : () => _selectAnswer(true),
                    icon: const Icon(Icons.error),
                    label: const Text('Has Error'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _showResult && _hasError == true
                          ? Colors.green
                          : _showResult && _userSelected && _hasError != true
                              ? Colors.red
                              : Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 3.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showResult ? null : () => _selectAnswer(false),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Correct'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _showResult && _hasError == false
                          ? Colors.green
                          : _showResult && _userSelected && _hasError != false
                              ? Colors.red
                              : Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 3.h),
                    ),
                  ),
                ),
              ],
            ),
            if (_showResult) ...[
              SizedBox(height: 2.h),
              Card(
                color: (_hasError == (_userSelected ? true : false))
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      Icon(
                        (_hasError == (_userSelected ? true : false))
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: (_hasError == (_userSelected ? true : false))
                            ? Colors.green
                            : Colors.red,
                        size: 32.sp,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        (_hasError == (_userSelected ? true : false))
                            ? 'Correct!'
                            : 'Incorrect',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: (_hasError == (_userSelected ? true : false))
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      if (_errorExplanation != null) ...[
                        SizedBox(height: 1.h),
                        Text(
                          _errorExplanation!,
                          style: TextStyle(fontSize: 14.sp),
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







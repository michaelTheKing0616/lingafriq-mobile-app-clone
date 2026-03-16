import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/game/game_session_model.dart';
import '../../../services/polie_content_generator.dart';
import '../../../widgets/error_boundary.dart';
import '../../loading/dynamic_loading_screen.dart';
import '../base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

/// Multilingual Relay Race Game
class MultilingualRelayGame extends BaseGameScreen {
  const MultilingualRelayGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.multilingualRelayRace;

  @override
  ConsumerState<MultilingualRelayGame> createState() => _MultilingualRelayGameState();
}

class _MultilingualRelayGameState extends BaseGameScreenState<MultilingualRelayGame> {

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
  String? _sourcePhrase;
  String? _intermediatePhrase;
  List<String> _targetOptions = [];
  String? _selectedTarget;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  String? _correctTarget;
  

  @override
  Future<void> onGameInitialized() async {
    await _loadNewRelay();
  }

  Future<void> _loadNewRelay() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _showResult = false;
      _selectedTarget = null;
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateMultilingualRelay(widget.language);

      final content = gameContent['content']?.toString() ?? '';
      final parsed = _parseRelay(content);
      final targets = List<String>.from(parsed['targets'] as List<String>);

      setState(() {
        _round++;
        _sourcePhrase = parsed['source'];
        _intermediatePhrase = parsed['intermediate'];
        _correctTarget = targets.isNotEmpty ? targets.first : null;
        _targetOptions = List<String>.from(targets)..shuffle(Random());
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading relay: $e');
      // Use fallback content so game is still playable
      final options = ['Sannu', 'Habari', 'Bawo', 'Kedu'];
      setState(() {
        _round++;
        _sourcePhrase = 'Hello';
        _intermediatePhrase = 'Hola';
        _correctTarget = options.first;
        _targetOptions = List<String>.from(options)..shuffle(Random());
        setLoading(false);
      });
    }
  }

  Map<String, dynamic> _parseRelay(String content) {
    final lines = content.split('\n');
    String? source;
    String? intermediate;
    final targets = <String>[];

    for (var line in lines) {
      if (line.toLowerCase().contains('english:') || line.toLowerCase().contains('source:')) {
        source = line.split(':').skip(1).join(':').trim();
      }
      if (line.toLowerCase().contains('intermediate:') || line.toLowerCase().contains('spanish:')) {
        intermediate = line.split(':').skip(1).join(':').trim();
      }
      if (line.trim().startsWith(RegExp(r'[A-D]\.|1\.|2\.|3\.|4\.'))) {
        targets.add(line.replaceFirst(RegExp(r'^[A-D1-4]\.\s*'), '').trim());
      }
    }

    if (targets.length < 4) {
      targets.addAll(['Sannu', 'Habari', 'Bawo', 'Kedu']);
    }

    return {
      'source': source ?? 'Hello',
      'intermediate': intermediate ?? 'Hola',
      'targets': targets.take(4).toList(),
    };
  }

  void _selectTarget(String target) {
    if (_showResult) return;

    final isCorrect = target == _correctTarget;

    setState(() {
      _selectedTarget = target;
      _isCorrect = isCorrect;
      _showResult = true;

      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'relay_$_round',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 3000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {'source': _sourcePhrase, 'target': target},
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadNewRelay();
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
          title: const Text('Relay Complete!'),
          content: Text('You completed $_score out of $_maxRounds relays!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
                    Icon(Icons.swap_horiz, size: 48.sp, color: Colors.teal),
                    SizedBox(height: 2.h),
                    Text(
                      'Translation Chain:',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text('English', style: TextStyle(fontSize: 12.sp)),
                                Text(_sourcePhrase ?? '', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: Colors.teal),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text('Intermediate', style: TextStyle(fontSize: 12.sp)),
                                Text(_intermediatePhrase ?? '', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: Colors.teal),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(widget.language, style: TextStyle(fontSize: 12.sp)),
                                Text('?', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'What is the translation in ${widget.language}?',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ..._targetOptions.map((target) {
              final isSelected = _selectedTarget == target;
              final isCorrect = target == _correctTarget;

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
                    leading: Icon(Icons.swap_horiz, color: Colors.teal),
                    title: Text(target),
                    trailing: _showResult && isCorrect
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrect
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectTarget(target),
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
    );
    } catch (e, st) {
      debugPrint('MultilingualRelayGame buildGameContent: $e $st');
      rethrow;
    }
  }
}







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
import 'dart:math';

/// Call and Response Game
class CallResponseGame extends BaseGameScreen {
  const CallResponseGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.callAndResponse;

  @override
  ConsumerState<CallResponseGame> createState() => _CallResponseGameState();
}

class _CallResponseGameState extends BaseGameScreenState<CallResponseGame>
    with RoundProgressGameShellMixin<CallResponseGame> {

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
  Map<String, dynamic>? _currentPattern;
  List<String> _responseOptions = [];
  String? _selectedResponse;
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
  
  String _callPhrase = '';
  String? _correctResponse;
  List<GameScenario> _scenarios = [];

  @override
  Future<void> onGameInitialized() async {
    _scenarios = loadBundledGameScenarios(
      ref,
      language: widget.language,
      game: 'CallAndResponse',
      max: _maxRounds,
    );
    await _loadNewPattern();
  }

  String _extractCall(GameScenario scenario) {
    final title = scenario.title.trim();
    if (title.toLowerCase().startsWith('call:')) {
      return title.substring(5).trim();
    }
    return title.isNotEmpty ? title : scenario.prompt;
  }

  String _extractResponse(GameScenario scenario) {
    final prompt = scenario.prompt.trim();
    if (prompt.toLowerCase().startsWith('respond:')) {
      return prompt.substring(8).trim();
    }
    return (scenario.expectedResponse ?? prompt).trim();
  }

  Future<void> _loadNewPattern() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _showResult = false;
      _selectedResponse = null;
    });

    if (_scenarios.isNotEmpty) {
      final scenario = _scenarios[_round % _scenarios.length];
      final correct = _extractResponse(scenario);
      final pool = _scenarios
          .map(_extractResponse)
          .where((text) => text.isNotEmpty)
          .toSet()
          .toList();
      final options = <String>[correct];
      for (final candidate in pool) {
        if (options.length >= 4) break;
        if (!options.contains(candidate)) options.add(candidate);
      }
      while (options.length < 4) {
        options.addAll(_getFallbackResponses());
      }
      options.shuffle(Random());
      setState(() {
        _currentPattern = {'bundled': true, 'id': scenario.id};
        _round++;
        _callPhrase = _extractCall(scenario);
        _correctResponse = correct;
        _responseOptions = options.take(4).toList();
        setLoading(false);
      });
      return;
    }

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateGameContent(
        gameType: 'call_response',
        language: widget.language,
      );

      final content = gameContent['content']?.toString() ?? '';
      final responses = _extractResponses(content);

      setState(() {
        _currentPattern = gameContent;
        _round++;
        _callPhrase = _extractCall(content);
        _correctResponse = responses.isNotEmpty ? responses.first : null;
        _responseOptions = List<String>.from(responses)..shuffle(Random());
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading pattern: $e');
      setState(() {
        setLoading(false);
        final fallback = _getFallbackResponses();
        _correctResponse = fallback.first;
        _responseOptions = List<String>.from(fallback)..shuffle(Random());
        _callPhrase = _getFallbackCall();
      });
    }
  }

  List<String> _extractResponses(String content) {
    final responses = <String>[];
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains('response:') || 
          (line.length < 50 && line.isNotEmpty)) {
        final response = line.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (response.isNotEmpty) {
          responses.add(response);
        }
      }
    }
    
    if (responses.length < 4) {
      responses.addAll(_getFallbackResponses());
    }
    
    return responses.take(4).toList();
  }

  List<String> _getFallbackResponses() {
    final allResponses = {
      'Yoruba': ['E kaaro', 'E kaasan', 'E kaale', 'Bawo ni'],
      'Swahili': ['Nzuri', 'Poa', 'Safi', 'Vizuri'],
      'Hausa': ['Lafiya', 'Yauwa', 'Da kyau', 'Na gode'],
      'Igbo': ['O di mma', 'Ndewo', 'Kedu', 'Daalụ'],
    };
    return allResponses[widget.language] ?? ['Good', 'Fine', 'Well', 'Thanks'];
  }

  String _extractCall(String content) {
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains('call:') || 
          line.toLowerCase().contains('greeting:')) {
        return line.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      }
    }
    return _getFallbackCall();
  }

  String _getFallbackCall() {
    final calls = {
      'Yoruba': 'Bawo ni?',
      'Swahili': 'Habari?',
      'Hausa': 'Yaya kake?',
      'Igbo': 'Kedu?',
    };
    return calls[widget.language] ?? 'How are you?';
  }

  void _selectResponse(String response) {
    if (_showResult) return;
    
    final isCorrect = response == _correctResponse;
    
    setState(() {
      _selectedResponse = response;
      _isCorrect = isCorrect;
      _showResult = true;
      
      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'call_response_$_round',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 5000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {'call': _callPhrase, 'response': response},
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadNewPattern();
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
          title: const Text('Pattern Complete!'),
          content: Text('You mastered $_score out of $_maxRounds patterns!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
                    Icon(Icons.queue_music, size: 48.sp, color: Colors.purple),
                    SizedBox(height: 2.h),
                    Text(
                      'Call:',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _callPhrase,
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'What is the response?',
                      style: TextStyle(fontSize: 14.sp),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            ..._responseOptions.map((response) {
              final isSelected = _selectedResponse == response;
              final isCorrectOption = response == _correctResponse;
              
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
                    leading: Icon(Icons.music_note, color: Colors.purple),
                    title: Text(response),
                    trailing: _showResult && isCorrectOption
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrectOption
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectResponse(response),
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
                        _isCorrect ? 'Perfect Response!' : 'Try Again',
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
      debugPrint('CallResponseGame buildGameContent: $e $st');
      rethrow;
    }
  }
}







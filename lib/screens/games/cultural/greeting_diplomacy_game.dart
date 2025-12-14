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

/// Greeting Diplomacy Challenge Game
class GreetingDiplomacyGame extends BaseGameScreen {
  const GreetingDiplomacyGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.greetingDiplomacyChallenge;

  @override
  ConsumerState<GreetingDiplomacyGame> createState() => _GreetingDiplomacyGameState();
}

class _GreetingDiplomacyGameState extends BaseGameScreenState<GreetingDiplomacyGame> {

  Future<void> _initializeGame() async {
    setState(() {
      _isLoading = true;
      setState(() { _error = null; });
    });
    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      // Initialize game content
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        setState(() { _error = e.toString(); });
      });
    }
  }
  Map<String, dynamic>? _currentScenario;
  List<String> _greetingOptions = [];
  String? _selectedGreeting;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  bool _isLoadingScenario = false;
  String _scenarioDescription = '';

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
      _isLoadingScenario = true;
      _showResult = false;
      _selectedGreeting = null;
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateGameContent(
        gameType: 'greeting_diplomacy',
        language: widget.language,
      );

      final content = gameContent['content']?.toString() ?? '';
      final greetings = _extractGreetings(content);

      setState(() {
        _currentScenario = gameContent;
        _round++;
        _scenarioDescription = _extractScenario(content);
        _greetingOptions = greetings;
        _isLoadingScenario = false;
      });
    } catch (e) {
      debugPrint('Error loading greeting scenario: $e');
      setState(() {
        _isLoadingScenario = false;
        _greetingOptions = _getFallbackGreetings();
        _scenarioDescription = 'You meet an elder in the village';
      });
    }
  }

  List<String> _extractGreetings(String content) {
    final greetings = <String>[];
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains('greeting:') || 
          (line.length < 50 && line.isNotEmpty && !line.contains('.'))) {
        final greeting = line.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (greeting.isNotEmpty) {
          greetings.add(greeting);
        }
      }
    }
    
    if (greetings.length < 4) {
      greetings.addAll(_getFallbackGreetings());
    }
    
    return greetings.take(4).toList()..shuffle(Random());
  }

  List<String> _getFallbackGreetings() {
    final allGreetings = {
      'Yoruba': ['Bawo ni', 'E kaaro', 'E kaasan', 'E kaale'],
      'Swahili': ['Hujambo', 'Habari', 'Shikamoo', 'Jambo'],
      'Hausa': ['Sannu', 'Ina kwana', 'Yaya kake', 'Barka'],
      'Igbo': ['Kedu', 'Ndewo', 'Kedu ka ime', 'Nno'],
    };
    return allGreetings[widget.language] ?? ['Hello', 'Good morning', 'Good afternoon', 'Good evening'];
  }

  String _extractScenario(String content) {
    final sentences = content.split('.');
    if (sentences.isNotEmpty) {
      return sentences.first.trim();
    }
    return 'Choose the appropriate greeting';
  }

  void _selectGreeting(String greeting) {
    if (_showResult) return;
    
    final isCorrect = greeting == _greetingOptions.first;
    
    setState(() {
      _selectedGreeting = greeting;
      _isCorrect = isCorrect;
      _showResult = true;
      
      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'greeting_${_round}',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 5000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {
        'greeting': greeting,
        'scenario': _scenarioDescription,
      },
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
          title: const Text('Challenge Complete!'),
          content: Text('You mastered $_score out of $_maxRounds greetings!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
    if (isLoading || _isLoadingScenario) {
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
      return const Center(child: Text('Challenge Complete!'));
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
                    Icon(Icons.waving_hand, size: 48.sp, color: Colors.blue),
                    SizedBox(height: 2.h),
                    Text(
                      'Scenario',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _scenarioDescription,
                      style: TextStyle(fontSize: 16.sp),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Choose the appropriate greeting:',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ..._greetingOptions.map((greeting) {
              final isSelected = _selectedGreeting == greeting;
              final isCorrectOption = greeting == _greetingOptions.first;
              
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
                    leading: Icon(Icons.handshake, color: Colors.blue),
                    title: Text(greeting),
                    trailing: _showResult && isCorrectOption
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrectOption
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectGreeting(greeting),
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
                        _isCorrect ? 'Perfect Greeting!' : 'Try Again',
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



import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/game/game_session_model.dart';
import '../../../services/polie_content_generator.dart';
import '../../../widgets/error_boundary.dart';
import '../../loading/dynamic_loading_screen.dart';
import '../base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

/// Village Quest Game - NPC conversation game
class VillageQuestGame extends BaseGameScreen {
  const VillageQuestGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.villageQuest;

  @override
  ConsumerState<VillageQuestGame> createState() => _VillageQuestGameState();
}

class _VillageQuestGameState extends BaseGameScreenState<VillageQuestGame> {

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
  List<String> _responseOptions = [];
  String? _selectedResponse;
  bool _showResult = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  
  String _npcName = '';
  String _npcMessage = '';
  String _scenarioDescription = '';
  String? _correctResponse;

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
      _selectedResponse = null;
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateVillageQuestScenario(
        widget.language,
      );

      setState(() {
        _currentScenario = gameContent;
        _round++;
        _npcName = gameContent['npcName']?.toString() ?? 'Village Elder';
        _npcMessage = gameContent['message']?.toString() ?? gameContent['content']?.toString() ?? '';
        _scenarioDescription = gameContent['scenario']?.toString() ?? '';
        final options = _extractResponses(gameContent);
        _correctResponse = options.isNotEmpty ? options.first : null;
        _responseOptions = List<String>.from(options)..shuffle(Random());
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading scenario: $e');
      // Use fallback content so game is still playable
      final fallbackResponses = _getFallbackResponses();
      setState(() {
        _currentScenario = {'npcName': 'Village Elder', 'message': 'Welcome to our village! How can I help you?'};
        _round++;
        _npcName = 'Village Elder';
        _npcMessage = 'Welcome to our village! How can I help you?';
        _scenarioDescription = 'A village elder greets you.';
        _correctResponse = fallbackResponses.first;
        _responseOptions = List<String>.from(fallbackResponses)..shuffle(Random());
        setLoading(false);
      });
    }
  }

  List<String> _extractResponses(Map<String, dynamic> content) {
    final responses = <String>[];
    
    if (content['responses'] is List) {
      responses.addAll((content['responses'] as List).map((e) => e.toString()));
    } else if (content['options'] is List) {
      responses.addAll((content['options'] as List).map((e) => e.toString()));
    } else {
      final text = content['content']?.toString() ?? '';
      final lines = text.split('\n');
      for (var line in lines) {
        if (line.trim().startsWith(RegExp(r'[A-D]\.|1\.|2\.|3\.|4\.'))) {
          responses.add(line.replaceFirst(RegExp(r'^[A-D1-4]\.\s*'), '').trim());
        }
      }
    }
    
    if (responses.length < 4) {
      responses.addAll(_getFallbackResponses());
    }
    
    return responses.take(4).toList();
  }

  List<String> _getFallbackResponses() {
    return [
      'Hello! Nice to meet you.',
      'Thank you for your help.',
      'Can you show me around?',
      'I am learning your language.',
    ];
  }

  void _selectResponse(String response) {
    if (_showResult) return;
    
    final isCorrect = response == _correctResponse;
    
    setState(() {
      _selectedResponse = response;
      _showResult = true;
      
      if (isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'scenario_$_round',
      result: isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 3000,
      confidence: isCorrect ? 1.0 : 0.0,
      feedback: {'response': response, 'npc': _npcName},
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
          title: const Text('Quest Complete!'),
          content: Text('You completed $_score out of $_maxRounds scenarios!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
                    Icon(Icons.location_city, size: 48.sp, color: Colors.brown),
                    SizedBox(height: 2.h),
                    Text(
                      _npcName,
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                    ),
                    if (_scenarioDescription.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        _scenarioDescription,
                        style: TextStyle(fontSize: 14.sp),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        _npcMessage,
                        style: TextStyle(fontSize: 16.sp),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Choose your response:',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ..._responseOptions.map((response) {
              final isSelected = _selectedResponse == response;
              final isCorrect = response == _correctResponse;
              
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
                    leading: Icon(Icons.chat_bubble_outline, color: Colors.brown),
                    title: Text(response),
                    trailing: _showResult && isCorrect
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrect
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
                color: (_selectedResponse == _correctResponse)
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      Icon(
                        (_selectedResponse == _correctResponse)
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: (_selectedResponse == _correctResponse)
                            ? Colors.green
                            : Colors.red,
                        size: 32.sp,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        (_selectedResponse == _correctResponse)
                            ? 'Great response!'
                            : 'Try a more culturally appropriate response.',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: (_selectedResponse == _correctResponse)
                              ? Colors.green
                              : Colors.red,
                        ),
                        textAlign: TextAlign.center,
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
      debugPrint('VillageQuestGame buildGameContent: $e $st');
      rethrow;
    }
  }
}







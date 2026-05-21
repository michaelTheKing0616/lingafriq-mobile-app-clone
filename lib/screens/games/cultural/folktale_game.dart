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

/// Folktale Reconstruction Game
class FolktaleGame extends BaseGameScreen {
  const FolktaleGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.folktaleReconstruction;

  @override
  ConsumerState<FolktaleGame> createState() => _FolktaleGameState();
}

class _FolktaleGameState extends BaseGameScreenState<FolktaleGame>
    with RoundProgressGameShellMixin<FolktaleGame> {

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
  Map<String, dynamic>? _currentStory;
  List<String> _storyParts = [];
  String? _selectedPart;
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
  
  String _storyTitle = '';
  String? _correctStoryPart;
  List<GameScenario> _bundledScenarios = [];

  @override
  Future<void> onGameInitialized() async {
    _bundledScenarios = loadBundledGameScenarios(
      ref,
      language: widget.language,
      game: 'FolktaleReconstruction',
      max: 10,
    );
    await _loadNewStory();
  }

  Future<void> _loadNewStory() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _showResult = false;
      _selectedPart = null;
    });

    if (_bundledScenarios.isNotEmpty) {
      final s = _bundledScenarios[_round % _bundledScenarios.length];
      final parts = <String>[
        s.title,
        s.prompt,
        if (s.culturalNote != null) s.culturalNote!,
        if (s.expectedResponse != null) s.expectedResponse!,
      ].where((p) => p.trim().isNotEmpty).toList();
      final correct = parts.isNotEmpty ? parts.first : s.prompt;
      setState(() {
        _currentStory = {'bundled': true, 'id': s.id};
        _round++;
        _storyTitle = s.title;
        _correctStoryPart = correct;
        _storyParts = List<String>.from(parts)..shuffle(Random());
        setLoading(false);
      });
      return;
    }

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final storyData = await polieGenerator.generateCulturalStory(
        widget.language,
        theme: 'folktale',
      );

      final story = storyData['content']?.toString() ?? '';
      final parts = _splitStoryIntoParts(story);

      setState(() {
        _currentStory = storyData;
        _round++;
        _storyTitle = storyData['title']?.toString() ?? 'Folktale';
        _correctStoryPart = parts.isNotEmpty ? parts.first : null;
        _storyParts = List<String>.from(parts)..shuffle(Random());
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading folktale: $e');
      setState(() {
        setLoading(false);
        final fallback = _getFallbackParts();
        _correctStoryPart = fallback.first;
        _storyParts = List<String>.from(fallback)..shuffle(Random());
        _storyTitle = 'Traditional Folktale';
      });
    }
  }

  List<String> _splitStoryIntoParts(String story) {
    final sentences = story.split('.');
    final parts = sentences.where((s) => s.trim().isNotEmpty).take(4).toList();
    while (parts.length < 4) {
      parts.add('Story part ${parts.length + 1}');
    }
    return parts;
  }

  List<String> _getFallbackParts() {
    return [
      'Once upon a time',
      'In a faraway village',
      'A wise elder told',
      'The story teaches',
    ];
  }

  void _selectPart(String part) {
    if (_showResult) return;
    
    final isCorrect = part == _correctStoryPart;
    
    setState(() {
      _selectedPart = part;
      _isCorrect = isCorrect;
      _showResult = true;
      
      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'folktale_$_round',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 5000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {'part': part, 'story': _storyTitle},
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadNewStory();
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
          title: const Text('Folktale Complete!'),
          content: Text('You reconstructed $_score out of $_maxRounds folktales!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
                    Icon(Icons.book, size: 48.sp, color: Colors.indigo),
                    SizedBox(height: 2.h),
                    Text(
                      _storyTitle,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Arrange the story parts correctly',
                      style: TextStyle(fontSize: 14.sp),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Select the first part:',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ..._storyParts.map((part) {
              final isSelected = _selectedPart == part;
              final isCorrectOption = part == _correctStoryPart;
              
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
                    leading: Icon(Icons.text_snippet, color: Colors.indigo),
                    title: Text(part),
                    trailing: _showResult && isCorrectOption
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrectOption
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectPart(part),
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
      debugPrint('FolktaleGame buildGameContent: $e $st');
      rethrow;
    }
  }
}







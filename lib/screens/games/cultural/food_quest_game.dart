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

/// Food Quest Game
class FoodQuestGame extends BaseGameScreen {
  const FoodQuestGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.foodQuest;

  @override
  ConsumerState<FoodQuestGame> createState() => _FoodQuestGameState();
}

class _FoodQuestGameState extends BaseGameScreenState<FoodQuestGame>
    with RoundProgressGameShellMixin<FoodQuestGame> {

  Future<void> _initializeGame() async {
    setLoading(true);
    setError(null);
    try {
      ref.read(polieContentGeneratorProvider);
      await _loadNewFood();
      setLoading(false);
    } catch (e) {
      setLoading(false);
      setError(e.toString());
    }
  }
  // ignore: unused_field
  Map<String, dynamic>? _currentFood;
  List<String> _foodOptions = [];
  String? _selectedFood;
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
  bool _isLoadingFood = false;
  String _foodDescription = '';
  String? _correctFood;
  List<GameScenario> _scenarios = [];

  @override
  bool get requiresPhraseCards => false;

  @override
  Future<void> onGameInitialized() async {
    _scenarios = loadBundledGameScenarios(
      ref,
      language: widget.language,
      game: 'FoodQuest',
      max: _maxRounds,
    );
    await _loadNewFood();
  }

  Future<void> _loadNewFood() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      _isLoadingFood = true;
      _showResult = false;
      _selectedFood = null;
    });

    if (_scenarios.isNotEmpty) {
      final scenario = _scenarios[_round % _scenarios.length];
      final correct = (scenario.expectedResponse ?? scenario.prompt).trim();
      final pool = _scenarios
          .map((s) => (s.expectedResponse ?? s.prompt).trim())
          .where((text) => text.isNotEmpty)
          .toSet()
          .toList();
      final options = <String>[correct];
      for (final candidate in pool) {
        if (options.length >= 4) break;
        if (!options.contains(candidate)) options.add(candidate);
      }
      while (options.length < 4) {
        options.addAll(_getFallbackFoods());
      }
      options.shuffle(Random());
      setState(() {
        _currentFood = {'bundled': true, 'id': scenario.id};
        _round++;
        _foodDescription = scenario.title;
        _correctFood = correct;
        _foodOptions = options.take(4).toList();
        _isLoadingFood = false;
      });
      return;
    }

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateGameContent(
        gameType: 'food_quest',
        language: widget.language,
        difficulty: widget.level ?? 'intermediate',
      );

      final content = gameContent['content']?.toString() ?? '';
      final foods = _extractFoodsFromContent(content);

      setState(() {
        _currentFood = gameContent;
        _round++;
        _foodDescription = _extractDescription(content);
        _correctFood = foods.isNotEmpty ? foods.first : null;
        _foodOptions = List<String>.from(foods)..shuffle(Random());
        _isLoadingFood = false;
      });
    } catch (e) {
      debugPrint('Error loading food quest: $e');
      // Use fallback content so game is still playable
      final fallbackFoods = _getFallbackFoods();
      setState(() {
        _currentFood = {'content': 'Traditional African food'};
        _round++;
        _foodDescription = 'Traditional African food';
        _correctFood = fallbackFoods.first;
        _foodOptions = List<String>.from(fallbackFoods)..shuffle(Random());
        _isLoadingFood = false;
      });
    }
  }

  List<String> _extractFoodsFromContent(String content) {
    final foods = <String>[];
    final lines = content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains('food:') || 
          line.toLowerCase().contains('dish:') ||
          (line.length < 30 && line.isNotEmpty)) {
        final food = line.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (food.isNotEmpty && food.length < 30) {
          foods.add(food);
        }
      }
    }
    
    if (foods.length < 4) {
      foods.addAll(_getFallbackFoods());
    }
    
    return foods.take(4).toList();
  }

  List<String> _getFallbackFoods() {
    final allFoods = {
      'Yoruba': ['Jollof Rice', 'Egusi Soup', 'Pounded Yam', 'Suya'],
      'Swahili': ['Pilau', 'Ugali', 'Nyama Choma', 'Samosas'],
      'Hausa': ['Tuwo Shinkafa', 'Miyan Kuka', 'Fura', 'Kilishi'],
      'Igbo': ['Ofe Onugbu', 'Abacha', 'Nkwobi', 'Isi Ewu'],
    };
    return allFoods[widget.language] ?? ['Jollof Rice', 'Egusi Soup', 'Pounded Yam', 'Suya'];
  }

  String _extractDescription(String content) {
    final sentences = content.split('.');
    if (sentences.isNotEmpty) {
      return sentences.first.trim();
    }
    return 'Learn about traditional African food';
  }

  void _selectFood(String food) {
    if (_showResult) return;
    
    final isCorrect = food == _correctFood;
    
    setState(() {
      _selectedFood = food;
      _isCorrect = isCorrect;
      _showResult = true;
      
      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'food_$_round',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 5000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {
        'food': food,
        'description': _foodDescription,
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadNewFood();
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
          content: Text('You discovered $_score out of $_maxRounds foods!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
      if (isLoading || _isLoadingFood) {
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
      return const Center(child: Text('Quest Complete!'));
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
                    Icon(Icons.restaurant, size: 48.sp, color: Colors.orange),
                    SizedBox(height: 2.h),
                    Text(
                      'Food Quest',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _foodDescription,
                      style: TextStyle(fontSize: 16.sp),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Which food matches this description?',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ..._foodOptions.map((food) {
              final isSelected = _selectedFood == food;
              final isCorrectOption = food == _correctFood;
              
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
                    leading: Icon(Icons.restaurant_menu, color: Colors.orange),
                    title: Text(food),
                    trailing: _showResult && isCorrectOption
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrectOption
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectFood(food),
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
      debugPrint('FoodQuestGame buildGameContent: $e $st');
      rethrow;
    }
  }
}






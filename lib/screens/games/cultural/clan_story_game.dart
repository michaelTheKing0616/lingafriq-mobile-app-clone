import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/game/game_session_model.dart';
import '../../../services/polie_content_generator.dart';
import '../../../widgets/error_boundary.dart';
import '../../loading/dynamic_loading_screen.dart';
import '../base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

/// Clan Lineage Story Builder Game
class ClanStoryGame extends BaseGameScreen {
  const ClanStoryGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.clanLineageStoryBuilder;

  @override
  ConsumerState<ClanStoryGame> createState() => _ClanStoryGameState();
}

class _ClanStoryGameState extends BaseGameScreenState<ClanStoryGame> {
  Map<String, dynamic>? _currentStory;
  List<String> _storyParts = [];
  String? _selectedPart;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  // ignore: unused_field
  final bool _isLoading = false;
  String _storyPrompt = '';
  String? _correctPart;

  @override
  Future<void> onGameInitialized() async {
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

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final storyData = await polieGenerator.generateCulturalStory(
        widget.language,
        theme: 'clan_lineage',
      );

      final story = storyData['content']?.toString() ?? '';
      final parts = _splitStoryIntoParts(story);

      setState(() {
        _currentStory = storyData;
        _round++;
        _storyPrompt = storyData['title']?.toString() ?? 'Build the story';
        _correctPart = parts.isNotEmpty ? parts.first : null;
        _storyParts = List<String>.from(parts)..shuffle(Random());
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading story: $e');
      setState(() {
        setLoading(false);
        final fallback = _getFallbackParts();
        _correctPart = fallback.first;
        _storyParts = List<String>.from(fallback)..shuffle(Random());
        _storyPrompt = 'Build a clan story';
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
      'Long ago, in a village',
      'A wise elder spoke',
      'The clan gathered',
      'Unity was found',
    ];
  }

  void _selectPart(String part) {
    if (_showResult) return;
    
    final isCorrect = part == _correctPart;
    
    setState(() {
      _selectedPart = part;
      _isCorrect = isCorrect;
      _showResult = true;
      
      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'story_$_round',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 5000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {'part': part, 'story': _storyPrompt},
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
          title: const Text('Story Complete!'),
          content: Text('You built $_score out of $_maxRounds stories!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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

  Future<void> _initializeGame() async {
    setLoading(true); setError(null);
    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      _currentStory = await polieGenerator.generateGameContent(
        language: widget.language,
        gameType: widget.getGameType().name,
      );
        setLoading(false);
        setState(() {
          _storyParts = (_currentStory?['story_parts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        });
    } catch (e) {
      setLoading(false); setError(e.toString());
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
        errorMessage: error ?? 'Unknown error',
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
                    Icon(Icons.account_tree, size: 48.sp, color: Colors.brown),
                    SizedBox(height: 2.h),
                    Text(
                      _storyPrompt,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Arrange the story parts in order',
                      style: TextStyle(fontSize: 14.sp),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Select the first part of the story:',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ..._storyParts.map((part) {
              final isSelected = _selectedPart == part;
              final isCorrectOption = part == _correctPart;
              
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
                    leading: Icon(Icons.text_fields, color: Colors.brown),
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
      debugPrint('ClanStoryGame buildGameContent: $e $st');
      rethrow;
    }
  }
}






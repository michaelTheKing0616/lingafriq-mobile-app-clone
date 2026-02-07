import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import '../../services/polie_content_generator.dart';
import '../../utils/error_handler.dart';
import '../../utils/integration_helpers.dart';
import '../../utils/performance_utils.dart';
import '../../widgets/error_boundary.dart';
import '../../screens/loading/dynamic_loading_screen.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';
import '../../games/drum_rhythm/drum_rhythm_screen.dart';

// Export separate game implementations
export 'cultural/clan_story_game.dart';
export 'cultural/taxi_survival_game.dart';
export 'cultural/food_quest_game.dart';
export 'cultural/call_response_game.dart';
export 'cultural/greeting_diplomacy_game.dart';
export 'cultural/folktale_game.dart';
export 'cultural/phrase_sniper_game.dart';
export 'cultural/liar_liar_game.dart';
export 'cultural/village_quest_game.dart';
export 'cultural/accent_puzzle_game.dart';
export 'cultural/flashcard_safari_game.dart';
export 'cultural/tongue_twister_game.dart';
export 'cultural/emoji_translator_game.dart';
export 'cultural/rhythm_typing_game.dart';
export 'cultural/elders_blessings_game.dart';
export 'cultural/multilingual_relay_game.dart';
export 'cultural/cultural_etiquette_game.dart';
export 'cultural/drum_word_game.dart';

/// Proverb Unlocker Game
class ProverbUnlockerGame extends BaseGameScreen {
  const ProverbUnlockerGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.proverbUnlocker;

  @override
  ConsumerState<ProverbUnlockerGame> createState() => _ProverbUnlockerGameState();
}

class _ProverbUnlockerGameState extends BaseGameScreenState<ProverbUnlockerGame> {
  Map<String, dynamic>? _currentProverb;
  List<String> _shuffledOptions = [];
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  bool _isLoadingProverb = false;

  Future<void> _initializeGame() async {
    await _loadNewProverb();
  }

  @override
  Future<void> onGameInitialized() async {
    await _loadNewProverb();
  }

  Future<void> _loadNewProverb() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      _isLoadingProverb = true;
      _showResult = false;
      _selectedAnswer = null;
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final proverbData = await polieGenerator.generateProverb(
        widget.language,
        theme: _getRandomTheme(),
      );

      setState(() {
        _currentProverb = proverbData;
        _round++;
        // Create multiple choice options
        _shuffledOptions = _createOptions(proverbData);
        _isLoadingProverb = false;
      });
    } catch (e) {
      debugPrint('Error loading proverb: $e');
      setState(() {
        _isLoadingProverb = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading proverb. Please try again.')),
        );
      }
    }
  }

  List<String> _createOptions(Map<String, dynamic> proverbData) {
    final correctMeaning = proverbData['meaning']?.toString() ?? 
                          proverbData['context']?.toString() ?? 
                          'Wisdom through experience';
    final options = [correctMeaning];
    
    // Add distractors
    options.addAll([
      'A common greeting',
      'A traditional dance',
      'A type of food',
      'A weather saying',
    ]);
    
    options.shuffle(Random());
    return options;
  }

  String _getRandomTheme() {
    final themes = ['wisdom', 'family', 'work', 'friendship', 'nature', 'respect'];
    return themes[Random().nextInt(themes.length)];
  }

  String? _correctMeaning;

  void _selectAnswer(String answer) {
    if (_showResult) return;
    
    setState(() {
      _selectedAnswer = answer;
      _correctMeaning = _currentProverb?['meaning']?.toString() ?? 
                            _currentProverb?['context']?.toString() ?? '';
      _isCorrect = answer == _correctMeaning;
      _showResult = true;
      
      if (_isCorrect) {
        _score++;
      }
    });

    // Record turn
    completeTurn(
      cardId: 'proverb_${_round}',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: 5000,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {
        'proverb': _currentProverb?['proverb'],
        'selected': answer,
        'correct': _correctMeaning ?? '',
      },
    );

    // Auto-advance after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadNewProverb();
      }
    });
  }

  Future<void> _endGame() async {
    final accuracy = _score / _maxRounds;
    await finishGame();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Game Complete!'),
          content: Text('You scored $_score out of $_maxRounds!\nAccuracy: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
    if (isLoading || _isLoadingProverb) {
      return const DynamicLoadingScreen();
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

    final proverb = _currentProverb?['proverb'] ?? 'Loading...';
    final translation = _currentProverb?['translation'] ?? '';

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
            // Proverb Display
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Icon(Icons.lightbulb, size: 48.sp, color: Colors.amber),
                    SizedBox(height: 2.h),
                    Text(
                      'Proverb in ${widget.language}',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      proverb,
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    if (translation.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        translation,
                        style: TextStyle(fontSize: 14.sp, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'What does this proverb mean?',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            // Multiple Choice Options
            ..._shuffledOptions.map((option) {
              final isSelected = _selectedAnswer == option;
              final isCorrectOption = option == (_currentProverb?['meaning']?.toString() ?? 
                                                   _currentProverb?['context']?.toString() ?? '');
              
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
                    title: Text(option),
                    trailing: _showResult && isCorrectOption
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _showResult && isSelected && !isCorrectOption
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
                    onTap: () => _selectAnswer(option),
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
                      if (_currentProverb?['context'] != null) ...[
                        SizedBox(height: 1.h),
                        Text(
                          _currentProverb!['context'].toString(),
                          style: TextStyle(fontSize: 12.sp),
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

/// Drum Rhythm Shadowing Game - Migrated to GameKit
/// Use DrumRhythmScreen instead
@Deprecated('Use DrumRhythmScreen from lib/games/drum_rhythm/drum_rhythm_screen.dart')
class DrumRhythmGame extends BaseGameScreen {
  const DrumRhythmGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.drumRhythmShadowing;

  @override
  ConsumerState<DrumRhythmGame> createState() => _DrumRhythmGameState();
}

class _DrumRhythmGameState extends BaseGameScreenState<DrumRhythmGame> {
  @override
  Widget buildGameContent(BuildContext context) {
    // Redirect to new GameKit implementation
    return DrumRhythmScreen(
      language: widget.language,
      level: widget.level,
      onBack: widget.onBack,
    );
  }
}

/// Clan Lineage Story Builder Game
class ClanStoryGame extends BaseGameScreen {
  const ClanStoryGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

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
  bool _isLoading = false;
  String _storyPrompt = '';

  Future<void> _initializeGame() async {
    await _loadNewStory();
  }

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
      _isLoading = true;
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
        _storyParts = parts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading story: $e');
      setState(() {
        _isLoading = false;
        _storyParts = _getFallbackParts();
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
    return parts..shuffle(Random());
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
    
    final isCorrect = part == _storyParts.first;
    
    setState(() {
      _selectedPart = part;
      _isCorrect = isCorrect;
      _showResult = true;
      
      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'story_${_round}',
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

  @override
  Widget buildGameContent(BuildContext context) {
    if (isLoading || _isLoading) {
      return const DynamicLoadingScreen();
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
              final isCorrectOption = part == _storyParts.first;
              
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
      ),
    );
  }
}

/// Market Bargaining Simulator Game
class MarketBargainingGame extends BaseGameScreen {
  const MarketBargainingGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.marketBargainingSimulator;

  @override
  ConsumerState<MarketBargainingGame> createState() => _MarketBargainingGameState();
}

class _MarketBargainingGameState extends BaseGameScreenState<MarketBargainingGame> {
  Map<String, dynamic>? _currentScenario;
  String? _sellerPrice;
  String? _userOffer;
  final TextEditingController _offerController = TextEditingController();
  bool _showResult = false;
  bool _isAccepted = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  bool _isLoadingScenario = false;
  List<String> _bargainingPhrases = [];

  Future<void> _initializeGame() async {
    await _loadNewScenario();
  }

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

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
      _userOffer = null;
      _offerController.clear();
    });

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final scenarioData = await polieGenerator.generateMarketScenario(widget.language);

      setState(() {
        _currentScenario = scenarioData;
        _round++;
        _sellerPrice = _generateSellerPrice();
        _bargainingPhrases = scenarioData['phrases'] as List<String>? ?? [];
        _isLoadingScenario = false;
      });
    } catch (e) {
      debugPrint('Error loading scenario: $e');
      setState(() {
        _isLoadingScenario = false;
        _sellerPrice = '1000';
        _bargainingPhrases = ['How much?', 'Can you reduce?', 'Thank you'];
      });
    }
  }

  String _generateSellerPrice() {
    final prices = ['500', '750', '1000', '1200', '1500'];
    return prices[Random().nextInt(prices.length)];
  }

  void _submitOffer() {
    if (_offerController.text.isEmpty) return;
    
    final offer = int.tryParse(_offerController.text) ?? 0;
    final sellerPrice = int.tryParse(_sellerPrice ?? '1000') ?? 1000;
    
    final isAccepted = offer >= (sellerPrice * 0.8);
    
    setState(() {
      _userOffer = _offerController.text;
      _isAccepted = isAccepted;
      _showResult = true;
      
      if (_isAccepted) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'bargain_${_round}',
      result: _isAccepted ? GameResult.correct : GameResult.partial,
      durationMs: 10000,
      confidence: _isAccepted ? 1.0 : 0.5,
      feedback: {
        'seller_price': _sellerPrice,
        'user_offer': _userOffer,
        'accepted': _isAccepted,
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
          title: const Text('Game Complete!'),
          content: Text('You successfully bargained $_score out of $_maxRounds times!\nSuccess rate: ${(accuracy * 100).toStringAsFixed(0)}%'),
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
      return const DynamicLoadingScreen();
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

    final scenario = _currentScenario?['scenario']?.toString() ?? 'Market scenario';

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
                    Icon(Icons.store, size: 48.sp, color: Colors.orange),
                    SizedBox(height: 2.h),
                    Text(
                      scenario,
                      style: TextStyle(fontSize: 16.sp),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seller asks:',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_sellerPrice} ${widget.language == 'Swahili' ? 'shillings' : 'naira'}',
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            if (_bargainingPhrases.isNotEmpty) ...[
              Text(
                'Useful Phrases:',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 1.w,
                runSpacing: 1.h,
                children: _bargainingPhrases.take(3).map((phrase) {
                  return Chip(
                    label: Text(phrase, style: TextStyle(fontSize: 12.sp)),
                    backgroundColor: Colors.grey.withOpacity(0.2),
                  );
                }).toList(),
              ),
              SizedBox(height: 4.h),
            ],
            TextField(
              controller: _offerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Your Offer',
                hintText: 'Enter your price',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: widget.language == 'Swahili' ? 'shillings' : 'naira',
              ),
              enabled: !_showResult,
            ),
            SizedBox(height: 2.h),
            if (!_showResult)
              FilledButton(
                onPressed: _submitOffer,
                child: const Text('Submit Offer'),
              ),
            if (_showResult) ...[
              SizedBox(height: 2.h),
              Card(
                color: _isAccepted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      Icon(
                        _isAccepted ? Icons.check_circle : Icons.info,
                        color: _isAccepted ? Colors.green : Colors.orange,
                        size: 32.sp,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _isAccepted ? 'Deal Accepted!' : 'Counter Offer',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: _isAccepted ? Colors.green : Colors.orange,
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

/// Taxi & Bus Stop Survival Game
class TaxiSurvivalGame extends BaseGameScreen {
  const TaxiSurvivalGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.taxiBusStopSurvival;

  @override
  ConsumerState<TaxiSurvivalGame> createState() => _TaxiSurvivalGameState();
}

class _TaxiSurvivalGameState extends BaseGameScreenState<TaxiSurvivalGame> {
  Map<String, dynamic>? _currentScenario;
  List<String> _phraseOptions = [];
  String? _selectedPhrase;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  bool _isLoading = false;
  String _scenarioText = '';

  Future<void> _initializeGame() async {
    await _loadNewScenario();
  }

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
      _isLoading = true;
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
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading scenario: $e');
      setState(() {
        _isLoading = false;
        _phraseOptions = _getFallbackPhrases();
        _scenarioText = 'You need to take a taxi to the market';
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
      cardId: 'taxi_${_round}',
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
    if (isLoading || _isLoading) {
      return const DynamicLoadingScreen();
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

/// Food Quest Game
class FoodQuestGame extends BaseGameScreen {
  const FoodQuestGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.foodQuest;

  @override
  ConsumerState<FoodQuestGame> createState() => _FoodQuestGameState();
}

class _FoodQuestGameState extends BaseGameScreenState<FoodQuestGame> {
  Map<String, dynamic>? _currentFood;
  List<String> _foodOptions = [];
  String? _selectedFood;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  bool _isLoadingFood = false;
  String _foodDescription = '';

  Future<void> _initializeGame() async {
    await _loadNewFood();
  }

  @override
  Future<void> onGameInitialized() async {
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
        _foodOptions = foods;
        _isLoadingFood = false;
      });
    } catch (e) {
      debugPrint('Error loading food quest: $e');
      setState(() {
        _isLoadingFood = false;
        _foodOptions = _getFallbackFoods();
        _foodDescription = 'Traditional African food';
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
    
    return foods.take(4).toList()..shuffle(Random());
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
    
    final isCorrect = food == _foodOptions.first;
    
    setState(() {
      _selectedFood = food;
      _isCorrect = isCorrect;
      _showResult = true;
      
      if (_isCorrect) {
        _score++;
      }
    });

    completeTurn(
      cardId: 'food_${_round}',
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
    if (isLoading || _isLoadingFood) {
      return const DynamicLoadingScreen();
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
              final isCorrectOption = food == _foodOptions.first;
              
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
      ),
    );
  }
}

// CallResponseGame is now exported from cultural/call_response_game.dart

// GreetingDiplomacyGame is now exported from cultural/greeting_diplomacy_game.dart

// FolktaleGame is now exported from cultural/folktale_game.dart

// PhraseSniperGame is now exported from cultural/phrase_sniper_game.dart

// All remaining games are now exported from their respective files:
// - LiarLiarGame from cultural/liar_liar_game.dart
// - VillageQuestGame from cultural/village_quest_game.dart
// - AccentPuzzleGame from cultural/accent_puzzle_game.dart
// - FlashcardSafariGame from cultural/flashcard_safari_game.dart
// - TongueTwisterGame from cultural/tongue_twister_game.dart
// - EmojiTranslatorGame from cultural/emoji_translator_game.dart
// - RhythmTypingGame from cultural/rhythm_typing_game.dart
// - EldersBlessingsGame from cultural/elders_blessings_game.dart
// - MultilingualRelayGame from cultural/multilingual_relay_game.dart
// - CulturalEtiquetteGame from cultural/cultural_etiquette_game.dart
// - DrumWordGame from cultural/drum_word_game.dart



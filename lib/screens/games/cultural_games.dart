import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import '../../services/polie_content_generator.dart';
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
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

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
      // Use fallback content so game is still playable
      setState(() {
        _currentProverb = {
          'proverb': 'Wisdom is like a baobab tree; no one individual can embrace it.',
          'translation': 'Knowledge requires community effort.',
          'meaning': 'Collective wisdom surpasses individual understanding.',
          'context': 'A traditional saying emphasizing community learning.',
          'language': widget.language,
        };
        _round++;
        _shuffledOptions = _createOptions(_currentProverb!);
        _isLoadingProverb = false;
      });
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
      cardId: 'proverb_$_round',
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
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

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

// ClanStoryGame -> cultural/clan_story_game.dart

/// Market Bargaining Simulator Game
class MarketBargainingGame extends BaseGameScreen {
  const MarketBargainingGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

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
      cardId: 'bargain_$_round',
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
                      '$_sellerPrice ${widget.language == 'Swahili' ? 'shillings' : 'naira'}',
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

// Remaining cultural games are exported from their own files in cultural/
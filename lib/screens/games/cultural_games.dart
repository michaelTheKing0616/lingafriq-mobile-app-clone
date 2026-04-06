import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/game_content_provider.dart';
import '../../models/game/game_content_models.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';
import '../../services/polie_content_generator.dart';
import '../../widgets/error_boundary.dart';
import '../../screens/loading/dynamic_loading_screen.dart';
import 'base_game_screen.dart';
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

/// Proverb Unlocker Game — Fill-in-the-blank ancestral tablet UI
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
  ConsumerState<ProverbUnlockerGame> createState() =>
      _ProverbUnlockerGameState();
}

class _ProverbUnlockerGameState
    extends BaseGameScreenState<ProverbUnlockerGame> {
  List<GameProverb> _proverbs = [];
  int _currentIndex = 0;
  List<String> _proverbWords = [];
  List<int> _blankIndices = [];
  Map<int, String> _filledBlanks = {};
  List<String> _tokenOptions = [];
  Set<String> _usedTokens = {};
  String _culturalNote = '';
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  int getCardCount() => 6;

  @override
  Future<void> onGameInitialized() async {
    final loaded = ref.read(
      gameProverbsProvider(GameContentFilter(language: widget.language)),
    );
    if (loaded.isNotEmpty) {
      _proverbs = List.of(loaded)..shuffle(Random());
      if (_proverbs.length > 6) _proverbs = _proverbs.sublist(0, 6);
    } else {
      _proverbs = _fallbackProverbs();
    }
    _prepareRound();
  }

  List<GameProverb> _fallbackProverbs() => [
        const GameProverb(id: 1, language: 'Yoruba', original: 'Agbara eniyan ju ti eranko lo', translation: 'Human strength surpasses that of animals', meaning: 'Unity and intelligence overcome brute force', cefr: 'A1'),
        const GameProverb(id: 2, language: 'Swahili', original: 'Haraka haraka haina baraka', translation: 'Hurry hurry has no blessing', meaning: 'Patience leads to better outcomes', cefr: 'A1'),
        const GameProverb(id: 3, language: 'Zulu', original: 'Umuntu ngumuntu ngabantu', translation: 'A person is a person through people', meaning: 'Humanity is defined by community', cefr: 'A1'),
        const GameProverb(id: 4, language: 'Igbo', original: 'Onye aghana nwanne ya', translation: 'Be your brother\'s keeper', meaning: 'Look after each other always', cefr: 'A1'),
        const GameProverb(id: 5, language: 'Xhosa', original: 'Umntu ngumntu ngabantu', translation: 'I am because we are', meaning: 'Individual identity is rooted in collective belonging', cefr: 'A1'),
        const GameProverb(id: 6, language: 'Amharic', original: 'Sew besew yinoralal', translation: 'People live through people', meaning: 'Community support sustains life', cefr: 'A1'),
      ];

  void _prepareRound() {
    if (_currentIndex >= _proverbs.length) {
      finishGame();
      return;
    }
    final proverb = _proverbs[_currentIndex];
    final words = proverb.original.split(' ');
    final rng = Random();

    final blankCount = (words.length > 5) ? 2 : 1;
    final blanks = <int>{};
    while (blanks.length < blankCount && blanks.length < words.length) {
      blanks.add(rng.nextInt(words.length));
    }

    final correctTokens = blanks.map((i) => words[i]).toList();
    final distractors = <String>[];
    for (final p in _proverbs) {
      for (final w in p.original.split(' ')) {
        if (!correctTokens.contains(w) && !distractors.contains(w)) {
          distractors.add(w);
        }
        if (distractors.length >= 5 - correctTokens.length) break;
      }
      if (distractors.length >= 5 - correctTokens.length) break;
    }
    while (distractors.length + correctTokens.length < 5) {
      distractors.add('word${distractors.length}');
    }

    final allTokens = [...correctTokens, ...distractors.take(5 - correctTokens.length)]
      ..shuffle(rng);

    setState(() {
      _proverbWords = words;
      _blankIndices = blanks.toList()..sort();
      _filledBlanks = {};
      _tokenOptions = allTokens;
      _usedTokens = {};
      _showResult = false;
      _isCorrect = false;
      _culturalNote = proverb.meaning ?? proverb.translation;
    });
  }

  void _tapToken(String token) {
    if (_showResult || _usedTokens.contains(token)) return;
    HapticFeedback.selectionClick();
    final nextBlank = _blankIndices.firstWhere(
      (i) => !_filledBlanks.containsKey(i),
      orElse: () => -1,
    );
    if (nextBlank < 0) return;
    setState(() {
      _filledBlanks[nextBlank] = token;
      _usedTokens.add(token);
    });
  }

  void _tapFilledBlank(int index) {
    if (_showResult) return;
    final token = _filledBlanks[index];
    if (token == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _filledBlanks.remove(index);
      _usedTokens.remove(token);
    });
  }

  void _unlockWisdom() {
    if (_filledBlanks.length < _blankIndices.length) return;
    HapticFeedback.mediumImpact();
    final correct = _blankIndices.every(
      (i) => _filledBlanks[i] == _proverbWords[i],
    );

    setState(() {
      _showResult = true;
      _isCorrect = correct;
    });

    completeTurn(
      cardId: 'proverb_$_currentIndex',
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 5000,
      feedback: {
        'filled': _filledBlanks.map((k, v) => MapEntry(k.toString(), v)),
        'expected': {for (final i in _blankIndices) i.toString(): _proverbWords[i]},
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _currentIndex++;
      _prepareRound();
    });
  }

  @override
  String? get appBarTitle => 'Proverb Unlocker';

  @override
  Widget buildGameContent(BuildContext context) {
    if (_proverbs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 72.h, 16.w, 24.h),
          children: [
            _ancestralTablet(cs),
            SizedBox(height: 20.h),
            _wisdomTokens(cs),
            SizedBox(height: 24.h),
            GriotGradientButton(
              label: 'Unlock Wisdom',
              icon: Icons.lock_open_rounded,
              onPressed: _filledBlanks.length == _blankIndices.length && !_showResult
                  ? _unlockWisdom
                  : null,
            ),
            SizedBox(height: 20.h),
            GameCulturalNoteCard(
              title: "Griot's Insight",
              body: _culturalNote,
            ),
            if (_showResult) ...[
              SizedBox(height: 16.h),
              _resultBanner(cs),
            ],
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GameTopBar(
            onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
            currentStep: _currentIndex + 1,
            totalSteps: _proverbs.length,
          ),
        ),
      ],
    );
  }

  Widget _ancestralTablet(ColorScheme cs) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD4A574), Color(0xFFB8956A)],
          ),
          borderRadius: ModernGriotRadius.borderXl,
          boxShadow: ModernGriotShadows.lg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded,
                size: 36.sp, color: const Color(0xFFFFD700).withOpacity(0.6)),
            SizedBox(height: 16.h),
            Text(
              'Ancestral Proverb',
              style: ModernGriotTypography.titleMedium(
                  context: context, color: Colors.white),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6.w,
                  runSpacing: 12.h,
                  children: List.generate(_proverbWords.length, (i) {
                    if (_blankIndices.contains(i)) {
                      final filled = _filledBlanks[i];
                      final showCorrectSlot = _showResult && filled != null && filled == _proverbWords[i];
                      final showWrongSlot = _showResult && filled != null && filled != _proverbWords[i];
                      return GestureDetector(
                        onTap: () => _tapFilledBlank(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          constraints: BoxConstraints(minWidth: 60.w),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: showCorrectSlot
                                ? ModernGriotColors.secondary.withOpacity(0.3)
                                : showWrongSlot
                                    ? ModernGriotColors.error.withOpacity(0.3)
                                    : filled != null
                                        ? Colors.white.withOpacity(0.25)
                                        : Colors.white.withOpacity(0.1),
                            borderRadius: ModernGriotRadius.borderSm,
                            border: Border(
                              bottom: BorderSide(
                                color: showCorrectSlot
                                    ? ModernGriotColors.secondary
                                    : showWrongSlot
                                        ? ModernGriotColors.error
                                        : const Color(0xFFFFD700),
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Text(
                            filled ?? '___',
                            textAlign: TextAlign.center,
                            style: ModernGriotTypography.bodyLarge(
                              context: context,
                              color: filled != null
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        _proverbWords[i],
                        style: ModernGriotTypography.bodyLarge(
                            context: context, color: Colors.white),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            if (_proverbs.isNotEmpty && _currentIndex < _proverbs.length)
              Text(
                _proverbs[_currentIndex].translation,
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodySmall(
                  context: context,
                  color: Colors.white.withOpacity(0.65),
                ).copyWith(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _wisdomTokens(ColorScheme cs) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10.w,
      runSpacing: 10.h,
      children: _tokenOptions.map((token) {
        final used = _usedTokens.contains(token);
        return GestureDetector(
          onTap: () => _tapToken(token),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: used ? 0.35 : 1.0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: used
                    ? cs.surfaceContainerHigh
                    : ModernGriotColors.primaryContainer.withOpacity(0.2),
                borderRadius: ModernGriotRadius.borderPill,
                border: Border.all(
                  color: used
                      ? cs.outlineVariant.withOpacity(0.2)
                      : ModernGriotColors.primaryContainer,
                  width: 1.5,
                ),
                boxShadow: used ? null : ModernGriotShadows.sm,
              ),
              child: Text(
                token,
                style: ModernGriotTypography.labelLarge(
                  context: context,
                  color: used
                      ? ModernGriotColors.onSurfaceVariant
                      : ModernGriotColors.primary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _resultBanner(ColorScheme cs) {
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isCorrect
                ? ModernGriotColors.secondary
                : ModernGriotColors.error,
            size: 28.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _isCorrect
                  ? 'Wisdom unlocked! The ancestors speak through you.'
                  : 'Not quite — the correct words were: ${_blankIndices.map((i) => _proverbWords[i]).join(", ")}',
              style: ModernGriotTypography.bodyMedium(context: context),
            ),
          ),
        ],
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
    // Bypass BaseGameScreen scaffold to avoid nesting; use GameKit screen directly.
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
  List<Widget>? get appBarActions {
    if (isLoading || _isLoadingScenario || _round > _maxRounds) return null;
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
      );
    } catch (e, st) {
      debugPrint('MarketBargainingGame buildGameContent: $e $st');
      rethrow;
    }
  }
}

// Remaining cultural games are exported from their own files in cultural/
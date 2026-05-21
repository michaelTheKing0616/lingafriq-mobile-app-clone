// This file contains advanced game implementations.
// Each game follows the BaseGameScreen pattern.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/game/game_session_model.dart';
import '../../models/game/phrase_card_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/dio_provider.dart';
import '../../providers/api_provider.dart';
import '../../services/polie_content_generator.dart';
import '../../services/voice/pronunciation_analysis_service.dart';
import '../../models/lesson_item_model.dart';
import '../../utils/pan_african_design_system.dart';
import '../../utils/media_url_resolver.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

const bool _allowSyntheticGameContent = bool.fromEnvironment(
  'ALLOW_SYNTHETIC_GAME_CONTENT',
  defaultValue: false,
);

/// Shared helpers used by advanced game screens.
mixin GameTemplateMixin<T extends BaseGameScreen> on BaseGameScreenState<T> {
  // Common game logic can go here
}

String _normalizedLanguageKey(String language) {
  return language.trim().toLowerCase();
}

List<PhraseCard> _cardsForLanguage(WidgetRef ref, String language) {
  final allCards = ref.read(gameProvider.notifier).availableCards;
  final normalizedLanguage = _normalizedLanguageKey(language);
  final matching = allCards
      .where((card) => _normalizedLanguageKey(card.language) == normalizedLanguage)
      .toList();
  return matching.isNotEmpty ? matching : allCards.toList();
}

List<String> _staticGrammarSentenceBank(String language) {
  switch (_normalizedLanguageKey(language)) {
    case 'yoruba':
      return const [
        'Mo n ko Yoruba lojoojumo.',
        'E kaaro, bawo ni o se wa?',
        'A o lo si oja ni ale.',
      ];
    case 'swahili':
      return const [
        'Ninajifunza Kiswahili kila siku.',
        'Habari yako rafiki yangu?',
        'Tutakwenda sokoni jioni.',
      ];
    case 'hausa':
      return const [
        'Ina koyon Hausa kowace rana.',
        'Sannu, yaya kake yau?',
        'Za mu je kasuwa da yamma.',
      ];
    default:
      return [
        'I am practicing $language every day.',
        'Today we greet and ask simple questions in $language.',
        'We can describe food, places, and daily routines in $language.',
      ];
  }
}

List<Map<String, dynamic>> _buildGrammarFallbackSentences({
  required WidgetRef ref,
  required String language,
}) {
  final cards = _cardsForLanguage(ref, language);
  final cardSentences = cards
      .expand((card) => card.contextExamples)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .take(8)
      .toList();

  final sourceSentences = cardSentences.isNotEmpty ? cardSentences : _staticGrammarSentenceBank(language);
  return sourceSentences.map((line) {
    final words = line
        .split(RegExp(r'[ ,.!?;:]+'))
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();
    return {
      'sentence': line,
      'words': words,
    };
  }).toList();
}

List<String> _staticKaraokeLyricsBank(String language) {
  switch (_normalizedLanguageKey(language)) {
    case 'yoruba':
      return const [
        'E kaabo si kilasi wa',
        'A n ko ede wa pelu ayo',
        'So oro naa ni kedere',
        'A tun so o, a si mo o',
      ];
    case 'swahili':
      return const [
        'Karibu kwenye darasa letu',
        'Tunajifunza kwa furaha',
        'Sema maneno kwa uwazi',
        'Rudia tena kwa kujiamini',
      ];
    case 'hausa':
      return const [
        'Barka da zuwa ajinmu',
        'Muna koyo cikin farin ciki',
        'Faɗi kalmomi a sarari',
        'Maimaita su da kwarin gwiwa',
      ];
    default:
      return [
        'Welcome to this $language practice song',
        'We repeat each phrase with steady rhythm',
        'Speak clearly and keep your flow',
        'Finish strong with confident pronunciation',
      ];
  }
}

Map<String, dynamic> _buildKaraokeFallbackSong({
  required WidgetRef ref,
  required String language,
  String? preferredTitle,
  List<String>? seedLyrics,
}) {
  final cards = _cardsForLanguage(ref, language);
  final cardLines = cards
      .expand((card) => <String>[card.text, ...card.contextExamples])
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .take(6)
      .toList();
  final lyrics = (seedLyrics != null && seedLyrics.isNotEmpty)
      ? seedLyrics.take(6).toList()
      : (cardLines.isNotEmpty ? cardLines : _staticKaraokeLyricsBank(language));

  return {
    'title': (preferredTitle != null && preferredTitle.trim().isNotEmpty)
        ? preferredTitle.trim()
        : '$language Pronunciation Flow',
    'lyrics': lyrics,
  };
}

List<String> _staticRecipeStepsBank(String language) {
  switch (_normalizedLanguageKey(language)) {
    case 'yoruba':
      return const [
        'Gba eroja pataki jọ sinu ago.',
        'Ge eroja naa si kekere ki won le se yarayara.',
        'Dá epo sinu ikoko, fi ata ati alubosa kun un.',
        'Jẹ ki o jo die, fi obe naa sin pelu ounje gbigbona.',
      ];
    case 'swahili':
      return const [
        'Kusanya viungo vikuu kwenye meza.',
        'Kata viungo vipande vidogo kwa kupika haraka.',
        'Weka mafuta, kisha ongeza vitunguu na viungo.',
        'Pika kwa moto wa wastani hadi chakula kiwe tayari.',
      ];
    case 'hausa':
      return const [
        'Tattara manyan kayan hadi a wuri guda.',
        'Yanka kayan kaɗan-kaɗan domin su dahu da sauri.',
        'Zuba mai a tukunya, ƙara albasa da kayan ƙamshi.',
        'Dafa a wuta matsakaici har sai ya yi kyau a ci.',
      ];
    default:
      return [
        'Gather your core ingredients for this $language dish.',
        'Prepare and cut ingredients into even pieces.',
        'Cook aromatics first, then add the main ingredients.',
        'Finish gently and serve while warm.',
      ];
  }
}

Map<String, dynamic> _buildQuizChefFallbackRecipe({
  required WidgetRef ref,
  required String language,
  String? preferredTitle,
}) {
  final cards = _cardsForLanguage(ref, language);
  final ingredients = cards
      .map((card) => card.gloss.trim().isNotEmpty ? card.gloss.trim() : card.text.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .take(4)
      .toList();

  final steps = ingredients.length >= 3
      ? <String>[
          'Gather ${ingredients.take(3).join(', ')}.',
          'Prepare the ingredients and repeat each key word in $language.',
          'Cook everything together and adjust seasoning.',
          'Serve the dish and describe the flavor in $language.',
        ]
      : _staticRecipeStepsBank(language);

  final title = (preferredTitle != null && preferredTitle.trim().isNotEmpty)
      ? preferredTitle.trim()
      : '$language Home Kitchen Challenge';

  return {
    'title': title,
    'steps': steps
        .asMap()
        .entries
        .map((entry) => {
              'step': entry.value,
              'order': entry.key + 1,
            })
        .toList(),
  };
}

// ========== GAME IMPLEMENTATIONS ==========

/// Listen & Sketch Game
class ListenSketchGame extends BaseGameScreen {
  const ListenSketchGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.listenAndSketch;

  @override
  ConsumerState<ListenSketchGame> createState() => _ListenSketchGameState();
}

class _ListenSketchGameState extends BaseGameScreenState<ListenSketchGame> {
  String? _audioText;
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _showDrawingInterface = false;
  PhraseCard? _currentCard;
  final List<PhraseCard> _cards = [];
  List<PhraseCard> _optionCards = [];
  int _correctOptionIndex = 0;

  @override
  int getCardCount() => 5;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isNotEmpty) {
      _prepareRound();
    }
  }

  void _prepareRound() {
    _currentCard = _cards[_currentIndex];
    _audioText = _currentCard!.gloss;
    final distractors = _cards.where((card) => card.cardId != _currentCard!.cardId).toList();
    distractors.shuffle(Random());
    _optionCards = [_currentCard!, ...distractors.take(3)];
    _optionCards.shuffle(Random());
    _correctOptionIndex =
        _optionCards.indexWhere((card) => card.cardId == _currentCard!.cardId);
  }

  Future<void> _playAudio() async {
    final resolved = resolveMediaUrl(_currentCard?.audioNativeUrl);
    if (resolved == null || resolved.isEmpty) return;
    
    setState(() => _isPlaying = true);
    try {
      await _audioPlayer.setUrl(resolved);
      await _audioPlayer.play();
      await _audioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
      setState(() {
        _isPlaying = false;
        _showDrawingInterface = true;
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() => _isPlaying = false);
    }
  }

  void _selectPicture(int index) {
    final isCorrect = index == _correctOptionIndex;
    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;
    
    completeTurn(
      cardId: _currentCard!.cardId,
      result: isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      feedback: {
        'selected_option_index': index,
        'correct_option_index': _correctOptionIndex,
        'audio_text': _audioText,
      },
    );

    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _prepareRound();
        _showDrawingInterface = false;
      });
    } else {
      finishGame();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  String? get appBarTitle =>
      _currentCard == null ? null : widget.getGameType().displayName;

  @override
  String? get shellProgressLabel =>
      _cards.isEmpty ? null : '${_currentIndex + 1}/${_cards.length}';

  @override
  Widget buildGameContent(BuildContext context) {
    try {
      if (_currentCard == null) {
        return const Center(child: Text('No cards available'));
      }

      return Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _cards.length,
            ),
            SizedBox(height: 4.h),
            if (!_showDrawingInterface)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.headphones, size: 64),
                      SizedBox(height: 2.h),
                      Text(
                        'Listen to the description',
                        style: TextStyle(fontSize: 18.sp),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4.h),
                      FilledButton.icon(
                        onPressed: _isPlaying ? null : _playAudio,
                        icon: Icon(_isPlaying ? Icons.volume_up : Icons.play_arrow),
                        label: Text(_isPlaying ? 'Playing...' : 'Play Audio'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Select the correct picture:',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4.h),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _optionCards.length,
                        itemBuilder: (context, index) {
                          final option = _optionCards[index];
                          return Card(
                            child: InkWell(
                              onTap: () => _selectPicture(index),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if ((option.imageUrl ?? '').isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: option.imageUrl!,
                                          height: 56,
                                          width: 56,
                                          fit: BoxFit.cover,
                                          fadeInDuration: const Duration(milliseconds: 180),
                                          placeholder: (_, __) => const Icon(Icons.image, size: 48),
                                          errorWidget: (_, __, ___) => const Icon(Icons.image, size: 48),
                                          memCacheWidth: 56,
                                          memCacheHeight: 56,
                                        ),
                                      )
                                    else
                                      const Icon(Icons.image, size: 48),
                                    SizedBox(height: 8),
                                    Text(
                                      option.gloss,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('ListenSketchGame buildGameContent: $e $st');
      rethrow;
    }
  }
}

/// Picture-Word Association Game
class PictureWordGame extends BaseGameScreen {
  const PictureWordGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.pictureWordAssociation;

  @override
  ConsumerState<PictureWordGame> createState() => _PictureWordGameState();
}

class _PictureWordGameState extends BaseGameScreenState<PictureWordGame> {
  final List<PhraseCard> _cards = [];
  int _currentIndex = 0;
  PhraseCard? _currentCard;
  String? _selectedWord;
  List<String> _wordOptions = [];
  // ignore: unused_field
  int _score = 0;
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  int getCardCount() => 8;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isNotEmpty) {
      _loadCurrentCard();
    }
  }

  void _loadCurrentCard() {
    if (_currentIndex >= _cards.length) {
      finishGame();
      return;
    }
    
    setState(() {
      _currentCard = _cards[_currentIndex];
      _selectedWord = null;
      _showResult = false;
      _wordOptions = _generateWordOptions(_currentCard!);
    });
  }

  List<String> _generateWordOptions(PhraseCard card) {
    final options = [card.gloss];
    // Add 3 random wrong options from other cards
    final otherCards = _cards.where((c) => c.cardId != card.cardId).toList();
    otherCards.shuffle(Random());
    for (int i = 0; i < 3 && i < otherCards.length; i++) {
      options.add(otherCards[i].gloss);
    }
    options.shuffle(Random());
    return options;
  }

  void _selectWord(String word) {
    if (_showResult) return;
    
    setState(() {
      _selectedWord = word;
      _isCorrect = word == _currentCard!.gloss;
      _showResult = true;
      if (_isCorrect) _score++;
    });

    HapticFeedback.mediumImpact();
    
    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    completeTurn(
      cardId: _currentCard!.cardId,
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {
        'selected_word': word,
        'correct_word': _currentCard!.gloss,
        'image_url': _currentCard!.imageUrl,
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _loadCurrentCard();
        });
      }
    });
  }

  @override
  String? get appBarTitle =>
      (isLoading || _currentCard == null) ? null : widget.getGameType().displayName;

  @override
  String? get shellProgressLabel =>
      _cards.isEmpty ? null : '${_currentIndex + 1}/${_cards.length}';

  @override
  Widget buildGameContent(BuildContext context) {
    try {
      if (isLoading || _currentCard == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final progress = (_currentIndex + 1) / _cards.length;

      return Column(
        children: [
          LinearProgressIndicator(value: progress),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 300.h,
                    decoration: BoxDecoration(
                      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      boxShadow: PanAfricanShadows.md,
                    ),
                    child: _currentCard!.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                            child: CachedNetworkImage(
                              imageUrl: _currentCard!.imageUrl!,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 180),
                              placeholder: (_, __) => Center(
                                child: Icon(Icons.image, size: 64.sp, color: PanAfricanColors.neutralMedium),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Icon(Icons.image, size: 64.sp, color: PanAfricanColors.neutralMedium),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.image, size: 64.sp, color: PanAfricanColors.neutralMedium),
                          ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Select the correct word:',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2.h),
                  ..._wordOptions.map((word) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _showResult ? null : () => _selectWord(word),
                            style: FilledButton.styleFrom(
                              backgroundColor: _showResult
                                  ? (_isCorrect && word == _selectedWord
                                      ? Colors.green
                                      : (!_isCorrect && word == _selectedWord
                                          ? Colors.red
                                          : (word == _currentCard!.gloss && _showResult
                                              ? Colors.green.shade100
                                              : null)))
                                  : PanAfricanColors.primary,
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                            ),
                            child: Text(
                              word,
                              style: TextStyle(fontSize: 16.sp),
                            ),
                          ),
                        ),
                      )),
                  if (_showResult)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        _isCorrect ? 'Correct! 🎉' : 'Incorrect. Try again!',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: _isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    } catch (e, st) {
      debugPrint('PictureWordGame buildGameContent: $e $st');
      rethrow;
    }
  }
}

/// Memory Map Game
class MemoryMapGame extends BaseGameScreen {
  const MemoryMapGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.memoryMap;

  @override
  ConsumerState<MemoryMapGame> createState() => _MemoryMapGameState();
}

class _MemoryMapGameState extends BaseGameScreenState<MemoryMapGame> {
  final List<PhraseCard> _cards = [];
  final Map<String, Offset> _wordPositions = {};
  String? _selectedWord;
  String? _targetLocation;
  int _currentRound = 0;
  final int _maxRounds = 5;
  // ignore: unused_field
  int _score = 0;
  bool _showResult = false;

  @override
  int getCardCount() => 10;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isNotEmpty) {
      _setupRound();
    }
  }

  void _setupRound() {
    if (_currentRound >= _maxRounds) {
      finishGame();
      return;
    }

    setState(() {
      _currentRound++;
      _wordPositions.clear();
      _selectedWord = null;
      _showResult = false;
      
      // Assign words to random map positions
      final random = Random();
      for (int i = 0; i < _cards.length && i < 8; i++) {
        final card = _cards[i];
        _wordPositions[card.gloss] = Offset(
          random.nextDouble() * 0.8 + 0.1, // 0.1 to 0.9
          random.nextDouble() * 0.8 + 0.1,
        );
      }
      
      // Select a random target word
      final words = _wordPositions.keys.toList();
      _targetLocation = words[random.nextInt(words.length)];
    });
  }

  void _selectWord(String word) {
    if (_showResult) return;
    
    setState(() {
      _selectedWord = word;
      _showResult = true;
      
      final isCorrect = word == _targetLocation;
      if (isCorrect) _score++;
      
      final duration = startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 0;

      completeTurn(
        cardId: _cards.firstWhere((c) => c.gloss == word).cardId,
        result: isCorrect ? GameResult.correct : GameResult.incorrect,
        durationMs: duration,
        confidence: isCorrect ? 1.0 : 0.0,
        feedback: {
          'selected_word': word,
          'target_location': _targetLocation,
          'round': _currentRound,
        },
      );
    });

    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _setupRound();
      }
    });
  }

  @override
  String? get appBarTitle =>
      (isLoading || _wordPositions.isEmpty) ? null : widget.getGameType().displayName;

  @override
  String? get shellProgressLabel =>
      _wordPositions.isEmpty ? null : '$_currentRound/$_maxRounds';

  @override
  Widget buildGameContent(BuildContext context) {
    try {
      if (isLoading || _wordPositions.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final colorScheme = Theme.of(context).colorScheme;

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Text(
                  'Find the word at this location:',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  ),
                  child: Text(
                    _targetLocation!,
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                    border: Border.all(color: PanAfricanColors.primary, width: 2),
                  ),
                  child: CustomPaint(
                    painter: _MapPainter(
                      wordPositions: _wordPositions,
                      selectedWord: _selectedWord,
                      targetLocation: _targetLocation,
                      showResult: _showResult,
                      labelColor: colorScheme.onPrimary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
                      boxShadow: PanAfricanShadows.md,
                    ),
                    child: Wrap(
                      spacing: 2.w,
                      runSpacing: 2.h,
                      children: _wordPositions.keys.map((word) {
                        final isSelected = word == _selectedWord;
                        final isCorrect = word == _targetLocation && _showResult;
                        final isWrong = isSelected && word != _targetLocation && _showResult;
                        
                        return FilledButton(
                          onPressed: _showResult ? null : () => _selectWord(word),
                          style: FilledButton.styleFrom(
                            backgroundColor: isWrong
                                ? Colors.red
                                : (isCorrect && _showResult
                                    ? Colors.green
                                    : PanAfricanColors.primary),
                          ),
                          child: Text(word),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e, st) {
      debugPrint('MemoryMapGame buildGameContent: $e $st');
      rethrow;
    }
  }
}

class _MapPainter extends CustomPainter {
  final Map<String, Offset> wordPositions;
  final String? selectedWord;
  final String? targetLocation;
  final bool showResult;
  final Color labelColor;

  _MapPainter({
    required this.wordPositions,
    required this.selectedWord,
    required this.targetLocation,
    required this.showResult,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    // Draw map features (simplified)
    paint.color = Colors.brown.shade300;
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), 20, paint);
    
    // Draw word markers
    wordPositions.forEach((word, position) {
      final x = position.dx * size.width;
      final y = position.dy * size.height;
      
      if (showResult && word == targetLocation) {
        paint.color = Colors.green;
      } else if (showResult && word == selectedWord && word != targetLocation) {
        paint.color = Colors.red;
      } else {
        paint.color = Colors.blue;
      }
      
      canvas.drawCircle(Offset(x, y), 15, paint);
      
      // Draw word label
      final textPainter = TextPainter(
        text: TextSpan(
          text: word.length > 8 ? '${word.substring(0, 8)}...' : word,
          style: TextStyle(color: labelColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + 20));
    });
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) {
    return oldDelegate.wordPositions != wordPositions ||
        oldDelegate.selectedWord != selectedWord ||
        oldDelegate.showResult != showResult;
  }
}

/// Pronunciation Karaoke Game
class PronunciationKaraokeGame extends BaseGameScreen {
  const PronunciationKaraokeGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.pronunciationKaraoke;

  @override
  ConsumerState<PronunciationKaraokeGame> createState() => _PronunciationKaraokeGameState();
}

class _PronunciationKaraokeGameState extends BaseGameScreenState<PronunciationKaraokeGame> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Map<String, dynamic>> _songs = [];
  int _currentSongIndex = 0;
  Map<String, dynamic>? _currentSong;
  bool _isRecording = false;
  bool _isPlaying = false;
  int? _pronunciationScore;
  String? _pronunciationError;
  String? _recordingPath;
  int _currentLineIndex = 0;
  List<String> _lyrics = [];
  String? _loadError;
  Map<String, String>? _authHeaders;

  @override
  int getCardCount() => 3;

  @override
  Future<void> onGameInitialized() async {
    await _loadAuthHeaders();
    await _loadSongs();
  }

  Future<void> _loadAuthHeaders() async {
    try {
      var token = ref.read(apiProvider.notifier).token;
      token ??= await ref.read(apiProvider.notifier).refreshAccessToken();
      if (token != null && token.isNotEmpty) {
        _authHeaders = {'Authorization': 'Bearer $token'};
      } else {
        _authHeaders = null;
      }
    } catch (_) {
      _authHeaders = null;
    }
  }

  Future<void> _loadSongs() async {
    try {
      final bundled = _buildKaraokeFallbackSong(
        ref: ref,
        language: widget.language,
      );
      final bundledLyrics = List<String>.from(bundled['lyrics'] as List? ?? []);
      if (bundledLyrics.length >= 3) {
        setState(() {
          _loadError = null;
          _songs.add(bundled);
          _currentSong = bundled;
          _lyrics = bundledLyrics;
        });
        return;
      }

      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final content = await polieGenerator.generateGameContent(
        gameType: 'pronunciation_karaoke',
        language: widget.language,
      );

      final songs = _parseSongs(content['content']?.toString() ?? '');
      final resolvedSongs = songs.isNotEmpty
          ? songs
          : (_allowSyntheticGameContent ? [bundled] : <Map<String, dynamic>>[]);
      if (resolvedSongs.isEmpty) {
        throw Exception('No karaoke content available');
      }
      setState(() {
        _loadError = null;
        _songs.addAll(resolvedSongs);
        if (_songs.isNotEmpty) {
          _currentSong = _songs[0];
          _lyrics = List<String>.from(_currentSong!['lyrics'] as List? ?? []);
        }
      });
    } catch (e) {
      debugPrint('Error loading songs: $e');
      final fallback = _buildKaraokeFallbackSong(
        ref: ref,
        language: widget.language,
      );
      final lyrics = List<String>.from(fallback['lyrics'] as List? ?? []);
      if (lyrics.isNotEmpty) {
        setState(() {
          _loadError = null;
          _songs.add(fallback);
          _currentSong = fallback;
          _lyrics = lyrics;
        });
        return;
      }
      setState(() {
        _loadError = 'Karaoke content is unavailable right now. Please retry.';
      });
    }
  }

  List<Map<String, dynamic>> _parseSongs(String content) {
    final trimmed = content.trim();
    if (trimmed.isNotEmpty) {
      try {
        final decoded = jsonDecode(trimmed);
        final candidates = (decoded is List)
            ? decoded
            : (decoded is Map<String, dynamic> ? decoded['songs'] : null);
        if (candidates is List) {
          final parsedSongs = candidates
              .map<Map<String, dynamic>?>((item) {
                if (item is! Map) return null;
                final map = Map<String, dynamic>.from(item);
                final title = map['title']?.toString();
                final lyricsValue = map['lyrics'];
                final lyrics = (lyricsValue is List)
                    ? lyricsValue
                        .map((line) => line.toString().trim())
                        .where((line) => line.isNotEmpty)
                        .toList()
                    : <String>[];
                final audioUrl = map['audioUrl']?.toString();
                if (title == null || title.isEmpty || lyrics.isEmpty) {
                  return null;
                }
                return {
                  'title': title,
                  'lyrics': lyrics,
                  if (audioUrl != null && audioUrl.isNotEmpty) 'audioUrl': audioUrl,
                };
              })
              .whereType<Map<String, dynamic>>()
              .toList();
          if (parsedSongs.isNotEmpty) {
            return parsedSongs;
          }
        }
      } catch (_) {}
    }

    final lines = content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    String? title;
    String? audioUrl;
    final lyrics = <String>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('title:')) {
        title = line.split(':').skip(1).join(':').trim();
        continue;
      }
      if (lower.startsWith('audio:') || lower.startsWith('audio_url:') || lower.startsWith('audiourl:')) {
        audioUrl = line.split(':').skip(1).join(':').trim();
        continue;
      }
      if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith(RegExp(r'^\d+\.\s'))) {
        final lyric = line.replaceFirst(RegExp(r'^(- |\* |\d+\.\s)'), '').trim();
        if (lyric.isNotEmpty) {
          lyrics.add(lyric);
        }
      }
    }

    if (_allowSyntheticGameContent) {
      final fallbackSong = _buildKaraokeFallbackSong(
        ref: ref,
        language: widget.language,
        preferredTitle: title,
        seedLyrics: lyrics.isNotEmpty ? lyrics : null,
      );
      if (audioUrl != null && audioUrl.isNotEmpty) {
        fallbackSong['audioUrl'] = audioUrl;
      }
      return [fallbackSong];
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _playSong() async {
    final audioUrl = resolveMediaUrl(_currentSong?['audioUrl']?.toString());
    if (audioUrl == null || audioUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reference audio is not available for this track yet.'),
          ),
        );
      }
      return;
    }
    setState(() => _isPlaying = true);
    try {
      try {
        await _audioPlayer.setUrl(audioUrl, headers: _authHeaders);
      } catch (_) {
        await _audioPlayer.setUrl(audioUrl);
      }
      await _audioPlayer.play();
      await _audioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    } catch (e) {
      debugPrint('Error playing karaoke audio: $e');
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      setState(() => _isRecording = true);
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${tempDir.path}/karaoke_$timestamp.m4a';
      await _recorder.start(const RecordConfig(), path: _recordingPath!);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    
    if (path != null && _currentSong != null) {
      await _scorePronunciation(path);
    }
  }

  Future<void> _scorePronunciation(String audioPath) async {
    try {
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) return;

      final currentLine = _lyrics[_currentLineIndex];
      final audioData = await audioFile.readAsBytes();
      final lessonItem = LessonItem(
        id: 'karaoke_${_currentSongIndex}_$_currentLineIndex',
        language: widget.language,
        languageCode: widget.language,
        level: widget.level ?? 'A1',
        category: 'pronunciation',
        type: 'karaoke_line',
        text: currentLine,
        translation: _currentSong?['title']?.toString() ?? 'Karaoke track',
        difficulty: 0.5,
        qualityScore: 0.0,
      );
      final pronunciationService = PronunciationAnalysisService(ref.read(client));
      final result = await pronunciationService.analyzePronunciation(
        audioData: audioData,
        sampleRate: 16000,
        lessonItem: lessonItem,
        enableToneAnalysis: true,
        enablePhonemeAnalysis: true,
      );
      final score = (result.overallScore * 100).round();
      
      setState(() {
        _pronunciationScore = score;
        _pronunciationError = null;
      });

      final duration = startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 0;

      completeTurn(
        cardId: 'karaoke_${_currentSongIndex}_$_currentLineIndex',
        result: score >= 85 ? GameResult.correct : GameResult.partial,
        durationMs: duration,
        confidence: result.overallScore,
        feedback: {
          'score': score,
          'line': currentLine,
          'song': _currentSong!['title'],
          'phoneme_accuracy': result.phonemeAccuracy,
          'tone_accuracy': result.toneAccuracy,
          'fluency': result.fluencyScore,
        },
      );

      if (_currentLineIndex < _lyrics.length - 1) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _currentLineIndex++;
              _pronunciationScore = null;
              _pronunciationError = null;
            });
          }
        });
      } else {
        // Song complete
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            if (_currentSongIndex < _songs.length - 1) {
              setState(() {
                _currentSongIndex++;
                _currentSong = _songs[_currentSongIndex];
                _lyrics = List<String>.from(_currentSong!['lyrics'] as List);
                _currentLineIndex = 0;
                _pronunciationScore = null;
                _pronunciationError = null;
              });
            } else {
              finishGame();
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error scoring pronunciation: $e');
      setState(() {
        _pronunciationScore = null;
        _pronunciationError =
            'We could not grade this attempt. Please record this line again.';
      });
      final duration = startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 0;
      completeTurn(
        cardId: 'karaoke_${_currentSongIndex}_$_currentLineIndex',
        result: GameResult.partial,
        durationMs: duration,
        confidence: 0.0,
        feedback: {
          'graded': false,
          'line': _lyrics[_currentLineIndex],
          'song': _currentSong?['title'],
          'error': e.toString(),
        },
      );
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  String? get appBarTitle =>
      (isLoading || _currentSong == null) ? null : widget.getGameType().displayName;

  @override
  String? get shellProgressLabel => (_lyrics.isEmpty || _currentSong == null)
      ? null
      : 'Song ${_currentSongIndex + 1}/${_songs.length} · Line ${_currentLineIndex + 1}/${_lyrics.length}';

  @override
  Widget buildGameContent(BuildContext context) {
    try {
      if (_loadError != null) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                SizedBox(height: 2.h),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 2.h),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _loadError = null;
                      _songs.clear();
                      _currentSong = null;
                      _lyrics = [];
                      _currentSongIndex = 0;
                      _currentLineIndex = 0;
                    });
                    _loadSongs();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      if (isLoading || _currentSong == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final colorScheme = Theme.of(context).colorScheme;

      return Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_pronunciationScore != null)
                    Container(
                      padding: EdgeInsets.all(4.w),
                      margin: EdgeInsets.only(bottom: 4.h),
                      decoration: BoxDecoration(
                        color: _pronunciationScore! >= 85
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                      child: Text(
                        'Score: $_pronunciationScore%',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: _pronunciationScore! >= 85 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  if (_pronunciationError != null)
                    Container(
                      padding: EdgeInsets.all(3.w),
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                      child: Text(
                        _pronunciationError!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Text(
                    _lyrics[_currentLineIndex],
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: PanAfricanColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Line ${_currentLineIndex + 1} of ${_lyrics.length}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              boxShadow: PanAfricanShadows.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 48.sp,
                  onPressed: _isPlaying ? null : _playSong,
                  color: PanAfricanColors.primary,
                ),
                GestureDetector(
                  onTapDown: (_) => _startRecording(),
                  onTapUp: (_) => _stopRecording(),
                  onTapCancel: () => _stopRecording(),
                  child: Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : PanAfricanColors.primary,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: colorScheme.onPrimary,
                      size: 40.sp,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 48.sp,
                  onPressed: _pronunciationScore == null ? null : () {
                    if (_currentLineIndex < _lyrics.length - 1) {
                      setState(() {
                        _currentLineIndex++;
                        _pronunciationScore = null;
                        _pronunciationError = null;
                      });
                    }
                  },
                  color: PanAfricanColors.primary,
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e, st) {
      debugPrint('PronunciationKaraokeGame buildGameContent: $e $st');
      rethrow;
    }
  }
}

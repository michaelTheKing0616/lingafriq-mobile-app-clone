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
import '../../services/games/game_image_service.dart';
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
                                          height: 64,
                                          width: 64,
                                          fit: BoxFit.cover,
                                          fadeInDuration: const Duration(milliseconds: 180),
                                          placeholder: (_, __) => _GameTileVisual(
                                            gloss: option.gloss,
                                            seed: option.cardId.hashCode,
                                          ),
                                          errorWidget: (_, __, ___) => _GameTileVisual(
                                            gloss: option.gloss,
                                            seed: option.cardId.hashCode,
                                          ),
                                          memCacheWidth: 64,
                                          memCacheHeight: 64,
                                        ),
                                      )
                                    else
                                      _GameTileVisual(
                                        gloss: option.gloss,
                                        seed: option.cardId.hashCode,
                                      ),
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

class _GameTileVisual extends StatelessWidget {
  final String gloss;
  final int seed;
  const _GameTileVisual({required this.gloss, required this.seed});

  @override
  Widget build(BuildContext context) {
    final visual = GameImageService.instance.resolveForGloss(gloss, seed: seed);
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        visual.emoji,
        style: const TextStyle(fontSize: 34),
      ),
    );
  }
}

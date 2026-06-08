import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/game/game_session_model.dart';
import '../../../models/game/game_content_models.dart';
import '../../../services/polie_content_generator.dart';
import '../../../widgets/error_boundary.dart';
import '../../loading/dynamic_loading_screen.dart';
import '../base_game_screen.dart';
import '../mixins/round_progress_shell_mixin.dart';
import '../game_scenario_loader.dart';
import '../../../widgets/content/vocab_audio_controls.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

/// Flashcard Safari Game - AR vocabulary scanning
class FlashcardSafariGame extends BaseGameScreen {
  const FlashcardSafariGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.flashcardSafari;

  @override
  ConsumerState<FlashcardSafariGame> createState() => _FlashcardSafariGameState();
}

class _FlashcardSafariGameState extends BaseGameScreenState<FlashcardSafariGame>
    with RoundProgressGameShellMixin<FlashcardSafariGame> {
  Map<String, dynamic>? _currentCard;
  List<String> _translationOptions = [];
  String? _selectedTranslation;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  List<GameWord> _bundledWords = [];

  @override
  int get gameRound => _round;

  @override
  int get gameMaxRounds => _maxRounds;

  @override
  int get gameScore => _score;

  String _word = '';
  bool _showWord = true;
  String? _correctTranslation;

  @override
  bool get requiresPhraseCards => false;

  @override
  Future<void> onGameInitialized() async {
    _bundledWords = loadBundledGameWords(
      ref,
      language: widget.language,
      gameTag: 'FlashcardSafari',
      max: 24,
    );
    await _loadNewCard();
  }

  Future<void> _loadNewCard() async {
    if (_round >= _maxRounds) {
      await _endGame();
      return;
    }

    setState(() {
      setLoading(true);
      _showResult = false;
      _selectedTranslation = null;
      _showWord = true;
    });

    if (_bundledWords.isNotEmpty) {
      final rng = Random();
      final word = _bundledWords[rng.nextInt(_bundledWords.length)];
      final pool = _bundledWords
          .map((w) => w.englishMeaning)
          .where((m) => m.isNotEmpty && m != word.englishMeaning)
          .toSet()
          .toList()
        ..shuffle(rng);
      final options = <String>[word.englishMeaning];
      for (final d in pool) {
        if (options.length >= 4) break;
        if (!options.contains(d)) options.add(d);
      }
      while (options.length < 4) {
        options.add('—');
      }
      options.shuffle(rng);
      setState(() {
        _currentCard = {'bundled': true, 'id': word.id};
        _round++;
        _word = word.word;
        _correctTranslation = word.englishMeaning;
        _translationOptions = options.take(4).toList();
        setLoading(false);
      });
      return;
    }

    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final gameContent = await polieGenerator.generateGameContent(
        gameType: 'flashcard_safari',
        language: widget.language,
      );

      final content = gameContent['content']?.toString() ?? '';
      final parsed = _parseCard(content);

      setState(() {
        _currentCard = gameContent;
        _round++;
        _word = parsed['word'] as String;
        final options = List<String>.from(parsed['options'] as List<String>);
        _correctTranslation = options.isNotEmpty ? options.first : null;
        _translationOptions = List<String>.from(options)..shuffle(Random());
        setLoading(false);
      });
    } catch (e) {
      debugPrint('Error loading card: $e');
      setState(() {
        setLoading(false);
        _round++;
        _word = _getFallbackWord();
        final fallback = _getFallbackTranslations();
        _correctTranslation = fallback.first;
        _translationOptions = List<String>.from(fallback)..shuffle(Random());
      });
    }
  }

  Map<String, dynamic> _parseCard(String content) {
    final lines = content.split('\n');
    String? word;
    final options = <String>[];

    for (var line in lines) {
      if (line.toLowerCase().contains('word:') || line.toLowerCase().contains('vocabulary:')) {
        word = line.split(':').skip(1).join(':').trim();
      } else if (line.toLowerCase().contains('meaning:') ||
          line.toLowerCase().contains('translation:')) {
        options.add(line.split(':').skip(1).join(':').trim());
      } else if (line.trim().startsWith('-') || line.trim().startsWith('•')) {
        options.add(line.replaceFirst(RegExp(r'^[-•]\s*'), '').trim());
      }
    }

    return {
      'word': word ?? _getFallbackWord(),
      'options': options.isNotEmpty ? options : _getFallbackTranslations(),
    };
  }

  String _getFallbackWord() => 'Ẹ kú àárọ̀';

  List<String> _getFallbackTranslations() => [
        'Good morning',
        'Thank you',
        'How are you',
        'Welcome',
      ];

  void _flipCard() {
    setState(() => _showWord = !_showWord);
  }

  void _selectTranslation(String translation) {
    if (_showResult) return;
    setState(() {
      _selectedTranslation = translation;
      _isCorrect = translation == _correctTranslation;
      _showResult = true;
      if (_isCorrect) _score += 10;
    });
  }

  Future<void> _nextCard() async {
    await Future.delayed(const Duration(milliseconds: 800));
    await _loadNewCard();
  }

  Future<void> _endGame() async {
    await finishGame();
    if (!mounted) return;
    final accuracy = _maxRounds > 0 ? _score / (_maxRounds * 10) : 0.0;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Safari complete'),
        content: Text(
          'Score: $_score\nAccuracy: ${(accuracy.clamp(0, 1) * 100).toStringAsFixed(0)}%',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
          onRetry: () => _loadNewCard(),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(error!),
                SizedBox(height: 2.h),
                FilledButton(
                  onPressed: () => _loadNewCard(),
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
            GestureDetector(
              onTap: _flipCard,
              child: Card(
                elevation: 8,
                child: Container(
                  height: 40.h,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _showWord
                          ? [Colors.orange[100]!, Colors.orange[300]!]
                          : [Colors.green[100]!, Colors.green[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showWord ? Icons.camera_alt : Icons.translate,
                          size: 64.sp,
                          color: Colors.brown,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _showWord ? _word : 'Tap to see word',
                          style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (_showWord) ...[
                          SizedBox(height: 8.h),
                          VocabAudioControls(
                            language: widget.language,
                            text: _word,
                            compact: true,
                          ),
                        ],
                        SizedBox(height: 1.h),
                        Text(
                          _showWord ? 'Tap to flip' : 'Tap to see word',
                          style: TextStyle(fontSize: 14.sp, color: Colors.brown[700]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            ..._translationOptions.map((translation) {
              final isSelected = _selectedTranslation == translation;
              final isCorrect = translation == _correctTranslation;
              Color? bgColor;
              if (_showResult && isSelected) {
                bgColor = isCorrect ? Colors.green[100] : Colors.red[100];
              }
              return Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: ElevatedButton(
                  onPressed: _showResult ? null : () => _selectTranslation(translation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor,
                    padding: EdgeInsets.all(3.w),
                  ),
                  child: Text(
                    translation,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ),
              );
            }),
            if (_showResult) ...[
              SizedBox(height: 2.h),
              Text(
                _isCorrect ? 'Correct!' : 'Try again next round',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: _isCorrect ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              FilledButton(
                onPressed: _nextCard,
                child: const Text('Next Card'),
              ),
            ],
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('FlashcardSafariGame buildGameContent: $e $st');
      return Center(child: Text('Error: $e'));
    }
  }
}

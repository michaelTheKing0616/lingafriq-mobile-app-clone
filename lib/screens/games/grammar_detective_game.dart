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
import 'base_game_screen.dart';

class GrammarDetectiveGame extends BaseGameScreen {
  const GrammarDetectiveGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.grammarDetective;

  @override
  ConsumerState<GrammarDetectiveGame> createState() =>
      _GrammarDetectiveGameState();
}

class _GrammarDetectiveGameState
    extends BaseGameScreenState<GrammarDetectiveGame> {
  late List<_GrammarSentence> _sentences;
  int _currentIndex = 0;
  final Set<int> _markedWords = {};
  bool _submitted = false;
  int _totalCorrect = 0;

  @override
  int getCardCount() => 8;

  @override
  Future<void> onGameInitialized() async {
    final cards = ref.read(gameProvider.notifier).availableCards;
    final rng = Random();

    _sentences = cards.map((card) {
      final words = card.text.split(' ');
      final errorCount = (words.length > 4) ? rng.nextInt(2) + 1 : 1;
      final errorIndices = <int>{};
      while (errorIndices.length < errorCount &&
          errorIndices.length < words.length) {
        errorIndices.add(rng.nextInt(words.length));
      }

      final corrupted = List<String>.from(words);
      final corrections = <int, _ErrorCorrection>{};
      for (final idx in errorIndices) {
        final original = corrupted[idx];
        final mangled = _corruptWord(original, rng);
        corrections[idx] = _ErrorCorrection(
          errorWord: mangled,
          correctWord: original,
        );
        corrupted[idx] = mangled;
      }

      return _GrammarSentence(
        words: corrupted,
        errorIndices: errorIndices,
        corrections: corrections,
        translation: card.gloss,
        culturalNote: card.contextExamples.isNotEmpty
            ? card.contextExamples.first
            : 'Practice makes perfect in ${widget.language}.',
      );
    }).toList();

    setState(() {});
  }

  String _corruptWord(String word, Random rng) {
    if (word.length <= 2) return '${word}a';
    final i = rng.nextInt(word.length - 1) + 1;
    final chars = word.split('');
    final tmp = chars[i];
    chars[i] = chars[i - 1];
    chars[i - 1] = tmp;
    return chars.join();
  }

  void _toggleWord(int index) {
    if (_submitted) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_markedWords.contains(index)) {
        _markedWords.remove(index);
      } else {
        _markedWords.add(index);
      }
    });
  }

  void _submitCorrections() {
    if (_submitted) return;
    HapticFeedback.mediumImpact();
    final sentence = _sentences[_currentIndex];
    final correctHits =
        _markedWords.intersection(sentence.errorIndices).length;
    final falseAlarms =
        _markedWords.difference(sentence.errorIndices).length;
    final isGood =
        correctHits == sentence.errorIndices.length && falseAlarms == 0;

    if (isGood) _totalCorrect++;

    setState(() => _submitted = true);

    completeTurn(
      cardId: 'grammar_$_currentIndex',
      result: isGood ? GameResult.correct : GameResult.incorrect,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 5000,
      feedback: {
        'marked': _markedWords.toList(),
        'errors': sentence.errorIndices.toList(),
      },
    );
  }

  void _nextSentence() {
    if (_currentIndex < _sentences.length - 1) {
      setState(() {
        _currentIndex++;
        _markedWords.clear();
        _submitted = false;
      });
    } else {
      finishGame();
    }
  }

  double get _accuracy =>
      _sentences.isEmpty ? 0 : _totalCorrect / (_currentIndex + 1);

  @override
  String? get appBarTitle => 'Grammar Detective';

  @override
  Widget buildGameContent(BuildContext context) {
    if (_sentences.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final cs = Theme.of(context).colorScheme;
    final sentence = _sentences[_currentIndex];

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 72.h, 16.w, 100.h),
          children: [
            _parchmentBlock(cs, sentence),
            SizedBox(height: 16.h),
            if (_submitted) _correctionGuide(cs, sentence),
            if (_submitted) SizedBox(height: 16.h),
            _heritageInsight(cs, sentence),
            SizedBox(height: 16.h),
            _scoreDisplay(cs),
            SizedBox(height: 24.h),
            if (!_submitted)
              GriotGradientButton(
                label: 'Submit Corrections',
                icon: Icons.search_rounded,
                onPressed: _markedWords.isNotEmpty ? _submitCorrections : null,
              )
            else
              GriotGradientButton(
                label: _currentIndex < _sentences.length - 1
                    ? 'Next Sentence'
                    : 'Finish',
                icon: Icons.arrow_forward_rounded,
                onPressed: _nextSentence,
              ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GameTopBar(
            onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
            currentStep: _currentIndex + 1,
            totalSteps: _sentences.length,
          ),
        ),
      ],
    );
  }

  Widget _parchmentBlock(ColorScheme cs, _GrammarSentence sentence) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.md,
        image: DecorationImage(
          image: const AssetImage('assets/images/parchment_texture.png'),
          fit: BoxFit.cover,
          opacity: 0.05,
          onError: (_, __) {},
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.policy_rounded,
                  size: 20.sp, color: ModernGriotColors.primary),
              SizedBox(width: 8.w),
              Text('Find the errors',
                  style: ModernGriotTypography.titleSmall(context: context)),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 8.h,
            children: List.generate(sentence.words.length, (i) {
              final isMarked = _markedWords.contains(i);
              final isError = sentence.errorIndices.contains(i);
              final showCorrect = _submitted && isError && isMarked;
              final showMissed = _submitted && isError && !isMarked;
              final showFalse = _submitted && !isError && isMarked;

              Color chipBg;
              Color chipText;
              if (showCorrect) {
                chipBg = ModernGriotColors.error.withOpacity(0.15);
                chipText = ModernGriotColors.error;
              } else if (showMissed) {
                chipBg = Colors.orange.withOpacity(0.15);
                chipText = Colors.orange.shade800;
              } else if (showFalse) {
                chipBg = ModernGriotColors.onSurfaceVariant.withOpacity(0.1);
                chipText = ModernGriotColors.onSurfaceVariant;
              } else if (isMarked) {
                chipBg = ModernGriotColors.error.withOpacity(0.12);
                chipText = ModernGriotColors.error;
              } else {
                chipBg = Colors.transparent;
                chipText = ModernGriotColors.onSurface;
              }

              return GestureDetector(
                onTap: () => _toggleWord(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: ModernGriotRadius.borderSm,
                    border: isMarked && !_submitted
                        ? Border.all(
                            color: ModernGriotColors.error, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    sentence.words[i],
                    style: ModernGriotTypography.bodyLarge(
                      context: context,
                      color: chipText,
                    ).copyWith(
                      decoration:
                          isMarked ? TextDecoration.underline : null,
                      decorationColor: ModernGriotColors.error,
                      decorationThickness: 2,
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 12.h),
          Text(
            sentence.translation,
            style: ModernGriotTypography.bodySmall(context: context).copyWith(
              fontStyle: FontStyle.italic,
              color: ModernGriotColors.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _correctionGuide(ColorScheme cs, _GrammarSentence sentence) {
    final entries = sentence.corrections.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded,
                  size: 20.sp, color: ModernGriotColors.secondary),
              SizedBox(width: 8.w),
              Text("Griot's Guide",
                  style: ModernGriotTypography.titleSmall(context: context)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Text('Error',
                    style: ModernGriotTypography.labelMedium(
                        context: context, color: ModernGriotColors.error)),
              ),
              Expanded(
                child: Text('Correction',
                    style: ModernGriotTypography.labelMedium(
                        context: context,
                        color: ModernGriotColors.secondary)),
              ),
            ],
          ),
          Divider(color: cs.outlineVariant.withOpacity(0.2), height: 16.h),
          ...entries.map((e) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: ModernGriotColors.error.withOpacity(0.08),
                          borderRadius: ModernGriotRadius.borderSm,
                        ),
                        child: Text(
                          e.value.errorWord,
                          style: ModernGriotTypography.bodyMedium(
                            context: context,
                            color: ModernGriotColors.error,
                          ).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16.sp,
                        color: ModernGriotColors.onSurfaceVariant),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color:
                              ModernGriotColors.secondary.withOpacity(0.08),
                          borderRadius: ModernGriotRadius.borderSm,
                        ),
                        child: Text(
                          e.value.correctWord,
                          style: ModernGriotTypography.bodyMedium(
                            context: context,
                            color: ModernGriotColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _heritageInsight(ColorScheme cs, _GrammarSentence sentence) {
    return GriotCard(
      surfaceLevel: 0,
      padding: EdgeInsets.all(16.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: ModernGriotColors.primaryContainer.withOpacity(0.3),
              borderRadius: ModernGriotRadius.borderLg,
            ),
            child: Icon(Icons.temple_hindu_rounded,
                size: 32.sp,
                color: ModernGriotColors.primary.withOpacity(0.6)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Heritage Insight',
                    style:
                        ModernGriotTypography.labelLarge(context: context)),
                SizedBox(height: 4.h),
                Text(
                  sentence.culturalNote,
                  style: ModernGriotTypography.bodySmall(context: context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreDisplay(ColorScheme cs) {
    final pct = (_accuracy * 100).toStringAsFixed(0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.analytics_rounded,
            size: 20.sp, color: ModernGriotColors.primary),
        SizedBox(width: 8.w),
        Text(
          'Accuracy: $pct%',
          style: ModernGriotTypography.titleSmall(
              context: context, color: ModernGriotColors.primary),
        ),
        SizedBox(width: 16.w),
        Text(
          '$_totalCorrect / ${_currentIndex + 1}',
          style: ModernGriotTypography.bodyMedium(context: context),
        ),
      ],
    );
  }
}

class _GrammarSentence {
  final List<String> words;
  final Set<int> errorIndices;
  final Map<int, _ErrorCorrection> corrections;
  final String translation;
  final String culturalNote;

  const _GrammarSentence({
    required this.words,
    required this.errorIndices,
    required this.corrections,
    required this.translation,
    required this.culturalNote,
  });
}

class _ErrorCorrection {
  final String errorWord;
  final String correctWord;
  const _ErrorCorrection({required this.errorWord, required this.correctWord});
}

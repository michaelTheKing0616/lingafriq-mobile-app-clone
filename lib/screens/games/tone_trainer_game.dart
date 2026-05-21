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
import '../../utils/pan_african_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';
import 'base_game_screen.dart';
import 'game_scenario_loader.dart';

class ToneTrainerGame extends BaseGameScreen {
  const ToneTrainerGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.toneTrainer;

  @override
  ConsumerState<ToneTrainerGame> createState() => _ToneTrainerGameState();
}

class _ToneTrainerGameState extends BaseGameScreenState<ToneTrainerGame> {
  final List<PhraseCard> _cards = [];
  final List<_ToneQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedTone;
  bool _answered = false;
  int _score = 0;

  @override
  int getCardCount() => 8;

  @override
  Future<void> onGameInitialized() async {
    final lang = widget.language.toLowerCase();
    final tonalWords = ref
        .read(
          gameWordsProvider(
            GameContentFilter(language: lang, gameTag: 'ToneTrainer'),
          ),
        )
        .where((w) => w.tonalNote != null && w.tonalNote!.trim().isNotEmpty)
        .toList();

    if (tonalWords.isNotEmpty) {
      final pool = List.of(tonalWords)..shuffle(Random());
      for (final word in pool.take(getCardCount())) {
        _cards.add(_phraseFromGameWord(word));
        _questions.add(_ToneQuestion(
          card: _cards.last,
          correctToneIndex: _toneIndexFromNote(word.tonalNote!),
          toneLabels: const ['á (High)', 'ā (Mid)', 'à (Low)'],
          toneSymbols: const ['á', 'ā', 'à'],
          tonalHint: word.tonalNote,
        ));
      }
    }

    final scenarios = loadBundledGameScenarios(
      ref,
      language: widget.language,
      game: 'ToneTrainer',
      max: getCardCount(),
    );
    if (_questions.length < getCardCount() && scenarios.isNotEmpty) {
      for (final scenario in scenarios) {
        if (_questions.length >= getCardCount()) break;
        _cards.add(PhraseCard(
          cardId: 'tone_scenario_${scenario.id}',
          language: widget.language,
          text: scenario.prompt,
          ascii: scenario.prompt,
          gloss: scenario.expectedResponse ?? scenario.title,
          level: scenario.cefr,
          contextExamples: [
            if (scenario.culturalNote != null) scenario.culturalNote!,
          ],
        ));
        _questions.add(_ToneQuestion(
          card: _cards.last,
          correctToneIndex: _toneIndexFromNote(
            scenario.culturalNote ?? scenario.expectedResponse ?? '',
          ),
          toneLabels: const ['á (High)', 'ā (Mid)', 'à (Low)'],
          toneSymbols: const ['á', 'ā', 'à'],
          tonalHint: scenario.culturalNote ?? scenario.title,
        ));
      }
    }

    if (_questions.isEmpty) {
      final gameProv = ref.read(gameProvider.notifier);
      _cards.addAll(gameProv.availableCards);
      _buildQuestionsFromCards();
    }
    setState(() {});
  }

  PhraseCard _phraseFromGameWord(GameWord word) => PhraseCard(
        cardId: 'tone_word_${word.id}',
        language: word.language,
        text: word.word,
        ascii: word.word,
        gloss: word.englishMeaning,
        ipa: word.phoneticGuide,
        level: word.cefr,
        contextExamples: [
          if (word.culturalNote != null) word.culturalNote!,
        ],
      );

  int _toneIndexFromNote(String note) {
    final lower = note.toLowerCase();
    if (lower.contains('low')) return 2;
    if (lower.contains('mid')) return 1;
    if (lower.contains('high')) return 0;
    return 1;
  }

  void _buildQuestionsFromCards() {
    final rng = Random(DateTime.now().millisecondsSinceEpoch);
    for (final card in _cards) {
      final correctTone = rng.nextInt(3);
      _questions.add(_ToneQuestion(
        card: card,
        correctToneIndex: correctTone,
        toneLabels: const ['á (High)', 'ā (Mid)', 'à (Low)'],
        toneSymbols: const ['á', 'ā', 'à'],
      ));
    }
  }

  _ToneQuestion? get _currentQuestion =>
      _currentIndex < _questions.length ? _questions[_currentIndex] : null;

  void _selectTone(int index) {
    if (_answered) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedTone = index);
  }

  void _checkSelection() {
    if (_selectedTone == null || _answered) return;
    HapticFeedback.mediumImpact();

    final q = _currentQuestion!;
    final correct = _selectedTone == q.correctToneIndex;

    if (correct) _score++;

    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;
    completeTurn(
      cardId: q.card.cardId,
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      confidence: correct ? 1.0 : 0.0,
      userAction: 'tone_selected_${_selectedTone}',
    );

    setState(() => _answered = true);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedTone = null;
        _answered = false;
      });
    } else {
      finishGame();
    }
  }

  @override
  String? get appBarTitle =>
      'Tone Trainer (${_currentIndex + 1}/${_questions.length})';

  @override
  Widget buildGameContent(BuildContext context) {
    if (_questions.isEmpty) {
      return Center(
        child: Text('No tonal words available',
            style: ModernGriotTypography.bodyLarge(context: context)),
      );
    }

    final q = _currentQuestion;
    if (q == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final progress = _questions.isEmpty
        ? 0.0
        : (_currentIndex + 1) / _questions.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
        child: Column(
          children: [
            SizedBox(height: PanAfricanSpacing.sm),
            GriotProgressBar(value: progress, height: 6, showGlowTip: true),
            SizedBox(height: PanAfricanSpacing.lg),
            // Word display
            Text(q.card.text,
                style: ModernGriotTypography.displaySmall(context: context),
                textAlign: TextAlign.center),
            if (q.card.ipa != null) ...[
              SizedBox(height: PanAfricanSpacing.xxs),
              Text('/${q.card.ipa}/',
                  style: ModernGriotTypography.bodyMedium(
                      context: context,
                      color: ModernGriotColors.onSurfaceVariant)),
            ],
            SizedBox(height: PanAfricanSpacing.xs),
            Text(q.card.gloss,
                style: ModernGriotTypography.bodyLarge(
                    context: context,
                    color: ModernGriotColors.onSurfaceVariant),
                textAlign: TextAlign.center),
            SizedBox(height: PanAfricanSpacing.lg),
            // Tone height visualization
            Container(
              width: double.infinity,
              height: 120.h,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: ModernGriotRadius.borderXl,
                border: Border.all(
                    color: ModernGriotColors.outlineVariant.withOpacity(0.3)),
              ),
              child: CustomPaint(
                painter: _ToneArcPainter(
                  highlightedIndex: _selectedTone,
                  correctIndex: _answered ? q.correctToneIndex : null,
                  primaryColor: ModernGriotColors.primary,
                  secondaryColor: ModernGriotColors.secondary,
                  errorColor: ModernGriotColors.error,
                  surfaceColor: ModernGriotColors.outlineVariant,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (i) {
                      final heights = [0.15, 0.45, 0.75];
                      return Padding(
                        padding: EdgeInsets.only(top: heights[i] * 80.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedTone == i
                                    ? ModernGriotColors.primaryContainer
                                    : cs.surfaceContainerHighest,
                                border: Border.all(
                                  color: _selectedTone == i
                                      ? ModernGriotColors.primary
                                      : ModernGriotColors.outlineVariant,
                                  width: _selectedTone == i ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  q.toneSymbols[i],
                                  style: ModernGriotTypography.titleMedium(
                                    context: context,
                                    color: _selectedTone == i
                                        ? ModernGriotColors.primary
                                        : ModernGriotColors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              ['High', 'Mid', 'Low'][i],
                              style: ModernGriotTypography.labelSmall(
                                  context: context),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            // Semantic shift sidebar
            _SemanticShiftCard(language: widget.language, word: q.card.text),
            SizedBox(height: PanAfricanSpacing.md),
            // Tone selectors
            Text('Select the correct tone pattern:',
                style: ModernGriotTypography.titleSmall(context: context)),
            SizedBox(height: PanAfricanSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) {
                final isCorrect = _answered && i == q.correctToneIndex;
                final isWrong = _answered && _selectedTone == i && !isCorrect;
                final isActive = _selectedTone == i && !_answered;

                Color bg;
                Color border;
                if (isCorrect) {
                  bg = ModernGriotColors.secondary.withOpacity(0.15);
                  border = ModernGriotColors.secondary;
                } else if (isWrong) {
                  bg = ModernGriotColors.error.withOpacity(0.12);
                  border = ModernGriotColors.error;
                } else if (isActive) {
                  bg = ModernGriotColors.primaryContainer.withOpacity(0.3);
                  border = ModernGriotColors.primary;
                } else {
                  bg = cs.surfaceContainerLowest;
                  border = ModernGriotColors.outlineVariant;
                }

                return GestureDetector(
                  onTap: () => _selectTone(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 90.w,
                    height: 90.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bg,
                      border: Border.all(color: border, width: isActive ? 2.5 : 1.5),
                      boxShadow: isActive ? ModernGriotShadows.sm : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(q.toneSymbols[i],
                            style: ModernGriotTypography.headlineSmall(
                                context: context)),
                        SizedBox(height: 2.h),
                        Text(q.toneLabels[i],
                            style: ModernGriotTypography.labelSmall(
                                context: context),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            // CTA button
            if (!_answered)
              GriotGradientButton(
                label: 'Check Selection',
                icon: Icons.check_rounded,
                onPressed: _selectedTone != null ? _checkSelection : null,
              )
            else
              GriotGradientButton(
                label: _currentIndex < _questions.length - 1
                    ? 'Next Word'
                    : 'Finish Game',
                icon: Icons.arrow_forward_rounded,
                onPressed: _nextQuestion,
              ),
            SizedBox(height: PanAfricanSpacing.md),
            // Cultural note
            GameCulturalNoteCard(
              title: 'Did you know?',
              body: q.tonalHint ?? _getTonalFact(widget.language),
              icon: Icons.lightbulb_rounded,
            ),
            SizedBox(height: PanAfricanSpacing.xl),
          ],
        ),
      ),
    );
  }
}

String _getTonalFact(String language) {
  final lang = language.toLowerCase();
  final facts = <String, String>{
    'yoruba':
        'Yoruba has 3 tones — high (´), mid (unmarked), and low (`). Changing the tone changes the meaning entirely: "ọkọ" can mean husband, hoe, or vehicle.',
    'igbo':
        'Igbo is a tonal language with two main tones: high and low. The word "akụ" (wealth) vs "àkụ̀" (termite) differs only in tone.',
    'hausa':
        'Hausa uses two tones — high and low — to distinguish words. Tone interacts with vowel length to create meaning.',
    'twi':
        'Twi (Akan) uses two level tones and one falling tone. Tone is crucial for distinguishing homophones.',
  };
  return facts[lang] ??
      'Many African languages are tonal, meaning pitch changes the meaning of words. Mastering tones is key to being understood.';
}

class _ToneArcPainter extends CustomPainter {
  final int? highlightedIndex;
  final int? correctIndex;
  final Color primaryColor;
  final Color secondaryColor;
  final Color errorColor;
  final Color surfaceColor;

  _ToneArcPainter({
    this.highlightedIndex,
    this.correctIndex,
    required this.primaryColor,
    required this.secondaryColor,
    required this.errorColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = surfaceColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = primaryColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final x1 = size.width * 0.15;
    final x2 = size.width * 0.50;
    final x3 = size.width * 0.85;
    final y1 = size.height * 0.25;
    final y2 = size.height * 0.50;
    final y3 = size.height * 0.75;

    // Draw dashed arcs connecting the tone positions
    final path1 = Path()
      ..moveTo(x1, y1)
      ..quadraticBezierTo((x1 + x2) / 2, y1 - 10, x2, y2);
    canvas.drawPath(path1, highlightedIndex == 0 ? dashPaint : paint);

    final path2 = Path()
      ..moveTo(x2, y2)
      ..quadraticBezierTo((x2 + x3) / 2, y2 + 10, x3, y3);
    canvas.drawPath(path2, highlightedIndex == 2 ? dashPaint : paint);
  }

  @override
  bool shouldRepaint(_ToneArcPainter old) =>
      old.highlightedIndex != highlightedIndex ||
      old.correctIndex != correctIndex;
}

class _SemanticShiftCard extends StatelessWidget {
  final String language;
  final String word;

  const _SemanticShiftCard({required this.language, required this.word});

  @override
  Widget build(BuildContext context) {
    final lang = language.toLowerCase();
    final pairs = <String, List<List<String>>>{
      'yoruba': [
        ['ọkọ́', 'husband'],
        ['ọkọ', 'vehicle'],
        ['ọ̀kọ̀', 'hoe'],
      ],
      'igbo': [
        ['ákụ́', 'wealth'],
        ['àkụ̀', 'termite'],
        ['ákụ̀', 'parrot'],
      ],
    };

    final examples = pairs[lang] ?? pairs['yoruba']!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderLg,
        border: Border.all(
            color: ModernGriotColors.tertiary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded,
                  size: 16.sp, color: ModernGriotColors.tertiary),
              SizedBox(width: 6.w),
              Text('Minimal Pairs',
                  style: ModernGriotTypography.labelLarge(
                      context: context, color: ModernGriotColors.tertiary)),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          ...examples.map((pair) => Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  children: [
                    Text(pair[0],
                        style: ModernGriotTypography.titleSmall(context: context)),
                    SizedBox(width: 8.w),
                    Text('→',
                        style: ModernGriotTypography.bodySmall(context: context)),
                    SizedBox(width: 8.w),
                    Text(pair[1],
                        style: ModernGriotTypography.bodyMedium(
                            context: context,
                            color: ModernGriotColors.onSurfaceVariant)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ToneQuestion {
  final PhraseCard card;
  final int correctToneIndex;
  final List<String> toneLabels;
  final List<String> toneSymbols;
  final String? tonalHint;

  const _ToneQuestion({
    required this.card,
    required this.correctToneIndex,
    required this.toneLabels,
    required this.toneSymbols,
    this.tonalHint,
  });
}

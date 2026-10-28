import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../games/tone_forge/tone_forge_models.dart';
import '../../learning/pronunciation/tone_models.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import '../../services/offline/tone_trainer_queue_service.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';
import 'base_game_screen.dart';

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
  final List<_ToneQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedTone;
  bool _answered = false;
  int _score = 0;
  ToneLanguageModel? _inventory;

  @override
  int getCardCount() => 8;

  @override
  Future<void> onGameInitialized() async {
    final lang = widget.language.toLowerCase();
    final catalog = await loadToneModelsCatalogFromAsset();
    if (!isToneTrainerAvailable(catalog, lang)) {
      setState(() {});
      return;
    }

    final pool = await buildToneGamePool(
      catalog: catalog,
      languageCode: lang,
      fetchLimit: 48,
    );
    ToneTrainerQueueService.instance
        .recordPoolDiagnostics(pool.diagnostics.formatLine());
    _inventory = pool.inventory;

    if (pool.lexemes.isEmpty || pool.options.isEmpty || pool.inventory == null) {
      setState(() {});
      return;
    }

    final rng = Random();
    final shuffled = List<ToneGameLexeme>.from(pool.lexemes)..shuffle(rng);
    for (final lexeme in shuffled.take(getCardCount())) {
      final syllableIndex = lexeme.tonePattern.length == 1
          ? 0
          : rng.nextInt(lexeme.tonePattern.length);
      final spec = toneTrainerQuestionFromLexeme(
        lexeme: lexeme,
        options: pool.options,
        inventory: pool.inventory!,
        syllableIndex: syllableIndex,
      );
      if (spec == null) continue;
      _questions.add(_ToneQuestion.fromSpec(spec));
    }
    setState(() {});
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
      userAction: 'tone_selected_$_selectedTone',
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
        child: Text(
          _inventory == null
              ? 'Tone Trainer is not available for this language yet.'
              : 'No verified tonal words are ready yet. Check back after more lexicon review.',
          style: ModernGriotTypography.bodyLarge(context: context),
          textAlign: TextAlign.center,
        ),
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
            if (q.syllableLabel.isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.xxs),
              Text(
                q.syllableLabel,
                style: ModernGriotTypography.labelMedium(
                  context: context,
                  color: ModernGriotColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
                    color: ModernGriotColors.outlineVariant.withValues(alpha: 0.3)),
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(q.options.length, (i) {
                      final heights = _toneHeightsForCount(q.options.length);
                      final heightFactor = i < heights.length ? heights[i] : 0.45;
                      final opt = q.options[i];
                      return Padding(
                        padding: EdgeInsets.only(top: heightFactor * 80.h),
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
                                  opt.symbol,
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
                              opt.label,
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
              children: List.generate(q.options.length, (i) {
                final opt = q.options[i];
                final isCorrect = _answered && i == q.correctToneIndex;
                final isWrong = _answered && _selectedTone == i && !isCorrect;
                final isActive = _selectedTone == i && !_answered;

                Color bg;
                Color border;
                if (isCorrect) {
                  bg = ModernGriotColors.secondary.withValues(alpha: 0.15);
                  border = ModernGriotColors.secondary;
                } else if (isWrong) {
                  bg = ModernGriotColors.error.withValues(alpha: 0.12);
                  border = ModernGriotColors.error;
                } else if (isActive) {
                  bg = ModernGriotColors.primaryContainer.withValues(alpha: 0.3);
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
                        Text(opt.symbol,
                            style: ModernGriotTypography.headlineSmall(
                                context: context)),
                        SizedBox(height: 2.h),
                        Text('${opt.symbol} (${opt.label})',
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
      ..color = surfaceColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
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
            color: ModernGriotColors.tertiary.withValues(alpha: 0.3)),
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

List<double> _toneHeightsForCount(int count) {
  if (count <= 1) return const [0.45];
  if (count == 2) return const [0.2, 0.7];
  return const [0.15, 0.45, 0.75];
}

class _ToneQuestion {
  final PhraseCard card;
  final int correctToneIndex;
  final List<ToneInventoryOption> options;
  final int syllableIndex;
  final String? tonalHint;
  final String syllableLabel;

  const _ToneQuestion({
    required this.card,
    required this.correctToneIndex,
    required this.options,
    required this.syllableIndex,
    this.tonalHint,
    this.syllableLabel = '',
  });

  factory _ToneQuestion.fromSpec(ToneTrainerQuestionSpec spec) {
    final lex = spec.lexeme;
    final syllable = spec.syllableIndex < lex.syllables.length
        ? lex.syllables[spec.syllableIndex]
        : '';
    return _ToneQuestion(
      card: PhraseCard(
        cardId: 'tone_lex_${lex.lexemeId}',
        language: lex.language,
        text: lex.toneMarkedForm,
        ascii: lex.toneMarkedForm,
        gloss: lex.englishGloss ?? '',
        level: 'A1',
      ),
      correctToneIndex: spec.correctInventoryIndex,
      options: spec.options,
      syllableIndex: spec.syllableIndex,
      syllableLabel: lex.tonePattern.length > 1
          ? 'Syllable ${spec.syllableIndex + 1}${syllable.isNotEmpty ? ': $syllable' : ''}'
          : '',
      tonalHint: lex.tonePattern.join('–'),
    );
  }
}

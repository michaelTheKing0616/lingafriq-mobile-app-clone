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
import 'game_scenario_loader.dart';

class StoryBuilderGame extends BaseGameScreen {
  const StoryBuilderGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.storyBuilder;

  @override
  ConsumerState<StoryBuilderGame> createState() => _StoryBuilderGameState();
}

class _StoryBuilderGameState extends BaseGameScreenState<StoryBuilderGame> {
  int _currentChapter = 0;
  int _selectedChoice = -1;
  final List<String> _storySegments = [];
  final List<String> _translationSegments = [];
  String _culturalNote = '';
  String _locationName = '';
  List<GameScenario> _scenarios = [];
  late List<PhraseCard> _cards;
  List<_StoryChoice> _choices = [];
  int get _chapterCount =>
      _scenarios.isNotEmpty ? _scenarios.length : _cards.length;

  static const _locations = [
    'Xhosa Village',
    'Yoruba Kingdom',
    'Swahili Coast',
    'Zulu Kraal',
    'Igbo Compound',
  ];

  static const _sceneColors = [
    Color(0xFFD4A574),
    Color(0xFFC48B5C),
    Color(0xFFB87A4B),
    Color(0xFFAA6939),
    Color(0xFF9C5828),
  ];

  @override
  int getCardCount() => 5;

  @override
  Future<void> onGameInitialized() async {
    _cards = ref.read(gameProvider.notifier).availableCards;
    _scenarios = loadBundledGameScenarios(
      ref,
      language: widget.language,
      game: 'StoryBuilder',
      max: 5,
    );
    _locationName = _scenarios.isNotEmpty
        ? _scenarios.first.title
        : _locations[Random().nextInt(_locations.length)];
    _prepareChapter();
  }

  void _prepareChapter() {
    if (_currentChapter >= _chapterCount) {
      finishGame();
      return;
    }
    final rng = Random();

    if (_scenarios.isNotEmpty) {
      final scenario = _scenarios[_currentChapter];
      _storySegments.add(scenario.prompt);
      _translationSegments.add(
        scenario.expectedResponse ?? scenario.title,
      );
      _culturalNote = scenario.culturalNote?.isNotEmpty == true
          ? scenario.culturalNote!
          : 'Continue the story using phrases from ${widget.language}.';
      _locationName = scenario.title;

      final correctText =
          scenario.expectedResponse ?? scenario.prompt;
      final correct = _StoryChoice(
        letter: 'A',
        text: correctText,
        isCorrect: true,
      );
      final distractors = _scenarios
          .where((s) => s.id != scenario.id)
          .map((s) => s.prompt)
          .where((text) => text.isNotEmpty && text != correctText)
          .take(3)
          .map((text) => _StoryChoice(
                letter: '',
                text: text,
                isCorrect: false,
              ))
          .toList();
      while (distractors.length < 3) {
        distractors.add(_StoryChoice(
          letter: '',
          text: 'Skip this beat',
          isCorrect: false,
        ));
      }

      final all = [correct, ...distractors]..shuffle(rng);
      for (var i = 0; i < all.length; i++) {
        all[i] = _StoryChoice(
          letter: String.fromCharCode(65 + i),
          text: all[i].text,
          isCorrect: all[i].isCorrect,
        );
      }

      setState(() {
        _selectedChoice = -1;
        _choices = all;
      });
      return;
    }

    final card = _cards[_currentChapter];

    _storySegments.add(card.text);
    _translationSegments.add(card.gloss);
    _culturalNote = card.contextExamples.isNotEmpty
        ? card.contextExamples.first
        : 'This phrase reflects the cultural values of '
            '${widget.language}-speaking communities.';

    final correct = _StoryChoice(
      letter: 'A',
      text: card.text,
      isCorrect: true,
    );
    final distractors = <_StoryChoice>[];
    final usedIndices = <int>{_currentChapter};
    for (var i = 0; i < 3; i++) {
      int idx;
      do {
        idx = rng.nextInt(_cards.length);
      } while (usedIndices.contains(idx) && usedIndices.length < _cards.length);
      usedIndices.add(idx);
      distractors.add(_StoryChoice(
        letter: String.fromCharCode(66 + i),
        text: _cards[idx].text,
        isCorrect: false,
      ));
    }

    final all = [correct, ...distractors]..shuffle(rng);
    for (var i = 0; i < all.length; i++) {
      all[i] = _StoryChoice(
        letter: String.fromCharCode(65 + i),
        text: all[i].text,
        isCorrect: all[i].isCorrect,
      );
    }

    setState(() {
      _selectedChoice = -1;
      _choices = all;
    });
  }

  void _onChoiceTap(int index) {
    if (_selectedChoice >= 0) return;
    HapticFeedback.lightImpact();
    final choice = _choices[index];

    setState(() => _selectedChoice = index);

    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 3000;

    final cardId = _scenarios.isNotEmpty
        ? 'story_${_scenarios[_currentChapter].id}'
        : _cards[_currentChapter].cardId;
    completeTurn(
      cardId: cardId,
      result: choice.isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      feedback: {'chapter': _currentChapter, 'selected': choice.letter},
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _currentChapter++;
      _prepareChapter();
    });
  }

  @override
  String? get appBarTitle => 'Story Builder';

  @override
  Widget buildGameContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 72.h, 16.w, 100.h),
          children: [
            _heroSceneCard(cs),
            SizedBox(height: 16.h),
            _storyCanvas(cs),
            SizedBox(height: 20.h),
            ..._choiceCards(cs),
            SizedBox(height: 16.h),
            GameCulturalNoteCard(
              title: "Griot's Insight",
              body: _culturalNote,
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GameTopBar(
            onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
            currentStep: _currentChapter + 1,
            totalSteps: _chapterCount,
          ),
        ),
        Positioned(
          bottom: 24.h,
          right: 20.w,
          child: _readAloudFab(),
        ),
      ],
    );
  }

  Widget _heroSceneCard(ColorScheme cs) {
    final bgColor = _sceneColors[_currentChapter % _sceneColors.length];
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: ModernGriotRadius.borderXl,
          boxShadow: ModernGriotShadows.md,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: ModernGriotRadius.borderXl,
                child: CustomPaint(painter: _TrianglePatternPainter(bgColor)),
              ),
            ),
            Center(
              child: Icon(Icons.landscape_rounded,
                  size: 80.sp, color: Colors.white.withOpacity(0.2)),
            ),
            Positioned(
              bottom: 20.h,
              left: 20.w,
              right: 20.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: ModernGriotRadius.borderLg,
                ),
                child: Text(
                  _locationName,
                  style: ModernGriotTypography.headlineSmall(
                      context: context, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyCanvas(ColorScheme cs) {
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded,
                  size: 20.sp, color: ModernGriotColors.primary),
              SizedBox(width: 8.w),
              Text('Story Canvas',
                  style: ModernGriotTypography.titleSmall(context: context)),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _storySegments.join(' '),
            style: ModernGriotTypography.bodyLarge(context: context),
          ),
          SizedBox(height: 8.h),
          Text(
            _translationSegments.join(' '),
            style: ModernGriotTypography.bodyMedium(context: context).copyWith(
              color: ModernGriotColors.onSurfaceVariant.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _choiceCards(ColorScheme cs) {
    return List.generate(_choices.length, (i) {
      final choice = _choices[i];
      final isSelected = _selectedChoice == i;
      final revealed = _selectedChoice >= 0;

      Color? borderColor;
      if (revealed && choice.isCorrect) {
        borderColor = ModernGriotColors.secondary;
      } else if (revealed && isSelected && !choice.isCorrect) {
        borderColor = ModernGriotColors.error;
      } else if (isSelected) {
        borderColor = ModernGriotColors.primary;
      }

      return Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: GestureDetector(
          onTap: _selectedChoice < 0 ? () => _onChoiceTap(i) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: ModernGriotRadius.borderXl,
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 2)
                  : Border.all(
                      color: cs.outlineVariant.withOpacity(0.15), width: 1),
              boxShadow: ModernGriotShadows.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ModernGriotColors.primary
                        : ModernGriotColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      choice.letter,
                      style: ModernGriotTypography.labelLarge(
                        context: context,
                        color: isSelected
                            ? ModernGriotColors.onPrimary
                            : ModernGriotColors.onSurface,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(choice.text,
                      style:
                          ModernGriotTypography.bodyMedium(context: context)),
                ),
                if (revealed && choice.isCorrect)
                  Icon(Icons.check_circle_rounded,
                      color: ModernGriotColors.secondary, size: 22.sp),
                if (revealed && isSelected && !choice.isCorrect)
                  Icon(Icons.cancel_rounded,
                      color: ModernGriotColors.error, size: 22.sp),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _readAloudFab() {
    return GestureDetector(
      onTap: () => HapticFeedback.mediumImpact(),
      child: Container(
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          gradient: ModernGriotGradients.signatureGradient,
          shape: BoxShape.circle,
          boxShadow: ModernGriotShadows.fab,
        ),
        child: Icon(Icons.volume_up_rounded,
            color: ModernGriotColors.onPrimary, size: 26.sp),
      ),
    );
  }
}

class _StoryChoice {
  final String letter;
  final String text;
  final bool isCorrect;
  const _StoryChoice(
      {required this.letter, required this.text, required this.isCorrect});
}

class _TrianglePatternPainter extends CustomPainter {
  final Color baseColor;
  _TrianglePatternPainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    const step = 40.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final path = Path()
          ..moveTo(x, y + step)
          ..lineTo(x + step / 2, y)
          ..lineTo(x + step, y + step)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

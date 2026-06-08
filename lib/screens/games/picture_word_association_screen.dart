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
import '../../services/games/game_image_service.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';
import 'base_game_screen.dart';

/// Picture-Word Association — match a foreign word to the correct image card.
///
/// Shows a large foreign word and four image-placeholder cards in a 2×2 grid.
/// The user selects the card whose meaning matches the word, then taps
/// "CHECK SELECTION". Correct answers glow green; wrong answers shake red.
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
  int? _selectedOption;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _streak = 0;
  DateTime? _roundStart;
  List<_ImageOption> _options = [];
  double _shakeOffset = 0;

  @override
  int getCardCount() => 10;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.length < 4) {
      setError('Need at least 4 cards to play. Try a different language.');
      return;
    }
    _prepareRound();
  }

  void _prepareRound() {
    if (_currentIndex >= _cards.length) {
      finishGame();
      return;
    }

    final card = _cards[_currentIndex];
    final rng = Random();
    final distractors = _cards
        .where((c) => c.cardId != card.cardId)
        .toList()
      ..shuffle(rng);
    final picks = distractors.take(3).toList();
    final all = [card, ...picks]..shuffle(rng);

    _options = all.asMap().entries.map((e) {
      final c = e.value;
      final visual = GameImageService.instance.resolveForGloss(
        c.gloss,
        seed: c.cardId.hashCode,
      );
      return _ImageOption(
        meaning: c.gloss,
        emoji: visual.emoji,
        color: visual.background,
        foreground: visual.foreground,
        icon: visual.icon,
        isCorrect: c.cardId == card.cardId,
      );
    }).toList();

    setState(() {
      _selectedOption = null;
      _showResult = false;
      _shakeOffset = 0;
      _roundStart = DateTime.now();
    });
  }

  void _selectOption(int index) {
    if (_showResult) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedOption = index);
  }

  Future<void> _checkSelection() async {
    if (_selectedOption == null || _showResult) return;

    final correct = _options[_selectedOption!].isCorrect;
    HapticFeedback.mediumImpact();

    setState(() {
      _showResult = true;
      _isCorrect = correct;
      if (correct) {
        _score++;
        _streak++;
      } else {
        _streak = 0;
      }
    });

    if (!correct) _runShake();

    final ms = _roundStart != null
        ? DateTime.now().difference(_roundStart!).inMilliseconds
        : 0;

    final canContinue = await completeTurn(
      cardId: _cards[_currentIndex].cardId,
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: ms,
      confidence: correct ? 1.0 : 0.0,
      feedback: {
        'selected': _options[_selectedOption!].meaning,
        'correct': _cards[_currentIndex].gloss,
        'round': _currentIndex + 1,
      },
    );
    if (!canContinue) return;

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    _currentIndex++;
    _prepareRound();
  }

  Future<void> _runShake() async {
    for (var i = 0; i < 3; i++) {
      if (!mounted) return;
      setState(() => _shakeOffset = 8);
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() => _shakeOffset = -8);
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (mounted) setState(() => _shakeOffset = 0);
  }

  @override
  String? get appBarTitle => _cards.isEmpty
      ? null
      : 'Picture-Word (${_currentIndex + 1}/${_cards.length})';

  @override
  Widget buildGameContent(BuildContext context) {
    if (_cards.isEmpty || _currentIndex >= _cards.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final cs = Theme.of(context).colorScheme;
    final card = _cards[_currentIndex];

    return Column(
      children: [
        GameTopBar(
          onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
          currentStep: _currentIndex + 1,
          totalSteps: _cards.length,
          streak: _streak,
          xp: _score * 10,
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
          child: GriotGlassPanel(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14.sp, color: cs.primary),
                SizedBox(width: 6.w),
                Text(
                  'Step ${_currentIndex + 1} of ${_cards.length}',
                  style: ModernGriotTypography.labelMedium(
                    context: context,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 24.w),
          child: Column(
            children: [
              Text(
                card.text,
                style: ModernGriotTypography.displaySmall(context: context),
                textAlign: TextAlign.center,
              ),
              if (card.ipa != null) ...[
                SizedBox(height: 4.h),
                Text(
                  '/${card.ipa!}/',
                  style: ModernGriotTypography.bodySmall(context: context),
                ),
              ],
            ],
          ),
        ),

        if (_showResult)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: _isCorrect
                      ? ModernGriotColors.secondary
                      : ModernGriotColors.error,
                  size: 20.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  _isCorrect ? 'Correct!' : 'Not quite — the right one is highlighted',
                  style: ModernGriotTypography.labelLarge(
                    context: context,
                    color: _isCorrect
                        ? ModernGriotColors.secondary
                        : ModernGriotColors.error,
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Transform.translate(
              offset: Offset(_shakeOffset, 0),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 0.92,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  _options.length.clamp(0, 4),
                  _buildImageCard,
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
          child: GriotGradientButton(
            label: 'CHECK SELECTION',
            icon: Icons.check_rounded,
            onPressed: _showResult
                ? null
                : (_selectedOption != null ? _checkSelection : null),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(int i) {
    final option = _options[i];
    final selected = _selectedOption == i;
    final correct = _showResult && option.isCorrect;
    final wrong = _showResult && selected && !option.isCorrect;

    Color borderColor = Colors.transparent;
    double bw = 2;
    if (selected && !_showResult) {
      borderColor = ModernGriotColors.primary;
      bw = 3;
    } else if (correct) {
      borderColor = ModernGriotColors.secondary;
      bw = 3;
    } else if (wrong) {
      borderColor = ModernGriotColors.error;
      bw = 3;
    }

    return GestureDetector(
      onTap: _showResult ? null : () => _selectOption(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: ModernGriotRadius.borderXl,
          border: Border.all(color: borderColor, width: bw),
          boxShadow: selected ? ModernGriotShadows.md : ModernGriotShadows.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ModernGriotRadius.xl - bw),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: option.color.withAlpha(wrong ? 90 : 220),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      option.emoji,
                      style: TextStyle(fontSize: 48.sp),
                    ),
                    SizedBox(height: 6.h),
                    Icon(
                      option.icon,
                      size: 22.sp,
                      color: option.foreground.withAlpha(220),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        option.meaning,
                        style: ModernGriotTypography.titleSmall(
                          color: option.foreground,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (correct)
                Container(
                  color: ModernGriotColors.secondary.withAlpha(50),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 48.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (wrong)
                Container(
                  color: ModernGriotColors.error.withAlpha(50),
                  child: Center(
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 48.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageOption {
  final String meaning;
  final String emoji;
  final Color color;
  final Color foreground;
  final IconData icon;
  final bool isCorrect;

  const _ImageOption({
    required this.meaning,
    required this.emoji,
    required this.color,
    required this.foreground,
    required this.icon,
    required this.isCorrect,
  });
}

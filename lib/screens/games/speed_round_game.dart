import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/game_content_provider.dart';
import '../../widgets/content/vocab_audio_controls.dart';
import '../../models/game/game_content_models.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';
import 'base_game_screen.dart';

class SpeedRoundGame extends BaseGameScreen {
  const SpeedRoundGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.speedRoundRemix;

  @override
  ConsumerState<SpeedRoundGame> createState() => _SpeedRoundGameState();
}

class _SpeedRoundGameState extends BaseGameScreenState<SpeedRoundGame>
    with TickerProviderStateMixin {
  final List<PhraseCard> _cards = [];
  int _currentIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  Timer? _timer;
  int _timeLeft = 60;
  bool _gameOver = false;

  final List<_ScorePopupData> _popups = [];
  late final AnimationController _bgController;
  late final Animation<Color?> _bgColor1;
  late final Animation<Color?> _bgColor2;

  @override
  int getCardCount() => 20;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isNotEmpty) _startTimer();
  }

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgColor1 = ColorTween(
      begin: ModernGriotColors.primaryContainer.withOpacity(0.15),
      end: ModernGriotColors.secondaryContainer.withOpacity(0.12),
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
    _bgColor2 = ColorTween(
      begin: ModernGriotColors.tertiaryContainer.withOpacity(0.08),
      end: ModernGriotColors.primaryContainer.withOpacity(0.10),
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  PhraseCard? get _currentCard =>
      _currentIndex < _cards.length ? _cards[_currentIndex] : null;

  void _answer(bool claimedCorrect) {
    if (_gameOver || _currentCard == null) return;
    HapticFeedback.lightImpact();

    final card = _currentCard!;
    final isCorrect = claimedCorrect;
    final points = isCorrect ? 10 : 0;

    if (isCorrect) {
      _score += points;
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      _addPopup('+$points', ModernGriotColors.secondary);
    } else {
      _streak = 0;
    }

    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    completeTurn(
      cardId: card.cardId,
      result: isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      confidence: isCorrect ? 1.0 : 0.0,
      userAction: claimedCorrect ? 'correct_tap' : 'incorrect_tap',
    );

    setState(() => _currentIndex++);
    if (_currentIndex >= _cards.length) _endGame();
  }

  void _addPopup(String text, Color color) {
    final id = DateTime.now().microsecondsSinceEpoch;
    setState(() => _popups.add(_ScorePopupData(id: id, text: text, color: color)));
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _popups.removeWhere((p) => p.id == id));
    });
  }

  void _endGame() {
    _timer?.cancel();
    if (_gameOver) return;
    setState(() => _gameOver = true);
    finishGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgController.dispose();
    super.dispose();
  }

  @override
  String? get appBarTitle =>
      'Speed Round (${_currentIndex + 1}/${_cards.length})';

  @override
  Widget buildGameContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_cards.isEmpty) {
      return Center(
        child: Text('No cards available',
            style: ModernGriotTypography.bodyLarge(context: context)),
      );
    }

    if (_gameOver) {
      return _buildGameOverView(context, cs);
    }

    final card = _currentCard;
    if (card == null) return const SizedBox.shrink();
    final progress = _cards.isEmpty ? 0.0 : _currentIndex / _cards.length;

    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _bgColor1.value ?? Colors.transparent,
                _bgColor2.value ?? Colors.transparent,
              ],
            ),
          ),
          child: child,
        );
      },
      child: SafeArea(
        child: Stack(
          children: [
            // Stitch-style top bar: close + timer anchor + streak pill.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: PanAfricanSpacing.md,
                  vertical: PanAfricanSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.82),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: widget.onBack,
                          icon: Icon(
                            Icons.close_rounded,
                            color: ModernGriotColors.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: PanAfricanSpacing.md,
                            vertical: PanAfricanSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: ModernGriotColors.tertiaryContainer,
                            borderRadius: ModernGriotRadius.borderPill,
                            boxShadow: ModernGriotShadows.xs,
                          ),
                          child: Text(
                            '$_streak 🔥',
                            style: ModernGriotTypography.titleSmall(
                              context: context,
                              color: ModernGriotColors.onTertiaryContainer,
                            ).copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: ModernGriotColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ModernGriotColors.errorContainer,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ModernGriotColors.error.withOpacity(0.25),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$_timeLeft',
                        style: ModernGriotTypography.titleLarge(
                          context: context,
                          color: ModernGriotColors.onError,
                        ).copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                PanAfricanSpacing.md,
                98,
                PanAfricanSpacing.md,
                PanAfricanSpacing.md,
              ),
              child: Column(
                children: [
                  GriotProgressBar(value: progress, height: 6, showGlowTip: true),
                  SizedBox(height: PanAfricanSpacing.lg),
                  Expanded(
                    child: Column(
                      children: [
                        GameQuestionCard(
                          question: card.text,
                          subtitle: card.gloss,
                          hint: card.ipa != null ? 'Phonetic: ${card.ipa}' : null,
                        ),
                        SizedBox(height: PanAfricanSpacing.sm),
                        VocabAudioControls(
                          language: widget.language,
                          text: card.text,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'CORRECT',
                          icon: Icons.check_rounded,
                          color: ModernGriotColors.secondary,
                          onTap: () => _answer(true),
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.sm),
                      Expanded(
                        child: _ActionButton(
                          label: 'INCORRECT',
                          icon: Icons.close_rounded,
                          color: ModernGriotColors.error,
                          onTap: () => _answer(false),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),
                ],
              ),
            ),
            // Floating score popups
            ...List.generate(_popups.length, (i) {
              final p = _popups[i];
              return Positioned(
                top: 180.h,
                left: 0,
                right: 0,
                child: Center(
                  child: GameScorePopup(
                    key: ValueKey(p.id),
                    text: p.text,
                    color: p.color,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverView(BuildContext context, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off_rounded, size: 56.sp, color: ModernGriotColors.primary),
            SizedBox(height: PanAfricanSpacing.md),
            Text("Time's Up!",
                style: ModernGriotTypography.headlineMedium(context: context)),
            SizedBox(height: PanAfricanSpacing.lg),
            GriotMasteryRing(
              value: _cards.isEmpty ? 0 : _score / (_cards.length * 10),
              size: 120,
              label: 'Score',
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text('Best Streak: $_bestStreak',
                style: ModernGriotTypography.titleMedium(context: context)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: ModernGriotRadius.borderXl,
        child: Ink(
          height: 64.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: ModernGriotRadius.borderXl,
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24.sp),
              SizedBox(width: 8.w),
              Text(label,
                  style: ModernGriotTypography.labelLarge(
                      context: context, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePopupData {
  final int id;
  final String text;
  final Color color;
  const _ScorePopupData({required this.id, required this.text, required this.color});
}

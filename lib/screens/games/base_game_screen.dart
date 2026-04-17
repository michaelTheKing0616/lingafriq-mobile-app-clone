import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/hearts_provider.dart';
import '../../services/game_tutorial_helper.dart';
import '../../services/lazy_game_loader.dart';
import '../../services/telemetry_service.dart';
import '../../utils/gamification_integration.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/gamification/gamification_widgets.dart';
import '../../widgets/gamification/combo_tracker.dart';
import '../../widgets/gamification/combo_display_widget.dart';
import '../../services/sound_effects_service.dart';
import '../../widgets/pan_african_components.dart';
import '../../widgets/rive_global_guide.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/skeleton_loader.dart';
import 'templates/game_template_shell.dart';

/// Base class for all game screens - handles common functionality
abstract class BaseGameScreen extends ConsumerStatefulWidget {
  final String language;
  final String? level;
  final VoidCallback? onBack;

  const BaseGameScreen({
    super.key,
    required this.language,
    this.level,
    this.onBack,
  });

  GameType getGameType();
}

/// Formats a language code/name for the compact GameTopBar chip.
String? formatGameLanguageLabel(String language) {
  final raw = language.trim();
  if (raw.isEmpty) return null;
  return raw
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map(
        (w) =>
            '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
      )
      .join(' ');
}

abstract class BaseGameScreenState<T extends BaseGameScreen> extends ConsumerState<T> {
  GameSession? _session;
  DateTime? _startTime;
  bool _isLoading = true;
  String? _error;
  bool _isFinishingGame = false;
  bool _hasShownCompletionDialog = false;
  late final ComboTracker _comboTracker;

  GameSession? get session => _session;
  DateTime? get startTime => _startTime;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ComboTracker get comboTracker => _comboTracker;

  /// Shown in [GameTemplateShell] / [GameTopBar] when not null.
  String? get shellLanguageLabel => formatGameLanguageLabel(widget.language);

  /// e.g. "3/5" — override in games with clear round progress.
  String? get shellProgressLabel => null;

  /// e.g. "12 pts" — override when the game tracks a numeric score.
  String? get shellScoreLabel => null;

  // Protected setter for error - allows subclasses to set error
  void setError(String? error) {
    setState(() {
      _error = error;
    });
  }
  
  // Protected setter for loading state
  void setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }
  
  // Protected setter for start time
  void setStartTime(DateTime? time) {
    setState(() {
      _startTime = time;
    });
  }

  @override
  void initState() {
    super.initState();
    _comboTracker = ComboTracker();
    _initializeGame();
  }
  
  @override
  void dispose() {
    _comboTracker.dispose();
    super.dispose();
  }

  Future<void> _initializeGame() async {
    setState(() => _isLoading = true);
    _isFinishingGame = false;
    _hasShownCompletionDialog = false;
    try {
      // Use logged-in user if available; fall back to guest ID so games
      // always work even if userProvider hasn't been populated yet.
      final user = ref.read(userProvider);
      final userId = user?.id.toString() ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

      // Optional preload — failure must never block game start
      try {
        final lazyLoader = ref.read(lazyGameLoaderProvider);
        await lazyLoader.loadGameOnDemand(
          widget.getGameType(),
          language: widget.language,
        );
      } catch (_) {
        // Preload is non-critical; continue to game
      }

      final gameProv = ref.read(gameProvider.notifier);
      _session = await gameProv.startGame(
        userId: userId,
        gameType: widget.getGameType(),
        language: widget.language,
        level: widget.level,
        cardCount: getCardCount(),
      );

      if (gameProv.availableCards.isEmpty) {
        setState(() {
          _error = 'No content available for ${widget.language} yet.\n'
              'Try selecting another language from the games hub (e.g. Hausa, Igbo, or Kiswahili).';
          _isLoading = false;
        });
        unawaited(
          _emitGameLoadFailureTelemetry(
            'no_cards_available:${widget.language}',
          ),
        );
        return;
      }

      _startTime = DateTime.now();
      _comboTracker.reset(); // Reset combo when starting new game

      // Game-specific init (e.g. AI content generation) is non-fatal.
      // Cards are already loaded — the game can still function with fallback
      // content if onGameInitialized() fails.
      try {
        await onGameInitialized();
      } catch (initError) {
        debugPrint('Game-specific init error (continuing with fallback): $initError');
      }
      
      setState(() => _isLoading = false);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(GameTutorialHelper.maybeShowForGame(context, widget.getGameType()));
      });
    } catch (e) {
      setState(() {
        _error = 'Could not start game: $e';
        _isLoading = false;
      });
      unawaited(_emitGameLoadFailureTelemetry(e));
    }
  }

  Future<void> _emitGameLoadFailureTelemetry(Object error) async {
    try {
      await ref.read(telemetryServiceProvider).trackGameLoadFailed(
            gameType: widget.getGameType().name,
            language: widget.language,
            reason: error.toString(),
          );
    } catch (_) {
      // Telemetry must never affect gameplay
    }
  }


  /// Override to specify card count
  int getCardCount() => 10;

  /// Override for game-specific initialization
  Future<void> onGameInitialized() async {}

  /// Complete a turn - call this from game implementations
  /// Returns false if user is out of hearts and cannot continue
  Future<bool> completeTurn({
    required String cardId,
    required GameResult result,
    required int durationMs,
    double? confidence,
    Map<String, dynamic>? feedback,
    String? userAction,
  }) async {
    if (_session == null) return true;

    final gameProv = ref.read(gameProvider.notifier);
    await gameProv.completeTurn(
      cardId: cardId,
      result: result,
      durationMs: durationMs,
      confidence: confidence,
      feedback: feedback,
      userAction: userAction,
    );

    // Sound effects and combo tracking
    final soundEffects = ref.read(soundEffectsProvider);
    if (result == GameResult.correct) {
      soundEffects.playCorrect();
      _comboTracker.recordCorrect();
    } else {
      soundEffects.playIncorrect();
      _comboTracker.recordIncorrect();
    }

    // If incorrect, check hearts system
    if (result == GameResult.incorrect) {
      final canContinue = await GamificationIntegrationHelper.of(ref).onMistake();
      if (!canContinue && mounted) {
        _showOutOfHeartsDialog();
        return false;
      }
    }
    
    return true;
  }

  /// Show dialog when user runs out of hearts
  void _showOutOfHeartsDialog() {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.lgBR),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.xs),
              decoration: BoxDecoration(
                color: PanAfricanColors.kenteRed.withOpacity(0.1),
                borderRadius: PanAfricanRadius.roundBR,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                color: PanAfricanColors.kenteRed,
                size: 24.sp,
              ),
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            Text(
              'Out of Hearts!',
              style: PanAfricanTypography.titleLarge(context),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'ve run out of hearts. Would you like to refill to continue?',
              style: PanAfricanTypography.bodyMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            const HeartsWidget(showRefill: false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'Exit Game',
              style: PanAfricanTypography.labelLarge(context),
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              HapticFeedback.lightImpact();
              try {
                final success = await GamificationIntegrationHelper.of(ref).refillHearts();
                if (!mounted) return;
                if (success) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Hearts refilled! Continue playing.',
                        style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      backgroundColor: PanAfricanColors.primary,
                    ),
                  );
                } else {
                  // Refill failed — insufficient currency
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Not enough cowries to refill hearts. Come back later or earn more!',
                        style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      backgroundColor: PanAfricanColors.kenteRed,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Something went wrong. Please try again later.',
                        style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                    backgroundColor: PanAfricanColors.kenteRed,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: Icon(Icons.favorite_rounded, size: 20.sp),
            label: Text('Refill Hearts', style: PanAfricanTypography.labelLarge(context, color: Theme.of(context).colorScheme.onPrimary)),
            style: FilledButton.styleFrom(
              backgroundColor: PanAfricanColors.kenteRed,
              shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
            ),
          ),
        ],
      ),
    );
  }

  /// Finish the game
  Future<void> finishGame() async {
    if (_isFinishingGame || _hasShownCompletionDialog) return;
    _isFinishingGame = true;
    try {
      final gameProv = ref.read(gameProvider.notifier);
      final endedSession = await gameProv.endGame();

      // Calculate XP based on performance with combo multiplier
      final baseXP = _calculateXP(endedSession);
      final multiplier = _comboTracker.currentMultiplier;
      final xpEarned = (baseXP * multiplier).round();

      // Award gamification with combo multiplier
      await ref.read(gamificationProvider.notifier).awardXP(
        'game_complete',
        multiplier: multiplier,
        sourceId: '${widget.getGameType().name}_${DateTime.now().millisecondsSinceEpoch}',
      );

      final soundEffects = ref.read(soundEffectsProvider);
      if (endedSession.accuracy >= 1.0) {
        soundEffects.playCelebration();
      } else {
        soundEffects.playCorrect();
      }
      _comboTracker.reset();

      if (mounted) {
        _hasShownCompletionDialog = true;
        _showCompletionDialog(endedSession, xpEarned);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finishing game: $e')),
        );
      }
    } finally {
      _isFinishingGame = false;
    }
  }

  /// Calculate XP based on game performance
  int _calculateXP(GameSession session) {
    const baseXP = 10;
    final accuracyBonus = (session.accuracy * 20).round();
    final speedBonus = session.durationMs < 30000 ? 10 : (session.durationMs < 60000 ? 5 : 0);
    final perfectBonus = session.accuracy >= 1.0 ? 25 : 0;
    
    return baseXP + accuracyBonus + speedBonus + perfectBonus;
  }

  void _showCompletionDialog(GameSession session, int xpEarned) {
    final isPerfect = session.accuracy >= 1.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.mediumImpact();

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, __) => Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Confetti-style decorative elements for perfect scores
              if (isPerfect) _ConfettiLayer(duration: 300),
              // Main content card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.lg),
                child: _CompletionOverlayContent(
                  session: session,
                  xpEarned: xpEarned,
                  isPerfect: isPerfect,
                  isDark: isDark,
                  onPlayAgain: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(ctx);
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder<void>(
                        pageBuilder: (_, __, ___) => widget,
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  onDone: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(ctx);
                    (widget.onBack ?? () => Navigator.pop(context))();
                  },
                  buildStatRow: _buildStatRow,
                ),
              ),
            ],
          ),
        ),
      ),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: isHighlight 
                ? PanAfricanColors.primary 
                : (isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Text(
            label,
            style: PanAfricanTypography.bodyMedium(context),
          ),
          const Spacer(),
          Text(
            value,
            style: isHighlight
                ? PanAfricanTypography.titleMedium(context, color: PanAfricanColors.primary)
                : PanAfricanTypography.titleSmall(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    final heartsState = ref.watch(heartsProvider);
    
    if (_isLoading) {
      return GameTemplateShell(
        title: widget.getGameType().displayName,
        languageLabel: shellLanguageLabel,
        progressLabel: shellProgressLabel,
        scoreLabel: shellScoreLabel,
        onBack: () {
          HapticFeedback.lightImpact();
          (widget.onBack ?? () => Navigator.pop(context))();
        },
        playArea: Container(
          decoration: BoxDecoration(
            gradient: isDark ? PanAfricanGradients.darkSurface : null,
            color: isDark ? null : PanAfricanColors.surfaceLight,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonLoader(
                      child: Column(
                        children: [
                          SkeletonStatCard(),
                          SizedBox(height: PanAfricanSpacing.lg),
                          SkeletonStatCard(),
                          SizedBox(height: PanAfricanSpacing.lg),
                          SkeletonListCard(),
                        ],
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    Text(
                      'Loading game...',
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: PanAfricanSpacing.md,
                right: PanAfricanSpacing.md,
                child: RiveGlobalGuide(
                  width: 80.w,
                  height: 80.h,
                  showInCorner: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return GameTemplateShell(
        title: widget.getGameType().displayName,
        languageLabel: shellLanguageLabel,
        progressLabel: shellProgressLabel,
        scoreLabel: shellScoreLabel,
        onBack: () {
          HapticFeedback.lightImpact();
          (widget.onBack ?? () => Navigator.pop(context))();
        },
        playArea: Container(
          decoration: BoxDecoration(
            gradient: isDark ? PanAfricanGradients.darkSurface : null,
            color: isDark ? null : PanAfricanColors.surfaceLight,
          ),
          child: Stack(
            children: [
              AppErrorState(
                message: _error!,
                onRetry: () {
                  HapticFeedback.lightImpact();
                  _initializeGame();
                },
              ),
              Positioned(
                top: PanAfricanSpacing.md,
                right: PanAfricanSpacing.md,
                child: RiveGlobalGuide(
                  width: 80.w,
                  height: 80.h,
                  showInCorner: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget bodyContent;
    try {
      bodyContent = buildGameContent(context);
    } catch (e, st) {
      debugPrint('buildGameContent error: $e $st');
      bodyContent = _buildGameLoadError(context, e);
    }

    return GameTemplateShell(
      title: appBarTitle ?? widget.getGameType().displayName,
      languageLabel: shellLanguageLabel,
      progressLabel: shellProgressLabel,
      scoreLabel: shellScoreLabel,
      onBack: () {
        HapticFeedback.lightImpact();
        (widget.onBack ?? () => Navigator.pop(context))();
      },
      appBarActions: appBarActions ?? const [],
      playArea: Container(
        decoration: BoxDecoration(
          gradient: isDark ? PanAfricanGradients.darkSurface : null,
          color: isDark ? null : PanAfricanColors.surfaceLight,
        ),
        child: Stack(
          children: [
            bodyContent,
            Positioned(
              top: PanAfricanSpacing.md,
              left: PanAfricanSpacing.md,
              child: _GameHud(
                isDark: isDark,
                level: gamification.level,
                xp: gamification.xp,
                streak: gamification.dailyStreak,
                showHearts: heartsState.challengeModeEnabled,
              ),
            ),
            Positioned(
              top: PanAfricanSpacing.md,
              right: PanAfricanSpacing.md,
              child: RiveGlobalGuide(
                width: 80.w,
                height: 80.h,
                showInCorner: true,
              ),
            ),
            ComboDisplayWidget(comboTracker: _comboTracker),
          ],
        ),
      ),
    );
  }

  /// Optional custom AppBar title (e.g. "Grammar Detective (1/5)").
  /// If null, [getGameType].displayName is used.
  String? get appBarTitle => null;

  /// Optional AppBar actions. Override in subclasses to add custom actions (e.g. timer, score).
  List<Widget>? get appBarActions => null;

  /// Builds fallback UI when [buildGameContent] throws.
  Widget _buildGameLoadError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48.sp, color: PanAfricanColors.kenteRed),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Game failed to load',
              style: PanAfricanTypography.titleMedium(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              'Something went wrong. Please try again.',
              style: PanAfricanTypography.bodySmall(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _initializeGame();
              },
              icon: Icon(Icons.refresh_rounded, size: 20.sp),
              label: Text('Retry', style: PanAfricanTypography.labelLarge(context, color: Theme.of(context).colorScheme.onPrimary)),
              style: FilledButton.styleFrom(
                backgroundColor: PanAfricanColors.primary,
                shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Override to build the game body content only.
  ///
  /// Return the body widget (e.g. [Padding], [Column], [ListView]).
  /// Do NOT return a [Scaffold]; [BaseGameScreen] provides the Scaffold, AppBar, and overlays.
  Widget buildGameContent(BuildContext context);
}

class _GameHud extends StatelessWidget {
  final bool isDark;
  final int level;
  final int xp;
  final int streak;
  final bool showHearts;

  const _GameHud({
    required this.isDark,
    required this.level,
    required this.xp,
    required this.streak,
    required this.showHearts,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Game stats: level $level, ${_formatCompactNumber(xp)} experience points, $streak day streak${showHearts ? ", hearts remaining" : ""}',
      child: PanAfricanCard(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.xs,
        ),
        backgroundColor: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(label: 'Level $level', child: PanAfricanBadge(
              label: 'Lv $level',
              color: PanAfricanColors.primary,
              icon: Icons.trending_up_rounded,
            )),
            SizedBox(width: PanAfricanSpacing.sm),
            Semantics(label: '${_formatCompactNumber(xp)} experience points', child: PanAfricanBadge(
              label: '${_formatCompactNumber(xp)} XP',
              color: PanAfricanColors.secondary,
              icon: Icons.star_rounded,
            )),
            SizedBox(width: PanAfricanSpacing.sm),
            Semantics(label: '$streak day streak', child: PanAfricanBadge(
              label: '$streak',
              color: PanAfricanColors.tertiary,
              icon: Icons.local_fire_department_rounded,
            )),
            if (showHearts) ...[
              SizedBox(width: PanAfricanSpacing.sm),
              Semantics(label: 'Hearts remaining', child: const HeartsWidget(compact: true)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCompactNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(1)}K';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}K';
    return value.toString();
  }
}

/// Decorative confetti-style layer for perfect score celebration.
class _ConfettiLayer extends StatelessWidget {
  final int duration;

  const _ConfettiLayer({required this.duration});

  static const List<Color> _confettiColors = [
    PanAfricanColors.primary,
    PanAfricanColors.secondary,
    PanAfricanColors.tertiary,
    PanAfricanColors.kenteRed,
    PanAfricanColors.kenteBlue,
    PanAfricanColors.ankaraPurple,
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(24, (i) {
            final colors = _confettiColors;
            final color = colors[i % colors.length];
            final left = ((i * 37) % 100) / 100.0 * size.width - 8;
            final top = ((i * 29) % 100) / 100.0 * size.height - 8;
            final dotSize = 4.0 + (i % 3) * 2.0;
            return Positioned(
              left: left.clamp(0.0, size.width - 16),
              top: top.clamp(0.0, size.height - 16),
              child: Container(
                width: dotSize.sp,
                height: dotSize.sp,
                decoration: BoxDecoration(
                  color: color,
                  shape: i % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: i % 3 != 0 ? BorderRadius.circular(1.r) : null,
                ),
              )
                  .animate(delay: Duration(milliseconds: (i * 15).clamp(0, 150)))
                  .fadeIn(duration: 250.ms)
                  .scale(begin: const Offset(0.3, 0.3), end: const Offset(1, 1), duration: 250.ms)
                  .then()
                  .shimmer(duration: 600.ms, color: color.withOpacity(0.5)),
            );
          }),
        ),
      ),
    );
  }
}

/// Animated completion overlay content card.
class _CompletionOverlayContent extends StatelessWidget {
  final GameSession session;
  final int xpEarned;
  final bool isPerfect;
  final bool isDark;
  final VoidCallback onPlayAgain;
  final VoidCallback onDone;
  final Widget Function(IconData, String, String, {bool isHighlight}) buildStatRow;

  const _CompletionOverlayContent({
    required this.session,
    required this.xpEarned,
    required this.isPerfect,
    required this.isDark,
    required this.onPlayAgain,
    required this.onDone,
    required this.buildStatRow,
  });

  @override
  Widget build(BuildContext context) {
    final titleIcon = Container(
      padding: EdgeInsets.all(PanAfricanSpacing.xs),
      decoration: BoxDecoration(
        color: isPerfect
            ? PanAfricanColors.secondary.withOpacity(0.2)
            : PanAfricanColors.primary.withOpacity(0.1),
        borderRadius: PanAfricanRadius.roundBR,
      ),
      child: Icon(
        isPerfect ? Icons.star_rounded : Icons.check_circle_rounded,
        color: isPerfect ? PanAfricanColors.secondary : PanAfricanColors.primary,
        size: 24.sp,
      ),
    );

    final titleWidget = Row(
      children: [
        isPerfect
            ? titleIcon
                .animate()
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms)
                .then()
                .shimmer(duration: 1200.ms, color: PanAfricanColors.secondary.withOpacity(0.4))
            : titleIcon,
        SizedBox(width: PanAfricanSpacing.sm),
        Expanded(
          child: Text(
            isPerfect ? 'Perfect Score!' : 'Game Complete!',
            style: PanAfricanTypography.titleLarge(context),
          ),
        ),
      ],
    );

    return Container(
      constraints: BoxConstraints(maxWidth: 360.w),
      padding: EdgeInsets.all(PanAfricanSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleWidget,
          SizedBox(height: PanAfricanSpacing.lg),
          buildStatRow(Icons.track_changes_rounded, 'Accuracy', '${(session.accuracy * 100).toStringAsFixed(0)}%'),
          buildStatRow(Icons.done_all_rounded, 'Correct', '${session.correctCount}/${session.totalTurns}'),
          buildStatRow(Icons.timer_rounded, 'Time', '${(session.durationMs / 1000).toStringAsFixed(0)}s'),
          Divider(height: PanAfricanSpacing.lg, color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
          buildStatRow(Icons.star_rounded, 'XP Earned', '+$xpEarned', isHighlight: true),
          SizedBox(height: PanAfricanSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPlayAgain,
                  icon: Icon(Icons.refresh_rounded, size: 20.sp),
                  label: Text('Try Again', style: PanAfricanTypography.labelLarge(context)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
                  ),
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDone,
                  icon: Icon(Icons.exit_to_app_rounded, size: 20.sp),
                  label: Text('Exit', style: PanAfricanTypography.labelLarge(context, color: Theme.of(context).colorScheme.onPrimary)),
                  style: FilledButton.styleFrom(
                    backgroundColor: PanAfricanColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


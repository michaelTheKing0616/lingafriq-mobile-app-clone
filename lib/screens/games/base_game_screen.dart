import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/hearts_provider.dart';
import '../../services/lazy_game_loader.dart';
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

abstract class BaseGameScreenState<T extends BaseGameScreen> extends ConsumerState<T> {
  GameSession? _session;
  DateTime? _startTime;
  bool _isLoading = true;
  String? _error;
  late final ComboTracker _comboTracker;

  GameSession? get session => _session;
  DateTime? get startTime => _startTime;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ComboTracker get comboTracker => _comboTracker;
  
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
    try {
      // Use logged-in user if available; fall back to guest ID so games
      // always work even if userProvider hasn't been populated yet.
      final user = ref.read(userProvider);
      final userId = user?.id.toString() ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

      // Optional preload — failure must never block game start
      try {
        final lazyLoader = ref.read(lazyGameLoaderProvider);
        await lazyLoader.loadGameOnDemand(widget.getGameType());
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
              'Try selecting a different language (e.g. Yoruba, Swahili).';
          _isLoading = false;
        });
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
    } catch (e) {
      setState(() {
        _error = 'Could not start game: $e';
        _isLoading = false;
      });
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
        _showCompletionDialog(endedSession, xpEarned);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finishing game: $e')),
        );
      }
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
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.lgBR),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        title: Row(
          children: [
            Container(
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
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            Expanded(
              child: Text(
                isPerfect ? 'Perfect Score!' : 'Game Complete!',
                style: PanAfricanTypography.titleLarge(context),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow(Icons.track_changes_rounded, 'Accuracy', '${(session.accuracy * 100).toStringAsFixed(0)}%'),
            _buildStatRow(Icons.done_all_rounded, 'Correct', '${session.correctCount}/${session.totalTurns}'),
            _buildStatRow(Icons.timer_rounded, 'Time', '${(session.durationMs / 1000).toStringAsFixed(0)}s'),
            Divider(height: PanAfricanSpacing.lg, color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
            _buildStatRow(Icons.star_rounded, 'XP Earned', '+$xpEarned', isHighlight: true),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            icon: Icon(Icons.check_rounded, size: 20.sp),
            label: Text('Done', style: PanAfricanTypography.labelLarge(context, color: Theme.of(context).colorScheme.onPrimary)),
            style: FilledButton.styleFrom(
              backgroundColor: PanAfricanColors.primary,
              shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
            ),
          ),
        ],
      ),
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
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.getGameType().displayName,
            style: PanAfricanTypography.titleMedium(context, color: Theme.of(context).colorScheme.onPrimary),
          ),
          leading: Semantics(
            label: 'Go back',
            button: true,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, size: 24.sp),
              onPressed: () {
                HapticFeedback.lightImpact();
                (widget.onBack ?? () => Navigator.pop(context))();
              },
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: PanAfricanGradients.forest),
          ),
          elevation: 0,
        ),
        body: Container(
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
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.getGameType().displayName,
            style: PanAfricanTypography.titleMedium(context, color: Theme.of(context).colorScheme.onPrimary),
          ),
          leading: Semantics(
            label: 'Go back',
            button: true,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, size: 24.sp),
              onPressed: () {
                HapticFeedback.lightImpact();
                (widget.onBack ?? () => Navigator.pop(context))();
              },
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: PanAfricanGradients.forest),
          ),
          elevation: 0,
        ),
        body: Container(
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle ?? widget.getGameType().displayName,
          style: PanAfricanTypography.titleMedium(context, color: Theme.of(context).colorScheme.onPrimary),
        ),
        leading: Semantics(
          label: 'Go back',
          button: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: 24.sp),
            onPressed: () {
              HapticFeedback.lightImpact();
              (widget.onBack ?? () => Navigator.pop(context))();
            },
          ),
        ),
        actions: appBarActions ?? const [],
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: PanAfricanGradients.forest),
        ),
        elevation: 0,
      ),
      body: Container(
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


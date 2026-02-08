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
import '../../services/telemetry_service.dart';
import '../../utils/gamification_integration.dart';
import '../../utils/error_handler.dart';
import '../../utils/integration_helpers.dart';
import '../../utils/pan_african_design_system.dart';
import '../../utils/performance_utils.dart';
import '../../widgets/gamification/gamification_widgets.dart';
import '../../widgets/pan_african_components.dart';
import '../../widgets/rive_global_guide.dart';
import '../../games/animation/rive_asset_loader.dart';

/// Base class for all game screens - handles common functionality
abstract class BaseGameScreen extends ConsumerStatefulWidget {
  final String language;
  final String? level;
  final VoidCallback? onBack;

  const BaseGameScreen({
    Key? key,
    required this.language,
    this.level,
    this.onBack,
  }) : super(key: key);

  GameType getGameType();
}

abstract class BaseGameScreenState<T extends BaseGameScreen> extends ConsumerState<T> {
  GameSession? _session;
  DateTime? _startTime;
  bool _isLoading = true;
  String? _error;

  GameSession? get session => _session;
  DateTime? get startTime => _startTime;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
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
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(userProvider);
      if (user == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Optimize: Preload game if not already loaded
      final lazyLoader = ref.read(lazyGameLoaderProvider);
      await lazyLoader.loadGameOnDemand(widget.getGameType());

      final gameProv = ref.read(gameProvider.notifier);
      _session = await gameProv.startGame(
        userId: user.id.toString(),
        gameType: widget.getGameType(),
        language: widget.language,
        level: widget.level,
        cardCount: getCardCount(),
      );

      _startTime = DateTime.now();
      await onGameInitialized();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
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
              final success = await GamificationIntegrationHelper.of(ref).refillHearts();
              if (success && mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Hearts refilled! Continue playing.',
                      style: PanAfricanTypography.bodyMedium(context, color: Colors.white),
                    ),
                    backgroundColor: PanAfricanColors.primary,
                  ),
                );
              }
            },
            icon: Icon(Icons.favorite_rounded, size: 20.sp),
            label: Text('Refill Hearts', style: PanAfricanTypography.labelLarge(context, color: Colors.white)),
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

      // Calculate XP based on performance
      final xpEarned = _calculateXP(endedSession);
      final wordsLearned = endedSession.correctCount;

      // Award gamification
      await GamificationIntegrationHelper.of(ref).onGameComplete(
        xpEarned: xpEarned,
        wordsLearned: wordsLearned,
        accuracy: endedSession.accuracy,
      );

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
            label: Text('Done', style: PanAfricanTypography.labelLarge(context, color: Colors.white)),
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
    final highlightColor = isHighlight ? PanAfricanColors.primary : null;
    
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
            style: PanAfricanTypography.titleMedium(context, color: Colors.white),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: 24.sp),
            onPressed: () {
              HapticFeedback.lightImpact();
              (widget.onBack ?? () => Navigator.pop(context))();
            },
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
                    CircularProgressIndicator(
                      color: PanAfricanColors.primary,
                      strokeWidth: 3,
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
            style: PanAfricanTypography.titleMedium(context, color: Colors.white),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: 24.sp),
            onPressed: () {
              HapticFeedback.lightImpact();
              (widget.onBack ?? () => Navigator.pop(context))();
            },
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
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.lg),
                      decoration: BoxDecoration(
                        color: PanAfricanColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_rounded,
                        size: 48.sp,
                        color: PanAfricanColors.error,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    Text(
                      'Something went wrong',
                      style: PanAfricanTypography.titleMedium(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xl),
                      child: Text(
                        _error!,
                        style: PanAfricanTypography.bodyMedium(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.lg),
                    FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _initializeGame();
                      },
                      icon: Icon(Icons.refresh_rounded, size: 20.sp),
                      label: Text('Try Again', style: PanAfricanTypography.labelLarge(context, color: Colors.white)),
                      style: FilledButton.styleFrom(
                        backgroundColor: PanAfricanColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.lg,
                          vertical: PanAfricanSpacing.sm,
                        ),
                      ),
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

    return Stack(
      children: [
        buildGameContent(context),
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
      ],
    );
  }

  /// Override to build the actual game UI
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
    return PanAfricanCard(
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
          PanAfricanBadge(
            label: 'Lv $level',
            color: PanAfricanColors.primary,
            icon: Icons.trending_up_rounded,
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          PanAfricanBadge(
            label: '${_formatCompactNumber(xp)} XP',
            color: PanAfricanColors.secondary,
            icon: Icons.star_rounded,
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          PanAfricanBadge(
            label: '$streak',
            color: PanAfricanColors.tertiary,
            icon: Icons.local_fire_department_rounded,
          ),
          if (showHearts) ...[
            SizedBox(width: PanAfricanSpacing.sm),
            const HeartsWidget(compact: true),
          ],
        ],
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


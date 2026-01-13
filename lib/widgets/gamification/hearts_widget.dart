import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/hearts_system_model.dart';
import '../../providers/hearts_provider.dart';
import '../../services/sound_effects_service.dart';
import '../../utils/pan_african_design_system.dart';

/// Hearts/Lives Display Widget
/// 
/// Shows current hearts with regeneration timer
/// Compact mode for app bars, full mode for dialogs
class HeartsWidget extends ConsumerStatefulWidget {
  final bool compact;
  final VoidCallback? onTap;

  const HeartsWidget({
    Key? key,
    this.compact = false,
    this.onTap,
  }) : super(key: key);

  @override
  ConsumerState<HeartsWidget> createState() => _HeartsWidgetState();
}

class _HeartsWidgetState extends ConsumerState<HeartsWidget>
    with SingleTickerProviderStateMixin {
  Timer? _regenerationTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _regenerationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _regenerationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heartsState = ref.watch(heartsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!heartsState.challengeModeEnabled) {
      return const SizedBox.shrink(); // Hidden when challenge mode is off
    }

    if (heartsState.isUnlimited) {
      return _buildUnlimitedHearts(isDark);
    }

    return widget.compact 
        ? _buildCompactView(heartsState, isDark)
        : _buildFullView(heartsState, isDark);
  }

  Widget _buildUnlimitedHearts(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.primaryGreen,
        borderRadius: PanAfricanRadius.roundBR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 18.sp),
          SizedBox(width: 4.w),
          Text(
            '∞',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(HeartsState state, bool isDark) {
    final isLow = state.currentHearts <= 2;

    return GestureDetector(
      onTap: widget.onTap ?? () => _showHeartsDialog(context, state),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = isLow ? 1.0 + (_pulseController.value * 0.1) : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isLow 
                    ? PanAfricanColors.tertiary.withOpacity(0.15)
                    : (isDark ? Colors.white.withOpacity(0.1) : PanAfricanColors.surface),
                borderRadius: PanAfricanRadius.roundBR,
                border: Border.all(
                  color: isLow ? PanAfricanColors.tertiary : Colors.transparent,
                  width: isLow ? 1.5 : 0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: isLow ? PanAfricanColors.tertiary : PanAfricanColors.tertiary.withOpacity(0.8),
                    size: 18.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${state.currentHearts}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isLow ? PanAfricanColors.tertiary : (isDark ? Colors.white : PanAfricanColors.textPrimary),
                    ),
                  ),
                  if (state.isRegenerating) ...[
                    SizedBox(width: 6.w),
                    SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: CircularProgressIndicator(
                        value: state.regenerationProgress,
                        strokeWidth: 2,
                        color: PanAfricanColors.tertiary,
                        backgroundColor: PanAfricanColors.tertiary.withOpacity(0.2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullView(HeartsState state, bool isDark) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.surfaceDark : Colors.white,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hearts row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(state.maxHearts, (index) {
              final isFilled = index < state.currentHearts;
              final isRegenerating = !isFilled && index == state.currentHearts && state.isRegenerating;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isFilled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFilled 
                          ? PanAfricanColors.tertiary 
                          : PanAfricanColors.tertiary.withOpacity(0.3),
                      size: 36.sp,
                    ),
                    if (isRegenerating)
                      SizedBox(
                        width: 36.w,
                        height: 36.w,
                        child: CircularProgressIndicator(
                          value: state.regenerationProgress,
                          strokeWidth: 3,
                          color: PanAfricanColors.tertiary,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          // Status text
          if (state.currentHearts < state.maxHearts)
            Text(
              state.isRegenerating
                  ? 'Next heart in ${state.timeUntilNextHeartFormatted}'
                  : 'Full hearts!',
              style: PanAfricanTypography.bodySmall(context).copyWith(
                color: isDark ? Colors.white70 : PanAfricanColors.textSecondary,
              ),
            ),
          if (state.currentHearts == 0)
            Padding(
              padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
              child: Text(
                'Out of hearts! Wait or refill.',
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: PanAfricanColors.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showHeartsDialog(BuildContext context, HeartsState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? PanAfricanColors.surfaceDark : Colors.white,
            borderRadius: PanAfricanRadius.xlBR,
            boxShadow: PanAfricanShadows.large,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '❤️ Hearts',
                style: PanAfricanTypography.headlineSmall(context).copyWith(
                  color: isDark ? Colors.white : PanAfricanColors.textPrimary,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              _buildFullView(state, isDark),
              SizedBox(height: PanAfricanSpacing.lg),
              // Info text
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.sm),
                decoration: BoxDecoration(
                  color: PanAfricanColors.primary.withOpacity(0.1),
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: PanAfricanColors.primary, size: 20.sp),
                    SizedBox(width: PanAfricanSpacing.xs),
                    Expanded(
                      child: Text(
                        'Hearts regenerate every 30 minutes. Use them wisely!',
                        style: PanAfricanTypography.bodySmall(context).copyWith(
                          color: isDark ? Colors.white70 : PanAfricanColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
              // Refill button
              if (state.currentHearts < state.maxHearts)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _refillHearts(context),
                    icon: Icon(Icons.monetization_on_rounded),
                    label: Text('Refill (${HeartsConfig.cowriesCostPerRefill} Cowries)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PanAfricanColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.roundBR),
                    ),
                  ),
                ),
              SizedBox(height: PanAfricanSpacing.sm),
              // Close button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refillHearts(BuildContext context) async {
    final success = await ref.read(heartsProvider.notifier).refillHearts();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough cowries!'),
          backgroundColor: PanAfricanColors.tertiary,
        ),
      );
    } else if (mounted) {
      ref.read(soundEffectsProvider).playCelebration();
      Navigator.of(context).pop();
    }
  }
}

/// Small hearts indicator for app bar
class HeartsAppBarIndicator extends ConsumerWidget {
  const HeartsAppBarIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const HeartsWidget(compact: true);
  }
}


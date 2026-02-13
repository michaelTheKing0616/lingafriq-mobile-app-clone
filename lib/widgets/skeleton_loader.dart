import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/pan_african_design_system.dart';

/// Shimmer animation for skeleton loading states.
/// Replaces spinners with content-shaped placeholders for better perceived performance.
class SkeletonLoader extends StatefulWidget {
  final Widget child;

  const SkeletonLoader({super.key, required this.child});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? PanAfricanColors.surfaceContainerDark : const Color(0xFFE8EBE8);
    final highlightColor = isDark
        ? PanAfricanColors.surfaceContainerHighDark
        : const Color(0xFFF4F6F5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// A rectangular skeleton placeholder.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double? borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : const Color(0xFFE8EBE8),
        borderRadius: BorderRadius.circular(
            borderRadius ?? PanAfricanRadius.sm),
      ),
    );
  }
}

/// A circular skeleton placeholder (for avatars).
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : const Color(0xFFE8EBE8),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A pre-composed skeleton for a typical list card (avatar + title + subtitle).
class SkeletonListCard extends StatelessWidget {
  const SkeletonListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.md,
          vertical: PanAfricanSpacing.sm,
        ),
        child: Row(
          children: [
            SkeletonCircle(size: 48.w),
            SizedBox(width: PanAfricanSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140.w, height: 14.h),
                  SizedBox(height: PanAfricanSpacing.xs),
                  SkeletonBox(width: 200.w, height: 10.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A pre-composed skeleton for a dashboard stat card.
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: PanAfricanRadius.mdBR,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 80.w, height: 12.h),
            SizedBox(height: PanAfricanSpacing.sm),
            SkeletonBox(width: 120.w, height: 24.h),
            SizedBox(height: PanAfricanSpacing.xs),
            SkeletonBox(width: 160.w, height: 10.h),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Streak indicator - shows current streak with flame animation
class StreakIndicator extends StatelessWidget {
  final int streak;
  final Color? color;

  const StreakIndicator({
    super.key,
    required this.streak,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.red.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 20.sp,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1000.ms,
                color: Colors.yellow.withOpacity(0.8),
              ),
          SizedBox(width: 1.w),
          Text(
            '$streak',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}


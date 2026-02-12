import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Momentum bar - shows learning momentum
class MomentumBar extends StatelessWidget {
  final double momentum; // 0.0 to 1.0
  final int streak;

  const MomentumBar({
    Key? key,
    required this.momentum,
    required this.streak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: Colors.blue.shade700, size: 20.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: momentum.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.purple.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: 1500.ms,
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            '${(momentum * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}


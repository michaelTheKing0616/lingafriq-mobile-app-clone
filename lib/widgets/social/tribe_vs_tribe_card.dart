import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Stunning card for Tribe vs Tribe events
class TribeVsTribeCard extends StatelessWidget {
  final String eventName;
  final List<String> participatingTribes;
  final Map<String, int> tribeScores;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback? onTap;
  final bool isActive;

  const TribeVsTribeCard({
    Key? key,
    required this.eventName,
    required this.participatingTribes,
    required this.tribeScores,
    required this.startDate,
    required this.endDate,
    this.onTap,
    this.isActive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedTribes = participatingTribes.toList()
      ..sort((a, b) => (tribeScores[b] ?? 0).compareTo(tribeScores[a] ?? 0));
    final winner = sortedTribes.isNotEmpty ? sortedTribes[0] : null;
    final daysRemaining = endDate.difference(DateTime.now()).inDays;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PanAfricanColors.primary.withOpacity(0.15),
                PanAfricanColors.secondary.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: isActive 
                  ? PanAfricanColors.primary.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          padding: EdgeInsets.all(PanAfricanSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          PanAfricanColors.primary,
                          PanAfricanColors.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      boxShadow: PanAfricanShadows.md,
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  )
                      .animate()
                      .scale(delay: 100.ms, duration: 400.ms, curve: Curves.elasticOut),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventName,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideX(begin: -0.1),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14.sp,
                              color: isActive 
                                  ? PanAfricanColors.primary
                                  : Colors.grey,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              isActive 
                                  ? '$daysRemaining days remaining'
                                  : 'Event ended',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isActive 
                                    ? PanAfricanColors.primary
                                    : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: PanAfricanColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(PanAfricanRadius.round),
                        border: Border.all(
                          color: PanAfricanColors.primary,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: PanAfricanColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .scale(delay: 400.ms, duration: 300.ms),
                ],
              ),
              SizedBox(height: 20.h),
              ...sortedTribes.take(3).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final tribe = entry.value;
                final score = tribeScores[tribe] ?? 0;
                final isWinning = index == 0;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isWinning
                        ? PanAfricanColors.secondary.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                    border: Border.all(
                      color: isWinning
                          ? PanAfricanColors.secondary
                          : Colors.grey.withOpacity(0.2),
                      width: isWinning ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isWinning
                              ? PanAfricanColors.secondary
                              : Colors.grey[300],
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: isWinning ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .scale(delay: (500 + index * 100).ms, duration: 300.ms),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tribe,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            ClipRRect(
                          borderRadius: BorderRadius.circular(PanAfricanRadius.round),
                              child: LinearProgressIndicator(
                                value: score > 0 ? (score / 10000).clamp(0.0, 1.0) : 0.0,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isWinning
                                  ? PanAfricanColors.secondary
                                  : PanAfricanColors.primary,
                                ),
                                minHeight: 6.h,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isWinning
                            ? PanAfricanColors.secondary
                            : PanAfricanColors.primary,
                        borderRadius: BorderRadius.circular(PanAfricanRadius.round),
                        ),
                        child: Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                          .animate()
                          .scale(delay: (600 + index * 100).ms, duration: 300.ms),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: (500 + index * 100).ms)
                    .slideX(begin: -0.1, delay: (500 + index * 100).ms);
              }),
              SizedBox(height: 12.h),
              if (isActive)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        PanAfricanColors.primary,
                        PanAfricanColors.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.round),
                    boxShadow: [
                      BoxShadow(
                        color: PanAfricanColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Join Your Tribe',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms)
                    .scale(delay: 800.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}


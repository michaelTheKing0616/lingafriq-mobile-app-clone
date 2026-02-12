import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Stunning card for Language Villages
class LanguageVillageCard extends StatelessWidget {
  final String villageName;
  final String language;
  final int activeUsers;
  final int maxUsers;
  final String description;
  final VoidCallback? onTap;
  final Color? accentColor;

  const LanguageVillageCard({
    Key? key,
    required this.villageName,
    required this.language,
    required this.activeUsers,
    required this.maxUsers,
    required this.description,
    this.onTap,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? PanAfricanColors.primary;
    final isFull = activeUsers >= maxUsers;
    final percentage = (activeUsers / maxUsers).clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
      ),
      child: InkWell(
        onTap: isFull ? null : onTap,
        borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PanAfricanRadius.xl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.3),
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
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 30.sp,
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
                          villageName,
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
                        Text(
                          language,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 300.ms)
                            .slideX(begin: -0.1),
                      ],
                    ),
                  ),
                  if (isFull)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(PanAfricanRadius.round),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Text(
                        'Full',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
                  .animate()
                  .fadeIn(delay: 400.ms),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Icon(
                    Icons.people_rounded,
                    size: 16.sp,
                    color: color,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$activeUsers/$maxUsers members',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (!isFull)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(PanAfricanRadius.round),
                        boxShadow: PanAfricanShadows.md,
                      ),
                      child: Text(
                        'Join',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        .animate()
                        .scale(delay: 500.ms, duration: 300.ms),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(PanAfricanRadius.round),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6.h,
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms)
                  .scaleX(begin: 0, end: 1, delay: 600.ms, duration: 500.ms),
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


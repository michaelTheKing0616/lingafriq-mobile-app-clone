import 'package:flutter/material.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Modern card widget with pan-African design elements
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool showShadow;
  final Gradient? gradient;
  final Border? border;

  const ModernCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
    this.borderRadius,
    this.showShadow = true,
    this.gradient,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cardColor = color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(20);
    final defaultElevation = elevation ?? (showShadow ? 4.0 : 0.0);

    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient == null ? cardColor : null,
        gradient: gradient,
        borderRadius: defaultBorderRadius,
        border: border,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        borderRadius: defaultBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: defaultBorderRadius,
          splashColor: AppColors.primaryGreen.withOpacity(0.1),
          highlightColor: AppColors.primaryGreen.withOpacity(0.05),
          child: cardContent,
        ),
      );
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: cardContent,
    ).animate()
        .fadeIn(duration: 300.ms, delay: 50.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: 50.ms);
  }
}

/// Language card with modern design
class LanguageCard extends StatelessWidget {
  final String name;
  final String? backgroundImage;
  final int completed;
  final int totalCount;
  final int totalScore;
  final VoidCallback? onTap;
  final bool isFeatured;

  const LanguageCard({
    Key? key,
    required this.name,
    this.backgroundImage,
    this.completed = 0,
    this.totalCount = 0,
    this.totalScore = 0,
    this.onTap,
    this.isFeatured = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final progress = totalCount > 0 ? completed / totalCount : 0.0;

    return ModernCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      showShadow: true,
      child: Stack(
        children: [
          // Background Image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: backgroundImage != null && backgroundImage!.isNotEmpty
                ? Image.network(
                    backgroundImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder(context);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildPlaceholder(context);
                    },
                  )
                : _buildPlaceholder(context),
          ),
          
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language Name
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Featured',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Progress Info
                  if (totalCount > 0) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.accentGold,
                          size: 16.sp,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completed/$totalCount lessons',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12.sp,
                          ),
                        ),
                        const Spacer(),
                        if (totalScore > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: AppColors.accentGold,
                                size: 16.sp,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$totalScore',
                                style: TextStyle(
                                  color: AppColors.accentGold,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accentGold,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ] else
                    Text(
                      'Start learning',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen,
            AppColors.accentGold,
            AppColors.accentOrange,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.language,
          color: Colors.white.withOpacity(0.5),
          size: 48,
        ),
      ),
    );
  }
}


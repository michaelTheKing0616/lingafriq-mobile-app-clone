import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
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
  final bool animate;

  const ModernCard({
    super.key,
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
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight);
    final defaultBorderRadius = borderRadius ?? PanAfricanRadius.lgBR;

    Widget cardContent = Container(
      padding: padding ?? EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: gradient == null ? cardColor : null,
        gradient: gradient,
        borderRadius: defaultBorderRadius,
        border: border ?? Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
          width: 1,
        ),
        boxShadow: showShadow ? PanAfricanShadows.sm : null,
      ),
      child: child,
    );

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        borderRadius: defaultBorderRadius,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap!();
          },
          borderRadius: defaultBorderRadius,
          splashColor: PanAfricanColors.primary.withOpacity(0.08),
          highlightColor: PanAfricanColors.primary.withOpacity(0.04),
          child: cardContent,
        ),
      );
    }

    final card = Container(
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.md,
        vertical: PanAfricanSpacing.sm,
      ),
      child: cardContent,
    );

    if (animate) {
      return card.animate()
          .fadeIn(duration: 250.ms, delay: 50.ms)
          .slideY(begin: 0.05, end: 0, duration: 250.ms, delay: 50.ms);
    }
    
    return card;
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
    super.key,
    required this.name,
    this.backgroundImage,
    this.completed = 0,
    this.totalCount = 0,
    this.totalScore = 0,
    this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? completed / totalCount : 0.0;

    return ModernCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      showShadow: true,
      border: Border.all(color: Colors.transparent),
      child: Stack(
        children: [
          // Background Image
          ClipRRect(
            borderRadius: PanAfricanRadius.lgBR,
            child: backgroundImage != null && backgroundImage!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: backgroundImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 180),
                    placeholder: (context, _) => _buildShimmerPlaceholder(context),
                    errorWidget: (context, _, __) => _buildPlaceholder(context),
                  )
                : _buildPlaceholder(context),
          ),
          
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: PanAfricanRadius.lgBR,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Theme.of(context).colorScheme.scrim.withOpacity(0.6),
                  Theme.of(context).colorScheme.scrim.withOpacity(0.85),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language Name
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: PanAfricanTypography.titleLarge(context, color: Theme.of(context).colorScheme.onPrimary).copyWith(
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
                          padding: EdgeInsets.symmetric(
                            horizontal: PanAfricanSpacing.sm,
                            vertical: PanAfricanSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: PanAfricanColors.secondary,
                            borderRadius: PanAfricanRadius.smBR,
                          ),
                          child: Text(
                            'Featured',
                            style: PanAfricanTypography.labelSmall(context, color: PanAfricanColors.neutralDarkest),
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: PanAfricanSpacing.sm),
                  
                  // Progress Info
                  if (totalCount > 0) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: PanAfricanColors.secondary,
                          size: 16.sp,
                        ),
                        SizedBox(width: PanAfricanSpacing.xxs),
                        Text(
                          '$completed/$totalCount lessons',
                          style: PanAfricanTypography.bodySmall(context, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9)),
                        ),
                        const Spacer(),
                        if (totalScore > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: PanAfricanColors.secondary,
                                size: 16.sp,
                              ),
                              SizedBox(width: PanAfricanSpacing.xxs),
                              Text(
                                '$totalScore',
                                style: PanAfricanTypography.labelMedium(context, color: PanAfricanColors.secondary),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    SizedBox(height: PanAfricanSpacing.sm),
                    
                    // Progress Bar
                    ClipRRect(
                      borderRadius: PanAfricanRadius.roundBR,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          PanAfricanColors.secondary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ] else
                    Text(
                      'Start learning',
                      style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)).copyWith(
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
      decoration: const BoxDecoration(
        gradient: PanAfricanGradients.sunset,
      ),
      child: Center(
        child: Icon(
          Icons.language_rounded,
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.4),
          size: 48.sp,
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? PanAfricanColors.neutralDark : PanAfricanColors.neutralLight;
    final highlight = isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight;
    return Shimmer.fromColors(
      baseColor: base.withOpacity(0.55),
      highlightColor: highlight.withOpacity(0.55),
      child: _buildPlaceholder(context),
    );
  }
}


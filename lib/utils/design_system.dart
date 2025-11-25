import 'package:flutter/material.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';

/// Modern Design System for LingAfriq
/// Based on Material Design 3 principles and modern UI best practices

class DesignSystem {
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 100.0;

  // Elevation/Shadows
  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLarge => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  // Gradients - Updated to match Stitch designs
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0XFFC4413A), Color(0XFFF7CB46)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryGreen, AppColors.accentGold],
  );

  // Stitch Design Gradients
  static const LinearGradient stitchPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.stitchPrimary, Color(0xFF22C55E)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.success, Color(0xFF66BB6A)],
  );

  // Card Styles
  static BoxDecoration cardDecoration(BuildContext context, {bool elevated = true}) {
    return BoxDecoration(
      color: context.isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(radiusL),
      boxShadow: elevated ? shadowMedium : null,
    );
  }

  // Modern Button Style
  static BoxDecoration buttonDecoration({
    required Color color,
    bool isOutlined = false,
  }) {
    return BoxDecoration(
      gradient: isOutlined ? null : LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withOpacity(0.8)],
      ),
      color: isOutlined ? Colors.transparent : null,
      borderRadius: BorderRadius.circular(radiusRound),
      border: isOutlined ? Border.all(color: color, width: 2) : null,
      boxShadow: isOutlined ? null : shadowSmall,
    );
  }
}

/// Modern Card Widget with enhanced styling (Stitch Design)
class ModernCardV2 extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool elevated;
  final double borderRadius;
  final bool isSelected;
  final Color? borderColor;

  const ModernCardV2({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.elevated = true,
    this.borderRadius = DesignSystem.radiusL,
    this.isSelected = false,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cardColor = color ?? (isDark ? AppColors.stitchCardDark : AppColors.stitchCardLight);
    final border = isSelected 
        ? Border.all(color: AppColors.stitchPrimary, width: 2)
        : Border.all(
            color: borderColor ?? (isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight),
            width: 2,
          );

    final card = Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.stitchPrimary.withOpacity(0.2)
            : cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: elevated ? DesignSystem.shadowSmall : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Enhanced Language Card matching Stitch design
class ModernLanguageCard extends StatelessWidget {
  final String languageName;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isFeatured;
  final bool isSelected;

  const ModernLanguageCard({
    Key? key,
    required this.languageName,
    this.imageUrl,
    required this.onTap,
    this.isFeatured = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cardColor = isSelected
        ? AppColors.stitchPrimary.withOpacity(0.2)
        : (isDark ? AppColors.stitchCardDark : AppColors.stitchCardLight);
    final borderColor = isSelected
        ? AppColors.stitchPrimary
        : (isDark ? AppColors.stitchBorderDark : AppColors.stitchBorderLight);

    return Container(
      margin: EdgeInsets.only(bottom: DesignSystem.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusM),
        boxShadow: DesignSystem.shadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignSystem.radiusM),
          child: Container(
            padding: EdgeInsets.all(DesignSystem.spacingM),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(DesignSystem.radiusM),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: Row(
              children: [
                // Language Flag/Image
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignSystem.radiusS),
                    image: imageUrl != null && imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl!),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) => null,
                          )
                        : null,
                    color: imageUrl == null || imageUrl!.isEmpty
                        ? AppColors.stitchPrimary.withOpacity(0.3)
                        : null,
                  ),
                  child: imageUrl == null || imageUrl!.isEmpty
                      ? Icon(
                          Icons.language,
                          color: AppColors.stitchPrimary,
                          size: 24,
                        )
                      : null,
                ),
                SizedBox(width: DesignSystem.spacingM),
                // Language Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.stitchTextDark : AppColors.stitchTextLight,
                        ),
                      ),
                      if (isFeatured)
                        Text(
                          'Most popular course',
                          style: TextStyle(
                            fontSize: 14,
                            color: (isDark ? AppColors.stitchTextDark : AppColors.stitchTextLight)
                                .withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ),
                // Checkmark if selected
                if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.stitchPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Section Header with modern styling
class ModernSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const ModernSectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DesignSystem.spacingM,
        vertical: DesignSystem.spacingL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.adaptive,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: DesignSystem.spacingXS),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.adaptive54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}


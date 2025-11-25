import 'package:flutter/material.dart';
import 'package:lingafriq/utils/app_colors.dart';

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

  // Gradients
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

/// Modern Card Widget with enhanced styling
class ModernCardV2 extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool elevated;
  final double borderRadius;

  const ModernCardV2({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.elevated = true,
    this.borderRadius = DesignSystem.radiusL,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? EdgeInsets.all(DesignSystem.spacingM),
      decoration: BoxDecoration(
        color: color ?? (context.isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevated ? DesignSystem.shadowMedium : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }

    return card;
  }
}

/// Enhanced Language Card with modern design
class ModernLanguageCard extends StatelessWidget {
  final String languageName;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isFeatured;

  const ModernLanguageCard({
    Key? key,
    required this.languageName,
    this.imageUrl,
    required this.onTap,
    this.isFeatured = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        boxShadow: DesignSystem.shadowMedium,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image or Gradient
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildGradientBackground(),
                  )
                else
                  _buildGradientBackground(),
                
                // Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                
                // Content
                Positioned(
                  bottom: DesignSystem.spacingM,
                  left: DesignSystem.spacingM,
                  right: DesignSystem.spacingM,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isFeatured)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignSystem.spacingS,
                            vertical: DesignSystem.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold,
                            borderRadius: BorderRadius.circular(DesignSystem.radiusS),
                          ),
                          child: Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      SizedBox(height: isFeatured ? DesignSystem.spacingS : 0),
                      Text(
                        languageName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: DesignSystem.accentGradient,
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


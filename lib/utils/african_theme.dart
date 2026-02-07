import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Pan-African Theme Colors and Design Elements
/// Inspired by African cultures, landscapes, and traditions

class AfricanTheme {
  // Pan-African Color Palette
  static const Color primaryGreen = PanAfricanColors.primary; // Legacy alias
  static const Color accentGold = PanAfricanColors.secondary;
  static const Color earthBrown = PanAfricanColors.neutralDark;
  static const Color sunsetOrange = PanAfricanColors.tertiary;
  static const Color skyBlue = PanAfricanColors.kenteBlue;
  static const Color deepRed = PanAfricanColors.kenteRed;
  static const Color vibrantPurple = PanAfricanColors.ankaraPurple;
  static const Color stitchCardDark = PanAfricanColors.cardDark;
  static const Color stitchBorderDark = PanAfricanColors.borderDark;
  
  // Background Colors
  static const Color backgroundLight = PanAfricanColors.surfaceLight;
  static const Color backgroundDark = PanAfricanColors.surfaceDark;
  
  // Text Colors
  static const Color textDark = PanAfricanColors.textPrimaryLight;
  static const Color textLight = PanAfricanColors.textPrimaryDark;
  
  // Gradients
  static const LinearGradient africanSunset = PanAfricanGradients.sunset;
  static const LinearGradient africanSavanna = PanAfricanGradients.forest;
  static const LinearGradient africanEarth = PanAfricanGradients.earth;
  static const LinearGradient africanVibrancy = PanAfricanGradients.kenteVibrant;
  
  // African Pattern Decorations
  static BoxDecoration kentePattern(Color baseColor) {
    return BoxDecoration(
      color: baseColor,
      // In a real implementation, you'd use actual Kente pattern images
      // For now, we'll use gradient patterns
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor,
          baseColor.withOpacity(0.8),
          baseColor.withOpacity(0.6),
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }
  
  // Adinkra Symbol Colors (Ghanaian symbols)
  static const List<Color> adinkraColors = [
    primaryGreen,
    accentGold,
    deepRed,
    skyBlue,
    vibrantPurple,
  ];
  
  // African-inspired shadows
  static List<BoxShadow> get africanShadow => PanAfricanShadows.lg;
  
  // Text Styles
  static Color textPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? textLight : textDark;
  }

  static Color textSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? textLight : textDark;
    return base.withOpacity(0.8);
  }

  static TextStyle headingStyle(BuildContext context) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: textPrimary(context),
      letterSpacing: -0.5,
      height: 1.2,
    );
  }
  
  static TextStyle bodyStyle(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textSecondary(context),
      height: 1.5,
    );
  }
}

/// African Pattern Widget
class AfricanPatternDecoration extends StatelessWidget {
  final Widget child;
  final Color? patternColor;
  final double opacity;
  
  const AfricanPatternDecoration({
    Key? key,
    required this.child,
    this.patternColor,
    this.opacity = 0.1,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Overlay pattern (in production, use actual pattern images)
        Positioned.fill(
          child: CustomPaint(
            painter: _AfricanPatternPainter(
              color: (patternColor ?? AfricanTheme.primaryGreen).withOpacity(opacity),
            ),
          ),
        ),
      ],
    );
  }
}

class _AfricanPatternPainter extends CustomPainter {
  final Color color;
  
  _AfricanPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Draw geometric patterns inspired by African designs
    final spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw diamond pattern
        final path = Path()
          ..moveTo(x, y + spacing / 2)
          ..lineTo(x + spacing / 2, y)
          ..lineTo(x + spacing, y + spacing / 2)
          ..lineTo(x + spacing / 2, y + spacing)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


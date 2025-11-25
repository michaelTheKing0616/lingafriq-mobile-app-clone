import 'package:flutter/material.dart';

/// Pan-African Theme Colors and Design Elements
/// Inspired by African cultures, landscapes, and traditions

class AfricanTheme {
  // Pan-African Color Palette
  static const Color primaryGreen = Color(0xFF2BEE6C); // Vibrant African green
  static const Color accentGold = Color(0xFFF7CB46); // African gold
  static const Color earthBrown = Color(0xFF8B4513); // Rich earth tone
  static const Color sunsetOrange = Color(0xFFFF6B35); // African sunset
  static const Color skyBlue = Color(0xFF1CB0F6); // African sky
  static const Color deepRed = Color(0xFFC4413A); // African red
  static const Color vibrantPurple = Color(0xFFA733EC); // African purple
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF102216);
  
  // Text Colors
  static const Color textDark = Color(0xFF0D1B12);
  static const Color textLight = Color(0xFFE0F8E7);
  
  // Gradients
  static const LinearGradient africanSunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunsetOrange, accentGold],
  );
  
  static const LinearGradient africanSavanna = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyBlue, primaryGreen],
  );
  
  static const LinearGradient africanEarth = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [earthBrown, deepRed],
  );
  
  static const LinearGradient africanVibrancy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, vibrantPurple, accentGold],
  );
  
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
  static List<BoxShadow> get africanShadow => [
    BoxShadow(
      color: primaryGreen.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
      spreadRadius: 2,
    ),
    BoxShadow(
      color: accentGold.withOpacity(0.2),
      blurRadius: 10,
      offset: const Offset(0, 5),
    ),
  ];
  
  // Text Styles
  static TextStyle headingStyle(BuildContext context) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: textDark,
      letterSpacing: -0.5,
      height: 1.2,
    );
  }
  
  static TextStyle bodyStyle(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textDark.withOpacity(0.8),
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


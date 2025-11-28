import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/loading_screen_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Dynamic loading screen with rotating African cultural content
/// Based on the design concept with:
/// - App logo
/// - Circular illustration of African person
/// - Greeting in local language
/// - Interesting fact about Africa
/// - Loading progress indicator
class DynamicLoadingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onLoadingComplete;
  final Duration? loadingDuration;

  const DynamicLoadingScreen({
    Key? key,
    this.onLoadingComplete,
    this.loadingDuration,
  }) : super(key: key);

  @override
  ConsumerState<DynamicLoadingScreen> createState() =>
      _DynamicLoadingScreenState();
}

class _DynamicLoadingScreenState
    extends ConsumerState<DynamicLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Refresh content to get a new one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loadingScreenProvider.notifier).refreshContent();
    });

    // Setup progress animation
    _progressController = AnimationController(
      duration: widget.loadingDuration ?? const Duration(seconds: 3),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    _progressAnimation.addListener(() {
      setState(() {
        _progress = _progressAnimation.value;
      });
    });

    _progressController.forward().then((_) {
      widget.onLoadingComplete?.call();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(loadingScreenProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF102216),
                          const Color(0xFF0A0A0A),
                        ]
                      : [
                          const Color(0xFF1A1A1A),
                          const Color(0xFF0A0A0A),
                        ],
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.sp),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 4.h),

                    // App Logo
                    _buildLogo(),

                    SizedBox(height: 6.h),

                    // Circular illustration of African person
                    _buildPersonIllustration(content, isDark),

                    SizedBox(height: 4.h),

                    // Greeting
                    _buildGreeting(content, isDark),

                    SizedBox(height: 2.h),

                    // Interesting fact
                    _buildFact(content, isDark),

                    SizedBox(height: 6.h),

                    // Loading indicator
                    _buildLoadingIndicator(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo icon (using a placeholder - replace with actual logo)
        Container(
          width: 48.sp,
          height: 48.sp,
          decoration: BoxDecoration(
            color: AppColors.accentGold,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.language_rounded,
            color: Colors.white,
            size: 32.sp,
          ),
        ),
        SizedBox(width: 12.sp),
        Text(
          'LingoAfrica',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonIllustration(
      LoadingScreenContent content, bool isDark) {
    return Container(
      width: 200.sp,
      height: 200.sp,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background pattern (stripes)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFD4A574), // Light brown
                    const Color(0xFF8B6F47), // Darker brown
                    const Color(0xFFD4A574),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: _StripePainter(),
              ),
            ),

            // Person image
            // Try to load from network first, fallback to asset
            content.imageUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: content.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(content),
                    errorWidget: (context, url, error) =>
                        _buildPlaceholder(content),
                  )
                : _buildPlaceholder(content),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(LoadingScreenContent content) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryGreen.withOpacity(0.3),
            AppColors.accentGold.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              content.countryFlag,
              style: TextStyle(fontSize: 64.sp),
            ),
            SizedBox(height: 8.sp),
            Text(
              content.country,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(LoadingScreenContent content, bool isDark) {
    return Column(
      children: [
        Text(
          content.greeting,
          style: TextStyle(
            fontSize: 36.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 4.sp),
        Text(
          content.greetingTranslation,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildFact(LoadingScreenContent content, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 16.sp),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.accentGold,
                size: 20.sp,
              ),
              SizedBox(width: 8.sp),
              Text(
                'Did you know?',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          Text(
            content.fact,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Column(
      children: [
        Text(
          'Getting things ready...',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 12.sp),
        Container(
          width: double.infinity,
          height: 6.sp,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: _progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentGold,
                        AppColors.primaryOrange,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for stripe pattern background
class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2;

    const spacing = 20.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/loading_screen_content.dart';
import 'package:lingafriq/providers/loading_screen_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/images.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Minimum time to show loading screen so users can read facts
/// Intelligently configured to allow users to read facts comfortably
const Duration kMinLoadingDisplayTime = Duration(seconds: 5); // Increased for better readability

/// Time between fact rotations (for longer loading operations)
const Duration kFactRotationInterval = Duration(seconds: 6);

/// Dynamic loading screen with rotating African cultural content
/// Based on the design concept with:
/// - App logo
/// - Circular illustration of African person
/// - Greeting in local language
/// - Interesting fact about Africa
/// - Loading progress indicator
/// 
/// The screen will display for at least [kMinLoadingDisplayTime] to allow
/// users to read the educational content about Africa.
class DynamicLoadingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onLoadingComplete;
  final Duration? loadingDuration;
  
  /// If true, the screen will wait for [loadingDuration] before calling onComplete
  /// If false, it will call onComplete immediately after animation starts but UI remains
  final bool waitForDuration;
  
  /// Optional message to display
  final String? message;

  const DynamicLoadingScreen({
    Key? key,
    this.onLoadingComplete,
    this.loadingDuration,
    this.waitForDuration = true,
    this.message,
  }) : super(key: key);
  
  /// Shows a loading screen for an async operation, ensuring minimum display time
  static Future<T?> showWhileLoading<T>({
    required BuildContext context,
    required Future<T> Function() asyncOperation,
    String? message,
  }) async {
    final navigator = Navigator.of(context);
    final startTime = DateTime.now();
    
    // Push loading screen
    navigator.push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: DynamicLoadingScreen(
              message: message,
              loadingDuration: kMinLoadingDisplayTime,
            ),
          );
        },
      ),
    );
    
    try {
      // Execute async operation
      final result = await asyncOperation();
      
      // Ensure minimum display time
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < kMinLoadingDisplayTime) {
        await Future.delayed(kMinLoadingDisplayTime - elapsed);
      }
      
      // Pop loading screen
      if (navigator.canPop()) {
        navigator.pop();
      }
      
      return result;
    } catch (e) {
      // Pop loading screen even on error
      if (navigator.canPop()) {
        navigator.pop();
      }
      rethrow;
    }
  }

  @override
  ConsumerState<DynamicLoadingScreen> createState() =>
      _DynamicLoadingScreenState();
}

class _DynamicLoadingScreenState
    extends ConsumerState<DynamicLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  double _progress = 0.0;
  int _factIndex = 0;
  Timer? _factTimer;
  
  // Fallback facts if backend is slow
  static const List<String> _fallbackFacts = [
    'Africa has over 2,000 distinct languages, making it the most linguistically diverse continent.',
    'The Yoruba language has three tones: high, mid, and low, which change word meanings.',
    'Swahili is spoken by over 100 million people across East Africa.',
    'Ethiopia has its own unique alphabet called Ge\'ez with 231 characters.',
    'The click consonants in Xhosa and Zulu are among the rarest sounds in human language.',
    'Ancient Egypt developed one of the world\'s first writing systems: hieroglyphics.',
    'Hausa is one of Africa\'s most widely spoken languages with 70+ million speakers.',
    'Many African proverbs teach life lessons and are passed down through generations.',
  ];

  @override
  void initState() {
    super.initState();
    
    _factIndex = Random().nextInt(_fallbackFacts.length);
    
    // Refresh content to get a new one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loadingScreenProvider.notifier).refreshContent();
    });

    // Setup progress animation - use minimum duration
    final duration = widget.loadingDuration ?? kMinLoadingDisplayTime;
    _progressController = AnimationController(
      duration: duration,
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
    
    // Pulse animation for visual interest
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController.forward().then((_) {
      if (widget.waitForDuration) {
        widget.onLoadingComplete?.call();
      }
    });
    
    // Rotate facts for longer loading times
    _factTimer = Timer.periodic(kFactRotationInterval, (_) {
      if (mounted) {
        setState(() {
          _factIndex = (_factIndex + 1) % _fallbackFacts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _factTimer?.cancel();
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
    return Image.asset(
      Images.logo,
      width: 200.sp,
      height: 80.sp,
      fit: BoxFit.contain,
    );
  }

  Widget _buildPersonIllustration(
      LoadingScreenContent content, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 180.sp,
            height: 180.sp,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentGold.withOpacity(0.8),
                  AppColors.primaryOrange.withOpacity(0.6),
                  AppColors.primaryGreen.withOpacity(0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.all(4.sp),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF102216) : const Color(0xFF0A0A0A),
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
                            const Color(0xFFD4A574).withOpacity(0.3),
                            const Color(0xFF8B6F47).withOpacity(0.3),
                            const Color(0xFFD4A574).withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: CustomPaint(
                        painter: _StripePainter(),
                      ),
                    ),

                    // Person image or placeholder
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
            ),
          ),
        );
      },
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
    // Use backend fact if available, otherwise use fallback
    final fact = content.fact.isNotEmpty 
        ? content.fact 
        : _fallbackFacts[_factIndex];
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(fact),
        margin: EdgeInsets.symmetric(horizontal: 16.sp),
        padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 16.sp),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.white.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accentGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(6.sp),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.accentGold,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 10.sp),
                Text(
                  'Did you know?',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            Text(
              fact,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.9),
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Column(
      children: [
        Text(
          widget.message ?? 'Getting things ready...',
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 16.sp),
        Container(
          width: 200.sp,
          height: 4.sp,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
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
                        AppColors.primaryGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.sp),
        Text(
          '${(_progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.accentGold.withOpacity(0.8),
            fontWeight: FontWeight.w600,
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


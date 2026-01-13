import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/loading_screen_provider.dart';
import '../models/loading_screen_content.dart';
import '../utils/app_colors.dart';
import '../utils/images.dart';

/// Minimum time to show loading screen so users can read facts
const Duration kMinLoadingDuration = Duration(seconds: 4);

/// A beautiful, reusable loading overlay with African cultural facts
/// 
/// Usage:
/// ```dart
/// // As a full screen
/// AfricanLoadingOverlay.showFullScreen(context);
/// 
/// // As an overlay while loading
/// await AfricanLoadingOverlay.wrapAsync(
///   context: context,
///   ref: ref,
///   asyncOperation: () => fetchData(),
/// );
/// ```
class AfricanLoadingOverlay extends ConsumerStatefulWidget {
  /// If true, shows as full screen. If false, shows as overlay on existing content.
  final bool isFullScreen;
  
  /// Minimum duration to show the loading screen (so users can read facts)
  final Duration minDisplayDuration;
  
  /// Callback when loading animation completes
  final VoidCallback? onComplete;
  
  /// Optional message to display
  final String? message;
  
  /// Whether to show the progress bar
  final bool showProgress;

  const AfricanLoadingOverlay({
    Key? key,
    this.isFullScreen = true,
    this.minDisplayDuration = kMinLoadingDuration,
    this.onComplete,
    this.message,
    this.showProgress = true,
  }) : super(key: key);

  /// Shows the loading overlay and executes an async operation
  /// Returns the result of the operation
  /// Ensures loading screen shows for at least [kMinLoadingDuration]
  static Future<T?> wrapAsync<T>({
    required BuildContext context,
    required WidgetRef ref,
    required Future<T> Function() asyncOperation,
    String? message,
    Duration minDuration = kMinLoadingDuration,
  }) async {
    final startTime = DateTime.now();
    
    // Show loading overlay
    final overlayEntry = OverlayEntry(
      builder: (context) => AfricanLoadingOverlay(
        isFullScreen: true,
        minDisplayDuration: minDuration,
        message: message,
      ),
    );
    
    Overlay.of(context).insert(overlayEntry);
    
    try {
      // Execute the async operation
      final result = await asyncOperation();
      
      // Ensure minimum display time
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
      
      return result;
    } finally {
      overlayEntry.remove();
    }
  }

  /// Shows a full-screen loading and returns after minDuration
  static Future<void> showForDuration({
    required BuildContext context,
    Duration duration = kMinLoadingDuration,
    String? message,
  }) async {
    final overlayEntry = OverlayEntry(
      builder: (context) => AfricanLoadingOverlay(
        isFullScreen: true,
        minDisplayDuration: duration,
        message: message,
      ),
    );
    
    Overlay.of(context).insert(overlayEntry);
    await Future.delayed(duration);
    overlayEntry.remove();
  }

  @override
  ConsumerState<AfricanLoadingOverlay> createState() => _AfricanLoadingOverlayState();
}

class _AfricanLoadingOverlayState extends ConsumerState<AfricanLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  int _currentFactIndex = 0;
  Timer? _factRotationTimer;
  
  // Pre-loaded facts about Africa for instant display
  static const List<Map<String, String>> _africanFacts = [
    {
      'fact': 'Africa has over 2,000 distinct languages, making it the most linguistically diverse continent.',
      'country': 'Africa',
      'flag': '🌍',
    },
    {
      'fact': 'The Yoruba language has three tones: high, mid, and low, which change word meanings.',
      'country': 'Nigeria',
      'flag': '🇳🇬',
    },
    {
      'fact': 'Swahili is spoken by over 100 million people across East Africa.',
      'country': 'Tanzania',
      'flag': '🇹🇿',
    },
    {
      'fact': 'Ethiopia has its own unique alphabet called Ge\'ez with 231 characters.',
      'country': 'Ethiopia',
      'flag': '🇪🇹',
    },
    {
      'fact': 'The click consonants in Xhosa and Zulu are among the rarest sounds in human language.',
      'country': 'South Africa',
      'flag': '🇿🇦',
    },
    {
      'fact': 'Ancient Egypt developed one of the world\'s first writing systems: hieroglyphics.',
      'country': 'Egypt',
      'flag': '🇪🇬',
    },
    {
      'fact': 'The Akan languages of Ghana use a system of day names based on the day you were born.',
      'country': 'Ghana',
      'flag': '🇬🇭',
    },
    {
      'fact': 'Hausa is one of Africa\'s most widely spoken languages with 70+ million speakers.',
      'country': 'Nigeria',
      'flag': '🇳🇬',
    },
    {
      'fact': 'The Amharic script runs from left to right, unlike Arabic and Hebrew.',
      'country': 'Ethiopia',
      'flag': '🇪🇹',
    },
    {
      'fact': 'Igbo has over 20 dialects, with some being mutually unintelligible.',
      'country': 'Nigeria',
      'flag': '🇳🇬',
    },
    {
      'fact': 'The Berber languages have been spoken in North Africa for over 4,000 years.',
      'country': 'Morocco',
      'flag': '🇲🇦',
    },
    {
      'fact': 'Wolof greetings in Senegal can last several minutes as a sign of respect.',
      'country': 'Senegal',
      'flag': '🇸🇳',
    },
    {
      'fact': 'Zulu has 15 noun classes, each affecting how other words in a sentence are formed.',
      'country': 'South Africa',
      'flag': '🇿🇦',
    },
    {
      'fact': 'Many African proverbs teach life lessons and are passed down through generations.',
      'country': 'Africa',
      'flag': '🌍',
    },
    {
      'fact': 'The African Union recognizes 6 official languages: Arabic, English, French, Portuguese, Spanish, and Swahili.',
      'country': 'Africa',
      'flag': '🌍',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    _currentFactIndex = Random().nextInt(_africanFacts.length);
    
    // Progress animation
    _progressController = AnimationController(
      duration: widget.minDisplayDuration,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController, 
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    
    // Pulse animation for the circle
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Start progress
    _progressController.forward().then((_) {
      widget.onComplete?.call();
    });
    
    // Rotate facts every 5 seconds if loading takes longer
    _factRotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _currentFactIndex = (_currentFactIndex + 1) % _africanFacts.length;
        });
      }
    });
    
    // Try to load from backend too
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loadingScreenProvider.notifier).refreshContent();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _factRotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backendContent = ref.watch(loadingScreenProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFact = _africanFacts[_currentFactIndex];
    
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value.clamp(0.0, 1.0),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0D2818), // Deep forest green
                    const Color(0xFF1A1A2E), // Dark blue-black
                    const Color(0xFF16213E), // Navy
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 1),
                    
                    // Logo
                    _buildLogo(),
                    
                    SizedBox(height: 32.h),
                    
                    // Animated circle with flag/content
                    _buildAnimatedCircle(currentFact, backendContent),
                    
                    SizedBox(height: 24.h),
                    
                    // Greeting (from backend if available)
                    _buildGreeting(backendContent),
                    
                    SizedBox(height: 24.h),
                    
                    // Fact card
                    _buildFactCard(currentFact, backendContent),
                    
                    const Spacer(flex: 1),
                    
                    // Loading indicator
                    if (widget.showProgress) _buildLoadingIndicator(),
                    
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Image.asset(
        Images.logo,
        width: 180.w,
        height: 60.h,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildAnimatedCircle(Map<String, String> currentFact, LoadingScreenContent backendContent) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 160.w,
            height: 160.w,
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
              margin: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A2E),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentFact['flag'] ?? '🌍',
                      style: TextStyle(fontSize: 48.sp),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      currentFact['country'] ?? 'Africa',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreeting(LoadingScreenContent backendContent) {
    final greeting = backendContent.greeting.isNotEmpty 
        ? backendContent.greeting 
        : 'Sannu'; // Default Hausa greeting
    final translation = backendContent.greetingTranslation.isNotEmpty
        ? backendContent.greetingTranslation
        : 'Hello';
    
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.accentGold,
              Colors.white,
              AppColors.accentGold,
            ],
          ).createShader(bounds),
          child: Text(
            greeting,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '"$translation"',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildFactCard(Map<String, String> currentFact, LoadingScreenContent backendContent) {
    final fact = backendContent.fact.isNotEmpty 
        ? backendContent.fact 
        : currentFact['fact'] ?? '';
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(fact),
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
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
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.accentGold,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Did you know?',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              fact,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
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

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Text(
              widget.message ?? 'Loading your experience...',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: 200.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: _progressAnimation.value,
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
            SizedBox(height: 8.h),
            Text(
              '${(_progressAnimation.value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.accentGold.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Simple wrapper for showing the loading overlay during any async operation
Future<T?> showAfricanLoading<T>({
  required BuildContext context,
  required WidgetRef ref,
  required Future<T> Function() operation,
  String? message,
}) {
  return AfricanLoadingOverlay.wrapAsync(
    context: context,
    ref: ref,
    asyncOperation: operation,
    message: message,
  );
}


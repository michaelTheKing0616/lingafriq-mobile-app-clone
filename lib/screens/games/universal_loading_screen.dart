import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';

class UniversalLoadingScreen extends ConsumerStatefulWidget {
  const UniversalLoadingScreen({
    super.key,
    this.factText,
    this.onSkip,
  });

  final String? factText;
  final VoidCallback? onSkip;

  @override
  ConsumerState<UniversalLoadingScreen> createState() =>
      _UniversalLoadingScreenState();
}

class _UniversalLoadingScreenState extends ConsumerState<UniversalLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final AnimationController _progressController;
  late final AnimationController _dotController;

  int _currentDot = 0;

  static const _defaultFacts = [
    'Yoruba has 3 tonal levels — high, mid, and low — that change word meaning entirely.',
    'Swahili is spoken by over 100 million people across East Africa.',
    'The Ge\'ez script used for Amharic has 231 characters — one of the oldest alphabets still in use.',
    'Zulu has 15 noun classes, each affecting verbs, adjectives, and pronouns.',
    'Wolof greetings can last several minutes — they\'re a form of social bonding.',
  ];

  late final String _displayedFact;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: ModernGriotColors.primary,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _displayedFact = widget.factText ??
        _defaultFacts[Random().nextInt(_defaultFacts.length)];

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _dotController.addListener(_updateDot);
  }

  void _updateDot() {
    final newDot = (_dotController.value * 3).floor().clamp(0, 2);
    if (newDot != _currentDot) setState(() => _currentDot = newDot);
  }

  @override
  void dispose() {
    _dotController.removeListener(_updateDot);
    _pulseController.dispose();
    _progressController.dispose();
    _dotController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ModernGriotColors.primary,
      body: GriotSvgPatternBackground(
        pattern: GriotPattern.kente,
        opacity: 0.03,
        color: ModernGriotColors.onPrimary,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: screenSize.height * 0.28,
              child: _PulsingGlow(pulseAnim: _pulseAnim),
            ),
            Positioned(
              top: screenSize.height * 0.28 + 40.r,
              child: Icon(
                Icons.lightbulb_rounded,
                size: 40.sp,
                color: const Color(0xFFFFC107),
              ),
            ),
            Positioned(
              top: screenSize.height * 0.48,
              child: Text(
                'LingAfriq',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: ModernGriotColors.onPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Positioned(
              bottom: screenSize.height * 0.16,
              left: 28.w,
              right: 28.w,
              child: _FactCard(fact: _displayedFact),
            ),
            Positioned(
              bottom: screenSize.height * 0.08,
              left: 40.w,
              right: 40.w,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) => _GradientProgressBar(
                  value: _progressController.value,
                ),
              ),
            ),
            Positioned(
              bottom: screenSize.height * 0.04,
              child: _LoadingDots(currentDot: _currentDot),
            ),
            if (widget.onSkip != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onSkip!();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: ModernGriotRadius.borderPill,
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: ModernGriotColors.onPrimary.withAlpha(180),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulsingGlow extends StatelessWidget {
  const _PulsingGlow({required this.pulseAnim});
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, _) {
        return SizedBox(
          width: 200.r,
          height: 200.r,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(3, (i) {
              final delay = i * 0.33;
              final t = ((pulseAnim.value + delay) % 1.0);
              final scale = 0.3 + t * 0.7;
              final opacity = (1.0 - t).clamp(0.0, 0.35);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 200.r,
                  height: 200.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ModernGriotColors.primaryContainer
                        .withAlpha((opacity * 255).round()),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.fact});
  final String fact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: ModernGriotRadius.borderXl,
      child: Container(
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: ModernGriotRadius.borderXl,
          border: Border.all(
            color: Colors.white.withAlpha(20),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16.sp,
                  color: const Color(0xFFFFC107),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Did You Know?',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: ModernGriotColors.onPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              fact,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: ModernGriotColors.onPrimary.withAlpha(200),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final barHeight = 4.h;

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(barHeight / 2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: ModernGriotGradients.signatureGradient,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.currentDot});
  final int currentDot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i == currentDot;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isActive ? 8.r : 6.r,
          height: isActive ? 8.r : 6.r,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ModernGriotColors.onPrimary
                .withAlpha(isActive ? 220 : 80),
          ),
        );
      }),
    );
  }
}

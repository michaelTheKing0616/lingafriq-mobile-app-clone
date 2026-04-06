import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ChatWelcomeScreen extends StatelessWidget {
  const ChatWelcomeScreen({
    super.key,
    required this.onBeginJourney,
    required this.onAlreadyLearner,
  });

  final VoidCallback onBeginJourney;
  final VoidCallback onAlreadyLearner;

  static const _breakpoint = 600.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernGriotColors.surface,
      body: GriotSvgPatternBackground(
        pattern: GriotPattern.triangles,
        opacity: 0.035,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= _breakpoint;
              return isWide
                  ? _WideLayout(
                      onBeginJourney: onBeginJourney,
                      onAlreadyLearner: onAlreadyLearner,
                    )
                  : _NarrowLayout(
                      onBeginJourney: onBeginJourney,
                      onAlreadyLearner: onAlreadyLearner,
                    );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wide (two-column) layout
// ---------------------------------------------------------------------------

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.onBeginJourney,
    required this.onAlreadyLearner,
  });

  final VoidCallback onBeginJourney;
  final VoidCallback onAlreadyLearner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      child: Row(
        children: [
          Expanded(
            child: _CopyColumn(
              onBeginJourney: onBeginJourney,
              onAlreadyLearner: onAlreadyLearner,
            ),
          ),
          SizedBox(width: 32.w),
          Expanded(child: _PortraitColumn()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Narrow (single-column) layout
// ---------------------------------------------------------------------------

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.onBeginJourney,
    required this.onAlreadyLearner,
  });

  final VoidCallback onBeginJourney;
  final VoidCallback onAlreadyLearner;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PortraitColumn(),
          SizedBox(height: 28.h),
          _CopyColumn(
            onBeginJourney: onBeginJourney,
            onAlreadyLearner: onAlreadyLearner,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Left column: headline, body, stats, CTAs
// ---------------------------------------------------------------------------

class _CopyColumn extends StatelessWidget {
  const _CopyColumn({
    required this.onBeginJourney,
    required this.onAlreadyLearner,
  });

  final VoidCallback onBeginJourney;
  final VoidCallback onAlreadyLearner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _headline(context),
        SizedBox(height: 16.h),
        Text(
          'Connect with your roots through the beauty of African languages. '
          'Practice with native speakers, unlock cultural stories, '
          'and join a thriving community of heritage learners.',
          style: ModernGriotTypography.bodyLarge(context: context),
        ),
        SizedBox(height: 20.h),
        _statsRow(),
        SizedBox(height: 32.h),
        SizedBox(
          width: double.infinity,
          child: GriotGradientButton(
            label: 'Begin Journey',
            icon: Icons.explore_rounded,
            onPressed: onBeginJourney,
          ),
        ),
        SizedBox(height: 12.h),
        Center(
          child: GriotTertiaryButton(
            label: 'Already a Learner? Sign In',
            onPressed: onAlreadyLearner,
          ),
        ),
      ],
    );
  }

  Widget _headline(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: ModernGriotTypography.displaySmall(context: context),
        children: [
          const TextSpan(text: 'Your Ancestry,\n'),
          TextSpan(
            text: 'Digitally Woven',
            style: ModernGriotTypography.displaySmall(
              context: context,
              color: ModernGriotColors.primary,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: const [
        GriotBadgePill(
          label: '45+ Dialects',
          icon: Icons.language_rounded,
        ),
        GriotBadgePill(
          label: '12k Members',
          icon: Icons.groups_rounded,
          color: ModernGriotColors.secondaryContainer,
          textColor: ModernGriotColors.onSecondaryContainer,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Right column: portrait + floating badges
// ---------------------------------------------------------------------------

class _PortraitColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final portraitHeight = constraints.maxWidth * 1.15;

        return SizedBox(
          height: portraitHeight.clamp(260.0, 480.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Asymmetric portrait placeholder
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFDBC9),
                        Color(0xFFFFF0EA),
                        Color(0xFFD6ED79),
                      ],
                    ),
                    boxShadow: ModernGriotShadows.lg,
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(ModernGriotRadius.xl),
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 80.sp,
                        color: ModernGriotColors.primary.withAlpha(60),
                      ),
                    ),
                  ),
                ),
              ),

              // "Griot Certified" badge — top-right with bounce
              Positioned(
                top: -8.h,
                right: 12.w,
                child: const GriotBadgePill(
                  label: 'Griot Certified',
                  icon: Icons.verified_rounded,
                  color: ModernGriotColors.primaryContainer,
                  textColor: ModernGriotColors.onPrimaryContainer,
                  bounce: true,
                ),
              ),

              // "Active Echo" glass badge — bottom-left
              Positioned(
                bottom: 16.h,
                left: -6.w,
                child: _GlassBadge(label: 'Active Echo'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Frosted glass badge (small, decorative)
// ---------------------------------------------------------------------------

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: ModernGriotRadius.borderPill,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(140),
            borderRadius: ModernGriotRadius.borderPill,
            border: Border.all(
              color: Colors.white.withAlpha(60),
            ),
            boxShadow: ModernGriotShadows.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                size: 14.sp,
                color: ModernGriotColors.secondary,
              ),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: ModernGriotColors.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

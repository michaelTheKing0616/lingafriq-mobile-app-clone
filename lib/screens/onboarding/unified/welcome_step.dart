part of '../unified_onboarding_screen.dart';

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext, required this.onHaveAccount});

  final VoidCallback onNext;
  final VoidCallback onHaveAccount;

  Widget _poliePlane(BuildContext context, double side) {
    return Semantics(
      label:
          'LingAfriq. Speak African languages with confidence. '
          'Learn with Polie. Works offline.',
      child: ExcludeSemantics(
        child: Center(
          child:
              SizedBox(
                    width: side,
                    height: side,
                    child: ClipRect(
                      child: OverflowBox(
                        maxHeight: double.infinity,
                        alignment: Alignment.topCenter,
                        child: OnboardingAvatarWidget(
                          step: OnboardingStep.welcome,
                          size: side,
                          animate: true,
                          showDialogue: false,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .scale(
                    delay: _motionDelay(context, 200.ms),
                    duration: _motionDuration(context, 600.ms),
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: _motionDuration(context, 500.ms)),
        ),
      ),
    );
  }

  List<Widget> _copyAndActions(BuildContext context) {
    return [
      // Polie's intro: greets in five home scripts on a woven mat.
      Semantics(
        label: 'Polie greets you: welcome, in Yoruba, Hausa, Igbo, '
            'Swahili and Twi.',
        child: ExcludeSemantics(
          child: Column(
            children: [
              const _WovenStrip(color: ModernGriotColors.brandCoral),
              SizedBox(height: ModernGriotSpacing.xxs.h),
              Text(
                _bidi(context, 'Ẹ kú àbọ̀ · Sannu · Nnọọ · Karibu · Akwaaba'),
                key: const ValueKey('welcome-greetings'),
                textAlign: TextAlign.center,
                style: ModernGriotTypography.titleSmall(
                  context: context,
                  color: ModernGriotColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(
        delay: _motionDelay(context, 300.ms),
        duration: _motionDuration(context, 400.ms),
      ),
      SizedBox(height: ModernGriotSpacing.xs.h),
      Text(
        _bidi(context, 'Welcome to'),
        textAlign: TextAlign.center,
        style: ModernGriotTypography.titleMedium(
          context: context,
          color: ModernGriotColors.onSurfaceVariant,
        ),
      ).animate().fadeIn(
        delay: _motionDelay(context, 400.ms),
        duration: _motionDuration(context, 300.ms),
      ),
      SizedBox(height: ModernGriotSpacing.xxs.h),
      Text(
        _bidi(context, 'LingAfriq'),
        textAlign: TextAlign.center,
        style: ModernGriotTypography.displaySmall(
          context: context,
          color: ModernGriotColors.onSurface,
        ).copyWith(height: 1.05),
      ),
      SizedBox(height: ModernGriotSpacing.xs.h),
      Text(
        _bidi(context, 'The language village that gets you speaking.'),
        textAlign: TextAlign.center,
        style: ModernGriotTypography.headlineSmall(
          context: context,
          color: ModernGriotColors.onSurface,
        ).copyWith(height: 1.25),
      ),
      SizedBox(height: ModernGriotSpacing.xxs.h),
      Text(
        _bidi(context, 'Short lessons with Polie. Hear, tap, and say real phrases.'),
        textAlign: TextAlign.center,
        style: ModernGriotTypography.bodyMedium(
          context: context,
          color: ModernGriotColors.onSurfaceVariant,
        ),
      ),
      SizedBox(height: ModernGriotSpacing.sm.h),
      Semantics(
        label: 'Works offline, about 2 megabytes per unit',
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ModernGriotSpacing.sm.w,
            vertical: ModernGriotSpacing.xxs.h,
          ),
          decoration: BoxDecoration(
            color: ModernGriotColors.surfaceContainerLowest,
            border: Border.all(color: ModernGriotColors.outline),
            borderRadius: BorderRadius.circular(ModernGriotRadius.pill),
          ),
          child: Text(
            _bidi(context, 'Works offline · about 2 MB per unit'),
            textAlign: TextAlign.center,
            style: ModernGriotTypography.labelMedium(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
        ),
      ),
      SizedBox(height: ModernGriotSpacing.md.h),
      ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: math.max(
            ModernGriotLayout.minTouchTarget.h,
            ModernGriotLayout.minTouchTarget.toDouble(),
          ),
        ),
        child: FilledButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onNext();
          },
          style: FilledButton.styleFrom(
            backgroundColor: ModernGriotColors.brandGold,
            foregroundColor: ModernGriotColors.onBrandGold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
            ),
          ),
          child: Text(
            _bidi(context, 'Get started'),
            style: ModernGriotTypography.titleMedium(
              context: context,
              color: ModernGriotColors.onBrandGold,
            ),
          ),
        ),
      ).animate().fadeIn(
        delay: _motionDelay(context, 800.ms),
        duration: _motionDuration(context, 300.ms),
      ),
      TextButton(
        onPressed: onHaveAccount,
        style: TextButton.styleFrom(
          minimumSize: const Size(
            double.infinity,
            ModernGriotLayout.minTouchTarget,
          ),
        ),
        child: Text(
          _bidi(context, 'I already have an account'),
          textAlign: TextAlign.center,
          style: ModernGriotTypography.labelLarge(
            context: context,
            color: ModernGriotColors.onSurface,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ModernGriotColors.tertiaryContainer,
            ModernGriotColors.surface,
            ModernGriotColors.surfaceContainerLow,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: ResponsiveSafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final useScroll = textScale >= 1.5;
            final polieSide = math.min(
              constraints.maxWidth - ModernGriotSpacing.lg.w * 2,
              // ~55% of the viewport at default scale; shrink when text grows.
              constraints.maxHeight * (useScroll ? 0.28 : 0.55),
            );

            if (useScroll) {
              // Large text: copy scrolls, the two actions stay pinned so
              // "Get started" is always one tap away.
              final parts = _copyAndActions(context);
              final actions = parts.sublist(parts.length - 2);
              final copy = parts.sublist(0, parts.length - 2);
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ModernGriotSpacing.lg.w,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(height: ModernGriotSpacing.xl.h),
                            SizedBox(
                              height: polieSide,
                              width: double.infinity,
                              child: _poliePlane(context, polieSide),
                            ),
                            SizedBox(height: ModernGriotSpacing.md.h),
                            ...copy,
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: ModernGriotSpacing.xs.h),
                    ...actions,
                    SizedBox(height: ModernGriotSpacing.xs.h),
                  ],
                ),
              );
            }

            // Finch/Speak composition: Polie owns the top ~55%; CTA stays on-screen.
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ModernGriotSpacing.lg.w,
              ),
              child: Column(
                children: [
                  Expanded(flex: 55, child: _poliePlane(context, polieSide)),
                  ..._copyAndActions(context),
                  SizedBox(height: ModernGriotSpacing.xs.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// 2. Language pick — Duolingo grouped rows
// =============================================================================

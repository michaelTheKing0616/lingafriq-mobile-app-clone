part of '../unified_onboarding_screen.dart';

class _FirstWinStep extends HookConsumerWidget {
  const _FirstWinStep({required this.onNext, required this.learningLanguage});

  final Function(Map<String, dynamic>) onNext;
  final String learningLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = useState(0); // 0 hear, 1 tap, 2 say, 3 celebration
    final heard = useState(false);
    final audioStatus = useState<_GreetingAudioStatus>(
      _GreetingAudioStatus.idle,
    );
    final pickedTap = useState<String?>(null);
    final saidReady = useState(false);
    // Speaking is never required: "Can't speak now" finishes the lesson
    // without the speaking XP, and is never penalised beyond that.
    final spoke = useState(false);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final copy = _lessonCopyFor(learningLanguage);
    final decoy = switch (learningLanguage) {
      'sw' => 'Jambo',
      'ha' => 'Ina kwana',
      'ig' => 'Kedu',
      'am' => 'ታደለ',
      'zu' => 'Unjani',
      _ => 'Sannu',
    };
    final tapChoices = [copy.tap, 'Hello', decoy];

    Future<void> playGreeting() async {
      if (audioStatus.value == _GreetingAudioStatus.playing) return;
      HapticFeedback.selectionClick();
      audioStatus.value = _GreetingAudioStatus.playing;
      // Widget tests have no audio pipeline — still show an honest outcome.
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        audioStatus.value = _GreetingAudioStatus.unavailable;
        heard.value = true;
        return;
      }
      var played = false;
      try {
        played = await ref
            .read(ttsProvider.notifier)
            .speak(copy.hear, languageName: copy.name.toLowerCase())
            .timeout(const Duration(seconds: 4), onTimeout: () => false);
      } catch (e) {
        logger.warn('First-win greeting TTS failed', error: e);
        played = false;
      }
      if (!context.mounted) return;
      // Honest outcome: real audio OR explicit unavailable — never silent.
      audioStatus.value = played
          ? _GreetingAudioStatus.heard
          : _GreetingAudioStatus.unavailable;
      heard.value = true;
    }

    if (phase.value >= 3) {
      final xp = _kExerciseXp * (spoke.value ? 3 : 2);
      return _StepScaffold(
        bottom: _PrimaryCta(
          label: 'Keep going',
          enabled: true,
          onPressed: () {
            onNext({
              'first_win_completed': true,
              'first_win_xp': xp,
              'first_win_words': 1,
              'first_win_spoke': spoke.value,
            });
          },
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (!reduceMotion) const _ConfettiBurst(),
            Column(
              children: [
                SizedBox(height: ModernGriotSpacing.lg.h),
                if (!reduceMotion)
                  _PolieBadge(
                        step: OnboardingStep.complete,
                        size: (ModernGriotSpacing.xl * 6).w,
                      )
                      .animate()
                      .scale(
                        duration: _motionDuration(context, 1200.ms),
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: _motionDuration(context, 400.ms))
                else
                  _PolieBadge(
                    step: OnboardingStep.complete,
                    size: (ModernGriotSpacing.xl * 6).w,
                  ),
                SizedBox(height: ModernGriotSpacing.md.h),
                Text(
                  'You did it!',
                  style: ModernGriotTypography.headlineMedium(
                    context: context,
                    color: ModernGriotColors.onSurface,
                  ),
                ),
                SizedBox(height: ModernGriotSpacing.xs.h),
                Text(
                  'Celebrate progress, not perfection.',
                  textAlign: TextAlign.center,
                  style: ModernGriotTypography.bodyLarge(
                    context: context,
                    color: ModernGriotColors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: ModernGriotSpacing.lg.h),
                Row(
                  children: [
                    const Expanded(
                      child: _StatTile(value: '1', label: 'New word'),
                    ),
                    Expanded(
                      child: _StatTile(value: '$xp', label: 'XP'),
                    ),
                    const Expanded(
                      child: _StatTile(value: '1', label: 'Lesson done'),
                    ),
                  ],
                ),
                SizedBox(height: ModernGriotSpacing.lg.h),
              ],
            ),
          ],
        ),
      );
    }

    final canAdvance = switch (phase.value) {
      0 => heard.value,
      1 => pickedTap.value == copy.tap,
      2 => saidReady.value,
      _ => false,
    };

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: phase.value == 2 ? 'Finish lesson' : 'Continue',
        enabled: canAdvance,
        onPressed: () {
          if (phase.value == 2) spoke.value = true;
          phase.value++;
          heard.value = false;
          pickedTap.value = null;
          saidReady.value = false;
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your first win',
            style: ModernGriotTypography.headlineSmall(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xxs.h),
          Text(
            'A 60-second taste of ${copy.name}. Hear, tap, say.',
            style: ModernGriotTypography.bodyMedium(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
          LinearProgressIndicator(
            value: (phase.value + 1) / 3,
            backgroundColor: ModernGriotColors.surfaceContainerHighest,
            color: ModernGriotColors.brandGold,
            minHeight: ModernGriotSpacing.xxs.h,
            borderRadius: BorderRadius.circular(ModernGriotRadius.pill),
          ),
          SizedBox(height: ModernGriotSpacing.xl.h),
          Center(
            child: _PolieBadge(
              step: OnboardingStep.story,
              size: (ModernGriotSpacing.xxl * 2 + ModernGriotSpacing.lg).w,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
          if (phase.value == 0) ...[
            Center(
              child: Text(
                'Hear: ${copy.hear}',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.headlineMedium(
                  context: context,
                  color: ModernGriotColors.onSurface,
                ),
              ),
            ),
            SizedBox(height: ModernGriotSpacing.sm.h),
            Center(
              child: Semantics(
                button: true,
                liveRegion: true,
                label: switch (audioStatus.value) {
                  _GreetingAudioStatus.heard => 'Greeting played',
                  _GreetingAudioStatus.unavailable => 'Audio unavailable',
                  _GreetingAudioStatus.playing => 'Playing greeting',
                  _GreetingAudioStatus.idle => 'Play greeting ${copy.hear}',
                },
                child: OutlinedButton.icon(
                  onPressed: audioStatus.value == _GreetingAudioStatus.playing
                      ? null
                      : playGreeting,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(
                      ModernGriotLayout.minTouchTarget * 2.5,
                      ModernGriotLayout.minTouchTarget.toDouble(),
                    ),
                    foregroundColor: ModernGriotColors.onSurface,
                    side: const BorderSide(color: ModernGriotColors.brandCoral),
                  ),
                  icon: Icon(switch (audioStatus.value) {
                    _GreetingAudioStatus.heard => Icons.check_circle_rounded,
                    _GreetingAudioStatus.unavailable =>
                      Icons.volume_off_rounded,
                    _GreetingAudioStatus.playing => Icons.graphic_eq_rounded,
                    _GreetingAudioStatus.idle => Icons.volume_up_rounded,
                  }),
                  label: Text(switch (audioStatus.value) {
                    _GreetingAudioStatus.heard => 'Heard it',
                    _GreetingAudioStatus.unavailable => 'Audio unavailable',
                    _GreetingAudioStatus.playing => 'Playing…',
                    _GreetingAudioStatus.idle => 'Play greeting',
                  }),
                ),
              ),
            ),
            if (audioStatus.value == _GreetingAudioStatus.unavailable) ...[
              SizedBox(height: ModernGriotSpacing.xs.h),
              Text(
                'We could not play sound right now. You can still continue.',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodySmall(
                  context: context,
                  color: ModernGriotColors.onSurfaceVariant,
                ),
              ),
            ],
          ] else if (phase.value == 1) ...[
            Center(
              child: Text(
                'Tap the greeting',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.headlineMedium(
                  context: context,
                  color: ModernGriotColors.onSurface,
                ),
              ),
            ),
            SizedBox(height: ModernGriotSpacing.md.h),
            for (final choice in tapChoices)
              _SelectRow(
                label: choice,
                isSelected: pickedTap.value == choice,
                onTap: () {
                  HapticFeedback.selectionClick();
                  pickedTap.value = choice;
                },
              ),
          ] else ...[
            Center(
              child: Text(
                'Say it with Polie',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.headlineMedium(
                  context: context,
                  color: ModernGriotColors.onSurface,
                ),
              ),
            ),
            SizedBox(height: ModernGriotSpacing.xs.h),
            Center(
              child: Text(
                copy.say,
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodyLarge(
                  context: context,
                  color: ModernGriotColors.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: ModernGriotSpacing.md.h),
            Center(
              child: Semantics(
                button: true,
                label: saidReady.value
                    ? 'You marked the phrase as said'
                    : 'Mark that you said ${copy.hear}',
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    saidReady.value = true;
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(
                      ModernGriotLayout.minTouchTarget * 2.5,
                      ModernGriotLayout.minTouchTarget.toDouble(),
                    ),
                    foregroundColor: ModernGriotColors.onSurface,
                    side: const BorderSide(color: ModernGriotColors.brandCoral),
                  ),
                  icon: Icon(
                    saidReady.value
                        ? Icons.check_circle_rounded
                        : Icons.mic_rounded,
                  ),
                  label: Text(
                    saidReady.value ? 'Nice, you said it' : 'I said it',
                  ),
                ),
              ),
            ),
            SizedBox(height: ModernGriotSpacing.xs.h),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: Size(
                    ModernGriotLayout.minTouchTarget * 2.5,
                    ModernGriotLayout.minTouchTarget.toDouble(),
                  ),
                  foregroundColor: ModernGriotColors.onSurfaceVariant,
                ),
                onPressed: () {
                  spoke.value = false;
                  saidReady.value = false;
                  phase.value = 3;
                },
                child: const Text("Can't speak now"),
              ),
            ),
          ],
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

/// XP per completed exercise (hear, tap, say).
const int _kExerciseXp = 5;

enum _GreetingAudioStatus { idle, playing, heard, unavailable }

class _ConfettiBurst extends StatelessWidget {
  const _ConfettiBurst();

  @override
  Widget build(BuildContext context) {
    final dots = <(double, double, Color)>[
      (0.12, 0.08, ModernGriotColors.brandGold),
      (0.28, 0.18, ModernGriotColors.brandCoral),
      (0.55, 0.06, ModernGriotColors.secondary),
      (0.72, 0.16, ModernGriotColors.brandGold),
      (0.88, 0.10, ModernGriotColors.primary),
      (0.40, 0.22, ModernGriotColors.tertiary),
    ];
    return IgnorePointer(
      child: SizedBox(
        height: ModernGriotSpacing.xxxl.h * 2,
        width: double.infinity,
        child: Stack(
          children: [
            for (var i = 0; i < dots.length; i++)
              Positioned(
                left:
                    MediaQuery.sizeOf(context).width * dots[i].$1 -
                    ModernGriotSpacing.lg.w,
                top: ModernGriotSpacing.xxl.h * dots[i].$2,
                child:
                    Container(
                          width: ModernGriotSpacing.sm.w,
                          height: ModernGriotSpacing.sm.w,
                          decoration: BoxDecoration(
                            color: dots[i].$3,
                            borderRadius: BorderRadius.circular(
                              ModernGriotRadius.xs,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 280.ms)
                        .moveY(
                          begin: -ModernGriotSpacing.md,
                          end: ModernGriotSpacing.lg.toDouble(),
                          duration: 900.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeOut(delay: 700.ms, duration: 300.ms),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ModernGriotSpacing.xxs.w),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ModernGriotSpacing.md.h,
          horizontal: ModernGriotSpacing.xs.w,
        ),
        decoration: BoxDecoration(
          color: ModernGriotColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
          border: Border.all(
            color: ModernGriotColors.outlineVariant.withValues(
              alpha: _GriotAlpha.ghostBorder,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: ModernGriotTypography.headlineMedium(
                context: context,
                color: ModernGriotColors.primary,
              ),
            ),
            SizedBox(height: ModernGriotSpacing.xxs.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: ModernGriotTypography.labelMedium(
                context: context,
                color: ModernGriotColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 6. Account + age — birth-year wheel, Ask-a-parent, distinct sign-in
// =============================================================================

part of '../unified_onboarding_screen.dart';

class _ProfileStep extends HookConsumerWidget {
  const _ProfileStep({
    required this.onboardingData,
    required this.onComplete,
    required this.onSkip,
  });

  final Map<String, dynamic> onboardingData;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final learnCode = onboardingData['learning_language'] as String?;
    final username = useState('');
    final usernameStatus = useState<_UsernameStatus>(_UsernameStatus.initial);
    final isChecking = useState(false);
    final avatarPath = useState<String?>(null);
    Timer? debounceTimer;

    useEffect(() {
      void listener() {
        final text = usernameController.text.trim();
        username.value = text;
        debounceTimer?.cancel();

        if (text.isEmpty) {
          usernameStatus.value = _UsernameStatus.initial;
          isChecking.value = false;
          return;
        }
        if (text.length < 3) {
          usernameStatus.value = _UsernameStatus.tooShort;
          return;
        }
        if (text.length > 30) {
          usernameStatus.value = _UsernameStatus.tooLong;
          return;
        }
        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(text)) {
          usernameStatus.value = _UsernameStatus.invalidFormat;
          return;
        }

        usernameStatus.value = _UsernameStatus.checking;
        isChecking.value = true;
        debounceTimer = Timer(const Duration(milliseconds: 500), () async {
          try {
            final api = ref.read(apiProvider.notifier);
            final isAvailable = await api.checkUsernameAvailability(text);
            if (context.mounted) {
              usernameStatus.value = isAvailable
                  ? _UsernameStatus.available
                  : _UsernameStatus.taken;
              isChecking.value = false;
            }
          } catch (e) {
            if (context.mounted) {
              usernameStatus.value = _UsernameStatus.error;
              isChecking.value = false;
            }
          }
        });
      }

      usernameController.addListener(listener);
      return () {
        debounceTimer?.cancel();
        usernameController.removeListener(listener);
      };
    }, []);

    Future<void> pickAvatar() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          avatarPath.value = result.files.single.path;
        }
      } catch (e) {
        logger.error('Error picking avatar', error: e);
        if (context.mounted) {
          showLingAfriqError(context, 'Failed to pick image');
        }
      }
    }

    final canComplete =
        username.value.isNotEmpty &&
        username.value.length >= 3 &&
        username.value.length <= 30 &&
        RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username.value) &&
        (usernameStatus.value == _UsernameStatus.available ||
            usernameStatus.value == _UsernameStatus.error);

    return _StepScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrimaryCta(
            label: 'Complete setup',
            enabled: canComplete,
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('username', username.value);
                if (avatarPath.value != null) {
                  await prefs.setString('avatar_path', avatarPath.value!);
                }
              } catch (e) {
                logger.error('Error saving profile', error: e);
              }
              onComplete();
            },
          ),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Skip for now',
              style: ModernGriotTypography.labelLarge(
                context: context,
                color: _captionInk,
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
        ],
      ),
      header: const _QuestionHeader(
        step: OnboardingStep.profile,
        question: 'Pick a name',
        hint: 'A learner without a name is a drum without a rhythm.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: 'Add a profile photo, optional',
            excludeSemantics: true,
            child: InkWell(
              onTap: pickAvatar,
              borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: ModernGriotLayout.minTouchTarget,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: ModernGriotSpacing.lg.r,
                      backgroundColor: ModernGriotColors.brandGold.withValues(
                        alpha: _GriotAlpha.chipSelected,
                      ),
                      backgroundImage: avatarPath.value != null
                          ? FileImage(File(avatarPath.value!))
                          : null,
                      child: avatarPath.value == null
                          ? Icon(
                              Icons.add_a_photo_rounded,
                              size: ModernGriotSpacing.md.sp,
                              color: ModernGriotColors.onSurface,
                            )
                          : null,
                    ),
                    SizedBox(width: ModernGriotSpacing.sm.w),
                    Expanded(
                      child: Text(
                        'Add a photo (optional)',
                        style: ModernGriotTypography.labelLarge(
                          context: context,
                          color: ModernGriotColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          TextField(
            controller: usernameController,
            style: ModernGriotTypography.bodyLarge(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Enter your username',
              filled: true,
              fillColor: ModernGriotColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
              ),
              suffixIcon: isChecking.value
                  ? Padding(
                      padding: EdgeInsets.all(ModernGriotSpacing.sm.w),
                      child: SizedBox(
                        width: ModernGriotSpacing.md.w,
                        height: ModernGriotSpacing.md.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _usernameIcon(usernameStatus.value),
              helperText: _usernameHelper(usernameStatus.value),
              helperMaxLines: 3,
              helperStyle: ModernGriotTypography.bodySmall(
                context: context,
                color: _captionInk,
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.sm.h),
          Text(
            _bidi(context, 'Ideas from your language'),
            style: ModernGriotTypography.labelLarge(
              context: context,
              color: _captionInk,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          Wrap(
            spacing: ModernGriotSpacing.xs.w,
            runSpacing: ModernGriotSpacing.xs.h,
            children: [
              for (final idea in _nameIdeas(learnCode))
                ActionChip(
                  label: Text(idea),
                  tooltip: 'Use the name $idea',
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  backgroundColor: ModernGriotColors.surfaceContainerLowest,
                  side: BorderSide(color: _accentFor(learnCode)),
                  labelStyle: ModernGriotTypography.labelLarge(
                    context: context,
                    color: ModernGriotColors.onSurface,
                  ),
                  onPressed: () {
                    usernameController.text = idea;
                    usernameController.selection = TextSelection.collapsed(
                      offset: idea.length,
                    );
                  },
                ),
            ],
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          _VillageCardPreview(
            name: username.value.isEmpty ? null : username.value,
            accent: _accentFor(learnCode),
            greeting: _greetings[learnCode],
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }

  /// Original name ideas: words for star, light, joy, hope in each language.
  static List<String> _nameIdeas(String? code) => switch (code) {
    'yo' => const ['Irawo_learns', 'Ayo_speaks', 'Ireti'],
    'ha' => const ['Tauraro', 'Haske_learns', 'Murna'],
    'ig' => const ['Kpakpando', 'Obi_learns', 'Nkem'],
    'sw' => const ['Nyota', 'Furaha_learns', 'Tumaini'],
    'tw' => const ['Nsoroma', 'Anigye_learns', 'Akwaaba'],
    'zu' => const ['Inkanyezi', 'Injabulo', 'Themba'],
    _ => const ['Baobab_learns', 'Griot_speaks', 'Village_star'],
  };

  Widget? _usernameIcon(_UsernameStatus status) {
    switch (status) {
      case _UsernameStatus.available:
        return const Icon(
          Icons.check_circle_rounded,
          color: ModernGriotColors.secondary,
        );
      case _UsernameStatus.taken:
        return const Icon(Icons.cancel_rounded, color: ModernGriotColors.error);
      case _UsernameStatus.tooShort:
      case _UsernameStatus.tooLong:
      case _UsernameStatus.invalidFormat:
        return const Icon(
          Icons.warning_rounded,
          color: ModernGriotColors.tertiary,
        );
      default:
        return null;
    }
  }

  String? _usernameHelper(_UsernameStatus status) {
    switch (status) {
      case _UsernameStatus.initial:
        return 'Use 3 to 30 letters, numbers, or underscores';
      case _UsernameStatus.checking:
        return 'Checking if that name is free…';
      case _UsernameStatus.available:
        return 'That name is yours';
      case _UsernameStatus.taken:
        return "Someone's already using that one, try another";
      case _UsernameStatus.tooShort:
        return 'Needs at least 3 characters';
      case _UsernameStatus.tooLong:
        return 'Keep it to 30 characters or fewer';
      case _UsernameStatus.invalidFormat:
        return 'Only letters, numbers, and underscores, please';
      case _UsernameStatus.error:
        return "We couldn't check that just now, but you can still continue";
    }
  }
}

enum _UsernameStatus {
  initial,
  checking,
  available,
  taken,
  tooShort,
  tooLong,
  invalidFormat,
  error,
}

/// How the learner will appear in the village: fills the step with a live
/// preview instead of empty space.
class _VillageCardPreview extends StatelessWidget {
  const _VillageCardPreview({
    required this.name,
    required this.accent,
    required this.greeting,
  });

  final String? name;
  final Color accent;
  final String? greeting;

  @override
  Widget build(BuildContext context) {
    final shown = name ?? 'Your name';
    return Semantics(
      container: true,
      label: 'Preview: how you appear in the village, $shown',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('village-card-preview'),
        padding: EdgeInsets.all(ModernGriotSpacing.md.w),
        decoration: BoxDecoration(
          color: ModernGriotColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: ModernGriotSpacing.lg.r,
                  backgroundColor: accent,
                  child: Text(
                    shown.characters.first.toUpperCase(),
                    style: ModernGriotTypography.titleMedium(
                      context: context,
                      color: ModernGriotColors.surfaceContainerLowest,
                    ),
                  ),
                ),
                SizedBox(width: ModernGriotSpacing.sm.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _bidi(context, shown),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ModernGriotTypography.titleMedium(
                          context: context,
                          color: ModernGriotColors.onSurface,
                        ),
                      ),
                      if (greeting != null)
                        Text(
                          greeting!,
                          style: ModernGriotTypography.bodyMedium(
                            context: context,
                            color: _captionInk,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ModernGriotSpacing.sm.h),
            _WovenStrip(color: accent),
          ],
        ),
      ),
    );
  }
}

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
            label: 'Complete Setup',
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
                color: ModernGriotColors.onSurfaceVariant,
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
                color: ModernGriotColors.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }

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
        return 'Checking if that name is free...';
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

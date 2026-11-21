part of '../unified_onboarding_screen.dart';

class _LanguagePickStep extends HookConsumerWidget {
  const _LanguagePickStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static _homeLanguages(BuildContext context) => [
    {'code': 'en', 'name': l10nOf(context).onboardingEnglish, 'script': l10nOf(context).onboardingEnglish},
    {'code': 'fr', 'name': l10nOf(context).onboardingFrench, 'script': l10nOf(context).onboardingFranAis},
    {'code': 'pt', 'name': l10nOf(context).onboardingPortuguese, 'script': l10nOf(context).onboardingPortuguS},
    {'code': 'ar', 'name': l10nOf(context).onboardingArabic, 'script': l10nOf(context).onboardingText9970},
    {'code': 'sw', 'name': l10nOf(context).onboardingSwahili, 'script': l10nOf(context).onboardingKiswahili},
  ];

  static _learnLanguages(BuildContext context) => [
    {
      'code': 'yo',
      'name': l10nOf(context).onboardingYoruba,
      'script': l10nOf(context).onboardingDYorB,
      'region': l10nOf(context).onboardingWestAfrica,
    },
    {'code': 'ha', 'name': l10nOf(context).onboardingHausa, 'script': l10nOf(context).onboardingHausa, 'region': l10nOf(context).onboardingWestAfrica},
    {
      'code': 'ig',
      'name': l10nOf(context).onboardingIgbo,
      'script': l10nOf(context).onboardingAsSIgbo,
      'region': l10nOf(context).onboardingWestAfrica,
    },
    {'code': 'tw', 'name': l10nOf(context).onboardingTwi, 'script': l10nOf(context).onboardingTwi, 'region': l10nOf(context).onboardingWestAfrica},
    {'code': 'wo', 'name': l10nOf(context).onboardingWolof, 'script': l10nOf(context).onboardingWolof, 'region': l10nOf(context).onboardingWestAfrica},
    {
      'code': 'pcm',
      'name': l10nOf(context).onboardingNigerianPidgin,
      'script': l10nOf(context).onboardingNaij,
      'region': l10nOf(context).onboardingWestAfrica,
    },
    {
      'code': 'sw',
      'name': l10nOf(context).onboardingSwahili,
      'script': l10nOf(context).onboardingKiswahili,
      'region': l10nOf(context).onboardingEastAfrica,
    },
    {
      'code': 'am',
      'name': l10nOf(context).onboardingAmharic,
      'script': l10nOf(context).onboardingText91cf,
      'region': l10nOf(context).onboardingEastAfrica,
    },
    {
      'code': 'zu',
      'name': l10nOf(context).onboardingZulu,
      'script': l10nOf(context).onboardingIsizulu,
      'region': l10nOf(context).onboardingSouthernAfrica,
    },
    {
      'code': 'xh',
      'name': l10nOf(context).onboardingXhosa,
      'script': l10nOf(context).onboardingIsixhosa,
      'region': l10nOf(context).onboardingSouthernAfrica,
    },
    {
      'code': 'ar-maghreb',
      'name': l10nOf(context).onboardingDarija,
      'script': l10nOf(context).onboardingTextd271,
      'region': l10nOf(context).onboardingNorthAfrica,
    },
    {
      'code': 'ber',
      'name': l10nOf(context).onboardingTamazight,
      'script': l10nOf(context).onboardingText526f,
      'region': l10nOf(context).onboardingNorthAfrica,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLearn = useState<String?>(null);
    // Null until the learner overrides — defaults from device locale in build.
    final selectedHomeOverride = useState<String?>(null);
    final query = useState('');
    final searchController = useTextEditingController();

    final deviceLang = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final deviceHome = _homeLanguages(context).any((h) => h['code'] == deviceLang)
        ? deviceLang
        : 'en';
    final selectedHome = selectedHomeOverride.value ?? deviceHome;

    final filtered = _learnLanguages(context).where((lang) {
      final q = query.value.trim().toLowerCase();
      if (q.isEmpty) return true;
      return (lang['name'] as String).toLowerCase().contains(q) ||
          (lang['script'] as String).toLowerCase().contains(q) ||
          (lang['region'] as String).toLowerCase().contains(q);
    }).toList();

    final regions = <String>[];
    for (final lang in filtered) {
      final r = lang['region'] as String;
      if (!regions.contains(r)) regions.add(r);
    }

    return _StepScaffold(
      bottom: _PrimaryCta(
        label: 'Continue',
        enabled: selectedLearn.value != null,
        onPressed: () async {
          try {
            await DynamicLocalizationService.setLanguage(selectedHome);
          } catch (e) {
            logger.error('Error setting language', error: e);
          }
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('proficiency_language', selectedHome);
            await prefs.setString('learning_language', selectedLearn.value!);
            scheduleGamesPreloadAfterLearningLanguageSaved(ref);
          } catch (e) {
            logger.error('Error saving languages', error: e);
          }
          onNext({
            'proficiency_language': selectedHome,
            'learning_language': selectedLearn.value,
          });
        },
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionHeader(
            question: l10nOf(context).onboardingWhatDoYouWantToLearn,
            step: OnboardingStep.languageSelection,
          ),
          if (_greetings(context)[selectedLearn.value] != null) ...[
            SizedBox(height: ModernGriotSpacing.xs.h),
            Semantics(
              liveRegion: true,
              child: Text(
                _bidi(context, _greetings(context)[selectedLearn.value]!),
                key: const ValueKey('onboarding-greeting'),
                style: ModernGriotTypography.headlineSmall(
                  context: context,
                  color: ModernGriotColors.onSurface,
                ),
              ),
            ),
            SizedBox(height: ModernGriotSpacing.xxs.h),
            _WovenStrip(color: _accentFor(selectedLearn.value)),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ModernGriotSpacing.md.h),
          Text(
            _bidi(context, l10nOf(context).onboardingISpeak),
            style: ModernGriotTypography.labelLarge(
              context: context,
              color: _captionInk,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final home in _homeLanguages(context))
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: ModernGriotSpacing.xs.w,
                    ),
                    child: FilterChip(
                      selected: selectedHome == home['code'],
                      // Endonym: people spot their own language faster.
                      label: Text(
                        _bidi(context, home['script']!),
                        semanticsLabel: home['name'],
                        style: ModernGriotTypography.labelLarge(
                          context: context,
                          color: ModernGriotColors.onSurface,
                        ),
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        selectedHomeOverride.value = home['code']!;
                      },
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.standard,
                      selectedColor: ModernGriotColors.brandGold.withValues(
                        alpha: _GriotAlpha.chipSelected,
                      ),
                      checkmarkColor: ModernGriotColors.primary,
                      labelStyle: ModernGriotTypography.labelLarge(
                        context: context,
                        color: ModernGriotColors.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: ModernGriotSpacing.sm.h),
          TextField(
            controller: searchController,
            onChanged: (v) => query.value = v,
            style: ModernGriotTypography.bodyLarge(
              context: context,
              color: ModernGriotColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: _bidi(context, l10nOf(context).onboardingSearchLanguagesea93),
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: ModernGriotColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                borderSide: BorderSide(
                  color: ModernGriotColors.outlineVariant.withValues(
                    alpha: _GriotAlpha.ghostBorder,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                borderSide: BorderSide(
                  color: ModernGriotColors.outlineVariant.withValues(
                    alpha: _GriotAlpha.ghostBorder,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: ModernGriotSpacing.md.h),
          if (filtered.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: ModernGriotSpacing.xl.h),
              child: Semantics(
                liveRegion: true,
                label: l10nOf(context).onboardingNoLanguagesMatchYourSearch,
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: ModernGriotSpacing.xl.sp,
                      color: _captionInk,
                    ),
                    SizedBox(height: ModernGriotSpacing.xs.h),
                    Text(
                      _bidi(context, l10nOf(context).onboardingNoLanguagesMatchThatSearch),
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.titleMedium(
                        context: context,
                        color: ModernGriotColors.onSurface,
                      ),
                    ),
                    SizedBox(height: ModernGriotSpacing.xxs.h),
                    Text(
                      _bidi(
                        context,
                        l10nOf(context).onboardingTryARegionAScriptName,
                      ),
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.bodyMedium(
                        context: context,
                        color: _captionInk,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final region in regions) ...[
              Text(
                _bidi(context, region),
                style: ModernGriotTypography.titleSmall(
                  context: context,
                  color: _captionInk,
                ),
              ),
              SizedBox(height: ModernGriotSpacing.xs.h),
              for (final lang in filtered.where((l) => l['region'] == region))
                _SelectRow(
                  height: ModernGriotLayout.selectRowComfortable,
                  label: lang['name'] as String,
                  subtitle: _greetings(context)[lang['code']] == null
                      ? lang['script'] as String
                      : l10nOf(context).onboardingValueValue26468('${_greetings(context)[lang['code']]}', '${lang['script']}'),
                  isSelected: selectedLearn.value == lang['code'],
                  leading: _LanguageEmblem(
                    code: lang['code'] as String,
                    size: ModernGriotLayout.minTouchTarget.w * 0.75,
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    selectedLearn.value = lang['code'] as String;
                  },
                ),
              SizedBox(height: ModernGriotSpacing.xs.h),
            ],
          SizedBox(height: ModernGriotSpacing.lg.h),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. Goal + daily time — Finch cards + Headspace clarity
// =============================================================================

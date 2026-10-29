part of '../unified_onboarding_screen.dart';

class _LanguagePickStep extends HookConsumerWidget {
  const _LanguagePickStep({required this.onNext});

  final Function(Map<String, dynamic>) onNext;

  static const _homeLanguages = [
    {'code': 'en', 'name': 'English', 'script': 'English'},
    {'code': 'fr', 'name': 'French', 'script': 'Français'},
    {'code': 'pt', 'name': 'Portuguese', 'script': 'Português'},
    {'code': 'ar', 'name': 'Arabic', 'script': 'العربية'},
    {'code': 'sw', 'name': 'Swahili', 'script': 'Kiswahili'},
  ];

  static const _learnLanguages = [
    {
      'code': 'yo',
      'name': 'Yoruba',
      'script': 'Èdè Yorùbá',
      'region': 'West Africa',
      'glyph': 'Y',
    },
    {
      'code': 'ha',
      'name': 'Hausa',
      'script': 'Hausa',
      'region': 'West Africa',
      'glyph': 'H',
    },
    {
      'code': 'ig',
      'name': 'Igbo',
      'script': 'Asụsụ Igbo',
      'region': 'West Africa',
      'glyph': 'Ị',
    },
    {
      'code': 'tw',
      'name': 'Twi',
      'script': 'Twi',
      'region': 'West Africa',
      'glyph': 'T',
    },
    {
      'code': 'wo',
      'name': 'Wolof',
      'script': 'Wolof',
      'region': 'West Africa',
      'glyph': 'W',
    },
    {
      'code': 'pcm',
      'name': 'Nigerian Pidgin',
      'script': 'Naijá',
      'region': 'West Africa',
      'glyph': 'N',
    },
    {
      'code': 'sw',
      'name': 'Swahili',
      'script': 'Kiswahili',
      'region': 'East Africa',
      'glyph': 'S',
    },
    {
      'code': 'am',
      'name': 'Amharic',
      'script': 'አማርኛ',
      'region': 'East Africa',
      'glyph': 'አ',
    },
    {
      'code': 'zu',
      'name': 'Zulu',
      'script': 'isiZulu',
      'region': 'Southern Africa',
      'glyph': 'Z',
    },
    {
      'code': 'xh',
      'name': 'Xhosa',
      'script': 'isiXhosa',
      'region': 'Southern Africa',
      'glyph': 'X',
    },
    {
      'code': 'ar-maghreb',
      'name': 'Darija',
      'script': 'الدارجة',
      'region': 'North Africa',
      'glyph': 'د',
    },
    {
      'code': 'ber',
      'name': 'Tamazight',
      'script': 'ⵜⴰⵎⴰⵣⵉⵖⵜ',
      'region': 'North Africa',
      'glyph': 'ⵣ',
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
    final deviceHome = _homeLanguages.any((h) => h['code'] == deviceLang)
        ? deviceLang
        : 'en';
    final selectedHome = selectedHomeOverride.value ?? deviceHome;

    final filtered = _learnLanguages.where((lang) {
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
          const _QuestionHeader(
            question: 'What do you want to learn?',
            step: OnboardingStep.languageSelection,
          ),
          if (_greetings[selectedLearn.value] != null) ...[
            SizedBox(height: ModernGriotSpacing.xs.h),
            Semantics(
              liveRegion: true,
              child: Text(
                _greetings[selectedLearn.value]!,
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
            _bidi(context, 'I speak'),
            style: ModernGriotTypography.labelLarge(
              context: context,
              color: ModernGriotColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ModernGriotSpacing.xs.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final home in _homeLanguages)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: ModernGriotSpacing.xs.w,
                    ),
                    child: FilterChip(
                      selected: selectedHome == home['code'],
                      // Endonym: people spot their own language faster.
                      label: Text(
                        home['script']!,
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
                      checkmarkColor: ModernGriotColors.brandCoral,
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
              hintText: _bidi(context, 'Search languages'),
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
                label: 'No languages match your search',
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: ModernGriotSpacing.xl.sp,
                      color: ModernGriotColors.onSurfaceVariant,
                    ),
                    SizedBox(height: ModernGriotSpacing.xs.h),
                    Text(
                      _bidi(context, 'No languages match that search.'),
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.titleMedium(
                        context: context,
                        color: ModernGriotColors.onSurface,
                      ),
                    ),
                    SizedBox(height: ModernGriotSpacing.xxs.h),
                    Text(
                      _bidi(context, 'Try a region, a script name, or clear the box.'),
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.bodyMedium(
                        context: context,
                        color: ModernGriotColors.onSurfaceVariant,
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
                  color: ModernGriotColors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: ModernGriotSpacing.xs.h),
              for (final lang in filtered.where((l) => l['region'] == region))
                _SelectRow(
                  height: ModernGriotLayout.selectRowComfortable,
                  label: lang['name'] as String,
                  subtitle: _greetings[lang['code']] == null
                      ? lang['script'] as String
                      : '${_greetings[lang['code']]} · ${lang['script']}',
                  isSelected: selectedLearn.value == lang['code'],
                  leading: _ScriptGlyphBadge(
                    glyph: lang['glyph'] as String,
                    accent: _accentFor(lang['code'] as String),
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

class _ScriptGlyphBadge extends StatelessWidget {
  const _ScriptGlyphBadge({required this.glyph, this.accent});

  final String glyph;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ModernGriotLayout.minTouchTarget.w * 0.75,
      height: ModernGriotLayout.minTouchTarget.w * 0.75,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(ModernGriotRadius.md),
        border: accent == null
            ? Border.all(
                color: ModernGriotColors.outlineVariant.withValues(
                  alpha: _GriotAlpha.ghostBorder,
                ),
              )
            : Border.all(color: accent!, width: 2),
      ),
      child: Text(
        glyph,
        style: ModernGriotTypography.titleMedium(
          context: context,
          color: ModernGriotColors.onSurface,
        ).copyWith(height: 1),
      ),
    );
  }
}

// =============================================================================
// 3. Goal + daily time — Finch cards + Headspace clarity
// =============================================================================

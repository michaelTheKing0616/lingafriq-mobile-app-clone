import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/tab_scaffold_provider.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class AILanguageSelectionScreen extends HookConsumerWidget {
  const AILanguageSelectionScreen({super.key});

  /// ISO-style codes for [LanguageVillagesScreen] route args and downstream APIs.
  static const _languageCodeByName = <String, String>{
    'Yoruba': 'yo',
    'Swahili': 'sw',
    'Hausa': 'ha',
    'Zulu': 'zu',
    'Amharic': 'am',
    'Twi': 'tw',
    'Igbo': 'ig',
    'Xhosa': 'xh',
    'Wolof': 'wo',
  };

  static const _proficiencyTierLabels = ['Seeker', 'Pathfinder', 'Griot'];

  static const _languages = [
    _LangData('Yoruba', '🇳🇬', 12400, ['Tonal'], Color(0xFF009639)),
    _LangData('Swahili', '🇰🇪', 18200, ['Popular'], Color(0xFF006600)),
    _LangData('Hausa', '🇳🇬', 9800, ['Tonal'], Color(0xFF009639)),
    _LangData('Zulu', '🇿🇦', 7600, ['Click'], Color(0xFF007749)),
    _LangData('Amharic', '🇪🇹', 5300, ['Script'], Color(0xFF078930)),
    _LangData('Twi', '🇬🇭', 4100, ['Tonal'], Color(0xFF006B3F)),
    _LangData('Igbo', '🇳🇬', 6700, ['Tonal'], Color(0xFF009639)),
    _LangData('Xhosa', '🇿🇦', 3200, ['Click'], Color(0xFF007749)),
    _LangData('Wolof', '🇸🇳', 2800, ['Oral'], Color(0xFF00853F)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ValueNotifier<int>(-1);
    final proficiency = ValueNotifier<int>(0);

    return GriotScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(
                  Navigator.of(context).canPop()
                      ? Icons.arrow_back_rounded
                      : Icons.menu_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: Navigator.of(context).canPop() ? 'Back' : 'Menu',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  } else {
                    ref.read(scaffoldKeyProvider).currentState?.openDrawer();
                  }
                },
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: ModernGriotTypography.headlineLarge(),
                  children: [
                    const TextSpan(text: 'Choose '),
                    TextSpan(
                      text: 'your tongue',
                      style: ModernGriotTypography.headlineLarge(
                        color: ModernGriotColors.primary,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Select a language to begin your journey',
              style: ModernGriotTypography.bodyMedium(),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: selected,
                builder: (context, sel, _) {
                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _languages.length,
                    itemBuilder: (context, i) {
                      final lang = _languages[i];
                      final isSelected = sel == i;
                      return _LanguageCard(
                        data: lang,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          selected.value = i;
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: proficiency,
                    builder: (context, prof, _) {
                      return _ProficiencySelector(
                        selected: prof,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          proficiency.value = v;
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: GriotGradientButton(
                      label: 'ENTER THE VILLAGE',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () async {
                        final idx = selected.value;
                        if (idx < 0 || idx >= _languages.length) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Choose a language to enter the village.',
                                style: ModernGriotTypography.bodyMedium(),
                              ),
                            ),
                          );
                          return;
                        }
                        final lang = _languages[idx];
                        final code = _languageCodeByName[lang.name] ??
                            lang.name.toLowerCase().replaceAll(' ', '_');
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          'ai_village_entry_language',
                          lang.name,
                        );
                        await prefs.setString(
                          'ai_village_entry_language_code',
                          code,
                        );
                        await prefs.setInt(
                          'ai_village_proficiency_index',
                          proficiency.value.clamp(0, 2),
                        );
                        await prefs.setString(
                          'ai_village_proficiency_label',
                          _proficiencyTierLabels[
                              proficiency.value.clamp(0, 2)],
                        );
                        if (!context.mounted) return;
                        await Navigator.of(context).pushNamed(
                          'language-village',
                          arguments: <String, String>{
                            'languageDisplayName': lang.name,
                            'languageCode': code,
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 12.h),
                  GriotBadgePill(
                    label: 'Pro Tip: Start with greetings!',
                    icon: Icons.lightbulb_rounded,
                    bounce: true,
                    color: ModernGriotColors.secondaryContainer,
                    textColor: ModernGriotColors.onSecondaryContainer,
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangData {
  const _LangData(
      this.name, this.flag, this.learners, this.tags, this.accent);
  final String name;
  final String flag;
  final int learners;
  final List<String> tags;
  final Color accent;
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });
  final _LangData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: ModernGriotRadius.borderXl,
          border: Border.all(
            color: isSelected ? cs.primary : Colors.transparent,
            width: isSelected ? 2.5 : 0,
          ),
          boxShadow: isSelected
              ? ModernGriotShadows.glow(cs.primary)
              : ModernGriotShadows.sm,
        ),
        child: Column(
          children: [
            Container(
              height: 6.h,
              decoration: BoxDecoration(
                color: data.accent,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ModernGriotRadius.xl),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data.flag, style: TextStyle(fontSize: 28.sp)),
                    SizedBox(height: 6.h),
                    Text(
                      data.name,
                      style: ModernGriotTypography.titleSmall(),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${_formatCount(data.learners)} learners',
                      style: ModernGriotTypography.labelSmall(),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 4.w,
                      children: data.tags
                          .map((t) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cs.primary.withAlpha(20)
                                      : cs.surfaceContainerHighest,
                                  borderRadius: ModernGriotRadius.borderPill,
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _ProficiencySelector extends StatelessWidget {
  const _ProficiencySelector({
    required this.selected,
    required this.onChanged,
  });
  final int selected;
  final ValueChanged<int> onChanged;

  static const _levels = [
    ('Seeker', 'Beginner', Icons.explore_rounded),
    ('Pathfinder', 'Intermediate', Icons.map_rounded),
    ('Griot', 'Advanced', Icons.auto_awesome_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(_levels.length, (i) {
        final isActive = selected == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: isActive ? cs.primary : cs.surfaceContainerLow,
                borderRadius: ModernGriotRadius.borderPill,
                boxShadow: isActive ? ModernGriotShadows.sm : null,
              ),
              child: Column(
                children: [
                  Icon(
                    _levels[i].$3,
                    size: 16.sp,
                    color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _levels[i].$1,
                    style: ModernGriotTypography.labelMedium(
                      color: isActive ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                  Text(
                    _levels[i].$2,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: isActive
                          ? cs.onPrimary.withAlpha(180)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

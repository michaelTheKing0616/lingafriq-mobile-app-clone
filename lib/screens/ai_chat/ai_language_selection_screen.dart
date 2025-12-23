import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart' show DynamicLocalizationService, AppLanguage;
import 'ai_mode_selection_screen.dart';

/// Beautiful Material 3 Language Selection Screen
class AILanguageSelectionScreen extends HookConsumerWidget {
  const AILanguageSelectionScreen({Key? key}) : super(key: key);

  // Language data with flags - using AppLanguage enum
  List<Map<String, String>> get languages {
    final flagMap = {
      'yoruba': '🇳🇬',
      'hausa': '🇳🇬',
      'igbo': '🇳🇬',
      'swahili': '🇰🇪',
      'zulu': '🇿🇦',
      'xhosa': '🇿🇦',
      'amharic': '🇪🇹',
      'twi': '🇬🇭',
      'afrikaans': '🇿🇦',
      'nigerian_pidgin': '🇳🇬',
      'pidgin': '🇳🇬',
      'wolof': '🇸🇳',
      'somali': '🇸🇴',
    };
    
    return AppLanguage.values.map((lang) {
      final name = lang.name.replaceAll('_', ' ');
      final capitalizedName = name.split(' ').map((word) => 
        word[0].toUpperCase() + word.substring(1)
      ).join(' ');
      
      return {
        'code': lang.name,
        'name': capitalizedName,
        'flag': flagMap[lang.name] ?? '🌍',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = useState<String?>(null);
    final isLoading = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Loading...',
      child: Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      'Choose Your Language',
                      style: PanAfricanTypography.displayMedium(context)
                          .copyWith(color: Colors.white),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(
                      'Select the language you want to practice',
                      style: PanAfricanTypography.bodyMedium(context)
                          .copyWith(color: Colors.white70),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                  ],
                ),
              ),

              // Language Grid
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? PanAfricanColors.surfaceDark
                        : PanAfricanColors.surfaceLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(PanAfricanRadius.xl),
                    ),
                  ),
                  child: GridView.builder(
                    padding: EdgeInsets.all(PanAfricanSpacing.lg),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: PanAfricanSpacing.md,
                      mainAxisSpacing: PanAfricanSpacing.md,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final lang = languages[index];
                      final isSelected = selectedLanguage.value == lang['code'];

                      return _LanguageCard(
                        language: lang,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () {
                          selectedLanguage.value = lang['code'];
                          HapticFeedback.mediumImpact();
                          Future.delayed(Duration(milliseconds: 300), () {
                            Navigator.push(
                              context,
                              SmoothPageRoute(
                                child: AIModeSelectionScreen(
                                  language: lang['code']!,
                                  languageName: lang['name']!,
                                ),
                              ),
                            );
                          });
                        },
                      )
                          .animate(delay: (index * 50).ms)
                          .fadeIn(duration: 300.ms)
                          .scale(begin: Offset(0.8, 0.8), end: Offset(1, 1));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final Map<String, String> language;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? PanAfricanGradients.sunset
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark
                        ? PanAfricanColors.cardDark
                        : PanAfricanColors.cardLight,
                    isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ],
                ),
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          boxShadow: isSelected ? PanAfricanShadows.glowGold(0.3) : PanAfricanShadows.md,
          border: Border.all(
            color: isSelected
                ? PanAfricanColors.secondary
                : PanAfricanColors.borderLight.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              language['flag'] ?? '🌍',
              style: TextStyle(fontSize: 48.sp),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              language['name'] ?? '',
              style: PanAfricanTypography.titleMedium(context).copyWith(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              SizedBox(height: PanAfricanSpacing.xs),
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24.sp,
              ),
            ],
          ],
        ),
      ),
    );
  }
}


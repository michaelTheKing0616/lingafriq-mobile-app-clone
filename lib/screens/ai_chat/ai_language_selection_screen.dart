import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart'
    show DynamicLocalizationService, AppLanguage;
import 'package:lingafriq/services/sound_effects_service.dart';
import 'ai_mode_selection_screen.dart';

/// AI Chat — Screen 1: Choose Your Language
/// Full-screen globe abstraction with floating language orbs and color auras.
class AILanguageSelectionScreen extends HookConsumerWidget {
  const AILanguageSelectionScreen({Key? key}) : super(key: key);

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
      final capitalizedName = name
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
      return {
        'code': lang.name,
        'name': capitalizedName,
        'flag': flagMap[lang.name] ?? '🌍',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final soundEffects = ref.watch(soundEffectsProvider);

    final bodyContent = SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(PolieSpacing.lg),
            child: Column(
              children: [
                Text(
                  'Choose Your Language',
                  style: PolieTypography.h1(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                SizedBox(height: PolieSpacing.sm),
                Text(
                  'Tap a language to begin • Long-press for dialects',
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
              ],
            ),
          ),
          Expanded(
            child: languages.isEmpty
                ? _buildEmptyState(context, isDark)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return _OrbGrid(
                        languages: languages,
                        isDark: isDark,
                        onTap: (lang) {
                          HapticFeedback.mediumImpact();
                          soundEffects.play(SoundEffect.buttonTap);
                          Navigator.push(
                            context,
                            SmoothPageRoute(
                              child: AIModeSelectionScreen(
                                language: lang['code']!,
                                languageName: lang['name']!,
                              ),
                            ),
                          );
                        },
                        onLongPress: (lang) => _showDialectsBottomSheet(
                          context,
                          lang['name']!,
                          lang['code']!,
                          isDark,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Loading...',
      child: Scaffold(
        backgroundColor: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        body: bodyContent,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PolieSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.language_rounded,
              size: 64,
              color: PolieColors.primary.withOpacity(0.5),
            ),
            SizedBox(height: PolieSpacing.md),
            Text(
              'No languages available',
              style: PolieTypography.h2(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PolieSpacing.xs),
            Text(
              'Language options will appear here when configured.',
              style: PolieTypography.body(context).copyWith(
                color: PolieColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDialectsBottomSheet(
    BuildContext context,
    String languageName,
    String code,
    bool isDark,
  ) {
    HapticFeedback.mediumImpact();
    final dialects = _getDialectsForLanguage(code);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(PolieSpacing.lg),
        decoration: BoxDecoration(
          color: isDark
              ? PolieColors.surfaceGlassDark
              : PolieColors.surfaceGlass,
          borderRadius: BorderRadius.vertical(top: Radius.circular(PolieRadius.xl)),
          border: Border.all(
            color: PolieColors.royalAmethyst.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$languageName — Dialects & variants',
              style: PolieTypography.h2(context),
            ),
            SizedBox(height: PolieSpacing.md),
            ...dialects.map(
              (d) => ListTile(
                title: Text(d, style: PolieTypography.body(context)),
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getDialectsForLanguage(String code) {
    switch (code.toLowerCase()) {
      case 'yoruba':
        return ['Standard Yorùbá', 'Ìgbómìnà', 'Ìjẹ̀bú', 'Èkìtì', 'Òǹdó'];
      case 'hausa':
        return ['Standard Hausa', 'Kano', 'Sokoto', 'Daura'];
      case 'igbo':
        return ['Standard Igbo', 'Central Igbo', 'Nigerian Igbo'];
      case 'swahili':
        return ['Kiswahili sanifu', 'Kiangazi', 'Kimvita', 'Kiunguja'];
      case 'pidgin':
      case 'nigerian_pidgin':
        return ['Nigerian Pidgin', 'Wes Kos', 'Benín'];
      default:
        return ['Standard variety', 'Regional variants'];
    }
  }
}

/// Floating orbs with color aura; positions use simple grid with slight randomness for organic feel.
class _OrbGrid extends StatelessWidget {
  final List<Map<String, String>> languages;
  final bool isDark;
  final void Function(Map<String, String> lang) onTap;
  final void Function(Map<String, String> lang) onLongPress;

  const _OrbGrid({
    required this.languages,
    required this.isDark,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: PolieSpacing.md),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: PolieSpacing.lg,
        runSpacing: PolieSpacing.lg,
        children: List.generate(languages.length, (index) {
          final lang = languages[index];
          final code = lang['code'] ?? '';
          final accent = polieAccentForLanguage(code);
          final delay = (index * 60).ms;
          return _LanguageOrb(
            name: lang['name']!,
            flag: lang['flag']!,
            accentColor: accent,
            isDark: isDark,
            onTap: () => onTap(lang),
            onLongPress: () => onLongPress(lang),
          )
              .animate(delay: delay)
              .fadeIn(duration: 350.ms)
              .scale(begin: Offset(0.6, 0.6), end: Offset(1, 1), curve: Curves.easeOut);
        }),
      ),
    );
  }
}

class _LanguageOrb extends StatelessWidget {
  final String name;
  final String flag;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _LanguageOrb({
    required this.name,
    required this.flag,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight;
    final borderColor = isDark
        ? PolieColors.royalAmethyst.withOpacity(0.2)
        : accentColor.withOpacity(0.25);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        child: Container(
          width: 100.w,
          height: 110.h,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(PolieRadius.lg),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: TextStyle(fontSize: 32.sp)),
              SizedBox(height: PolieSpacing.xs),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PolieSpacing.xs),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PolieTypography.label(context).copyWith(
                    color: isDark
                        ? PolieColors.textPrimary
                        : PolieColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

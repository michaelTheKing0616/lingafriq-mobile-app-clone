import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/error_handler.dart';
import '../../utils/integration_helpers.dart';
import '../../utils/performance_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/widgets/standard_app_bar.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer_material3.dart';
import 'tutor_translation_mode_screen.dart';
import 'tutor_grammar_mode_screen.dart';
import 'tutor_pronunciation_mode_screen.dart';
import 'tutor_story_mode_screen.dart';
import 'tutor_dialogue_mode_screen.dart';
import 'tutor_assess_mode_screen.dart';

/// Beautiful Material 3 Tutor Dashboard with 6 Mode Tabs
class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<TutorMode> _modes = [
    TutorMode(
      id: 'translate',
      title: 'Translation',
      description: 'Translate text with grammar notes',
      icon: Icons.translate,
      color: PanAfricanColors.kenteBlue,
      screen: const TutorTranslationModeScreen(),
    ),
    TutorMode(
      id: 'explain',
      title: 'Grammar',
      description: 'Learn grammar rules and examples',
      icon: Icons.menu_book,
      color: PanAfricanColors.primary,
      screen: const TutorGrammarModeScreen(),
    ),
    TutorMode(
      id: 'pronunciation',
      title: 'Pronunciation',
      description: 'Perfect your pronunciation',
      icon: Icons.record_voice_over,
      color: PanAfricanColors.tertiary,
      screen: const TutorPronunciationModeScreen(),
    ),
    TutorMode(
      id: 'story',
      title: 'Stories',
      description: 'Cultural stories with vocabulary',
      icon: Icons.auto_stories,
      color: PanAfricanColors.kenteRed,
      screen: const TutorStoryModeScreen(),
    ),
    TutorMode(
      id: 'dialogue',
      title: 'Dialogue',
      description: 'Practice conversations',
      icon: Icons.chat_bubble_outline,
      color: PanAfricanColors.kitengeTeal,
      screen: const TutorDialogueModeScreen(),
    ),
    TutorMode(
      id: 'assess',
      title: 'Assessment',
      description: 'Test your proficiency',
      icon: Icons.assessment,
      color: PanAfricanColors.secondary,
      screen: const TutorAssessModeScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _modes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Polie Tutor',
        showBackButton: true,
        showDrawerButton: true,
      ),
      drawer: const AppDrawerMaterial3(),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header (kept for rich intro copy)
              _buildHeader(context, isDark),
              
              // Mode Cards Grid (for quick access)
              _buildModeCards(context, isDark),
              
              // Tab Bar
              _buildTabBar(context, isDark),
              
              // Tab Views (with consistent padding)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.md,
                    vertical: PanAfricanSpacing.sm,
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: _modes.map((mode) => mode.screen).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Polie Tutor',
            style: PanAfricanTypography.displayMedium(context),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
          SizedBox(height: PanAfricanSpacing.xs),
          Text(
            'Your AI language learning companion',
            style: PanAfricanTypography.bodyMedium(context),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
        ],
      ),
    );
  }

  Widget _buildModeCards(BuildContext context, bool isDark) {
    return Container(
      height: 140.h,
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _modes.length,
        itemBuilder: (context, index) {
          final mode = _modes[index];
          return _ModeCard(
            mode: mode,
            isDark: isDark,
            onTap: () {
              _tabController.animateTo(index);
              HapticFeedback.mediumImpact();
            },
          )
              .animate(delay: (index * 100).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.2);
        },
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PanAfricanRadius.lg),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: PanAfricanColors.primary,
        labelColor: PanAfricanColors.primary,
        unselectedLabelColor: isDark
            ? PanAfricanColors.textSecondaryDark
            : PanAfricanColors.textSecondaryLight,
        tabs: _modes.map((mode) {
          return Tab(
            icon: Icon(mode.icon),
            text: mode.title,
          );
        }).toList(),
      ),
    );
  }
}

class TutorMode {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget screen;

  TutorMode({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class _ModeCard extends StatelessWidget {
  final TutorMode mode;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120.w,
        margin: EdgeInsets.only(right: PanAfricanSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          boxShadow: PanAfricanShadows.md,
          border: Border.all(
            color: mode.color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: mode.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                mode.icon,
                color: mode.color,
                size: 32.sp,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              mode.title,
              style: PanAfricanTypography.titleSmall(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.xxs),
            Text(
              mode.description,
              style: PanAfricanTypography.bodySmall(context),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


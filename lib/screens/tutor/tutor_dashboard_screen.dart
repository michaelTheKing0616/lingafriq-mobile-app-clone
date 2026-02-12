import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/error_handler.dart';
import '../../utils/integration_helpers.dart';
import '../../utils/performance_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
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
      color: PolieColors.electricTeal,
      screen: const TutorTranslationModeScreen(),
    ),
    TutorMode(
      id: 'explain',
      title: 'Grammar',
      description: 'Learn grammar rules and examples',
      icon: Icons.menu_book,
      color: PolieColors.royalAmethyst,
      screen: const TutorGrammarModeScreen(),
    ),
    TutorMode(
      id: 'pronunciation',
      title: 'Pronunciation',
      description: 'Perfect your pronunciation',
      icon: Icons.record_voice_over,
      color: PolieColors.goldEmber,
      screen: const TutorPronunciationModeScreen(),
    ),
    TutorMode(
      id: 'story',
      title: 'Stories',
      description: 'Cultural stories with vocabulary',
      icon: Icons.auto_stories,
      color: PolieColors.electricTealLight,
      screen: const TutorStoryModeScreen(),
    ),
    TutorMode(
      id: 'dialogue',
      title: 'Dialogue',
      description: 'Practice conversations',
      icon: Icons.chat_bubble_outline,
      color: PolieColors.royalAmethystLight,
      screen: const TutorDialogueModeScreen(),
    ),
    TutorMode(
      id: 'assess',
      title: 'Assessment',
      description: 'Test your proficiency',
      icon: Icons.assessment,
      color: PolieColors.goldEmberLight,
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PolieColors.primary,
              PolieColors.primaryDark,
              PolieColors.obsidian,
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
                    horizontal: PolieSpacing.md,
                    vertical: PolieSpacing.sm,
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
      padding: EdgeInsets.all(PolieSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Polie Tutor',
            style: PolieTypography.h1(context).copyWith(color: PolieColors.textPrimary),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
          SizedBox(height: PolieSpacing.xs),
          Text(
            'Your AI language learning companion',
            style: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary),
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
        color: PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PolieRadius.lg),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: PolieColors.royalAmethyst,
        labelColor: PolieColors.textPrimary,
        unselectedLabelColor: PolieColors.textSecondary,
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
        margin: EdgeInsets.only(right: PolieSpacing.sm),
        padding: EdgeInsets.all(PolieSpacing.md),
        decoration: BoxDecoration(
          color: PolieColors.surfaceContainerLight,
          borderRadius: BorderRadius.circular(PolieRadius.lg),
          boxShadow: PolieElevation.level1(context),
          border: Border.all(
            color: mode.color.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(PolieSpacing.sm),
              decoration: BoxDecoration(
                color: mode.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                mode.icon,
                color: mode.color,
                size: 28.sp,
              ),
            ),
            SizedBox(height: PolieSpacing.sm),
            Text(
              mode.title,
              style: PolieTypography.label(context).copyWith(color: PolieColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PolieSpacing.xs),
            Text(
              mode.description,
              style: PolieTypography.bodySmall(context),
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


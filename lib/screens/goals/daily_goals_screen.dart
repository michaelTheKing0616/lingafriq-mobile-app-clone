import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/daily_goals_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/screens/ai_chat/ai_chat_language_setup_screen.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/games/games_screen.dart';
import 'package:lingafriq/screens/tabs_view/home/take_quiz_screen.dart';
import 'package:lingafriq/screens/tabs_view/tabs_view.dart';
import 'package:lingafriq/lessons/screens/lessons_list_screen.dart';
import 'package:lingafriq/screens/vocabulary/vocabulary_screen.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/error_handler.dart' hide ErrorBoundary;
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/empty_state_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DailyGoalsScreen extends ConsumerStatefulWidget {
  const DailyGoalsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyGoalsScreen> createState() => _DailyGoalsScreenState();
}

class _DailyGoalsScreenState extends ConsumerState<DailyGoalsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh goals when screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyGoalsProvider.notifier).refreshGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'Unable to load daily goals. Please check your connection and try again.',
      onRetry: () {
        ref.read(dailyGoalsProvider.notifier).refreshGoals();
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final goalsNotifier = ref.watch(dailyGoalsProvider.notifier);
    final goals = ref.watch(dailyGoalsProvider.notifier).goals;
    final streak = ref.watch(dailyGoalsProvider.notifier).currentStreak;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text('Daily Goals', style: PanAfricanTypography.titleLarge(context)),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak Card - Material 3 Design
            _buildStreakCard(context, streak, isDark),
            SizedBox(height: 24.sp),
            
            // Daily Goals Title
            Text(
              'Today\'s Goals',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16.sp),
            
            // Goals List
            goals.isEmpty
                ? _buildEmptyState(context, isDark)
                : Column(
                    children: goals.map((goal) => _buildGoalCard(context, goal, isDark, goalsNotifier)).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, int streak, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: PanAfricanGradients.forest,
        borderRadius: PanAfricanRadius.xlBR,
        boxShadow: PanAfricanShadows.glowGreen(0.3),
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Row(
          children: [
            // Fire Icon
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 32.sp),
              ),
            ),
            SizedBox(width: PanAfricanSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak Day Streak',
                    style: PanAfricanTypography.headlineMedium(context, color: Colors.white),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxs),
                  Text(
                    streak > 0 
                        ? 'Keep it up! You\'re on fire!'
                        : 'Start your learning journey today!',
                    style: PanAfricanTypography.bodyMedium(context, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(32.sp),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64.sp,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            SizedBox(height: 16.sp),
            Text(
              'No goals available',
              style: TextStyle(
                fontSize: 18.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              'Check back later for your daily goals',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, goal, bool isDark, goalsNotifier) {
    final icon = _getGoalIcon(goal.type);
    final title = _getGoalTitle(goal.type);
    final progress = goal.progress;
    final isCompleted = goal.completed;

    return InkWell(
      onTap: () => _navigateToGoalModule(context, goal.type),
      borderRadius: PanAfricanRadius.xlBR,
      child: Container(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
          borderRadius: PanAfricanRadius.xlBR,
          border: Border.all(
            color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
            width: 1,
          ),
          boxShadow: PanAfricanShadows.sm,
        ),
        child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.sm),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? PanAfricanColors.primary.withOpacity(0.2)
                        : (isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight),
                    borderRadius: PanAfricanRadius.mdBR,
                  ),
                  child: Text(
                    icon,
                    style: TextStyle(fontSize: 24.sp),
                  ),
                ),
                SizedBox(width: PanAfricanSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PanAfricanTypography.titleMedium(context, color: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight),
                      ),
                      SizedBox(height: PanAfricanSpacing.xxs),
                      Text(
                        '${goal.current} / ${goal.target}',
                        style: PanAfricanTypography.bodyMedium(context, color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm, vertical: PanAfricanSpacing.xxs),
                    decoration: BoxDecoration(
                      color: PanAfricanColors.primary,
                      borderRadius: PanAfricanRadius.roundBR,
                    ),
                    child: Text(
                      '✓ Done',
                      style: PanAfricanTypography.labelSmall(context, color: Colors.white),
                    ),
                  ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            // Progress Bar
            ClipRRect(
              borderRadius: PanAfricanRadius.smBR,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? PanAfricanColors.primary : PanAfricanColors.tertiary,
                ),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              '${(progress * 100).toInt()}% complete',
              style: PanAfricanTypography.labelSmall(context, color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _navigateToGoalModule(BuildContext context, String goalType) {
    final navigation = ref.read(navigationProvider);
    // Navigate to the appropriate module based on goal type
    switch (goalType) {
      case 'lessons':
        // Show language selector for lessons
        _showLanguageSelectorForLessons(context);
        break;
      case 'quizzes':
        // Show language selector, then navigate to quiz
        _showLanguageSelectorForQuiz(context);
        break;
      case 'games':
        navigation.navigateTo(const GamesScreen());
        break;
      case 'chat_minutes':
        navigation.navigateTo(const AiChatLanguageSetupScreen(
          initialMode: PolieMode.translation,
        ));
        break;
      case 'words_learned':
        // Navigate to vocabulary/words screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VocabularyScreen(),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigating to $goalType...')),
        );
    }
  }

  String _getGoalIcon(String type) {
    switch (type) {
      case 'lessons':
        return '📚';
      case 'quizzes':
        return '🎯';
      case 'games':
        return '🎮';
      case 'chat_minutes':
        return '💬';
      case 'words_learned':
        return '📝';
      default:
        return '✅';
    }
  }

  String _getGoalTitle(String type) {
    switch (type) {
      case 'lessons':
        return 'Complete Lessons';
      case 'quizzes':
        return 'Take Quizzes';
      case 'games':
        return 'Play Games';
      case 'chat_minutes':
        return 'Chat with Polie';
      case 'words_learned':
        return 'Learn Words';
      default:
        return 'Goal';
    }
  }

  void _showLanguageSelectorForLessons(BuildContext context) async {
    await safeAsync(
      context: context,
      operation: () async {
        // Fetch languages
        final languages = await ref.read(apiProvider.notifier).getLanguages();
        if (!mounted) return;

        // Show bottom sheet to select language
        if (mounted) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              decoration: BoxDecoration(
                color: context.isDarkMode ? const Color(0xFF1F3527) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select Language for Lessons',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: context.adaptive,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ...languages.results.take(5).map((language) => ListTile(
                    leading: Icon(Icons.book, color: PanAfricanColors.primary),
                    title: Text(
                      language.name,
                      style: TextStyle(color: context.adaptive),
                    ),
                    onTap: () {
                      // CRITICAL FIX: Add context.mounted checks before Navigator calls
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (context.mounted) {
                          Navigator.pop(context); // Close daily goals
                          if (context.mounted) {
                            ref.read(navigationProvider).navigateTo(
                              LessonsListScreen(language: language),
                            );
                          }
                        }
                      }
                    },
                  )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }
      },
      errorContext: 'showLanguageSelectorForLessons',
      showError: true,
    );
  }

  void _showLanguageSelectorForQuiz(BuildContext context) async {
    await safeAsync(
      context: context,
      operation: () async {
        // Fetch languages
        final languages = await ref.read(apiProvider.notifier).getLanguages();
        if (!mounted) return;

        // Show bottom sheet to select language
        if (mounted) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              decoration: BoxDecoration(
                color: context.isDarkMode ? const Color(0xFF1F3527) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select Language for Quiz',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: context.adaptive,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ...languages.results.take(5).map((language) => ListTile(
                    leading: Icon(Icons.language, color: PanAfricanColors.primary),
                    title: Text(
                      language.name,
                      style: TextStyle(color: context.adaptive),
                    ),
                    onTap: () {
                      // CRITICAL FIX: Add context.mounted checks before Navigator calls
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (context.mounted) {
                          Navigator.pop(context); // Close daily goals
                          if (context.mounted) {
                            ref.read(navigationProvider).navigateTo(
                              TakeQuizScreen(language: language),
                            );
                          }
                        }
                      }
                    },
                  )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }
      },
      errorContext: 'showLanguageSelectorForQuiz',
      showError: true,
    );
  }
}


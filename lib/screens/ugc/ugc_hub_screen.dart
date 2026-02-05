import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/screens/ugc/create_lesson_screen.dart';
import 'package:lingafriq/screens/ugc/create_quiz_screen.dart';
import 'package:lingafriq/screens/ugc/create_story_screen.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

/// Hub screen for User-Generated Content
class UGCHubScreen extends ConsumerStatefulWidget {
  const UGCHubScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UGCHubScreen> createState() => _UGCHubScreenState();
}

class _UGCHubScreenState extends ConsumerState<UGCHubScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text('Create Content', style: PanAfricanTypography.titleLarge(context)),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
        leading: IconButton(
          icon: Icon(PanAfricanIcons.back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share Your Knowledge',
              style: PanAfricanTypography.headlineMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              'Create and share lessons, quizzes, and stories with the community',
              style: PanAfricanTypography.bodyMedium(context, color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            
            // Create Lesson Card
            _ContentTypeCard(
              title: 'Create Lesson',
              description: 'Share your knowledge by creating a lesson',
              icon: PanAfricanIcons.lesson,
              color: PanAfricanColors.kenteBlue,
              onTap: () async {
                HapticFeedback.lightImpact();
                final result = await safeNavigate(
                  context: context,
                  destination: const CreateLessonScreen(),
                );
                if (context.mounted && result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lesson created!', style: PanAfricanTypography.bodyMedium(context, color: Colors.white)),
                      backgroundColor: PanAfricanColors.success,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: PanAfricanSpacing.md),
            
            // Create Quiz Card
            _ContentTypeCard(
              title: 'Create Quiz',
              description: 'Test knowledge with interactive quizzes',
              icon: PanAfricanIcons.quiz,
              color: PanAfricanColors.ankaraPurple,
              onTap: () async {
                HapticFeedback.lightImpact();
                final result = await safeNavigate(
                  context: context,
                  destination: const CreateQuizScreen(),
                );
                if (context.mounted && result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quiz created!', style: PanAfricanTypography.bodyMedium(context, color: Colors.white)),
                      backgroundColor: PanAfricanColors.success,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: PanAfricanSpacing.md),
            
            // Create Story Card
            _ContentTypeCard(
              title: 'Create Story',
              description: 'Share cultural stories and narratives',
              icon: PanAfricanIcons.book,
              color: PanAfricanColors.tertiary,
              onTap: () async {
                HapticFeedback.lightImpact();
                final result = await safeNavigate(
                  context: context,
                  destination: const CreateStoryScreen(),
                );
                if (context.mounted && result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Story created!', style: PanAfricanTypography.bodyMedium(context, color: Colors.white)),
                      backgroundColor: PanAfricanColors.success,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            
            // My Content Section
            Text(
              'My Content',
              style: PanAfricanTypography.titleLarge(context),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ref.read(userGeneratedContentServiceProvider).getUserContent(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: PanAfricanColors.primary));
                }
                
                if (snapshot.hasError) {
                  return Text(
                    'Error loading content: ${snapshot.error}',
                    style: PanAfricanTypography.bodyMedium(context, color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
                  );
                }
                
                final content = snapshot.data ?? [];
                
                if (content.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(PanAfricanSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                      borderRadius: PanAfricanRadius.lgBR,
                      boxShadow: PanAfricanShadows.sm,
                    ),
                    child: Text(
                      'No content created yet. Start creating!',
                      style: PanAfricanTypography.bodyMedium(context, color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                
                return Column(
                  children: content.map((item) {
                    return Container(
                      margin: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                      decoration: BoxDecoration(
                        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                        borderRadius: PanAfricanRadius.lgBR,
                        boxShadow: PanAfricanShadows.sm,
                      ),
                      child: ListTile(
                        title: Text(item['title'] ?? 'Untitled', style: PanAfricanTypography.titleMedium(context)),
                        subtitle: Text(item['type'] ?? 'content', style: PanAfricanTypography.bodySmall(context)),
                        trailing: IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            final ugcService = ref.read(userGeneratedContentServiceProvider);
                            await ugcService.shareContent(
                              contentId: item['id'] ?? '',
                              contentType: item['type'] ?? 'lesson',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Content shared!', style: PanAfricanTypography.bodyMedium(context, color: Colors.white)),
                                  backgroundColor: PanAfricanColors.success,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContentTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: PanAfricanRadius.lgBR,
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: PanAfricanRadius.mdBR,
                  ),
                  child: Icon(icon, color: color, size: 32.sp),
                ),
                SizedBox(width: PanAfricanSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PanAfricanTypography.titleMedium(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.xxs),
                      Text(
                        description,
                        style: PanAfricanTypography.bodySmall(context),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/screens/ugc/ugc_validation_feedback_screen.dart';
import 'package:lingafriq/screens/ugc/ugc_quality_badges_widget.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Enhanced Create Lesson Screen with Validation Feedback and Quality Badges
class CreateLessonScreenEnhanced extends HookConsumerWidget {
  const CreateLessonScreenEnhanced({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final contentController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final selectedLanguage = useState('yoruba');
    final isSubmitting = useState(false);
    final validationResult = useState<Map<String, dynamic>?>(null);
    final qualityBadges = useState<List<String>>([]);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languages = ['yoruba', 'hausa', 'igbo', 'swahili', 'zulu', 'afrikaans'];

    Future<void> validateContent() async {
      if (contentController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter lesson content')),
        );
        return;
      }

      try {
        final response = await ApiService.post(
          '/user-content/validate',
          data: {
            'content': contentController.text,
            'contentType': 'lesson',
            'language': selectedLanguage.value,
          },
        );

        if (response.statusCode == 200) {
          validationResult.value = response.data['data'];
          qualityBadges.value = _extractBadges(response.data['data']);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }

    Future<void> submitLesson() async {
      if (titleController.text.isEmpty || contentController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all required fields')),
        );
        return;
      }

      isSubmitting.value = true;
      try {
        final response = await ApiService.post(
          '/user-content/lessons',
          data: {
            'title': titleController.text,
            'content': contentController.text,
            'description': descriptionController.text,
            'language': selectedLanguage.value,
            'qualityBadges': qualityBadges.value,
          },
        );

        if (response.statusCode == 200) {
          if (context.mounted) {
            ErrorHandler.showSuccess(context, 'Lesson created successfully!');
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    List<String> _extractBadges(Map<String, dynamic>? validation) {
      if (validation == null) return [];
      final badges = <String>[];
      
      if (validation['grammarCheck']?['passed'] == true) {
        badges.add('grammatically_perfect');
      }
      if (validation['culturalCheck']?['passed'] == true) {
        badges.add('culturally_authentic');
      }
      if (validation['canonicalCheck']?['passed'] == true) {
        badges.add('canonical_form');
      }
      
      return badges;
    }

    final isLoading = useState(false);
    
    return LoadingOverlay(
      isLoading: isLoading.value,
      message: 'Creating lesson...',
      child: Scaffold(
      appBar: AppBar(
        title: Text('Create Lesson'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (validationResult.value != null)
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(
                    builder: (context) => UGCValidationFeedbackScreen(
                      contentId: 'draft',
                      contentType: 'lesson',
                    ),
                  ),
                );
              },
              tooltip: 'View Validation Details',
            ),
        ],
      ),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quality Badges Preview
                if (qualityBadges.value.isNotEmpty)
                  Card(
                    color: PanAfricanColors.primaryContainer.withOpacity(0.3),
                    child: Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quality Badges',
                            style: PanAfricanTypography.titleSmall(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.sm),
                          UGCQualityBadgesWidget(
                            badges: qualityBadges.value,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                SizedBox(height: PanAfricanSpacing.lg),

                // Language Selection
                DropdownButtonFormField<String>(
                  value: selectedLanguage.value,
                  decoration: InputDecoration(
                    labelText: 'Language',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                  items: languages.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedLanguage.value = value;
                  },
                ),
                SizedBox(height: PanAfricanSpacing.md),

                // Title
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Lesson Title *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                  style: PanAfricanTypography.bodyLarge(context),
                ),
                SizedBox(height: PanAfricanSpacing.md),

                // Description
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: PanAfricanSpacing.md),

                // Content
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Lesson Content *',
                    hintText: 'Enter your lesson content here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                  maxLines: 10,
                  style: PanAfricanTypography.bodyLarge(context),
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Validate Button
                ElevatedButton.icon(
                  onPressed: validateContent,
                  icon: Icon(Icons.check_circle),
                  label: Text('Validate Content'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PanAfricanColors.secondary,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.md),

                // Validation Result Summary
                if (validationResult.value != null)
                  Card(
                    color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                    child: Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Validation Summary',
                            style: PanAfricanTypography.titleMedium(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.sm),
                          Text(
                            'Score: ${(validationResult.value!['overallScore'] ?? 0).toInt()}/100',
                            style: PanAfricanTypography.bodyLarge(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                SmoothPageRoute(
                                  builder: (context) => UGCValidationFeedbackScreen(
                                    contentId: 'draft',
                                    contentType: 'lesson',
                                  ),
                                ),
                              );
                            },
                            child: Text('View Full Details'),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                SizedBox(height: PanAfricanSpacing.xl),

                // Submit Button
                ElevatedButton(
                  onPressed: isSubmitting.value ? null : submitLesson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PanAfricanColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                  ),
                  child: isSubmitting.value
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Create Lesson',
                          style: PanAfricanTypography.labelLarge(context)
                              .copyWith(color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/screens/ugc/ugc_enhanced_rules.dart';
import 'package:lingafriq/screens/ugc/ugc_quality_badges_widget.dart';
import 'package:lingafriq/screens/ugc/ugc_validation_feedback_screen.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';

/// Screen for creating user-generated lessons
class CreateLessonScreen extends HookConsumerWidget {
  const CreateLessonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final contentController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final tagsController = useTextEditingController();
    final selectedLanguage = useState<String>('yoruba');
    final isSubmitting = useState(false);
    final isValidating = useState(false);
    final qualityBadges = useState<List<String>>(const <String>[]);
    final validationPayload = useState<Map<String, dynamic>?>(null);
    
    final languages = ['yoruba', 'hausa', 'igbo', 'swahili', 'zulu', 'afrikaans', 'nigerian_pidgin'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreLine = lessonScoreLine(validationPayload.value);

    Future<void> openValidationDetails() async {
      await Navigator.push(
        context,
        SmoothPageRoute(
          child: const UGCValidationFeedbackScreen(
            contentId: 'draft',
            contentType: 'lesson',
          ),
        ),
      );
    }

    Future<void> validateLesson() async {
      if (contentController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ugcPleaseEnterLessonContent(),
              style: PanAfricanTypography.bodyMedium(
                context,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: PanAfricanColors.error,
          ),
        );
        return;
      }

      isValidating.value = true;
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
          final body = response.data;
          Map<String, dynamic>? payload;
          if (body is Map && body['data'] is Map) {
            payload = Map<String, dynamic>.from(body['data'] as Map);
          }
          validationPayload.value = payload;
          qualityBadges.value = lessonQualityBadges(payload);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      } finally {
        isValidating.value = false;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text('Create Lesson', style: PanAfricanTypography.titleLarge(context)),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
        leading: IconButton(
          icon: const Icon(PanAfricanIcons.back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (validationPayload.value != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: ugcViewValidationDetails(),
              onPressed: openValidationDetails,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language Selection
            DropdownButtonFormField<String>(
              initialValue: selectedLanguage.value,
              decoration: InputDecoration(
                labelText: 'Language',
                labelStyle: PanAfricanTypography.bodyMedium(context),
                border: OutlineInputBorder(
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                filled: true,
                fillColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              ),
              items: languages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang.toUpperCase(), style: PanAfricanTypography.bodyMedium(context)),
                );
              }).toList(),
              onChanged: (value) {
                HapticFeedback.selectionClick();
                if (value != null) selectedLanguage.value = value;
              },
            ),
            SizedBox(height: PanAfricanSpacing.md),
            
            // Title
            TextField(
              controller: titleController,
              style: PanAfricanTypography.bodyLarge(context),
              decoration: InputDecoration(
                labelText: 'Lesson Title',
                labelStyle: PanAfricanTypography.bodyMedium(context),
                border: OutlineInputBorder(
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                filled: true,
                fillColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            
            // Description
            TextField(
              controller: descriptionController,
              style: PanAfricanTypography.bodyLarge(context),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: PanAfricanTypography.bodyMedium(context),
                border: OutlineInputBorder(
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                filled: true,
                fillColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              ),
              maxLines: 2,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            
            // Content
            TextField(
              controller: contentController,
              style: PanAfricanTypography.bodyLarge(context),
              decoration: InputDecoration(
                labelText: 'Lesson Content',
                hintText: 'Enter your lesson content here...',
                hintStyle: PanAfricanTypography.bodyMedium(context, color: PanAfricanColors.textSecondaryLight),
                labelStyle: PanAfricanTypography.bodyMedium(context),
                border: OutlineInputBorder(
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                filled: true,
                fillColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              ),
              maxLines: 10,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            
            // Tags
            TextField(
              controller: tagsController,
              style: PanAfricanTypography.bodyLarge(context),
              decoration: InputDecoration(
                labelText: 'Tags (comma-separated)',
                hintText: 'e.g., greetings, beginner, vocabulary',
                hintStyle: PanAfricanTypography.bodyMedium(context, color: PanAfricanColors.textSecondaryLight),
                labelStyle: PanAfricanTypography.bodyMedium(context),
                border: OutlineInputBorder(
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                filled: true,
                fillColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),

            if (qualityBadges.value.isNotEmpty) ...[
              Text(
                ugcQualityBadgesLabel(),
                style: PanAfricanTypography.titleSmall(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              UGCQualityBadgesWidget(
                badges: qualityBadges.value,
                isDark: isDark,
              ),
              SizedBox(height: PanAfricanSpacing.md),
            ],
            if (validationPayload.value != null) ...[
              Text(
                ugcValidationSummaryLabel(),
                style: PanAfricanTypography.titleMedium(context),
              ),
              if (scoreLine != null)
                Text(scoreLine, style: PanAfricanTypography.bodyLarge(context)),
              TextButton(
                onPressed: openValidationDetails,
                child: Text(ugcViewFullDetails()),
              ),
              SizedBox(height: PanAfricanSpacing.md),
            ],
            OutlinedButton.icon(
              onPressed: isValidating.value ? null : validateLesson,
              icon: const Icon(Icons.check_circle),
              label: Text(ugcValidateContentLabel()),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            
            // Submit Button
            FilledButton(
              onPressed: isSubmitting.value ? null : () async {
                HapticFeedback.mediumImpact();
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in title and content', style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary)),
                      backgroundColor: PanAfricanColors.error,
                    ),
                  );
                  return;
                }
                
                isSubmitting.value = true;
                
                await safeAsync(
                  context: context,
                  operation: () async {
                    final ugcService = ref.read(userGeneratedContentServiceProvider);
                    final tags = tagsController.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();
                    
                    await ugcService.createLesson(
                      language: selectedLanguage.value,
                      title: titleController.text,
                      content: contentController.text,
                      description: descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                      tags: tags.isEmpty ? null : tags,
                    );
                    
                    if (context.mounted) {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lesson created successfully!', style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary)),
                          backgroundColor: PanAfricanColors.success,
                        ),
                      );
                      Navigator.of(context).pop(true);
                    }
                  },
                  errorContext: 'createLesson',
                  showError: true,
                );
                
                if (context.mounted) {
                  isSubmitting.value = false;
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: PanAfricanColors.primary,
                padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.lgBR),
              ),
              child: isSubmitting.value
                  ? SizedBox(
                      width: 20.sp,
                      height: 20.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                      ),
                    )
                  : Text('Create Lesson', style: PanAfricanTypography.labelLarge(context, color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}


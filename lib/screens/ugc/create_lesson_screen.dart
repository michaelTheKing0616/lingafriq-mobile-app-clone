import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/providers/api_provider.dart';

/// Screen for creating user-generated lessons
class CreateLessonScreen extends HookConsumerWidget {
  const CreateLessonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final contentController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final tagsController = useTextEditingController();
    final selectedLanguage = useState<String>('yoruba');
    final isSubmitting = useState(false);
    
    final languages = ['yoruba', 'hausa', 'igbo', 'swahili', 'zulu', 'afrikaans', 'nigerian_pidgin'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text('Create Lesson', style: PanAfricanTypography.titleLarge(context)),
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
            // Language Selection
            DropdownButtonFormField<String>(
              value: selectedLanguage.value,
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
            
            // Submit Button
            FilledButton(
              onPressed: isSubmitting.value ? null : () async {
                HapticFeedback.mediumImpact();
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in title and content', style: PanAfricanTypography.bodyMedium(context, color: Colors.white)),
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
                    
                    final lesson = await ugcService.createLesson(
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
                          content: Text('Lesson created successfully!', style: PanAfricanTypography.bodyMedium(context, color: Colors.white)),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Create Lesson', style: PanAfricanTypography.labelLarge(context, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}


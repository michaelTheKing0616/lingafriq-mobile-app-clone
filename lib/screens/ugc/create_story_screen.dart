import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';

/// Screen for creating user-generated stories
class CreateStoryScreen extends HookConsumerWidget {
  const CreateStoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final storyController = useTextEditingController();
    final themeController = useTextEditingController();
    final vocabController = useTextEditingController();
    final selectedLanguage = useState<String>('yoruba');
    final isSubmitting = useState(false);
    
    final languages = ['yoruba', 'hausa', 'igbo', 'swahili', 'zulu', 'afrikaans', 'nigerian_pidgin'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text('Create Story', style: PanAfricanTypography.titleLarge(context)),
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
                labelText: 'Story Title',
                labelStyle: PanAfricanTypography.bodyMedium(context),
                border: OutlineInputBorder(
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                filled: true,
                fillColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            
            // Theme
            TextField(
              controller: themeController,
              style: PanAfricanTypography.bodyLarge(context),
              decoration: InputDecoration(
                labelText: 'Theme (Optional)',
                hintText: 'e.g., friendship, adventure, wisdom',
                hintStyle: PanAfricanTypography.bodyMedium(context, color: PanAfricanColors.textSecondaryLight),
                labelStyle: PanAfricanTypography.bodyMedium(context),
                border: OutlineInputBorder(
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                filled: true,
                fillColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            
            // Story Content
            TextField(
              controller: storyController,
              style: PanAfricanTypography.bodyLarge(context),
              decoration: InputDecoration(
                labelText: 'Story Content',
                hintText: 'Write your story here...',
                hintStyle: PanAfricanTypography.bodyMedium(context, color: PanAfricanColors.textSecondaryLight),
                labelStyle: PanAfricanTypography.bodyMedium(context),
                border: OutlineInputBorder(
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                filled: true,
                fillColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              ),
              maxLines: 15,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            
            // Vocabulary
            TextField(
              controller: vocabController,
              style: PanAfricanTypography.bodyLarge(context),
              decoration: InputDecoration(
                labelText: 'Key Vocabulary (comma-separated)',
                hintText: 'e.g., word1, word2, word3',
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
                if (titleController.text.isEmpty || storyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in title and story content', style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary)),
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
                    final vocabulary = vocabController.text
                        .split(',')
                        .map((v) => v.trim())
                        .where((v) => v.isNotEmpty)
                        .toList();
                    
                    final story = await ugcService.createStory(
                      language: selectedLanguage.value,
                      title: titleController.text,
                      story: storyController.text,
                      theme: themeController.text.isEmpty ? null : themeController.text,
                      vocabulary: vocabulary.isEmpty ? null : vocabulary,
                    );
                    
                    if (context.mounted) {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Story created successfully!', style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary)),
                          backgroundColor: PanAfricanColors.success,
                        ),
                      );
                      Navigator.of(context).pop(true);
                    }
                  },
                  errorContext: 'createStory',
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
                  : Text('Create Story', style: PanAfricanTypography.labelLarge(context, color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}



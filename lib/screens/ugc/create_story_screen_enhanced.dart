import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/screens/ugc/ugc_quality_badges_widget.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';

/// Enhanced Create Story Screen with Validation Feedback
class CreateStoryScreenEnhanced extends HookConsumerWidget {
  const CreateStoryScreenEnhanced({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final contentController = useTextEditingController();
    final selectedLanguage = useState('yoruba');
    final isSubmitting = useState(false);
    final validationResult = useState<Map<String, dynamic>?>(null);
    final qualityBadges = useState<List<String>>([]);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> validateContent() async {
      final errors = <String>[];
      final title = titleController.text.trim();
      final content = contentController.text.trim();

      if (title.isEmpty) errors.add('Story title is required.');
      if (title.length < 5) errors.add('Story title should be at least 5 characters.');

      if (content.isEmpty) {
        errors.add('Story content is required.');
      } else if (content.length < 50) {
        errors.add('Story content should be at least 50 characters.');
      }

      final badges = <String>[];
      if (title.isNotEmpty && title.length >= 12) badges.add('Clear title');
      if (content.isNotEmpty && content.length >= 200) badges.add('Rich content');
      if (content.isNotEmpty && content.length >= 500) badges.add('Detailed story');
      if (errors.isEmpty) badges.add('Validation passed');

      validationResult.value = errors.isEmpty ? null : {'errors': errors};
      qualityBadges.value = badges;
    }

    Future<void> submitStory() async {
      await validateContent();
      if (validationResult.value != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((validationResult.value!['errors'] as List?)?.join('\n') ?? 'Please fix validation errors.'),
          ),
        );
        return;
      }

      if (!context.mounted) return;

      isSubmitting.value = true;
      try {
        final service = ref.read(userGeneratedContentServiceProvider);
        final result = await service.createStory(
          language: selectedLanguage.value,
          title: titleController.text.trim(),
          story: contentController.text.trim(),
          theme: null,
          vocabulary: null,
        );

        if (!context.mounted) return;
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story created successfully!')),
          );
          Navigator.pop(context, result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create story. Please try again.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e);
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Story'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                      child: UGCQualityBadgesWidget(
                        badges: qualityBadges.value,
                        isDark: isDark,
                      ),
                    ),
                  ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Title
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Story Title *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.md),

                // Content
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Story Content *',
                    hintText: 'Write your story here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                  maxLines: 15,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Validate Button
                ElevatedButton.icon(
                  onPressed: validateContent,
                  icon: Icon(Icons.check_circle),
                  label: Text('Validate Story'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PanAfricanColors.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xl),

                // Submit Button
                ElevatedButton(
                  onPressed: isSubmitting.value ? null : submitStory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PanAfricanColors.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                  ),
                  child: isSubmitting.value
                      ? CircularProgressIndicator()
                      : Text('Create Story'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Create Story'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language Selection
            DropdownButtonFormField<String>(
              value: selectedLanguage.value,
              decoration: InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            SizedBox(height: 16.sp),
            
            // Title
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Story Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16.sp),
            
            // Theme
            TextField(
              controller: themeController,
              decoration: InputDecoration(
                labelText: 'Theme (Optional)',
                hintText: 'e.g., friendship, adventure, wisdom',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16.sp),
            
            // Story Content
            TextField(
              controller: storyController,
              decoration: InputDecoration(
                labelText: 'Story Content',
                hintText: 'Write your story here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 15,
            ),
            SizedBox(height: 16.sp),
            
            // Vocabulary
            TextField(
              controller: vocabController,
              decoration: InputDecoration(
                labelText: 'Key Vocabulary (comma-separated)',
                hintText: 'e.g., word1, word2, word3',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 24.sp),
            
            // Submit Button
            FilledButton(
              onPressed: isSubmitting.value ? null : () async {
                if (titleController.text.isEmpty || storyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in title and story content'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                isSubmitting.value = true;
                
                try {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Story created successfully!'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating story: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (context.mounted) {
                    isSubmitting.value = false;
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: EdgeInsets.symmetric(vertical: 16.sp),
              ),
              child: isSubmitting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Create Story'),
            ),
          ],
        ),
      ),
    );
  }
}



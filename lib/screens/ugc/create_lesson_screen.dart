import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Create Lesson'),
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
                labelText: 'Lesson Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16.sp),
            
            // Description
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16.sp),
            
            // Content
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: 'Lesson Content',
                hintText: 'Enter your lesson content here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 10,
            ),
            SizedBox(height: 16.sp),
            
            // Tags
            TextField(
              controller: tagsController,
              decoration: InputDecoration(
                labelText: 'Tags (comma-separated)',
                hintText: 'e.g., greetings, beginner, vocabulary',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 24.sp),
            
            // Submit Button
            FilledButton(
              onPressed: isSubmitting.value ? null : () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in title and content'),
                      backgroundColor: Colors.red,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lesson created successfully!'),
                          backgroundColor: AppColors.primaryGreen,
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
                  : const Text('Create Lesson'),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Screen for creating user-generated quizzes
class CreateQuizScreen extends HookConsumerWidget {
  const CreateQuizScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final selectedLanguage = useState<String>('yoruba');
    final questions = useState<List<Map<String, dynamic>>>([]);
    final isSubmitting = useState(false);
    final currentQuestion = useState<Map<String, dynamic>?>(null);
    
    final languages = ['yoruba', 'hausa', 'igbo', 'swahili', 'zulu', 'afrikaans', 'nigerian_pidgin'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text('Create Quiz'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              currentQuestion.value = {
                'question': '',
                'options': ['', '', '', ''],
                'correctAnswer': 0,
              };
            },
            tooltip: 'Add Question',
          ),
        ],
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
                labelText: 'Quiz Title',
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
            SizedBox(height: 24.sp),
            
            // Questions List
            Text(
              'Questions (${questions.value.length})',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 8.sp),
            
            ...questions.value.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return Card(
                margin: EdgeInsets.only(bottom: 8.sp),
                child: ListTile(
                  title: Text(question['question'] ?? 'Question ${index + 1}'),
                  subtitle: Text('${question['options']?.length ?? 0} options'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      questions.value = List.from(questions.value)..removeAt(index);
                    },
                  ),
                ),
              );
            }),
            
            if (currentQuestion.value != null) ...[
              SizedBox(height: 16.sp),
              _QuestionEditor(
                question: currentQuestion.value!,
                onSave: (q) {
                  questions.value = [...questions.value, q];
                  currentQuestion.value = null;
                },
                onCancel: () {
                  currentQuestion.value = null;
                },
              ),
            ],
            
            SizedBox(height: 24.sp),
            
            // Submit Button
            FilledButton(
              onPressed: isSubmitting.value || questions.value.isEmpty
                  ? null
                  : () async {
                      if (titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in quiz title'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      isSubmitting.value = true;
                      
                      try {
                        final ugcService = ref.read(userGeneratedContentServiceProvider);
                        final quiz = await ugcService.createQuiz(
                          language: selectedLanguage.value,
                          title: titleController.text,
                          questions: questions.value,
                          description: descriptionController.text.isEmpty
                              ? null
                              : descriptionController.text,
                        );
                        
                        if (quiz != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Quiz created successfully!'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                          Navigator.of(context).pop(true);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error creating quiz: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
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
                  : const Text('Create Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionEditor extends HookConsumerWidget {
  final Map<String, dynamic> question;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const _QuestionEditor({
    required this.question,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionController = useTextEditingController(text: question['question'] ?? '');
    final optionControllers = useMemoized(() => [
      useTextEditingController(text: question['options']?[0] ?? ''),
      useTextEditingController(text: question['options']?[1] ?? ''),
      useTextEditingController(text: question['options']?[2] ?? ''),
      useTextEditingController(text: question['options']?[3] ?? ''),
    ]);
    final correctAnswer = useState(question['correctAnswer'] ?? 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF1F3527) : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: questionController,
              decoration: InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16.sp),
            ...optionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 8.sp),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: correctAnswer.value,
                      onChanged: (value) => correctAnswer.value = value!,
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 16.sp),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 8.sp),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      onSave({
                        'question': questionController.text,
                        'options': optionControllers.map((c) => c.text).toList(),
                        'correctAnswer': correctAnswer.value,
                      });
                    },
                    child: const Text('Add Question'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



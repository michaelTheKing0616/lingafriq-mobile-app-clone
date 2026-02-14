import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/integration_helpers.dart';

/// Screen for creating user-generated quizzes
class CreateQuizScreen extends HookConsumerWidget {
  const CreateQuizScreen({super.key});

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
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text('Create Quiz', style: PanAfricanTypography.titleLarge(context)),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
        leading: IconButton(
          icon: Icon(PanAfricanIcons.back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              HapticFeedback.lightImpact();
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
                labelText: 'Quiz Title',
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
            SizedBox(height: PanAfricanSpacing.lg),
            
            // Questions List
            Text(
              'Questions (${questions.value.length})',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            
            ...questions.value.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                decoration: BoxDecoration(
                  color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                  borderRadius: PanAfricanRadius.lgBR,
                  boxShadow: PanAfricanShadows.sm,
                ),
                child: ListTile(
                  title: Text(question['question'] ?? 'Question ${index + 1}', style: PanAfricanTypography.titleSmall(context)),
                  subtitle: Text('${question['options']?.length ?? 0} options', style: PanAfricanTypography.bodySmall(context)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: PanAfricanColors.error),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      questions.value = List.from(questions.value)..removeAt(index);
                    },
                  ),
                ),
              );
            }),
            
            if (currentQuestion.value != null) ...[
              SizedBox(height: PanAfricanSpacing.md),
              _QuestionEditor(
                question: currentQuestion.value!,
                onSave: (q) {
                  HapticFeedback.mediumImpact();
                  questions.value = [...questions.value, q];
                  currentQuestion.value = null;
                },
                onCancel: () {
                  HapticFeedback.lightImpact();
                  currentQuestion.value = null;
                },
              ),
            ],
            
            SizedBox(height: PanAfricanSpacing.lg),
            
            // Submit Button
            FilledButton(
              onPressed: isSubmitting.value || questions.value.isEmpty
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      if (titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please fill in quiz title', style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary)),
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
                          await ugcService.createQuiz(
                            language: selectedLanguage.value,
                            title: titleController.text,
                            questions: questions.value,
                            description: descriptionController.text.isEmpty
                                ? null
                                : descriptionController.text,
                          );
                          
                          if (context.mounted) {
                            HapticFeedback.heavyImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Quiz created successfully!', style: PanAfricanTypography.bodyMedium(context, color: Theme.of(context).colorScheme.onPrimary)),
                                backgroundColor: PanAfricanColors.success,
                              ),
                            );
                            Navigator.of(context).pop(true);
                          }
                        },
                        errorContext: 'createQuiz',
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
                  : Text('Create Quiz', style: PanAfricanTypography.labelLarge(context, color: Theme.of(context).colorScheme.onPrimary)),
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: questionController,
              style: PanAfricanTypography.bodyLarge(context),
              decoration: InputDecoration(
                labelText: 'Question',
                labelStyle: PanAfricanTypography.bodyMedium(context),
                border: OutlineInputBorder(
                  borderRadius: PanAfricanRadius.mdBR,
                ),
                filled: true,
                fillColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            ...optionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: correctAnswer.value,
                      activeColor: PanAfricanColors.primary,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        correctAnswer.value = value!;
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: PanAfricanTypography.bodyMedium(context),
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          labelStyle: PanAfricanTypography.bodySmall(context),
                          border: OutlineInputBorder(
                            borderRadius: PanAfricanRadius.mdBR,
                          ),
                          filled: true,
                          fillColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: PanAfricanSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
                      shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
                      side: BorderSide(color: PanAfricanColors.primary),
                    ),
                    child: Text('Cancel', style: PanAfricanTypography.labelLarge(context, color: PanAfricanColors.primary)),
                  ),
                ),
                SizedBox(width: PanAfricanSpacing.xs),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onSave({
                        'question': questionController.text,
                        'options': optionControllers.map((c) => c.text).toList(),
                        'correctAnswer': correctAnswer.value,
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: PanAfricanColors.primary,
                      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
                      shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
                    ),
                    child: Text('Add Question', style: PanAfricanTypography.labelLarge(context, color: Theme.of(context).colorScheme.onPrimary)),
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



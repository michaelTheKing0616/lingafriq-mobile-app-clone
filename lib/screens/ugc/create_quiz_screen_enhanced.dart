import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/screens/ugc/ugc_quality_badges_widget.dart';
import 'package:lingafriq/services/user_generated_content_service.dart';

/// Enhanced Create Quiz Screen with Validation Feedback
class CreateQuizScreenEnhanced extends HookConsumerWidget {
  const CreateQuizScreenEnhanced({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final selectedLanguage = useState('yoruba');
    final questions = useState<List<Map<String, dynamic>>>([]);
    final isSubmitting = useState(false);
    final validationResult = useState<Map<String, dynamic>?>(null);
    final qualityBadges = useState<List<String>>([]);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    void addQuestion() {
      questions.value = [
        ...questions.value,
        {
          'question': '',
          'options': ['', '', '', ''],
          'correctAnswer': 0,
        },
      ];
    }

    Future<void> validateContent() async {
      final errors = <String>[];
      final title = titleController.text.trim();
      final desc = descriptionController.text.trim();

      if (title.isEmpty) errors.add('Quiz title is required.');
      if (title.length < 5) errors.add('Quiz title should be at least 5 characters.');

      if (questions.value.isEmpty) {
        errors.add('Add at least one question.');
      }

      for (int i = 0; i < questions.value.length; i++) {
        final q = questions.value[i];
        final qText = (q['question'] ?? '').toString().trim();
        final opts = (q['options'] as List?)?.map((e) => e.toString().trim()).toList() ?? const <String>[];
        final correct = (q['correctAnswer'] is int) ? q['correctAnswer'] as int : int.tryParse('${q['correctAnswer']}') ?? 0;

        if (qText.isEmpty) errors.add('Question ${i + 1}: question text is required.');
        if (opts.length != 4) errors.add('Question ${i + 1}: must have 4 options.');
        for (int j = 0; j < opts.length; j++) {
          if (opts[j].isEmpty) errors.add('Question ${i + 1}: option ${j + 1} is required.');
        }
        if (correct < 0 || correct > 3) errors.add('Question ${i + 1}: select a valid correct answer.');
      }

      final badges = <String>[];
      if (title.isNotEmpty && title.length >= 12) badges.add('Clear title');
      if (desc.isNotEmpty && desc.length >= 20) badges.add('Has description');
      if (questions.value.length >= 5) badges.add('Rich quiz');
      if (errors.isEmpty) badges.add('Validation passed');

      validationResult.value = errors.isEmpty ? null : {'errors': errors};
      qualityBadges.value = badges;
    }

    Future<void> submitQuiz() async {
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
        final result = await service.createQuiz(
          language: selectedLanguage.value,
          title: titleController.text.trim(),
          description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
          questions: List<Map<String, dynamic>>.from(questions.value),
        );

        if (!context.mounted) return;
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz created successfully!')),
          );
          Navigator.pop(context, result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create quiz. Please try again.')),
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
        title: Text('Create Quiz'),
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
                    labelText: 'Quiz Title *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Description
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Questions List
                ...questions.value.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  final correctAnswer = (question['correctAnswer'] is int)
                      ? question['correctAnswer'] as int
                      : int.tryParse('${question['correctAnswer']}') ?? 0;
                  return Card(
                    margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                    child: Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${index + 1}',
                            style: PanAfricanTypography.titleMedium(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.sm),
                          TextField(
                            onChanged: (value) {
                              final updated = List<Map<String, dynamic>>.from(questions.value);
                              updated[index] = {
                                ...updated[index],
                                'question': value,
                              };
                              questions.value = updated;
                            },
                            decoration: InputDecoration(
                              labelText: 'Question',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                              ),
                            ),
                          ),
                          SizedBox(height: PanAfricanSpacing.md),
                          ...List.generate(4, (optIdx) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) {
                                        final updated = List<Map<String, dynamic>>.from(questions.value);
                                        final q = Map<String, dynamic>.from(updated[index]);
                                        final opts = List<String>.from((q['options'] as List?) ?? ['', '', '', '']);
                                        while (opts.length < 4) {
                                          opts.add('');
                                        }
                                        opts[optIdx] = value;
                                        q['options'] = opts;
                                        updated[index] = q;
                                        questions.value = updated;
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Option ${optIdx + 1}',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: PanAfricanSpacing.sm),
                                  Radio<int>(
                                    value: optIdx,
                                    groupValue: correctAnswer,
                                    onChanged: (v) {
                                      if (v == null) return;
                                      final updated = List<Map<String, dynamic>>.from(questions.value);
                                      updated[index] = {
                                        ...updated[index],
                                        'correctAnswer': v,
                                      };
                                      questions.value = updated;
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                final updated = List<Map<String, dynamic>>.from(questions.value);
                                updated.removeAt(index);
                                questions.value = updated;
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove question'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Add Question Button
                ElevatedButton.icon(
                  onPressed: addQuestion,
                  icon: Icon(Icons.add),
                  label: Text('Add Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PanAfricanColors.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xl),

                // Submit Button
                ElevatedButton(
                  onPressed: isSubmitting.value ? null : submitQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PanAfricanColors.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                  ),
                  child: isSubmitting.value
                      ? CircularProgressIndicator()
                      : Text('Create Quiz'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


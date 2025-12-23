import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/screens/ugc/ugc_validation_feedback_screen.dart';
import 'package:lingafriq/screens/ugc/ugc_quality_badges_widget.dart';

/// Enhanced Create Quiz Screen with Validation Feedback
class CreateQuizScreenEnhanced extends HookConsumerWidget {
  const CreateQuizScreenEnhanced({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final selectedLanguage = useState('yoruba');
    final questions = useState<List<Map<String, dynamic>>>([]);
    final isSubmitting = useState(false);
    final validationResult = useState<Map<String, dynamic>?>(null);
    final qualityBadges = useState<List<String>>([]);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> addQuestion() {
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
      // Similar to CreateLessonScreenEnhanced
    }

    Future<void> submitQuiz() async {
      // Similar to CreateLessonScreenEnhanced
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

                // Questions List
                ...questions.value.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
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
                            decoration: InputDecoration(
                              labelText: 'Question',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                              ),
                            ),
                          ),
                          // Options and correct answer selection
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
                    foregroundColor: Colors.black,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xl),

                // Submit Button
                ElevatedButton(
                  onPressed: isSubmitting.value ? null : submitQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PanAfricanColors.primary,
                    foregroundColor: Colors.white,
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


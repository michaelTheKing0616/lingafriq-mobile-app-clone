import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';

/// Polie-Powered Placement Test Screen
class PlacementTestScreen extends HookConsumerWidget {
  final String language;

  const PlacementTestScreen({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final test = useState<Map<String, dynamic>?>(null);
    final currentQuestionIndex = useState(0);
    final answers = useState<Map<int, String>>({});
    final isLoading = useState(false);
    final isGenerating = useState(true);
    final result = useState<Map<String, dynamic>?>(null);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> generateTest() async {
      await safeAsync(
        context: context,
        operation: () async {
          final response = await ApiService.get(
            '/onboarding/placement-test/generate',
            queryParameters: {'language': language},
          );

          if (response.statusCode == 200) {
            test.value = response.data['data'];
            isGenerating.value = false;
          } else {
            throw Exception('Failed to generate test');
          }
        },
        errorContext: 'generateTest',
        showError: true,
      );
      isGenerating.value = false;
    }

    Future<void> submitTest() async {
      final questionsLength = (test.value?['questions'] as List?)?.length ?? 0;
      if (answers.value.length < questionsLength) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please answer all questions')),
        );
        return;
      }

      isLoading.value = true;
      await safeAsync(
        context: context,
        operation: () async {
          final answerList = (test.value?['questions'] as List).asMap().entries.map((entry) {
            return {
              'question_id': (entry.value as Map)['id'],
              'answer': answers.value[entry.key] ?? '',
            };
          }).toList();

          final response = await ApiService.post(
            '/onboarding/placement-test/submit',
            data: {
              'test_id': test.value?['test_id'],
              'language': language,
              'answers': answerList,
              'test_questions': test.value?['questions'],
            },
          );

          if (response.statusCode == 200) {
            result.value = response.data['data'];
          } else {
            throw Exception('Failed to submit test');
          }
        },
        errorContext: 'submitTest',
        showError: true,
      );
      isLoading.value = false;
    }

    useEffect(() {
      generateTest();
      return null;
    }, []);

    if (isGenerating.value) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: PanAfricanSpacing.lg),
              Text(
                'Generating your placement test...',
                style: PanAfricanTypography.bodyLarge(context),
              ),
            ],
          ),
        ),
      );
    }

    if (result.value != null) {
      return _buildResultsScreen(context, result.value!, isDark);
    }

    if (test.value == null) {
      return Scaffold(
        body: Center(
          child: Text('Failed to load test'),
        ),
      );
    }

    final questions = test.value!['questions'] as List;
    final currentQuestion = questions[currentQuestionIndex.value] as Map<String, dynamic>;
    final isLoadingOverlay = useState(false);

    return LoadingOverlay(
      isLoading: isLoadingOverlay.value,
      message: 'Loading test...',
      child: Scaffold(
        appBar: AppBar(
          title: Text('Placement Test'),
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
          child: Column(
            children: [
              // Progress
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                child: LinearProgressIndicator(
                  value: (currentQuestionIndex.value + 1) / questions.length,
                  backgroundColor: PanAfricanColors.neutralLight,
                  valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                'Question ${currentQuestionIndex.value + 1} of ${questions.length}',
                style: PanAfricanTypography.labelMedium(context),
              ),

              // Question
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(PanAfricanSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQuestion['question'] ?? '',
                        style: PanAfricanTypography.headlineSmall(context),
                      ),
                      SizedBox(height: PanAfricanSpacing.lg),

                      // Answer Options
                      if (currentQuestion['type'] == 'multiple_choice' &&
                          currentQuestion['options'] != null)
                        ...(currentQuestion['options'] as List).asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          final isSelected = answers.value[currentQuestionIndex.value] == option;

                          return Card(
                            margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                            color: isSelected
                                ? PanAfricanColors.primary
                                : (isDark
                                    ? PanAfricanColors.cardDark
                                    : PanAfricanColors.cardLight),
                            child: ListTile(
                              title: Text(
                                option,
                                style: PanAfricanTypography.bodyMedium(context).copyWith(
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: Colors.white)
                                  : null,
                              onTap: () {
                                answers.value = {
                                  ...answers.value,
                                  currentQuestionIndex.value: option,
                                };
                                HapticFeedback.mediumImpact();
                              },
                            ),
                          );
                        }),

                      // Text Input for other question types
                      if (currentQuestion['type'] != 'multiple_choice')
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Your Answer',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? PanAfricanColors.surfaceContainerDark
                                : PanAfricanColors.surfaceContainerLight,
                          ),
                          onChanged: (value) {
                            answers.value = {
                              ...answers.value,
                              currentQuestionIndex.value: value,
                            };
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Navigation Buttons
              Container(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Row(
                  children: [
                    if (currentQuestionIndex.value > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            currentQuestionIndex.value--;
                            HapticFeedback.lightImpact();
                          },
                          child: Text('Previous'),
                        ),
                      ),
                    if (currentQuestionIndex.value > 0)
                      SizedBox(width: PanAfricanSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: currentQuestionIndex.value < questions.length - 1
                            ? () {
                                currentQuestionIndex.value++;
                                HapticFeedback.mediumImpact();
                              }
                            : (isLoading.value ? null : submitTest),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PanAfricanColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                        ),
                        child: isLoading.value
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                currentQuestionIndex.value < questions.length - 1
                                    ? 'Next'
                                    : 'Submit',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen(
    BuildContext context,
    Map<String, dynamic> result,
    bool isDark,
  ) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: PanAfricanGradients.celebration,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.xl),
            child: Column(
              children: [
                Text(
                  'Placement Test Complete!',
                  style: PanAfricanTypography.displayMedium(context)
                      .copyWith(color: Colors.white),
                ),
                SizedBox(height: PanAfricanSpacing.xl),
                Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    result['cefr_level'] ?? 'A1',
                    style: PanAfricanTypography.displayLarge(context)
                        .copyWith(color: PanAfricanColors.primary),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xl),
                Text(
                  'Your Proficiency Level',
                  style: PanAfricanTypography.titleLarge(context)
                      .copyWith(color: Colors.white),
                ),
                SizedBox(height: PanAfricanSpacing.xl),

                // Strengths
                if (result['strengths'] != null)
                  _buildSection(
                    context,
                    'Strengths',
                    result['strengths'] as List,
                    PanAfricanColors.success,
                    isDark,
                  ),

                // Weaknesses
                if (result['weaknesses'] != null)
                  _buildSection(
                    context,
                    'Areas for Improvement',
                    result['weaknesses'] as List,
                    PanAfricanColors.warning,
                    isDark,
                  ),

                // Recommendations
                if (result['recommendations'] != null)
                  _buildSection(
                    context,
                    'Recommendations',
                    result['recommendations'] as List,
                    PanAfricanColors.primary,
                    isDark,
                  ),

                SizedBox(height: PanAfricanSpacing.xl),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: PanAfricanColors.primary,
                    minimumSize: Size(double.infinity, 50.h),
                  ),
                  child: Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List items,
    Color color,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.lg),
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: PanAfricanTypography.titleLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          ...items.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 20.sp),
                  SizedBox(width: PanAfricanSpacing.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}


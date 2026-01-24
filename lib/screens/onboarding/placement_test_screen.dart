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
import 'package:lingafriq/services/placement_test_service.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/dio_provider.dart' show client;
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/models/placement_question.dart';

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

    // Helpers for placement result (used in submitTest). The previously removed
    // _getStrengths / _getWeaknesses / _getRecommendations duplicates are not needed:
    // they were defined after submitTest and caused "referenced before declared".
    // These declarations above submitTest fix that.
    List<String> getStrengths(PlacementResult r) {
      if (r.score >= 70) return ['Strong vocabulary foundation', 'Good understanding of basic grammar'];
      if (r.score >= 50) return ['Basic vocabulary knowledge'];
      return ['Willingness to learn'];
    }
    List<String> getWeaknesses(PlacementResult r) {
      if (r.score < 50) return ['Need to build vocabulary', 'Grammar fundamentals needed'];
      if (r.score < 70) return ['Some grammar concepts need review'];
      return [];
    }
    List<String> getRecommendations(PlacementResult r) {
      final level = r.level;
      if (level == 'A1' || level == 'A2') return ['Start with beginner lessons', 'Focus on vocabulary building', 'Practice pronunciation daily'];
      if (level == 'B1' || level == 'B2') return ['Continue with intermediate content', 'Practice conversation skills', 'Expand vocabulary in specific topics'];
      return ['Advanced lessons recommended', 'Focus on fluency and nuance', 'Engage with native content'];
    }

    Future<void> generateTest() async {
      isGenerating.value = true;
      try {
        // Try to fetch from backend first, fallback to local if it fails
        List<PlacementQuestion> questions;
        try {
          final dio = ref.read(client);
          final response = await dio.get(
            '${Api.baseurl}onboarding/placement-test/generate',
            queryParameters: {'language': language},
          );
          
          if (response.statusCode == 200 && response.data != null) {
            final data = response.data is Map ? response.data : (response.data['data'] ?? {});
            final questionsList = (data['questions'] as List?) ?? [];
            
            // Convert backend format to PlacementQuestion objects
            questions = questionsList.map((q) {
              final qMap = q as Map<String, dynamic>;
              return PlacementQuestion(
                id: qMap['id'] ?? '',
                languageCode: qMap['languageCode'] ?? language,
                level: qMap['level'] ?? 'A1',
                skill: qMap['skill'] ?? 'vocab',
                prompt: qMap['prompt'] ?? '',
                options: (qMap['options'] as List).cast<String>(),
                correctIndex: qMap['correctIndex'] ?? 0,
              );
            }).toList();
            
            logger.info('Placement test generated from backend', context: {
              'language': language,
              'questionCount': questions.length,
            });
          } else {
            throw Exception('Invalid response from backend');
          }
        } catch (backendError) {
          // Fallback to local service if backend fails
          logger.warn('Backend placement test generation failed, using local service', error: backendError);
          questions = await PlacementTestService.loadQuestionsForLanguage(ref, language);
        }

        if (questions.isEmpty) {
          throw Exception('No questions available for $language');
        }

        // Convert to the format expected by the UI
        test.value = {
          'test_id': '${DateTime.now().millisecondsSinceEpoch}',
          'language': language,
          'questions': questions.map((q) => {
                'id': q.id,
                'question': q.prompt,
                'type': 'multiple_choice',
                'options': q.options,
                'correct_index': q.correctIndex,
              }).toList(),
        };
        isGenerating.value = false;
      } catch (e) {
        isGenerating.value = false;
        // Don't show error dialog - let the UI handle it by showing the failure screen
        logger.error('Failed to generate placement test', error: e);
        // test.value remains null, which will trigger the failure screen
      }
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
      try {
        // Convert questions to PlacementQuestion objects for evaluation
        final questions = (test.value?['questions'] as List).map((q) {
          final qMap = q as Map<String, dynamic>;
          return PlacementQuestion(
            id: qMap['id'] ?? '',
            languageCode: language,
            level: 'A1', // Default level
            skill: 'vocab', // Default skill
            prompt: qMap['question'] ?? '',
            options: (qMap['options'] as List).cast<String>(),
            correctIndex: qMap['correct_index'] ?? 0,
          );
        }).toList();

        // Get selected indices from answers
        final selectedIndices = <int?>[];
        for (var i = 0; i < questions.length; i++) {
          final answer = answers.value[i];
          if (answer != null) {
            final index = questions[i].options.indexWhere((opt) => opt == answer);
            selectedIndices.add(index >= 0 ? index : null);
          } else {
            selectedIndices.add(null);
          }
        }

        // Evaluate locally
        final placementResult = PlacementTestService.evaluate(
          languageCode: language,
          questions: questions,
          selectedIndices: selectedIndices,
        );

        // Convert to result format
        result.value = {
          'cefr_level': placementResult.level,
          'score': placementResult.score,
          'total_questions': placementResult.totalQuestions,
          'correct': placementResult.correct,
          'strengths': getStrengths(placementResult),
          'weaknesses': getWeaknesses(placementResult),
          'recommendations': getRecommendations(placementResult),
        };

        // Try to sync results to backend (non-blocking)
        try {
          await ApiService.post(
            '/onboarding/placement-test',
            data: {
              'placement_test_results': result.value,
            },
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Backend sync timeout'),
          );
        } catch (e) {
          // Log but continue - results are saved locally
          logger.warn('Failed to sync placement test results to backend', error: e);
        }
      } catch (e) {
        ErrorHandler.showError(context, e);
      } finally {
        isLoading.value = false;
      }
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
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 64.sp,
                      color: PanAfricanColors.warning,
                    ),
                    SizedBox(height: PanAfricanSpacing.xl),
                    Text(
                      'Unable to Generate Placement Test',
                      style: PanAfricanTypography.headlineSmall(context),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    Text(
                      'We couldn\'t connect to the server to generate your placement test. You can continue without it and take it later from your profile.',
                      style: PanAfricanTypography.bodyMedium(context),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: PanAfricanSpacing.xl),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PanAfricanColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50.h),
                      ),
                      child: Text('Continue Without Test'),
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    OutlinedButton(
                      onPressed: () {
                        isGenerating.value = true;
                        generateTest();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50.h),
                      ),
                      child: Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          ), // closes Column
        ), // closes SafeArea
        ), // closes Container body
      ), // closes Scaffold
    ); // closes LoadingOverlay
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


import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/audio_player_widget.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/portrait_video_player.dart';
import '../models/lesson_content.dart';

/// Quiz section widget with multiple choice questions
class QuizSectionWidget extends StatefulWidget {
  final LessonContent content;
  final Function(int questionId, String answer) onAnswerSelected;
  final Function(int questionId, String answer) onCheckAnswer;
  final VoidCallback onFinish;
  final bool Function(int questionId)? isAnswerChecked;
  final bool Function(int questionId, String option)? isAnswerCorrect;

  const QuizSectionWidget({
    super.key,
    required this.content,
    required this.onAnswerSelected,
    required this.onCheckAnswer,
    required this.onFinish,
    this.isAnswerChecked,
    this.isAnswerCorrect,
  });

  @override
  State<QuizSectionWidget> createState() => _QuizSectionWidgetState();
}

class _QuizSectionWidgetState extends State<QuizSectionWidget>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _shakeController;
  int _currentQuestionIndex = 0;
  final Map<int, String?> _selectedAnswers = {};
  final Map<int, bool> _checkedAnswers = {};

  @override
  void initState() {
    super.initState();
    final qs = widget.content.questions;
    if (kDebugMode && qs != null && qs.length > 1) {
      final ids = qs.map((e) => e.id).toSet();
      assert(
        ids.length == qs.length,
        'Quiz questions must have unique ids (duplicate undermines state maps).',
      );
    }
    _pageController = PageController();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _selectAnswer(int questionId, String answer) {
    setState(() {
      _selectedAnswers[questionId] = answer;
    });
    widget.onAnswerSelected(questionId, answer);
  }

  Future<void> _checkAnswer(int questionId, String answer) async {
    if (_selectedAnswers[questionId] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an answer'),
          backgroundColor: PanAfricanColors.error,
        ),
      );
      return;
    }

    setState(() {
      _checkedAnswers[questionId] = true;
    });

    final isCorrect = widget.isAnswerCorrect?.call(questionId, answer) ?? false;
    if (!isCorrect) {
      _shakeController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _shakeController.reset();
    }

    if (!mounted) return;
    widget.onCheckAnswer(questionId, answer);
  }

  /// Page index is driven by [PageView.onPageChanged] to avoid desync with
  /// [PageController] (fixes crashes / wrong question after Next/Previous).
  Future<void> _goToNextPage(int questionCount) async {
    if (_currentQuestionIndex >= questionCount - 1) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.content.questions ?? [];
    if (questions.isEmpty) {
      return Center(
        child: Text(
          'No questions available',
          style: PanAfricanTypography.bodyLarge(context),
        ),
      );
    }

    final currentQuestion = questions[_currentQuestionIndex];
    final questionId = currentQuestion.id;
    final selectedAnswer = _selectedAnswers[questionId];
    final isChecked = _checkedAnswers[questionId] ?? false;

    return Column(
      children: [
        // Progress indicator
        if (questions.length > 1)
          Semantics(
            label: 'Question ${_currentQuestionIndex + 1} of ${questions.length}. ${((_currentQuestionIndex + 1) / questions.length * 100).toInt()} percent complete.',
            value: '${((_currentQuestionIndex + 1) / questions.length * 100).toInt()}%',
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                    style: PanAfricanTypography.labelMedium(context),
                  ),
                  const Spacer(),
                  Text(
                    '${((_currentQuestionIndex + 1) / questions.length * 100).toInt()}%',
                    style: PanAfricanTypography.labelMedium(context).copyWith(
                      color: PanAfricanColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Question content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() {
                _currentQuestionIndex = index;
              });
            },
            itemCount: questions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(questions[index], index == _currentQuestionIndex);
            },
          ),
        ),

        // Navigation buttons
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: Semantics(
                      label: 'Previous question',
                      button: true,
                      child: PanAfricanButton(
                        onPressed: () async {
                          await _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        label: 'Previous',
                        icon: Icons.arrow_back_rounded,
                        backgroundColor: PanAfricanColors.cardDark,
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                if (_currentQuestionIndex > 0) SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: Semantics(
                    label: isChecked
                        ? (_currentQuestionIndex == questions.length - 1
                            ? 'Finish quiz'
                            : 'Next question')
                        : 'Check answer',
                    button: true,
                    enabled: isChecked || selectedAnswer != null,
                    child: PanAfricanButton(
                      onPressed: isChecked
                          ? () async {
                              if (_currentQuestionIndex == questions.length - 1) {
                                if (!mounted) return;
                                widget.onFinish();
                              } else {
                                await _goToNextPage(questions.length);
                              }
                            }
                          : (selectedAnswer != null
                              ? () => _checkAnswer(questionId, selectedAnswer)
                              : null),
                      label: isChecked
                          ? (_currentQuestionIndex == questions.length - 1
                              ? 'Finish'
                              : 'Next')
                          : 'Check',
                      icon: isChecked && _currentQuestionIndex < questions.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      backgroundColor: PanAfricanColors.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(QuizQuestion question, bool isActive) {
    if (!isActive) return const SizedBox.shrink();

    final questionId = question.id;
    final selectedAnswer = _selectedAnswers[questionId];
    final isChecked = _checkedAnswers[questionId] ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question media
          if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
            PanAfricanCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: PanAfricanRadius.lgBR,
                child: CachedNetworkImage(
                  imageUrl: question.imageUrl!,
                  placeholder: (context, url) => Container(
                    height: 200.h,
                    color: PanAfricanColors.cardDark,
                    child: Center(
                      child: CircularProgressIndicator(color: PanAfricanColors.primary),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200.h,
                    color: PanAfricanColors.cardDark,
                    child: Icon(Icons.error_outline, color: PanAfricanColors.error),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          if (question.audioUrl != null && question.audioUrl!.isNotEmpty) ...[
            PanAfricanCard(
              padding: EdgeInsets.all(16.w),
              child: AudioPlayerWidget(audioUrl: question.audioUrl!),
            ),
            SizedBox(height: 16.h),
          ],

          if (question.videoUrl != null && question.videoUrl!.isNotEmpty) ...[
            PanAfricanCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: PanAfricanRadius.lgBR,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: PortraitPlayerPage(videoUrl: question.videoUrl!),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Question text
          Semantics(
            label: 'Question. ${question.question}',
            header: true,
            child: PanAfricanCard(
              hasGradientBorder: true,
              gradientStart: PanAfricanColors.secondary,
              gradientEnd: PanAfricanColors.tertiary,
              padding: EdgeInsets.all(20.w),
              child: Text(
                question.question,
                style: PanAfricanTypography.headlineSmall(context),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final optionLabel = String.fromCharCode(65 + index); // A, B, C, D
            final isSelected = selectedAnswer == option.text;
            final showCorrect = isChecked && option.isCorrect;
            final showIncorrect = isChecked && isSelected && !option.isCorrect;

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: showIncorrect
                        ? Offset(
                            10 * _shakeController.value * (1 - _shakeController.value) * 2,
                            0,
                          )
                        : Offset.zero,
                    child: Semantics(
                      label: 'Answer option $optionLabel: ${option.text}. ${isSelected ? 'Selected' : ''}',
                      button: true,
                      selected: isSelected,
                      child: PanAfricanCard(
                        onTap: isChecked
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                _selectAnswer(questionId, option.text);
                              },
                        backgroundColor: showCorrect
                          ? PanAfricanColors.success.withOpacity(0.15)
                          : showIncorrect
                              ? PanAfricanColors.error.withOpacity(0.15)
                              : isSelected
                                  ? PanAfricanColors.primary.withOpacity(0.15)
                                  : null,
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          // Option label
                          Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: showCorrect
                                  ? PanAfricanColors.success
                                  : showIncorrect
                                      ? PanAfricanColors.error
                                      : isSelected
                                          ? PanAfricanColors.primary
                                          : PanAfricanColors.borderLight,
                            ),
                            child: Center(
                              child: Text(
                                optionLabel,
                                style: PanAfricanTypography.labelLarge(context).copyWith(
                                  color: (showCorrect || showIncorrect || isSelected)
                                      ? Colors.white
                                      : null,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Option text
                          Expanded(
                            child: Text(
                              option.text,
                              style: PanAfricanTypography.bodyLarge(context).copyWith(
                                color: showCorrect
                                    ? PanAfricanColors.success
                                    : showIncorrect
                                        ? PanAfricanColors.error
                                        : null,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                          // Status icon
                          if (isChecked)
                            Icon(
                              showCorrect
                                  ? Icons.check_circle_rounded
                                  : showIncorrect
                                      ? Icons.cancel_rounded
                                      : null,
                              color: showCorrect
                                  ? PanAfricanColors.success
                                  : showIncorrect
                                      ? PanAfricanColors.error
                                      : null,
                              size: 24.sp,
                            ),
                        ],
                      ),
                    ),
                  ),
                  );
                },
              ),
            );
          }),

          // Hint (if available and not checked)
          if (question.hint != null && question.hint!.isNotEmpty && !isChecked) ...[
            SizedBox(height: 16.h),
            PanAfricanCard(
              padding: EdgeInsets.all(16.w),
              backgroundColor: PanAfricanColors.secondary.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: PanAfricanColors.secondary),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      question.hint!,
                      style: PanAfricanTypography.bodyMedium(context).copyWith(
                        color: PanAfricanColors.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Fun fact (if available and checked)
          if (question.funFact != null &&
              question.funFact!.isNotEmpty &&
              isChecked) ...[
            SizedBox(height: 16.h),
            PanAfricanCard(
              padding: EdgeInsets.all(16.w),
              backgroundColor: PanAfricanColors.tertiary.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: PanAfricanColors.tertiary),
                      SizedBox(width: 12.w),
                      Text(
                        'Fun Fact',
                        style: PanAfricanTypography.labelLarge(context).copyWith(
                          color: PanAfricanColors.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    question.funFact!,
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

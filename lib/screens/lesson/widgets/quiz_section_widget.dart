import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/widgets/bidi_text.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/audio_player_widget.dart';
import 'package:lingafriq/widgets/content/vocab_audio_controls.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/portrait_video_player.dart';
import '../models/lesson_content.dart';
import 'package:lingafriq/models/quiz_model.dart';

/// Quiz section widget with multiple choice questions
class QuizSectionWidget extends StatefulWidget {
  final LessonContent content;
  final Function(int questionId, String answer) onAnswerSelected;
  final Function(int questionId, String answer) onCheckAnswer;
  final VoidCallback onFinish;
  final bool Function(int questionId)? isAnswerChecked;
  final bool Function(int questionId, String option)? isAnswerCorrect;
  final String? vocabAudioLanguage;
  final String? vocabAudioText;

  const QuizSectionWidget({
    super.key,
    required this.content,
    required this.onAnswerSelected,
    required this.onCheckAnswer,
    required this.onFinish,
    this.isAnswerChecked,
    this.isAnswerCorrect,
    this.vocabAudioLanguage,
    this.vocabAudioText,
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
    final qs = _bankQuestions;
    if (kDebugMode && qs.length > 1) {
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

  List<QuizQuestion> get _bankQuestions {
    final raw = widget.content.questions ?? [];
    return [
      for (final question in raw)
        if (QuizModel.fromChoice(
              system: 'unit_quiz',
              id: 'unit.${question.id}',
              prompt: question.question,
              choices: [
                for (final option in question.options)
                  {'text': option.text, 'correct_answer': option.isCorrect},
              ],
              hint: question.hint,
              funFact: question.funFact,
              refs: [
                if (question.audioUrl != null && question.audioUrl!.isNotEmpty)
                  question.audioUrl!,
                if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
                  question.imageUrl!,
              ],
            ) !=
            null)
          question,
    ];
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
          content: Text(l10nOf(context).lessonPickFirst),
          backgroundColor: PanAfricanColors.error,
        ),
      );
      return;
    }

    setState(() {
      _checkedAnswers[questionId] = true;
    });

    final isCorrect = widget.isAnswerCorrect?.call(questionId, answer) ?? false;
    final reducedMotion = mounted
        ? MediaQuery.disableAnimationsOf(context)
        : false;
    if (!isCorrect && !reducedMotion) {
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
      duration: _pageTransitionDuration(),
      curve: Curves.easeInOut,
    );
  }

  /// Instant (zero-duration) transitions when the learner has reduced motion
  /// enabled at the OS level; otherwise our standard 300ms glide.
  Duration _pageTransitionDuration() {
    if (!mounted) return const Duration(milliseconds: 300);
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 300);
  }

  /// Mirrors forward/back iconography for RTL locales (Arabic, Darija) so
  /// "next" visually points the way text actually flows.
  IconData _directionalIcon(
    BuildContext context, {
    required IconData ltr,
    required IconData rtl,
  }) {
    return Directionality.of(context) == TextDirection.rtl ? rtl : ltr;
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final questions = _bankQuestions;
    if (questions.isEmpty) {
      return PanAfricanEmptyState(
        icon: Icons.quiz_outlined,
        title: l.lessonNotReadyTitle,
        description: l.lessonNotReadyBody,
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
            label: l.lessonQuestionProgress(
              _currentQuestionIndex + 1,
              questions.length,
              ((_currentQuestionIndex + 1) / questions.length * 100).toInt(),
            ),
            value:
                '${((_currentQuestionIndex + 1) / questions.length * 100).toInt()}%',
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Text(
                    l.lessonQuestionOf(
                      _currentQuestionIndex + 1,
                      questions.length,
                    ),
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
              return _buildQuestionCard(
                questions[index],
                index == _currentQuestionIndex,
              );
            },
          ),
        ),

        // Navigation buttons, inside the answer feedback panel once checked
        // (lesson-flow pack: tinted bottom banner with the verdict).
        LessonFeedbackPanel(
          checked: isChecked,
          correct:
              isChecked &&
              selectedAnswer != null &&
              (widget.isAnswerCorrect?.call(questionId, selectedAnswer) ??
                  false),
          correctAnswer: currentQuestion.options
              .where((o) => o.isCorrect)
              .map((o) => o.text)
              .firstOrNull,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: Semantics(
                        label: l.lessonPreviousQuestion,
                        button: true,
                        child: PanAfricanButton(
                          onPressed: () async {
                            await _pageController.previousPage(
                              duration: _pageTransitionDuration(),
                              curve: Curves.easeInOut,
                            );
                          },
                          label: l.lessonPrevious,
                          icon: _directionalIcon(
                            context,
                            ltr: Icons.arrow_back_rounded,
                            rtl: Icons.arrow_forward_rounded,
                          ),
                          backgroundColor: PanAfricanColors.cardDark,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: Semantics(
                      label: isChecked
                          ? (_currentQuestionIndex == questions.length - 1
                                ? l.lessonFinishQuiz
                                : l.lessonNextQuestion)
                          : l.lessonCheckAnswer,
                      button: true,
                      enabled: isChecked || selectedAnswer != null,
                      child: PanAfricanButton(
                        onPressed: isChecked
                            ? () async {
                                if (_currentQuestionIndex ==
                                    questions.length - 1) {
                                  if (!mounted) return;
                                  widget.onFinish();
                                } else {
                                  await _goToNextPage(questions.length);
                                }
                              }
                            : (selectedAnswer != null
                                  ? () =>
                                        _checkAnswer(questionId, selectedAnswer)
                                  : null),
                        label: isChecked
                            ? (_currentQuestionIndex == questions.length - 1
                                  ? l.lessonFinish
                                  : l.lessonNext)
                            : l.lessonCheck,
                        icon:
                            isChecked &&
                                _currentQuestionIndex < questions.length - 1
                            ? _directionalIcon(
                                context,
                                ltr: Icons.arrow_forward_rounded,
                                rtl: Icons.arrow_back_rounded,
                              )
                            : Icons.check_rounded,
                        backgroundColor: PanAfricanColors.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
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

    final l = l10nOf(context);
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
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: PanAfricanColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200.h,
                    color: PanAfricanColors.cardDark,
                    child: const Icon(
                      Icons.error_outline,
                      color: PanAfricanColors.error,
                    ),
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
            label: l.lessonQuestionLabel(question.question),
            header: true,
            child: PanAfricanCard(
              hasGradientBorder: true,
              gradientStart: PanAfricanColors.secondary,
              gradientEnd: PanAfricanColors.tertiary,
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BidiText(
                    question.question,
                    style: PanAfricanTypography.headlineSmall(context),
                  ),
                  if (widget.vocabAudioLanguage != null &&
                      widget.vocabAudioText != null &&
                      widget.vocabAudioText!.trim().isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    VocabAudioControls(
                      language: widget.vocabAudioLanguage!,
                      text: widget.vocabAudioText!,
                      compact: true,
                    ),
                  ],
                ],
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
                  final reducedMotion = MediaQuery.disableAnimationsOf(context);
                  return Transform.translate(
                    offset: showIncorrect && !reducedMotion
                        ? Offset(
                            10 *
                                _shakeController.value *
                                (1 - _shakeController.value) *
                                2,
                            0,
                          )
                        : Offset.zero,
                    child: Semantics(
                      label: [
                        l.lessonOptionLabel(optionLabel, option.text),
                        if (isSelected) l.lessonOptionSelected,
                      ].join(' '),
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
                            ? PanAfricanColors.success.withValues(alpha: 0.15)
                            : showIncorrect
                            ? PanAfricanColors.error.withValues(alpha: 0.15)
                            : isSelected
                            ? PanAfricanColors.primary.withValues(alpha: 0.15)
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
                                // White-on-fill lettering needs a solid enough
                                // background to clear WCAG AA; the flat
                                // "success" green is too light for that, so the
                                // correct state reuses our (darker) brand
                                // primary green instead.
                                color: showCorrect
                                    ? Theme.of(context).colorScheme.primary
                                    : showIncorrect
                                    ? PanAfricanColors.error
                                    : isSelected
                                    ? PanAfricanColors.primary
                                    : PanAfricanColors.borderLight,
                              ),
                              child: Center(
                                child: Text(
                                  optionLabel,
                                  style:
                                      PanAfricanTypography.labelLarge(
                                        context,
                                      ).copyWith(
                                        color:
                                            (showCorrect ||
                                                showIncorrect ||
                                                isSelected)
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
                              child: BidiText(
                                option.text,
                                style: PanAfricanTypography.bodyLarge(context).copyWith(
                                  // AA-safe text colors: the flat success/error
                                  // tokens are too light for WCAG body text, so
                                  // we use their high-contrast theme analogues.
                                  color: showCorrect
                                      ? Theme.of(context).colorScheme.primary
                                      : showIncorrect
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer
                                      : null,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
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
          if (question.hint != null &&
              question.hint!.isNotEmpty &&
              !isChecked) ...[
            SizedBox(height: 16.h),
            Semantics(
              label: l.lessonHintLabel(question.hint!),
              child: PanAfricanCard(
                padding: EdgeInsets.all(16.w),
                backgroundColor: PanAfricanColors.secondary.withValues(
                  alpha: 0.1,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: PanAfricanColors.secondary,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: BidiText(
                        question.hint!,
                        style: PanAfricanTypography.bodyMedium(context)
                            .copyWith(
                              // "secondary" (gold) is too light to read as body
                              // text on a near-white card — this on-container
                              // token keeps the warm gold feel at AA contrast.
                              color: PanAfricanColors.onSecondaryContainer,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Fun fact (if available and checked)
          if (question.funFact != null &&
              question.funFact!.isNotEmpty &&
              isChecked) ...[
            SizedBox(height: 16.h),
            Semantics(
              label: '${l.lessonFunFact}: ${question.funFact!}',
              child: PanAfricanCard(
                padding: EdgeInsets.all(16.w),
                backgroundColor: PanAfricanColors.tertiary.withValues(
                  alpha: 0.1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: PanAfricanColors.tertiary,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          l.lessonFunFact,
                          style: PanAfricanTypography.labelLarge(context)
                              .copyWith(
                                // "tertiary" (sunset orange) fails AA on a light
                                // card; the on-container token keeps the warm
                                // tone readable.
                                color: PanAfricanColors.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    BidiText(
                      question.funFact!,
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Verdict banner under a checked answer: green for correct, coral for
/// incorrect with the right answer spelled out. Wraps the action button so
/// the next step sits inside the verdict, as in the reference pack.
class LessonFeedbackPanel extends StatelessWidget {
  const LessonFeedbackPanel({
    super.key,
    required this.checked,
    required this.correct,
    required this.child,
    this.correctAnswer,
  });

  final bool checked;
  final bool correct;
  final String? correctAnswer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!checked) return child;
    final l = l10nOf(context);
    final bg = correct
        ? PanAfricanColors.primaryContainer
        : PanAfricanColors.tertiaryContainer;
    final fg = correct
        ? PanAfricanColors.onPrimaryContainer
        : PanAfricanColors.onTertiaryContainer;
    final accent = correct
        ? PanAfricanColors.primary
        : PanAfricanColors.kenteRed;
    final title = correct ? l.lessonCorrectTitle : l.lessonIncorrectTitle;
    final body = correct
        ? l.lessonCorrectBody
        : (correctAnswer == null
              ? null
              : l.lessonCorrectAnswer(correctAnswer!));
    final panel = Container(
      key: Key(
        correct ? 'lesson-feedback-correct' : 'lesson-feedback-incorrect',
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            container: true,
            label: [title, ?body].join('. '),
            excludeSemantics: true,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.w, 16.w, 16.w, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      correct ? Icons.check_rounded : Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: PanAfricanTypography.titleLarge(
                            context,
                          ).copyWith(color: fg, fontWeight: FontWeight.w800),
                        ),
                        if (body != null) ...[
                          SizedBox(height: 2.w),
                          Text(
                            body,
                            style: PanAfricanTypography.bodyMedium(
                              context,
                            ).copyWith(color: fg),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return panel;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (_, t, c) =>
          FractionalTranslation(translation: Offset(0, t * 0.3), child: c),
      child: panel,
    );
  }
}

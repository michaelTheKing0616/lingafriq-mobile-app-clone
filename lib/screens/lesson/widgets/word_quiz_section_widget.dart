import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/content/vocab_audio_controls.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import '../models/lesson_content.dart';

/// Word quiz section widget with fill-in-the-blank functionality
class WordQuizSectionWidget extends StatefulWidget {
  final LessonContent content;
  final Function(int blankIndex, String? answer) onAnswerChanged;
  final VoidCallback onCheck;
  final List<String?>? currentAnswers;
  final String? audioLanguage;

  const WordQuizSectionWidget({
    super.key,
    required this.content,
    required this.onAnswerChanged,
    required this.onCheck,
    this.currentAnswers,
    this.audioLanguage,
  });

  @override
  State<WordQuizSectionWidget> createState() => _WordQuizSectionWidgetState();
}

class _WordQuizSectionWidgetState extends State<WordQuizSectionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  final Map<int, String?> _answers = {};
  List<String> _availableChoices = [];
  bool _isChecked = false;
  final Map<int, bool> _blankCorrectness = {};

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initializeChoices();
    if (widget.currentAnswers != null) {
      for (int i = 0; i < widget.currentAnswers!.length; i++) {
        _answers[i] = widget.currentAnswers![i];
      }
    }
  }

  void _initializeChoices() {
    final questions = widget.content.wordQuestions ?? [];
    if (questions.isEmpty) return;

    // Extract all possible answers from questions
    final allAnswers = <String>{};
    for (final question in questions) {
      // Parse answer from question format (e.g., "question/answer")
      final parts = question.question.split('/');
      if (parts.length > 1) {
        allAnswers.add(parts.last.trim());
      }
    }

    // Add some distractors (simplified - in production, get from backend)
    _availableChoices = allAnswers.toList()..shuffle();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _selectChoice(String choice) {
    // Find first empty blank
    final questions = widget.content.wordQuestions ?? [];
    for (int i = 0; i < questions.length; i++) {
      if (_answers[i] == null) {
        setState(() {
          _answers[i] = choice;
        });
        widget.onAnswerChanged(i, choice);
        HapticFeedback.selectionClick();
        return;
      }
    }
  }

  void _removeAnswer(int blankIndex) {
    setState(() {
      _answers[blankIndex] = null;
    });
    widget.onAnswerChanged(blankIndex, null);
    HapticFeedback.selectionClick();
  }

  Future<void> _checkAnswers() async {
    if (_answers.values.any((a) => a == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A few blanks are still empty — fill them in and try again.',
          ),
          backgroundColor: PanAfricanColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isChecked = true;
    });

    final questions = widget.content.wordQuestions ?? [];
    bool allCorrect = true;

    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final userAnswer = _answers[i]?.trim() ?? '';
      final parts = question.question.split('/');
      final correctAnswer = parts.length > 1 ? parts.last.trim() : '';

      final isCorrect = userAnswer.toLowerCase() == correctAnswer.toLowerCase();
      _blankCorrectness[i] = isCorrect;

      if (!isCorrect) {
        allCorrect = false;
      }
    }

    final reducedMotion = mounted
        ? MediaQuery.disableAnimationsOf(context)
        : false;
    if (!allCorrect && !reducedMotion) {
      _shakeController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 500));
      _shakeController.reset();
    }

    widget.onCheck();
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.content.wordQuestions ?? [];
    if (questions.isEmpty) {
      return const PanAfricanEmptyState(
        icon: Icons.edit_note_rounded,
        title: "Nothing to fill in yet",
        description:
            "We're still preparing this fill-in-the-blank practice. Please check back in a moment.",
      );
    }

    // Build sentence with blanks
    final sentenceParts = <Widget>[];
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final userAnswer = _answers[i];
      final isCorrect = _blankCorrectness[i] ?? false;
      final isIncorrect = _isChecked && !isCorrect && userAnswer != null;

      // Add content before blank
      if (question.content.isNotEmpty) {
        sentenceParts.add(
          Text(
            question.content,
            style: PanAfricanTypography.bodyLarge(context),
          ),
        );
      }

      // Add blank
      final blankIndex = i;
      sentenceParts.add(
        Semantics(
          label: userAnswer != null
              ? 'Blank ${blankIndex + 1}, filled with $userAnswer. Tap to clear.'
              : 'Empty blank ${blankIndex + 1}. Tap a word below to fill it in.',
          button: userAnswer != null,
          child: GestureDetector(
            onTap: userAnswer != null ? () => _removeAnswer(blankIndex) : null,
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final reducedMotion = MediaQuery.disableAnimationsOf(context);
                return Transform.translate(
                  offset: isIncorrect && !reducedMotion
                      ? Offset(
                          10 *
                              _shakeController.value *
                              (1 - _shakeController.value) *
                              2,
                          0,
                        )
                      : Offset.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 80.w,
                      minHeight: AdaptiveLayout.minTouchTarget.h,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? PanAfricanColors.success.withValues(alpha: 0.15)
                            : isIncorrect
                            ? PanAfricanColors.error.withValues(alpha: 0.15)
                            : PanAfricanColors.cardDark,
                        border: Border.all(
                          color: isCorrect
                              ? PanAfricanColors.success
                              : isIncorrect
                              ? PanAfricanColors.error
                              : PanAfricanColors.borderLight,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        userAnswer ?? '____',
                        style: PanAfricanTypography.bodyLarge(context).copyWith(
                          // AA-safe text colors (the flat success/error fills
                          // are too light to read reliably as body text).
                          color: isCorrect
                              ? Theme.of(context).colorScheme.primary
                              : isIncorrect
                              ? Theme.of(context).colorScheme.onErrorContainer
                              : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // Get unused choices
    final usedChoices = _answers.values.whereType<String>().toSet();
    final unusedChoices = _availableChoices
        .where((c) => !usedChoices.contains(c))
        .toList();

    final audioPhrase = _primaryAudioPhrase(questions);
    final lang = widget.audioLanguage?.trim();

    return Column(
      children: [
        if (lang != null && lang.isNotEmpty && audioPhrase.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: Row(
              children: [
                Text(
                  'Listen',
                  style: PanAfricanTypography.labelMedium(context),
                ),
                SizedBox(width: 8.w),
                VocabAudioControls(
                  language: lang,
                  text: audioPhrase,
                  compact: true,
                ),
              ],
            ),
          ),
        // Sentence with blanks
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: PanAfricanCard(
              padding: EdgeInsets.all(20.w),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: sentenceParts,
              ),
            ),
          ),
        ),

        // Word bank
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            // This bar is pinned to the bottom, so its shadow must fall
            // upward onto the content above -- none of the PanAfricanShadows
            // presets support a negative offset. We keep that directional
            // requirement but adopt the same brand shadow color
            // (neutralDarkest) and the nearest defined opacity step (lg's
            // 0.08) that every other PanAfricanShadows variant uses, instead
            // of an unbranded raw Colors.black.
            boxShadow: [
              BoxShadow(
                color: PanAfricanColors.neutralDarkest.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Word Bank',
                style: PanAfricanTypography.labelLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: unusedChoices.map((choice) {
                  return Semantics(
                    label: 'Select answer: $choice',
                    button: true,
                    child: GestureDetector(
                      onTap: () => _selectChoice(choice),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: AdaptiveLayout.minTouchTarget.h,
                        ),
                        child: PanAfricanCard(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          backgroundColor: PanAfricanColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Center(
                            child: Text(
                              choice,
                              style: PanAfricanTypography.bodyMedium(context)
                                  .copyWith(
                                    color: PanAfricanColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Check button
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Semantics(
              label: _isChecked ? 'All correct' : 'Check answers',
              button: true,
              child: PanAfricanButton(
                width: double.infinity,
                onPressed: _isChecked ? null : _checkAnswers,
                label: _isChecked ? 'All Correct!' : 'Check',
                icon: _isChecked
                    ? Icons.check_circle_rounded
                    : Icons.check_rounded,
                // Brand primary (not flat "success") so the white label text
                // clears WCAG AA against the fill.
                backgroundColor: PanAfricanColors.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _primaryAudioPhrase(List<WordQuizQuestion> questions) {
    if (questions.isEmpty) return '';
    final parts = <String>[];
    for (final q in questions) {
      final segments = q.question.split('/');
      if (segments.length > 1) {
        parts.add(segments.last.trim());
      }
    }
    return parts.join(' ');
  }
}

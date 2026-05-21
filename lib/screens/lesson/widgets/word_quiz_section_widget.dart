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
        SnackBar(
          content: Text('Please fill in all blanks'),
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

    if (!allCorrect) {
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
      return Center(
        child: Text(
          'No word quiz questions available',
          style: PanAfricanTypography.bodyLarge(context),
        ),
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
      sentenceParts.add(
        GestureDetector(
          onTap: userAnswer != null ? () => _removeAnswer(i) : null,
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              return Transform.translate(
                offset: isIncorrect
                    ? Offset(
                        10 * _shakeController.value * (1 - _shakeController.value) * 2,
                        0,
                      )
                    : Offset.zero,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? PanAfricanColors.success.withOpacity(0.15)
                        : isIncorrect
                            ? PanAfricanColors.error.withOpacity(0.15)
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
                  constraints: BoxConstraints(minWidth: 80.w),
                  child: Center(
                    child: Text(
                      userAnswer ?? '____',
                      style: PanAfricanTypography.bodyLarge(context).copyWith(
                        color: isCorrect
                            ? PanAfricanColors.success
                            : isIncorrect
                                ? PanAfricanColors.error
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
      );
    }

    // Get unused choices
    final usedChoices = _answers.values.whereType<String>().toSet();
    final unusedChoices = _availableChoices.where((c) => !usedChoices.contains(c)).toList();

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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                style: PanAfricanTypography.labelLarge(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                      child: PanAfricanCard(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        backgroundColor: PanAfricanColors.primary.withOpacity(0.1),
                        child: Text(
                          choice,
                          style: PanAfricanTypography.bodyMedium(context).copyWith(
                            color: PanAfricanColors.primary,
                            fontWeight: FontWeight.w600,
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
                icon: _isChecked ? Icons.check_circle_rounded : Icons.check_rounded,
              backgroundColor: _isChecked
                  ? PanAfricanColors.success
                  : PanAfricanColors.primary,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/placement_question.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/services/placement_test_service.dart';
import 'package:lingafriq/services/localization_service.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';

class PlacementQuizScreen extends HookConsumerWidget {
  final VoidCallback onComplete;

  const PlacementQuizScreen({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingProvider);
    final languageCode = (onboarding.selectedLanguage ?? 'swahili').toLowerCase();
    final localization = ref.read(localizationProvider);

    return FutureBuilder<List<PlacementQuestion>>(
      future: PlacementTestService.loadQuestionsForLanguage(ref as Ref, languageCode),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final questions = snapshot.data ?? const <PlacementQuestion>[];
        if (questions.isEmpty) {
          return Scaffold(
            body: Center(
              child: Text(
                'Placement questions are not available right now. Please try again later.',
                style: TextStyle(fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return _PlacementQuizScaffold(
          languageCode: languageCode,
          questions: questions,
          localization: localization,
          onFinished: (result) {
            final notifier = ref.read(onboardingProvider.notifier);
            notifier.updatePlacementTest(result.toMap());

            // Optionally seed initial proficiency from placement level
            notifier.updateProficiency(result.level);
            notifier.saveOnboardingData();

            onComplete();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _PlacementQuizScaffold extends StatefulWidget {
  final String languageCode;
  final List<PlacementQuestion> questions;
  final void Function(PlacementResult) onFinished;
  final LocalizationService localization;

  const _PlacementQuizScaffold({
    Key? key,
    required this.languageCode,
    required this.questions,
    required this.onFinished,
    required this.localization,
  }) : super(key: key);

  @override
  State<_PlacementQuizScaffold> createState() => _PlacementQuizScaffoldState();
}

class _PlacementQuizScaffoldState extends State<_PlacementQuizScaffold> {
  int _currentIndex = 0;
  late List<int?> _answers;

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.filled(widget.questions.length, null);
  }

  void _selectOption(int optionIndex) {
    setState(() {
      _answers[_currentIndex] = optionIndex;
    });
    HapticFeedback.lightImpact();
  }

  void _next() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      final result = PlacementTestService.evaluate(
        languageCode: widget.languageCode,
        questions: widget.questions,
        selectedIndices: _answers,
      );
      widget.onFinished(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = widget.localization;
    final q = widget.questions[_currentIndex];
    final selected = _answers[_currentIndex];
    final progress = ( _currentIndex + 1 ) / (widget.questions.isEmpty ? 1 : widget.questions.length);

    return Scaffold(
      backgroundColor:
          isDark ? AfricanTheme.backgroundDark : AfricanTheme.backgroundLight,
      body: Container(
        decoration: AfricanTheme.kentePattern(
          isDark ? AfricanTheme.backgroundDark : AfricanTheme.backgroundLight,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header and progress (title localized via Polie)
                FutureBuilder<String>(
                  future: loc.t(
                    key: 'placement.title',
                    english: 'Placement Test',
                  ),
                  builder: (context, snapshot) {
                    final title = snapshot.data ?? 'Placement Test';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AfricanTheme.textLight
                                : AfricanTheme.textDark,
                          ),
                        ),
                        Text(
                          '${_currentIndex + 1} / ${widget.questions.length}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 1.5.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(AfricanTheme.primaryGreen),
                  ),
                ),
                SizedBox(height: 3.h),

                // Question card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: isDark ? AfricanTheme.stitchCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                      boxShadow: DesignSystem.shadowLarge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.prompt,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Expanded(
                          child: ListView.separated(
                            itemCount: q.options.length,
                            separatorBuilder: (_, __) => SizedBox(height: 1.h),
                            itemBuilder: (context, index) {
                              final option = q.options[index];
                              final isSelected = selected == index;
                              return InkWell(
                                onTap: () => _selectOption(index),
                                borderRadius: BorderRadius.circular(DesignSystem.radiusL),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AfricanTheme.primaryGreen.withOpacity(0.15)
                                        : (isDark ? AfricanTheme.stitchBorderDark : Colors.grey[100]),
                                    borderRadius: BorderRadius.circular(DesignSystem.radiusL),
                                    border: Border.all(
                                      color: isSelected
                                          ? AfricanTheme.primaryGreen
                                          : (isDark
                                              ? AfricanTheme.stitchBorderDark
                                              : Colors.grey[300]!),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AfricanTheme.primaryGreen
                                                : Colors.grey[500]!,
                                          ),
                                          color: isSelected
                                              ? AfricanTheme.primaryGreen
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                                            : null,
                                      ),
                                      SizedBox(width: 2.w),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 2.h),

                // Next button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selected == null ? null : _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: AfricanTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                      ),
                    ),
                    child: Text(
                      _currentIndex == widget.questions.length - 1 ? 'Finish' : 'Next',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/placement_question.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/services/placement_test_service.dart';
import 'package:lingafriq/services/localization_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),
                  Text(
                    'Loading placement test...',
                    style: PanAfricanTypography.bodyLarge(context),
                  ),
                ],
              ),
            ),
          );
        }
        final questions = snapshot.data ?? const <PlacementQuestion>[];
        if (questions.isEmpty) {
          return Scaffold(
            backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 64.sp,
                      color: PanAfricanColors.warning,
                    ),
                    SizedBox(height: PanAfricanSpacing.lg),
                    Text(
                      'Placement questions are not available right now.',
                      style: PanAfricanTypography.titleMedium(context),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(
                      'Please try again later.',
                      style: PanAfricanTypography.bodyMedium(context, color: PanAfricanColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: PanAfricanSpacing.xl),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PanAfricanColors.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        minimumSize: Size(200.w, 50.h),
                      ),
                      child: Text('Go Back'),
                    ),
                  ],
                ),
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
          isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
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
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
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
                          style: PanAfricanTypography.titleLarge(context),
                        ),
                        Text(
                          '${_currentIndex + 1} / ${widget.questions.length}',
                          style: PanAfricanTypography.labelMedium(
                            context,
                            color: isDark
                                ? PanAfricanColors.textSecondaryDark
                                : PanAfricanColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: PanAfricanSpacing.md),
                ClipRRect(
                  borderRadius: PanAfricanRadius.roundBR,
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(PanAfricanColors.primary),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Question card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(PanAfricanSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                      borderRadius: PanAfricanRadius.xlBR,
                      boxShadow: PanAfricanShadows.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.prompt,
                          style: PanAfricanTypography.titleMedium(context),
                        ),
                        SizedBox(height: PanAfricanSpacing.lg),
                        Expanded(
                          child: ListView.separated(
                            itemCount: q.options.length,
                            separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.sm),
                            itemBuilder: (context, index) {
                              final option = q.options[index];
                              final isSelected = selected == index;
                              return InkWell(
                                onTap: () => _selectOption(index),
                                borderRadius: PanAfricanRadius.lgBR,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: PanAfricanSpacing.md,
                                    vertical: PanAfricanSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? PanAfricanColors.primary.withOpacity(0.15)
                                        : (isDark
                                            ? PanAfricanColors.surfaceContainerDark
                                            : PanAfricanColors.surfaceContainerLight),
                                    borderRadius: PanAfricanRadius.lgBR,
                                    border: Border.all(
                                      color: isSelected
                                          ? PanAfricanColors.primary
                                          : (isDark
                                              ? PanAfricanColors.borderDark
                                              : PanAfricanColors.borderLight),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22.w,
                                        height: 22.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? PanAfricanColors.primary
                                                : PanAfricanColors.neutralMedium,
                                          ),
                                          color: isSelected
                                              ? PanAfricanColors.primary
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? Icon(Icons.check, size: 16.sp, color: Theme.of(context).colorScheme.onPrimary)
                                            : null,
                                      ),
                                      SizedBox(width: PanAfricanSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: PanAfricanTypography.bodyMedium(context),
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
                SizedBox(height: PanAfricanSpacing.lg),

                // Next button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selected == null
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            _next();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: PanAfricanColors.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: PanAfricanRadius.roundBR,
                      ),
                    ),
                    child: Text(
                      _currentIndex == widget.questions.length - 1 ? 'Finish' : 'Next',
                      style: PanAfricanTypography.labelLarge(context, color: Theme.of(context).colorScheme.onPrimary),
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


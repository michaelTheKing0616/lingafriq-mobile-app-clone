import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';

class TonalLessonScreen extends ConsumerStatefulWidget {
  const TonalLessonScreen({super.key});

  @override
  ConsumerState<TonalLessonScreen> createState() => _TonalLessonScreenState();
}

class _TonalLessonScreenState extends ConsumerState<TonalLessonScreen> {
  int _currentQuestion = 0;
  int? _selectedOption;

  static const _questions = [
    _TonalQuestion(
      word: 'Ọkọ̀',
      definition: 'A hoe used for farming',
      imageIcon: Icons.agriculture_rounded,
      language: 'Yoruba',
      cefr: 'A2',
      options: ['Low-High', 'Mid-High', 'Mid-Low'],
      correctIndex: 2,
    ),
    _TonalQuestion(
      word: 'Ọkọ́',
      definition: 'Husband / spouse',
      imageIcon: Icons.favorite_rounded,
      language: 'Yoruba',
      cefr: 'A1',
      options: ['Low-High', 'Mid-High', 'Mid-Low'],
      correctIndex: 0,
    ),
    _TonalQuestion(
      word: 'Ọkọ',
      definition: 'Vehicle / canoe',
      imageIcon: Icons.directions_car_rounded,
      language: 'Yoruba',
      cefr: 'A1',
      options: ['Low-High', 'Mid-High', 'Mid-Low'],
      correctIndex: 1,
    ),
    _TonalQuestion(
      word: 'Àgbọ̀n',
      definition: 'Coconut',
      imageIcon: Icons.eco_rounded,
      language: 'Yoruba',
      cefr: 'B1',
      options: ['Low-High', 'Mid-High', 'Mid-Low'],
      correctIndex: 2,
    ),
  ];

  _TonalQuestion get _current => _questions[_currentQuestion];

  void _selectOption(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedOption = index);
  }

  void _check() {
    if (_selectedOption == null) return;
    HapticFeedback.mediumImpact();
    final correct = _selectedOption == _current.correctIndex;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? 'Correct! 🎉' : 'Not quite — try again!'),
        backgroundColor: correct
            ? ModernGriotColors.secondary
            : ModernGriotColors.error,
        duration: const Duration(seconds: 1),
      ),
    );
    if (correct && _currentQuestion < _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _currentQuestion++;
          _selectedOption = null;
        });
      });
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedOption = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              _buildHeader(cs),
              SizedBox(height: 20.h),
              _buildVocabCard(cs),
              SizedBox(height: 24.h),
              _buildOptionsGrid(cs),
              const Spacer(),
              _buildProgressDots(cs),
              SizedBox(height: 16.h),
              _buildFooterButtons(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.arrow_back_rounded,
              size: 24.sp, color: cs.onSurface),
        ),
        SizedBox(width: 12.w),
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withAlpha(40),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.psychology_rounded,
              size: 20.sp, color: cs.primary),
        ),
        SizedBox(width: 8.w),
        Text('TONAL DRILL',
            style: ModernGriotTypography.labelLarge(
                context: context, color: cs.primary)),
        const Spacer(),
        Text(
          '${_currentQuestion + 1}/${_questions.length}',
          style: ModernGriotTypography.labelMedium(
              context: context, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildVocabCard(ColorScheme cs) {
    final q = _current;
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(20.r),
      child: Column(
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(30),
              borderRadius: ModernGriotRadius.borderXl,
            ),
            child: Icon(q.imageIcon, size: 36.sp, color: cs.primary),
          ),
          SizedBox(height: 16.h),
          Text(q.word,
              style: ModernGriotTypography.headlineLarge(context: context)),
          SizedBox(height: 8.h),
          Text(q.definition,
              style: ModernGriotTypography.bodyMedium(context: context),
              textAlign: TextAlign.center),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GriotChip(label: q.language),
              SizedBox(width: 8.w),
              GriotChip(label: q.cefr, selected: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid(ColorScheme cs) {
    return Row(
      children: List.generate(_current.options.length, (i) {
        final selected = _selectedOption == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left: i == 0 ? 0 : 6.w, right: i == 2 ? 0 : 6.w),
            child: GestureDetector(
              onTap: () => _selectOption(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary
                      : cs.surfaceContainerLow,
                  borderRadius: ModernGriotRadius.borderXl,
                  boxShadow: selected
                      ? ModernGriotShadows.glow(cs.primary)
                      : ModernGriotShadows.sm,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? cs.onPrimary
                              : cs.outlineVariant,
                          width: 2,
                        ),
                        color: selected
                            ? cs.onPrimary
                            : Colors.transparent,
                      ),
                      child: selected
                          ? Icon(Icons.check,
                              size: 14.sp, color: cs.primary)
                          : null,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _current.options[i],
                      style: ModernGriotTypography.labelMedium(
                        context: context,
                        color: selected
                            ? cs.onPrimary
                            : cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProgressDots(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_questions.length, (i) {
        final isCurrent = i == _currentQuestion;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: isCurrent ? 24.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: isCurrent ? cs.primary : cs.surfaceContainerHighest,
            borderRadius: ModernGriotRadius.borderPill,
          ),
        );
      }),
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      children: [
        Expanded(
          child: GriotSecondaryButton(
            label: 'SKIP',
            icon: Icons.skip_next_rounded,
            onPressed: _skip,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GriotGradientButton(
            label: 'CHECK',
            icon: Icons.check_rounded,
            onPressed: _selectedOption != null ? _check : null,
          ),
        ),
      ],
    );
  }
}

class _TonalQuestion {
  const _TonalQuestion({
    required this.word,
    required this.definition,
    required this.imageIcon,
    required this.language,
    required this.cefr,
    required this.options,
    required this.correctIndex,
  });

  final String word;
  final String definition;
  final IconData imageIcon;
  final String language;
  final String cefr;
  final List<String> options;
  final int correctIndex;
}

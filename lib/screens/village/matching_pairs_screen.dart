import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';

class MatchingPairsScreen extends ConsumerStatefulWidget {
  const MatchingPairsScreen({super.key});

  @override
  ConsumerState<MatchingPairsScreen> createState() =>
      _MatchingPairsScreenState();
}

class _MatchingPairsScreenState extends ConsumerState<MatchingPairsScreen> {
  int _score = 0;
  int _secondsElapsed = 0;
  int? _selectedLeft;
  int? _selectedRight;
  final Set<int> _matchedIndices = {};

  static const _pairs = [
    ('Ọmọ', 'Child'),
    ('Ilé', 'House'),
    ('Omi', 'Water'),
    ('Oúnjẹ', 'Food'),
    ('Ẹ̀gbọ́n', 'Sibling'),
    ('Ọjà', 'Market'),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _secondsElapsed++);
      return _matchedIndices.length < _pairs.length;
    });
  }

  String get _timerText {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _selectLeft(int index) {
    if (_matchedIndices.contains(index)) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedLeft = index);
    _checkPair();
  }

  void _selectRight(int index) {
    if (_matchedIndices.contains(index)) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedRight = index);
    _checkPair();
  }

  void _checkPair() {
    if (_selectedLeft != null &&
        _selectedRight != null &&
        _selectedLeft == _selectedRight) {
      HapticFeedback.mediumImpact();
      setState(() {
        _matchedIndices.add(_selectedLeft!);
        _score += 10;
        _selectedLeft = null;
        _selectedRight = null;
      });
    }
  }

  void _confirmPair() {
    if (_selectedLeft == null || _selectedRight == null) return;
    if (_selectedLeft == _selectedRight) {
      HapticFeedback.heavyImpact();
      setState(() {
        _matchedIndices.add(_selectedLeft!);
        _score += 10;
        _selectedLeft = null;
        _selectedRight = null;
      });
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedLeft = null;
        _selectedRight = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      body: Stack(
        children: [
          _decorativeBlobs(cs),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(cs),
                SizedBox(height: 16.h),
                Expanded(child: _buildGrid(cs)),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildCheckFab(cs),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back_rounded,
                size: 24.sp, color: cs.onSurface),
          ),
          SizedBox(width: 12.w),
          Text('Matching Pairs',
              style: ModernGriotTypography.titleMedium(context: context)),
          const Spacer(),
          GriotBadgePill(
            label: '$_score pts',
            icon: Icons.star_rounded,
            color: ModernGriotColors.primaryContainer,
            textColor: ModernGriotColors.onPrimaryContainer,
          ),
          SizedBox(width: 8.w),
          GriotBadgePill(
            label: _timerText,
            icon: Icons.timer_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('Yoruba',
                    style: ModernGriotTypography.labelMedium(
                        context: context, color: cs.primary)),
                SizedBox(height: 8.h),
                ...List.generate(
                    _pairs.length, (i) => _tile(i, _pairs[i].$1, true, cs)),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              children: [
                Text('English',
                    style: ModernGriotTypography.labelMedium(
                        context: context, color: cs.secondary)),
                SizedBox(height: 8.h),
                ...List.generate(
                    _pairs.length, (i) => _tile(i, _pairs[i].$2, false, cs)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(int index, String text, bool isLeft, ColorScheme cs) {
    final matched = _matchedIndices.contains(index);
    final selected = isLeft
        ? _selectedLeft == index
        : _selectedRight == index;

    Color bg;
    Color borderColor;
    double opacity;
    if (matched) {
      bg = ModernGriotColors.secondaryContainer.withAlpha(150);
      borderColor = cs.secondary;
      opacity = 0.6;
    } else if (selected) {
      bg = cs.surfaceContainerLowest;
      borderColor = cs.primary;
      opacity = 1.0;
    } else {
      bg = cs.surfaceContainerLowest;
      borderColor = Colors.transparent;
      opacity = 1.0;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: GestureDetector(
        onTap: () => isLeft ? _selectLeft(index) : _selectRight(index),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: double.infinity,
            padding:
                EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: ModernGriotRadius.borderXl,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: ModernGriotShadows.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: ModernGriotTypography.titleSmall(
                        context: context),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (matched)
                  Icon(Icons.check_circle_rounded,
                      size: 18.sp, color: cs.secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckFab(ColorScheme cs) {
    final enabled = _selectedLeft != null && _selectedRight != null;
    return FloatingActionButton.large(
      onPressed: enabled ? _confirmPair : null,
      backgroundColor:
          enabled ? cs.secondary : cs.surfaceContainerHighest,
      elevation: 0,
      shape: const CircleBorder(),
      child: Icon(
        Icons.check_rounded,
        size: 32.sp,
        color: enabled ? cs.onSecondary : cs.onSurfaceVariant,
      ),
    );
  }

  Widget _decorativeBlobs(ColorScheme cs) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              left: -40.w,
              top: 120.h,
              child: _blur(80.r, cs.primaryContainer.withAlpha(40)),
            ),
            Positioned(
              right: -30.w,
              bottom: 180.h,
              child: _blur(70.r, cs.secondaryContainer.withAlpha(35)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blur(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

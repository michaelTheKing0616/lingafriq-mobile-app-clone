import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class TribalDuelScreen extends ConsumerStatefulWidget {
  const TribalDuelScreen({super.key});

  @override
  ConsumerState<TribalDuelScreen> createState() => _TribalDuelScreenState();
}

class _TribalDuelScreenState extends ConsumerState<TribalDuelScreen>
    with SingleTickerProviderStateMixin {
  int _selectedAnswer = -1;
  late AnimationController _timerController;

  static const _answers = [
    'To love',
    'To run',
    'To eat',
    'To sleep',
  ];

  static const _leftChat = [
    _DuelChat('Amina', 'Let\'s go Eagles! 🦅'),
    _DuelChat('Kwame', 'Easy question — kupenda!'),
    _DuelChat('Lila', 'We got this!'),
  ];

  static const _rightChat = [
    _DuelChat('Jabari', 'Dragons hold strong! 🐉'),
    _DuelChat('Nia', 'Think carefully...'),
    _DuelChat('Omar', 'We can win this round'),
  ];

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GriotScaffold(
      floatingActionButton: _buildTotemFab(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 12.h),
                    _buildVsBanner(context),
                    SizedBox(height: 20.h),
                    _buildCountdownTimer(context),
                    SizedBox(height: 20.h),
                    _buildQuestionCard(context),
                    SizedBox(height: 16.h),
                    _buildAnswerOptions(context),
                    SizedBox(height: 16.h),
                    _buildSubmitButton(context),
                    SizedBox(height: 24.h),
                    _buildDualChat(context),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerLow,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Icon(Icons.close_rounded, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tribal Duel',
                    style: ModernGriotTypography.titleSmall()),
                Row(
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text('LIVE · Round 3/5',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
                        )),
                  ],
                ),
              ],
            ),
          ),
          GriotBadgePill(label: 'Q3', bounce: true),
        ],
      ),
    );
  }

  Widget _buildVsBanner(BuildContext context) {
    return SizedBox(
      height: 130.h,
      child: Row(
        children: [
          Expanded(child: _buildTeamCard('Eagles', '🦅', 3, 2840)),
          SizedBox(width: 8.w),
          Transform.rotate(
            angle: pi / 12,
            child: Container(
              width: 52.r,
              height: 52.r,
              decoration: BoxDecoration(
                gradient: ModernGriotGradients.signatureGradient,
                shape: BoxShape.circle,
                boxShadow: ModernGriotShadows.fab,
              ),
              child: Center(
                child: Text('VS',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    )),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(child: _buildTeamCard('Dragons', '🐉', 5, 2620)),
        ],
      ),
    );
  }

  Widget _buildTeamCard(String name, String emoji, int rank, int score) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: 28.sp)),
          SizedBox(height: 4.h),
          Text(name, style: ModernGriotTypography.titleSmall()),
          Text('Rank #$rank',
              style: ModernGriotTypography.bodySmall()),
          SizedBox(height: 4.h),
          Text('$score',
              style: ModernGriotTypography.headlineSmall(
                  color: ModernGriotColors.primary)),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer(BuildContext context) {
    return AnimatedBuilder(
      animation: _timerController,
      builder: (context, _) {
        final remaining = 30 - (30 * _timerController.value).round();
        final isUrgent = remaining <= 10;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isUrgent
                ? const Color(0xFFEF4444).withAlpha(15)
                : ModernGriotColors.surfaceContainerLow,
            borderRadius: ModernGriotRadius.borderPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_rounded,
                size: 20.sp,
                color: isUrgent
                    ? const Color(0xFFEF4444)
                    : ModernGriotColors.primaryContainer,
              ),
              SizedBox(width: 8.w),
              Text(
                '00:${remaining.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: isUrgent
                      ? const Color(0xFFEF4444)
                      : ModernGriotColors.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard(BuildContext context) {
    return GriotCard(
      surfaceLevel: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: ModernGriotColors.primary.withAlpha(15),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Text('VOCABULARY CHALLENGE',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: ModernGriotColors.primary,
                  letterSpacing: 1.0,
                )),
          ),
          SizedBox(height: 14.h),
          Text('What does "Kupenda" mean?',
              style: ModernGriotTypography.titleLarge()),
          SizedBox(height: 6.h),
          Text('Select the correct English translation.',
              style: ModernGriotTypography.bodySmall()),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(BuildContext context) {
    return Column(
      children: _answers.asMap().entries.map((e) {
        final idx = e.key;
        final text = e.value;
        final isSelected = _selectedAnswer == idx;
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedAnswer = idx);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? ModernGriotColors.primary.withAlpha(12)
                    : ModernGriotColors.surfaceContainerLow,
                borderRadius: ModernGriotRadius.borderXl,
                border: Border.all(
                  color: isSelected
                      ? ModernGriotColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.r,
                    height: 24.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? ModernGriotColors.primary
                          : ModernGriotColors.surfaceContainerHighest,
                    ),
                    child: isSelected
                        ? Icon(Icons.check_rounded,
                            size: 14.sp, color: Colors.white)
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Text(text,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: ModernGriotColors.onSurface,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return GriotGradientButton(
      label: 'SUBMIT ANSWER',
      icon: Icons.send_rounded,
      onPressed: _selectedAnswer >= 0
          ? () => HapticFeedback.heavyImpact()
          : null,
    );
  }

  Widget _buildDualChat(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live Team Chat', style: ModernGriotTypography.titleSmall()),
        SizedBox(height: 10.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildChatStream(
                  'Eagles 🦅', _leftChat, ModernGriotColors.primary),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildChatStream(
                  'Dragons 🐉', _rightChat, const Color(0xFF7B5733)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatStream(
      String label, List<_DuelChat> messages, Color accent) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: ModernGriotTypography.labelSmall(color: accent)),
          SizedBox(height: 6.h),
          ...messages.map((m) {
            return Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.author,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      )),
                  Text(m.text,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: ModernGriotColors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotemFab() {
    return GestureDetector(
      onTap: () => HapticFeedback.heavyImpact(),
      child: Container(
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded,
                size: 22.sp, color: const Color(0xFF3A1500)),
            Text('TOTEM',
                style: TextStyle(
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF3A1500),
                  letterSpacing: 0.8,
                )),
          ],
        ),
      ),
    );
  }
}

class _DuelChat {
  const _DuelChat(this.author, this.text);
  final String author;
  final String text;
}

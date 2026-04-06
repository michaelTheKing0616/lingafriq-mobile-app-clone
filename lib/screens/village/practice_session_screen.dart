import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/navigation/village_navigation.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';

class PracticeSessionScreen extends ConsumerStatefulWidget {
  const PracticeSessionScreen({super.key});

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen>
    with TickerProviderStateMixin {
  bool _micOn = true;
  bool _cameraOn = true;
  bool _focusToolOpen = false;
  int _activeSpeaker = 0;
  int _secondsElapsed = 0;
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  static const _participants = [
    _SessionParticipant('Amina K.', true),
    _SessionParticipant('Kwame O.', false),
    _SessionParticipant('Zuri M.', false),
    _SessionParticipant('You', false),
  ];

  static const _focusPhrase = _PronunciationFocus(
    target: 'Bá mi sọ̀rọ̀',
    translation: 'Talk to me',
    tip: 'Rising tone on sọ̀rọ̀',
  );

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _startTimer();
    _rotateActiveSpeaker();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _secondsElapsed++);
      return true;
    });
  }

  void _rotateActiveSpeaker() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;
      setState(() => _activeSpeaker = Random().nextInt(_participants.length));
      return true;
    });
  }

  String get _timerText {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleFocusTool() {
    HapticFeedback.lightImpact();
    setState(() => _focusToolOpen = !_focusToolOpen);
    if (_focusToolOpen) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),
            _buildTopBar(cs),
            SizedBox(height: 12.h),
            Expanded(child: _buildVideoGridWithOverlay(cs)),
            SizedBox(height: 12.h),
            _buildBottomBar(cs),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back_rounded,
                size: 24.sp, color: cs.onSurface),
          ),
          SizedBox(width: 12.w),
          _buildLiveBadge(),
          const Spacer(),
          GriotBadgePill(
            label: _timerText,
            icon: Icons.timer_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: ModernGriotColors.error.withAlpha(20),
            borderRadius: ModernGriotRadius.borderPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ModernGriotColors.error.withAlpha(
                    (180 + 75 * _pulseController.value).round(),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Text('LIVE',
                  style: ModernGriotTypography.labelMedium(
                      context: context,
                      color: ModernGriotColors.error)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoGridWithOverlay(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Stack(
        children: [
          _buildVideoGrid(cs),
          if (_focusToolOpen)
            Positioned(
              right: 0,
              bottom: 16.h,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildFocusTool(cs),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(ColorScheme cs) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _videoTile(0, cs)),
              SizedBox(width: 8.w),
              Expanded(child: _videoTile(1, cs)),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _videoTile(2, cs)),
              SizedBox(width: 8.w),
              Expanded(child: _videoTile(3, cs)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _videoTile(int index, ColorScheme cs) {
    final p = _participants[index];
    final isActive = index == _activeSpeaker;
    final glowColor = const Color(0xFFD4A017);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: ModernGriotRadius.borderXl,
        border: isActive
            ? Border.all(color: glowColor, width: 2.5)
            : Border.all(color: Colors.transparent, width: 2.5),
        boxShadow: isActive
            ? ModernGriotShadows.glow(glowColor)
            : ModernGriotShadows.sm,
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.person_rounded,
                size: 48.sp, color: cs.onSurfaceVariant.withAlpha(80)),
          ),
          Positioned(
            left: 10.w,
            bottom: 10.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: cs.inverseSurface.withAlpha(180),
                borderRadius: ModernGriotRadius.borderPill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    Icon(Icons.graphic_eq_rounded,
                        size: 12.sp, color: glowColor),
                  if (isActive) SizedBox(width: 4.w),
                  Text(p.name,
                      style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: cs.onInverseSurface)),
                ],
              ),
            ),
          ),
          if (isActive)
            Positioned(
              right: 10.w,
              top: 10.h,
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: glowColor.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mic_rounded,
                    size: 14.sp, color: glowColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFocusTool(ColorScheme cs) {
    return GriotGlassPanel(
      padding: EdgeInsets.all(14.r),
      borderRadius: ModernGriotRadius.borderXl,
      child: SizedBox(
        width: 210.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.center_focus_strong_rounded,
                    size: 16.sp, color: cs.primary),
                SizedBox(width: 6.w),
                Text('Focus Phrase',
                    style: ModernGriotTypography.labelMedium(
                        context: context, color: cs.primary)),
              ],
            ),
            SizedBox(height: 10.h),
            Text(_focusPhrase.target,
                style: ModernGriotTypography.titleLarge(context: context)),
            SizedBox(height: 4.h),
            Text(_focusPhrase.translation,
                style: ModernGriotTypography.bodySmall(context: context)),
            SizedBox(height: 6.h),
            Text(_focusPhrase.tip,
                style: ModernGriotTypography.labelSmall(
                    context: context, color: cs.secondary)),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: ModernGriotGradients.signatureGradient,
                    borderRadius: ModernGriotRadius.borderPill,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          size: 18.sp, color: ModernGriotColors.onPrimary),
                      SizedBox(width: 4.w),
                      Text('Play',
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: ModernGriotColors.onPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme cs) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: ModernGriotRadius.borderPill,
        boxShadow: ModernGriotShadows.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(
            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: 'Mic',
            active: _micOn,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _micOn = !_micOn);
            },
            cs: cs,
          ),
          _controlButton(
            icon: _cameraOn
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label: 'Camera',
            active: _cameraOn,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _cameraOn = !_cameraOn);
            },
            cs: cs,
          ),
          _controlButton(
            icon: Icons.center_focus_strong_rounded,
            label: 'Focus',
            active: _focusToolOpen,
            onTap: _toggleFocusTool,
            cs: cs,
          ),
          _endButton(cs),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: active
                  ? cs.primary.withAlpha(25)
                  : cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 22.sp,
                color: active ? cs.primary : cs.onSurfaceVariant),
          ),
          SizedBox(height: 3.h),
          Text(label,
              style: TextStyle(
                  fontSize: 10.sp, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _endButton(ColorScheme cs) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pushReplacementNamed(
          '/${VillageRouteNames.sessionSummary}',
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: const BoxDecoration(
              color: ModernGriotColors.error,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.call_end_rounded,
                size: 22.sp, color: ModernGriotColors.onError),
          ),
          SizedBox(height: 3.h),
          Text('End',
              style: TextStyle(
                  fontSize: 10.sp, color: ModernGriotColors.error)),
        ],
      ),
    );
  }
}

class _SessionParticipant {
  const _SessionParticipant(this.name, this.isSpeaking);
  final String name;
  final bool isSpeaking;
}

class _PronunciationFocus {
  const _PronunciationFocus({
    required this.target,
    required this.translation,
    required this.tip,
  });
  final String target;
  final String translation;
  final String tip;
}

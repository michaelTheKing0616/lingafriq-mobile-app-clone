import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

// ---------------------------------------------------------------------------
// Mock status segments
// ---------------------------------------------------------------------------

class _StatusSegment {
  const _StatusSegment({
    required this.targetPhrase,
    required this.pronunciation,
    required this.translation,
    required this.badge,
  });

  final String targetPhrase;
  final String pronunciation;
  final String translation;
  final String badge;
}

const _mockSegments = <_StatusSegment>[
  _StatusSegment(
    targetPhrase: 'Ẹ kú àárọ̀',
    pronunciation: '/ɛ kú àːɾɔ̀/',
    translation: 'Good morning',
    badge: 'A1 Beginner',
  ),
  _StatusSegment(
    targetPhrase: 'Báwo ni?',
    pronunciation: '/bá.wɔ̃ ni/',
    translation: 'How are you?',
    badge: 'Daily Streak 🔥',
  ),
  _StatusSegment(
    targetPhrase: 'Mo dúpẹ́',
    pronunciation: '/mɔ dúpɛ́/',
    translation: 'Thank you',
    badge: 'A2 Elementary',
  ),
  _StatusSegment(
    targetPhrase: 'Odabọ̀',
    pronunciation: '/ɔ.da.bɔ̀/',
    translation: 'Goodbye',
    badge: 'Phrase Master',
  ),
];

const _emojiReactions = ['❤️', '🔥', '👏', '😮', '😂'];
const _segmentDuration = Duration(seconds: 5);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class WaStatusViewScreen extends ConsumerStatefulWidget {
  const WaStatusViewScreen({super.key, required this.statusId});

  final String statusId;

  @override
  ConsumerState<WaStatusViewScreen> createState() =>
      _WaStatusViewScreenState();
}

class _WaStatusViewScreenState extends ConsumerState<WaStatusViewScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _autoTimer;
  late AnimationController _progressController;
  final _replyController = TextEditingController();

  int get _totalSegments => _mockSegments.length;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _segmentDuration,
    )..addStatusListener(_onProgressDone);
    _startSegmentTimer();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _progressController.dispose();
    _replyController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startSegmentTimer() {
    _progressController
      ..reset()
      ..forward();
  }

  void _onProgressDone(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goNext();
    }
  }

  void _goNext() {
    if (_currentIndex < _totalSegments - 1) {
      setState(() => _currentIndex++);
      _startSegmentTimer();
    } else {
      _dismiss();
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startSegmentTimer();
    } else {
      _startSegmentTimer();
    }
  }

  void _dismiss() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final segment = _mockSegments[_currentIndex];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) _dismiss();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _background(),
            _gradientOverlay(),
            SafeArea(
              child: Column(
                children: [
                  _progressBars(),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: _tapZones(size, segment),
                  ),
                  _emojiRow(),
                  _replyBar(),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Background gradient ──────────────────────────────────────────────────

  Widget _background() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9E3D00),
            Color(0xFFFF7A35),
            Color(0xFF526124),
          ],
        ),
      ),
    );
  }

  Widget _gradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 1.0],
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withAlpha(200),
            ],
          ),
        ),
      ),
    );
  }

  // ── Progress bars ────────────────────────────────────────────────────────

  Widget _progressBars() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: List.generate(_totalSegments, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: _SegmentBar(
                filled: i < _currentIndex,
                active: i == _currentIndex,
                controller: _progressController,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Tap zones with phrase card ───────────────────────────────────────────

  Widget _tapZones(Size size, _StatusSegment segment) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = constraints.maxWidth / 2;
        return GestureDetector(
          onTapUp: (details) {
            if (details.localPosition.dx < halfWidth) {
              _goPrev();
            } else {
              _goNext();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: GriotGlassPanel(
                blurSigma: 30,
                opacity: 0.25,
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      segment.targetPhrase,
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.headlineLarge(
                        context: context,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      segment.pronunciation,
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.bodyLarge(
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      segment.translation,
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.titleMedium(
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    GriotBadgePill(
                      label: segment.badge,
                      color: ModernGriotColors.primaryContainer.withAlpha(200),
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Emoji reactions ──────────────────────────────────────────────────────

  Widget _emojiRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _emojiReactions.map((emoji) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Reply bar ────────────────────────────────────────────────────────────

  Widget _replyBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ClipRRect(
        borderRadius: ModernGriotRadius.borderPill,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: ModernGriotRadius.borderPill,
              border: Border.all(
                color: Colors.white.withAlpha(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Reply...',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: 14.sp,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_replyController.text.trim().isNotEmpty) {
                      HapticFeedback.mediumImpact();
                      _replyController.clear();
                    }
                  },
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white70,
                    size: 22.sp,
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

// ---------------------------------------------------------------------------
// Segment progress bar
// ---------------------------------------------------------------------------

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.filled,
    required this.active,
    required this.controller,
  });

  final bool filled;
  final bool active;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3.h,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(60),
        borderRadius: BorderRadius.circular(2),
      ),
      child: filled
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : active
              ? AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: controller.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                )
              : const SizedBox.shrink(),
    );
  }
}

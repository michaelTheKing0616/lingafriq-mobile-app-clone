import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class LiveClassroomMobileScreen extends ConsumerStatefulWidget {
  const LiveClassroomMobileScreen({super.key});

  @override
  ConsumerState<LiveClassroomMobileScreen> createState() =>
      _LiveClassroomMobileScreenState();
}

class _LiveClassroomMobileScreenState
    extends ConsumerState<LiveClassroomMobileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _micPulse;
  late final Animation<double> _micScale;
  bool _isMuted = false;

  static const _listeners = [
    ('Fatima B.', true),
    ('Sipho M.', false),
    ('Selam T.', true),
    ('Kofi A.', false),
    ('Ngozi E.', true),
    ('Yaw M.', false),
    ('Zainab K.', true),
    ('Thabo R.', false),
  ];

  static const _reactions = ['🔥', '🤝', '✊', '💡', '🎉', '👏'];

  @override
  void initState() {
    super.initState();
    _micPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _micScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _micPulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _micPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkScheme = ModernGriotColorScheme.dark;

    return Theme(
      data: ThemeData.dark().copyWith(colorScheme: darkScheme),
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(darkScheme),
              SizedBox(height: 16.h),
              _buildActiveSpeaker(darkScheme),
              SizedBox(height: 20.h),
              _buildLessonCard(darkScheme),
              SizedBox(height: 16.h),
              _buildReactionPills(darkScheme),
              SizedBox(height: 20.h),
              _buildListenerGrid(darkScheme),
              const Spacer(),
              _buildControlsRow(darkScheme),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Icon(Icons.arrow_back_rounded,
                color: cs.onSurface, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.r,
                  height: 6.r,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 5.w),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Yoruba Conversations',
              style: ModernGriotTypography.titleSmall(color: cs.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant, size: 22.sp),
        ],
      ),
    );
  }

  Widget _buildActiveSpeaker(ColorScheme cs) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _micScale,
          builder: (context, child) {
            return Container(
              width: 120.r,
              height: 120.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ModernGriotColorsDark.primary
                      .withAlpha((120 + 135 * _micScale.value - 135).round()),
                  width: (3 + 2 * (_micScale.value - 1.0)).r,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ModernGriotColorsDark.primary
                        .withAlpha((20 * _micScale.value).round()),
                    blurRadius: 30 * _micScale.value,
                    spreadRadius: 5 * (_micScale.value - 1.0),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Center(
            child: Container(
              width: 100.r,
              height: 100.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surfaceContainerHigh,
              ),
              child: Icon(
                _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                size: 40.sp,
                color: _isMuted
                    ? cs.onSurfaceVariant
                    : ModernGriotColorsDark.primary,
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Adeola K.',
          style: ModernGriotTypography.titleMedium(color: cs.onSurface),
        ),
        SizedBox(height: 2.h),
        Text(
          'Host · Speaking',
          style: TextStyle(
            fontSize: 12.sp,
            color: ModernGriotColorsDark.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonCard(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: ModernGriotRadius.borderXl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_rounded,
                    size: 16.sp, color: ModernGriotColorsDark.primary),
                SizedBox(width: 6.w),
                Text(
                  'Active Lesson',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: ModernGriotColorsDark.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Greetings & Introductions',
              style: ModernGriotTypography.titleSmall(color: cs.onSurface),
            ),
            SizedBox(height: 4.h),
            Text(
              'Practice everyday Yoruba greetings with proper tonal pronunciation',
              style: ModernGriotTypography.bodySmall(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionPills(ColorScheme cs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: _reactions.map((emoji) {
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => HapticFeedback.lightImpact(),
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: TextStyle(fontSize: 20.sp)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListenerGrid(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Listeners',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: ModernGriotRadius.borderPill,
                ),
                child: Text(
                  '${_listeners.length}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 0.75,
            ),
            itemCount: _listeners.length,
            itemBuilder: (context, i) {
              final listener = _listeners[i];
              return Column(
                children: [
                  Stack(
                    children: [
                      GriotAvatar(size: 40),
                      if (listener.$2)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12.r,
                            height: 12.r,
                            decoration: BoxDecoration(
                              color: ModernGriotColorsDark.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF111111),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    listener.$1.split(' ').first,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: _isMuted ? 'Unmute' : 'Mute',
            color: cs.surfaceContainerHigh,
            iconColor: cs.onSurface,
            onTap: () => setState(() => _isMuted = !_isMuted),
          ),
          _ControlButton(
            icon: Icons.back_hand_rounded,
            label: 'Raise',
            color: cs.surfaceContainerHigh,
            iconColor: cs.onSurface,
            onTap: () => HapticFeedback.mediumImpact(),
          ),
          _ControlButton(
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            color: cs.surfaceContainerHigh,
            iconColor: cs.onSurface,
            onTap: () {},
          ),
          _ControlButton(
            icon: Icons.call_end_rounded,
            label: 'Leave',
            color: const Color(0xFFE53935),
            iconColor: Colors.white,
            onTap: () => HapticFeedback.heavyImpact(),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22.sp, color: iconColor),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: label == 'Leave'
                  ? const Color(0xFFE53935)
                  : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class SpeakerQueueScreen extends ConsumerWidget {
  const SpeakerQueueScreen({super.key});

  static const _queueItems = [
    _QueuePerson('Fatima B.', 'Hausa · Level 5', true, Duration(minutes: 2, seconds: 15)),
    _QueuePerson('Sipho M.', 'Zulu · Level 3', false, Duration(minutes: 4, seconds: 30)),
    _QueuePerson('Kofi A.', 'Twi · Level 7', true, Duration(minutes: 6, seconds: 10)),
    _QueuePerson('Ngozi E.', 'Igbo · Level 4', false, Duration(minutes: 8, seconds: 45)),
    _QueuePerson('Yaw M.', 'Akan · Level 2', false, Duration(minutes: 11, seconds: 20)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(cs),
              SizedBox(height: 16.h),
              _buildStats(cs),
              SizedBox(height: 20.h),
              _buildCurrentSpeaker(cs),
              SizedBox(height: 20.h),
              _buildHostControls(cs),
              SizedBox(height: 20.h),
              _buildWaitingQueue(cs),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Row(
      children: [
        Text(
          'Speaker Queue',
          style: ModernGriotTypography.headlineSmall(),
        ),
        SizedBox(width: 10.w),
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
      ],
    );
  }

  Widget _buildStats(ColorScheme cs) {
    return Row(
      children: [
        _StatPill(
          icon: Icons.people_rounded,
          label: '23 in room',
          color: cs.surfaceContainerHigh,
          textColor: cs.onSurfaceVariant,
        ),
        SizedBox(width: 8.w),
        _StatPill(
          icon: Icons.queue_rounded,
          label: '${_queueItems.length} waiting',
          color: ModernGriotColors.primary.withAlpha(25),
          textColor: ModernGriotColors.primary,
        ),
        SizedBox(width: 8.w),
        _StatPill(
          icon: Icons.timer_rounded,
          label: '~3 min avg',
          color: ModernGriotColors.secondary.withAlpha(40),
          textColor: ModernGriotColors.secondary,
        ),
      ],
    );
  }

  Widget _buildCurrentSpeaker(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currently Speaking',
          style: ModernGriotTypography.titleSmall(),
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            gradient: ModernGriotGradients.signatureGradient,
            borderRadius: ModernGriotRadius.borderXl,
            boxShadow: ModernGriotShadows.fab,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GriotAvatar(size: 52, status: GriotAvatarStatus.online),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chidi O.',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: ModernGriotColors.onPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Igbo · Level 6',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: ModernGriotColors.onPrimary.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SpeakerTimer(),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.mic_off_rounded,
                      label: 'Mute',
                      filled: false,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Demote',
                      filled: false,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_alarm_rounded,
                      label: '+1 Min',
                      filled: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHostControls(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: ModernGriotRadius.borderXl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _HostAction(Icons.skip_next_rounded, 'Next'),
          _HostAction(Icons.shuffle_rounded, 'Shuffle'),
          _HostAction(Icons.pause_circle_rounded, 'Pause'),
          _HostAction(Icons.clear_all_rounded, 'Clear'),
        ],
      ),
    );
  }

  Widget _buildWaitingQueue(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Waiting Queue',
          style: ModernGriotTypography.titleSmall(),
        ),
        SizedBox(height: 12.h),
        ...List.generate(_queueItems.length, (i) {
          final person = _queueItems[i];
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: GriotCard(
              surfaceLevel: 1,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  _ConnectionDot(position: i),
                  SizedBox(width: 12.w),
                  Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurfaceVariant.withAlpha(120),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GriotAvatar(size: 40),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              person.name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            if (person.isPro) ...[
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: ModernGriotColors.primaryContainer,
                                  borderRadius: ModernGriotRadius.borderPill,
                                ),
                                child: Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w800,
                                    color: ModernGriotColors.onPrimaryContainer,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${person.details} · Waiting ${_formatDuration(person.waitTime)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => HapticFeedback.mediumImpact(),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                      decoration: BoxDecoration(
                        color: ModernGriotColors.primary,
                        borderRadius: ModernGriotRadius.borderPill,
                      ),
                      child: Text(
                        'Promote',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: ModernGriotColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: ModernGriotRadius.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: textColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeakerTimer extends StatefulWidget {
  @override
  State<_SpeakerTimer> createState() => _SpeakerTimerState();
}

class _SpeakerTimerState extends State<_SpeakerTimer> {
  int _seconds = 127;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _seconds++);
        _tick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final min = _seconds ~/ 60;
    final sec = _seconds % 60;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: ModernGriotRadius.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 14.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
  });

  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: filled ? Colors.white.withAlpha(40) : Colors.transparent,
          borderRadius: ModernGriotRadius.borderPill,
          border: filled
              ? null
              : Border.all(color: Colors.white.withAlpha(80), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.sp, color: Colors.white),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostAction extends StatelessWidget {
  const _HostAction(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22.sp, color: cs.onSurface),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.position});
  final int position;

  @override
  Widget build(BuildContext context) {
    final strength = 1.0 - (position * 0.15).clamp(0.0, 0.7);

    return Column(
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(
            color: ModernGriotColors.secondary.withAlpha((255 * strength).round()),
            shape: BoxShape.circle,
          ),
        ),
        if (position < 4) ...[
          Container(
            width: 2.r,
            height: 16.h,
            color: ModernGriotColors.secondary.withAlpha((60 * strength).round()),
          ),
        ],
      ],
    );
  }
}

class _QueuePerson {
  final String name;
  final String details;
  final bool isPro;
  final Duration waitTime;
  const _QueuePerson(this.name, this.details, this.isPro, this.waitTime);
}

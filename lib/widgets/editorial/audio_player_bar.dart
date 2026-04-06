import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Fixed bottom audio player bar with progress scrubber, play/pause,
/// and playback speed control.
///
/// Designed for persistent audio playback during heritage content
/// browsing. Renders a compact bar with track metadata, a seek slider,
/// transport controls, and a speed cycle button.
class AudioPlayerBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final double playbackSpeed;
  final VoidCallback? onPlayPause;
  final ValueChanged<Duration>? onSeek;
  final ValueChanged<double>? onSpeedChange;

  const AudioPlayerBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.position,
    required this.duration,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.onPlayPause,
    this.onSeek,
    this.onSpeedChange,
  });

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final totalMs = duration.inMilliseconds.toDouble();
    final currentMs =
        position.inMilliseconds.toDouble().clamp(0.0, totalMs).toDouble();

    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 10.h,
        bottom: MediaQuery.of(context).padding.bottom + 8.h,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outline.withOpacity(0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildScrubber(colors, totalMs, currentMs),
          SizedBox(height: 2.h),
          _buildTimestamps(colors, totalMs),
          SizedBox(height: 6.h),
          _buildControls(context, colors),
        ],
      ),
    );
  }

  Widget _buildScrubber(ColorScheme colors, double totalMs, double currentMs) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3.h,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.onSurface.withOpacity(0.1),
        thumbColor: colors.primary,
        overlayColor: colors.primary.withOpacity(0.12),
      ),
      child: Slider(
        min: 0,
        max: totalMs > 0 ? totalMs : 1,
        value: totalMs > 0 ? currentMs : 0,
        onChanged: (value) {
          onSeek?.call(Duration(milliseconds: value.round()));
        },
      ),
    );
  }

  Widget _buildTimestamps(ColorScheme colors, double totalMs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDuration(position),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: colors.onSurface.withOpacity(0.55),
            ),
          ),
          Text(
            _formatDuration(duration),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: colors.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, ColorScheme colors) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: colors.onSurface.withOpacity(0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        _buildSpeedButton(colors),
        SizedBox(width: 4.w),
        _buildPlayPauseButton(colors),
      ],
    );
  }

  Widget _buildSpeedButton(ColorScheme colors) {
    final label = playbackSpeed == playbackSpeed.roundToDouble()
        ? '${playbackSpeed.toInt()}x'
        : '${playbackSpeed}x';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final currentIndex = _speeds.indexOf(playbackSpeed);
        final nextIndex =
            currentIndex < 0 ? 2 : (currentIndex + 1) % _speeds.length;
        onSpeedChange?.call(_speeds[nextIndex]);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: colors.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: colors.onSurface.withOpacity(0.75),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(ColorScheme colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPlayPause?.call();
      },
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: colors.onPrimary,
          size: 26.sp,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

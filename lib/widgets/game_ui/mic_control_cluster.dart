import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class MicControlCluster extends StatelessWidget {
  final bool isRecording;
  final bool processing;
  final Duration duration;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback? onReplay;
  final VoidCallback? onSubmit;

  const MicControlCluster({
    super.key,
    required this.isRecording,
    required this.processing,
    required this.duration,
    required this.onStart,
    required this.onStop,
    this.onReplay,
    this.onSubmit,
  });

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isRecording ? 'Recording... ${_format(duration)}' : 'Ready to record',
          style: PanAfricanTypography.labelMedium(context).copyWith(
            color: isRecording ? PanAfricanColors.error : PanAfricanColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: processing ? null : (isRecording ? onStop : onStart),
              icon: processing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(isRecording ? Icons.stop_rounded : Icons.mic_rounded),
              label: Text(isRecording ? 'Stop' : 'Record'),
              style: FilledButton.styleFrom(
                backgroundColor: isRecording ? PanAfricanColors.error : PanAfricanColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            if (onReplay != null) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: processing ? null : onReplay,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Replay'),
              ),
            ],
            if (onSubmit != null) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: processing ? null : onSubmit,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Submit'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

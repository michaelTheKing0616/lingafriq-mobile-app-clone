import 'package:flutter/material.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class AudioControlCluster extends StatelessWidget {
  final bool isPlaying;
  final bool loading;
  final VoidCallback onTogglePlay;
  final VoidCallback? onReplay;
  final ValueChanged<double>? onSpeedChanged;
  final double speed;

  const AudioControlCluster({
    super.key,
    required this.isPlaying,
    required this.loading,
    required this.onTogglePlay,
    this.onReplay,
    this.onSpeedChanged,
    this.speed = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonalIcon(
          onPressed: loading ? null : onTogglePlay,
          icon: loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
          label: Text(isPlaying ? 'Pause' : 'Play'),
        ),
        const SizedBox(width: 8),
        if (onReplay != null)
          IconButton(
            onPressed: onReplay,
            icon: const Icon(Icons.replay_rounded),
            tooltip: 'Replay',
            color: PanAfricanColors.kenteBlue,
          ),
        if (onSpeedChanged != null)
          DropdownButton<double>(
            value: speed,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 0.75, child: Text('0.75x')),
              DropdownMenuItem(value: 1.0, child: Text('1x')),
              DropdownMenuItem(value: 1.25, child: Text('1.25x')),
            ],
            onChanged: (value) {
              if (value != null) onSpeedChanged!(value);
            },
          ),
      ],
    );
  }
}

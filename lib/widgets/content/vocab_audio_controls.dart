import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/content/curriculum_audio_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Slow + native playback for curriculum/game vocabulary (manifest + TTS).
class VocabAudioControls extends ConsumerWidget {
  const VocabAudioControls({
    super.key,
    required this.language,
    required this.text,
    this.compact = false,
  });

  final String language;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.read(curriculumAudioServiceProvider);
    final style = compact
        ? IconButton.styleFrom(
            visualDensity: VisualDensity.compact,
            foregroundColor: PanAfricanColors.primary,
          )
        : null;

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            style: style,
            tooltip: 'Listen slowly',
            icon: const Icon(Icons.slow_motion_video_outlined, size: 20),
            onPressed: () => audio.speakPhrase(
              language: language,
              text: text,
              slow: true,
            ),
          ),
          IconButton(
            style: style,
            tooltip: 'Listen native speed',
            icon: const Icon(Icons.volume_up_outlined, size: 20),
            onPressed: () => audio.speakPhrase(
              language: language,
              text: text,
              slow: false,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        OutlinedButton.icon(
          onPressed: () => audio.speakPhrase(
            language: language,
            text: text,
            slow: true,
          ),
          icon: const Icon(Icons.slow_motion_video_outlined, size: 18),
          label: const Text('Slow'),
        ),
        FilledButton.icon(
          onPressed: () => audio.speakPhrase(
            language: language,
            text: text,
            slow: false,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: PanAfricanColors.primary,
          ),
          icon: const Icon(Icons.volume_up_outlined, size: 18),
          label: const Text('Native'),
        ),
      ],
    );
  }
}

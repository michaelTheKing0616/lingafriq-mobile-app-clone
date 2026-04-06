import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:lingafriq/providers/tts_provider.dart';

/// Play/stop control for server-side MMS-TTS (no device synthesis).
class TtsPlayButton extends HookConsumerWidget {
  const TtsPlayButton({
    super.key,
    required this.text,
    this.languageName = 'english',
    this.iconSize = 28,
    this.pidginDisclaimer = false,
  });

  final String text;
  final String languageName;
  final double iconSize;
  final bool pidginDisclaimer;

  /// Nigerian Pidgin uses MMS English — show disclaimer even if caller forgets the flag.
  static bool isNigerianPidginLanguage(String languageName) {
    final n = languageName.toLowerCase().trim().replaceAll(' ', '-');
    return n == 'nigerian-pidgin' ||
        n == 'pidgin' ||
        (n.contains('nigerian') && n.contains('pidgin'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsProvider.notifier);
    final loading = useState(false);

    return StreamBuilder<PlayerState>(
      stream: tts.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        final processing = snapshot.data?.processingState;
        final buffering = processing == ProcessingState.loading ||
            processing == ProcessingState.buffering;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              tooltip: playing ? 'Stop' : 'Play pronunciation',
              icon: (loading.value || buffering)
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                      size: iconSize,
                    ),
              onPressed: () async {
                if (playing) {
                  await tts.stop();
                  return;
                }
                loading.value = true;
                try {
                  final ok = await tts.speak(text, languageName: languageName);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not play audio. Check your connection and try again.',
                        ),
                      ),
                    );
                  }
                } finally {
                  loading.value = false;
                }
              },
            ),
            if (pidginDisclaimer || isNigerianPidginLanguage(languageName))
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(
                    'Approximate voice (no native Pidgin model yet)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

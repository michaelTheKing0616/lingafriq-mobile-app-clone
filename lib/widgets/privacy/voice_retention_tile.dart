import 'package:flutter/material.dart';
import 'package:lingafriq/services/voice/voice_recording_retention.dart';

/// Disclosure + retention choice + delete-now for on-device voice recordings.
class VoiceRetentionTile extends StatefulWidget {
  const VoiceRetentionTile({super.key, this.retention});

  final VoiceRecordingRetention? retention;

  static String labelFor(int h) => switch (h) {
    0 => 'Right after scoring',
    24 => 'After 24 hours',
    168 => 'After 7 days',
    _ => 'After 30 days',
  };

  @override
  State<VoiceRetentionTile> createState() => _VoiceRetentionTileState();
}

class _VoiceRetentionTileState extends State<VoiceRetentionTile> {
  int _hours = VoiceRecordingRetention.defaultHours;
  late final VoiceRecordingRetention _r =
      widget.retention ?? VoiceRecordingRetention();

  @override
  void initState() {
    super.initState();
    VoiceRecordingRetention.hours().then((h) {
      if (mounted) setState(() => _hours = h);
    });
  }

  Future<void> _deleteNow() async {
    final n = await _r.deleteAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted $n recording${n == 1 ? '' : 's'} from this device.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
          child: Text(
            'Your voice is recorded only while you practise, to score '
            'pronunciation and transcribe speech. Recordings on this device '
            'are deleted automatically.',
            key: ValueKey('voice-retention-disclosure'),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.auto_delete_outlined),
          title: const Text('Delete device recordings'),
          trailing: DropdownButton<int>(
            key: const ValueKey('voice-retention-dropdown'),
            value: _hours,
            items: [
              for (final h in VoiceRecordingRetention.options)
                DropdownMenuItem(
                  value: h,
                  child: Text(VoiceRetentionTile.labelFor(h)),
                ),
            ],
            onChanged: (h) async {
              if (h == null) return;
              await VoiceRecordingRetention.setHours(h);
              if (mounted) setState(() => _hours = h);
              await _r.sweep();
            },
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('voice-delete-now'),
            onPressed: _deleteNow,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete my recordings now'),
          ),
        ),
      ],
    );
  }
}

import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:flutter/material.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/services/voice/voice_recording_retention.dart';

/// Disclosure, auto-delete choice and "delete now" for on-device recordings.
///
/// Stacked layout (title, description, full-width selector, full-width
/// action) so nothing competes for width at large text sizes.
class VoiceRetentionTile extends StatefulWidget {
  const VoiceRetentionTile({super.key, this.retention});

  final VoiceRecordingRetention? retention;

  static String labelFor(AppLocalizations l, int hours) => switch (hours) {
    0 => l.voiceRetentionImmediate,
    24 => l.voiceRetention24h,
    168 => l.voiceRetention7d,
    _ => l.voiceRetention30d,
  };

  @override
  State<VoiceRetentionTile> createState() => _VoiceRetentionTileState();
}

class _VoiceRetentionTileState extends State<VoiceRetentionTile> {
  int _hours = VoiceRecordingRetention.defaultHours;
  bool _deleting = false;
  late final VoiceRecordingRetention _r =
      widget.retention ?? VoiceRecordingRetention();

  @override
  void initState() {
    super.initState();
    VoiceRecordingRetention.hours().then((h) {
      if (mounted) setState(() => _hours = h);
    });
  }

  Future<void> _confirmAndDelete(AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text(l.voiceRetentionConfirmTitle),
        content: Text(l.voiceRetentionConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            key: const ValueKey('voice-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.voiceRetentionConfirmDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    final n = await _r.deleteAll();
    if (!mounted) return;
    setState(() => _deleting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.voiceRetentionDeleted(n))));
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l.voiceRetentionTitle,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.voiceRetentionBody,
            key: const ValueKey('voice-retention-disclosure'),
            style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(l.voiceRetentionSelectLabel, style: t.labelLarge),
          const SizedBox(height: 6),
          KeyedSubtree(
            key: ValueKey('retention-$_hours'),
            child: Semantics(
              label: l.voiceRetentionSelectLabel,
              child: DropdownButtonFormField<int>(
                key: const ValueKey('voice-retention-dropdown'),
                initialValue: _hours,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.auto_delete_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final h in VoiceRecordingRetention.options)
                    DropdownMenuItem(
                      value: h,
                      child: Text(VoiceRetentionTile.labelFor(l, h)),
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
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('voice-delete-now'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.6)),
            ),
            onPressed: _deleting ? null : () => _confirmAndDelete(l),
            icon: _deleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            label: Text(l.voiceRetentionDeleteNow, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

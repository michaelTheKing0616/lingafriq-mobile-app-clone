import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/offline/tone_trainer_queue_service.dart';
import 'package:lingafriq/services/voice/audio_recording_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class ToneRhythmTrainerScreen extends StatefulWidget {
  final String language;
  final String? expectedText;

  const ToneRhythmTrainerScreen({
    super.key,
    required this.language,
    this.expectedText,
  });

  @override
  State<ToneRhythmTrainerScreen> createState() => _ToneRhythmTrainerScreenState();
}

class _ToneRhythmTrainerScreenState extends State<ToneRhythmTrainerScreen> {
  final _rec = AudioRecordingService();
  late final TextEditingController _expectedCtrl;
  bool _isRecording = false;
  bool _isSubmitting = false;
  String? _recordingPath;
  Map<String, dynamic>? _result;
  String? _error;
  String? _queuedNotice;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _tick;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _expectedCtrl = TextEditingController(text: widget.expectedText ?? '');
  }

  @override
  void dispose() {
    _tick?.cancel();
    _expectedCtrl.dispose();
    super.dispose();
  }

  void _startTicker() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() => _elapsed = _stopwatch.elapsed);
    });
  }

  void _stopTicker() {
    _tick?.cancel();
    _tick = null;
  }

  String _formatElapsed(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _toggleRecord() async {
    if (_isSubmitting) return;
    if (_isRecording) {
      HapticFeedback.mediumImpact();
      final path = await _rec.stopRecording();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
      _stopwatch.stop();
      _stopTicker();
      return;
    }

    final ok = await _rec.checkPermission();
    if (!ok) {
      final granted = await _rec.requestPermission();
      if (!granted) {
        setState(() => _error = 'Microphone permission is required.');
        return;
      }
    }
    HapticFeedback.mediumImpact();
    final path = await _rec.startRecording(sampleRate: 16000, numChannels: 1);
    if (path == null) {
      setState(() => _error = 'Failed to start recording.');
      return;
    }
    setState(() {
      _error = null;
      _result = null;
      _recordingPath = null;
      _isRecording = true;
      _queuedNotice = null;
    });
    _stopwatch
      ..reset()
      ..start();
    _startTicker();
  }

  Future<void> _submit() async {
    if (_isRecording || _isSubmitting) return;
    final expected = _expectedCtrl.text.trim();
    if (expected.isEmpty) {
      setState(() => _error = 'Enter the phrase you are trying to say.');
      return;
    }
    final path = _recordingPath;
    if (path == null || !(await File(path).exists())) {
      setState(() => _error = 'Record audio first.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _result = null;
      _queuedNotice = null;
    });

    try {
      await ApiService.initialize();
      final res = await ApiService.uploadFile(
        ApiContract.learningV2.toneTrainer,
        path,
        fileFieldName: 'audio',
        additionalData: {
          'expectedText': expected,
          'language': widget.language.trim().toLowerCase(),
        },
      );
      if (res.statusCode != 200 || res.data is! Map) {
        throw Exception('Tone evaluation failed');
      }
      setState(() => _result = (res.data as Map).cast<String, dynamic>());
    } catch (e) {
      // Offline-first fallback: queue the audio upload for later.
      try {
        await ToneTrainerQueueService.instance.enqueue(
          language: widget.language,
          expectedText: expected,
          audioPath: path,
        );
        setState(() {
          _queuedNotice = 'Saved offline. We’ll analyze it automatically when you’re back online.';
        });
      } catch (_) {
        setState(() => _error = e.toString());
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Tone & Rhythm'),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroHeader(
            title: 'Practice tone & rhythm',
            subtitle: 'Record a phrase. Get meaning-weighted feedback.\nWorks offline — submits when you’re back online.',
            trailing: _StatusPill(
              label: _isRecording ? 'Recording ${_formatElapsed(_elapsed)}' : (_recordingPath != null ? 'Recorded' : 'Ready'),
              tone: _isRecording ? _PillTone.danger : (_recordingPath != null ? _PillTone.success : _PillTone.neutral),
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Target phrase', style: PanAfricanTypography.titleMedium(context)),
                const SizedBox(height: 8),
                TextField(
                  controller: _expectedCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Type the phrase (with tone marks if applicable)',
                    filled: true,
                    fillColor: isDark
                        ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35)
                        : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _toggleRecord,
                        icon: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded),
                        label: Text(_isRecording ? 'Stop' : 'Record'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: (_isSubmitting || _isRecording) ? null : _submit,
                        icon: const Icon(Icons.analytics_rounded),
                        label: Text(_isSubmitting ? 'Analyzing…' : 'Analyze'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_recordingPath != null)
                  Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recorded: ${_recordingPath!.split(Platform.pathSeparator).last}',
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_error != null || _queuedNotice != null) ...[
            const SizedBox(height: 12),
            _Notice(
              tone: _error != null ? _NoticeTone.error : _NoticeTone.success,
              title: _error != null ? 'Couldn’t analyze right now' : 'Saved offline',
              message: _error ?? _queuedNotice ?? '',
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final tone = result['tone'];
    final accuracy = result['accuracy'];
    final meaningRisk = result['meaningRisk'] == true;
    final feedback = (tone is Map ? tone['feedback'] : null)?.toString() ?? '';
    final errors = (tone is Map ? tone['errors'] : null);
    final errorCount = errors is List ? errors.length : 0;
    final accuracyNum = accuracy is num ? accuracy.toDouble() : null;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Result', style: PanAfricanTypography.titleMedium(context))),
              _MetricChip(
                label: 'Accuracy',
                value: accuracyNum == null ? '—' : '${accuracyNum.toStringAsFixed(0)}%',
                tone: accuracyNum != null && accuracyNum >= 80 ? _ChipTone.success : _ChipTone.neutral,
              ),
              const SizedBox(width: 8),
              _MetricChip(
                label: 'Tone errors',
                value: '$errorCount',
                tone: errorCount == 0 ? _ChipTone.success : (errorCount <= 2 ? _ChipTone.warn : _ChipTone.danger),
              ),
            ],
          ),
          if (meaningRisk) ...[
            const SizedBox(height: 8),
            _Notice(
              tone: _NoticeTone.warn,
              title: 'Meaning risk: high',
              message: 'Tone errors on a short phrase can change meaning. Slow down and exaggerate contour first, then speed up.',
            ),
          ],
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Feedback', style: PanAfricanTypography.titleSmall(context)),
            const SizedBox(height: 4),
            Text(feedback, style: PanAfricanTypography.bodyMedium(context)),
          ],
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PanAfricanTypography.titleLarge(context)),
                const SizedBox(height: 6),
                Text(subtitle, style: PanAfricanTypography.bodySmall(context)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: PanAfricanShadows.sm,
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.12)),
      ),
      child: child,
    );
  }
}

enum _PillTone { neutral, success, danger }

class _StatusPill extends StatelessWidget {
  final String label;
  final _PillTone tone;

  const _StatusPill({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    switch (tone) {
      case _PillTone.success:
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        break;
      case _PillTone.danger:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        break;
      case _PillTone.neutral:
        bg = scheme.surfaceContainerHighest.withOpacity(0.7);
        fg = scheme.onSurface;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PanAfricanTypography.bodySmall(context).copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum _ChipTone { neutral, success, warn, danger }

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final _ChipTone tone;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg = scheme.surfaceContainerHighest.withOpacity(0.65);
    Color fg = scheme.onSurface;
    if (tone == _ChipTone.success) {
      bg = scheme.primaryContainer;
      fg = scheme.onPrimaryContainer;
    } else if (tone == _ChipTone.warn) {
      bg = scheme.tertiaryContainer;
      fg = scheme.onTertiaryContainer;
    } else if (tone == _ChipTone.danger) {
      bg = scheme.errorContainer;
      fg = scheme.onErrorContainer;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PanAfricanTypography.bodySmall(context).copyWith(color: fg.withOpacity(0.9))),
          Text(value, style: PanAfricanTypography.titleSmall(context).copyWith(color: fg)),
        ],
      ),
    );
  }
}

enum _NoticeTone { success, warn, error }

class _Notice extends StatelessWidget {
  final _NoticeTone tone;
  final String title;
  final String message;

  const _Notice({
    required this.tone,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    final IconData icon;
    switch (tone) {
      case _NoticeTone.success:
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        icon = Icons.check_circle_rounded;
        break;
      case _NoticeTone.warn:
        bg = scheme.tertiaryContainer;
        fg = scheme.onTertiaryContainer;
        icon = Icons.warning_rounded;
        break;
      case _NoticeTone.error:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        icon = Icons.error_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PanAfricanTypography.titleSmall(context).copyWith(color: fg)),
                const SizedBox(height: 2),
                Text(message, style: PanAfricanTypography.bodySmall(context).copyWith(color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


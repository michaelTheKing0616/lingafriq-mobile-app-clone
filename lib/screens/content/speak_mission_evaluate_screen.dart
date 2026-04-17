import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/services/learning/dialect_preference_service.dart';
import 'package:lingafriq/services/learning/speak_mission_service.dart';
import 'package:lingafriq/services/voice/audio_recording_service.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';

class SpeakMissionEvaluateScreen extends ConsumerStatefulWidget {
  final String languageCode;
  final String scenarioId;
  final String scenarioTitle;
  final List<String> referenceKeywords;
  final String registerContext;

  const SpeakMissionEvaluateScreen({
    super.key,
    required this.languageCode,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.referenceKeywords,
    required this.registerContext,
  });

  @override
  ConsumerState<SpeakMissionEvaluateScreen> createState() => _SpeakMissionEvaluateScreenState();
}

class _SpeakMissionEvaluateScreenState extends ConsumerState<SpeakMissionEvaluateScreen> {
  final _rec = AudioRecordingService();
  final _svc = SpeakMissionService();
  final _dialectSvc = DialectPreferenceService();

  bool _busy = false;
  String? _recordingPath;
  String _transcript = '';
  SpeakMissionEvaluationResult? _result;
  String? _error;
  String? _dialectTag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final pref = await _dialectSvc.get(umbrellaLanguage: widget.languageCode);
        final tag = pref?['preferredDialectTag']?.toString();
        if (tag != null && tag.trim().isNotEmpty && mounted) {
          setState(() => _dialectTag = tag.trim());
        }
      } catch (_) {}
    });
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _result = null;
      _transcript = '';
    });
    final path = await _rec.startRecording();
    if (path == null) {
      setState(() => _error = 'Microphone permission denied or recorder unavailable.');
      return;
    }
    setState(() => _recordingPath = path);
  }

  Future<void> _stopAndEvaluate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final path = await _rec.stopRecording();
      final p = path ?? _recordingPath;
      if (p == null) throw Exception('No recording found');
      final bytes = await _rec.getRecordingBytes(p);
      if (bytes == null || bytes.isEmpty) throw Exception('Could not read recording');

      // Transcribe (on-device lite path uses Groq Whisper; if not configured it returns empty).
      final transcript = await ref.read(groqChatProvider.notifier).transcribeAudio(bytes);
      if (transcript.trim().isEmpty) {
        throw Exception('Transcription failed. Configure Groq key or enable server STT.');
      }
      setState(() => _transcript = transcript.trim());

      // Server rubric scoring (production path). This will return 503 if AI providers are unavailable.
      final result = await _svc.evaluate(
        language: widget.languageCode,
        dialectTag: _dialectTag,
        scenarioId: widget.scenarioId,
        transcript: transcript.trim(),
        referenceKeywords: widget.referenceKeywords,
        registerContext: widget.registerContext,
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
      final rp = _recordingPath;
      if (rp != null) {
        try {
          final f = File(rp);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (_) {}
      }
      _recordingPath = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _rec.isRecording;
    return Scaffold(
      backgroundColor: PolieColors.obsidian,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: PolieColors.textPrimary,
        title: Text('Speak Mission: ${widget.scenarioTitle}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(PolieSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record a short response (10–30s). We’ll grade comprehensibility, intent, register, and repair strategy.',
                style: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary),
              ),
              SizedBox(height: PolieSpacing.lg),
              if (_error != null)
                Container(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  decoration: BoxDecoration(
                    color: PolieColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(PolieRadius.md),
                    border: Border.all(color: PolieColors.error.withOpacity(0.4)),
                  ),
                  child: Text(
                    _error!,
                    style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.textPrimary),
                  ),
                ),
              if (_transcript.isNotEmpty) ...[
                SizedBox(height: PolieSpacing.md),
                Text('Transcript', style: PolieTypography.h3(context).copyWith(color: PolieColors.textPrimary)),
                SizedBox(height: PolieSpacing.sm),
                Text(_transcript, style: PolieTypography.body(context).copyWith(color: PolieColors.textPrimary)),
              ],
              if (_result != null) ...[
                SizedBox(height: PolieSpacing.lg),
                Text('Scores', style: PolieTypography.h3(context).copyWith(color: PolieColors.textPrimary)),
                SizedBox(height: PolieSpacing.sm),
                _ScoreRow(label: 'Comprehensibility', value: _result!.scores['comprehensibility']),
                _ScoreRow(label: 'Intent', value: _result!.scores['intent']),
                _ScoreRow(label: 'Register', value: _result!.scores['register']),
                _ScoreRow(label: 'Repair', value: _result!.scores['repair']),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy
                          ? null
                          : isRecording
                              ? _stopAndEvaluate
                              : _start,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRecording ? PolieColors.goldEmber : PolieColors.electricTeal,
                        foregroundColor: PolieColors.obsidian,
                        padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PolieRadius.md)),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isRecording ? 'Stop & Evaluate' : 'Start Recording'),
                    ),
                  ),
                  SizedBox(width: PolieSpacing.md),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                    color: PolieColors.textPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final dynamic value;
  const _ScoreRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final n = value is num ? value.toInt() : 0;
    return Padding(
      padding: EdgeInsets.only(bottom: PolieSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary)),
          ),
          Text('$n', style: PolieTypography.body(context).copyWith(color: PolieColors.textPrimary)),
        ],
      ),
    );
  }
}


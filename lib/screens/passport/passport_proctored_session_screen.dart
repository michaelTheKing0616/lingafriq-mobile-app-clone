import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/passport/passport_service.dart';
import 'package:lingafriq/services/voice/audio_recording_service.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/screens/passport/passport_credential_screen.dart';

class PassportProctoredSessionScreen extends ConsumerStatefulWidget {
  final String language;
  final String proctorMode; // device_rules | staff_review
  const PassportProctoredSessionScreen({
    super.key,
    required this.language,
    this.proctorMode = 'device_rules',
  });

  @override
  ConsumerState<PassportProctoredSessionScreen> createState() => _PassportProctoredSessionScreenState();
}

class _PassportProctoredSessionScreenState extends ConsumerState<PassportProctoredSessionScreen> {
  final _svc = PassportService();
  final _rec = AudioRecordingService();

  bool _busy = true;
  String? _error;
  PassportSessionStart? _session;
  int _idx = 0;
  String? _recordingPath;
  DateTime? _recordingStartedAt;
  final List<Map<String, dynamic>> _recordings = [];

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
      });
      final s = await _svc.startSession(
        language: widget.language,
        proctorMode: widget.proctorMode,
        integritySignals: {
          'platform': Theme.of(context).platform.toString(),
          'startedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
      setState(() {
        _session = s;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _beginRecording() async {
    if (_session == null) return;
    final path = await _rec.startRecording();
    if (path == null) {
      setState(() => _error = 'Microphone permission denied or recorder unavailable.');
      return;
    }
    setState(() {
      _recordingPath = path;
      _recordingStartedAt = DateTime.now();
    });
  }

  Future<void> _stopAndUpload() async {
    if (_busy || _session == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final prompt = _session!.prompts[_idx];
      await _rec.stopRecording();
      final p = _recordingPath;
      if (p == null) throw Exception('No recording path');
      final duration = _recordingStartedAt == null
          ? 0
          : DateTime.now().difference(_recordingStartedAt!).inSeconds;
      final up = await _svc.uploadRecording(
        sessionId: _session!.sessionId,
        promptId: prompt.promptId,
        filePath: p,
        durationSec: duration,
      );
      _recordings.removeWhere((r) => r['promptId'] == prompt.promptId);
      _recordings.add({
        'promptId': prompt.promptId,
        'storageKey': up['storageKey'],
        'durationSec': up['durationSec'] ?? duration,
      });

      if (_idx < _session!.prompts.length - 1) {
        setState(() {
          _idx++;
          _recordingPath = null;
          _recordingStartedAt = null;
          _busy = false;
        });
        return;
      }

      final submitted = await _svc.submit(
        sessionId: _session!.sessionId,
        recordings: _recordings,
        rubric: {},
        integritySignals: {
          'completedAt': DateTime.now().toUtc().toIso8601String(),
          'recordingCount': _recordings.length,
        },
      );

      if (!mounted) return;
      final token = submitted['verifyToken']?.toString() ?? '';
      final level = submitted['level']?.toString() ?? '';
      final score = (submitted['score'] is num) ? (submitted['score'] as num).round() : 0;
      if (token.isNotEmpty) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PassportCredentialScreen(
              verifyToken: token,
              level: level,
              score: score,
            ),
          ),
        );
      } else {
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_rec.isRecording,
      onPopInvoked: (didPop) async {
        if (!_rec.isRecording) return;
        HapticFeedback.heavyImpact();
      },
      child: Scaffold(
        backgroundColor: PolieColors.obsidian,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: PolieColors.textPrimary,
          title: const Text('Proctored Passport Session'),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(PolieSpacing.lg),
            child: _busy && _session == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        Container(
                          padding: EdgeInsets.all(PolieSpacing.md),
                          decoration: BoxDecoration(
                            color: PolieColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(PolieRadius.md),
                            border: Border.all(color: PolieColors.error.withOpacity(0.4)),
                          ),
                          child: Text(_error!, style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.textPrimary)),
                        ),
                      if (_session != null) ...[
                        Text(
                          'Rules: do not leave the app during recording. Complete all prompts.',
                          style: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary),
                        ),
                        SizedBox(height: PolieSpacing.lg),
                        Text(
                          'Prompt ${_idx + 1}/${_session!.prompts.length}',
                          style: PolieTypography.h3(context).copyWith(color: PolieColors.textPrimary),
                        ),
                        SizedBox(height: PolieSpacing.sm),
                        Text(
                          _session!.prompts[_idx].text,
                          style: PolieTypography.body(context).copyWith(color: PolieColors.textPrimary),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _busy
                                    ? null
                                    : (_rec.isRecording ? _stopAndUpload : _beginRecording),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _rec.isRecording ? PolieColors.goldEmber : PolieColors.electricTeal,
                                  foregroundColor: PolieColors.obsidian,
                                  padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PolieRadius.md)),
                                ),
                                child: Text(_rec.isRecording ? 'Stop & Upload' : 'Start Recording'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/passport/passport_service.dart';
import 'package:lingafriq/services/voice/audio_recording_service.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:lingafriq/screens/passport/passport_credential_screen.dart';

enum _CatPhase { rules, active, flagged, resultUnsure, error }

class PassportProctoredSessionScreen extends ConsumerStatefulWidget {
  final String language;
  final String proctorMode;
  final String? resumeSessionId;

  const PassportProctoredSessionScreen({
    super.key,
    required this.language,
    this.proctorMode = 'device_rules',
    this.resumeSessionId,
  });

  @override
  ConsumerState<PassportProctoredSessionScreen> createState() => _PassportProctoredSessionScreenState();
}

class _PassportProctoredSessionScreenState extends ConsumerState<PassportProctoredSessionScreen>
    with WidgetsBindingObserver {
  final _svc = PassportService();
  final _rec = AudioRecordingService();

  bool _busy = true;
  String? _error;
  _CatPhase _phase = _CatPhase.rules;
  PassportSessionStart? _session;
  String? _sessionToken;
  int _idx = 0;
  String? _recordingPath;
  DateTime? _recordingStartedAt;
  final List<Map<String, dynamic>> _recordings = [];
  String? _flagReason;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_session == null || _sessionToken == null || _phase != _CatPhase.active) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      unawaited(_reportFlag('app_backgrounded'));
    }
  }

  Future<void> _bootstrap() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
      });
      final PassportSessionStart s;
      if (widget.resumeSessionId != null && widget.resumeSessionId!.isNotEmpty) {
        s = await _svc.resumeSession(widget.resumeSessionId!);
        setState(() {
          _session = s;
          _sessionToken = s.sessionToken;
          _phase = _CatPhase.active;
          _busy = false;
        });
      } else {
        s = await _svc.startSession(
          language: widget.language,
          proctorMode: widget.proctorMode,
          integritySignals: {
            'platform': Theme.of(context).platform.toString(),
            'startedAt': DateTime.now().toUtc().toIso8601String(),
            'voiceConsent': true,
          },
        );
        setState(() {
          _session = s;
          _sessionToken = s.sessionToken;
          _phase = _CatPhase.rules;
          _busy = false;
        });
      }
    } on PassportCatException catch (e) {
      setState(() {
        _error = e.code;
        _phase = _CatPhase.error;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _phase = _CatPhase.error;
        _busy = false;
      });
    }
  }

  void _acceptRules() {
    if (_session == null) return;
    setState(() => _phase = _CatPhase.active);
  }

  Future<void> _reportFlag(String reason) async {
    if (_session == null || _sessionToken == null) return;
    try {
      await _svc.reportIntegrityViolation(
        sessionId: _session!.sessionId,
        sessionToken: _sessionToken!,
        reason: reason,
      );
      setState(() {
        _phase = _CatPhase.flagged;
        _flagReason = reason;
      });
    } catch (_) {
      setState(() {
        _phase = _CatPhase.flagged;
        _flagReason = reason;
      });
    }
  }

  Future<void> _beginRecording() async {
    if (_session == null || _phase != _CatPhase.active) return;
    final path = await _rec.startRecording();
    if (path == null) {
      await _reportFlag('audio_unavailable');
      return;
    }
    setState(() {
      _recordingPath = path;
      _recordingStartedAt = DateTime.now();
    });
  }

  Future<void> _stopAndUpload() async {
    if (_busy || _session == null || _sessionToken == null || _phase != _CatPhase.active) return;
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
      if (duration < 2) {
        await _reportFlag('audio_lost');
        return;
      }
      final up = await _svc.uploadRecording(
        sessionId: _session!.sessionId,
        promptId: prompt.promptId,
        filePath: p,
        durationSec: duration,
      );
      const itemScore = 0.72;
      _recordings.removeWhere((r) => r['promptId'] == prompt.promptId);
      _recordings.add({
        'promptId': prompt.promptId,
        'storageKey': up['storageKey'],
        'durationSec': up['durationSec'] ?? duration,
        'itemScore': itemScore,
      });

      final next = await _svc.advanceCatStep(
        sessionId: _session!.sessionId,
        sessionToken: _sessionToken!,
        promptId: prompt.promptId,
        itemScore: itemScore,
      );

      if (next != null) {
        final prompts = List<PassportPrompt>.from(_session!.prompts);
        if (_idx + 1 < prompts.length) {
          prompts[_idx + 1] = next;
        } else {
          prompts.add(next);
        }
        setState(() {
          _session = PassportSessionStart(
            sessionId: _session!.sessionId,
            sessionToken: _sessionToken!,
            rules: _session!.rules,
            prompts: prompts,
          );
          _idx++;
          _recordingPath = null;
          _recordingStartedAt = null;
          _busy = false;
        });
        return;
      }

      final submitted = await _svc.submit(
        sessionId: _session!.sessionId,
        sessionToken: _sessionToken!,
        recordings: _recordings,
        rubric: {},
        integritySignals: {
          'completedAt': DateTime.now().toUtc().toIso8601String(),
          'recordingCount': _recordings.length,
          'voiceConsent': true,
        },
      );

      if (!mounted) return;
      if (submitted['heldForReview'] == true) {
        setState(() {
          _phase = _CatPhase.flagged;
          _flagReason = submitted['flagReason']?.toString() ?? 'held_for_review';
          _busy = false;
        });
        return;
      }
      if (submitted['unsure'] == true) {
        setState(() {
          _phase = _CatPhase.resultUnsure;
          _busy = false;
        });
        return;
      }
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
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _phase = _CatPhase.error;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = _session?.rules ?? const {};
    return PopScope(
      canPop: _phase != _CatPhase.active || !_rec.isRecording,
      onPopInvoked: (didPop) async {
        if (!_rec.isRecording) return;
        HapticFeedback.heavyImpact();
      },
      child: Scaffold(
        backgroundColor: PolieColors.obsidian,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: PolieColors.textPrimary,
          title: const Text('Passport speaking check'),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(PolieSpacing.lg),
            child: _busy && _session == null
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(context, rules),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> rules) {
    if (_phase == _CatPhase.rules) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before you begin',
            style: PolieTypography.h2(context).copyWith(color: PolieColors.textPrimary),
          ),
          SizedBox(height: PolieSpacing.md),
          Text(
            'Stay in the app while you record. Use a quiet room and speak alone — we only keep audio long enough to score, then delete it.',
            style: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary),
          ),
          SizedBox(height: PolieSpacing.sm),
          Text(
            'Max break: ${rules['maxBreakSec'] ?? 10}s. Voice consent is required for this proctored check.',
            style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.textSecondary),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _session == null ? null : _acceptRules,
              style: ElevatedButton.styleFrom(
                backgroundColor: PolieColors.electricTeal,
                foregroundColor: PolieColors.obsidian,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PolieRadius.md)),
              ),
              child: const Text('I understand — start'),
            ),
          ),
        ],
      );
    }

    if (_phase == _CatPhase.flagged) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session held for review',
            style: PolieTypography.h3(context).copyWith(color: PolieColors.goldEmber),
          ),
          SizedBox(height: PolieSpacing.md),
          Text(
            'We noticed something that breaks the proctoring rules (${_flagReason ?? 'integrity'}). A reviewer will look at this session before any level is issued.',
            style: PolieTypography.body(context).copyWith(color: PolieColors.textPrimary),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: PolieColors.textPrimary,
              ),
              child: const Text('Back'),
            ),
          ),
        ],
      );
    }

    if (_phase == _CatPhase.resultUnsure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We need a clearer sample',
            style: PolieTypography.h3(context).copyWith(color: PolieColors.textPrimary),
          ),
          SizedBox(height: PolieSpacing.md),
          Text(
            'Your speaking was recorded safely, but confidence was too low to assign a Passport level. Try again when you are in a quiet space.',
            style: PolieTypography.body(context).copyWith(color: PolieColors.textSecondary),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: PolieColors.electricTeal,
                foregroundColor: PolieColors.obsidian,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null)
          Container(
            padding: EdgeInsets.all(PolieSpacing.md),
            decoration: BoxDecoration(
              color: PolieColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(PolieRadius.md),
              border: Border.all(color: PolieColors.error.withValues(alpha: 0.4)),
            ),
            child: Text(
              _error!,
              style: PolieTypography.bodySmall(context).copyWith(color: PolieColors.textPrimary),
            ),
          ),
        if (_session != null && _phase == _CatPhase.active) ...[
          Text(
            'Prompt ${_idx + 1}/${_session!.prompts.length}',
            style: PolieTypography.h3(context).copyWith(color: PolieColors.textPrimary),
          ),
          SizedBox(height: PolieSpacing.sm),
          Semantics(
            label: 'Speaking prompt',
            child: Text(
              _session!.prompts[_idx].text,
              style: PolieTypography.body(context).copyWith(color: PolieColors.textPrimary),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : (_rec.isRecording ? _stopAndUpload : _beginRecording),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rec.isRecording ? PolieColors.goldEmber : PolieColors.electricTeal,
                    foregroundColor: PolieColors.obsidian,
                    padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PolieRadius.md)),
                  ),
                  child: Text(_rec.isRecording ? 'Stop & continue' : 'Start recording'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

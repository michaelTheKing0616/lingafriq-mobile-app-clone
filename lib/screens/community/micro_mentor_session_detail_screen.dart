import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/chat/live_classroom_screen_material3.dart';
import 'package:lingafriq/services/community/micro_mentor_service.dart';
import 'package:lingafriq/services/voice/audio_recording_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class MicroMentorSessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const MicroMentorSessionDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<MicroMentorSessionDetailScreen> createState() => _MicroMentorSessionDetailScreenState();
}

class _MicroMentorSessionDetailScreenState extends ConsumerState<MicroMentorSessionDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _session;

  bool _mentorRecording = false;
  bool _learnerRecording = false;

  final _goals = TextEditingController();
  final _notes = TextEditingController();
  double _r1 = 3;
  double _r2 = 3;
  double _r3 = 3;

  final _rec = AudioRecordingService();
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void dispose() {
    _goals.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  static const List<(String, String)> _reportCategories = [
    ('harassment', 'Harassment'),
    ('inappropriate_content', 'Inappropriate content'),
    ('spam', 'Spam'),
    ('safety_concern', 'Safety concern'),
    ('other', 'Other'),
  ];

  Future<void> _showReportDialog() async {
    if (_session == null) return;
    final detailsCtrl = TextEditingController();
    final ok = await showDialog<(bool, String)>(
      context: context,
      builder: (ctx) {
        var category = _reportCategories.first.$1;
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Report this session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _reportCategories
                          .map((e) => DropdownMenuItem<String>(value: e.$1, child: Text(e.$2)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setLocal(() => category = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailsCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'What happened?',
                        hintText: 'At least 10 characters',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, (false, category)), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, (true, category)), child: const Text('Submit')),
              ],
            );
          },
        );
      },
    );
    if (ok == null || !ok.$1 || !mounted) {
      detailsCtrl.dispose();
      return;
    }
    final category = ok.$2;
    final text = detailsCtrl.text.trim();
    detailsCtrl.dispose();
    if (text.length < 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a bit more detail (at least 10 characters).')),
      );
      return;
    }
    try {
      await ref.read(microMentorServiceProvider).reportSession(sessionId: widget.sessionId, category: category, details: text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted. Thank you.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await ref.read(microMentorServiceProvider).getSession(widget.sessionId);
      final consent = Map<String, dynamic>.from(s['consent'] ?? const {});
      setState(() {
        _session = s;
        _mentorRecording = consent['mentorRecording'] == true;
        _learnerRecording = consent['learnerRecording'] == true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _isMentor() {
    final me = ref.read(userProvider)?.id.toString();
    final mentor = _session?['mentorUserId']?.toString();
    return me != null && mentor != null && me == mentor;
  }

  Future<void> _respond(String action) async {
    try {
      await ref.read(microMentorServiceProvider).mentorRespond(sessionId: widget.sessionId, action: action);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated: $action')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _join() async {
    try {
      final res = await ref.read(microMentorServiceProvider).joinSession(widget.sessionId);
      final livekit = Map<String, dynamic>.from(res['livekit'] ?? const {});
      final token = livekit['token']?.toString();
      final url = livekit['url']?.toString();
      final roomName = livekit['roomName']?.toString() ?? 'Micro‑mentor';
      final roomId = res['roomId']?.toString() ?? widget.sessionId;
      if (!mounted) return;
      if (token == null || token.isEmpty || url == null || url.isEmpty) {
        throw Exception('Missing LiveKit credentials');
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LiveClassroomScreenMaterial3(
            roomId: roomId,
            roomName: roomName,
            livekitToken: token,
            livekitUrl: url,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _setMyConsent(bool v) async {
    try {
      final updated = await ref.read(microMentorServiceProvider).setConsent(sessionId: widget.sessionId, consent: v);
      setState(() {
        _mentorRecording = updated['mentorRecording'] == true;
        _learnerRecording = updated['learnerRecording'] == true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      final path = await _rec.stopRecording();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
      return;
    }
    final ok = await _rec.checkPermission();
    if (!ok) {
      final granted = await _rec.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required')));
        }
        return;
      }
    }
    final path = await _rec.startRecording(sampleRate: 16000, numChannels: 1);
    if (path == null) return;
    setState(() {
      _isRecording = true;
      _recordingPath = null;
    });
  }

  Future<void> _uploadRecording() async {
    final path = _recordingPath;
    if (path == null || !(await File(path).exists())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record audio first')));
      return;
    }
    try {
      await ApiService.initialize();
      final res = await ApiService.uploadFile(
        ApiContract.url(ApiContract.microMentorsV2.sessionRecording(widget.sessionId)),
        path,
        fileFieldName: 'audio',
      );
      if (res.statusCode != 201) throw Exception('Upload failed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording uploaded')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _submitRubric() async {
    if (!_isMentor()) return;
    try {
      final rubric = {
        'goals': _goals.text.trim(),
        'notes': _notes.text.trim(),
        'ratings': {
          'comprehensibility': _r1.round(),
          'confidence': _r2.round(),
          'politenessRegister': _r3.round(),
        },
      };
      final res = await ref.read(microMentorServiceProvider).submitRubric(
            sessionId: widget.sessionId,
            rubric: rubric,
            generateSummary: true,
          );
      if (!mounted) return;
      if (res['queued'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Queued offline for sync')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rubric saved')));
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Session'),
        actions: [
          if (!_loading && _error == null && _session != null)
            IconButton(
              tooltip: 'Report issue',
              icon: const Icon(Icons.flag_outlined),
              onPressed: _showReportDialog,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: EdgeInsets.all(PanAfricanSpacing.lg), child: Text(_error!)))
              : ListView(
                  padding: EdgeInsets.all(PanAfricanSpacing.lg),
                  children: [
                    Text('Status: ${_session?['status']}', style: PanAfricanTypography.titleMedium(context)),
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text('Language: ${_session?['language']}', style: PanAfricanTypography.bodyMedium(context)),
                    Text('When: ${_session?['scheduledStartTime']}', style: PanAfricanTypography.bodySmall(context)),
                    SizedBox(height: PanAfricanSpacing.lg),
                    if (_isMentor() && _session?['status'] == 'requested') ...[
                      Row(
                        children: [
                          Expanded(child: FilledButton(onPressed: () => _respond('accept'), child: const Text('Accept'))),
                          SizedBox(width: PanAfricanSpacing.sm),
                          Expanded(child: OutlinedButton(onPressed: () => _respond('decline'), child: const Text('Decline'))),
                        ],
                      ),
                      SizedBox(height: PanAfricanSpacing.lg),
                    ],
                    FilledButton.icon(
                      onPressed: (_session?['status'] == 'accepted' || _session?['status'] == 'live') ? _join : null,
                      icon: const Icon(Icons.headset_mic_rounded),
                      label: const Text('Join voice room'),
                    ),
                    SizedBox(height: PanAfricanSpacing.lg),
                    Text('Recording consent', style: PanAfricanTypography.titleMedium(context)),
                    SizedBox(height: PanAfricanSpacing.xs),
                    Text(
                      'Both mentor and learner must opt in before uploading a recording artifact.',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                    SwitchListTile(
                      value: _isMentor() ? _mentorRecording : _learnerRecording,
                      onChanged: (v) => _setMyConsent(v),
                      title: Text(_isMentor() ? 'My consent (mentor)' : 'My consent (learner)'),
                    ),
                    Text(
                      'Mentor: ${_mentorRecording ? 'yes' : 'no'} • Learner: ${_learnerRecording ? 'yes' : 'no'}',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _toggleRecord,
                            icon: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded),
                            label: Text(_isRecording ? 'Stop' : 'Record'),
                          ),
                        ),
                        SizedBox(width: PanAfricanSpacing.sm),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: (_mentorRecording && _learnerRecording) ? _uploadRecording : null,
                            icon: const Icon(Icons.cloud_upload_rounded),
                            label: const Text('Upload'),
                          ),
                        ),
                      ],
                    ),
                    if (_session?['summary'] != null) ...[
                      SizedBox(height: PanAfricanSpacing.lg),
                      Text('Summary', style: PanAfricanTypography.titleMedium(context)),
                      SizedBox(height: PanAfricanSpacing.xs),
                      Text(
                        Map<String, dynamic>.from(_session!['summary'] as Map)['text']?.toString() ?? '',
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                    ],
                    if (_isMentor()) ...[
                      SizedBox(height: PanAfricanSpacing.lg),
                      Text('Mentor rubric', style: PanAfricanTypography.titleMedium(context)),
                      SizedBox(height: PanAfricanSpacing.sm),
                      TextField(
                        controller: _goals,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Goals for next session', border: OutlineInputBorder()),
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                      TextField(
                        controller: _notes,
                        maxLines: 5,
                        decoration: const InputDecoration(labelText: 'Session notes', border: OutlineInputBorder()),
                      ),
                      SizedBox(height: PanAfricanSpacing.sm),
                      Text('Comprehensibility: ${_r1.round()}', style: PanAfricanTypography.bodySmall(context)),
                      Slider(value: _r1, min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => _r1 = v)),
                      Text('Confidence: ${_r2.round()}', style: PanAfricanTypography.bodySmall(context)),
                      Slider(value: _r2, min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => _r2 = v)),
                      Text('Politeness/register: ${_r3.round()}', style: PanAfricanTypography.bodySmall(context)),
                      Slider(value: _r3, min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => _r3 = v)),
                      SizedBox(height: PanAfricanSpacing.sm),
                      FilledButton(
                        onPressed: _submitRubric,
                        child: const Text('Save rubric + generate summary'),
                      ),
                    ],
                  ],
                ),
    );
  }
}

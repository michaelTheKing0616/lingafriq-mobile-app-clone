import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lingafriq/services/learning/code_switch_session_service.dart';
import 'package:lingafriq/services/learning/register_coach_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Dev / QA surface for **Phase 2** APIs: code-switch session + register coach (JWT required).
/// Conversation practice (speak missions) lives on `conversation-scenarios`; tone / phrase DNA / AR have dedicated routes.
class SpeakEngineLabScreen extends StatefulWidget {
  const SpeakEngineLabScreen({super.key});

  @override
  State<SpeakEngineLabScreen> createState() => _SpeakEngineLabScreenState();
}

class _SpeakEngineLabScreenState extends State<SpeakEngineLabScreen> {
  final _codeSwitch = CodeSwitchSessionService();
  final _registerCoach = RegisterCoachService();

  final _langCtrl = TextEditingController(text: 'yoruba');
  final _topicCtrl = TextEditingController(text: 'market_bargain');
  final _utteranceCtrl = TextEditingController(text: 'Give me that.');
  final _coachLangCtrl = TextEditingController(text: 'yoruba');
  String _registerContext = 'elder_respect';

  bool _loadingCode = false;
  bool _loadingCoach = false;
  String? _codeResult;
  String? _coachResult;
  String? _error;

  @override
  void dispose() {
    _langCtrl.dispose();
    _topicCtrl.dispose();
    _utteranceCtrl.dispose();
    _coachLangCtrl.dispose();
    super.dispose();
  }

  Future<void> _runCodeSwitch() async {
    setState(() {
      _loadingCode = true;
      _error = null;
      _codeResult = null;
    });
    try {
      final data = await _codeSwitch.startSession(
        language: _langCtrl.text,
        topic: _topicCtrl.text.isEmpty ? 'market_bargain' : _topicCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _codeResult = const JsonEncoder.withIndent('  ').convert(data);
        _loadingCode = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingCode = false;
      });
    }
  }

  Future<void> _runRegisterCoach() async {
    setState(() {
      _loadingCoach = true;
      _error = null;
      _coachResult = null;
    });
    try {
      final data = await _registerCoach.evaluate(
        utterance: _utteranceCtrl.text,
        language: _coachLangCtrl.text,
        context: _registerContext,
      );
      if (!mounted) return;
      setState(() {
        _coachResult = const JsonEncoder.withIndent('  ').convert(data);
        _loadingCoach = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingCoach = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speak engine · API lab')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Uses authenticated learning v2 endpoints. For speak-mission scoring, open Conversation practice.',
            style: PanAfricanTypography.bodyMedium(context),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Open conversation practice (speak missions)'),
            subtitle: const Text('Route: conversation-scenarios'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).pushNamed('/conversation-scenarios'),
          ),
          const Divider(height: 32),
          Text('Code-switch session', style: PanAfricanTypography.titleSmall(context)),
          const SizedBox(height: 8),
          TextField(
            controller: _langCtrl,
            decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _topicCtrl,
            decoration: const InputDecoration(labelText: 'Topic', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadingCode ? null : _runCodeSwitch,
            icon: _loadingCode
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: const Text('POST code-switch/session'),
          ),
          if (_codeResult != null) ...[
            const SizedBox(height: 8),
            SelectableText(_codeResult!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ],
          const Divider(height: 32),
          Text('Register coach', style: PanAfricanTypography.titleSmall(context)),
          const SizedBox(height: 8),
          TextField(
            controller: _utteranceCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Utterance', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _coachLangCtrl,
            decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _registerContext,
            decoration: const InputDecoration(labelText: 'Context', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'peer', child: Text('peer')),
              DropdownMenuItem(value: 'elder_respect', child: Text('elder_respect')),
              DropdownMenuItem(value: 'formal_work', child: Text('formal_work')),
              DropdownMenuItem(value: 'service_staff', child: Text('service_staff')),
            ],
            onChanged: (v) => setState(() => _registerContext = v ?? 'peer'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadingCoach ? null : _runRegisterCoach,
            icon: _loadingCoach
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.record_voice_over_rounded),
            label: const Text('POST register-coach'),
          ),
          if (_coachResult != null) ...[
            const SizedBox(height: 8),
            SelectableText(_coachResult!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

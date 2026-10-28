import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/services/ai_gateway_client.dart';
import 'package:lingafriq/services/content/persona_mission_service.dart';
import 'package:lingafriq/services/content/polie_conversation_service.dart';
import 'package:lingafriq/widgets/content/vocab_audio_controls.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

enum _MissionSendState { idle, sending, error }

/// Step-by-step persona mission with Polie roleplay prompts.
class PersonaMissionSessionScreen extends ConsumerStatefulWidget {
  const PersonaMissionSessionScreen({super.key, required this.session});

  final PersonaMissionSession session;

  @override
  ConsumerState<PersonaMissionSessionScreen> createState() =>
      _PersonaMissionSessionScreenState();
}

class _PersonaMissionSessionScreenState
    extends ConsumerState<PersonaMissionSessionScreen> {
  static const _personaErrorRetryKey = 'persona_error_retry';
  static const _personaErrorRetryCopy =
      "Couldn't reach the persona. Retry when you're ready.";

  final _input = TextEditingController();
  final List<_Turn> _turns = [];
  _MissionSendState _sendState = _MissionSendState.idle;
  String? _pendingText;

  PersonaMissionSession get _session => widget.session;
  bool get _isSending => _sendState == _MissionSendState.sending;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send({bool retry = false}) async {
    final text = retry ? _pendingText?.trim() : _input.text.trim();
    if (text == null ||
        text.isEmpty ||
        _isSending ||
        _session.isComplete) {
      return;
    }

    if (!retry) {
      setState(() {
        _pendingText = text;
        _turns.add(_Turn.user(text));
        _input.clear();
      });
    }

    setState(() => _sendState = _MissionSendState.sending);

    final gateway = AiGatewayClient(ref.read(client));
    final polie = ref.read(polieConversationServiceProvider);
    final lang = _session.mission.language;

    try {
      final step = _session.currentStep!;
      final personaPrefix = await polie.buildPersonaSystemPrefix(
        personaTitle: _session.mission.personaTitle,
        targetLanguage: lang,
        roleplayScene: '${_session.selectedSetting}: ${step.poliePrompt}',
      );
      final systemContext =
          '${personaPrefix.trim()}\n\n${_session.buildPolieSystemContext()}';
      final jsonPrompt = polie.buildRoleplayJsonPrompt(
        targetLanguage: lang,
        userMessage: text,
        personaPrefix: systemContext,
        responseStyle: 'natural',
      );
      final data = await gateway.completeChat(
        mode: 'roleplay',
        messages: [
          {'role': 'system', 'content': systemContext},
          {'role': 'user', 'content': jsonPrompt},
        ],
      );
      final reply = gateway.extractContent(data);
      final complete = reply.contains('[STEP_COMPLETE]');
      final clean = reply.replaceAll('[STEP_COMPLETE]', '').trim();
      if (!mounted) return;
      setState(() {
        _sendState = _MissionSendState.idle;
        _pendingText = null;
        _turns.add(_Turn.polie(clean));
        if (complete) {
          _session.currentStepIndex++;
          ref.read(personaMissionServiceProvider).saveMissionProgress(
                _session.mission.id,
                _session.currentStepIndex,
              );
        }
      });
      if (_session.isComplete && mounted) {
        ref.read(personaMissionServiceProvider).saveMissionProgress(
              _session.mission.id,
              _session.mission.steps.length,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LingAfriqUxVoice.lessonCompleteMessage(88)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sendState = _MissionSendState.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _session.currentStep;
    final total = _session.mission.steps.length;
    final index = _session.currentStepIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(_session.mission.personaTitle),
        backgroundColor: PanAfricanColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _session.isComplete ? 1 : (index + 1) / total,
            backgroundColor: PanAfricanColors.surfaceLight,
            color: PanAfricanColors.accent,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _session.isComplete
                      ? 'Mission complete'
                      : 'Step ${step?.step ?? total} of $total — ${step?.title ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Scene: ${_session.selectedSetting}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (step != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: step.vocab.map((v) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(v, style: const TextStyle(fontSize: 12)),
                          ),
                          VocabAudioControls(
                            language: _session.mission.language,
                            text: v,
                            compact: true,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.poliePrompt,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _turns.length,
              itemBuilder: (context, i) {
                final t = _turns[i];
                return Align(
                  alignment:
                      t.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                    ),
                    decoration: BoxDecoration(
                      color: t.isUser
                          ? PanAfricanColors.primary.withValues(alpha: 0.12)
                          : PanAfricanColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(t.text),
                  ),
                );
              },
            ),
          ),
          if (_sendState == _MissionSendState.error)
            Semantics(
              liveRegion: true,
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          _personaErrorRetryCopy,
                          key: Key(_personaErrorRetryKey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _send(retry: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_session.isComplete)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: !_isSending,
                        decoration: const InputDecoration(
                          hintText: 'Reply in character…',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isSending ? null : _send,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Turn {
  final String text;
  final bool isUser;

  _Turn.user(this.text) : isUser = true;
  _Turn.polie(this.text) : isUser = false;
}

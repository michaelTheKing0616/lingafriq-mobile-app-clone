import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/services/content/persona_mission_service.dart';
import 'package:lingafriq/services/content/polie_conversation_service.dart';
import 'package:lingafriq/widgets/content/vocab_audio_controls.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

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
  final _input = TextEditingController();
  final List<_Turn> _turns = [];
  bool _busy = false;

  PersonaMissionSession get _session => widget.session;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy || _session.isComplete) return;
    setState(() {
      _busy = true;
      _turns.add(_Turn.user(text));
      _input.clear();
    });

    final chat = ref.read(groqChatProvider.notifier);
    final polie = ref.read(polieConversationServiceProvider);
    final lang = _session.mission.language;
    await chat.setModeAndLanguage(
      mode: PolieMode.roleplay,
      sourceLanguage: 'English',
      targetLanguage: lang,
    );

    try {
      final step = _session.currentStep!;
      final personaPrefix = await polie.buildPersonaSystemPrefix(
        personaTitle: _session.mission.personaTitle,
        targetLanguage: lang,
        roleplayScene: '${_session.selectedSetting}: ${step.poliePrompt}',
      );
      final systemContext = '${personaPrefix.trim()}\n\n${_session.buildPolieSystemContext()}';
      final jsonPrompt = polie.buildRoleplayJsonPrompt(
        targetLanguage: lang,
        userMessage: text,
        personaPrefix: systemContext,
        responseStyle: 'natural',
      );
      final reply = await chat.sendMessage(
        jsonPrompt,
        systemPromptOverride: systemContext,
      );
      final complete = reply.contains('[STEP_COMPLETE]');
      final clean = reply.replaceAll('[STEP_COMPLETE]', '').trim();
      setState(() {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mission error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
                          Chip(label: Text(v, style: const TextStyle(fontSize: 12))),
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
                  Text(step.poliePrompt, style: Theme.of(context).textTheme.bodyMedium),
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
          if (!_session.isComplete)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        decoration: const InputDecoration(
                          hintText: 'Reply in character…',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _busy ? null : _send,
                      icon: _busy
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

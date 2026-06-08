import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingafriq/content/polie_conversation_prompt_builder.dart';
import 'package:lingafriq/services/content/polie_prompt_service.dart';

/// Merges personality bible snippets with Polie conversation mode.
class PolieConversationService {
  PolieConversationService(this._prompts);

  final PoliePromptService _prompts;

  static const _personaKeyMap = {
    'Encouraging Mentor': 'encouraging_mentor',
    'Cultural Elder': 'cultural_elder',
    'Streetwise Friend': 'streetwise_friend',
  };

  Future<String> buildPersonaSystemPrefix({
    String personaTitle = 'Encouraging Mentor',
    String targetLanguage = 'Yoruba',
    String? roleplayScene,
  }) async {
    final key = _personaKeyMap[personaTitle] ?? PolieConversationPromptBuilder.defaultPersonaKey;
    final data = await _prompts.loadSnippets();
    final personas = data['personas'] as Map<String, dynamic>? ?? {};
    final persona = (personas[key] as Map<String, dynamic>?) ?? {};
    final prefixTemplate = persona['system_prefix']?.toString() ??
        'You are Polie, a warm $targetLanguage mentor. Encourage first. Correct gently.';
    final prefix = prefixTemplate.replaceAll('{language}', targetLanguage);
    final scene = roleplayScene?.trim();
    return '''
$prefix
${scene != null && scene.isNotEmpty ? 'SCENE: $scene' : ''}
Speak boldly before speaking perfectly. Never shame the learner.
''';
  }

  String buildRoleplayJsonPrompt({
    required String targetLanguage,
    required String userMessage,
    required String personaPrefix,
    String responseStyle = 'natural',
    bool wantsEnglish = false,
    int nonce = 0,
    List<PolieConversationTurnContext> history = const [],
  }) {
    final builder = PolieConversationPromptBuilder();
    const styleInstruction = 'Stay in scene; teach through dialogue.';
    return builder.buildConversationJsonPrompt(
      targetLanguage: targetLanguage,
      userMessage: userMessage,
      responseStyle: responseStyle,
      styleInstruction: styleInstruction,
      wantsEnglish: wantsEnglish,
      personaSystemPrefix: personaPrefix,
      nonce: nonce,
      history: history,
    );
  }
}

final polieConversationServiceProvider = Provider<PolieConversationService>((ref) {
  return PolieConversationService(ref.read(poliePromptServiceProvider));
});

import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import 'package:lingafriq/services/ai/conversation_practice_enhancer.dart';

/// Builds Polie conversation JSON prompts aligned with the personality bible.
class PolieConversationPromptBuilder {
  PolieConversationPromptBuilder({
    ConversationPracticeEnhancer? enhancer,
  }) : _enhancer = enhancer ?? ConversationPracticeEnhancer();

  final ConversationPracticeEnhancer _enhancer;

  static const String defaultPersonaKey = 'encouraging_mentor';

  String buildConversationJsonPrompt({
    required String targetLanguage,
    required String userMessage,
    required String responseStyle,
    required String styleInstruction,
    required bool wantsEnglish,
    required String personaSystemPrefix,
    required int nonce,
    bool strict = false,
  }) {
    final lengthRule = strict
        ? 'MUST be in $targetLanguage ONLY, 8–14 sentences, >= 120 characters'
        : 'Prefer 8–14 sentences in $targetLanguage unless style is terse';

    final base = '''
Return STRICT JSON only. Do NOT wrap in markdown. Do NOT include text outside the JSON.
{
 "message_target":"A rich, complete reply in $targetLanguage. Use correct orthography/diacritics. Stay on-topic.",
 "message_english":"English translation of message_target OR null when not requested.",
 "correction":{"has_correction":false,"was_correct":true,"correction":"","note":"","tier":"correct"},
 "suggested_replies":["reply option 1 in $targetLanguage","reply option 2","reply option 3"],
 "new_vocab":[{"word":"new word","meaning":"meaning"}]
}

$personaSystemPrefix

MODE: CONVERSATION (LingAfriq — speak boldly before speaking perfectly)
Target language: $targetLanguage
Response style: $responseStyle
Style rules: $styleInstruction
User message: "$userMessage"

Correction hierarchy (set correction.tier):
- "correct" — natural and accurate; note in feedback tone: ${LingAfriqUxVoice.quizCorrect.first}
- "close" — meaning right, phrasing off; tier "close"
- "incorrect" — needs rework; tier "incorrect"; provide correction field

Rules:
- Answer the user's question in the first 1–2 sentences of message_target.
- $lengthRule
- Never shame accent or hesitation.
- If user made grammar mistakes, set has_correction true and fill correction + note.
${wantsEnglish ? '- Set message_english to faithful translation of message_target.' : '- Set message_english to null.'}
Nonce: $nonce
''';

    return _enhancer.getEnhancedPrompt(
      conversationId: 'polie_workspace',
      flowState: _flowForMessage(userMessage),
      basePrompt: base,
      userLevel: 'A1',
    );
  }

  ConversationFlow _flowForMessage(String text) {
    final t = text.toLowerCase();
    if (t.contains('greet') || t.contains('hello') || t.contains('bawo') || t.contains('sannu')) {
      return ConversationFlow.greeting;
    }
    if (t.contains('my name') || t.contains('i am from') || t.contains('introduce')) {
      return ConversationFlow.introduction;
    }
    if (t.contains('roleplay') || t.contains('pretend') || t.contains('scenario')) {
      return ConversationFlow.roleplay;
    }
    if (t.contains('bye') || t.contains('goodbye') || t.contains('see you')) {
      return ConversationFlow.wrapUp;
    }
    if (t.contains('?')) return ConversationFlow.questionAnswer;
    return ConversationFlow.topicDiscussion;
  }

  String personaPrefixFromSnippets(Map<String, dynamic> persona, String language) {
    final prefix = persona['system_prefix']?.toString() ?? '';
    return prefix.replaceAll('{language}', language);
  }
}

import 'package:lingafriq/content/lingafriq_ux_voice.dart';
import 'package:lingafriq/services/ai/conversation_practice_enhancer.dart';

/// A single past turn in the conversation. Used to give the LLM rolling
/// multi-turn context so it can maintain coherence and pronoun resolution
/// across a conversation.
class PolieConversationTurnContext {
  final String role; // 'user' | 'assistant'
  final String text;
  const PolieConversationTurnContext({required this.role, required this.text});

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

/// Builds Polie conversation JSON prompts aligned with the personality bible.
class PolieConversationPromptBuilder {
  PolieConversationPromptBuilder({
    ConversationPracticeEnhancer? enhancer,
  }) : _enhancer = enhancer ?? ConversationPracticeEnhancer();

  final ConversationPracticeEnhancer _enhancer;

  static const String defaultPersonaKey = 'encouraging_mentor';

  /// Maximum number of past turns (user+assistant pairs combined) to include
  /// in the rolling context buffer. 16 turns keeps token usage bounded while
  /// preserving enough coherence for nuanced multi-turn discussions.
  static const int maxHistoryTurns = 16;

  String buildConversationJsonPrompt({
    required String targetLanguage,
    required String userMessage,
    required String responseStyle,
    required String styleInstruction,
    required bool wantsEnglish,
    required String personaSystemPrefix,
    required int nonce,
    bool strict = false,
    List<PolieConversationTurnContext> history = const [],
  }) {
    final lengthRule = strict
        ? 'MUST be in $targetLanguage ONLY, 4–10 sentences, fully complete (no mid-word truncation)'
        : 'Prefer 4–10 natural sentences in $targetLanguage; shorter is fine when the user asks a small question';

    final historyBlock = _formatHistory(history);

    final base = '''
Return STRICT JSON only. Do NOT wrap in markdown. Do NOT include text outside the JSON.
{
 "message_target":"A natural reply in $targetLanguage. Use correct orthography/diacritics. Stay on-topic. Reference earlier turns when relevant.",
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
${historyBlock.isEmpty ? '' : 'Conversation so far:\n$historyBlock\n'}
Current user message: "$userMessage"

Correction hierarchy (set correction.tier):
- "correct" — natural and accurate; note in feedback tone: ${LingAfriqUxVoice.quizCorrect.first}
- "close" — meaning right, phrasing off; tier "close"
- "incorrect" — needs rework; tier "incorrect"; provide correction field

Rules:
- Answer the user's question directly in the first sentence of message_target.
- $lengthRule
- Use ONLY $targetLanguage in message_target (no English unless the user explicitly mixed it in).
- Maintain conversational coherence — reference earlier turns when natural.
- Never shame accent or hesitation.
- If user made grammar mistakes in the most recent turn, set has_correction true and fill correction + note.
${wantsEnglish ? '- Set message_english to a faithful, idiomatic translation of message_target.' : '- Set message_english to null.'}
- new_vocab MUST contain 0–3 fresh words the learner is unlikely to know yet from message_target, with concise English glosses.
- suggested_replies MUST contain 3 natural follow-up replies the user could send next, in $targetLanguage.
Nonce: $nonce
''';

    return _enhancer.getEnhancedPrompt(
      conversationId: 'polie_workspace',
      flowState: _flowForMessage(userMessage),
      basePrompt: base,
      userLevel: 'A1',
    );
  }

  /// Renders the rolling history buffer into a compact prompt block that
  /// preserves turn order and role labels without bloating tokens.
  String _formatHistory(List<PolieConversationTurnContext> history) {
    if (history.isEmpty) return '';
    final trimmed = history.length > maxHistoryTurns
        ? history.sublist(history.length - maxHistoryTurns)
        : history;
    final buf = StringBuffer();
    for (final turn in trimmed) {
      final role = turn.role.toLowerCase() == 'assistant' ? 'Polie' : 'User';
      final text = turn.text.replaceAll('\n', ' ').trim();
      if (text.isEmpty) continue;
      buf.writeln('- $role: "$text"');
    }
    return buf.toString().trimRight();
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

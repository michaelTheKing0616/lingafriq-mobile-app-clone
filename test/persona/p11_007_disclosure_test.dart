import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/historical_persona_registry.dart';
import 'package:lingafriq/ai/personas/historical_roleplay_controller.dart';
import 'package:lingafriq/ai/personas/persona_disclosure_badge.dart';

const _personasDir = 'lib/ai/personas';

void main() {
  test('P11-007_AC4_persona_prompts_contain_no_deny_ai_phrases', () {
    final dir = Directory(_personasDir);
    expect(dir.existsSync(), isTrue);
    for (final entity in dir.listSync(recursive: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('persona_disclosure_badge.dart')) continue;
      final text = entity.readAsStringSync();
      if (!text.contains('system') && !text.contains('RULES')) continue;
      final hit = scanPersonaPromptTextForDenyAi(text);
      expect(hit, isNull, reason: '${entity.path} contains forbidden "$hit"');
    }
  });

  test('P11-007_AC2_roleplay_system_prompt_requires_honest_ai_disclosure', () {
    final persona = HistoricalPersonaRegistry.findById('mandela_nelson');
    expect(persona, isNotNull);
    final controller = HistoricalRoleplayController(
      dio: Dio(BaseOptions(baseUrl: 'http://127.0.0.1/')),
    );
    final prompt = controller.buildRoleplaySystemPromptForTest(
      persona: persona!,
      languageCode: 'en',
      engagementType: HistoricalEngagementType.storyMode,
    );
    expect(scanPersonaPromptTextForDenyAi(prompt), isNull);
    expect(prompt.toLowerCase(), contains('ai recreation'));
    expect(prompt.toLowerCase(), contains('answer honestly'));
  });

  test('P11-007_AC3_opening_turn_flags_synthesised_voice', () async {
    final persona = HistoricalPersonaRegistry.findById('mandela_nelson');
    expect(persona, isNotNull);
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1/'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'ok': true,
                'speech_text': 'Sawubona, friend.',
                'language_teaching_points': [
                  {'type': 'vocabulary', 'content': 'sawubona = hello'},
                ],
                'emotion': 'encouraging',
                'next_beat': 'greet',
              },
            ),
          );
        },
      ),
    );
    final controller = HistoricalRoleplayController(dio: dio);
    final start = await controller.startPersonaSession(
      learnerId: 'p11_007',
      languageCode: 'en',
      personaId: persona!.id,
      engagementType: HistoricalEngagementType.storyMode,
    );
    expect(start.howBuilt.personaName, persona.displayName);
    expect(start.howBuilt.sourceSummary, isNotEmpty);
    expect(start.openingTurn.usesSynthesisedVoice, isTrue);
  });
}

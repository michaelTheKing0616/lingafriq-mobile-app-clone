import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/models/game/game_content_models.dart';
import 'package:lingafriq/models/game/game_session_model.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/screens/games/base_game_screen.dart';
import 'package:lingafriq/screens/games/game_scenario_loader.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';

/// Conversation Relay — multi-turn chain using bundled scenarios + Polie.
class ConversationRelayGame extends BaseGameScreen {
  const ConversationRelayGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.conversationRelay;

  @override
  ConsumerState<ConversationRelayGame> createState() =>
      _ConversationRelayGameState();
}

class _ConversationRelayGameState extends BaseGameScreenState<ConversationRelayGame> {
  final List<Map<String, dynamic>> _history = [];
  final _controller = TextEditingController();
  List<GameScenario> _scenarios = [];
  int _scenarioIndex = 0;
  int _turn = 0;
  static const _maxTurns = 8;
  bool _waiting = false;

  @override
  int getCardCount() => 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Future<void> onGameInitialized() async {
    _scenarios = loadBundledGameScenarios(
      ref,
      language: widget.language,
      game: 'ConversationRelay',
      max: 6,
    );
    if (_scenarios.isEmpty) {
      _scenarios = [
        GameScenario(
          id: 1,
          game: 'ConversationRelay',
          language: widget.language,
          cefr: 'A1',
          title: 'Greeting chain',
          prompt: 'Start with a respectful greeting in ${widget.language}.',
          expectedResponse: 'Reply with wellbeing, then ask a follow-up.',
          culturalNote: 'Relay = greet → respond → extend.',
        ),
      ];
    }
    _postSystem(_scenarios.first.prompt);
    setState(() {});
  }

  void _postSystem(String text) {
    _history.add({'type': 'system', 'text': text, 'at': DateTime.now()});
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _waiting || _turn >= _maxTurns) return;
    _controller.clear();
    HapticFeedback.lightImpact();
    setState(() {
      _waiting = true;
      _turn++;
      _history.add({'type': 'user', 'text': text, 'at': DateTime.now()});
    });

    final scenario = _scenarios[_scenarioIndex % _scenarios.length];
    final chat = ref.read(groqChatProvider.notifier);
    await chat.setModeAndLanguage(
      mode: PolieMode.conversation,
      targetLanguage: widget.language,
    );

    String reply;
    try {
      reply = await chat.sendMessage(
        '''
You are facilitating Conversation Relay in ${widget.language}.
Scenario: ${scenario.title}
Chain prompt: ${scenario.prompt}
Expected pattern: ${scenario.expectedResponse ?? ''}
Cultural note: ${scenario.culturalNote ?? ''}
User turn: "$text"
Reply in ${widget.language} only (2–4 sentences). End with a short question back to the learner.
''',
        systemPromptOverride:
            'Polie Conversation Relay. Use correct diacritics for ${widget.language}.',
      );
    } catch (_) {
      reply = scenario.expectedResponse ?? 'Continue in ${widget.language}.';
    }

    await completeTurn(
      cardId: 'relay_$_turn',
      result: GameResult.partial,
      durationMs: 3000,
      confidence: 0.7,
      feedback: {'turn': _turn, 'scenario': scenario.title},
    );

    if (!mounted) return;
    setState(() {
      _history.add({'type': 'ai', 'text': reply.trim(), 'at': DateTime.now()});
      _waiting = false;
    });

    if (_turn >= _maxTurns) {
      finishGame();
      return;
    }
    if (_turn % 2 == 0 && _scenarios.length > 1) {
      _scenarioIndex = (_scenarioIndex + 1) % _scenarios.length;
      _postSystem(_scenarios[_scenarioIndex].prompt);
      setState(() {});
    }
  }

  @override
  Widget buildGameContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(12.w),
          child: Text(
            'Conversation Relay',
            style: ModernGriotTypography.titleMedium(context: context),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _history.length,
            itemBuilder: (context, i) {
              final e = _history[i];
              final isUser = e['type'] == 'user';
              final isSystem = e['type'] == 'system';
              return Align(
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(12.w),
                  constraints: BoxConstraints(maxWidth: 0.85.sw),
                  decoration: BoxDecoration(
                    color: isSystem
                        ? ModernGriotColors.primary.withValues(alpha: 0.08)
                        : isUser
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(e['text'] as String? ?? ''),
                ),
              );
            },
          ),
        ),
        if (_waiting)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Your turn…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton.filled(
                  onPressed: _waiting ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

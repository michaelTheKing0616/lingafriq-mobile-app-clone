import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import '../../services/polie_content_generator.dart';
import 'base_game_screen.dart';
import 'mixins/round_progress_shell_mixin.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/game_ui/index.dart';
import 'dart:math';

/// Roleplay Adventure - Branching dialogue scenarios
class RoleplayAdventureGame extends BaseGameScreen {
  const RoleplayAdventureGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.roleplayAdventure;

  @override
  ConsumerState<RoleplayAdventureGame> createState() => _RoleplayAdventureGameState();
}

class _RoleplayAdventureGameState extends BaseGameScreenState<RoleplayAdventureGame>
    with RoundProgressGameShellMixin<RoleplayAdventureGame> {
  static const int _maxDialogueTurns = 5;

  String _scenario = 'market';
  String _npcMessage = '';
  final List<String> _dialogueHistory = [];
  final List<_DialogueOption> _options = [];
  int _turnCount = 0;

  @override
  int get gameRound => _turnCount;

  @override
  int get gameMaxRounds => _maxDialogueTurns;

  @override
  int get gameScore => session?.correctCount ?? 0;

  @override
  int getCardCount() => 1;

  @override
  Future<void> onGameInitialized() async {
    await _loadScenario();
  }

  Future<void> _loadScenario() async {
    final scenarios = ['market', 'clinic', 'transport', 'family'];
    _scenario = scenarios[Random().nextInt(scenarios.length)];
    try {
      final generator = ref.read(polieContentGeneratorProvider);
      final generated = await generator.generateGameContent(
        gameType: 'roleplay_adventure',
        language: widget.language,
        difficulty: widget.level,
        additionalContext:
            'Return exactly one NPC message and three learner reply options. '
            'Format:\nNPC: <message>\nCORRECT: <text>\nWRONG_LANGUAGE: <text>\nWRONG_CONTEXT: <text>',
      );
      final content = (generated['content']?.toString() ?? '').trim();
      final npc = _extractLabeledLine(content, 'NPC') ??
          'NPC: "Kí ni o fẹ́ ṣe lónìí?" (What would you like to do today?)';
      final correct =
          _extractLabeledLine(content, 'CORRECT') ?? 'Mo fẹ́ bá ọ sọ̀rọ̀ ní èdè wa.';
      final wrongLanguage =
          _extractLabeledLine(content, 'WRONG_LANGUAGE') ?? 'Hello, can we speak in English?';
      final wrongContext =
          _extractLabeledLine(content, 'WRONG_CONTEXT') ?? 'Mo dúpé gan-an.';

      if (!mounted) return;
      setState(() {
        _npcMessage = npc;
        _options
          ..clear()
          ..addAll([
            _DialogueOption(correct, 'correct'),
            _DialogueOption(wrongLanguage, 'wrong_language'),
            _DialogueOption(wrongContext, 'wrong_context'),
          ]);
        _options.shuffle(Random());
        _dialogueHistory.add(_npcMessage);
      });
    } catch (_) {
      if (!mounted) return;
      final fallback = _getLanguageFallback(widget.language);
      setState(() {
        _npcMessage = fallback['npc']! as String;
        _options
          ..clear()
          ..addAll(
            (fallback['options'] as List).map((o) =>
              _DialogueOption(o['text'] as String, o['result'] as String),
            ).toList(),
          );
        _options.shuffle(Random());
        _dialogueHistory.add(_npcMessage);
      });
    }
  }

  String? _extractLabeledLine(String source, String label) {
    final match =
        RegExp('^\\s*$label\\s*:\\s*(.+)\$', multiLine: true, caseSensitive: false)
            .firstMatch(source);
    return match?.group(1)?.trim();
  }

  void _selectOption(_DialogueOption option) {
    setState(() {
      _dialogueHistory.add('You: ${option.text}');
      _turnCount++;
    });

    final result = option.result == 'correct'
        ? GameResult.correct
        : GameResult.incorrect;

    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    completeTurn(
      cardId: 'roleplay_turn_$_turnCount',
      result: result,
      durationMs: duration,
      feedback: {'option': option.text, 'scenario': _scenario},
    );

    // NPC response
    Future.delayed(const Duration(seconds: 1), () async {
      if (mounted) {
        final npcFollowUp = await _generateNpcFollowUp(option, result);
        setState(() {
          _dialogueHistory.add(npcFollowUp);
        });
        await _loadScenario();

        if (_turnCount >= _maxDialogueTurns) {
          finishGame();
        }
      }
    });
  }

  Future<String> _generateNpcFollowUp(_DialogueOption option, GameResult result) async {
    try {
      final generator = ref.read(polieContentGeneratorProvider);
      final generated = await generator.generateGameContent(
        gameType: 'roleplay_adventure_followup',
        language: widget.language,
        difficulty: widget.level,
        additionalContext:
            'Return exactly one concise NPC follow-up line for this roleplay turn. '
            'Prefix with NPC:. Keep it under 20 words.\n'
            'Scenario: $_scenario\n'
            'Learner option: ${option.text}\n'
            'Result: ${result.name}',
      );

      final content = (generated['content']?.toString() ?? '').trim();
      if (content.isEmpty) {
        return _fallbackNpcFollowUp(result);
      }

      final firstLine = content
          .split('\n')
          .map((line) => line.trim())
          .firstWhere((line) => line.isNotEmpty, orElse: () => content);

      if (firstLine.startsWith('NPC:')) {
        return firstLine;
      }
      return 'NPC: $firstLine';
    } catch (_) {
      return _fallbackNpcFollowUp(result);
    }
  }

  String _fallbackNpcFollowUp(GameResult result) {
    final lang = widget.language.toLowerCase();
    if (result == GameResult.correct) {
      switch (lang) {
        case 'yoruba':
          return 'NPC: Ó dára! Ẹ jẹ́ ká tẹ̀síwájú.';
        case 'hausa':
          return 'NPC: Da kyau! Mu ci gaba.';
        case 'igbo':
          return 'NPC: Ọ dị mma! Ka anyị gaa n\'ihu.';
        case 'swahili':
          return 'NPC: Vizuri! Tuendelee.';
        case 'zulu':
          return 'NPC: Kuhle! Asiqhubeke.';
        default:
          return 'NPC: Good response. Let us continue.';
      }
    }
    switch (lang) {
      case 'yoruba':
        return 'NPC: Ẹ gbìyànjú lẹ́ẹ̀kan síi.';
      case 'hausa':
        return 'NPC: A sake gwadawa.';
      case 'igbo':
        return 'NPC: Gbalịa ọzọ.';
      case 'swahili':
        return 'NPC: Jaribu tena.';
      case 'zulu':
        return 'NPC: Zama futhi.';
      default:
        return 'NPC: Try again with a better fit.';
    }
  }

  static Map<String, dynamic> _getLanguageFallback(String language) {
    final scenarios = {
      'yoruba': {
        'npc': 'Vendor: "Báwo ní? Kí ni ẹ fẹ́ ra?"',
        'options': [
          {'text': 'Báwo ni? Mo fẹ́ ra ẹwà.', 'result': 'correct'},
          {'text': 'Hello, I want beans.', 'result': 'wrong_language'},
          {'text': 'Mo dúpé.', 'result': 'wrong_context'},
        ],
      },
      'hausa': {
        'npc': 'Mai sayarwa: "Sannu! Mene ne kuke so ku saya?"',
        'options': [
          {'text': 'Sannu! Ina son siyan wake.', 'result': 'correct'},
          {'text': 'Hello, I want beans.', 'result': 'wrong_language'},
          {'text': 'Na gode.', 'result': 'wrong_context'},
        ],
      },
      'igbo': {
        'npc': 'Onye ahịa: "Kedu? Gịnị ka ị chọrọ ịzụ?"',
        'options': [
          {'text': 'Kedu? Achọrọ m ịzụ agwa.', 'result': 'correct'},
          {'text': 'Hello, I want beans.', 'result': 'wrong_language'},
          {'text': 'Daalụ.', 'result': 'wrong_context'},
        ],
      },
      'swahili': {
        'npc': 'Muuzaji: "Habari! Unataka kununua nini?"',
        'options': [
          {'text': 'Habari! Nataka kununua maharagwe.', 'result': 'correct'},
          {'text': 'Hello, I want beans.', 'result': 'wrong_language'},
          {'text': 'Asante.', 'result': 'wrong_context'},
        ],
      },
      'zulu': {
        'npc': 'Umthengisi: "Sawubona! Ufuna ukuthenga ini?"',
        'options': [
          {'text': 'Sawubona! Ngifuna ukuthenga ubhontshisi.', 'result': 'correct'},
          {'text': 'Hello, I want beans.', 'result': 'wrong_language'},
          {'text': 'Ngiyabonga.', 'result': 'wrong_context'},
        ],
      },
    };
    return scenarios[language.toLowerCase()] ?? scenarios['yoruba']!;
  }

  @override
  Widget buildGameContent(BuildContext context) {
    try {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          children: [
            Semantics(
              label: 'Scenario: ${_scenario.toUpperCase()}',
              child: GameCard(
                child: Row(
                  children: [
                    const Icon(Icons.store, size: 24, semanticLabel: 'Scenario'),
                    SizedBox(width: 8.w),
                    Text(
                      'Scenario: ${_scenario.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: GameCard(
                child: ListView.builder(
                  itemCount: _dialogueHistory.length,
                  itemBuilder: (context, index) {
                    final message = _dialogueHistory[index];
                    final isNPC = message.startsWith('Vendor:') ||
                        message.startsWith('Doctor:') ||
                        message.startsWith('NPC:');
                    return Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Align(
                        alignment: isNPC ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: isNPC ? Colors.blue[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            message,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 12.h),
            ..._options.map((option) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Semantics(
                    label: 'Dialogue option: ${option.text}',
                    button: true,
                    child: PrimaryActionButton(
                      onPressed: () => _selectOption(option),
                      label: option.text,
                      icon: Icons.chat_bubble_outline_rounded,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('RoleplayAdventureGame buildGameContent: $e $st');
      rethrow;
    }
  }
}

class _DialogueOption {
  final String text;
  final String result; // 'correct', 'wrong_language', 'wrong_context'

  _DialogueOption(this.text, this.result);
}


import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

class _RoleplayAdventureGameState extends BaseGameScreenState<RoleplayAdventureGame> {
  final String _scenario = 'market';
  String _npcMessage = '';
  final List<String> _dialogueHistory = [];
  final List<_DialogueOption> _options = [];
  int _turnCount = 0;

  @override
  int getCardCount() => 1;

  @override
  Future<void> onGameInitialized() async {
    _loadScenario();
  }

  void _loadScenario() {
    // Mock scenarios
    final scenarios = {
      'market': {
        'npc': 'Vendor: "Báwo ní? Kí ni ẹ fẹ́ ra?" (How are you? What do you want to buy?)',
        'options': [
          _DialogueOption('Báwo ni? Mo fẹ́ ra ẹwà.', 'correct'),
          _DialogueOption('Hello, I want beans.', 'wrong_language'),
          _DialogueOption('Mo dúpé.', 'wrong_context'),
        ],
      },
      'doctor': {
        'npc': 'Doctor: "Kí ni o nílò?" (What do you need?)',
        'options': [
          _DialogueOption('Mo ní orí ń dun mi.', 'correct'),
          _DialogueOption('I have a headache.', 'wrong_language'),
          _DialogueOption('Mo dúpé.', 'wrong_context'),
        ],
      },
    };

    final scenario = scenarios[_scenario] ?? scenarios['market']!;
    setState(() {
      _npcMessage = scenario['npc'] as String;
      _options.clear();
      _options.addAll(scenario['options'] as List<_DialogueOption>);
      _dialogueHistory.add(_npcMessage);
    });
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
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (result == GameResult.correct) {
            _dialogueHistory.add('NPC: "Ó dáa! Ẹ ṣéun." (Good! Thank you.)');
          } else {
            _dialogueHistory.add('NPC: "Ṣé ẹ lè sọ ọ́ tún?" (Can you say it again?)');
          }
          _loadScenario(); // Next scenario
        });

        if (_turnCount >= 5) {
          finishGame();
        }
      }
    });
  }

  @override
  Widget buildGameContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.getGameType().displayName),
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, semanticLabel: 'Back'),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Scenario title
            Semantics(
              label: 'Scenario: ${_scenario.toUpperCase()}',
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Row(
                  children: [
                    Icon(Icons.store, size: 32, semanticLabel: 'Scenario'),
                    SizedBox(width: 2.w),
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
            ),
            SizedBox(height: 2.h),
            // Dialogue history
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: ListView.builder(
                    itemCount: _dialogueHistory.length,
                    itemBuilder: (context, index) {
                      final message = _dialogueHistory[index];
                      final isNPC = message.startsWith('Vendor:') ||
                          message.startsWith('Doctor:') ||
                          message.startsWith('NPC:');
                      return Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Align(
                          alignment: isNPC ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: isNPC ? Colors.blue[100] : Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
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
            ),
            SizedBox(height: 2.h),
            // Options
            ..._options.map((option) => Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Semantics(
                    label: 'Dialogue option: ${option.text}',
                    button: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _selectOption(option),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                        ),
                        child: Text(
                          option.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _DialogueOption {
  final String text;
  final String result; // 'correct', 'wrong_language', 'wrong_context'

  _DialogueOption(this.text, this.result);
}


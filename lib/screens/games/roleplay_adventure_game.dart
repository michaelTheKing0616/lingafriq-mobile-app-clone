import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/game_content_provider.dart';
import '../../models/game/game_content_models.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';
import 'base_game_screen.dart';

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
  ConsumerState<RoleplayAdventureGame> createState() =>
      _RoleplayAdventureGameState();
}

class _RoleplayAdventureGameState
    extends BaseGameScreenState<RoleplayAdventureGame> {
  List<GameScenario> _scenarios = [];
  int _currentIndex = 0;
  int _respectPoints = 75;
  String _npcDialogue = '';
  String _npcTranslation = '';
  List<_DecisionOption> _options = [];
  int? _selectedIndex;
  bool _showResult = false;
  final List<String> _dialogueHistory = [];

  static const _scenarioIcons = [
    Icons.store_rounded,
    Icons.local_hospital_rounded,
    Icons.directions_bus_rounded,
    Icons.family_restroom_rounded,
    Icons.school_rounded,
  ];

  @override
  int getCardCount() => 5;

  @override
  Future<void> onGameInitialized() async {
    final loaded = ref.read(
      gameScenariosProvider(GameContentFilter(
        language: widget.language,
        game: 'RoleplayAdventure',
      )),
    );
    if (loaded.isNotEmpty) {
      _scenarios = List.of(loaded)..shuffle(Random());
      if (_scenarios.length > 5) _scenarios = _scenarios.sublist(0, 5);
    } else {
      _scenarios = _fallbackScenarios();
    }
    _prepareRound();
  }

  List<GameScenario> _fallbackScenarios() => [
        GameScenario(id: 1, game: 'RoleplayAdventure', language: widget.language, cefr: 'A1', title: 'Market Greeting', prompt: 'A vendor greets you warmly at the stall.', expectedResponse: 'Respond with a culturally appropriate greeting.', culturalNote: 'Always greet elders before conducting business.'),
        GameScenario(id: 2, game: 'RoleplayAdventure', language: widget.language, cefr: 'A1', title: 'Family Visit', prompt: 'You arrive at a family compound for the first time.', expectedResponse: 'Show respect with a formal greeting.', culturalNote: 'Prostration or kneeling shows deep respect.'),
        GameScenario(id: 3, game: 'RoleplayAdventure', language: widget.language, cefr: 'A1', title: 'Transport Hub', prompt: 'A conductor calls out destinations loudly.', expectedResponse: 'State your destination clearly.', culturalNote: 'Negotiating fare before boarding is expected.'),
        GameScenario(id: 4, game: 'RoleplayAdventure', language: widget.language, cefr: 'A1', title: 'Elder Council', prompt: 'The village elder asks for your opinion.', expectedResponse: 'Offer a humble, respectful response.', culturalNote: 'Wisdom is valued over haste in council.'),
        GameScenario(id: 5, game: 'RoleplayAdventure', language: widget.language, cefr: 'A1', title: 'Festive Gathering', prompt: 'You are invited to share a meal at a ceremony.', expectedResponse: 'Accept graciously using proper etiquette.', culturalNote: 'Using the right hand is customary for eating.'),
      ];

  void _prepareRound() {
    if (_currentIndex >= _scenarios.length) {
      finishGame();
      return;
    }
    final scenario = _scenarios[_currentIndex];
    final rng = Random();
    final options = [
      _DecisionOption(
        text: scenario.expectedResponse ?? 'Respond respectfully',
        icon: Icons.handshake_rounded,
        color: ModernGriotColors.secondary,
        isCorrect: true,
      ),
      _DecisionOption(
        text: 'Switch to English casually',
        icon: Icons.language_rounded,
        color: ModernGriotColors.tertiary,
        isCorrect: false,
      ),
      _DecisionOption(
        text: 'Stay silent and walk away',
        icon: Icons.directions_walk_rounded,
        color: ModernGriotColors.error,
        isCorrect: false,
      ),
    ]..shuffle(rng);

    setState(() {
      _npcDialogue = scenario.prompt;
      _npcTranslation = scenario.title;
      _options = options;
      _selectedIndex = null;
      _showResult = false;
    });
  }

  void _selectOption(int index) {
    if (_showResult) return;
    HapticFeedback.mediumImpact();
    final option = _options[index];
    final isCorrect = option.isCorrect;
    final delta = isCorrect ? 10 : -15;

    setState(() {
      _selectedIndex = index;
      _showResult = true;
      _respectPoints = (_respectPoints + delta).clamp(0, 100);
      _dialogueHistory.add(option.text);
    });

    completeTurn(
      cardId: 'roleplay_$_currentIndex',
      result: isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 5000,
      feedback: {'option': option.text, 'respect': _respectPoints},
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _currentIndex++;
      _prepareRound();
    });
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (_scenarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final cs = Theme.of(context).colorScheme;
    final scenario = _currentIndex < _scenarios.length
        ? _scenarios[_currentIndex]
        : _scenarios.last;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 72.h, 16.w, 24.h),
          children: [
            _buildHeroScene(cs, scenario),
            SizedBox(height: 20.h),
            _buildDialogueBubble(cs),
            SizedBox(height: 20.h),
            ...List.generate(_options.length, (i) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildDecisionCard(cs, i),
            )),
            SizedBox(height: 16.h),
            if (scenario.culturalNote != null)
              GameCulturalNoteCard(
                title: "Griot's Wisdom",
                body: scenario.culturalNote!,
              ),
          ],
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: GameTopBar(
            onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
            currentStep: _currentIndex + 1,
            totalSteps: _scenarios.length,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroScene(ColorScheme cs, GameScenario scenario) {
    final iconData = _scenarioIcons[_currentIndex % _scenarioIcons.length];
    return Container(
      height: 530.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9E3D00), Color(0xFFFF7A35), Color(0xFFFDE8D0)],
        ),
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.lg,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 40.h, left: 0, right: 0,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 56.r,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Icon(iconData, size: 48.sp, color: Colors.white),
                ),
                SizedBox(height: 16.h),
                Text(
                  scenario.title,
                  style: ModernGriotTypography.headlineSmall(
                    context: context, color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Chapter ${_currentIndex + 1}',
                  style: ModernGriotTypography.labelLarge(
                    context: context,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24.h, left: 24.w, right: 24.w,
            child: _buildRespectMeter(cs),
          ),
        ],
      ),
    );
  }

  Widget _buildRespectMeter(ColorScheme cs) {
    final fraction = _respectPoints / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Respect', style: ModernGriotTypography.labelLarge(
              context: context, color: Colors.white,
            )),
            Text('$_respectPoints%', style: ModernGriotTypography.titleSmall(
              context: context, color: Colors.white,
            )),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          height: 12.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: ModernGriotRadius.borderPill,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8FBAC), Color(0xFF526124)],
                ),
                borderRadius: ModernGriotRadius.borderPill,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogueBubble(ColorScheme cs) {
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: ModernGriotColors.primaryContainer.withOpacity(0.3),
                child: Icon(Icons.person_rounded, size: 20.sp,
                    color: ModernGriotColors.primary),
              ),
              SizedBox(width: 12.w),
              Text('NPC', style: ModernGriotTypography.labelLarge(
                context: context, color: ModernGriotColors.primary,
              )),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(ModernGriotRadius.xl.r),
                bottomLeft: Radius.circular(ModernGriotRadius.xl.r),
                bottomRight: Radius.circular(ModernGriotRadius.xl.r),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_npcDialogue, style: ModernGriotTypography.bodyLarge(
                  context: context,
                )),
                SizedBox(height: 6.h),
                Text(_npcTranslation, style: ModernGriotTypography.bodySmall(
                  context: context,
                  color: ModernGriotColors.onSurfaceVariant,
                ).copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionCard(ColorScheme cs, int index) {
    final option = _options[index];
    final isSelected = _selectedIndex == index;
    final showCorrect = _showResult && option.isCorrect;
    final showWrong = _showResult && isSelected && !option.isCorrect;

    Color bgColor;
    if (showCorrect) {
      bgColor = ModernGriotColors.secondary.withOpacity(0.15);
    } else if (showWrong) {
      bgColor = ModernGriotColors.error.withOpacity(0.15);
    } else if (isSelected) {
      bgColor = option.color.withOpacity(0.12);
    } else {
      bgColor = cs.surfaceContainerLow;
    }

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: ModernGriotRadius.borderXl,
          boxShadow: isSelected ? ModernGriotShadows.md : ModernGriotShadows.sm,
          border: Border.all(
            color: isSelected
                ? option.color.withOpacity(0.5)
                : cs.outlineVariant.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40.r, height: 40.r,
              decoration: BoxDecoration(
                color: option.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(option.icon, size: 20.sp, color: option.color),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(option.text, style: ModernGriotTypography.bodyMedium(
                context: context,
              )),
            ),
            if (showCorrect)
              Icon(Icons.check_circle_rounded, color: ModernGriotColors.secondary, size: 24.sp),
            if (showWrong)
              Icon(Icons.cancel_rounded, color: ModernGriotColors.error, size: 24.sp),
          ],
        ),
      ),
    );
  }
}

class _DecisionOption {
  final String text;
  final IconData icon;
  final Color color;
  final bool isCorrect;

  const _DecisionOption({
    required this.text,
    required this.icon,
    required this.color,
    required this.isCorrect,
  });
}

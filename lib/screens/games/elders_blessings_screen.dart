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

class EldersBlessingsGame extends BaseGameScreen {
  const EldersBlessingsGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.eldersBlessingsChallenge;

  @override
  ConsumerState<EldersBlessingsGame> createState() =>
      _EldersBlessingsGameState();
}

class _EldersBlessingsGameState
    extends BaseGameScreenState<EldersBlessingsGame> {
  List<_EtiquetteScenario> _scenarios = [];
  int _currentIndex = 0;
  int _respectPoints = 850;
  String _rankTitle = 'Omoluabi Gold';
  List<_EtiquetteResponse> _responses = [];
  int? _selectedIndex;
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  int getCardCount() => 8;

  @override
  Future<void> onGameInitialized() async {
    final loaded = ref.read(
      gameScenariosProvider(GameContentFilter(
        language: widget.language,
        game: 'EldersBlessings',
      )),
    );
    if (loaded.isNotEmpty) {
      final scenarios = List.of(loaded)..shuffle(Random());
      _scenarios = scenarios.take(8).map((s) => _EtiquetteScenario(
        question: s.prompt,
        title: s.title,
        culturalWisdom: s.culturalNote ?? 'Respect for elders is the foundation of African culture.',
        correctResponse: s.expectedResponse ?? 'Formal Yoruba',
      )).toList();
    } else {
      _scenarios = _fallbackScenarios();
    }
    _prepareRound();
  }

  List<_EtiquetteScenario> _fallbackScenarios() => [
        const _EtiquetteScenario(question: 'An elder enters the room. What is the proper greeting?', title: 'Elder Enters', culturalWisdom: 'Rising to greet an elder shows deep respect in Yoruba culture.', correctResponse: 'Rise and prostrate'),
        const _EtiquetteScenario(question: 'You receive a blessing from a chief. How do you respond?', title: 'Chief\'s Blessing', culturalWisdom: 'Receiving blessings with both hands shows humility.', correctResponse: 'Cup both hands, bow head'),
        const _EtiquetteScenario(question: 'A royal figure speaks. What is expected?', title: 'Royal Address', culturalWisdom: 'Silence during a royal address shows deference to authority.', correctResponse: 'Listen in silence, bow'),
        const _EtiquetteScenario(question: 'You are offered kola nut at a ceremony. What do you do?', title: 'Kola Ceremony', culturalWisdom: 'He who brings kola brings life — a sacred Igbo proverb.', correctResponse: 'Accept with right hand'),
        const _EtiquetteScenario(question: 'An elder asks you to introduce yourself. How?', title: 'Introduction', culturalWisdom: 'Naming your lineage connects you to your ancestors.', correctResponse: 'State name and lineage'),
        const _EtiquetteScenario(question: 'You disagree with an elder\'s statement. What is proper?', title: 'Respectful Disagreement', culturalWisdom: 'One can disagree without disrespect — the tongue has no bone.', correctResponse: 'Acknowledge first, then share'),
        const _EtiquetteScenario(question: 'A grandmother blesses your journey. What is the response?', title: 'Journey Blessing', culturalWisdom: 'Grandmother\'s blessings carry the weight of generations.', correctResponse: 'Kneel and say Amen'),
        const _EtiquetteScenario(question: 'You arrive late to a gathering. How do you enter?', title: 'Late Arrival', culturalWisdom: 'A humble entrance shows awareness of one\'s impact on others.', correctResponse: 'Enter quietly, greet elders first'),
      ];

  void _prepareRound() {
    if (_currentIndex >= _scenarios.length) {
      finishGame();
      return;
    }
    final scenario = _scenarios[_currentIndex];
    final rng = Random();

    final responses = [
      _EtiquetteResponse(label: 'Formal Yoruba', text: scenario.correctResponse, color: const Color(0xFF9E3D00), isCorrect: true),
      _EtiquetteResponse(label: 'Royal Igbo', text: 'Nod quietly', color: const Color(0xFF526124), isCorrect: false),
      _EtiquetteResponse(label: 'Casual Pidgin', text: 'Just wave and move on', color: const Color(0xFF7B5733), isCorrect: false),
    ]..shuffle(rng);

    setState(() {
      _responses = responses;
      _selectedIndex = null;
      _showResult = false;
      _isCorrect = false;
      _updateRank();
    });
  }

  void _updateRank() {
    if (_respectPoints >= 900) {
      _rankTitle = 'Omoluabi Platinum';
    } else if (_respectPoints >= 700) {
      _rankTitle = 'Omoluabi Gold';
    } else if (_respectPoints >= 500) {
      _rankTitle = 'Omoluabi Silver';
    } else {
      _rankTitle = 'Omoluabi Bronze';
    }
  }

  void _selectResponse(int index) {
    if (_showResult) return;
    HapticFeedback.mediumImpact();
    final resp = _responses[index];

    setState(() {
      _selectedIndex = index;
      _showResult = true;
      _isCorrect = resp.isCorrect;
      _respectPoints = (_respectPoints + (resp.isCorrect ? 25 : -30)).clamp(0, 1000);
      _updateRank();
    });

    completeTurn(
      cardId: 'elders_$_currentIndex',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 5000,
      feedback: {'response': resp.text, 'respect': _respectPoints},
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
            _buildRespectMeter(cs),
            SizedBox(height: 20.h),
            _buildScenarioImage(cs, scenario),
            SizedBox(height: 20.h),
            _buildWisdomCard(cs, scenario),
            SizedBox(height: 20.h),
            ...List.generate(_responses.length, (i) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildResponseOption(cs, i),
            )),
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

  Widget _buildRespectMeter(ColorScheme cs) {
    final fraction = _respectPoints / 1000.0;
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.military_tech_rounded, size: 22.sp, color: ModernGriotColors.primaryContainer),
                  SizedBox(width: 8.w),
                  Text(_rankTitle, style: ModernGriotTypography.titleSmall(
                      context: context, color: ModernGriotColors.primary)),
                ],
              ),
              Text('$_respectPoints pts', style: ModernGriotTypography.labelLarge(
                  context: context, color: ModernGriotColors.onSurfaceVariant)),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            height: 10.h,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  gradient: ModernGriotGradients.signatureGradient,
                  borderRadius: ModernGriotRadius.borderPill,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioImage(ColorScheme cs, _EtiquetteScenario scenario) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDE8D0), Color(0xFFFF7A35)],
          ),
          borderRadius: ModernGriotRadius.borderXl,
          boxShadow: ModernGriotShadows.lg,
        ),
        child: Stack(
          children: [
            Positioned(
              right: 24.w, top: 24.h,
              child: Icon(Icons.auto_awesome_rounded, size: 40.sp,
                  color: Colors.white.withOpacity(0.3)),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(28.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 44.r,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: Icon(Icons.elderly_rounded, size: 44.sp,
                          color: Colors.white),
                    ),
                    SizedBox(height: 20.h),
                    Text(scenario.title,
                        style: ModernGriotTypography.titleLarge(
                            context: context, color: Colors.white),
                        textAlign: TextAlign.center),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: ModernGriotRadius.borderXl,
                      ),
                      child: Text(scenario.question,
                          textAlign: TextAlign.center,
                          style: ModernGriotTypography.bodyLarge(
                              context: context, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWisdomCard(ColorScheme cs, _EtiquetteScenario scenario) {
    return GameCulturalNoteCard(
      title: 'Cultural Wisdom',
      body: scenario.culturalWisdom,
      icon: Icons.psychology_rounded,
    );
  }

  Widget _buildResponseOption(ColorScheme cs, int index) {
    final resp = _responses[index];
    final isSelected = _selectedIndex == index;
    final showCorrect = _showResult && resp.isCorrect;
    final showWrong = _showResult && isSelected && !resp.isCorrect;

    Color bg;
    if (showCorrect) {
      bg = ModernGriotColors.secondary.withOpacity(0.12);
    } else if (showWrong) {
      bg = ModernGriotColors.error.withOpacity(0.12);
    } else {
      bg = resp.color.withOpacity(isSelected ? 0.12 : 0.05);
    }

    return GestureDetector(
      onTap: () => _selectResponse(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: ModernGriotRadius.borderXl,
          border: Border.all(
            color: isSelected
                ? resp.color.withOpacity(0.5)
                : resp.color.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? ModernGriotShadows.md : ModernGriotShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: resp.color.withOpacity(0.15),
                borderRadius: ModernGriotRadius.borderPill,
              ),
              child: Text(resp.label, style: ModernGriotTypography.labelMedium(
                  context: context, color: resp.color)),
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(resp.text,
                style: ModernGriotTypography.bodyMedium(context: context))),
            if (showCorrect)
              Icon(Icons.check_circle_rounded, color: ModernGriotColors.secondary, size: 22.sp),
            if (showWrong)
              Icon(Icons.cancel_rounded, color: ModernGriotColors.error, size: 22.sp),
          ],
        ),
      ),
    );
  }
}

class _EtiquetteScenario {
  final String question;
  final String title;
  final String culturalWisdom;
  final String correctResponse;

  const _EtiquetteScenario({
    required this.question,
    required this.title,
    required this.culturalWisdom,
    required this.correctResponse,
  });
}

class _EtiquetteResponse {
  final String label;
  final String text;
  final Color color;
  final bool isCorrect;

  const _EtiquetteResponse({
    required this.label,
    required this.text,
    required this.color,
    required this.isCorrect,
  });
}

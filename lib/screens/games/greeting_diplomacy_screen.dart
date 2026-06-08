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

class GreetingDiplomacyGame extends BaseGameScreen {
  const GreetingDiplomacyGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.greetingDiplomacyChallenge;

  @override
  ConsumerState<GreetingDiplomacyGame> createState() =>
      _GreetingDiplomacyGameState();
}

class _GreetingDiplomacyGameState
    extends BaseGameScreenState<GreetingDiplomacyGame> {
  static const _characters = [
    _CharacterType(name: 'Chief', formality: 'Very Formal', icon: Icons.account_balance_rounded, color: Color(0xFF9E3D00)),
    _CharacterType(name: 'Trader', formality: 'Semi-Formal', icon: Icons.store_rounded, color: Color(0xFF526124)),
    _CharacterType(name: 'Peer', formality: 'Casual', icon: Icons.people_rounded, color: Color(0xFF7B5733)),
    _CharacterType(name: 'In-law', formality: 'Respectful', icon: Icons.family_restroom_rounded, color: Color(0xFF4A6741)),
  ];

  List<_GreetingChallenge> _challenges = [];
  int _currentIndex = 0;
  int? _activeCharacterIndex;
  String _greetingSpeech = '';
  List<_GreetingResponse> _responses = [];
  int? _selectedResponse;
  bool _showResult = false;
  bool _isCorrect = false;
  bool _showPerfectMatch = false;

  @override
  int getCardCount() => 8;

  @override
  bool get requiresPhraseCards => false;

  @override
  Future<void> onGameInitialized() async {
    final loaded = ref.read(
      gameScenariosProvider(GameContentFilter(
        language: widget.language,
        game: 'GreetingDiplomacy',
      )),
    );
    if (loaded.isNotEmpty) {
      final scenarios = List.of(loaded)..shuffle(Random());
      _challenges = scenarios.take(8).map((s) => _GreetingChallenge(
        characterIndex: Random().nextInt(_characters.length),
        greeting: s.prompt,
        correctResponse: s.expectedResponse ?? 'Formal greeting',
        culturalNote: s.culturalNote,
      )).toList();
    } else {
      _challenges = _fallbackChallenges();
    }
    _prepareRound();
  }

  List<_GreetingChallenge> _fallbackChallenges() {
    final rng = Random();
    return List.generate(8, (i) => _GreetingChallenge(
      characterIndex: i % _characters.length,
      greeting: ['E ku irole, baba', 'Bawo ni, ore mi?', 'Shikamoo, mzee', 'Habari za asubuhi?', 'Kedu, nwanne m?', 'Ndewo, nna anyi', 'Sannu, alhaji', 'Ina kwana?'][i],
      correctResponse: ['Prostrate in respect', 'Casual fist bump', 'Touch forehead, bow', 'Warm handshake', 'Hug warmly', 'Kneel briefly', 'Bow slightly', 'Firm handshake'][i],
      culturalNote: 'Match greeting formality to the person\'s social standing.',
    ));
  }

  void _prepareRound() {
    if (_currentIndex >= _challenges.length) {
      finishGame();
      return;
    }
    final challenge = _challenges[_currentIndex];
    final rng = Random();

    final correct = _GreetingResponse(label: 'A', text: challenge.correctResponse, isCorrect: true);
    final wrong1 = _GreetingResponse(label: 'B', text: 'Wave from a distance', isCorrect: false);
    final wrong2 = _GreetingResponse(label: 'C', text: 'Nod silently', isCorrect: false);
    final responses = [correct, wrong1, wrong2]..shuffle(rng);
    for (var i = 0; i < responses.length; i++) {
      responses[i] = _GreetingResponse(
        label: String.fromCharCode(65 + i),
        text: responses[i].text,
        isCorrect: responses[i].isCorrect,
      );
    }

    setState(() {
      _activeCharacterIndex = challenge.characterIndex;
      _greetingSpeech = challenge.greeting;
      _responses = responses;
      _selectedResponse = null;
      _showResult = false;
      _isCorrect = false;
      _showPerfectMatch = false;
    });
  }

  void _selectResponse(int index) {
    if (_showResult) return;
    HapticFeedback.mediumImpact();
    final resp = _responses[index];

    setState(() {
      _selectedResponse = index;
      _showResult = true;
      _isCorrect = resp.isCorrect;
      if (_isCorrect) _showPerfectMatch = true;
    });

    completeTurn(
      cardId: 'greeting_$_currentIndex',
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 5000,
      feedback: {'response': resp.text, 'character': _characters[_activeCharacterIndex!].name},
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _currentIndex++;
      _prepareRound();
    });
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (_challenges.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16.w, 72.h, 16.w, 24.h),
          children: [
            _buildCharacterGrid(cs),
            SizedBox(height: 20.h),
            if (_activeCharacterIndex != null) ...[
              _buildChallengeCanvas(cs),
              SizedBox(height: 20.h),
              if (_showPerfectMatch) _buildPerfectBanner(cs),
              if (_showPerfectMatch) SizedBox(height: 16.h),
              ...List.generate(_responses.length, (i) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildResponseCard(cs, i),
              )),
            ],
          ],
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: GameTopBar(
            onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
            currentStep: _currentIndex + 1,
            totalSteps: _challenges.length,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterGrid(ColorScheme cs) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.6,
      children: List.generate(_characters.length, (i) {
        final c = _characters[i];
        final isActive = _activeCharacterIndex == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isActive
                ? c.color.withOpacity(0.15)
                : cs.surfaceContainerLow,
            borderRadius: ModernGriotRadius.borderXl,
            border: Border.all(
              color: isActive ? c.color : cs.outlineVariant.withOpacity(0.15),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? ModernGriotShadows.md : ModernGriotShadows.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: c.color.withOpacity(0.15),
                child: Icon(c.icon, size: 22.sp, color: c.color),
              ),
              SizedBox(height: 6.h),
              Text(c.name, style: ModernGriotTypography.labelLarge(
                  context: context, color: c.color)),
              Text(c.formality, style: ModernGriotTypography.bodySmall(
                  context: context, color: ModernGriotColors.onSurfaceVariant)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChallengeCanvas(ColorScheme cs) {
    final c = _characters[_activeCharacterIndex!];
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(20.r),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32.r,
            backgroundColor: c.color.withOpacity(0.15),
            child: Icon(c.icon, size: 32.sp, color: c.color),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: c.color.withOpacity(0.08),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(ModernGriotRadius.xl.r),
                bottomLeft: Radius.circular(ModernGriotRadius.xl.r),
                bottomRight: Radius.circular(ModernGriotRadius.xl.r),
              ),
            ),
            child: Text(
              '"$_greetingSpeech"',
              textAlign: TextAlign.center,
              style: ModernGriotTypography.bodyLarge(
                context: context, color: c.color,
              ).copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 8.h),
          Text('How do you respond?', style: ModernGriotTypography.labelMedium(
              context: context, color: ModernGriotColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildPerfectBanner(ColorScheme cs) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: ModernGriotGradients.forestGrowth,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.glow(ModernGriotColors.secondary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 24.sp),
          SizedBox(width: 8.w),
          Text('PERFECT MATCH', style: ModernGriotTypography.titleMedium(
              context: context, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildResponseCard(ColorScheme cs, int index) {
    final resp = _responses[index];
    final isSelected = _selectedResponse == index;
    final showCorrect = _showResult && resp.isCorrect;
    final showWrong = _showResult && isSelected && !resp.isCorrect;

    Color bg;
    if (showCorrect) {
      bg = ModernGriotColors.secondary.withOpacity(0.12);
    } else if (showWrong) {
      bg = ModernGriotColors.error.withOpacity(0.12);
    } else {
      bg = cs.surfaceContainerLow;
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
                ? ModernGriotColors.primary.withOpacity(0.5)
                : cs.outlineVariant.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: ModernGriotShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36.r, height: 36.r,
              decoration: BoxDecoration(
                color: ModernGriotColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(resp.label,
                  style: ModernGriotTypography.titleSmall(
                      context: context, color: ModernGriotColors.primary))),
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

class _CharacterType {
  final String name;
  final String formality;
  final IconData icon;
  final Color color;

  const _CharacterType({
    required this.name,
    required this.formality,
    required this.icon,
    required this.color,
  });
}

class _GreetingChallenge {
  final int characterIndex;
  final String greeting;
  final String correctResponse;
  final String? culturalNote;

  const _GreetingChallenge({
    required this.characterIndex,
    required this.greeting,
    required this.correctResponse,
    this.culturalNote,
  });
}

class _GreetingResponse {
  final String label;
  final String text;
  final bool isCorrect;

  const _GreetingResponse({
    required this.label,
    required this.text,
    required this.isCorrect,
  });
}

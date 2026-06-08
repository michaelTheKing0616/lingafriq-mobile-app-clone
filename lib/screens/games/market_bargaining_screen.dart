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

class MarketBargainingGame extends BaseGameScreen {
  const MarketBargainingGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.marketBargainingSimulator;

  @override
  ConsumerState<MarketBargainingGame> createState() =>
      _MarketBargainingGameState();
}

class _MarketBargainingGameState
    extends BaseGameScreenState<MarketBargainingGame> {
  List<GameScenario> _scenarios = [];
  int _currentIndex = 0;
  int _inventory = 0;
  int _askingPrice = 0;
  int _budget = 0;
  String _vendorSpeech = '';
  String _vendorTranslation = '';
  List<_BargainOption> _options = [];
  int? _selectedIndex;
  bool _showResult = false;
  bool _dealWon = false;

  @override
  int getCardCount() => 5;

  @override
  bool get requiresPhraseCards => false;

  @override
  Future<void> onGameInitialized() async {
    final loaded = ref.read(
      gameScenariosProvider(GameContentFilter(
        language: widget.language,
        game: 'MarketBargaining',
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
        GameScenario(id: 1, game: 'MarketBargaining', language: widget.language, cefr: 'A1', title: 'Fabric Stall', prompt: 'Kí ní iye àṣọ yìí?', expectedResponse: 'Polite greeting first', culturalNote: 'In Yoruba markets, always greet the vendor before asking for prices.'),
        GameScenario(id: 2, game: 'MarketBargaining', language: widget.language, cefr: 'A1', title: 'Spice Vendor', prompt: 'Ẹ wá ra ata rodo!', expectedResponse: 'Complement quality', culturalNote: 'Complementing the vendor\'s goods opens a positive bargaining space.'),
        GameScenario(id: 3, game: 'MarketBargaining', language: widget.language, cefr: 'A1', title: 'Bead Trader', prompt: 'Ìlẹ̀kẹ̀ yìí dára púpọ̀.', expectedResponse: 'Firm counter offer', culturalNote: 'Walking away slowly often brings the price down.'),
        GameScenario(id: 4, game: 'MarketBargaining', language: widget.language, cefr: 'A1', title: 'Fruit Seller', prompt: 'Oṣàn mi dùn gan-an!', expectedResponse: 'Ask for a bulk discount', culturalNote: 'Buying in bulk is a respected bargaining tactic.'),
        GameScenario(id: 5, game: 'MarketBargaining', language: widget.language, cefr: 'A1', title: 'Pottery Maker', prompt: 'Iṣẹ́ ọwọ́ ni èyí.', expectedResponse: 'Acknowledge craftsmanship', culturalNote: 'Appreciating handwork before negotiating shows cultural awareness.'),
      ];

  void _prepareRound() {
    if (_currentIndex >= _scenarios.length) {
      finishGame();
      return;
    }
    final scenario = _scenarios[_currentIndex];
    final rng = Random();
    _askingPrice = (rng.nextInt(5) + 3) * 500;
    _budget = (_askingPrice * 0.6).round();

    _options = [
      _BargainOption(text: 'Polite Greeting', icon: Icons.waving_hand_rounded, color: const Color(0xFF526124), isCorrect: true),
      _BargainOption(text: 'Firm Counter', icon: Icons.gavel_rounded, color: const Color(0xFF9E3D00), isCorrect: false),
      _BargainOption(text: 'Complement Quality', icon: Icons.thumb_up_rounded, color: const Color(0xFF7B5733), isCorrect: false),
    ]..shuffle(rng);

    setState(() {
      _vendorSpeech = scenario.prompt;
      _vendorTranslation = scenario.title;
      _selectedIndex = null;
      _showResult = false;
      _dealWon = false;
    });
  }

  void _selectOption(int index) {
    if (_showResult) return;
    HapticFeedback.mediumImpact();
    final option = _options[index];

    setState(() {
      _selectedIndex = index;
      _showResult = true;
      _dealWon = option.isCorrect;
      if (_dealWon) _inventory++;
    });

    completeTurn(
      cardId: 'bargain_$_currentIndex',
      result: _dealWon ? GameResult.correct : GameResult.incorrect,
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 5000,
      feedback: {'option': option.text, 'price': _askingPrice},
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
            _buildMarketScene(cs),
            SizedBox(height: 16.h),
            _buildSpeechBubble(cs),
            SizedBox(height: 16.h),
            _buildPriceRow(cs),
            SizedBox(height: 20.h),
            ...List.generate(_options.length, (i) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildOptionPill(cs, i),
            )),
            SizedBox(height: 16.h),
            if (scenario.culturalNote != null)
              GameCulturalNoteCard(
                title: 'Bargaining Insight',
                body: scenario.culturalNote!,
              ),
            SizedBox(height: 12.h),
            _buildQuestProgress(cs),
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
        Positioned(
          top: 62.h, right: 20.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: ModernGriotColors.secondary,
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_rounded, size: 16.sp, color: ModernGriotColors.onSecondary),
                SizedBox(width: 4.w),
                Text('$_inventory', style: ModernGriotTypography.labelLarge(
                  context: context, color: ModernGriotColors.onSecondary,
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarketScene(ColorScheme cs) {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF7A35), Color(0xFFFDE8D0)],
        ),
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.md,
      ),
      child: Stack(
        children: [
          Positioned(
            right: 24.w, bottom: 20.h,
            child: Icon(Icons.storefront_rounded, size: 80.sp,
                color: Colors.white.withOpacity(0.3)),
          ),
          Positioned(
            left: 24.w, top: 24.h,
            child: CircleAvatar(
              radius: 36.r,
              backgroundColor: Colors.white.withOpacity(0.3),
              child: Icon(Icons.person_rounded, size: 36.sp, color: Colors.white),
            ),
          ),
          Positioned(
            left: 24.w, bottom: 20.h,
            child: Text(_vendorTranslation,
                style: ModernGriotTypography.titleLarge(
                    context: context, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble(ColorScheme cs) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(ModernGriotRadius.xl.r),
          bottomLeft: Radius.circular(ModernGriotRadius.xl.r),
          bottomRight: Radius.circular(ModernGriotRadius.xl.r),
        ),
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_vendorSpeech, style: ModernGriotTypography.bodyLarge(
            context: context, color: ModernGriotColors.primary,
          ).copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: 4.h),
          Text('(${_scenarios[_currentIndex < _scenarios.length ? _currentIndex : _scenarios.length - 1].expectedResponse ?? ""})',
            style: ModernGriotTypography.bodySmall(context: context,
                color: ModernGriotColors.onSurfaceVariant).copyWith(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: ModernGriotColors.error.withOpacity(0.1),
              borderRadius: ModernGriotRadius.borderXl,
              border: Border.all(color: ModernGriotColors.error.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text('Asking', style: ModernGriotTypography.labelMedium(
                    context: context, color: ModernGriotColors.error)),
                Text('₦$_askingPrice', style: ModernGriotTypography.titleLarge(
                    context: context, color: ModernGriotColors.error)),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: ModernGriotColors.secondary.withOpacity(0.1),
              borderRadius: ModernGriotRadius.borderXl,
              border: Border.all(color: ModernGriotColors.secondary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text('Budget', style: ModernGriotTypography.labelMedium(
                    context: context, color: ModernGriotColors.secondary)),
                Text('₦$_budget', style: ModernGriotTypography.titleLarge(
                    context: context, color: ModernGriotColors.secondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionPill(ColorScheme cs, int index) {
    final option = _options[index];
    final isSelected = _selectedIndex == index;
    final showCorrect = _showResult && option.isCorrect;
    final showWrong = _showResult && isSelected && !option.isCorrect;

    Color bg;
    if (showCorrect) {
      bg = ModernGriotColors.secondary.withOpacity(0.15);
    } else if (showWrong) {
      bg = ModernGriotColors.error.withOpacity(0.15);
    } else {
      bg = option.color.withOpacity(isSelected ? 0.12 : 0.06);
    }

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: ModernGriotRadius.borderPill,
          border: Border.all(
            color: isSelected ? option.color.withOpacity(0.5)
                : option.color.withOpacity(0.2), width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(option.icon, size: 22.sp, color: option.color),
            SizedBox(width: 12.w),
            Expanded(child: Text(option.text,
                style: ModernGriotTypography.labelLarge(context: context,
                    color: option.color))),
            if (showCorrect)
              Icon(Icons.check_circle_rounded, color: ModernGriotColors.secondary, size: 22.sp),
            if (showWrong)
              Icon(Icons.cancel_rounded, color: ModernGriotColors.error, size: 22.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestProgress(ColorScheme cs) {
    final fraction = (_currentIndex + 1) / _scenarios.length;
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Artifact Quest', style: ModernGriotTypography.labelLarge(
              context: context, color: ModernGriotColors.primary)),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: ModernGriotRadius.borderPill,
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8.h,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(ModernGriotColors.primaryContainer),
            ),
          ),
          SizedBox(height: 6.h),
          Text('${_currentIndex + 1} of ${_scenarios.length} stalls visited',
              style: ModernGriotTypography.bodySmall(context: context)),
        ],
      ),
    );
  }
}

class _BargainOption {
  final String text;
  final IconData icon;
  final Color color;
  final bool isCorrect;

  const _BargainOption({
    required this.text,
    required this.icon,
    required this.color,
    required this.isCorrect,
  });
}

import 'dart:async';
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

/// Memory Map — a card-matching game where players flip tiles to find
/// word ↔ meaning pairs in a 3×4 grid.
///
/// Uses an Arewa-inspired diamond pattern background and tracks elapsed
/// time, moves, and pairs found. Matched pairs glow green; mismatched
/// tiles flip back after a brief delay.
class MemoryMapGame extends BaseGameScreen {
  const MemoryMapGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.memoryMap;

  @override
  ConsumerState<MemoryMapGame> createState() => _MemoryMapGameState();
}

class _MemoryMapGameState extends BaseGameScreenState<MemoryMapGame> {
  List<_MemoryTile> _tiles = [];
  final List<int> _flippedIndices = [];
  int _moves = 0;
  int _pairsFound = 0;
  int _totalPairs = 0;
  bool _isChecking = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _clockTimer;
  int _elapsedSeconds = 0;

  @override
  int getCardCount() => 12;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    final allCards = gameProv.availableCards;
    if (allCards.length < 3) {
      setError('Need at least 3 cards for Memory Map. Try another language.');
      return;
    }

    final pairCount = min(6, allCards.length);
    final selected = (allCards.toList()..shuffle(Random())).take(pairCount);

    final tiles = <_MemoryTile>[];
    for (final card in selected) {
      tiles.add(_MemoryTile(
        text: card.text,
        pairId: card.cardId,
        isForeign: true,
        cardId: card.cardId,
      ));
      tiles.add(_MemoryTile(
        text: card.gloss,
        pairId: card.cardId,
        isForeign: false,
        cardId: card.cardId,
      ));
    }
    tiles.shuffle(Random());

    setState(() {
      _tiles = tiles;
      _totalPairs = pairCount;
      _pairsFound = 0;
      _moves = 0;
      _elapsedSeconds = 0;
    });

    _stopwatch
      ..reset()
      ..start();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds = _stopwatch.elapsed.inSeconds);
    });
  }

  void _flipTile(int index) {
    if (_isChecking) return;
    final tile = _tiles[index];
    if (tile.isFlipped || tile.isMatched) return;
    if (_flippedIndices.length >= 2) return;

    HapticFeedback.lightImpact();
    setState(() {
      tile.isFlipped = true;
      _flippedIndices.add(index);
    });

    if (_flippedIndices.length == 2) {
      _moves++;
      _checkMatch();
    }
  }

  Future<void> _checkMatch() async {
    _isChecking = true;
    final a = _tiles[_flippedIndices[0]];
    final b = _tiles[_flippedIndices[1]];
    final matched = a.pairId == b.pairId && a.isForeign != b.isForeign;

    await Future.delayed(matched
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 1000));
    if (!mounted) return;

    final durationMs = _stopwatch.elapsed.inMilliseconds;

    if (matched) {
      HapticFeedback.mediumImpact();
      setState(() {
        a.isMatched = true;
        b.isMatched = true;
        _pairsFound++;
      });
      await completeTurn(
        cardId: a.cardId,
        result: GameResult.correct,
        durationMs: durationMs,
        confidence: 1.0,
        feedback: {'pair': a.pairId, 'moves': _moves},
      );
    } else {
      setState(() {
        a.isFlipped = false;
        b.isFlipped = false;
      });
      await completeTurn(
        cardId: a.cardId,
        result: GameResult.incorrect,
        durationMs: durationMs,
        confidence: 0.0,
        feedback: {
          'attempted_a': a.text,
          'attempted_b': b.text,
          'moves': _moves,
        },
      );
    }

    _flippedIndices.clear();
    _isChecking = false;

    if (_pairsFound >= _totalPairs) {
      _stopwatch.stop();
      _clockTimer?.cancel();
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) finishGame();
    }
  }

  void _resetMap() {
    HapticFeedback.mediumImpact();
    _stopwatch.stop();
    _clockTimer?.cancel();
    _flippedIndices.clear();
    _isChecking = false;
    onGameInitialized();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  String? get appBarTitle =>
      _tiles.isEmpty ? null : 'Memory Map ($_pairsFound/$_totalPairs)';

  @override
  Widget buildGameContent(BuildContext context) {
    if (_tiles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final cs = Theme.of(context).colorScheme;

    return GriotSvgPatternBackground(
      pattern: GriotPattern.diamonds,
      child: Column(
        children: [
          GameTopBar(
            onClose: () => (widget.onBack ?? () => Navigator.pop(context))(),
            progress: _totalPairs > 0 ? _pairsFound / _totalPairs : 0,
            streak: _pairsFound,
            xp: _pairsFound * 15,
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: GriotBentoGrid(
              gap: 10,
              items: [
                GriotBentoItem(
                  span: 4,
                  child: GriotStatCard(
                    icon: Icons.timer_rounded,
                    iconColor: cs.tertiary,
                    value: _formattedTime,
                    label: 'Time',
                  ),
                ),
                GriotBentoItem(
                  span: 4,
                  child: GriotStatCard(
                    icon: Icons.layers_rounded,
                    iconColor: ModernGriotColors.secondary,
                    value: '$_pairsFound/$_totalPairs',
                    label: 'Pairs',
                  ),
                ),
                GriotBentoItem(
                  span: 4,
                  child: GriotStatCard(
                    icon: Icons.touch_app_rounded,
                    iconColor: cs.primary,
                    value: '$_moves',
                    label: 'Moves',
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10.h,
                  crossAxisSpacing: 10.w,
                  childAspectRatio: 0.78,
                ),
                itemCount: _tiles.length,
                itemBuilder: (context, index) => _buildFlipCard(index),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 16.h),
            child: Row(
              children: [
                Expanded(
                  child: GriotSecondaryButton(
                    label: 'Reset Map',
                    icon: Icons.refresh_rounded,
                    onPressed: _resetMap,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GriotGradientButton(
                    label: 'Next Level',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _pairsFound >= _totalPairs ? () => finishGame() : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipCard(int index) {
    final tile = _tiles[index];
    final isRevealed = tile.isFlipped || tile.isMatched;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _flipTile(index),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: isRevealed
            ? _buildTileFront(tile, index, cs)
            : _buildTileBack(index, cs),
      ),
    );
  }

  Widget _buildTileBack(int index, ColorScheme cs) {
    return Container(
      key: ValueKey('back_$index'),
      decoration: BoxDecoration(
        gradient: ModernGriotGradients.signatureGradient,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Center(
        child: Icon(
          Icons.diamond_rounded,
          size: 28.sp,
          color: Colors.white.withAlpha(80),
        ),
      ),
    );
  }

  Widget _buildTileFront(_MemoryTile tile, int index, ColorScheme cs) {
    final matched = tile.isMatched;

    Color bg = cs.surfaceContainerLowest;
    Color borderClr = cs.primary;
    if (matched) {
      bg = ModernGriotColors.secondaryContainer;
      borderClr = ModernGriotColors.secondary;
    }

    return Container(
      key: ValueKey('front_$index'),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: ModernGriotRadius.borderXl,
        border: Border.all(color: borderClr, width: 2),
        boxShadow: matched ? ModernGriotShadows.glow(ModernGriotColors.secondary) : ModernGriotShadows.sm,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(8.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (tile.isForeign)
                  Icon(
                    Icons.translate_rounded,
                    size: 16.sp,
                    color: cs.primary.withAlpha(120),
                  )
                else
                  Icon(
                    Icons.abc_rounded,
                    size: 16.sp,
                    color: cs.tertiary.withAlpha(120),
                  ),
                SizedBox(height: 6.h),
                Text(
                  tile.text,
                  style: ModernGriotTypography.titleSmall(
                    context: context,
                    color: tile.isForeign ? cs.primary : cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (matched)
            Positioned(
              top: 6.r,
              right: 6.r,
              child: Icon(
                Icons.check_circle_rounded,
                size: 18.sp,
                color: ModernGriotColors.secondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _MemoryTile {
  final String text;
  final String pairId;
  final bool isForeign;
  final String cardId;
  bool isFlipped;
  bool isMatched;

  _MemoryTile({
    required this.text,
    required this.pairId,
    required this.isForeign,
    required this.cardId,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

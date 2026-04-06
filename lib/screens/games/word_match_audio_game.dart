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
import '../../utils/pan_african_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';
import 'base_game_screen.dart';

class WordMatchAudioGame extends BaseGameScreen {
  const WordMatchAudioGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.wordMatchAudio;

  @override
  ConsumerState<WordMatchAudioGame> createState() => _WordMatchAudioGameState();
}

class _WordMatchAudioGameState extends BaseGameScreenState<WordMatchAudioGame> {
  List<_MatchTile> _leftTiles = [];
  List<_MatchTile> _rightTiles = [];
  String? _selectedLeft;
  String? _selectedRight;
  final Set<String> _matchedIds = {};
  final Set<String> _errorIds = {};
  int _consecutiveCorrect = 0;
  bool _showStreakBadge = false;

  @override
  int getCardCount() => 10;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    final cards = gameProv.availableCards;
    if (cards.isEmpty) return;

    final displayCards = cards.take(5).toList();
    setState(() {
      _leftTiles = displayCards
          .map((c) => _MatchTile(id: c.cardId, label: c.text, audioUrl: c.audioNativeUrl))
          .toList()
        ..shuffle(Random());
      _rightTiles = displayCards
          .map((c) => _MatchTile(id: c.cardId, label: c.gloss))
          .toList()
        ..shuffle(Random());
    });
  }

  void _selectTile(String side, String id) {
    if (_matchedIds.contains(id)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _errorIds.clear();
      if (side == 'left') {
        _selectedLeft = _selectedLeft == id ? null : id;
      } else {
        _selectedRight = _selectedRight == id ? null : id;
      }
    });
  }

  void _checkPairs() {
    if (_selectedLeft == null || _selectedRight == null) return;
    HapticFeedback.mediumImpact();

    final correct = _selectedLeft == _selectedRight;
    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    completeTurn(
      cardId: _selectedLeft!,
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      confidence: correct ? 1.0 : 0.0,
      userAction: 'matched_pair',
    );

    setState(() {
      if (correct) {
        _matchedIds.add(_selectedLeft!);
        _consecutiveCorrect++;
        if (_consecutiveCorrect >= 3 && !_showStreakBadge) {
          _showStreakBadge = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showStreakBadge = false);
          });
        }
      } else {
        _consecutiveCorrect = 0;
        _errorIds.addAll({_selectedLeft!, _selectedRight!});
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _errorIds.clear());
        });
      }
      _selectedLeft = null;
      _selectedRight = null;
    });

    if (_matchedIds.length == _leftTiles.length) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) finishGame();
      });
    }
  }

  _TileState _tileState(String id, bool isLeft) {
    if (_matchedIds.contains(id)) return _TileState.matched;
    if (_errorIds.contains(id)) return _TileState.error;
    final selected = isLeft ? _selectedLeft : _selectedRight;
    if (selected == id) return _TileState.selected;
    return _TileState.idle;
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (_leftTiles.isEmpty) {
      return Center(
        child: Text('No pairs available',
            style: ModernGriotTypography.bodyLarge(context: context)),
      );
    }

    final progress = _leftTiles.isEmpty ? 0.0 : _matchedIds.length / _leftTiles.length;
    final canCheck = _selectedLeft != null && _selectedRight != null;

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm),
            child: Column(
              children: [
                SizedBox(height: PanAfricanSpacing.sm),
                GriotProgressBar(value: progress, height: 6, showGlowTip: true),
                SizedBox(height: PanAfricanSpacing.sm),
                // Column headers
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text('Foreign Word',
                          style: ModernGriotTypography.labelLarge(context: context),
                          textAlign: TextAlign.center),
                    ),
                    SizedBox(width: PanAfricanSpacing.xs),
                    Expanded(
                      flex: 5,
                      child: Text('English Meaning',
                          style: ModernGriotTypography.labelLarge(context: context),
                          textAlign: TextAlign.center),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.xs),
                // Two-column tile layout
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: ListView.separated(
                          itemCount: _leftTiles.length,
                          separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.xs),
                          itemBuilder: (_, i) {
                            final tile = _leftTiles[i];
                            return _WordTile(
                              label: tile.label,
                              state: _tileState(tile.id, true),
                              showSpeaker: true,
                              onTap: () => _selectTile('left', tile.id),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: PanAfricanSpacing.xs),
                      Expanded(
                        flex: 5,
                        child: ListView.separated(
                          itemCount: _rightTiles.length,
                          separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.xs),
                          itemBuilder: (_, i) {
                            final tile = _rightTiles[i];
                            return _WordTile(
                              label: tile.label,
                              state: _tileState(tile.id, false),
                              onTap: () => _selectTile('right', tile.id),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                // CHECK PAIRS CTA
                GriotGradientButton(
                  label: 'CHECK PAIRS',
                  icon: Icons.check_circle_rounded,
                  onPressed: canCheck ? _checkPairs : null,
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                // Daily goal footer
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.md,
                    vertical: PanAfricanSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: ModernGriotColors.surfaceContainerHigh,
                    borderRadius: ModernGriotRadius.borderLg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_rounded,
                          size: 16.sp, color: ModernGriotColors.secondary),
                      SizedBox(width: 6.w),
                      Text(
                        'Daily Goal: ${_matchedIds.length}/${_leftTiles.length} pairs matched',
                        style: ModernGriotTypography.labelMedium(
                            context: context, color: ModernGriotColors.secondary),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
              ],
            ),
          ),
          // Streak badge
          if (_showStreakBadge)
            Positioned(
              top: 60.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.lg,
                    vertical: PanAfricanSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: ModernGriotGradients.signatureGradient,
                    borderRadius: ModernGriotRadius.borderPill,
                    boxShadow: ModernGriotShadows.lg,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          color: ModernGriotColors.onPrimary, size: 20.sp),
                      SizedBox(width: 6.w),
                      Text('Perfect Streak!',
                          style: ModernGriotTypography.titleSmall(
                              context: context, color: ModernGriotColors.onPrimary)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Tile states for word match
enum _TileState { idle, selected, matched, error }

class _WordTile extends StatelessWidget {
  final String label;
  final _TileState state;
  final bool showSpeaker;
  final VoidCallback onTap;

  const _WordTile({
    required this.label,
    required this.state,
    this.showSpeaker = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMatched = state == _TileState.matched;
    final isSelected = state == _TileState.selected;
    final isError = state == _TileState.error;

    Color bg;
    Color borderColor;
    double borderWidth;
    if (isMatched) {
      bg = ModernGriotColors.secondary.withOpacity(0.12);
      borderColor = ModernGriotColors.secondary;
      borderWidth = 1.5;
    } else if (isSelected) {
      bg = ModernGriotColors.primaryContainer.withOpacity(0.25);
      borderColor = ModernGriotColors.primary;
      borderWidth = 2.0;
    } else if (isError) {
      bg = ModernGriotColors.error.withOpacity(0.1);
      borderColor = ModernGriotColors.error;
      borderWidth = 2.0;
    } else {
      bg = ModernGriotColors.surfaceContainerLowest;
      borderColor = ModernGriotColors.outlineVariant.withOpacity(0.3);
      borderWidth = 1.0;
    }

    return GestureDetector(
      onTap: isMatched ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: PanAfricanSpacing.sm,
          vertical: PanAfricanSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: ModernGriotRadius.borderLg,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isSelected ? ModernGriotShadows.sm : null,
        ),
        child: Opacity(
          opacity: isMatched ? 0.6 : 1.0,
          child: Row(
            children: [
              if (showSpeaker) ...[
                Icon(Icons.volume_up_rounded,
                    size: 18.sp, color: ModernGriotColors.primary),
                SizedBox(width: 6.w),
              ],
              Expanded(
                child: Text(label,
                    style: ModernGriotTypography.bodyMedium(context: context)),
              ),
              if (isMatched)
                Icon(Icons.check_circle_rounded,
                    size: 18.sp, color: ModernGriotColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchTile {
  final String id;
  final String label;
  final String? audioUrl;
  const _MatchTile({required this.id, required this.label, this.audioUrl});
}

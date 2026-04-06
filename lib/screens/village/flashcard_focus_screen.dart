import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';

class FlashcardFocusScreen extends ConsumerStatefulWidget {
  const FlashcardFocusScreen({super.key});

  @override
  ConsumerState<FlashcardFocusScreen> createState() =>
      _FlashcardFocusScreenState();
}

class _FlashcardFocusScreenState extends ConsumerState<FlashcardFocusScreen>
    with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  int _currentIndex = 0;
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  static const _mockParticipants = [
    _Participant('Amina', true),
    _Participant('Kwame', false),
    _Participant('Zuri', true),
    _Participant('Tunde', false),
    _Participant('Nia', false),
  ];

  static const _mockCards = [
    _FlashcardData(
      word: 'Ọmọ',
      translation: 'Child',
      usage: '"Ọmọ mi, wa jẹun" — My child, come eat.',
      level: 'A2',
      definition: 'A young human being; offspring.',
      culturalNote:
          'In Yoruba culture, children are seen as blessings from the Orishas and are central to family identity.',
    ),
    _FlashcardData(
      word: 'Àgbàlagbà',
      translation: 'Elder',
      usage: '"Àgbàlagbà ni ó mọ ìtàn" — The elder knows history.',
      level: 'B1',
      definition: 'A senior person deserving of respect.',
      culturalNote:
          'Elders hold the highest social authority in Yoruba communities and are greeted with prostration.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.lightImpact();
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _nextCard(bool known) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isFlipped = false;
      _flipController.reset();
      _currentIndex = (_currentIndex + 1) % _mockCards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = _mockCards[_currentIndex];

    return GriotScaffold(
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),
            _buildAvatarStrip(cs),
            SizedBox(height: 12.h),
            Expanded(child: _buildFlashcard(cs, card)),
            SizedBox(height: 12.h),
            _buildFeedbackButtons(),
            SizedBox(height: 12.h),
            _buildGlassToolbar(cs),
            SizedBox(height: 8.h),
            _buildPillControls(cs),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStrip(ColorScheme cs) {
    return SizedBox(
      height: 52.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _mockParticipants.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, i) {
          final p = _mockParticipants[i];
          return GriotAvatar(
            size: 42,
            status: GriotAvatarStatus.online,
            badge: p.hasMic
                ? Container(
                    width: 16.r,
                    height: 16.r,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.mic, size: 10.sp, color: cs.onPrimary),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildFlashcard(ColorScheme cs, _FlashcardData card) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: _toggleFlip,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value;
                final showBack = angle > pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: showBack
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi),
                          child: _cardBack(cs, card),
                        )
                      : _cardFront(cs, card),
                );
              },
            ),
          ),
          Positioned(
            right: -4.w,
            top: 40.h,
            child: Transform.rotate(
              angle: pi / 12,
              child: GriotBadgePill(
                label: 'LEVEL UP!',
                icon: Icons.trending_up_rounded,
                color: ModernGriotColors.secondaryContainer,
                textColor: ModernGriotColors.onSecondaryContainer,
                bounce: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardFront(ColorScheme cs, _FlashcardData card) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: ModernGriotRadius.borderXl,
          boxShadow: ModernGriotShadows.lg,
        ),
        child: Stack(
          children: [
            _warmBlobs(cs),
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(card.word,
                      style: ModernGriotTypography.displaySmall(
                          context: context)),
                  SizedBox(height: 8.h),
                  Container(
                    width: 48.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      gradient: ModernGriotGradients.signatureGradient,
                      borderRadius: ModernGriotRadius.borderFull,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(card.translation,
                      style: ModernGriotTypography.titleLarge(
                          context: context,
                          color: cs.primary)),
                  SizedBox(height: 16.h),
                  Text(card.usage,
                      textAlign: TextAlign.center,
                      style: ModernGriotTypography.bodyMedium(
                          context: context)),
                  SizedBox(height: 16.h),
                  GriotChip(label: card.level, selected: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardBack(ColorScheme cs, _FlashcardData card) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: ModernGriotRadius.borderXl,
          boxShadow: ModernGriotShadows.lg,
        ),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories_rounded,
                  size: 36.sp, color: cs.primary),
              SizedBox(height: 16.h),
              Text('Definition',
                  style: ModernGriotTypography.labelMedium(
                      context: context, color: cs.onSurfaceVariant)),
              SizedBox(height: 8.h),
              Text(card.definition,
                  textAlign: TextAlign.center,
                  style:
                      ModernGriotTypography.bodyLarge(context: context)),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: ModernGriotColors.secondaryContainer.withAlpha(80),
                  borderRadius: ModernGriotRadius.borderLg,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.diversity_3_rounded,
                            size: 16.sp, color: cs.secondary),
                        SizedBox(width: 6.w),
                        Text('Cultural Note',
                            style: ModernGriotTypography.labelMedium(
                                context: context,
                                color: cs.secondary)),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(card.culturalNote,
                        style: ModernGriotTypography.bodySmall(
                            context: context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _warmBlobs(ColorScheme cs) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: ModernGriotRadius.borderXl,
        child: CustomPaint(painter: _BlobPainter(cs.primaryContainer)),
      ),
    );
  }

  Widget _buildFeedbackButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          Expanded(
            child: GriotSecondaryButton(
              label: 'Review Later',
              icon: Icons.replay_rounded,
              onPressed: () => _nextCard(false),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: GriotGradientButton(
              label: 'I Know It',
              icon: Icons.check_rounded,
              onPressed: () => _nextCard(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassToolbar(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 48.w),
      child: GriotGlassPanel(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        borderRadius: ModernGriotRadius.borderPill,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _toolbarIcon(Icons.flip_rounded, 'Flip', _toggleFlip),
            _toolbarIcon(Icons.volume_up_rounded, 'Audio', () {}),
            _toolbarIcon(Icons.lightbulb_outline_rounded, 'Hint', () {}),
          ],
        ),
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, String label, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22.sp, color: cs.primary),
          SizedBox(height: 2.h),
          Text(label,
              style: ModernGriotTypography.labelSmall(context: context)),
        ],
      ),
    );
  }

  Widget _buildPillControls(ColorScheme cs) {
    final items = [
      (Icons.mic_rounded, 'Mic'),
      (Icons.videocam_rounded, 'Video'),
      (Icons.back_hand_rounded, 'Hand'),
      (Icons.more_horiz_rounded, 'More'),
    ];
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: ModernGriotRadius.borderPill,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map((e) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.$1, size: 22.sp, color: cs.onSurfaceVariant),
                    SizedBox(height: 2.h),
                    Text(e.$2,
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: cs.onSurfaceVariant)),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.3), 60, paint);
    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.65), 50, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) => color != old.color;
}

class _Participant {
  const _Participant(this.name, this.hasMic);
  final String name;
  final bool hasMic;
}

class _FlashcardData {
  const _FlashcardData({
    required this.word,
    required this.translation,
    required this.usage,
    required this.level,
    required this.definition,
    required this.culturalNote,
  });
  final String word;
  final String translation;
  final String usage;
  final String level;
  final String definition;
  final String culturalNote;
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../utils/api_service.dart';
import '../../services/capability_gate.dart';
import '../../widgets/griot/griot_widgets.dart';

/// copy_keys: flashcard.colearners.empty (P9-958).
const String kFlashcardCoLearnersEmpty =
    'No one else is studying with you right now. Keep going on your own or invite friends from your circle.';

/// copy_keys: flashcard.group_study.minor_blocked (P9-958).
const String kFlashcardGroupStudyMinorBlocked =
    'Group flashcard study is for verified adult learners. You can still review cards on your own.';

typedef FlashcardRosterLoader = Future<Map<String, dynamic>> Function({
  String? sessionId,
});

Future<Map<String, dynamic>> defaultFlashcardRosterLoader({
  String? sessionId,
}) async {
  await ApiService.initialize();
  final path = sessionId == null || sessionId.isEmpty
      ? '/api/v2/village/flashcards/roster'
      : '/api/v2/village/flashcards/roster?session_id=${Uri.encodeComponent(sessionId)}';
  final response = await ApiService.get(path);
  final json = response.data;
  if (json is Map<String, dynamic>) return json;
  return <String, dynamic>{'ok': false};
}

@visibleForTesting
FlashcardGroupStudyRoster flashcardRosterFromApi(Map<String, dynamic> json) {
  if (json['ok'] != true) {
    return const FlashcardGroupStudyRoster.solo();
  }
  final roster = json['roster'];
  if (roster is! Map<String, dynamic>) {
    return const FlashcardGroupStudyRoster.solo();
  }
  final mode = roster['mode'] as String? ?? 'solo';
  final rawPeers = roster['peers'];
  if (mode == 'practice_bot') {
    return const FlashcardGroupStudyRoster.practiceBot();
  }
  if (mode != 'matched_peers' || rawPeers is! List) {
    return const FlashcardGroupStudyRoster.solo();
  }
  final peers = <FlashcardCoLearner>[];
  for (final item in rawPeers) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    if (map['is_practice_bot'] == true) {
      peers.add(const FlashcardCoLearner.practiceBot());
      continue;
    }
    final name = (map['display_name'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;
    peers.add(FlashcardCoLearner.matched(
      displayName: name,
      hasMic: map['has_mic'] == true,
    ));
  }
  if (peers.isEmpty) {
    return const FlashcardGroupStudyRoster.solo();
  }
  return FlashcardGroupStudyRoster.matched(peers);
}

/// Group-study roster for Village flashcards (P10-911).
enum FlashcardStudyMode { solo, matchedPeers, practiceBot }

class FlashcardCoLearner {
  const FlashcardCoLearner.matched({
    required this.displayName,
    this.hasMic = false,
  }) : isPracticeBot = false;

  const FlashcardCoLearner.practiceBot()
      : displayName = null,
        hasMic = false,
        isPracticeBot = true;

  final String? displayName;
  final bool hasMic;
  final bool isPracticeBot;
}

class FlashcardGroupStudyRoster {
  const FlashcardGroupStudyRoster.solo() : mode = FlashcardStudyMode.solo, peers = const [];

  FlashcardGroupStudyRoster.matched(this.peers)
      : mode = FlashcardStudyMode.matchedPeers;

  const FlashcardGroupStudyRoster.practiceBot()
      : mode = FlashcardStudyMode.practiceBot,
        peers = const [FlashcardCoLearner.practiceBot()];

  final FlashcardStudyMode mode;
  final List<FlashcardCoLearner> peers;
}

class FlashcardFocusScreen extends ConsumerStatefulWidget {
  const FlashcardFocusScreen({
    super.key,
    this.sessionId,
    this.rosterOverride,
    this.rosterLoader = defaultFlashcardRosterLoader,
    this.capabilityGate,
  });

  final String? sessionId;
  /// Test / preview injection — skips network roster fetch.
  final FlashcardGroupStudyRoster? rosterOverride;
  final FlashcardRosterLoader rosterLoader;
  final CapabilityGate? capabilityGate;

  /// When omitted, roster loads from GET `/api/v2/village/flashcards/roster`.
  static const practiceBotLabel = 'Practice bot';

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
  FlashcardGroupStudyRoster _roster = const FlashcardGroupStudyRoster.solo();
  bool _rosterLoading = true;
  bool _groupStudyMinorBlocked = false;

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
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    if (widget.rosterOverride != null) {
      setState(() {
        _roster = widget.rosterOverride!;
        _rosterLoading = false;
      });
      return;
    }
    final gate = widget.capabilityGate ?? CapabilityGate();
    try {
      final caps = await gate.load(forceRefresh: true);
      final blocked = caps.isMinor || caps.tier == null;
      final json = await widget.rosterLoader(sessionId: widget.sessionId);
      if (!mounted) return;
      setState(() {
        _groupStudyMinorBlocked = blocked || json['group_study_allowed'] == false;
        _roster = flashcardRosterFromApi(json);
        if (_groupStudyMinorBlocked) {
          _roster = const FlashcardGroupStudyRoster.solo();
        }
        _rosterLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _roster = const FlashcardGroupStudyRoster.solo();
        _rosterLoading = false;
      });
    }
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
      appBar: AppBar(title: const Text('Flashcards')),
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),
            if (_groupStudyMinorBlocked)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                child: Semantics(
                  label: kFlashcardGroupStudyMinorBlocked,
                  child: Text(
                    kFlashcardGroupStudyMinorBlocked,
                    style: ModernGriotTypography.bodySmall(
                      context: context,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            if (_rosterLoading)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: LinearProgressIndicator(
                  minHeight: 2.h,
                  borderRadius: ModernGriotRadius.borderFull,
                ),
              )
            else
              FlashcardCoLearnerStrip(roster: _roster),
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
              child: const GriotBadgePill(
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

/// Co-learner strip for group study (P10-911); tested in isolation to avoid full-screen layout.
@visibleForTesting
class FlashcardCoLearnerStrip extends StatelessWidget {
  const FlashcardCoLearnerStrip({super.key, required this.roster});

  final FlashcardGroupStudyRoster roster;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (roster.mode == FlashcardStudyMode.solo) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Semantics(
          label: kFlashcardCoLearnersEmpty,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: ModernGriotRadius.borderLg,
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 20.sp, color: cs.onSurfaceVariant),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    kFlashcardCoLearnersEmpty,
                    style: ModernGriotTypography.bodySmall(
                      context: context,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 96.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: roster.peers.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, i) {
          final peer = roster.peers[i];
          final label = peer.isPracticeBot
              ? FlashcardFocusScreen.practiceBotLabel
              : (peer.displayName ?? '');
          return Semantics(
            label: peer.isPracticeBot
                ? FlashcardFocusScreen.practiceBotLabel
                : 'Co-learner $label',
            child: SizedBox(
              width: 56.w,
              height: 88.h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GriotAvatar(
                    size: 32,
                    status: peer.isPracticeBot
                        ? GriotAvatarStatus.busy
                        : GriotAvatarStatus.online,
                    badge: peer.hasMic
                        ? Container(
                            width: 16.r,
                            height: 16.r,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.mic,
                                size: 10.sp, color: cs.onPrimary),
                          )
                        : null,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: ModernGriotTypography.labelSmall(
                      context: context,
                      color: peer.isPracticeBot
                          ? cs.secondary
                          : cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

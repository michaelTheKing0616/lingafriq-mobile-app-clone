import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class LiveClassroomScreen extends ConsumerStatefulWidget {
  const LiveClassroomScreen({super.key});

  @override
  ConsumerState<LiveClassroomScreen> createState() =>
      _LiveClassroomScreenState();
}

class _LiveClassroomScreenState extends ConsumerState<LiveClassroomScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  final List<_FloatingEmoji> _floatingEmojis = [];
  int _activeSpeaker = 0;

  static const _speakers = [
    _Speaker('Adeola K.', 'Host', true),
    _Speaker('Chidi O.', 'Speaker', false),
    _Speaker('Amina N.', 'Speaker', false),
  ];

  static const _listeners = [
    'Fatima B.', 'Sipho M.', 'Selam T.', 'Kofi A.',
    'Ngozi E.', 'Yaw M.', 'Zainab K.', 'Thabo R.',
  ];

  static const _vocabCards = [
    _VocabCard('Bawo ni', 'How are you', 'Yoruba'),
    _VocabCard('Ẹ kú àárọ̀', 'Good morning', 'Yoruba'),
    _VocabCard('Ẹ ṣé', 'Thank you', 'Yoruba'),
    _VocabCard('Ọdún ló', 'Goodbye', 'Yoruba'),
    _VocabCard('Ẹ kú ilé', 'Welcome home', 'Yoruba'),
  ];

  static const _reactions = [
    ('🔥', 'Lit'),
    ('🤝', 'Tribe'),
    ('✊', 'Respect'),
    ('💡', 'Aha'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _addReaction(String emoji) {
    HapticFeedback.lightImpact();
    setState(() {
      _floatingEmojis.add(_FloatingEmoji(
        emoji: emoji,
        id: DateTime.now().microsecondsSinceEpoch,
        x: 0.3 + Random().nextDouble() * 0.4,
      ));
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _floatingEmojis.removeWhere(
            (e) =>
                DateTime.now().microsecondsSinceEpoch - e.id > 1800000,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkScheme = ModernGriotColorScheme.dark;

    return Theme(
      data: ThemeData.dark().copyWith(colorScheme: darkScheme),
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(darkScheme),
                  SizedBox(height: 12.h),
                  _buildSpeakerGrid(darkScheme),
                  SizedBox(height: 16.h),
                  _buildListenerGrid(darkScheme),
                  SizedBox(height: 12.h),
                  _buildReactionBar(darkScheme),
                  SizedBox(height: 12.h),
                  _buildVocabScroll(darkScheme),
                  const Spacer(),
                  _buildBottomBar(darkScheme),
                  SizedBox(height: 8.h),
                ],
              ),
              ..._floatingEmojis.map((e) => _FloatingEmojiWidget(data: e)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.r,
                  height: 6.r,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 5.w),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Yoruba Conversations',
              style: ModernGriotTypography.titleMedium(
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_rounded, size: 14.sp, color: cs.onSurface),
                SizedBox(width: 4.w),
                Text(
                  '${_speakers.length + _listeners.length}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerGrid(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_speakers.length, (i) {
          final speaker = _speakers[i];
          final isHost = i == 0;
          final isActive = i == _activeSpeaker;
          final size = isHost ? 80.0 : 64.0;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: GestureDetector(
              onTap: () => setState(() => _activeSpeaker = i),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      final ringScale =
                          isActive ? 1.0 + _pulseAnim.value * 0.08 : 1.0;
                      return Transform.scale(
                        scale: ringScale,
                        child: Container(
                          width: (size + 8).r,
                          height: (size + 8).r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive
                                  ? ModernGriotColorsDark.primary
                                      .withAlpha((180 + 75 * _pulseAnim.value).round())
                                  : cs.surfaceContainerHigh,
                              width: isActive ? 3.r : 2.r,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Center(
                      child: GriotAvatar(size: size),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    speaker.name,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    speaker.role,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildListenerGrid(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listeners',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 10.h,
            children: _listeners.map((name) {
              return Column(
                children: [
                  GriotAvatar(size: 36),
                  SizedBox(height: 3.h),
                  Text(
                    name.split(' ').first,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionBar(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _reactions.map((r) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: GestureDetector(
              onTap: () => _addReaction(r.$1),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: ModernGriotRadius.borderPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(r.$1, style: TextStyle(fontSize: 16.sp)),
                    SizedBox(width: 4.w),
                    Text(
                      r.$2,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVocabScroll(ColorScheme cs) {
    return SizedBox(
      height: 64.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: _vocabCards.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, i) {
          final card = _vocabCards[i];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: ModernGriotRadius.borderLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.word,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: ModernGriotColorsDark.primary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  card.translation,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme cs) {
    const controls = [
      (Icons.mic_off_rounded, 'Mute'),
      (Icons.back_hand_rounded, 'Raise'),
      (Icons.emoji_emotions_rounded, 'React'),
      (Icons.share_rounded, 'Share'),
      (Icons.chat_bubble_rounded, 'Chat'),
      (Icons.call_end_rounded, 'Leave'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: ClipRRect(
        borderRadius: ModernGriotRadius.borderXl,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: cs.surfaceContainer.withAlpha(200),
              borderRadius: ModernGriotRadius.borderXl,
              border: Border.all(
                color: cs.outlineVariant.withAlpha(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: controls.map((c) {
                final isLeave = c.$2 == 'Leave';
                return GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42.r,
                        height: 42.r,
                        decoration: BoxDecoration(
                          color: isLeave
                              ? const Color(0xFFE53935)
                              : cs.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          c.$1,
                          size: 20.sp,
                          color: isLeave ? Colors.white : cs.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        c.$2,
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500,
                          color: isLeave
                              ? const Color(0xFFE53935)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingEmojiWidget extends StatefulWidget {
  const _FloatingEmojiWidget({required this.data});
  final _FloatingEmoji data;

  @override
  State<_FloatingEmojiWidget> createState() => _FloatingEmojiWidgetState();
}

class _FloatingEmojiWidgetState extends State<_FloatingEmojiWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0)),
    );
    _translateY = Tween<double>(begin: 0, end: -160).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          left: widget.data.x * screenWidth,
          bottom: 140.h + (-_translateY.value),
          child: Opacity(
            opacity: _opacity.value,
            child: Text(
              widget.data.emoji,
              style: TextStyle(fontSize: 28.sp),
            ),
          ),
        );
      },
    );
  }
}

class _Speaker {
  final String name;
  final String role;
  final bool isHost;
  const _Speaker(this.name, this.role, this.isHost);
}

class _VocabCard {
  final String word;
  final String translation;
  final String language;
  const _VocabCard(this.word, this.translation, this.language);
}

class _FloatingEmoji {
  final String emoji;
  final int id;
  final double x;
  const _FloatingEmoji({required this.emoji, required this.id, required this.x});
}

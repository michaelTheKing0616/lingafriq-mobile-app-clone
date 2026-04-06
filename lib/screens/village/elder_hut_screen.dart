import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class ElderHutScreen extends ConsumerStatefulWidget {
  const ElderHutScreen({super.key});

  @override
  ConsumerState<ElderHutScreen> createState() => _ElderHutScreenState();
}

class _ElderHutScreenState extends ConsumerState<ElderHutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  int _selectedProverb = 0;

  static const _darkBg = Color(0xFF1C1A15);
  static const _darkSurface = Color(0xFF252219);
  static const _darkSurfaceHigh = Color(0xFF2E2A22);
  static const _gold = Color(0xFFFFD700);
  static const _goldMuted = Color(0xFFB8960C);
  static const _warmText = Color(0xFFEDE0D0);
  static const _warmTextDim = Color(0xFFCFC5B4);

  static const _proverbs = [
    _Proverb(
      'Mti mmoja hauundi msitu.',
      'One tree does not make a forest.',
      'Swahili · On community',
    ),
    _Proverb(
      'Haraka haraka haina baraka.',
      'Hurry hurry has no blessing.',
      'Swahili · On patience',
    ),
    _Proverb(
      'Asiyefunzwa na mamaye hufunzwa na ulimwengu.',
      'Whoever is not taught by their mother is taught by the world.',
      'Swahili · On upbringing',
    ),
    _Proverb(
      'Kidole kimoja hakivunji chawa.',
      'One finger does not crush a louse.',
      'Swahili · On teamwork',
    ),
    _Proverb(
      'Penye nia pana njia.',
      'Where there is a will, there is a way.',
      'Swahili · On determination',
    ),
  ];

  static const _dialogueHistory = [
    _DialogueTurn(
      speaker: 'You',
      text: 'Elder, what does it mean to truly learn a language?',
      isElder: false,
    ),
    _DialogueTurn(
      speaker: 'Elder Otieno',
      text: 'A language is not words alone, child. It is the rhythm of a '
          'people, the shape of their dreams. To learn a language is to adopt '
          'a new soul alongside your own.',
      isElder: true,
    ),
    _DialogueTurn(
      speaker: 'You',
      text: 'How do I keep going when it feels too difficult?',
      isElder: false,
    ),
    _DialogueTurn(
      speaker: 'Elder Otieno',
      text: 'Remember: "Haraka haraka haina baraka." Patience is the '
          'companion of wisdom. The baobab did not grow in a day, yet now '
          'it shelters the whole village.',
      isElder: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 24.h),
                    _buildTotemWithGlow(context),
                    SizedBox(height: 20.h),
                    _buildSageBadge(context),
                    SizedBox(height: 28.h),
                    _buildProverbCarousel(context),
                    SizedBox(height: 28.h),
                    _buildDialogue(context),
                    SizedBox(height: 28.h),
                    _buildInteractionButtons(context),
                    SizedBox(height: 24.h),
                    _buildWisdomStats(context),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: _darkSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_rounded,
                  size: 20.sp, color: _warmText),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Elder\'s Hut',
                    style: ModernGriotTypography.titleLarge(color: _warmText)),
                Text('A place of wisdom and reflection',
                    style: ModernGriotTypography.bodySmall(
                        color: _warmTextDim)),
              ],
            ),
          ),
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: _gold.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_stories_rounded,
                size: 18.sp, color: _gold),
          ),
        ],
      ),
    );
  }

  Widget _buildTotemWithGlow(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          width: 160.r,
          height: 160.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _gold.withAlpha((40 * _glowAnim.value).round()),
                blurRadius: 60 * _glowAnim.value,
                spreadRadius: 8 * _glowAnim.value,
              ),
              BoxShadow(
                color: _goldMuted.withAlpha((20 * _glowAnim.value).round()),
                blurRadius: 100 * _glowAnim.value,
                spreadRadius: 16 * _glowAnim.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        width: 160.r,
        height: 160.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _darkSurfaceHigh,
              _darkSurface,
              _darkBg,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          border: Border.all(
            color: _gold.withAlpha(60),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏺', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 4.h),
            Text('TOTEM',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: _gold,
                  letterSpacing: 2.0,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSageBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _gold.withAlpha(30),
            _goldMuted.withAlpha(15),
          ],
        ),
        borderRadius: ModernGriotRadius.borderPill,
        border: Border.all(color: _gold.withAlpha(50), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: 16.sp, color: _gold),
          SizedBox(width: 6.w),
          Text('SAGE',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                color: _gold,
                letterSpacing: 1.5,
              )),
          SizedBox(width: 6.w),
          Container(
            width: 4.r,
            height: 4.r,
            decoration: const BoxDecoration(
              color: _gold,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text('Elder Otieno',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: _warmTextDim,
              )),
        ],
      ),
    );
  }

  Widget _buildProverbCarousel(BuildContext context) {
    final proverb = _proverbs[_selectedProverb];
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: _darkSurface,
            borderRadius: ModernGriotRadius.borderXl,
            border: Border.all(color: _gold.withAlpha(25)),
          ),
          child: Column(
            children: [
              Icon(Icons.format_quote_rounded,
                  size: 28.sp, color: _gold.withAlpha(120)),
              SizedBox(height: 12.h),
              Text(
                proverb.african,
                style: ModernGriotTypography.titleMedium(color: _warmText),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                proverb.english,
                style: ModernGriotTypography.bodyMedium(
                    color: _warmTextDim),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _gold.withAlpha(12),
                  borderRadius: ModernGriotRadius.borderPill,
                ),
                child: Text(proverb.attribution,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: _goldMuted,
                    )),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_proverbs.length, (i) {
            final isActive = i == _selectedProverb;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedProverb = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 24.w : 8.w,
                height: 8.h,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  color: isActive ? _gold : _darkSurfaceHigh,
                  borderRadius: ModernGriotRadius.borderPill,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDialogue(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(
                color: _gold.withAlpha(120),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8.w),
            Text('Counsel of the Elder',
                style: ModernGriotTypography.titleSmall(color: _warmText)),
          ],
        ),
        SizedBox(height: 12.h),
        ..._dialogueHistory.map((turn) => _buildDialogueTurn(context, turn)),
      ],
    );
  }

  Widget _buildDialogueTurn(BuildContext context, _DialogueTurn turn) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: turn.isElder ? _gold.withAlpha(25) : _darkSurfaceHigh,
              shape: BoxShape.circle,
              border: turn.isElder
                  ? Border.all(color: _gold.withAlpha(40), width: 1.5)
                  : null,
            ),
            child: Center(
              child: turn.isElder
                  ? Icon(Icons.auto_stories_rounded,
                      size: 14.sp, color: _gold)
                  : Text('ME',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: _warmTextDim,
                      )),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(turn.speaker,
                    style: ModernGriotTypography.labelSmall(
                        color: turn.isElder ? _gold : _warmTextDim)),
                SizedBox(height: 4.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: turn.isElder
                        ? _gold.withAlpha(10)
                        : _darkSurfaceHigh,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(ModernGriotRadius.xl),
                      bottomLeft: Radius.circular(ModernGriotRadius.xl),
                      bottomRight: Radius.circular(ModernGriotRadius.xl),
                    ),
                    border: turn.isElder
                        ? Border.all(color: _gold.withAlpha(20))
                        : null,
                  ),
                  child: Text(turn.text,
                      style: ModernGriotTypography.bodySmall(
                          color: _warmText)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButtons(BuildContext context) {
    final buttons = [
      _ActionBtn('Ask', Icons.question_answer_rounded, 'Seek wisdom'),
      _ActionBtn('Explain', Icons.lightbulb_outline_rounded, 'Deepen meaning'),
      _ActionBtn('Practice', Icons.record_voice_over_rounded, 'Speak aloud'),
    ];

    return Row(
      children: buttons.map((btn) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: GestureDetector(
              onTap: () => HapticFeedback.mediumImpact(),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: _darkSurface,
                  borderRadius: ModernGriotRadius.borderXl,
                  border: Border.all(color: _gold.withAlpha(30)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: _gold.withAlpha(15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(btn.icon,
                          size: 22.sp, color: _gold),
                    ),
                    SizedBox(height: 8.h),
                    Text(btn.label,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _warmText,
                        )),
                    SizedBox(height: 2.h),
                    Text(btn.hint,
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: _warmTextDim,
                        )),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWisdomStats(BuildContext context) {
    final stats = [
      ('42', 'Proverbs\nLearned'),
      ('7', 'Day\nStreak'),
      ('3', 'Elders\nConsulted'),
    ];

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _darkSurface,
        borderRadius: ModernGriotRadius.borderXl,
        border: Border.all(color: _gold.withAlpha(18)),
      ),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Column(
              children: [
                Text(s.$1,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: _gold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
                SizedBox(height: 4.h),
                Text(s.$2,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: _warmTextDim,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Proverb {
  const _Proverb(this.african, this.english, this.attribution);
  final String african;
  final String english;
  final String attribution;
}

class _DialogueTurn {
  const _DialogueTurn({
    required this.speaker,
    required this.text,
    required this.isElder,
  });
  final String speaker;
  final String text;
  final bool isElder;
}

class _ActionBtn {
  const _ActionBtn(this.label, this.icon, this.hint);
  final String label;
  final IconData icon;
  final String hint;
}

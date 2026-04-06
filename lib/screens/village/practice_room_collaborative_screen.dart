import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import '../../widgets/game/game_widgets.dart';

class PracticeRoomCollaborativeScreen extends ConsumerStatefulWidget {
  const PracticeRoomCollaborativeScreen({super.key});

  @override
  ConsumerState<PracticeRoomCollaborativeScreen> createState() =>
      _PracticeRoomCollaborativeScreenState();
}

class _PracticeRoomCollaborativeScreenState
    extends ConsumerState<PracticeRoomCollaborativeScreen> {
  int _secondsElapsed = 0;
  bool _flashcardRevealed = false;
  int _activeToolTab = 0;
  final _scratchpadController = TextEditingController();

  static const _participants = [
    _CollabParticipant('Amina K.', [0.6, 0.8, 0.3, 0.9, 0.4, 0.7]),
    _CollabParticipant('Kwame O.', [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
    _CollabParticipant('Zuri M.', [0.3, 0.1, 0.5, 0.2, 0.4, 0.1]),
    _CollabParticipant('You', [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
  ];

  static const _flashcard = _MiniFlashcard(
    front: 'Ẹ kú àárọ̀',
    back: 'Good morning',
    hint: 'Greeting used before noon',
  );

  static const _messages = [
    _ScratchMessage('Amina K.', 'Can we practice the market dialogue?'),
    _ScratchMessage('Kwame O.', 'Yes! I still struggle with the tones on "ọjà"'),
    _ScratchMessage('Zuri M.', 'Try: Ọ̀jà → rising then falling'),
    _ScratchMessage('Amina K.', 'Let\'s do a role-play round 🎭'),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _secondsElapsed++);
      return true;
    });
  }

  String get _timerText {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _scratchpadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 8.h),
            _buildTopBar(cs),
            SizedBox(height: 10.h),
            SizedBox(height: 220.h, child: _buildVideoGrid(cs)),
            SizedBox(height: 10.h),
            Expanded(child: _buildToolsPanel(cs)),
            _buildFooter(cs),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back_rounded,
                size: 24.sp, color: cs.onSurface),
          ),
          SizedBox(width: 12.w),
          Text('Collaborative Room',
              style: ModernGriotTypography.titleMedium(context: context)),
          const Spacer(),
          GriotBadgePill(label: _timerText, icon: Icons.timer_outlined),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _videoTile(0, cs)),
                SizedBox(width: 8.w),
                Expanded(child: _videoTile(1, cs)),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _videoTile(2, cs)),
                SizedBox(width: 8.w),
                Expanded(child: _videoTile(3, cs)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoTile(int index, ColorScheme cs) {
    final p = _participants[index];
    final hasVoice = p.waveform.any((a) => a > 0.1);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: ModernGriotRadius.borderXl,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.person_rounded,
                size: 36.sp, color: cs.onSurfaceVariant.withAlpha(60)),
          ),
          Positioned(
            left: 8.w,
            bottom: 8.h,
            right: 8.w,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: cs.inverseSurface.withAlpha(180),
                      borderRadius: ModernGriotRadius.borderPill,
                    ),
                    child: Text(p.name,
                        style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: cs.onInverseSurface),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (hasVoice) ...[
                  SizedBox(width: 4.w),
                  GriotWaveformVisualizer(
                    amplitudes: p.waveform,
                    height: 20,
                    barWidth: 2,
                    gap: 1,
                    animate: true,
                    activeColor: ModernGriotColors.primaryContainer,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsPanel(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          _buildToolTabs(cs),
          SizedBox(height: 10.h),
          Expanded(
            child: _activeToolTab == 0
                ? _buildFlashcardTool(cs)
                : _buildScratchpad(cs),
          ),
        ],
      ),
    );
  }

  Widget _buildToolTabs(ColorScheme cs) {
    final tabs = ['Flashcard Deck', 'Scratchpad'];
    return Row(
      children: List.generate(tabs.length, (i) {
        final active = _activeToolTab == i;
        return Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _activeToolTab = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: active ? cs.primary : cs.surfaceContainerLow,
                borderRadius: ModernGriotRadius.borderPill,
              ),
              child: Text(tabs[i],
                  style: ModernGriotTypography.labelMedium(
                      context: context,
                      color: active ? cs.onPrimary : cs.onSurfaceVariant)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFlashcardTool(ColorScheme cs) {
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(20.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_rounded, size: 28.sp, color: cs.primary),
          SizedBox(height: 12.h),
          Text(
            _flashcardRevealed ? _flashcard.back : _flashcard.front,
            style: ModernGriotTypography.headlineSmall(context: context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          if (_flashcardRevealed)
            Text(_flashcard.hint,
                style: ModernGriotTypography.bodySmall(
                    context: context, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _flashcardRevealed = !_flashcardRevealed);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(20),
                borderRadius: ModernGriotRadius.borderPill,
                border: Border.all(color: cs.primary.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _flashcardRevealed
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18.sp,
                    color: cs.primary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    _flashcardRevealed ? 'Hide' : 'Reveal',
                    style: ModernGriotTypography.labelLarge(
                        context: context, color: cs.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchpad(ColorScheme cs) {
    return Column(
      children: [
        Expanded(
          child: GriotCard(
            surfaceLevel: 1,
            padding: EdgeInsets.all(12.r),
            child: ListView.separated(
              itemCount: _messages.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (_, i) {
                final msg = _messages[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GriotAvatar(size: 28),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg.author,
                              style: ModernGriotTypography.labelSmall(
                                  context: context, color: cs.primary)),
                          SizedBox(height: 2.h),
                          Text(msg.text,
                              style: ModernGriotTypography.bodySmall(
                                  context: context)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44.h,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: ModernGriotRadius.borderPill,
                  border: Border.all(
                      color: cs.outlineVariant.withAlpha(38)),
                ),
                child: TextField(
                  controller: _scratchpadController,
                  style: ModernGriotTypography.bodySmall(context: context),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type a note...',
                    hintStyle: ModernGriotTypography.bodySmall(
                        context: context, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => HapticFeedback.lightImpact(),
              child: Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  gradient: ModernGriotGradients.signatureGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send_rounded,
                    size: 20.sp, color: ModernGriotColors.onPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: ModernGriotColors.error,
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_end_rounded,
                      size: 20.sp, color: ModernGriotColors.onError),
                  SizedBox(width: 8.w),
                  Text('End Session',
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: ModernGriotColors.onError)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollabParticipant {
  const _CollabParticipant(this.name, this.waveform);
  final String name;
  final List<double> waveform;
}

class _MiniFlashcard {
  const _MiniFlashcard({
    required this.front,
    required this.back,
    required this.hint,
  });
  final String front;
  final String back;
  final String hint;
}

class _ScratchMessage {
  const _ScratchMessage(this.author, this.text);
  final String author;
  final String text;
}

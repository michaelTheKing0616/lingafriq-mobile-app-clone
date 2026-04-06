import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class VillageCafeScreen extends ConsumerStatefulWidget {
  const VillageCafeScreen({super.key});

  @override
  ConsumerState<VillageCafeScreen> createState() => _VillageCafeScreenState();
}

class _VillageCafeScreenState extends ConsumerState<VillageCafeScreen> {
  final _scrollController = ScrollController();
  final _chatController = TextEditingController();

  static const _chatMessages = [
    _ChatMsg('Amina K.', 'AM', 'Habari za asubuhi! Leo tunajifunza nini?',
        'Good morning! What are we learning today?', false),
    _ChatMsg('Juma M.', 'JM', 'Tunaendelea na vitenzi vya wakati uliopita.',
        'We continue with past tense verbs.', false),
    _ChatMsg('Lila S.', 'LS', 'Nimefurahi sana kusikia hilo!',
        'I am very happy to hear that!', false),
    _ChatMsg('Elder Mwangi', 'EM', 'Karibu watoto. Lugha ni daraja la tamaduni.',
        'Welcome children. Language is a bridge of cultures.', true),
  ];

  static const _waveAmplitudes = [
    0.3, 0.6, 0.9, 0.5, 0.8, 0.4, 0.7, 0.95, 0.6, 0.3,
    0.5, 0.8, 0.4, 0.6, 0.2, 0.7, 0.5, 0.3, 0.6, 0.4,
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GriotScaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),
                    _buildDailySpecial(context),
                    SizedBox(height: 20.h),
                    _buildWhoBrewing(context),
                    SizedBox(height: 20.h),
                    _buildElderWelcome(context),
                    SizedBox(height: 16.h),
                    ..._chatMessages.map((m) => _buildChatBubble(context, m)),
                    SizedBox(height: 12.h),
                    _buildVoiceMessage(context),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
            _buildChatInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerLow,
        boxShadow: ModernGriotShadows.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Icon(Icons.arrow_back_rounded, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: ModernGriotColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.coffee_rounded,
                size: 18.sp, color: ModernGriotColors.primary),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Village Café',
                    style: ModernGriotTypography.titleSmall()),
                Text('Swahili · 18 online',
                    style: ModernGriotTypography.labelSmall(
                        color: ModernGriotColors.secondary)),
              ],
            ),
          ),
          Icon(Icons.more_vert_rounded,
              size: 22.sp, color: ModernGriotColors.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildDailySpecial(BuildContext context) {
    return GriotCard(
      surfaceLevel: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_cafe_rounded,
                  size: 18.sp, color: ModernGriotColors.primaryContainer),
              SizedBox(width: 8.w),
              Text('Daily Special',
                  style: ModernGriotTypography.titleSmall(
                      color: ModernGriotColors.primaryContainer)),
              const Spacer(),
              GriotBadgePill(
                label: 'NEW',
                color: ModernGriotColors.secondaryContainer,
                textColor: ModernGriotColors.onSecondaryContainer,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text('Kupenda',
              style: ModernGriotTypography.headlineSmall()),
          Text('(verb) — to love',
              style: ModernGriotTypography.bodySmall()),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: ModernGriotColors.surfaceContainerHighest,
              borderRadius: ModernGriotRadius.borderLg,
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: [
                _conjugationRow('Mimi', 'Ninapenda', isHeader: true),
                _conjugationRow('Wewe', 'Unapenda'),
                _conjugationRow('Yeye', 'Anapenda'),
                _conjugationRow('Sisi', 'Tunapenda'),
                _conjugationRow('Wao', 'Wanapenda'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _conjugationRow(String pronoun, String verb,
      {bool isHeader = false}) {
    return TableRow(
      decoration: isHeader
          ? BoxDecoration(
              color: ModernGriotColors.primary.withAlpha(12),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            )
          : null,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Text(pronoun,
              style: ModernGriotTypography.labelMedium(
                  color: ModernGriotColors.onSurfaceVariant)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Text(verb,
              style: ModernGriotTypography.bodyMedium(
                  color: ModernGriotColors.primary)),
        ),
      ],
    );
  }

  Widget _buildWhoBrewing(BuildContext context) {
    final avatars = [
      ('AM', const Color(0xFF9E3D00)),
      ('JM', const Color(0xFF526124)),
      ('LS', const Color(0xFF7B5733)),
      ('NK', const Color(0xFFFF7A35)),
      ('BW', const Color(0xFF3A1500)),
    ];

    return Row(
      children: [
        SizedBox(
          width: (24.r * avatars.length) + 12.w,
          height: 36.r,
          child: Stack(
            children: List.generate(avatars.length, (i) {
              return Positioned(
                left: i * 20.0.w,
                child: Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: avatars[i].$2,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: ModernGriotColors.surface, width: 2.5),
                  ),
                  child: Center(
                    child: Text(
                      avatars[i].$1,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            "Who's Brewing — 5 learners chatting",
            style: ModernGriotTypography.labelSmall(
                color: ModernGriotColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildElderWelcome(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerLow,
        borderRadius: ModernGriotRadius.borderXl,
        border: Border(
          left: BorderSide(
            color: ModernGriotColors.secondary,
            width: 4.w,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: const BoxDecoration(
              color: ModernGriotColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_stories_rounded,
                size: 16.sp, color: ModernGriotColors.secondary),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Elder Mwangi',
                    style: ModernGriotTypography.labelMedium(
                        color: ModernGriotColors.secondary)),
                SizedBox(height: 4.h),
                Text(
                  '"Mti mmoja hauundi msitu" — One tree does not make a forest. '
                  'Welcome to the café. Learn together, grow together.',
                  style: ModernGriotTypography.bodySmall(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, _ChatMsg msg) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: msg.isElder
                  ? ModernGriotColors.secondary
                  : ModernGriotColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                msg.initials,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.name,
                    style: ModernGriotTypography.labelSmall(
                        color: ModernGriotColors.onSurface)),
                SizedBox(height: 4.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: msg.isElder
                        ? ModernGriotColors.secondaryContainer.withAlpha(60)
                        : ModernGriotColors.surfaceContainerLow,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(ModernGriotRadius.xl),
                      bottomLeft: Radius.circular(ModernGriotRadius.xl),
                      bottomRight: Radius.circular(ModernGriotRadius.xl),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.swahili,
                          style: ModernGriotTypography.bodyMedium(
                              color: ModernGriotColors.onSurface)),
                      SizedBox(height: 4.h),
                      Text(msg.english,
                          style: ModernGriotTypography.bodySmall(
                              color: ModernGriotColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMessage(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: const BoxDecoration(
              color: ModernGriotColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('JM',
                  style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Juma M.',
                    style: ModernGriotTypography.labelSmall(
                        color: ModernGriotColors.onSurface)),
                SizedBox(height: 4.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: ModernGriotColors.surfaceContainerLow,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(ModernGriotRadius.xl),
                      bottomLeft: Radius.circular(ModernGriotRadius.xl),
                      bottomRight: Radius.circular(ModernGriotRadius.xl),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_filled_rounded,
                          size: 28.sp,
                          color: ModernGriotColors.primaryContainer),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: GriotWaveformVisualizer(
                          amplitudes: _waveAmplitudes,
                          height: 32,
                          barWidth: 3,
                          gap: 2,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text('0:12',
                          style: ModernGriotTypography.labelSmall(
                              color: ModernGriotColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerLow,
        boxShadow: [
          BoxShadow(
            color: ModernGriotColors.onSurface.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: const BoxDecoration(
                color: ModernGriotColors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded,
                  size: 20.sp, color: ModernGriotColors.onSurfaceVariant),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              height: 40.h,
              decoration: BoxDecoration(
                color: ModernGriotColors.surfaceContainerHighest,
                borderRadius: ModernGriotRadius.borderPill,
              ),
              child: TextField(
                controller: _chatController,
                style: ModernGriotTypography.bodySmall(),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Andika ujumbe... (Type a message)',
                  hintStyle: ModernGriotTypography.bodySmall(
                      color: ModernGriotColors.onSurfaceVariant.withAlpha(120)),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => HapticFeedback.mediumImpact(),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: const BoxDecoration(
                gradient: ModernGriotGradients.signatureGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_rounded,
                  size: 18.sp, color: ModernGriotColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  const _ChatMsg(
      this.name, this.initials, this.swahili, this.english, this.isElder);
  final String name;
  final String initials;
  final String swahili;
  final String english;
  final bool isElder;
}

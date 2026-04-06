import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class ClassroomNotesScreen extends ConsumerWidget {
  const ClassroomNotesScreen({super.key});

  static const _vocabItems = [
    _VocabItem('Bawo ni', 'How are you', false),
    _VocabItem('Ẹ kú àárọ̀', 'Good morning', true),
    _VocabItem('Ẹ ṣé', 'Thank you', false),
    _VocabItem('Mo fẹ́ kọ́', 'I want to learn', false),
    _VocabItem('Ọdún ló', 'Goodbye', true),
  ];

  static const _grammarNotes = [
    _GrammarNote(
      'Tonal Pattern',
      'Yoruba uses three tones: high (´), mid (unmarked), low (`). '
          'Changing tone changes meaning entirely.',
    ),
    _GrammarNote(
      'Subject-Verb-Object',
      'Basic Yoruba word order: Mo (I) + jẹ (eat) + ẹ̀wà (beans) → "I eat beans"',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter(color: cs.outline)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(cs),
                  SizedBox(height: 16.h),
                  _buildInstructorCard(cs),
                  SizedBox(height: 20.h),
                  _buildWhiteboardSection(cs),
                  SizedBox(height: 20.h),
                  _buildVocabSidebar(cs),
                  SizedBox(height: 20.h),
                  _buildCulturalContext(cs),
                  SizedBox(height: 16.h),
                  _buildHistoryLink(cs),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Row(
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
                'LIVE NOTES',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Icon(Icons.bookmark_border_rounded, color: cs.onSurfaceVariant, size: 22.sp),
        SizedBox(width: 12.w),
        Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant, size: 22.sp),
      ],
    );
  }

  Widget _buildInstructorCard(ColorScheme cs) {
    return GriotCard(
      surfaceLevel: 0,
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          GriotAvatar(size: 44, status: GriotAvatarStatus.online),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adeola K.',
                  style: ModernGriotTypography.titleSmall(),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Yoruba Conversations · Session 4',
                  style: ModernGriotTypography.bodySmall(),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: ModernGriotColors.primary.withAlpha(25),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Text(
              '32 min',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: ModernGriotColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteboardSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Whiteboard',
          style: ModernGriotTypography.titleSmall(),
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: ModernGriotRadius.borderXl,
            boxShadow: ModernGriotShadows.md,
          ),
          child: Column(
            children: [
              Transform.rotate(
                angle: -0.03,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: ModernGriotColors.primaryContainer.withAlpha(30),
                    borderRadius: ModernGriotRadius.borderLg,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '"Ẹni tó bá fẹ́ jẹ oyin, kò gbọdọ̀ sá fún oyin."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: ModernGriotColors.primary,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '"One who wants to eat honey must not run from bees."',
                        textAlign: TextAlign.center,
                        style: ModernGriotTypography.bodySmall(
                          color: ModernGriotColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              ..._grammarNotes.map((note) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: ModernGriotRadius.borderLg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 14.sp,
                                color: ModernGriotColors.secondary,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                note.title,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: ModernGriotColors.secondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            note.body,
                            style: ModernGriotTypography.bodySmall(),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVocabSidebar(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Vocabulary', style: ModernGriotTypography.titleSmall()),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: ModernGriotRadius.borderPill,
              ),
              child: Text(
                '${_vocabItems.length} words',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ..._vocabItems.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: GriotCard(
                surfaceLevel: 1,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.word,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            item.meaning,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.saved)
                      Icon(Icons.check_circle_rounded,
                          size: 20.sp, color: ModernGriotColors.secondary)
                    else
                      GestureDetector(
                        onTap: () => HapticFeedback.lightImpact(),
                        child: Container(
                          width: 32.r,
                          height: 32.r,
                          decoration: BoxDecoration(
                            color: ModernGriotColors.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 18.sp,
                            color: ModernGriotColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildCulturalContext(ColorScheme cs) {
    return GriotCard(
      surfaceLevel: 2,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: ModernGriotColors.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.public_rounded,
                  size: 16.sp,
                  color: ModernGriotColors.tertiary,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Cultural Context',
                style: ModernGriotTypography.titleSmall(),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'In Yoruba culture, greetings are deeply valued and often reflect '
            'time of day, the person\'s activity, and social hierarchy. Younger '
            'people prostrate (dọ̀bálẹ̀) or kneel (kúnlẹ̀) when greeting elders, '
            'showing respect through physical posture alongside verbal expression.',
            style: ModernGriotTypography.bodySmall(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryLink(ColorScheme cs) {
    return Center(
      child: GestureDetector(
        onTap: () => HapticFeedback.lightImpact(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(180),
            borderRadius: ModernGriotRadius.borderPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded,
                  size: 16.sp, color: ModernGriotColors.primary),
              SizedBox(width: 6.w),
              Text(
                'Open Full Note History',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: ModernGriotColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(15)
      ..style = PaintingStyle.fill;

    const spacing = 24.0;
    const radius = 1.2;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _VocabItem {
  final String word;
  final String meaning;
  final bool saved;
  const _VocabItem(this.word, this.meaning, this.saved);
}

class _GrammarNote {
  final String title;
  final String body;
  const _GrammarNote(this.title, this.body);
}

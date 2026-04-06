import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/navigation/village_navigation.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class VillagesHubScreen extends ConsumerWidget {
  const VillagesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GriotScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        shape: BoxShape.circle,
                        boxShadow: ModernGriotShadows.sm,
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: 20.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildHero(context),
              SizedBox(height: 24.h),
              _buildAsymmetricGrid(context),
              SizedBox(height: 32.h),
              _buildDiscoverSection(context),
              SizedBox(height: 28.h),
              _buildContinentalMapTeaser(context),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8.r,
              height: 8.r,
              decoration: const BoxDecoration(
                color: ModernGriotColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '3 Active',
              style: ModernGriotTypography.labelSmall(
                color: ModernGriotColors.secondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text('My Villages', style: ModernGriotTypography.headlineLarge()),
        SizedBox(height: 4.h),
        Text(
          'Your language communities — practice, connect, grow.',
          style: ModernGriotTypography.bodyMedium(),
        ),
      ],
    );
  }

  Widget _buildAsymmetricGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: _VillageCard(
                language: 'Swahili',
                nativeName: 'Kiswahili',
                progress: 0.72,
                activeLearners: 1245,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9E3D00), Color(0xFFFF7A35)],
                ),
                height: 200.h,
                onOpen: () =>
                    VillageNavigation.pushSwahiliCorridorMap(context),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 3,
              child: _VillageCard(
                language: 'Yoruba',
                nativeName: 'Èdè Yorùbá',
                progress: 0.38,
                activeLearners: 834,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF526124), Color(0xFF7A8C3A)],
                ),
                height: 200.h,
                onOpen: () => VillageNavigation.pushLanguageVillage(
                  context,
                  languageDisplayName: 'Yoruba',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _VillageCard(
          language: 'Wolof',
          nativeName: 'Wollof',
          progress: 0.15,
          activeLearners: 421,
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF7B5733), Color(0xFFB8845A)],
          ),
          height: 120.h,
          isWide: true,
          onOpen: () => VillageNavigation.pushLanguageVillage(
            context,
            languageDisplayName: 'Wolof',
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverSection(BuildContext context) {
    const tags = [
      'Amharic', 'Zulu', 'Igbo', 'Hausa', 'Twi', 'Lingala', 'Shona', 'Somali',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discover More Villages',
            style: ModernGriotTypography.titleMedium()),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: tags
              .map((tag) => GriotChip(
                    label: tag,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      VillageNavigation.pushLanguageVillage(
                        context,
                        languageDisplayName: tag,
                      );
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildContinentalMapTeaser(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        VillageNavigation.pushSwahiliCorridorMap(context);
      },
      child: Container(
        height: 160.h,
        decoration: BoxDecoration(
          borderRadius: ModernGriotRadius.borderXl,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9E3D00), Color(0xFFFF7A35), Color(0xFFFDE8D0)],
          ),
          boxShadow: ModernGriotShadows.lg,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20.w,
              bottom: -20.h,
              child: Icon(Icons.public_rounded,
                  size: 140.sp, color: Colors.white.withAlpha(30)),
            ),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: ModernGriotRadius.borderPill,
                    ),
                    child: Text(
                      'TAP TO OPEN',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text('Swahili corridor map',
                      style: ModernGriotTypography.titleLarge(
                          color: Colors.white)),
                  SizedBox(height: 4.h),
                  Text('Walk the village — Griot Stage, Market, School & more',
                      style: ModernGriotTypography.bodySmall(
                          color: Colors.white.withAlpha(200))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VillageCard extends StatelessWidget {
  const _VillageCard({
    required this.language,
    required this.nativeName,
    required this.progress,
    required this.activeLearners,
    required this.gradient,
    required this.height,
    this.isWide = false,
    required this.onOpen,
  });

  final String language;
  final String nativeName;
  final double progress;
  final int activeLearners;
  final LinearGradient gradient;
  final double height;
  final bool isWide;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onOpen();
      },
      child: Container(
        height: height,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: ModernGriotRadius.borderXl,
          boxShadow: ModernGriotShadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language,
                    style: ModernGriotTypography.titleMedium(
                        color: Colors.white)),
                SizedBox(height: 2.h),
                Text(nativeName,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withAlpha(180),
                    )),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4.h,
                          backgroundColor: Colors.white.withAlpha(50),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text('${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text('$activeLearners active',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withAlpha(200),
                        )),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

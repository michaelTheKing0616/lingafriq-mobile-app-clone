import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/navigation/village_navigation.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class LanguageVillagesScreen extends HookConsumerWidget {
  const LanguageVillagesScreen({super.key});

  static const _locations = [
    _VillageLocation('Griot Stage', Icons.mic_rounded,
        'Share stories & perform', Offset(0.5, 0.12)),
    _VillageLocation('The Market', Icons.storefront_rounded,
        'Bargain & trade phrases', Offset(0.18, 0.32)),
    _VillageLocation('Sun Café', Icons.coffee_rounded,
        'Casual conversation hub', Offset(0.72, 0.28)),
    _VillageLocation("Elder's Hut", Icons.auto_stories_rounded,
        'Wisdom & proverbs', Offset(0.35, 0.52)),
    _VillageLocation('The School', Icons.school_rounded,
        'Structured lessons', Offset(0.68, 0.48)),
  ];

  static const _avatars = [
    _WanderingAvatar('AK', Offset(0.3, 0.2), Color(0xFF9E3D00)),
    _WanderingAvatar('OT', Offset(0.6, 0.38), Color(0xFF526124)),
    _WanderingAvatar('BI', Offset(0.45, 0.6), Color(0xFF7B5733)),
    _WanderingAvatar('ZN', Offset(0.8, 0.15), Color(0xFFFF7A35)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIdx = useState(-1);
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    var languageDisplayName = 'Yoruba';
    var languageCode = 'yo';
    if (routeArgs is Map) {
      final d = routeArgs['languageDisplayName'];
      final c = routeArgs['languageCode'];
      if (d is String && d.trim().isNotEmpty) {
        languageDisplayName = d.trim();
      }
      if (c is String && c.trim().isNotEmpty) {
        languageCode = c.trim();
      }
    }
    final villageTitle = '$languageDisplayName Village';
    final onlineLearners = 18 + languageDisplayName.hashCode.abs() % 214;
    final languageCodeUpper = languageCode.toUpperCase();

    return GriotScaffold(
      body: GriotSvgPatternBackground(
        pattern: GriotPattern.dots,
        opacity: 0.05,
        color: ModernGriotColors.secondary,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ModernGriotColors.secondary.withAlpha(25),
                    ModernGriotColors.surface,
                  ],
                ),
              ),
            ),
            CustomPaint(
              size: Size.infinite,
              painter: _VillagePathPainter(
                locations: _locations,
                color: ModernGriotColors.secondary.withAlpha(60),
              ),
            ),
            ..._avatars.map((a) => _buildAvatar(context, a)),
            ..._locations.asMap().entries.map((e) => _buildLocationNode(
                  context,
                  e.value,
                  e.key,
                  selectedIdx,
                ),),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8.h,
              left: 16.w,
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withAlpha(220),
                    shape: BoxShape.circle,
                    boxShadow: ModernGriotShadows.sm,
                  ),
                  child: Icon(Icons.arrow_back_rounded, size: 20.sp),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8.h,
              right: 16.w,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => VillageNavigation.pushTribeHub(context),
                  child: Ink(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      gradient: ModernGriotGradients.signatureGradient,
                      shape: BoxShape.circle,
                      boxShadow: ModernGriotShadows.fab,
                    ),
                    child: Icon(Icons.shield_rounded,
                        size: 22.sp, color: ModernGriotColors.onPrimary),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8.h,
              left: 0,
              right: 0,
              child: Center(
                child: GriotGlassPanel(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  borderRadius: ModernGriotRadius.borderPill,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: ModernGriotColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(villageTitle,
                          style: ModernGriotTypography.labelMedium()),
                      SizedBox(width: 4.w),
                      Text('•',
                          style: TextStyle(
                              color: ModernGriotColors.onSurfaceVariant)),
                      SizedBox(width: 4.w),
                      Text('$onlineLearners Active',
                          style: ModernGriotTypography.labelSmall(
                              color: ModernGriotColors.secondary)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ValueListenableBuilder<int>(
                valueListenable: selectedIdx,
                builder: (context, sel, _) {
                  if (sel < 0) return const SizedBox.shrink();
                  return _DetailPanel(
                    location: _locations[sel],
                    onlineLearners: onlineLearners,
                    onClose: () => selectedIdx.value = -1,
                    onEnter: () {
                      VillageNavigation.enterLanguageVillagePlace(
                        context,
                        placeName: _locations[sel].name,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationNode(
    BuildContext context,
    _VillageLocation loc,
    int index,
    ValueNotifier<int> selectedIdx,
  ) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final x = loc.position.dx * size.width - 55.w;
    final y = loc.position.dy * size.height;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          selectedIdx.value = index;
        },
        child: GriotCard(
          padding: EdgeInsets.all(10.r),
          surfaceLevel: 0,
          child: SizedBox(
            width: 100.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(loc.icon, size: 18.sp, color: cs.primary),
                ),
                SizedBox(height: 6.h),
                Text(
                  loc.name,
                  style: ModernGriotTypography.labelMedium(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  loc.description,
                  style:
                      TextStyle(fontSize: 9.sp, color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, _WanderingAvatar avatar) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: avatar.position.dx * size.width,
      top: avatar.position.dy * size.height,
      child: Container(
        width: 30.r,
        height: 30.r,
        decoration: BoxDecoration(
          color: avatar.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: ModernGriotShadows.sm,
        ),
        child: Center(
          child: Text(
            avatar.initials,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _VillageLocation {
  const _VillageLocation(
      this.name, this.icon, this.description, this.position);
  final String name;
  final IconData icon;
  final String description;
  final Offset position;
}

class _WanderingAvatar {
  const _WanderingAvatar(this.initials, this.position, this.color);
  final String initials;
  final Offset position;
  final Color color;
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.location,
    required this.onlineLearners,
    required this.languageCodeLabel,
    required this.onClose,
    required this.onEnter,
  });
  final _VillageLocation location;
  final int onlineLearners;
  final String languageCodeLabel;
  final VoidCallback onClose;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GriotGlassPanel(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      padding: EdgeInsets.all(20.r),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withAlpha(60),
                borderRadius: ModernGriotRadius.borderPill,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    gradient: ModernGriotGradients.signatureGradient,
                    borderRadius: ModernGriotRadius.borderLg,
                  ),
                  child: Icon(location.icon,
                      size: 24.sp, color: cs.onPrimary),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(location.name,
                          style: ModernGriotTypography.titleLarge()),
                      SizedBox(height: 2.h),
                      Text(location.description,
                          style: ModernGriotTypography.bodyMedium()),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20.sp),
                  onPressed: onClose,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                GriotBadgePill(
                  label: '$onlineLearners online',
                  icon: Icons.circle,
                  color: ModernGriotColors.secondaryContainer,
                  textColor: ModernGriotColors.onSecondaryContainer,
                ),
                SizedBox(width: 8.w),
                GriotBadgePill(
                  label: languageCodeLabel,
                  color: ModernGriotColors.primaryContainer.withAlpha(40),
                  textColor: ModernGriotColors.primary,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: GriotGradientButton(
                label: 'Enter',
                icon: Icons.arrow_forward_rounded,
                onPressed: onEnter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VillagePathPainter extends CustomPainter {
  _VillagePathPainter({required this.locations, required this.color});
  final List<_VillageLocation> locations;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < locations.length - 1; i++) {
      final from = Offset(
        locations[i].position.dx * size.width,
        locations[i].position.dy * size.height + 40,
      );
      final to = Offset(
        locations[i + 1].position.dx * size.width,
        locations[i + 1].position.dy * size.height + 40,
      );
      final mid =
          Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2 - 30);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);
      _drawDashed(canvas, path, paint, 6, 5);
    }
  }

  void _drawDashed(
      Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final end = (d + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

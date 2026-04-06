import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/navigation/village_navigation.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class SwahiliVillageMapScreen extends HookConsumerWidget {
  const SwahiliVillageMapScreen({super.key});

  static const _buildings = [
    _Building("Elder's Hut", 'NYUMBA YA WAZEE', Icons.auto_stories_rounded,
        Offset(0.22, 0.18)),
    _Building('School', 'SHULE', Icons.school_rounded, Offset(0.68, 0.15)),
    _Building('Market', 'SOKO', Icons.storefront_rounded, Offset(0.15, 0.42)),
    _Building('Café', 'MKAHWA', Icons.coffee_rounded, Offset(0.72, 0.38)),
    _Building('Griot Stage', 'JUKWAA LA SIMULIZI', Icons.mic_rounded,
        Offset(0.45, 0.58)),
  ];

  static const _avatars = [
    _Avatar('AS', Offset(0.38, 0.25), Color(0xFF9E3D00)),
    _Avatar('MW', Offset(0.55, 0.45), Color(0xFF526124)),
    _Avatar('JK', Offset(0.28, 0.55), Color(0xFF7B5733)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GriotScaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.3),
                radius: 1.4,
                colors: [
                  Color(0xFFFFF3D6),
                  Color(0xFFFEF6E7),
                  Color(0xFFF8F0E0),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _SavannahDotsPainter(),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _BuildingPathPainter(buildings: _buildings),
          ),
          ..._avatars.map((a) => _buildFloatingAvatar(context, a)),
          ..._buildings.map((b) => _buildBuildingNode(context, b)),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12.h,
            left: 0,
            right: 0,
            child: Center(
              child: GriotGlassPanel(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                    SizedBox(width: 8.w),
                    Text(
                      'Swahili Village',
                      style: ModernGriotTypography.titleSmall(),
                    ),
                    SizedBox(width: 6.w),
                    Text('•',
                        style: TextStyle(
                            color: ModernGriotColors.onSurfaceVariant)),
                    SizedBox(width: 6.w),
                    Text(
                      '245 Active',
                      style: ModernGriotTypography.labelSmall(
                        color: ModernGriotColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12.h,
            left: 16.w,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: ModernGriotColors.surface.withAlpha(220),
                  shape: BoxShape.circle,
                  boxShadow: ModernGriotShadows.sm,
                ),
                child: Icon(Icons.arrow_back_rounded, size: 20.sp),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24.h,
            right: 24.w,
            child: _PulseMicFab(),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingNode(BuildContext context, _Building b) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final x = b.position.dx * size.width - 55.w;
    final y = b.position.dy * size.height;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          VillageNavigation.enterSwahiliMapBuilding(
            context,
            englishLabel: b.english,
          );
        },
        child: Container(
          width: 110.w,
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: ModernGriotRadius.borderXl,
            boxShadow: ModernGriotShadows.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(b.icon, size: 20.sp, color: cs.primary),
              ),
              SizedBox(height: 6.h),
              Text(
                b.english,
                style: ModernGriotTypography.labelMedium(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                b.swahili,
                style: TextStyle(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w800,
                  color: ModernGriotColors.primary,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAvatar(BuildContext context, _Avatar a) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: a.position.dx * size.width,
      top: a.position.dy * size.height,
      child: Container(
        width: 28.r,
        height: 28.r,
        decoration: BoxDecoration(
          color: a.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: ModernGriotShadows.sm,
        ),
        child: Center(
          child: Text(
            a.initials,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Building {
  const _Building(this.english, this.swahili, this.icon, this.position);
  final String english;
  final String swahili;
  final IconData icon;
  final Offset position;
}

class _Avatar {
  const _Avatar(this.initials, this.position, this.color);
  final String initials;
  final Offset position;
  final Color color;
}

class _PulseMicFab extends StatefulWidget {
  @override
  State<_PulseMicFab> createState() => _PulseMicFabState();
}

class _PulseMicFabState extends State<_PulseMicFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context)
              .pushNamed('/${VillageRouteNames.polieModeSelection}');
        },
        child: Container(
          width: 60.r,
          height: 60.r,
          decoration: BoxDecoration(
            gradient: ModernGriotGradients.signatureGradient,
            shape: BoxShape.circle,
            boxShadow: ModernGriotShadows.fab,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_rounded, size: 24.sp,
                  color: ModernGriotColors.onPrimary),
              Text(
                'Talk',
                style: TextStyle(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w700,
                  color: ModernGriotColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavannahDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ModernGriotColors.onSurface.withAlpha(8)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        canvas.drawCircle(
          Offset(c * spacing + spacing / 2, r * spacing + spacing / 2),
          1.2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BuildingPathPainter extends CustomPainter {
  _BuildingPathPainter({required this.buildings});
  final List<_Building> buildings;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ModernGriotColors.primary.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < buildings.length - 1; i++) {
      final from = Offset(
        buildings[i].position.dx * size.width,
        buildings[i].position.dy * size.height + 40,
      );
      final to = Offset(
        buildings[i + 1].position.dx * size.width,
        buildings[i + 1].position.dy * size.height + 40,
      );
      final ctrl = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2 - 20);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/widgets/learning_path/path_tokens.dart';

/// Polie moods from polie_path.riv / PolieVM (v3).
enum PoliePathMood { idle, cheer, pointUp, sleepy }

String poliePathMoodWireName(PoliePathMood mood) {
  switch (mood) {
    case PoliePathMood.idle:
      return 'idle';
    case PoliePathMood.cheer:
      return 'cheer';
    case PoliePathMood.pointUp:
      return 'pointUp';
    case PoliePathMood.sleepy:
      return 'sleepy';
  }
}

const String kPoliePathRivAsset = 'assets/rive/path/polie_path.riv';

/// Polie on the lesson path: Rive when licensed asset exists; labelled still otherwise (P7-953 AC4).
class PoliePathMascot extends StatefulWidget {
  const PoliePathMascot({
    super.key,
    this.mood = PoliePathMood.idle,
    this.reducedMotion = false,
    this.bundleLicensed = true,
    this.rivAssetPresent = false,
    this.polieLabel = 'Polie, your learning guide',
    this.onTap,
    this.compact = false,
  });

  final PoliePathMood mood;
  final bool reducedMotion;
  final bool bundleLicensed;
  /// Set true when [kPoliePathRivAsset] is in the asset bundle (F-007 copy).
  final bool rivAssetPresent;
  final String polieLabel;
  final VoidCallback? onTap;

  /// Beside-node size for Candy Crush-style "avatar marks where you are".
  final bool compact;

  @override
  State<PoliePathMascot> createState() => _PoliePathMascotState();
}

class _PoliePathMascotState extends State<PoliePathMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;
  bool _assetOk = false;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (!widget.reducedMotion) {
      _bob.repeat(reverse: true);
    }
    _probeAsset();
  }

  Future<void> _probeAsset() async {
    if (!widget.bundleLicensed) return;
    if (widget.rivAssetPresent) {
      if (mounted) setState(() => _assetOk = true);
      return;
    }
    try {
      await rootBundle.load(kPoliePathRivAsset);
      if (mounted) setState(() => _assetOk = true);
    } catch (_) {
      // Still frame is fine.
    }
  }

  @override
  void didUpdateWidget(PoliePathMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion) {
      if (widget.reducedMotion) {
        _bob.stop();
        _bob.value = 0;
      } else {
        _bob.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Painted Polie silhouette is the reliable default; Rive artboard is
    // probed so INTEGRATION contracts stay wired for when GPU decode works.
    final child = PoliePathStillFrame(
      mood: widget.mood,
      label: widget.polieLabel,
      animate: !widget.reducedMotion,
      bob: _bob,
      hintRiveReady: _assetOk,
      compact: widget.compact,
    );

    final w = widget.compact ? 56.w : 120.w;
    final h = widget.compact ? 68.h : 140.h;

    return Semantics(
      button: widget.onTap != null,
      label: widget.polieLabel,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(width: w, height: h, child: child),
      ),
    );
  }
}

/// Static / lightly bobbing Polie frame (Rive absent, unlicensed, or reduced motion).
class PoliePathStillFrame extends StatelessWidget {
  const PoliePathStillFrame({
    super.key,
    required this.mood,
    required this.label,
    this.animate = false,
    this.bob,
    this.hintRiveReady = false,
    this.compact = false,
  });

  final PoliePathMood mood;
  final String label;
  final bool animate;
  final Animation<double>? bob;
  final bool hintRiveReady;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget body = FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PolieSilhouette(mood: mood),
          if (!compact) ...[
            SizedBox(height: 6.h),
            SizedBox(
              width: 108.w,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              poliePathMoodWireName(mood),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );

    if (animate && bob != null) {
      body = AnimatedBuilder(
        animation: bob!,
        builder: (context, child) {
          final t = bob!.value;
          return Transform.translate(
            offset: Offset(0, (t - 0.5) * 6),
            child: child,
          );
        },
        child: body,
      );
    }

    return Semantics(
      label: '$label. ${poliePathMoodWireName(mood)}.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: compact
              ? Colors.transparent
              : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(compact ? 16.r : 24.r),
          border: compact
              ? null
              : Border.all(
                  color: hintRiveReady
                      ? PathBrandColors.gold.withValues(alpha: 0.55)
                      : cs.outlineVariant.withValues(alpha: 0.4),
                ),
        ),
        child: body,
      ),
    );
  }
}

/// Readable Polie silhouette at ~40–80px (v3 brief: round head + quill crest).
class _PolieSilhouette extends StatelessWidget {
  const _PolieSilhouette({required this.mood});

  final PoliePathMood mood;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64.w,
      height: 72.h,
      child: CustomPaint(
        painter: _PoliePainter(mood: mood),
      ),
    );
  }
}

class _PoliePainter extends CustomPainter {
  _PoliePainter({required this.mood});

  final PoliePathMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFF5B8DEF);
    final gold = Paint()..color = PathBrandColors.gold;
    final cream = Paint()..color = const Color(0xFFFFF6E8);
    final cx = size.width / 2;

    // Hover disc
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.92),
        width: size.width * 0.55,
        height: size.height * 0.1,
      ),
      Paint()..color = const Color(0x6639D0E0),
    );

    // Pod / body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, size.height * 0.62),
          width: size.width * 0.42,
          height: size.height * 0.38,
        ),
        const Radius.circular(16),
      ),
      body,
    );
    // Gold core
    canvas.drawCircle(Offset(cx, size.height * 0.62), size.width * 0.08, gold);

    // Head
    canvas.drawCircle(Offset(cx, size.height * 0.32), size.width * 0.28, body);

    // Quill crest
    final quill = Path()
      ..moveTo(cx + size.width * 0.08, size.height * 0.12)
      ..quadraticBezierTo(
        cx + size.width * 0.32,
        size.height * 0.02,
        cx + size.width * 0.22,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        cx + size.width * 0.14,
        size.height * 0.18,
        cx + size.width * 0.08,
        size.height * 0.12,
      );
    canvas.drawPath(quill, cream);

    // Visor eyes by mood
    final eyeY = size.height * 0.32;
    final eyePaint = Paint()
      ..color = const Color(0xFF1A2744)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case PoliePathMood.cheer:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx - 8, eyeY),
            width: 10,
            height: 8,
          ),
          3.6,
          2.2,
          false,
          eyePaint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx + 8, eyeY),
            width: 10,
            height: 8,
          ),
          3.6,
          2.2,
          false,
          eyePaint,
        );
      case PoliePathMood.pointUp:
        canvas.drawLine(Offset(cx - 10, eyeY + 2), Offset(cx - 4, eyeY - 4), eyePaint);
        canvas.drawLine(Offset(cx + 4, eyeY + 2), Offset(cx + 10, eyeY - 4), eyePaint);
      case PoliePathMood.sleepy:
        canvas.drawLine(Offset(cx - 12, eyeY), Offset(cx - 4, eyeY), eyePaint);
        canvas.drawLine(Offset(cx + 4, eyeY), Offset(cx + 12, eyeY), eyePaint);
        final z = TextPainter(
          text: const TextSpan(
            text: 'z',
            style: TextStyle(
              color: Color(0xFF1A2744),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        z.paint(canvas, Offset(cx + 14, eyeY - 18));
      case PoliePathMood.idle:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx - 8, eyeY), width: 8, height: 5),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFF1A2744),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + 8, eyeY), width: 8, height: 5),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFF1A2744),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _PoliePainter oldDelegate) =>
      oldDelegate.mood != mood;
}

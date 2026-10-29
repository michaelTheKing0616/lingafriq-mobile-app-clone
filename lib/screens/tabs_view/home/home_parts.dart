import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Bundled illustrations for languages that ship with their own art.
const Map<String, String> kLanguageArtAssets = {
  'hausa': 'assets/images/hausa.png',
  'igala': 'assets/images/igala.png',
  'pidgin': 'assets/images/pidgin.png',
  'tiv': 'assets/images/tiv.png',
};

/// Brand tile colours (white monogram stays >=3:1 for large bold text).
const List<Color> kLanguageTileColors = [
  PanAfricanColors.primary,
  PanAfricanColors.kenteRed,
  PanAfricanColors.onTertiaryContainer,
  Color(0xFF0E6E5C),
  Color(0xFF6E3A8A),
  PanAfricanColors.primaryDark,
];

/// Bundled illustration for [name], if any.
String? languageArtAsset(String name) {
  final n = name.toLowerCase();
  for (final e in kLanguageArtAssets.entries) {
    if (n.contains(e.key)) return e.value;
  }
  return null;
}

/// Stable per-language tile colour (same name, same colour, every launch).
Color languageTileColor(String name) {
  var h = 0;
  for (final c in name.toLowerCase().codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return kLanguageTileColors[h % kLanguageTileColors.length];
}

String languageMonogram(String name) {
  final t = name.trim();
  return t.isEmpty ? '?' : t.characters.first.toUpperCase();
}

/// A branded tile per language: remote art when the API has it, else the
/// bundled illustration, else a coloured monogram on a woven pattern.
/// Never the generic globe.
class LanguageArt extends StatelessWidget {
  const LanguageArt({super.key, required this.name, this.imageUrl, this.size});

  final String name;
  final String? imageUrl;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 56.w;
    final local = _local(context, s);
    final url = imageUrl ?? '';
    final child = url.isEmpty
        ? local
        : CachedNetworkImage(
            imageUrl: url,
            width: s,
            height: s,
            fit: BoxFit.cover,
            placeholder: (_, __) => local,
            errorWidget: (_, __, ___) => local,
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
      child: SizedBox(width: s, height: s, child: child),
    );
  }

  Widget _local(BuildContext context, double s) {
    final asset = languageArtAsset(name);
    final color = languageTileColor(name);
    final mono = Text(
      languageMonogram(name),
      textScaler: TextScaler.noScaling,
      style: PanAfricanTypography.headlineLarge(context).copyWith(
        fontWeight: FontWeight.w900,
        fontSize: s * 0.46,
        height: 1,
        color: Colors.white,
        shadows: const [Shadow(blurRadius: 4, color: Color(0x66000000))],
      ),
    );
    return Stack(
      key: ValueKey(asset == null ? 'lang-art-monogram' : 'lang-art-image'),
      fit: StackFit.expand,
      children: [
        if (asset != null)
          Image.asset(asset, fit: BoxFit.cover)
        else ...[
          ColoredBox(color: color),
          CustomPaint(painter: _WovenPainter()),
        ],
        if (asset != null)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x8C000000)],
              ),
            ),
          ),
        Center(child: mono),
      ],
    );
  }
}

/// Kente-style woven bands: two gold stripes and a row of small diamonds.
class _WovenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final band = Paint()..color = const Color(0x33FFFFFF);
    final gold = Paint()
      ..color = PanAfricanColors.secondary.withValues(alpha: 0.85);
    final w = size.width, h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.70, w, h * 0.06), gold);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.86, w, h * 0.04), band);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.10, w, h * 0.04), band);
    final d = w / 6;
    for (var i = 0; i < 6; i++) {
      final cx = d * i + d / 2, cy = h * 0.80;
      canvas.drawPath(
        Path()
          ..moveTo(cx, cy - d * 0.22)
          ..lineTo(cx + d * 0.22, cy)
          ..lineTo(cx, cy + d * 0.22)
          ..lineTo(cx - d * 0.22, cy)
          ..close(),
        band,
      );
    }
  }

  @override
  bool shouldRepaint(_WovenPainter oldDelegate) => false;
}

/// One designed panel for Home's empty / offline / error states: a tinted
/// medallion, a title, one sentence and one action.
class HomeStatePanel extends StatelessWidget {
  const HomeStatePanel({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String body;
  final String actionLabel;
  final IconData? actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        PanAfricanSpacing.md,
        PanAfricanSpacing.lg,
        PanAfricanSpacing.md,
        PanAfricanSpacing.lg,
      ),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Column(
          children: [
            SizedBox(
              width: 112.w,
              height: 112.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tint.withValues(alpha: 0.14),
                    ),
                  ),
                  Container(
                    width: 76.w,
                    height: 76.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tint.withValues(alpha: 0.24),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(icon, size: 40.w, color: tint),
                  ),
                  PositionedDirectional(
                    top: 8.w,
                    end: 10.w,
                    child: const _Dot(PanAfricanColors.secondary, 12),
                  ),
                  PositionedDirectional(
                    bottom: 14.w,
                    start: 6.w,
                    child: const _Dot(PanAfricanColors.tertiary, 8),
                  ),
                ],
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: PanAfricanTypography.titleLarge(context),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.bodyMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 160),
              child: FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.refresh_rounded),
                label: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color, this.size);
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Skeleton for the language list while it loads: a Continue-card block and
/// three tile rows in the real layout, softly pulsing (static under reduced
/// motion), plus a visible caption so the wait is explained in words.
class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key, required this.caption});
  final String caption;

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 0.5;
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? PanAfricanColors.neutralDark
        : PanAfricanColors.neutralLightest;
    final hi = isDark
        ? PanAfricanColors.neutralMedium
        : const Color(0xFFE3E8E5);
    Widget block(double h, {double? w, double r = 12}) => AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: Color.lerp(base, hi, _c.value),
          borderRadius: BorderRadius.circular(r),
        ),
      ),
    );
    final side = PanAfricanSpacing.md;
    return Semantics(
      key: const Key('home-skeleton'),
      liveRegion: true,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(side, side, side, side),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: block(120.w, r: 20)),
            SizedBox(height: PanAfricanSpacing.lg),
            ExcludeSemantics(child: block(22.w, w: 180.w, r: 8)),
            for (var i = 0; i < 3; i++) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              ExcludeSemantics(
                child: Row(
                  children: [
                    block(56.w, w: 56.w),
                    SizedBox(width: PanAfricanSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          block(16.w, w: 140.w, r: 6),
                          SizedBox(height: PanAfricanSpacing.xs),
                          block(10.w, r: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: PanAfricanSpacing.md),
            Center(
              child: Text(
                widget.caption,
                textAlign: TextAlign.center,
                style: PanAfricanTypography.bodySmall(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

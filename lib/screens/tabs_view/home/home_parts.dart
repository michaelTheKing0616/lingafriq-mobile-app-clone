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

/// Geometric motifs drawn in code (no copied artwork); each language gets
/// its own so tiles read apart even in greyscale.
enum LanguageMotif {
  waves,
  circles,
  triangles,
  lozenges,
  chevrons,
  stripes,
  dots,
  steps,
}

/// A language's designed identity: palette, motif, native-script name and
/// a short greeting in the language itself.
@immutable
class LanguageIdentity {
  const LanguageIdentity({
    required this.base,
    required this.accent,
    required this.motif,
    this.native,
    this.greeting,
  });

  /// Tile fill; white text on it clears 4.5:1 (see the contrast test).
  final Color base;

  /// Lighter partner hue used by the motif.
  final Color accent;
  final LanguageMotif motif;
  final String? native;
  final String? greeting;
}

/// Known languages. Hues are spread around the wheel so neighbours differ.
const Map<String, LanguageIdentity> kLanguageIdentities = {
  'swahili': LanguageIdentity(
    base: Color(0xFF0B6262),
    accent: Color(0xFF5FD0C4),
    motif: LanguageMotif.waves,
    native: 'Kiswahili',
    greeting: 'Habari',
  ),
  'yoruba': LanguageIdentity(
    base: Color(0xFF2E3A87),
    accent: Color(0xFF9FB0FF),
    motif: LanguageMotif.circles,
    native: 'Yorùbá',
    greeting: 'Ẹ káàbọ̀',
  ),
  'hausa': LanguageIdentity(
    base: Color(0xFF8A4A10),
    accent: Color(0xFFF2B35B),
    motif: LanguageMotif.lozenges,
    native: 'Harshen Hausa',
    greeting: 'Sannu',
  ),
  'zulu': LanguageIdentity(
    base: Color(0xFF8A2D4F),
    accent: Color(0xFFF59AB8),
    motif: LanguageMotif.triangles,
    native: 'isiZulu',
    greeting: 'Sawubona',
  ),
  'igbo': LanguageIdentity(
    base: Color(0xFF1F6B3A),
    accent: Color(0xFF8EE0A6),
    motif: LanguageMotif.lozenges,
    native: 'Asụsụ Igbo',
    greeting: 'Nnọọ',
  ),
  'amharic': LanguageIdentity(
    base: Color(0xFF5B3A9A),
    accent: Color(0xFFC6B2FF),
    motif: LanguageMotif.steps,
    native: 'አማርኛ',
    greeting: 'ሰላም',
  ),
  'twi': LanguageIdentity(
    base: Color(0xFF9C3B12),
    accent: Color(0xFFFFB27A),
    motif: LanguageMotif.chevrons,
    native: 'Twi',
    greeting: 'Akwaaba',
  ),
  'xhosa': LanguageIdentity(
    base: Color(0xFF2F4F7A),
    accent: Color(0xFF9CC3F5),
    motif: LanguageMotif.stripes,
    native: 'isiXhosa',
    greeting: 'Molo',
  ),
  'pidgin': LanguageIdentity(
    base: Color(0xFF6A5A0A),
    accent: Color(0xFFF2D65B),
    motif: LanguageMotif.dots,
    native: 'Naijá',
    greeting: 'How far',
  ),
  'igala': LanguageIdentity(
    base: Color(0xFF7A2E2E),
    accent: Color(0xFFF0A08A),
    motif: LanguageMotif.chevrons,
    native: 'Igala',
  ),
  'tiv': LanguageIdentity(
    base: Color(0xFF3F5E1A),
    accent: Color(0xFFC4E58A),
    motif: LanguageMotif.stripes,
    native: 'Tiv',
  ),
  'somali': LanguageIdentity(
    base: Color(0xFF155A8A),
    accent: Color(0xFF8CCBF5),
    motif: LanguageMotif.dots,
    native: 'Af-Soomaali',
    greeting: 'Salaan',
  ),
  'shona': LanguageIdentity(
    base: Color(0xFF6B4423),
    accent: Color(0xFFE8B98A),
    motif: LanguageMotif.steps,
    native: 'chiShona',
    greeting: 'Mhoro',
  ),
  'lingala': LanguageIdentity(
    base: Color(0xFF0F5E4A),
    accent: Color(0xFF7FE0C2),
    motif: LanguageMotif.triangles,
    native: 'Lingála',
    greeting: 'Mbote',
  ),
  'kinyarwanda': LanguageIdentity(
    base: Color(0xFF3A5A8C),
    accent: Color(0xFFB5D0FF),
    motif: LanguageMotif.waves,
    native: 'Ikinyarwanda',
    greeting: 'Muraho',
  ),
  'wolof': LanguageIdentity(
    base: Color(0xFF7A3F6E),
    accent: Color(0xFFF0B0E0),
    motif: LanguageMotif.circles,
    native: 'Wolof',
    greeting: 'Nanga def',
  ),
};

/// Bundled illustration for [name], if any.
String? languageArtAsset(String name) {
  final n = name.toLowerCase();
  for (final e in kLanguageArtAssets.entries) {
    if (n.contains(e.key)) return e.value;
  }
  return null;
}

int _stableHash(String s) {
  var h = 0;
  for (final c in s.toLowerCase().codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

/// Identity for [name]: the curated one, else a stable generated one
/// (hue from the name, dark enough for white text, motif from the name).
LanguageIdentity languageIdentity(String name) {
  final n = name.toLowerCase();
  for (final e in kLanguageIdentities.entries) {
    if (n.contains(e.key)) return e.value;
  }
  final h = _stableHash(n);
  final hue = (h % 360).toDouble();
  return LanguageIdentity(
    base: HSLColor.fromAHSL(1, hue, 0.55, 0.28).toColor(),
    accent: HSLColor.fromAHSL(1, hue, 0.75, 0.72).toColor(),
    motif: LanguageMotif.values[h % LanguageMotif.values.length],
  );
}

/// Stable per-language tile colour (same name, same colour, every launch).
Color languageTileColor(String name) => languageIdentity(name).base;

/// Monogram from the native-script name when we have it.
String languageMonogram(String name) {
  final t = (languageIdentity(name).native ?? name).trim();
  if (t.isEmpty) return '?';
  // Skip lowercase prefixes like "isi"/"chi"/"Af-" so isiZulu reads "Z".
  final m = RegExp(r'[A-ZÀ-Ý]').firstMatch(t);
  final ch = m == null ? t.characters.first : m.group(0)!;
  return ch.toUpperCase();
}

/// A designed tile per language: remote art when the API has it, else the
/// bundled illustration framed in the language's colour, else its palette,
/// geometric motif and native-script monogram. Never the generic globe.
class LanguageArt extends StatelessWidget {
  const LanguageArt({super.key, required this.name, this.imageUrl, this.size});

  final String name;
  final String? imageUrl;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 56.w;
    final id = languageIdentity(name);
    final local = _local(context, s, id);
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
    return Container(
      width: s,
      height: s,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: id.accent,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md + 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: child,
      ),
    );
  }

  Widget _local(BuildContext context, double s, LanguageIdentity id) {
    final asset = languageArtAsset(name);
    final mono = Text(
      languageMonogram(name),
      textScaler: TextScaler.noScaling,
      style: PanAfricanTypography.headlineLarge(context).copyWith(
        fontWeight: FontWeight.w900,
        fontSize: s * 0.42,
        height: 1,
        color: Colors.white,
        shadows: const [Shadow(blurRadius: 4, color: Color(0x66000000))],
      ),
    );
    if (asset != null) {
      return Stack(
        key: const ValueKey('lang-art-image'),
        fit: StackFit.expand,
        children: [
          Image.asset(asset, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, id.base.withValues(alpha: 0.85)],
              ),
            ),
          ),
          Align(alignment: const Alignment(0, 0.55), child: mono),
        ],
      );
    }
    return Stack(
      key: const ValueKey('lang-art-monogram'),
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(id.base, id.accent, 0.18)!, id.base],
            ),
          ),
        ),
        CustomPaint(
          key: ValueKey('motif-${id.motif.name}'),
          painter: MotifPainter(id.motif, id.accent),
        ),
        Center(child: mono),
      ],
    );
  }
}

/// Paints [motif] in [color] at low alpha, kept to the tile edges so the
/// monogram in the centre stays clean.
class MotifPainter extends CustomPainter {
  const MotifPainter(this.motif, this.color);
  final LanguageMotif motif;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;
    final f = Paint()..color = color.withValues(alpha: 0.6);
    switch (motif) {
      case LanguageMotif.waves:
        for (final y in [0.14, 0.86]) {
          final path = Path()..moveTo(0, h * y);
          for (var i = 0; i < 4; i++) {
            final x0 = w * i / 4;
            path.quadraticBezierTo(
              x0 + w / 8,
              h * y + (i.isEven ? -h * 0.07 : h * 0.07),
              x0 + w / 4,
              h * y,
            );
          }
          canvas.drawPath(path, p);
        }
      case LanguageMotif.circles:
        for (final c in [const Offset(0, 0), Offset(w, h)]) {
          for (var r = 0.18; r <= 0.42; r += 0.12) {
            canvas.drawCircle(c, w * r, p);
          }
        }
      case LanguageMotif.triangles:
        for (var i = 0; i < 5; i++) {
          final x = w * i / 4;
          canvas.drawPath(
            Path()
              ..moveTo(x - w * 0.1, h)
              ..lineTo(x, h * 0.84)
              ..lineTo(x + w * 0.1, h)
              ..close(),
            f,
          );
          canvas.drawPath(
            Path()
              ..moveTo(x - w * 0.1, 0)
              ..lineTo(x, h * 0.16)
              ..lineTo(x + w * 0.1, 0)
              ..close(),
            f,
          );
        }
      case LanguageMotif.lozenges:
        for (final y in [0.12, 0.88]) {
          for (var i = 0; i < 5; i++) {
            final cx = w * (i + 0.5) / 5, cy = h * y, d = w * 0.07;
            canvas.drawPath(
              Path()
                ..moveTo(cx, cy - d)
                ..lineTo(cx + d, cy)
                ..lineTo(cx, cy + d)
                ..lineTo(cx - d, cy)
                ..close(),
              f,
            );
          }
        }
      case LanguageMotif.chevrons:
        for (final y in [0.1, 0.82]) {
          final path = Path()..moveTo(0, h * (y + 0.06));
          for (var i = 0; i < 5; i++) {
            path
              ..lineTo(w * (i + 0.5) / 5, h * y)
              ..lineTo(w * (i + 1) / 5, h * (y + 0.06));
          }
          canvas.drawPath(path, p);
        }
      case LanguageMotif.stripes:
        for (var i = -2; i < 8; i++) {
          final x = w * i / 5;
          canvas.save();
          canvas.clipRect(Rect.fromLTWH(0, 0, w * 0.22, h));
          canvas.drawLine(Offset(x, h), Offset(x + w * 0.4, 0), p);
          canvas.restore();
          canvas.save();
          canvas.clipRect(Rect.fromLTWH(w * 0.78, 0, w * 0.22, h));
          canvas.drawLine(Offset(x, h), Offset(x + w * 0.4, 0), p);
          canvas.restore();
        }
      case LanguageMotif.dots:
        for (var i = 0; i < 6; i++) {
          for (final y in [0.1, 0.9]) {
            canvas.drawCircle(Offset(w * (i + 0.5) / 6, h * y), w * 0.03, f);
          }
        }
      case LanguageMotif.steps:
        for (final flip in [false, true]) {
          final path = Path();
          final y0 = flip ? h : 0.0, dir = flip ? -1 : 1;
          path.moveTo(0, y0 + dir * h * 0.2);
          for (var i = 0; i < 4; i++) {
            final x = w * i / 4;
            path
              ..lineTo(x + w / 8, y0 + dir * h * 0.2)
              ..lineTo(x + w / 8, y0 + dir * h * 0.08)
              ..lineTo(x + w / 4, y0 + dir * h * 0.08)
              ..lineTo(x + w / 4, y0 + dir * h * 0.2);
          }
          canvas.drawPath(path, p);
        }
    }
  }

  @override
  bool shouldRepaint(MotifPainter old) =>
      old.motif != motif || old.color != color;
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

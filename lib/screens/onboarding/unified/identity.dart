part of '../unified_onboarding_screen.dart';

/// LingAfriq identity: original code-drawn motifs, per-language greetings and
/// regional accents. No third-party pattern or brand asset is used.

/// Caption ink for onboarding: >= 7:1 on surface, >= 4.5:1 on overlays
/// and the welcome gradient (darker than the app-wide onSurfaceVariant).
const Color _captionInk = Color(0xFF4A453B);

/// Native greeting per learn language (shown in its own script).
const Map<String, String> _greetings = {
  'yo': 'Ẹ kú àbọ̀',
  'ha': 'Sannu',
  'ig': 'Nnọọ',
  'tw': 'Akwaaba',
  'wo': 'Dalal ak jàmm',
  'pcm': 'How far?',
  'sw': 'Karibu',
  'am': 'እንኳን ደህና መጡ',
  'zu': 'Sawubona',
  'xh': 'Molo',
  'ar-maghreb': 'مرحبا',
  'ber': 'ⴰⵣⵓⵍ',
};

/// Decorative accents only (never text); each is >= 3:1 on surface white.
const Map<String, Color> _accents = {
  'yo': Color(0xFF2B3A8F), // indigo dye
  'ha': Color(0xFF1E6B4F), // savanna green
  'ig': Color(0xFF8A3B12), // uli earth
  'tw': Color(0xFF8A6200), // woven gold
  'wo': Color(0xFF00695C), // Atlantic teal
  'pcm': Color(0xFF2E7D32),
  'sw': Color(0xFF0B6E8A), // coast blue
  'am': Color(0xFF7B2D26), // highland red
  'zu': Color(0xFFB0381C), // bead red
  'xh': Color(0xFF6A3D9A),
  'ar-maghreb': Color(0xFF9C2A3A),
  'ber': Color(0xFF1558B0),
};

Color _accentFor(String? code) =>
    _accents[code] ?? const Color(0xFFB8451F); // deep coral, 5:1 on white

/// Original "woven strip" motif: diamonds on a zig-zag warp. Drawn in code.
class _WovenStripPainter extends CustomPainter {
  const _WovenStripPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final cell = h * 1.6;
    final fill = Paint()..color = color.withValues(alpha: 0.85);
    final line = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = math.max(1, h * 0.08)
      ..style = PaintingStyle.stroke;
    final zig = Path()..moveTo(0, h * 0.5);
    for (double x = 0; x < size.width + cell; x += cell) {
      final d = Path()
        ..moveTo(x + cell / 2, h * 0.15)
        ..lineTo(x + cell / 2 + h * 0.3, h * 0.5)
        ..lineTo(x + cell / 2, h * 0.85)
        ..lineTo(x + cell / 2 - h * 0.3, h * 0.5)
        ..close();
      canvas.drawPath(d, fill);
      zig
        ..lineTo(x + cell / 4, 0)
        ..lineTo(x + cell * 3 / 4, h)
        ..lineTo(x + cell, h * 0.5);
    }
    canvas.drawPath(zig, line);
  }

  @override
  bool shouldRepaint(_WovenStripPainter old) => old.color != color;
}

class _WovenStrip extends StatelessWidget {
  const _WovenStrip({required this.color});
  final Color color;
  static const double height = 10;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(child: CustomPaint(painter: _WovenStripPainter(color))),
    ),
  );
}

/// Signature progress: a string of beads; done beads filled in the accent,
/// the current bead larger with a ring.
class _BeadProgressPainter extends CustomPainter {
  const _BeadProgressPainter({
    required this.current,
    required this.total,
    required this.accent,
    required this.track,
    required this.rtl,
  });
  final int current;
  final int total;
  final Color accent;
  final Color track;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final cy = size.height / 2;
    final step = total == 1 ? 0.0 : size.width / (total - 1);
    final r = math.min(size.height / 2, math.max(2.0, step / 3));
    final pad = r + 1;
    final span = size.width - pad * 2;
    double xAt(int i) {
      final t = total == 1 ? 0.5 : i / (total - 1);
      return pad + span * (rtl ? 1 - t : t);
    }

    canvas.drawLine(
      Offset(pad, cy),
      Offset(size.width - pad, cy),
      Paint()
        ..color = track
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(xAt(0), cy),
      Offset(xAt(current), cy),
      Paint()
        ..color = accent
        ..strokeWidth = 2,
    );
    for (var i = 0; i < total; i++) {
      final c = Offset(xAt(i), cy);
      if (i < current) {
        canvas.drawCircle(c, r * 0.7, Paint()..color = accent);
      } else if (i == current) {
        canvas.drawCircle(c, r, Paint()..color = accent);
        canvas.drawCircle(
          c,
          r * 0.4,
          Paint()..color = ModernGriotColors.surface,
        );
      } else {
        canvas.drawCircle(
          c,
          r * 0.55,
          Paint()
            ..color = track
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BeadProgressPainter o) =>
      o.current != current ||
      o.total != total ||
      o.accent != accent ||
      o.rtl != rtl;
}

/// Emblem motif per language: original geometric bead and weave marks drawn
/// in code (not copied from any cloth, flag or brand).
enum _Motif {
  indigoDots,
  weave,
  uliSpiral,
  checker,
  waves,
  ladder,
  beadRings,
  chevrons,
  triangles,
  star,
}

const Map<String, _Motif> _motifs = {
  'yo': _Motif.indigoDots,
  'ha': _Motif.star,
  'ig': _Motif.uliSpiral,
  'tw': _Motif.checker,
  'wo': _Motif.waves,
  'pcm': _Motif.ladder,
  'sw': _Motif.waves,
  'am': _Motif.chevrons,
  'zu': _Motif.beadRings,
  'xh': _Motif.beadRings,
  'ar-maghreb': _Motif.star,
  'ber': _Motif.triangles,
};

class _LanguageEmblem extends StatelessWidget {
  const _LanguageEmblem({required this.code, required this.size});
  final String code;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      key: ValueKey('emblem-$code'),
      dimension: size,
      child: CustomPaint(
        painter: _EmblemPainter(
          motif: _motifs[code] ?? _Motif.weave,
          accent: _accentFor(code),
          // Two languages may share a motif; the seed varies the layout.
          seed: code.codeUnits.fold(0, (a, b) => a + b) % 3,
        ),
      ),
    ),
  );
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter({
    required this.motif,
    required this.accent,
    required this.seed,
  });
  final _Motif motif;
  final Color accent;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(s * 0.28),
    );
    canvas.drawRRect(r, Paint()..color = accent.withValues(alpha: 0.12));
    canvas.save();
    canvas.clipRRect(r);
    final ink = Paint()..color = accent;
    final line = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round;
    final c = Offset(s / 2, s / 2);
    final n = 3 + seed;
    switch (motif) {
      case _Motif.indigoDots:
        for (var i = 0; i < 3; i++) {
          for (var j = 0; j < 3; j++) {
            canvas.drawCircle(
              Offset(s * (0.25 + i * 0.25), s * (0.25 + j * 0.25)),
              s * ((i + j).isEven ? 0.08 : 0.045),
              ink,
            );
          }
        }
      case _Motif.weave:
        for (var i = 1; i < 4; i++) {
          canvas.drawLine(
            Offset(s * i / 4, s * 0.15),
            Offset(s * i / 4, s * 0.85),
            line,
          );
        }
        canvas.drawLine(Offset(s * 0.15, c.dy), Offset(s * 0.85, c.dy), line);
      case _Motif.uliSpiral:
        final p = Path()..moveTo(c.dx, c.dy);
        for (double t = 0; t < 4 * math.pi; t += 0.2) {
          final rr = s * 0.03 * t;
          p.lineTo(c.dx + rr * math.cos(t), c.dy + rr * math.sin(t));
        }
        canvas.drawPath(p, line..strokeWidth = s * 0.05);
      case _Motif.checker:
        final q = s / 4;
        for (var i = 0; i < 4; i++) {
          for (var j = 0; j < 4; j++) {
            if ((i + j).isEven) {
              canvas.drawRect(
                Rect.fromLTWH(i * q, j * q, q, q).deflate(q * 0.12),
                ink,
              );
            }
          }
        }
      case _Motif.waves:
        for (var k = 0; k < n - 1; k++) {
          final y = s * (0.3 + k * 0.2);
          final p = Path()..moveTo(0, y);
          for (double x = 0; x <= s; x += s / 8) {
            p.lineTo(x, y + ((x / (s / 8)).round().isEven ? -1 : 1) * s * 0.06);
          }
          canvas.drawPath(p, line..strokeWidth = s * 0.05);
        }
      case _Motif.ladder:
        canvas.drawLine(
          Offset(s * 0.3, s * 0.15),
          Offset(s * 0.3, s * 0.85),
          line,
        );
        canvas.drawLine(
          Offset(s * 0.7, s * 0.15),
          Offset(s * 0.7, s * 0.85),
          line,
        );
        for (var k = 0; k < 4; k++) {
          final y = s * (0.25 + k * 0.17);
          canvas.drawLine(Offset(s * 0.3, y), Offset(s * 0.7, y), line);
        }
      case _Motif.beadRings:
        for (var k = 0; k < 3; k++) {
          canvas.drawCircle(
            c,
            s * (0.12 + k * 0.12),
            line..strokeWidth = s * 0.06,
          );
        }
        canvas.drawCircle(c, s * 0.05, ink);
      case _Motif.chevrons:
        for (var k = 0; k < n; k++) {
          final y = s * (0.25 + k * 0.5 / n);
          canvas.drawPath(
            Path()
              ..moveTo(s * 0.2, y + s * 0.12)
              ..lineTo(c.dx, y)
              ..lineTo(s * 0.8, y + s * 0.12),
            line,
          );
        }
      case _Motif.triangles:
        for (var k = 0; k < 3; k++) {
          final x = s * (0.2 + k * 0.3);
          canvas.drawPath(
            Path()
              ..moveTo(x - s * 0.12, s * 0.7)
              ..lineTo(x, s * 0.35)
              ..lineTo(x + s * 0.12, s * 0.7)
              ..close(),
            ink,
          );
        }
      case _Motif.star:
        final p = Path();
        final pts = 8 - seed;
        for (var k = 0; k < pts * 2; k++) {
          final rr = k.isEven ? s * 0.34 : s * 0.16;
          final a = k * math.pi / pts - math.pi / 2;
          final o = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
          k == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(p..close(), ink);
    }
    canvas.restore();
    canvas.drawRRect(
      r.deflate(0.75),
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_EmblemPainter o) =>
      o.motif != motif || o.accent != accent || o.seed != seed;
}

/// Sign-in's LingAfriq moment: Polie greets in the chosen language over a
/// woven strip. Save progress shows the word basket instead, so the two
/// screens never repeat each other.
class _SignInHero extends StatelessWidget {
  const _SignInHero({this.code});
  final String? code;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(code);
    final greeting = _greetings[code] ?? 'Ẹ kú àbọ̀';
    return Column(
      key: const ValueKey('signin-hero'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WovenStrip(color: accent),
        SizedBox(height: ModernGriotSpacing.sm.h),
        Row(
          children: [
            Image.asset(
              'assets/images/cast_still_PaLingAfriq.png',
              height: 96,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => const SizedBox(width: 72, height: 96),
            ),
            SizedBox(width: ModernGriotSpacing.sm.w),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(ModernGriotSpacing.sm.w),
                decoration: BoxDecoration(
                  color: ModernGriotColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
                  border: Border.all(color: accent, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bidi(context, greeting),
                      style: ModernGriotTypography.titleLarge(
                        context: context,
                        color: ModernGriotColors.onSurface,
                      ),
                    ),
                    Text(
                      _bidi(
                        context,
                        'Polie is keeping your seat in the village.',
                      ),
                      style: ModernGriotTypography.bodyMedium(
                        context: context,
                        color: _captionInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Save progress's LingAfriq moment: the first-win basket in the chosen
/// language's emblem and colour.
class _WordBasket extends StatelessWidget {
  const _WordBasket({required this.code, required this.words});
  final String? code;
  final int words;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(code);
    return Semantics(
      container: true,
      child: Container(
        key: const ValueKey('save-basket'),
        padding: EdgeInsets.all(ModernGriotSpacing.sm.w),
        decoration: BoxDecoration(
          color: ModernGriotColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
          border: Border.all(color: ModernGriotColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (code != null) _LanguageEmblem(code: code!, size: 40),
                SizedBox(width: ModernGriotSpacing.sm.w),
                Expanded(
                  child: Text(
                    _tr(
                      context,
                      words == 1
                          ? '1 word in your basket'
                          : '$words words in your basket',
                      words == 1
                          ? 'كلمة واحدة في سلّتك'
                          : '$words كلمات في سلّتك',
                    ),
                    style: ModernGriotTypography.titleSmall(
                      context: context,
                      color: ModernGriotColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ModernGriotSpacing.xs.h),
            _WovenStrip(color: accent),
          ],
        ),
      ),
    );
  }
}

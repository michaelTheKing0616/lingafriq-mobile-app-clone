part of '../unified_onboarding_screen.dart';

/// LingAfriq identity: original code-drawn motifs, per-language greetings and
/// regional accents. No third-party pattern or brand asset is used.

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
    _accents[code] ?? ModernGriotColors.brandCoral;

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
      child: CustomPaint(painter: _WovenStripPainter(color)),
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

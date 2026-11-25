import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Today error copy from the deck. The sample golden paints this.
abstract final class LingErrorStateCopy {
  static const String whatHappened = 'The plan did not open.';
  static const String why = 'The lesson list did not come back.';
  static const String whatToDo = 'Try again.';
  static const String actionLabel = 'Try again';
}

/// Painted cue on an error or offline disc.
enum LingCueKind { cross, info }

/// Danger or info disc. The mark is a shape, so the cue is not colour alone.
class LingCueDisc extends StatelessWidget {
  const LingCueDisc({
    required this.fill,
    required this.mark,
    required this.kind,
    super.key,
  });

  final Color fill;
  final Color mark;
  final LingCueKind kind;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: LingAfriqTokens.spacing48,
      height: LingAfriqTokens.spacing48,
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Center(
          child: CustomPaint(
            size: const Size.square(LingAfriqTokens.spacing24),
            painter: _CuePainter(mark, kind),
          ),
        ),
      ),
    );
  }
}

class _CuePainter extends CustomPainter {
  const _CuePainter(this.color, this.kind);

  final Color color;
  final LingCueKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = LingAfriqTokens.strokeregular
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final double w = size.width;
    final double h = size.height;
    switch (kind) {
      case LingCueKind.cross:
        canvas.drawLine(
          Offset(w * 0.22, h * 0.22),
          Offset(w * 0.78, h * 0.78),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.78, h * 0.22),
          Offset(w * 0.22, h * 0.78),
          paint,
        );
      case LingCueKind.info:
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.38, paint);
        canvas.drawLine(
          Offset(w * 0.5, h * 0.42),
          Offset(w * 0.5, h * 0.72),
          paint,
        );
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.28),
          LingAfriqTokens.strokehairline,
          Paint()..color = color,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CuePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.kind != kind;
  }
}

/// Error anatomy. What happened, why, and what to do are required.
/// Omitting any of them, or the action, is a compile error.
class LingErrorState extends StatelessWidget {
  const LingErrorState({
    required this.whatHappened,
    required this.why,
    required this.whatToDo,
    required this.actionLabel,
    required this.onAction,
    this.unavailableLabel = 'Unavailable',
    super.key,
  });

  final String whatHappened;
  final String why;
  final String whatToDo;
  final String actionLabel;
  final VoidCallback onAction;
  final String unavailableLabel;

  static Color dangerFill(Brightness brightness) {
    return brightness == Brightness.dark
        ? LingAfriqTokens.roleDarkDanger
        : LingAfriqTokens.roleLightDanger;
  }

  static Color dangerMark(Brightness brightness) {
    return brightness == Brightness.dark
        ? LingAfriqTokens.roleDarkOnDanger
        : LingAfriqTokens.roleLightOnDanger;
  }

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final Brightness brightness = Theme.of(context).brightness;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ExcludeSemantics(
            child: LingCueDisc(
              key: const ValueKey<String>('ling-error-disc'),
              fill: dangerFill(brightness),
              mark: dangerMark(brightness),
              kind: LingCueKind.cross,
            ),
          ),
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _line(whatHappened, lingBody(palette.onSurface)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _line(why, lingBody(palette.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        _line(whatToDo, lingBody(palette.onSurfaceVariant)),
        const SizedBox(height: LingAfriqTokens.spacing16),
        LingButton(
          label: actionLabel,
          unavailableLabel: unavailableLabel,
          onPressed: onAction,
          role: LingButtonRole.accent,
        ),
      ],
    );
  }

  Widget _line(String text, TextStyle style) {
    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: Text(
          text,
          style: style,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}

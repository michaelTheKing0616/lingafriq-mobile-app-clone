import 'package:flutter/material.dart';
import 'package:lingafriq/design/icons/lingafriq_icons.dart';
import 'package:lingafriq/design/text/target_text.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/tone_lens/tone_contour.dart';
import 'package:lingafriq/design/tone_lens/tone_lens.dart';

/// Icons that point along the reading direction.
///
/// A back chevron is directional. Right-to-left layout mirrors it so it
/// still points back.
enum LingDirectionalIcon { backChevron }

/// Directional icons. These mirror.
const List<LingDirectionalIcon> lingDirectionalIcons = <LingDirectionalIcon>[
  LingDirectionalIcon.backChevron,
];

/// Icons that do not point. Search, check, and warning stay as drawn.
const List<LingIconName> lingNonDirectionalIcons = <LingIconName>[
  LingIconName.search,
  LingIconName.check,
  LingIconName.warning,
];

/// Ajami letters named in the type spec. They read right to left.
const String lingAjamiLetters = '\u067B\u06A2\u06A7\u06BD\u06CB';

/// True when [locale] is Arabic, or written in the Arabic script.
///
/// Hausa Ajami uses that script (`ha` with script `Arab`).
bool lingLocaleReadsRtl(Locale? locale) {
  if (locale == null) return false;
  if (locale.languageCode.toLowerCase() == 'ar') return true;
  final String script = locale.scriptCode?.toLowerCase() ?? '';
  return script == 'arab';
}

/// True when [text] contains Arabic script or an Ajami letter.
bool lingTargetReadsRtl(String text) {
  for (final int rune in text.runes) {
    if (lingAjamiLetters.runes.contains(rune)) return true;
    if (_arabicBlock(rune)) return true;
  }
  return false;
}

bool _arabicBlock(int rune) {
  return _between(rune, '\u0600', '\u06FF') ||
      _between(rune, '\u0750', '\u077F') ||
      _between(rune, '\u08A0', '\u08FF');
}

bool _between(int rune, String start, String end) {
  return rune >= start.runes.single && rune <= end.runes.single;
}

bool _mirrorDirectional(LingDirectionalIcon icon, TextDirection direction) {
  return direction == TextDirection.rtl && lingDirectionalIcons.contains(icon);
}

bool _mirrorFixed(LingIconName name, TextDirection direction) {
  if (direction != TextDirection.rtl) return false;
  return !lingNonDirectionalIcons.contains(name);
}

/// Sets [Directionality] to right to left for Arabic and for Ajami target text.
///
/// Other locales and Latin samples stay left to right.
class LingRtlScope extends StatelessWidget {
  const LingRtlScope({
    this.locale,
    this.targetText,
    required this.child,
    super.key,
  });

  final Locale? locale;

  /// Target-language sample. Arabic script and Ajami read right to left.
  final String? targetText;

  final Widget child;

  static TextDirection directionFor({Locale? locale, String? targetText}) {
    if (lingLocaleReadsRtl(locale)) return TextDirection.rtl;
    if (targetText != null && lingTargetReadsRtl(targetText)) {
      return TextDirection.rtl;
    }
    return TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: directionFor(locale: locale, targetText: targetText),
      child: child,
    );
  }
}

/// A row of tabs in reading order.
///
/// The first label is the start of the row. In right-to-left layout the
/// row reverses, so the first label sits at the right and tab order follows.
/// Large text wraps onto the next line so a label is not clipped.
class LingTabRow extends StatelessWidget {
  const LingTabRow({required this.labels, super.key});

  final List<String> labels;

  static const Key rowKey = Key('ling-rtl-tabs');

  static Key tabKey(String label) => ValueKey<String>(label);

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final List<String> ordered = rtl
        ? labels.reversed.toList(growable: false)
        : labels;
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Wrap(
        key: rowKey,
        textDirection: TextDirection.ltr,
        children: <Widget>[
          for (var index = 0; index < ordered.length; index++)
            FocusTraversalOrder(
              order: NumericFocusOrder(index.toDouble()),
              child: _Tab(label: ordered[index]),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  _Tab({required this.label}) : super(key: ValueKey<String>(label));

  final String label;

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Semantics(
        button: true,
        label: label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: LingAfriqTokens.spacing48,
            minHeight: LingAfriqTokens.spacing48,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingAfriqTokens.spacing8,
            ),
            child: Text(label, softWrap: true, overflow: TextOverflow.visible),
          ),
        ),
      ),
    );
  }
}

/// Tone Lens for a target-language sample.
///
/// An Arabic or Ajami sample flows right to left, and its contour box is
/// mirrored from left to right into right to left. A Latin sample stays
/// left to right. The mirror is layout. It does not animate.
class LingRtlToneLens extends StatelessWidget {
  const LingRtlToneLens({
    required this.word,
    required this.contours,
    required this.source,
    this.unverified = false,
    super.key,
  });

  static const Key contourKey = Key('ling-rtl-contour-box');

  final String word;
  final List<ToneContourKind> contours;
  final ToneSource source;
  final bool unverified;

  @override
  Widget build(BuildContext context) {
    final bool rtl = lingTargetReadsRtl(word);
    final Brightness brightness = Theme.of(context).brightness;
    final _Ink ink = _Ink.of(brightness);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: toneLensLabel(
        word: word,
        contours: contours,
        unverified: unverified,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ink.container,
          borderRadius: const BorderRadius.all(
            Radius.circular(LingAfriqTokens.radiusmd),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ContourBox(
                color: ink.ink,
                background: ink.container,
                kinds: contours,
                unverified: unverified,
                mirror: rtl,
              ),
              const SizedBox(height: LingAfriqTokens.spacing4),
              Directionality(
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                child: DefaultTextStyle(
                  style: TextStyle(color: ink.ink),
                  child: TargetText(text: word),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ink {
  const _Ink({required this.container, required this.ink});

  final Color container;
  final Color ink;

  static _Ink of(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const _Ink(
        container: LingAfriqTokens.roleDarkSurfaceContainer,
        ink: LingAfriqTokens.roleDarkOnSurface,
      );
    }
    return const _Ink(
      container: LingAfriqTokens.roleLightSurfaceContainer,
      ink: LingAfriqTokens.roleLightOnSurface,
    );
  }
}

class _ContourBox extends StatelessWidget {
  const _ContourBox({
    required this.color,
    required this.background,
    required this.kinds,
    required this.mirror,
    required this.unverified,
  });

  final Color color;
  final Color background;
  final List<ToneContourKind> kinds;
  final bool mirror;
  final bool unverified;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: LingRtlToneLens.contourKey,
      child: ColoredBox(
        color: background,
        child: SizedBox(
          height: LingAfriqTokens.spacing48,
          width: double.infinity,
          child: CustomPaint(
            painter: _MirroredContourPainter(
              color: color,
              kinds: kinds,
              unverified: unverified,
              mirror: mirror,
            ),
          ),
        ),
      ),
    );
  }
}

class _MirroredContourPainter extends CustomPainter {
  _MirroredContourPainter({
    required Color color,
    required List<ToneContourKind> kinds,
    required bool unverified,
    required this.mirror,
  }) : _delegate = ToneContourPainter(
         color: color,
         kinds: kinds,
         unverified: unverified,
       );

  final ToneContourPainter _delegate;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    if (!mirror) {
      _delegate.paint(canvas, size);
      return;
    }
    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    _delegate.paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MirroredContourPainter oldDelegate) {
    return mirror != oldDelegate.mirror ||
        _delegate.shouldRepaint(oldDelegate._delegate);
  }
}

/// A drawn mark that does not point.
///
/// Search, check, and warning keep the same painting in both directions.
class LingRtlFixedIcon extends StatelessWidget {
  const LingRtlFixedIcon({
    required this.name,
    required this.color,
    required this.accent,
    super.key,
  });

  final LingIconName name;
  final Color color;
  final Color accent;

  static Key paintKey(LingIconName name) {
    return ValueKey<String>('ling-rtl-fixed-${name.name}');
  }

  @override
  Widget build(BuildContext context) {
    final bool mirror = _mirrorFixed(name, Directionality.of(context));
    Widget mark = LingIcon(name: name, color: color, accent: accent);
    if (mirror) {
      mark = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1, 1, 1),
        filterQuality: FilterQuality.none,
        child: mark,
      );
    }
    return RepaintBoundary(key: paintKey(name), child: mark);
  }
}

/// Back chevron. It points to the start edge, so right-to-left layout mirrors it.
class LingRtlBackChevron extends StatelessWidget {
  const LingRtlBackChevron({
    required this.color,
    required this.background,
    required this.semanticsLabel,
    super.key,
  });

  static const Key paintKey = Key('ling-rtl-back-chevron');

  final Color color;
  final Color background;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final bool mirror = _mirrorDirectional(
      LingDirectionalIcon.backChevron,
      Directionality.of(context),
    );
    return Semantics(
      container: true,
      button: true,
      label: semanticsLabel,
      child: RepaintBoundary(
        key: paintKey,
        child: ColoredBox(
          color: background,
          child: SizedBox(
            width: LingAfriqTokens.spacing24,
            height: LingAfriqTokens.spacing24,
            child: CustomPaint(
              painter: _BackChevronPainter(color: color, mirror: mirror),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackChevronPainter extends CustomPainter {
  const _BackChevronPainter({required this.color, required this.mirror});

  final Color color;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    if (mirror) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.scale(
      size.width / LingAfriqTokens.spacing24,
      size.height / LingAfriqTokens.spacing24,
    );
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = LingAfriqTokens.strokeregular
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final Path path = Path()
      ..moveTo(15, 6)
      ..lineTo(8, 12)
      ..lineTo(15, 18);
    canvas.drawPath(path, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BackChevronPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.mirror != mirror;
  }
}

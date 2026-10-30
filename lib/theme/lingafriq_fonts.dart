import 'package:flutter/material.dart';

/// LingAfriq type system (docs/design/references/typography/SPEC.md).
///
/// Display: Nunito 700/800/900 (headlines, titles, buttons).
/// Text: Noto Sans 400/500/600/700 (body, helpers, labels).
/// Arabic / Ajami: Noto Sans Arabic 400/700.
/// All bundled under assets/fonts/lingafriq/ (SIL OFL 1.1); nothing is fetched at runtime.
abstract final class LingAfriqFonts {
  static const display = 'LingAfriqDisplay';
  static const text = 'LingAfriqText';
  static const arabic = 'LingAfriqArabic';

  /// Fallback chain for display styles (Nunito lacks ɛ ɔ ƙ ɖ … which Noto Sans has).
  static const fallback = <String>[
    'LingAfriqText',
    'LingAfriqArabic',
    'NotoSansEthiopic',
    'NotoSansTifinagh',
    'NotoSansNKo',
    'NotoSansVai',
    'NotoSansAdlam',
    'NotoSansOsmanya',
    'NotoSansBamum',
  ];

  /// Fallback chain for body styles (the body face is already Noto Sans).
  static final textFallback = fallback
      .where((f) => f != text)
      .toList(growable: false);

  /// Headlines scale up to 160%, body text up to 200%.
  static const headlineMaxScale = 1.6;
  static const bodyMaxScale = 2.0;

  /// Minimum body line-height: room for stacked tone marks (ọ̀, ẹ́).
  static const bodyMinHeight = 1.45;

  static const markSafeHeight = TextHeightBehavior(
    applyHeightToFirstAscent: true,
  );

  /// Nunito ships in 700/800/900 only; lighter requests map to 700.
  static FontWeight _displayWeight(FontWeight? w) {
    final v = (w ?? FontWeight.w800).value;
    if (v <= 700) return FontWeight.w700;
    if (v <= 800) return FontWeight.w800;
    return FontWeight.w900;
  }

  static TextStyle displayStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? wordSpacing,
    List<Shadow>? shadows,
    Color? backgroundColor,
    TextBaseline? textBaseline,
    Paint? foreground,
  }) => TextStyle(
    fontFamily: display,
    fontFamilyFallback: fallback,
    fontSize: fontSize,
    fontWeight: _displayWeight(fontWeight),
    color: foreground == null ? color : null,
    // Never below 1.1: target-language words carry marks above and below.
    height: height == null ? null : (height < 1.1 ? 1.1 : height),
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
    decorationColor: decorationColor,
    wordSpacing: wordSpacing,
    shadows: shadows,
    backgroundColor: backgroundColor,
    textBaseline: textBaseline,
    foreground: foreground,
  );

  static TextStyle textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? wordSpacing,
    List<Shadow>? shadows,
    Color? backgroundColor,
    TextBaseline? textBaseline,
    Paint? foreground,
  }) => TextStyle(
    fontFamily: text,
    fontFamilyFallback: textFallback,
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    color: foreground == null ? color : null,
    height: height == null ? null : (height < 1.1 ? 1.1 : height),
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
    decorationColor: decorationColor,
    wordSpacing: wordSpacing,
    shadows: shadows,
    backgroundColor: backgroundColor,
    textBaseline: textBaseline,
    foreground: foreground,
  );

  /// For call sites migrated from a single family: bold (700+) text uses the
  /// display face, lighter text uses the body face.
  static TextStyle roleStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    double? wordSpacing,
    List<Shadow>? shadows,
    Color? backgroundColor,
    TextBaseline? textBaseline,
    Paint? foreground,
  }) {
    final bold = (fontWeight?.value ?? 400) >= 700;
    final f = bold ? displayStyle : textStyle;
    return f(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      wordSpacing: wordSpacing,
      shadows: shadows,
      backgroundColor: backgroundColor,
      textBaseline: textBaseline,
      foreground: foreground,
    );
  }

  /// The SPEC.md TextTheme scale.
  static TextTheme textTheme({Color? color}) => TextTheme(
    displayLarge: displayStyle(
      fontSize: 48,
      fontWeight: FontWeight.w900,
      height: 1.1,
      letterSpacing: -0.5,
      color: color,
    ),
    displayMedium: displayStyle(
      fontSize: 40,
      fontWeight: FontWeight.w900,
      height: 1.1,
      letterSpacing: -0.5,
      color: color,
    ),
    displaySmall: displayStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.4,
      color: color,
    ),
    headlineLarge: displayStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.3,
      color: color,
    ),
    headlineMedium: displayStyle(
      fontSize: 25,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -0.2,
      color: color,
    ),
    headlineSmall: displayStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      height: 1.25,
      letterSpacing: -0.2,
      color: color,
    ),
    titleLarge: displayStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      height: 1.25,
      color: color,
    ),
    titleMedium: displayStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      height: 1.25,
      color: color,
    ),
    titleSmall: displayStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: color,
    ),
    labelLarge: displayStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: 0.3,
      color: color,
    ),
    labelMedium: textStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.2,
      color: color,
    ),
    labelSmall: textStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.2,
      color: color,
    ),
    bodyLarge: textStyle(fontSize: 17, height: 1.5, color: color),
    bodyMedium: textStyle(fontSize: 15, height: bodyMinHeight, color: color),
    bodySmall: textStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.45,
      letterSpacing: 0.1,
      color: color,
    ),
  );

  /// Clamp for headline text: `MediaQuery.textScalerOf(context)` capped at 160%.
  static TextScaler headlineScaler(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: headlineMaxScale);
}

/// A headline that follows the user's text size up to 160%.
class LingAfriqHeadline extends StatelessWidget {
  const LingAfriqHeadline(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
    data,
    style: style,
    maxLines: maxLines,
    overflow: overflow,
    textAlign: textAlign,
    textScaler: LingAfriqFonts.headlineScaler(context),
    textHeightBehavior: LingAfriqFonts.markSafeHeight,
  );
}

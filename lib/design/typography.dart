import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:lingafriq/design/a11y/reading_option.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// Approved type roles (ADR-012). Target-language text is Andika at 18sp
/// with leading 1.5. Scripts Andika does not cover use the bundled Noto faces.
abstract final class LingAfriqType {
  static const String glyphProof =
      'Ẹ kú àárọ̀ · Ọ̀ ṣun · Ị́ bịa · ɓaƙo ɗan ƴaƴa · Ɛyɛ · ŋ ɲ ɔ̃ · ሰላም · ߒߞߏ · ⵜⴰⵎⴰⵣⵉⵖⵜ';

  static const String targetRole = 'target-language';
  static const String displayRole = 'display';
  static const String bodyRole = 'body';
  static const String targetToken = 'type.target';
  static const String displayToken = 'type.display';
  static const String bodyToken = 'type.body';

  static const String targetFamily = 'Andika';
  static const String displayFamily = 'LingAfriqDisplay';
  static const String bodyFamily = 'LingAfriqText';

  static const List<String> scriptFallback = [
    'LingAfriqText',
    'NotoSansEthiopic',
    'NotoSansNKo',
    'NotoSansTifinagh',
    'NotoSansAdlam',
  ];

  static const double targetSize = 18;
  static const double bodySize = 16;
  static const double targetHeight = 1.5;

  static const TextStyle target = TextStyle(
    fontFamily: targetFamily,
    fontFamilyFallback: scriptFallback,
    fontSize: targetSize,
    height: targetHeight,
  );

  /// UI text. Off, this is the body face. On, it uses Andika and the wider
  /// spacing derived from the 4-point token.
  static TextStyle ui(ReadingOptionController option) {
    return _friendly(
      const TextStyle(fontFamily: bodyFamily, fontSize: bodySize, height: targetHeight),
      option,
    );
  }

  static TextStyle targetNow(ReadingOptionController option) {
    return _friendly(target, option);
  }

  static TextStyle _friendly(TextStyle style, ReadingOptionController option) {
    if (!option.enabled) return style;
    final tracking = LingAfriqTokens.spacing4 / 16;
    return style.copyWith(
      fontFamily: targetFamily,
      fontFamilyFallback: scriptFallback,
      letterSpacing: tracking,
      wordSpacing: LingAfriqTokens.spacing4 / 8,
      height: math.max(style.height ?? targetHeight, targetHeight),
    );
  }
}

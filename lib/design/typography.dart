import 'package:flutter/widgets.dart';

/// Approved type roles (ADR-012). Target-language text is Andika at 18sp
/// with leading 1.5. Scripts Andika does not cover use the bundled Noto faces.
abstract final class LingAfriqType {
  static const String glyphProof =
      'Ẹ kú àárọ̀ · Ọ̀ ṣun · Ị́ bịa · ɓaƙo ɗan ƴaƴa · Ɛyɛ · ŋ ɲ ɔ̃ · ሰላም · ߒߞߏ · ⵜⴰⵎⴰⵣⵉⵖⵜ';

  static const String targetRole = 'target-language';
  static const String displayRole = 'display';
  static const String bodyRole = 'body';

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
  static const double targetHeight = 1.5;

  static const TextStyle target = TextStyle(
    fontFamily: targetFamily,
    fontFamilyFallback: scriptFallback,
    fontSize: targetSize,
    height: targetHeight,
  );
}

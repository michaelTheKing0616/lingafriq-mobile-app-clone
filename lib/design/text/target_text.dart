import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/design/word_card/word_card.dart'
    deferred as word_card;
import 'package:lingafriq/services/word_card_service.dart';

/// Target-language text. Andika at 18sp, leading 1.5, with the Noto script
/// fallbacks from [LingAfriqType.target]. The line box uses that leading so
/// stacked tone marks stay inside the glyph's box at large text scale.
///
/// A long-press opens the word card. A plain [Text] has no card. Inside
/// [TargetWordCardGate] the press does nothing, so the card does not open
/// another card.
class TargetText extends StatelessWidget {
  const TargetText({
    required this.text,
    this.textAlign,
    this.maxLines,
    this.softWrap = true,
    this.semanticsLabel,
    this.host = WordCardHost.lesson,
    this.languageCode,
    this.dialect,
    this.wordCardService,
    this.openWordCard = true,
    super.key,
  });

  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool softWrap;

  /// Screen-reader label. When null, the text itself is the label.
  final String? semanticsLabel;

  /// Lesson, chat, game, persona, or dictionary. Passed to the card.
  final WordCardHost host;

  final String? languageCode;
  final String? dialect;
  final WordCardService? wordCardService;

  /// When false, a long-press does not open the card.
  final bool openWordCard;

  static const TextHeightBehavior heightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const StrutStyle strut = StrutStyle(
    fontFamily: LingAfriqType.targetFamily,
    fontFamilyFallback: LingAfriqType.scriptFallback,
    fontSize: LingAfriqType.targetSize,
    height: LingAfriqType.targetHeight,
    forceStrutHeight: true,
    leadingDistribution: TextLeadingDistribution.even,
  );

  Future<void> _open(BuildContext context) async {
    try {
      await word_card.loadLibrary();
    } on Object {
      return;
    }
    if (!context.mounted) return;
    if (Navigator.maybeOf(context) == null) return;
    await word_card.WordCard.show(
      context,
      query: WordCardQuery(
        word: text,
        host: host,
        languageCode: languageCode,
        dialect: dialect,
      ),
      service: wordCardService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color? color = DefaultTextStyle.of(context).style.color;
    final Text label = Text(
      text,
      style: LingAfriqType.target.copyWith(
        color: color,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      softWrap: softWrap,
      overflow: TextOverflow.visible,
      textHeightBehavior: heightBehavior,
      strutStyle: strut,
      semanticsLabel: semanticsLabel,
    );
    final bool opens = openWordCard && !TargetWordCardGate.blocks(context);
    if (!opens) return label;
    return MergeSemantics(
      child: Semantics(
        onLongPress: () {
          unawaited(_open(context));
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          excludeFromSemantics: true,
          onLongPress: () {
            unawaited(_open(context));
          },
          child: label,
        ),
      ),
    );
  }
}

/// Marks a word card so the target word inside it does not open another card.
class TargetWordCardGate extends InheritedWidget {
  const TargetWordCardGate({required super.child, super.key});

  static bool blocks(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TargetWordCardGate>() !=
        null;
  }

  @override
  bool updateShouldNotify(TargetWordCardGate oldWidget) => false;
}

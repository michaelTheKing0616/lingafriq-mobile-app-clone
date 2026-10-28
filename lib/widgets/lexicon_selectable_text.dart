import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';
import 'package:lingafriq/widgets/word_card_sheet.dart';

const String kLexiconWordCardSemanticsAction = 'Open Word Card';
const double kLexiconWordMinTouch = 48;

typedef LexiconWordCardLookup = Future<LexiconLookupResult> Function(String word);
typedef LexiconSuggestHandler = void Function(String surface);

Future<void> showLexiconNotFoundSheet(
  BuildContext context, {
  required String surface,
  LexiconSuggestHandler? onSuggest,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                kWordCardNotFoundCopyKey,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(surface, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (onSuggest != null)
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onSuggest(surface);
                  },
                  child: const Text(kWordCardSuggestCopyKey),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showLexiconOfflineMissingSheet(
  BuildContext context, {
  required String surface,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(kWordCardOfflineMissingCopyKey),
              const SizedBox(height: 8),
              Text(surface, style: Theme.of(ctx).textTheme.titleLarge),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> openWordCardForSurface(
  BuildContext context, {
  required String surface,
  required LexiconWordCardLookup lookup,
  LexiconSuggestHandler? onSuggest,
}) async {
  final result = await lookup(surface);
  if (!context.mounted) return;
  switch (result.kind) {
    case LexiconLookupKind.hit:
      final lexeme = result.lexeme;
      if (lexeme == null) {
        await showLexiconNotFoundSheet(context, surface: surface, onSuggest: onSuggest);
        return;
      }
      await showWordCardSheet(context, lexeme: lexeme);
    case LexiconLookupKind.offlineMissing:
      await showLexiconOfflineMissingSheet(context, surface: surface);
    case LexiconLookupKind.notFound:
      await showLexiconNotFoundSheet(context, surface: surface, onSuggest: onSuggest);
  }
}

class LexiconSelectableText extends StatelessWidget {
  const LexiconSelectableText({
    super.key,
    required this.text,
    required this.languageCode,
    this.style,
    this.textAlign,
    this.lookup,
    this.onSuggest,
    this.lookupService,
  });

  final String text;
  final String languageCode;
  final TextStyle? style;
  final TextAlign? textAlign;
  final LexiconWordCardLookup? lookup;
  final LexiconSuggestHandler? onSuggest;
  final LexiconLookupService? lookupService;

  Future<LexiconLookupResult> _resolveLookup(String word) {
    final handler = lookup;
    if (handler != null) return handler(word);
    final service = lookupService ??
        LexiconLookupService(languageCode: languageCode);
    return service.lookupSurface(word);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _tokenize(text);
    final defaultStyle = style ?? DefaultTextStyle.of(context).style;
    final align = textAlign ?? TextAlign.start;

    return Wrap(
      alignment: _wrapAlignment(align),
      children: [
        for (final token in tokens)
          if (token.isWhitespace)
            Text(token.text, style: defaultStyle)
          else
            _LexiconWordTapTarget(
              word: token.text,
              style: defaultStyle,
              onOpen: () => openWordCardForSurface(
                context,
                surface: token.text,
                lookup: _resolveLookup,
                onSuggest: onSuggest,
              ),
            ),
      ],
    );
  }

  static WrapAlignment _wrapAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return WrapAlignment.center;
      case TextAlign.end:
      case TextAlign.right:
        return WrapAlignment.end;
      default:
        return WrapAlignment.start;
    }
  }
}

class _LexiconWordToken {
  _LexiconWordToken(this.text, {required this.isWhitespace});
  final String text;
  final bool isWhitespace;
}

List<_LexiconWordToken> _tokenize(String source) {
  final out = <_LexiconWordToken>[];
  final pattern = RegExp(r'(\s+|[^\s]+)');
  for (final match in pattern.allMatches(source)) {
    final chunk = match.group(0) ?? '';
    if (chunk.trim().isEmpty) {
      out.add(_LexiconWordToken(chunk, isWhitespace: true));
      continue;
    }
    var wordEnd = chunk.length;
    while (wordEnd > 0 && _isTrailingPunctuation(chunk[wordEnd - 1])) {
      wordEnd--;
    }
    if (wordEnd <= 0) {
      out.add(_LexiconWordToken(chunk, isWhitespace: false));
      continue;
    }
    final word = chunk.substring(0, wordEnd);
    final punct = chunk.substring(wordEnd);
    out.add(_LexiconWordToken(word, isWhitespace: false));
    if (punct.isNotEmpty) {
      out.add(_LexiconWordToken(punct, isWhitespace: true));
    }
  }
  if (out.isEmpty && source.isNotEmpty) {
    out.add(_LexiconWordToken(source, isWhitespace: false));
  }
  return out;
}

bool _isTrailingPunctuation(String char) {
  return RegExp(r'[.,!?;:"()\[\]{}]').hasMatch(char);
}

class _LexiconWordTapTarget extends StatelessWidget {
  const _LexiconWordTapTarget({
    required this.word,
    required this.style,
    required this.onOpen,
  });

  final String word;
  final TextStyle style;
  final Future<void> Function() onOpen;

  static final CustomSemanticsAction _openWordCardAction =
      const CustomSemanticsAction(label: kLexiconWordCardSemanticsAction);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: word,
      button: true,
      customSemanticsActions: {
        _openWordCardAction: () {
          onOpen();
        },
      },
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onLongPress: onOpen,
          borderRadius: BorderRadius.circular(4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kLexiconWordMinTouch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 10),
              child: Text(word, style: style),
            ),
          ),
        ),
      ),
    );
  }
}

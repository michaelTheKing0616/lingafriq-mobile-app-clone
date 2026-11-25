import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/lexicon_selectable_text.dart';

/// Chat bubble with long-press Word Card lookup (P7-923).
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.messageText,
    required this.languageCode,
    this.isOutgoing = false,
    this.lookup,
    this.onSuggest,
  });

  final String messageText;
  final String languageCode;
  final bool isOutgoing;
  final LexiconWordCardLookup? lookup;
  final LexiconSuggestHandler? onSuggest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isOutgoing
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isOutgoing
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: LexiconSelectableText(
            text: messageText,
            languageCode: languageCode,
            style: theme.textTheme.bodyLarge?.copyWith(color: fg),
            lookup: lookup,
            onSuggest: onSuggest,
          ),
        ),
      ),
    );
  }
}

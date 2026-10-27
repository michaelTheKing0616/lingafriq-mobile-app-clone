// P11-018 — Scaffolded Twi opinion builder (surfaces gated until native sign-off).

import 'package:flutter/foundation.dart';

/// copy_keys: quest.builder.hint, quest.builder.submit
abstract final class QuestSentenceBuilderCopy {
  static const hint =
      'Tap tiles in order to argue your council position. Twi tiles unlock after native review.';
  static const submit = 'Speak this position';
  static const lockedTile = 'Twi phrase pending review';
  static const incomplete = 'Fill every slot before you continue.';
}

@immutable
class QuestBuilderToken {
  const QuestBuilderToken({
    required this.id,
    required this.labelEn,
    this.twiSurface,
    this.twiLocked = true,
  });

  final String id;
  final String labelEn;
  final String? twiSurface;
  final bool twiLocked;

  String displayLabel({required bool preferTwi, required bool twiUnlocked}) {
    if (preferTwi && twiUnlocked && twiSurface != null && twiSurface!.isNotEmpty) {
      return twiSurface!;
    }
    return labelEn;
  }
}

@immutable
class QuestSentenceScaffold {
  const QuestSentenceScaffold({
    required this.scaffoldId,
    required this.positionEn,
    required this.slotOrder,
    required this.tokensById,
    required this.requiredTokenIds,
  });

  final String scaffoldId;
  final String positionEn;
  final List<String> slotOrder;
  final Map<String, QuestBuilderToken> tokensById;
  final Set<String> requiredTokenIds;

  int get slotCount => slotOrder.length;

  List<QuestBuilderToken> tokensForPool() =>
      tokensById.values.toList(growable: false);
}

enum QuestBuilderValidation { complete, incomplete, wrongPosition }

QuestBuilderValidation validateScaffoldSelection({
  required QuestSentenceScaffold scaffold,
  required List<String?> filledTokenIds,
}) {
  if (filledTokenIds.length != scaffold.slotCount) {
    return QuestBuilderValidation.incomplete;
  }
  for (final id in filledTokenIds) {
    if (id == null || id.isEmpty) {
      return QuestBuilderValidation.incomplete;
    }
  }
  final chosen = filledTokenIds.map((e) => e!).toSet();
  if (!scaffold.requiredTokenIds.every(chosen.contains)) {
    return QuestBuilderValidation.wrongPosition;
  }
  return QuestBuilderValidation.complete;
}

String previewBuiltSentence({
  required QuestSentenceScaffold scaffold,
  required List<String?> filledTokenIds,
  required bool preferTwi,
  required bool twiUnlocked,
}) {
  final parts = <String>[];
  for (var i = 0; i < scaffold.slotCount; i++) {
    final id = filledTokenIds.elementAtOrNull(i);
    if (id == null) {
      parts.add('…');
      continue;
    }
    final token = scaffold.tokensById[id];
    if (token == null) {
      parts.add('…');
      continue;
    }
    parts.add(token.displayLabel(preferTwi: preferTwi, twiUnlocked: twiUnlocked));
  }
  return parts.join(' ');
}

/// Default defend-sovereignty scaffold (English until Twi surfaces are signed off).
QuestSentenceScaffold kYaaCouncilDefendScaffold = QuestSentenceScaffold(
  scaffoldId: 'defend_stool',
  positionEn: 'Argue that the nation must defend the Golden Stool together.',
  slotOrder: ['we', 'must', 'defend', 'stool', 'together'],
  requiredTokenIds: {'we', 'must', 'defend', 'stool', 'together'},
  tokensById: {
    'we': QuestBuilderToken(id: 'we', labelEn: 'We'),
    'must': QuestBuilderToken(id: 'must', labelEn: 'must'),
    'defend': QuestBuilderToken(id: 'defend', labelEn: 'defend'),
    'stool': QuestBuilderToken(
      id: 'stool',
      labelEn: 'the Golden Stool',
    ),
    'together': QuestBuilderToken(id: 'together', labelEn: 'together'),
    'negotiate': QuestBuilderToken(id: 'negotiate', labelEn: 'negotiate with'),
  },
);

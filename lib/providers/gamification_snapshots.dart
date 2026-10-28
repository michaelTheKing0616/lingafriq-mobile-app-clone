class CircleQuestMemberLabel {
  const CircleQuestMemberLabel({
    required this.slot,
    required this.isViewer,
    this.userId,
  });
  final String slot;
  final bool isViewer;
  final String? userId;
}

class CircleQuestSnapshot {
  const CircleQuestSnapshot({
    required this.empty,
    required this.goalXp,
    required this.progressXp,
    required this.members,
    this.complete = false,
  });

  final bool empty;
  final int goalXp;
  final int progressXp;
  final List<CircleQuestMemberLabel> members;
  final bool complete;

  factory CircleQuestSnapshot.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['members'] as List<dynamic>? ?? [];
    return CircleQuestSnapshot(
      empty: json['empty'] == true,
      goalXp: (json['goalXp'] as num?)?.toInt() ?? 0,
      progressXp: (json['progressXp'] as num?)?.toInt() ?? 0,
      complete: json['complete'] == true,
      members: membersRaw
          .map((e) => CircleQuestMemberLabel(
                slot: (e as Map)['slot']?.toString() ?? 'Learner',
                isViewer: (e)['isViewer'] == true,
                userId: (e)['userId']?.toString(),
              ))
          .toList(),
    );
  }
}

class FamilyPhraseSnapshot {
  const FamilyPhraseSnapshot({
    required this.empty,
    this.phrase = '',
    this.gloss = '',
  });

  final bool empty;
  final String phrase;
  final String gloss;

  factory FamilyPhraseSnapshot.fromJson(Map<String, dynamic> json) {
    return FamilyPhraseSnapshot(
      empty: json['empty'] == true,
      phrase: json['phrase']?.toString() ?? '',
      gloss: json['gloss']?.toString() ?? '',
    );
  }
}

class CowriesShopItem {
  const CowriesShopItem({
    required this.id,
    required this.sink,
    required this.cost,
    required this.title,
    required this.does,
    this.personaId,
    this.chapterId,
  });

  final String id;
  final String sink;
  final int cost;
  final String title;
  final String does;
  final String? personaId;
  final String? chapterId;

  factory CowriesShopItem.fromJson(Map<String, dynamic> json) {
    return CowriesShopItem(
      id: json['id']?.toString() ?? '',
      sink: json['sink']?.toString() ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      does: json['does']?.toString() ?? '',
      personaId: json['persona_id']?.toString(),
      chapterId: json['chapter_id']?.toString(),
    );
  }
}

class CowriesShopPurchaseResult {
  const CowriesShopPurchaseResult({required this.ok, this.message = ''});
  final bool ok;
  final String message;
}

class HeritageTreeSnapshot {
  const HeritageTreeSnapshot({
    required this.canDoCount,
    required this.stage,
    required this.members,
  });

  final int canDoCount;
  final String stage;
  final List<CircleQuestMemberLabel> members;

  factory HeritageTreeSnapshot.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['members'] as List<dynamic>? ?? [];
    return HeritageTreeSnapshot(
      canDoCount: (json['canDoCount'] as num?)?.toInt() ?? 0,
      stage: json['stage']?.toString() ?? 'seed',
      members: membersRaw
          .map((e) => CircleQuestMemberLabel(
                slot: (e as Map)['slot']?.toString() ?? 'Learner',
                isViewer: (e)['isViewer'] == true,
              ))
          .toList(),
    );
  }
}

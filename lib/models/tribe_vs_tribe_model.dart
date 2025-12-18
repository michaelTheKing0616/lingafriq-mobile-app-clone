/// Tribe vs Tribe Event model
class TribeVsTribeEvent {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participatingTribes;
  final Map<String, dynamic>? rewards;

  TribeVsTribeEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.participatingTribes,
    this.rewards,
  });

  bool get isActive =>
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isPast => DateTime.now().isAfter(endDate);
  Duration get timeRemaining => endDate.difference(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'participatingTribes': participatingTribes,
        'rewards': rewards,
      };

  factory TribeVsTribeEvent.fromJson(Map<String, dynamic> json) =>
      TribeVsTribeEvent(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        participatingTribes: (json['participatingTribes'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        rewards: json['rewards'] as Map<String, dynamic>?,
      );
}


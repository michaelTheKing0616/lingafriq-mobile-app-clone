import 'dart:convert';

class ProgressMetrics {
  final int wordsLearned;
  final double listeningHours;
  final double speakingHours;
  final double readingWords;
  final int writtenWords;
  final int knownWords;
  final double timeSpentMinutes;
  final DateTime lastUpdated;
  final Map<String, int> wordsByLanguage; // language -> word count
  final Map<String, double> timeByActivity; // activity -> hours

  ProgressMetrics({
    required this.wordsLearned,
    required this.listeningHours,
    required this.speakingHours,
    required this.readingWords,
    required this.writtenWords,
    required this.knownWords,
    required this.timeSpentMinutes,
    required this.lastUpdated,
    this.wordsByLanguage = const {},
    this.timeByActivity = const {},
  });

  double get timeSpentHours => timeSpentMinutes / 60.0;
  double get totalLearningTime => listeningHours + speakingHours + (timeSpentMinutes / 60.0);

  Map<String, dynamic> toMap() => {
    'wordsLearned': wordsLearned,
    'listeningHours': listeningHours,
    'speakingHours': speakingHours,
    'readingWords': readingWords,
    'writtenWords': writtenWords,
    'knownWords': knownWords,
    'timeSpentMinutes': timeSpentMinutes,
    'lastUpdated': lastUpdated.toIso8601String(),
    'wordsByLanguage': wordsByLanguage,
    'timeByActivity': timeByActivity,
  };

  factory ProgressMetrics.fromMap(Map<String, dynamic> map) => ProgressMetrics(
    wordsLearned: map['wordsLearned'] ?? 0,
    listeningHours: (map['listeningHours'] ?? 0.0).toDouble(),
    speakingHours: (map['speakingHours'] ?? 0.0).toDouble(),
    readingWords: (map['readingWords'] ?? 0.0).toDouble(),
    writtenWords: map['writtenWords'] ?? 0,
    knownWords: map['knownWords'] ?? 0,
    timeSpentMinutes: (map['timeSpentMinutes'] ?? 0.0).toDouble(),
    lastUpdated: DateTime.parse(map['lastUpdated']),
    wordsByLanguage: Map<String, int>.from(map['wordsByLanguage'] ?? {}),
    timeByActivity: Map<String, double>.from(map['timeByActivity'] ?? {}),
  );

  String toJson() => jsonEncode(toMap());
  factory ProgressMetrics.fromJson(String json) => ProgressMetrics.fromMap(jsonDecode(json));

  ProgressMetrics copyWith({
    int? wordsLearned,
    double? listeningHours,
    double? speakingHours,
    double? readingWords,
    int? writtenWords,
    int? knownWords,
    double? timeSpentMinutes,
    DateTime? lastUpdated,
    Map<String, int>? wordsByLanguage,
    Map<String, double>? timeByActivity,
  }) => ProgressMetrics(
    wordsLearned: wordsLearned ?? this.wordsLearned,
    listeningHours: listeningHours ?? this.listeningHours,
    speakingHours: speakingHours ?? this.speakingHours,
    readingWords: readingWords ?? this.readingWords,
    writtenWords: writtenWords ?? this.writtenWords,
    knownWords: knownWords ?? this.knownWords,
    timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    wordsByLanguage: wordsByLanguage ?? this.wordsByLanguage,
    timeByActivity: timeByActivity ?? this.timeByActivity,
  );
}


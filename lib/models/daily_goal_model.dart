import 'dart:convert';

class DailyGoal {
  final int id;
  final String type; // 'lessons', 'quizzes', 'games', 'chat_minutes', 'words_learned'
  final int target;
  final int current;
  final DateTime date;
  final bool completed;
  final int streak;
  final DateTime? lastCompletedDate;

  DailyGoal({
    required this.id,
    required this.type,
    required this.target,
    required this.current,
    required this.date,
    required this.completed,
    required this.streak,
    this.lastCompletedDate,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  bool get isToday => date.year == DateTime.now().year && 
                      date.month == DateTime.now().month && 
                      date.day == DateTime.now().day;

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'target': target,
    'current': current,
    'date': date.toIso8601String(),
    'completed': completed,
    'streak': streak,
    'lastCompletedDate': lastCompletedDate?.toIso8601String(),
  };

  factory DailyGoal.fromMap(Map<String, dynamic> map) => DailyGoal(
    id: map['id'] ?? 0,
    type: map['type'] ?? '',
    target: map['target'] ?? 0,
    current: map['current'] ?? 0,
    date: DateTime.parse(map['date']),
    completed: map['completed'] ?? false,
    streak: map['streak'] ?? 0,
    lastCompletedDate: map['lastCompletedDate'] != null 
        ? DateTime.parse(map['lastCompletedDate']) 
        : null,
  );

  String toJson() => jsonEncode(toMap());
  factory DailyGoal.fromJson(String json) => DailyGoal.fromMap(jsonDecode(json));
}


/// Game mode certification telemetry snapshot (P12-007 module).
library;

class GameModeCertification {
  final String gameType;
  final String sessionId;
  final bool launchTelemetrySent;
  final bool turnTelemetrySent;
  final bool completionTelemetrySent;
  final bool hasTurns;
  final bool completed;
  final DateTime updatedAt;

  const GameModeCertification({
    required this.gameType,
    required this.sessionId,
    required this.launchTelemetrySent,
    required this.turnTelemetrySent,
    required this.completionTelemetrySent,
    required this.hasTurns,
    required this.completed,
    required this.updatedAt,
  });

  bool get passed =>
      launchTelemetrySent &&
      turnTelemetrySent &&
      completionTelemetrySent &&
      hasTurns &&
      completed;

  Map<String, dynamic> toJson() => {
        'game_type': gameType,
        'session_id': sessionId,
        'launch_telemetry_sent': launchTelemetrySent,
        'turn_telemetry_sent': turnTelemetrySent,
        'completion_telemetry_sent': completionTelemetrySent,
        'has_turns': hasTurns,
        'completed': completed,
        'passed': passed,
        'updated_at': updatedAt.toIso8601String(),
      };
}

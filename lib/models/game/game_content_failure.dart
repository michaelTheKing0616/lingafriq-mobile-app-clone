enum GameContentFailureType {
  none,
  serviceUnavailable,
  noContent,
  parseFailure,
  authFailure,
}

class GameContentFailure {
  final GameContentFailureType type;
  final String message;
  final DateTime timestamp;

  const GameContentFailure({
    required this.type,
    required this.message,
    required this.timestamp,
  });

  factory GameContentFailure.none() {
    return GameContentFailure(
      type: GameContentFailureType.none,
      message: '',
      timestamp: DateTime.now(),
    );
  }
}

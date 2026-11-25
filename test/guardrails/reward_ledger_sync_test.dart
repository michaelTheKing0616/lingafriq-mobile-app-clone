import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/user_gamification_model.dart';

void main() {
  test('toSyncPayload strips server-authoritative balances', () {
    final model = UserGamificationModel(xp: 100, cowries: 50, ngwenya: 10);
    final payload = model.toSyncPayload();
    expect(payload.containsKey('xp'), isFalse);
    expect(payload.containsKey('cowries'), isFalse);
    expect(payload.containsKey('ngwenya'), isFalse);
    expect(payload['dailyStreak'], 0);
  });
}

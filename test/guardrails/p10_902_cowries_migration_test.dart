import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/models/user_gamification_model.dart';

void main() {
  test('fromJson folds retired balances into cowries', () {
    final model = UserGamificationModel.fromJson({
      'cowries': 10,
      'ngwenya': 40,
      'ancestral_beads': 5,
    });
    expect(model.cowries, 55);
    expect(model.ngwenya, 0);
    expect(model.ancestralBeads, 0);
  });

  test('toJson omits retired currency keys', () {
    final json = UserGamificationModel(cowries: 12).toJson();
    expect(json.containsKey('ngwenya'), isFalse);
    expect(json.containsKey('ancestralBeads'), isFalse);
    expect(json['cowries'], 12);
  });
}

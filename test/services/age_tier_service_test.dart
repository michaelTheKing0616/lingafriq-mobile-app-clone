import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/age_tier_service.dart';

void main() {
  test('AgeTierAssignmentResult parses server payload', () {
    final result = AgeTierAssignmentResult.fromJson(<String, dynamic>{
      'ok': true,
      'tier': 'adult',
      'status': 'active',
      'pending_guardian': false,
      'social_enabled': true,
      'chat_enabled': true,
      'purchase_enabled': true,
    });
    expect(result.ok, isTrue);
    expect(result.tier, 'adult');
    expect(result.socialEnabled, isTrue);
  });

  test('AgeTierService assignBirthDate posts expected fields', () async {
    Map<String, Object?>? captured;
    final service = AgeTierService(
      post: (path, {data}) async {
        captured = data;
        return <String, dynamic>{'ok': true, 'tier': '13_15', 'status': 'active'};
      },
    );
    await service.assignBirthDate(
      birthYear: 2011,
      birthMonth: 2,
      birthDay: 3,
      deviceKey: 'dev-1',
      nationality: 'NG',
    );
    expect(captured!['birth_year'], 2011);
    expect(captured!['device_key'], 'dev-1');
  });
}

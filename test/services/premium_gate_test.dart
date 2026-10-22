import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/revenuecat_service.dart';

void main() {
  test('a 403 premium_required response is the upgrade state', () {
    expect(
      isPremiumRequired(statusCode: 403, body: {'error': 'premium_required'}),
      isTrue,
    );
    expect(isPremiumRequired(statusCode: 403, body: {'error': 'forbidden'}), isFalse);
    expect(isPremiumRequired(statusCode: 500, body: {'error': 'premium_required'}), isFalse);
  });
}

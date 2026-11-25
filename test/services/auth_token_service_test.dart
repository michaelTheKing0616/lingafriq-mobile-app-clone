import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/auth_token_service.dart';

void main() {
  test('parallel refresh callers share one request', () async {
    final gate = RefreshGate();
    var calls = 0;
    Future<String?> action() async {
      calls += 1;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      return 'access-047';
    }

    final results = await Future.wait([
      gate.run(action),
      gate.run(action),
      gate.run(action),
    ]);

    expect(calls, 1);
    expect(results, ['access-047', 'access-047', 'access-047']);
  });

  test('a rotated refresh token replaces the stored one', () {
    expect(
      rotatedRefresh({'access': 'new-access', 'refresh': 'new-refresh'}, 'old-refresh'),
      'new-refresh',
    );
    expect(rotatedRefresh({'access': 'new-access'}, 'old-refresh'), 'old-refresh');
  });
}

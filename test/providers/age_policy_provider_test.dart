import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/providers/age_policy_provider.dart';

void main() {
  group('AgePolicyState.bandBlocksSocialSurfaces', () {
    test('blocks child, teen, unknown, and missing band', () {
      expect(AgePolicyState.bandBlocksSocialSurfaces('child'), isTrue);
      expect(AgePolicyState.bandBlocksSocialSurfaces('teen'), isTrue);
      expect(AgePolicyState.bandBlocksSocialSurfaces('unknown'), isTrue);
      expect(AgePolicyState.bandBlocksSocialSurfaces(null), isTrue);
      expect(AgePolicyState.bandBlocksSocialSurfaces(''), isTrue);
    });

    test('allows adult band', () {
      expect(AgePolicyState.bandBlocksSocialSurfaces('adult'), isFalse);
    });
  });

  group('isAgeRestrictedResponseBody', () {
    test('detects age_restricted code', () {
      expect(
        isAgeRestrictedResponseBody(<String, dynamic>{'code': 'age_restricted'}),
        isTrue,
      );
      expect(
        isAgeRestrictedResponseBody(<String, dynamic>{'code': 'forbidden'}),
        isFalse,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/passport/passport_route_args.dart';

void main() {
  group('PassportRouteArgs.parseProctored', () {
    test('defaults when null', () {
      final p = PassportRouteArgs.parseProctored(null);
      expect(p.language, PassportRouteArgs.defaultLanguage);
      expect(p.proctorMode, PassportRouteArgs.defaultProctorMode);
    });

    test('reads language and proctorMode', () {
      final p = PassportRouteArgs.parseProctored({'language': ' sw ', 'proctorMode': ' staff_review '});
      expect(p.language, 'sw');
      expect(p.proctorMode, 'staff_review');
    });
  });

  group('PassportRouteArgs.parseCredential', () {
    test('null when not a map', () {
      expect(PassportRouteArgs.parseCredential('x'), isNull);
    });

    test('null when verifyToken blank', () {
      expect(PassportRouteArgs.parseCredential({'verifyToken': '  '}), isNull);
    });

    test('parses token level score', () {
      final p = PassportRouteArgs.parseCredential({'verifyToken': 't1', 'level': 'L3', 'score': '42'});
      expect(p, isNotNull);
      expect(p!.verifyToken, 't1');
      expect(p.level, 'L3');
      expect(p.score, 42);
    });
  });
}

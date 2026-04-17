import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/classroom/classroom_v2_route_args.dart';

void main() {
  group('ClassroomV2RouteArgs.parse', () {
    test('null arguments yields null tribeId and default tribe name', () {
      final r = ClassroomV2RouteArgs.parse(null);
      expect(r.tribeId, isNull);
      expect(r.tribeName, ClassroomV2RouteArgs.defaultTribeName);
    });

    test('blank tribeId yields null tribeId', () {
      final r = ClassroomV2RouteArgs.parse({'tribeId': '  ', 'tribeName': 'My Class'});
      expect(r.tribeId, isNull);
      expect(r.tribeName, 'My Class');
    });

    test('trims tribeId and tribeName', () {
      final r = ClassroomV2RouteArgs.parse({'tribeId': ' abc ', 'tribeName': ' Room '});
      expect(r.tribeId, 'abc');
      expect(r.tribeName, 'Room');
    });

    test('non-map arguments yield null tribeId', () {
      final r = ClassroomV2RouteArgs.parse('not-a-map');
      expect(r.tribeId, isNull);
      expect(r.tribeName, ClassroomV2RouteArgs.defaultTribeName);
    });
  });
}

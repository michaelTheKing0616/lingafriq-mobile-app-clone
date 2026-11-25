import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/clips/clip_upload_service.dart';

void main() {
  group('ClipUploadService', () {
    test('validateDurationSec enforces 15–60 window', () {
      expect(ClipUploadService.validateDurationSec(14), isNotNull);
      expect(ClipUploadService.validateDurationSec(15), isNull);
      expect(ClipUploadService.validateDurationSec(60), isNull);
      expect(ClipUploadService.validateDurationSec(61), isNotNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/social/community_corrections_screen.dart';

void main() {
  test('P9-951 feed item parses native verification fields', () {
    final item = NativeCorrectionFeedItem.fromJson({
      'id': 'ncs_1',
      'language': 'yo',
      'originalText': 'Báwo ni?',
      'correctedText': 'Báwo ni?',
      'status': 'answered',
      'native_verified': true,
      'reputation_score': 0.82,
      'helpful_count': 2,
      'content_qa_routed': true,
    });
    expect(item.nativeVerified, isTrue);
    expect(item.reputationScore, 0.82);
    expect(item.contentQaRouted, isTrue);
    expect(item.helpfulCount, 2);
  });
}

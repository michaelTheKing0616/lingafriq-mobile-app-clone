import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/safety/community_guidelines_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('loader', () async {
    final strings = await CommunityGuidelinesLoader.load(const Locale('en'));
    expect(strings['guidelines.title'], isNotNull);
    final meta = await CommunityGuidelinesLoader.loadMeta();
    expect(meta.version, '1.0.0');
  });
}

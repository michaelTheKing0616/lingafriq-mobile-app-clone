// charter: v2
// P12-008: router smoke — consolidated routes must not reference deleted screens.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repoRoot = Directory.current.path.endsWith('navigation')
      ? Directory('${Directory.current.path}/../..')
      : Directory.current;
  final myApp = File('${repoRoot.path}/lib/my_app.dart');

  test('global_chat route uses Material3 screen not legacy GlobalChatScreen', () {
    expect(myApp.existsSync(), isTrue);
    final text = myApp.readAsStringSync();
    expect(text, contains("'global_chat'"));
    expect(text, contains('GlobalChatScreenMaterial3'));
    expect(text, isNot(contains('screens/chat/global_chat_screen.dart')));
    expect(text, isNot(matches(RegExp(r'GlobalChatScreen\(\)'))));
  });

  test('Polie workspace is wired; legacy ai_chat_screen variants are not imported', () {
    final text = myApp.readAsStringSync();
    expect(text, isNot(contains('ai_chat_screen.dart')));
    expect(text, isNot(contains('ai_chat_screen_new.dart')));
    expect(text, isNot(contains('ai_chat_screen_with_tracking.dart')));
    expect(text, isNot(contains('conversation_enhanced_screen.dart')));
  });
}

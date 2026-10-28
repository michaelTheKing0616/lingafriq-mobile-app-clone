import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/features/ai_chat/providers/groq_chat_models.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _maxLines = 500;

void _assertDirUnderMax(String dirPath) {
  final dir = Directory(dirPath);
  expect(dir.existsSync(), isTrue, reason: dirPath);
  for (final entity in dir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final lines = entity.readAsLinesSync().length;
    expect(lines, lessThanOrEqualTo(_maxLines), reason: entity.path);
  }
}

void main() {
  test('P12-006: api provider modules <= $_maxLines lines', () {
    _assertDirUnderMax('lib/features/api/providers');
    expect(File('lib/providers/api_provider.dart').readAsLinesSync().length,
        lessThanOrEqualTo(_maxLines));
  });

  test('P12-006: groq chat provider modules <= $_maxLines lines', () {
    _assertDirUnderMax('lib/features/ai_chat/providers');
    expect(File('lib/providers/ai_chat_provider_groq.dart').readAsLinesSync().length,
        lessThanOrEqualTo(_maxLines));
  });

  test('P12-006: public provider names unchanged', () {
    expect(groqChatProvider, isA<NotifierProvider<GroqChatProvider, BaseProviderState>>());
    expect(apiProvider, isA<NotifierProvider<ApiProvider, BaseProviderState>>());
    expect(PolieMode.tutor, PolieMode.tutor);
  });

  group('ApiProvider', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('typed error surface on setProviderError', () {
      container.read(apiProvider.notifier).setProviderError('Network unavailable');
      final state = container.read(apiProvider);
      expect(state.hasError, isTrue);
      expect(state.errorMessage, 'Network unavailable');
      expect(state.errorTimestamp, isNotNull);
    });
  });
}

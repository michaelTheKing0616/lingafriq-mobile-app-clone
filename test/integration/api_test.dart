import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('API Integration Tests', () {
    test('API provider initialization', () {
      final container = ProviderContainer();
      final apiNotifier = container.read(apiProvider.notifier);
      
      expect(apiNotifier, isNotNull);
      expect(apiNotifier.token, isNull); // No token initially
    });

    // Note: These tests require a running backend server
    // Uncomment and configure for actual integration testing
    
    // test('Login API call', () async {
    //   final container = ProviderContainer();
    //   final apiProvider = container.read(apiProvider.notifier);
    //   
    //   try {
    //     final user = await apiProvider.login({
    //       'email': 'test@example.com',
    //       'password': 'testpassword',
    //     });
    //     
    //     expect(user, isNotNull);
    //     expect(apiProvider.token, isNotNull);
    //   } catch (e) {
    //     // Handle test environment (no backend)
    //     expect(e, isA<Exception>());
    //   }
    // });

    // test('Get languages API call', () async {
    //   final container = ProviderContainer();
    //   final apiProvider = container.read(apiProvider.notifier);
    //   apiProvider.token = 'test_token';
    //   
    //   try {
    //     final languages = await apiProvider.getLanguages();
    //     expect(languages.results, isNotEmpty);
    //   } catch (e) {
    //     // Handle test environment
    //     expect(e, isA<Exception>());
    //   }
    // });
  });
}


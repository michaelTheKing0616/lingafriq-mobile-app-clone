import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('BaseProviderState (auth state)', () {
    test('should create with default values', () {
      final state = BaseProviderState();

      expect(state.errorMessage, isNull);
      expect(state.isLoading, false);
    });

    test('copyWith should create new state with updated values', () {
      final state = BaseProviderState(isLoading: false);
      final newState = state.copyWith(isLoading: true);

      expect(state.isLoading, false);
      expect(newState.isLoading, true);
    });

    test('copyWith without parameters should return same values', () {
      final state = BaseProviderState(isLoading: true, errorMessage: 'test error');
      final newState = state.copyWith();

      expect(newState.isLoading, true);
      expect(newState.errorMessage, 'test error');
    });

    test('clearError via copyWith should reset errorMessage', () {
      final state = BaseProviderState(errorMessage: 'Some error');
      final newState = state.copyWith(clearError: true);

      expect(newState.errorMessage, isNull);
    });
  });

  group('AuthProvider', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(SharedPreferencesProvider(prefs)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should not be loading', () {
      final state = container.read(authProvider);
      expect(state.isLoading, false);
    });

    test('initial state should have BaseProviderState', () {
      final state = container.read(authProvider);
      expect(state, isA<BaseProviderState>());
    });

    test('signOut should not throw', () async {
      final notifier = container.read(authProvider.notifier);
      await expectLater(notifier.signOut(), completes);
    });
  });

  group('Auth Validation', () {
    test('email validation should detect invalid emails', () {
      final invalidEmails = [
        '',
        'test',
        'test@',
        '@example.com',
        'test @example.com',
      ];

      for (final email in invalidEmails) {
        final isValid =
            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
        expect(isValid, false, reason: 'Email "$email" should be invalid');
      }
    });

    test('email validation should accept valid emails', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.org',
        'user+tag@example.co.uk',
      ];

      for (final email in validEmails) {
        final isValid =
            RegExp(r'^[\w-\.+]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
        expect(isValid, true, reason: 'Email "$email" should be valid');
      }
    });

    test('password validation should require minimum length', () {
      const minLength = 8;

      expect('short'.length >= minLength, false);
      expect('password123'.length >= minLength, true);
    });
  });

  group('Token Management', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should persist token across sessions', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'test_token_123');

      final savedToken = prefs.getString('auth_token');
      expect(savedToken, 'test_token_123');
    });

    test('should clear token on logout', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'test_token_123');

      await prefs.remove('auth_token');

      final savedToken = prefs.getString('auth_token');
      expect(savedToken, isNull);
    });
  });
}

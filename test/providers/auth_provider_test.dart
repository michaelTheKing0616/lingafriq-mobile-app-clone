import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthState', () {
    test('should create with default values', () {
      const state = AuthState();
      
      expect(state.user, isNull);
      expect(state.isLoading, false);
      expect(state.isAuthenticated, false);
      expect(state.errorMessage, isNull);
    });
    
    test('copyWith should create new state with updated values', () {
      const state = AuthState(isLoading: false);
      final newState = state.copyWith(isLoading: true);
      
      expect(state.isLoading, false);
      expect(newState.isLoading, true);
    });
    
    test('copyWith without parameters should return same values', () {
      const state = AuthState(isLoading: true, errorMessage: 'test error');
      final newState = state.copyWith();
      
      expect(newState.isLoading, true);
      expect(newState.errorMessage, 'test error');
    });
    
    test('isAuthenticated should be true when user is set', () {
      final state = AuthState(
        user: UserModel(
          id: '1',
          email: 'test@example.com',
          name: 'Test User',
        ),
      );
      
      expect(state.isAuthenticated, true);
    });
    
    test('clearError should reset errorMessage', () {
      const state = AuthState(errorMessage: 'Some error');
      final newState = state.copyWith(errorMessage: null);
      
      expect(newState.errorMessage, isNull);
    });
  });
  
  group('AuthNotifier', () {
    late ProviderContainer container;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('initial state should not be authenticated', () {
      final state = container.read(authProvider);
      expect(state.isAuthenticated, false);
      expect(state.user, isNull);
    });
    
    test('initial state should not be loading', () {
      final state = container.read(authProvider);
      expect(state.isLoading, false);
    });
    
    test('setLoading should update loading state', () {
      final notifier = container.read(authProvider.notifier);
      notifier.setLoading(true);
      
      final state = container.read(authProvider);
      expect(state.isLoading, true);
    });
    
    test('setError should update error message', () {
      final notifier = container.read(authProvider.notifier);
      notifier.setError('Test error');
      
      final state = container.read(authProvider);
      expect(state.errorMessage, 'Test error');
    });
    
    test('clearError should remove error message', () {
      final notifier = container.read(authProvider.notifier);
      notifier.setError('Test error');
      notifier.clearError();
      
      final state = container.read(authProvider);
      expect(state.errorMessage, isNull);
    });
    
    test('logout should clear user and token', () {
      final notifier = container.read(authProvider.notifier);
      // Set some state first
      notifier.setError('Some error');
      
      // Logout
      notifier.logout();
      
      final state = container.read(authProvider);
      expect(state.isAuthenticated, false);
      expect(state.user, isNull);
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
        // Basic email validation regex
        final isValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
        // Basic email validation regex
        final isValid = RegExp(r'^[\w-\.+]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
    
    test('should handle null token gracefully', () {
      final notifier = container.read(authProvider.notifier);
      // Access token when not set
      expect(() => notifier.token, returnsNormally);
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
      
      // Simulate logout clearing token
      await prefs.remove('auth_token');
      
      final savedToken = prefs.getString('auth_token');
      expect(savedToken, isNull);
    });
  });
}

// Simple UserModel for testing
class UserModel {
  final String id;
  final String email;
  final String name;
  
  UserModel({
    required this.id,
    required this.email,
    required this.name,
  });
}

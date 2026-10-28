import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, visibleForTesting;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/auth_provider.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/services/auth_token_service.dart';
import 'package:lingafriq/utils/api.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/models/user.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/utils/structured_logger.dart';


mixin ApiProviderMixin1 on Notifier<BaseProviderState>, BaseProviderMixin {
  Future<T> withTransportRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 350),
  }) async {
    var attempt = 0;
    Object? lastError;
    while (attempt < maxAttempts) {
      attempt++;
      try {
        return await operation();
      } on DioException catch (e) {
        lastError = e;
        if (!TransportErrorPolicy.isRetryable(e) || attempt >= maxAttempts) {
          rethrow;
        }
      } catch (e) {
        lastError = e;
        if (attempt >= maxAttempts) rethrow;
      }

      final wait = Duration(milliseconds: initialDelay.inMilliseconds * attempt);
      await Future.delayed(wait);
    }
    throw lastError ?? Exception('Transport retry failed');
  }

  @override
  BaseProviderState build() {
    // Load tokens from SharedPreferences on initialization
    // This ensures tokens are available if the app was previously logged in
    _loadTokensFromStorage();
    return BaseProviderState();
  }

  String? token;
  String? refreshToken;
  final RefreshGate _refreshGate = RefreshGate();

  /// Load tokens from SharedPreferences on provider initialization
  void _loadTokensFromStorage() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      token = prefs.getAccessToken();
      // Refresh token is async, but we can't await in build()
      // It will be loaded when needed via refreshAccessToken()
    } catch (e) {
      // Silently fail - tokens might not exist yet (user not logged in)
      token = null;
      refreshToken = null;
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(client).post(Api.logout).timeout(const Duration(seconds: 5));
    } catch (_) {
      // The caller still clears local tokens.
    }
  }

  /// Refresh access token using refresh token.
  /// Parallel callers share one request.
  Future<String?> refreshAccessToken() {
    return _refreshGate.run(() async {
      try {
        if (refreshToken == null || (refreshToken?.isEmpty ?? true)) {
          final prefs = ref.read(sharedPreferencesProvider);
          refreshToken = await prefs.getRefreshToken();
        }

        if (refreshToken == null || (refreshToken?.isEmpty ?? true)) {
          return null;
        }

        final res = await ref.read(client).post(
          Api.refreshToken,
          data: { 'refresh': refreshToken },
        );

        if (res.statusCode == 200) {
          final data = res.data;
          final access = (data is Map<String, dynamic>)
              ? (data['accessToken'] ?? data['access'] ?? data['token'])?.toString()
              : null;

          if (access != null && access.isNotEmpty) {
            token = access;
            refreshToken = rotatedRefresh(data, refreshToken);
            final prefs = ref.read(sharedPreferencesProvider);
            if (refreshToken != null && refreshToken!.isNotEmpty) {
              await prefs.storeAuthTokens(token!, refreshToken!);
            }
            return token;
          }
        }
        return null;
      } catch (_) {
        token = null;
        refreshToken = null;
        return null;
      }
    });
  }

  /// Clear stored tokens
  void clearToken() {
    token = null;
    refreshToken = null;
  }

  Future<void> register(FormData registerData) async {
    try {
      final agePayload = ref.read(onboardingProvider.notifier).registrationAgePayload();
      for (final entry in agePayload.entries) {
        registerData.fields.add(MapEntry(entry.key, entry.value.toString()));
      }
      final res = await ref.read(client).post(
            Api.register,
            data: registerData,
            options: Options(contentType: "multipart/form-data"),
          );
      if (res.statusCode != 201) throw res.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendVerification(String email) async {
    try {
      final res = await ref.read(client).post(
            ApiContract.url(ApiContract.auth.sendVerification),
            data: {'email': email},
          );
      if (res.statusCode != 200) {
        final error = res.data?['message'] ?? 'Failed to send verification code';
        throw Exception(error);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    try {
      final res = await ref.read(client).post(
            ApiContract.url(ApiContract.auth.verifyEmail),
            data: {
              'email': email,
              'code': code,
            },
          );
      if (res.statusCode != 200) {
        final error = res.data?['message'] ?? 'Invalid verification code';
        throw Exception(error);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      final res = await ref.read(client).post(
            ApiContract.url(ApiContract.auth.resendVerification),
            data: {'email': email},
          );
      if (res.statusCode != 200) {
        final error = res.data?['message'] ?? 'Failed to resend verification code';
        throw Exception(error);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ProfileModel> login(Map<String, String> data) async {
    try {
      // Log the login attempt with backend URL for debugging
      logger.info('Login API call', context: {
        'endpoint': Api.login,
        'baseUrl': ApiContract.baseUrl,
        'fullUrl': ApiContract.url(ApiContract.auth.login),
      });
      
      final res = await ref.read(client).post(Api.login, data: data);
      if (res.statusCode != 200) {
        // Convert to structured error
        final error = ErrorConverter.toAppError(
          DioException(
            requestOptions: RequestOptions(path: Api.login),
            response: res,
            type: DioExceptionType.badResponse,
          ),
        );
        throw error;
      }
      token = res.data['access'] ?? res.data['token'];
      refreshToken = res.data['refresh'];

      // Store tokens
      if ((token?.isNotEmpty ?? false) && (refreshToken?.isNotEmpty ?? false)) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.storeAuthTokens(token!, refreshToken!);
      }

      final email = data['email'] as String;
      final prefs = ref.read(sharedPreferencesProvider);
      // Always refresh profile from the server after login so fields like
      // `is_admin` / `is_staff` (staff tools) are never stale vs cached prefs.
      final userInfo = await getUserInfo();
      final user = await getProfileUser(userInfo.id);
      await prefs.storeUser(user, userInfo.email);

      // Update user provider with current user
      ref.read(userProvider.notifier).overrideUser(user);

      logger.info('Login successful', context: {'email': data['email']});
      return user;
    } catch (e) {
      // Log detailed error information for debugging
      logger.error('Login API call failed', error: e, context: {
        'endpoint': Api.login,
        'baseUrl': ApiContract.baseUrl,
        'fullUrl': ApiContract.url(ApiContract.auth.login),
        'errorType': e.runtimeType.toString(),
        'isDioException': e is DioException,
        'dioErrorType': e is DioException ? e.type.toString() : null,
        'statusCode': e is DioException ? e.response?.statusCode : null,
      });
      rethrow;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true);
      final data = {"email": email};
      final res = await ref.read(client).post(Api.resetPassword, data: data);
      if (res.statusCode != 204) throw res.data;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ref.read(dialogProvider(e)).showExceptionDialog();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final userId = ref.read(userProvider)?.id;
      if (userId == null) return false;
      state = state.copyWith(isLoading: true);
      final res = await ref.read(client).put(Api.userInfo, data: data);
      logger.debug('Profile update status received', context: {'statusCode': res.statusCode});
      if (res.statusCode != 200) throw res.data;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ref.read(dialogProvider(e)).showExceptionDialog();
      return false;
    }
  }

  Future<bool> accountUpdate() async {
    try {
      final res = await ref.read(client).get(Api.accountUpdate);
      logger.debug('Account update status received', context: {'statusCode': res.statusCode});
      if (res.statusCode != 200) throw res.data;
      return true;
    } catch (e) {
      logger.warn('Account update failed', tag: 'accountUpdate', error: e);
      return false;
    }
  }

  Future<bool> deleteUser(Map<String, dynamic> data) async {
    try {
      final userId = ref.read(userProvider)?.id;
      if (userId == null) return false;
      setBusy();
      final res = await ref.read(client).delete(
            Api.deleteUser(userId),
            data: data,
          );
      logger.debug('Delete user status received', context: {'statusCode': res.statusCode});
      if (res.statusCode != 204) throw res.data;
      setIdle();
      ref.read(authProvider.notifier).signOut();
      return true;
    } catch (e) {
      setIdle();
      ref.read(dialogProvider(e)).showExceptionDialog();
      return false;
    }
  }

  Future<ProfileModel> getProfileUser(int id) async {
    try {
      final res = await ref.read(client).get(Api.userProfile(id));

      if (res.statusCode != 200) throw res.data;
      return ProfileModel.fromMap(res.data.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getUserInfo() async {
    logger.debug('Fetching current user info');
    try {
      final res = await ref.read(client).get(Api.userInfo);
      if (res.statusCode != 200) throw res.data;
      return User.fromMap(res.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      setBusy();
      final data = {
        "new_password": newPassword,
        "current_password": currentPassword,
      };
      final res = await ref.read(client).post(Api.changePassword, data: data);
      if (res.statusCode != 204) throw res.data;
      setIdle();
      return true;
    } catch (e) {
      setIdle();
      ref.read(dialogProvider(e)).showExceptionDialog();
      return false;
    }
  }

  /// Update user preferences (privacy, analytics, etc.). Persists to backend when available.
  Future<bool> updateUserPreferences(Map<String, dynamic> prefs) async {
    try {
      final res = await ref.read(client).put(
        ApiContract.url(ApiContract.accounts.userPreferences),
        data: prefs,
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      // Backend may not implement preferences endpoint yet; fail silently
      return false;
    }
  }

  /// Fetch user preferences from backend.
  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final res = await ref.read(client).get(
        ApiContract.url(ApiContract.accounts.userPreferences),
      );
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // AVATAR API METHODS
  // ============================================

  /// Fetch user's avatar configuration from the backend.
  /// Returns null if network fails (offline-safe).
  Future<Map<String, dynamic>?> getAvatarConfig() async {
    try {
      final res = await ref.read(client).get(
        ApiContract.url(ApiContract.avatar.config),
      );
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data;
        if (data['success'] == true && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data']);
        }
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to fetch avatar config: $e');
      return null;
    }
  }

  /// Save user's avatar configuration to the backend.
  /// Returns true on success, false on failure (changes are kept locally).
  Future<bool> saveAvatarConfig(Map<String, dynamic> config) async {
    try {
      final res = await ref.read(client).put(
        ApiContract.url(ApiContract.avatar.config),
        data: config,
      );
      return res.statusCode == 200 && res.data?['success'] == true;
    } catch (e) {
      debugPrint('Failed to save avatar config: $e');
      return false;
    }
  }

  /// Unlock a premium avatar item (outfit, accessory, or hair style).
  /// Called when user purchases with cowries or earns through achievements.
  Future<Map<String, dynamic>?> unlockAvatarItem({
    required String itemType,
    required int itemId,
  }) async {
    try {
      final res = await ref.read(client).post(
        ApiContract.url(ApiContract.avatar.unlock),
        data: {'itemType': itemType, 'itemId': itemId},
      );
      if (res.statusCode == 200 && res.data?['success'] == true) {
        return Map<String, dynamic>.from(res.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to unlock avatar item: $e');
      return null;
    }
  }

  /// Fetch learning path by language and path type.
}

# Authentication Issue Analysis

## Problem Summary
The mobile app is not sending authentication tokens with API requests, causing 401 "No authorization token was found" errors. Users can't load lessons, quizzes, or see most app drawer entries.

## Root Cause

The app uses two different HTTP clients with different token storage mechanisms:

1. **`ApiService`** (dio-based utility class)
   - Reads tokens from SharedPreferences directly (`'auth_token'` or `'access_token'`)
   - Used in some screens

2. **`dio_provider`** (via `ref.read(client)`)
   - Reads tokens from `apiProvider.notifier.token` (member variable)
   - Used by providers like `api_provider.dart`

### The Issue

When the app starts:
1. `navigateBasedOnCondition()` checks for stored credentials
2. If credentials exist, it attempts auto-login
3. On successful login, tokens are stored in SharedPreferences via `storeAuthTokens()`
4. **However**, the `api_provider.token` member variable is only set during the login flow
5. If the app was previously logged in (tokens exist in SharedPreferences), the `api_provider.token` member variable is **null** because it's not initialized from SharedPreferences
6. When API calls are made via `ref.read(client).get()`, the `dio_provider` tries to get the token from `apiProvider.notifier.token`, which is null
7. Requests go without Authorization header → 401 errors

## Evidence from Logs

Backend logs show:
```
Client error No authorization token was found {
  "context": "error-handler",
  "statusCode": 401,
  "name": "UnauthorizedError",
  "path": "/language",
  "method": "GET",
  "ip": "102.88.110.199",
  "userAgent": "Dart/3.9 (dart:io)",
}
```

The `/language` endpoint requires authentication (`requireSignin` middleware) and is called via `api_provider.getLanguages()` which uses `ref.read(client).get()`.

## Solution

### Option 1: Initialize tokens from SharedPreferences on app start (Recommended)

Modify `api_provider.dart` to load tokens from SharedPreferences when the provider is initialized:

```dart
@override
BaseProviderState build() {
  // Load tokens from SharedPreferences on initialization
  _loadTokensFromStorage();
  return BaseProviderState();
}

Future<void> _loadTokensFromStorage() async {
  final prefs = ref.read(sharedPreferencesProvider);
  token = prefs.getAccessToken();
  refreshToken = await prefs.getRefreshToken();
}
```

### Option 2: Make dio_provider check SharedPreferences as fallback

Modify `dio_provider.dart` to check SharedPreferences if `apiProvider.notifier.token` is null:

```dart
final token = ref.read(apiProvider.notifier).token;
if (token == null) {
  // Fallback to SharedPreferences
  final prefs = ref.read(sharedPreferencesProvider);
  final storedToken = prefs.getAccessToken();
  if (storedToken != null) {
    options.headers.addAll({"Authorization": "Bearer $storedToken"});
  }
} else {
  options.headers.addAll({"Authorization": "Bearer $token"});
}
```

### Option 3: Ensure tokens are loaded after auto-login

In `auth_provider.dart`, after successful login in `navigateBasedOnCondition()`, ensure the tokens are also set in the api_provider:

```dart
final user = await login(email: email, password: password);
if (user is ProfileModel) {
  // Ensure api_provider has the tokens
  final prefs = ref.read(sharedPreferencesProvider);
  final token = prefs.getAccessToken();
  if (token != null) {
    ref.read(apiProvider.notifier).token = token; // Set member variable
  }
  // ... rest of code
}
```

## Additional Notes

1. **Backend Configuration**: The backend trust proxy is correctly configured (`app.set('trust proxy', 1)`), so rate limiting should work correctly.

2. **Token Storage**: Tokens are stored correctly in SharedPreferences with key `'auth_token'`, so `ApiService` calls should work if they're used.

3. **Token Refresh**: The `dio_provider` has token refresh logic on 401 errors, but it won't help if the initial token is missing.

## Recommended Fix

Implement **Option 1** as it's the cleanest solution and ensures tokens are always available when the provider is initialized. This handles both fresh app starts and cases where tokens exist from previous sessions.

## Files to Modify

1. `lib/providers/api_provider.dart` - Add `_loadTokensFromStorage()` method and call it in `build()`
2. Consider also updating `dio_provider.dart` to add SharedPreferences fallback as a safety net


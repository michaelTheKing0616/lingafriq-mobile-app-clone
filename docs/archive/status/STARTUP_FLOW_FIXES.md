# App Startup Flow & Backend Connectivity Fixes

## Date: January 27, 2026
## Purpose: Fix frontend-backend communication issues preventing onboarding and login

---

## App Flow Analysis

### Startup Flow (Traced)
1. **App Launch** → `main.dart`
   - Initializes services (Firebase, offline services, etc.)
   - Creates `MyApp` widget

2. **MyApp** → Shows `SplashScreen`

3. **SplashScreen** → After 1.2s delay, calls:
   ```dart
   ref.read(authProvider.notifier).navigateBasedOnCondition()
   ```

4. **navigateBasedOnCondition()** (in `auth_provider.dart`):
   - Checks if onboarding is complete
   - If NOT complete → Shows `OnboardingScreenMaterial3`
   - If complete → Checks if user is logged in
   - If NOT logged in → Attempts auto-login
   - If auto-login fails → Shows `WorldClassLoginScreen`

5. **Login Flow**:
   - User enters credentials → Calls `authProvider.login()`
   - Which calls `apiProvider.login()` → Makes POST to `Api.login` (`auth/jwt/create/`)
   - Uses `client` from `dio_provider.dart` with baseUrl = `Api.baseurl`
   - `Api.baseurl` comes from `EnvConfig.backendBaseUrl` (default: `https://api.lingafriq.com`)

---

## Issues Identified

### 1. **Misleading Error Messages**
- Backend connection failures were showing "Internet not connected"
- Error handler was misclassifying backend errors as network errors

### 2. **No Connectivity Verification**
- Login attempts were made without checking if backend is reachable
- No way to distinguish "no internet" vs "backend unreachable"

### 3. **Lack of Debug Information**
- No logging of backend URL being used
- No logging of connection attempts
- Difficult to diagnose connection issues

### 4. **Onboarding Flow**
- ✅ **GOOD**: Onboarding doesn't require backend (works offline)
- ✅ **GOOD**: Onboarding completion tries to sync but doesn't block if backend is down
- The issue is likely that onboarding completes, but then login fails

---

## Fixes Implemented

### 1. **Connectivity Check Before Login** (`auth_provider.dart`)

**Added**: Pre-login connectivity verification using `BackendConnectivityTest`

```dart
// Before attempting login, verify backend is reachable
final connectivityTest = BackendConnectivityTest();
final connectivityResult = await connectivityTest.testBackendHealth();

if (!connectivityResult.isConnected) {
  // Throw specific error based on connectivity status
  if (connectivityResult.hasInternet) {
    throw DioException(..., error: 'Cannot connect to server...');
  } else {
    throw DioException(..., error: 'No internet connection...');
  }
}
```

**Benefits**:
- Prevents misleading "Internet not connected" errors
- Provides accurate error messages
- Helps diagnose connection issues

### 2. **Enhanced Error Logging** (`auth_provider.dart` & `api_provider.dart`)

**Added**: Comprehensive logging at key points:

- **Startup**: Logs backend URL configuration
- **Onboarding Check**: Logs onboarding status
- **Login Attempt**: Logs email, endpoint, baseUrl
- **Login Success**: Logs successful login
- **Login Failure**: Logs detailed error information (error type, DioException type, status code)

**Example Log Output**:
```
[INFO] App startup navigation {backendUrl: https://api.lingafriq.com/, ...}
[INFO] Onboarding status check {isOnboardingSeen: false, ...}
[INFO] Login API call {endpoint: auth/jwt/create/, baseUrl: https://api.lingafriq.com/, ...}
[ERROR] Login API call failed {errorType: DioException, dioErrorType: DioExceptionType.connectionError, ...}
```

### 3. **Improved Error Messages**

**Updated**: Error handler already distinguishes:
- **Network errors**: DNS failures, no route to host → "No internet connection"
- **Backend errors**: Connection refused, timeouts → "Cannot connect to server"

**Added**: Connectivity check provides even more specific errors:
- "Cannot connect to server. Please check if the server is running or try again later."
- "No internet connection. Please check your network settings."

### 4. **Startup Logging**

**Added**: Logs backend URL at app startup to help diagnose configuration issues:

```dart
logger.info('App startup navigation', context: {
  'backendUrl': Api.baseurl,
  'backendUrlSource': 'EnvConfig.backendBaseUrl',
});
```

---

## How to Verify the Fixes

### 1. **Check Backend URL Configuration**

The app uses `EnvConfig.backendBaseUrl` which defaults to `https://api.lingafriq.com`

**To verify**:
- Check logs for: `[INFO] App startup navigation {backendUrl: ...}`
- Ensure the URL matches your actual backend

**To change**:
```bash
flutter run --dart-define=BACKEND_URL=http://your-backend-url:4000
```

### 2. **Test Connectivity**

**Before login attempt**, the app now:
1. Checks if device has internet
2. Checks if backend is reachable
3. Provides specific error if either check fails

**Check logs for**:
- `[WARN] Backend not reachable before login attempt` - Backend connectivity issue
- `[ERROR] Login API call failed` - Actual login API failure

### 3. **Verify Onboarding Flow**

**Onboarding should work even if backend is down**:
- Onboarding screens don't require backend
- Onboarding completion saves locally first
- Backend sync is attempted but doesn't block

**Check logs for**:
- `[INFO] Onboarding status check` - Shows onboarding state
- If onboarding not complete → Should show onboarding screen
- If onboarding complete → Should attempt login

### 4. **Test Login Flow**

**Expected behavior**:
1. User enters credentials
2. App checks backend connectivity
3. If backend unreachable → Shows "Cannot connect to server"
4. If backend reachable → Attempts login
5. If login fails → Shows specific error

**Check logs for**:
- `[INFO] Attempting login {email: ...}`
- `[INFO] Login API call {endpoint: ..., baseUrl: ...}`
- `[INFO] Login successful` or `[ERROR] Login API call failed`

---

## Troubleshooting

### Issue: "Internet not connected" but internet works

**Cause**: Backend URL might be incorrect or backend is down

**Solution**:
1. Check logs for backend URL: `[INFO] App startup navigation`
2. Verify backend is running: `curl http://your-backend-url:4000/healthcheck`
3. Check if URL matches: Backend URL in logs should match actual backend
4. If using HTTPS, ensure SSL certificate is valid

### Issue: Onboarding not showing

**Cause**: Onboarding flags might be set incorrectly

**Solution**:
1. Check logs: `[INFO] Onboarding status check`
2. Clear app data or reset onboarding flags:
   ```dart
   await prefs.setBool('onboarding_seen', false);
   await prefs.remove('onboarding_complete');
   ```

### Issue: Login fails with connection error

**Cause**: Backend is not reachable

**Solution**:
1. Check logs: `[WARN] Backend not reachable before login attempt`
2. Verify backend is running
3. Check network connectivity
4. Verify backend URL is correct
5. Check firewall/network settings

### Issue: Login works but shows error

**Cause**: Error handling might be catching success as error

**Solution**:
1. Check logs: `[INFO] Login successful` should appear
2. Verify error is not from a different operation (e.g., device registration)
3. Check if error is from a follow-up API call

---

## Files Modified

1. **`lib/providers/auth_provider.dart`**:
   - Added connectivity check before login
   - Added startup logging
   - Added detailed error logging
   - Improved auto-login error handling

2. **`lib/providers/api_provider.dart`**:
   - Added login attempt logging
   - Added login success/failure logging
   - Added detailed error context

---

## Next Steps

1. **Test the app**:
   - Run the app and check logs
   - Verify backend URL is correct
   - Test onboarding flow
   - Test login flow

2. **Monitor logs**:
   - Look for connectivity warnings
   - Check error messages are accurate
   - Verify backend URL matches actual backend

3. **If issues persist**:
   - Check backend is running and accessible
   - Verify backend URL configuration
   - Check network/firewall settings
   - Review error logs for specific error types

---

## Expected Behavior After Fixes

### ✅ Onboarding
- Should show onboarding screen if not completed
- Should work even if backend is down
- Should save locally and attempt backend sync

### ✅ Login
- Should check backend connectivity before attempting
- Should show accurate error messages
- Should log detailed information for debugging
- Should distinguish "no internet" vs "backend unreachable"

### ✅ Error Messages
- "No internet connection" → Only when truly offline
- "Cannot connect to server" → When backend is unreachable (but internet works)
- Specific error messages → Based on actual error type

---

## Debugging Commands

### Check Backend URL in Code
```dart
debugPrint('Backend URL: ${Api.baseurl}');
debugPrint('From EnvConfig: ${EnvConfig.backendBaseUrl}');
```

### Test Backend Connectivity
```dart
final test = BackendConnectivityTest();
final result = await test.testBackendHealth();
print('Connected: ${result.isConnected}');
print('Has Internet: ${result.hasInternet}');
print('Error: ${result.errorMessage}');
```

### Print Connectivity Status
```dart
await ConnectivityVerification.printStatus();
```

---

## Related Files

- `lib/providers/auth_provider.dart` - Auth and navigation logic
- `lib/providers/api_provider.dart` - API calls
- `lib/utils/error_handler.dart` - Error handling
- `lib/services/backend_connectivity_test.dart` - Connectivity testing
- `lib/utils/connectivity_verification.dart` - Connectivity utilities
- `lib/services/env_config.dart` - Backend URL configuration

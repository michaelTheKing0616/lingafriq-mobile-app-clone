# Backend Connectivity Verification Guide

## Overview
This guide helps verify that the mobile app can successfully connect to and communicate with the backend API.

## Quick Verification

### 1. Check Backend URL Configuration

The backend URL is configured in `lib/services/env_config.dart`:

```dart
static String get backendBaseUrl {
  const url = String.fromEnvironment('BACKEND_URL', defaultValue: 'https://api.lingafriq.com');
  return url;
}
```

**Default**: `https://api.lingafriq.com`

**To override during build**:
```bash
flutter build apk --dart-define=BACKEND_URL=http://your-backend-url:4000
```

### 2. Test Connectivity Programmatically

Use the `ConnectivityVerification` utility:

```dart
import 'package:lingafriq/utils/connectivity_verification.dart';

// Quick check
final isConnected = await ConnectivityVerification.isBackendReachable();

// Detailed status
final status = await ConnectivityVerification.getStatus();

// Print to console (for debugging)
await ConnectivityVerification.printStatus();
```

### 3. Test Specific Endpoints

```dart
// Test loading screen endpoint
final loadingScreenOk = await ConnectivityVerification.testEndpoint('api/loading-screen');

// Test login endpoint
final loginOk = await ConnectivityVerification.testEndpoint('auth/jwt/create/');

// Test onboarding endpoint
final onboardingOk = await ConnectivityVerification.testEndpoint('onboarding/check-username?username=test');
```

## Common Issues and Solutions

### Issue 1: "No internet connection" error (but internet is working)

**Cause**: The error handler is misclassifying backend connection failures as network errors.

**Solution**: The error handler has been improved to better distinguish:
- **Network errors**: DNS failures, no route to host, network unreachable
- **Backend errors**: Connection refused, timeouts, server errors

### Issue 2: Backend URL is incorrect

**Symptoms**:
- All API calls fail with connection errors
- "Cannot connect to server" messages

**Solution**:
1. Verify the backend is running: `curl http://your-backend-url:4000/healthcheck`
2. Check the configured URL in the app matches the actual backend URL
3. For local testing, use: `--dart-define=BACKEND_URL=http://10.0.2.2:4000` (Android emulator)
4. For physical device, use your computer's IP: `--dart-define=BACKEND_URL=http://192.168.1.X:4000`

### Issue 3: Backend is running but endpoints return 404

**Symptoms**:
- Backend health check succeeds
- Specific endpoints return 404

**Solution**:
1. Verify the endpoint path matches the backend route
2. Check backend logs for route registration
3. Ensure backend has been rebuilt after route changes: `npm run build` in backend

### Issue 4: SSL/Certificate errors

**Symptoms**:
- "Security certificate error" messages
- Connection fails with certificate errors

**Solution**:
1. If using HTTP (not HTTPS) locally, ensure URL uses `http://` not `https://`
2. For production, ensure backend has valid SSL certificate
3. Check nginx/proxy configuration if using reverse proxy

## Testing Checklist

- [ ] Backend is running and accessible
- [ ] Backend URL is correctly configured in app
- [ ] Internet connectivity test passes
- [ ] Backend health check passes (`/healthcheck`)
- [ ] Loading screen endpoint works (`/api/loading-screen`)
- [ ] Login endpoint is accessible (`/auth/jwt/create/`)
- [ ] Onboarding endpoint works (`/onboarding/check-username`)

## Debugging Steps

1. **Check backend URL**:
   ```dart
   debugPrint('Backend URL: ${Api.baseurl}');
   debugPrint('From EnvConfig: ${EnvConfig.backendBaseUrl}');
   ```

2. **Run connectivity test**:
   ```dart
   await ConnectivityVerification.printStatus();
   ```

3. **Check backend logs**:
   ```bash
   pm2 logs lingafriq-backend --lines 50
   ```

4. **Test backend directly**:
   ```bash
   curl http://your-backend-url:4000/healthcheck
   curl http://your-backend-url:4000/api/loading-screen
   ```

## Expected Backend Endpoints

| Endpoint | Method | Purpose | Auth Required |
|----------|--------|---------|---------------|
| `/healthcheck` | GET | Health check | No |
| `/api/loading-screen` | GET | Loading screen content | No |
| `/auth/jwt/create/` | POST | Login | No |
| `/auth/jwt/refresh/` | POST | Refresh token | No |
| `/onboarding/check-username` | GET | Check username availability | No |
| `/onboarding/placement-test/generate` | POST | Generate placement test | No |

## Next Steps

If connectivity issues persist:

1. Verify backend is running and accessible from your network
2. Check firewall/network settings
3. Verify backend URL configuration
4. Check backend logs for errors
5. Test endpoints directly with curl/Postman
6. Review error messages in app logs

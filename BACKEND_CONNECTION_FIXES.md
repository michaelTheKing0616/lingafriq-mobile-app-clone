# Backend Connection Fixes - January 28, 2026

## Issues Identified

### 1. **Wrong Health Endpoint** ❌
**Location**: `lib/services/backend_health_service.dart` (line 66)

**Problem**: The app was checking `health/` but the backend uses `/healthcheck`

**Impact**: Health checks were failing, causing the app to incorrectly report backend as unreachable even when it was online.

**Fix**: Changed from `'${Api.baseurl}health/'` to `'${Api.baseurl}healthcheck'`

### 2. **Incorrect Default Backend URL** ❌
**Location**: `lib/services/env_config.dart` (line 45)

**Problem**: Default backend URL was set to `https://api.lingafriq.com` but the actual production server is at `https://admin.lingafriq.com` (as configured in nginx)

**Impact**: If `BACKEND_URL` wasn't explicitly set during build, the app would try to connect to the wrong server, causing all API calls to fail.

**Fix**: Updated default from `https://api.lingafriq.com` to `https://admin.lingafriq.com`

## Backend Server Configuration

From the server logs and nginx config:
- **Server**: `admin.lingafriq.com` (or IP `104.248.26.163`)
- **Port**: 4000 (proxied through nginx on ports 80/443)
- **Health Endpoint**: `/healthcheck` (returns `{ok: true}`)
- **Protocol**: HTTPS (with SSL certificate)

## Files Modified

1. `lib/services/backend_health_service.dart`
   - Fixed health endpoint path

2. `lib/services/env_config.dart`
   - Updated default backend URL

## Verification

The backend logs show successful health check requests:
```
GET /healthcheck
Status: 200
Response: {ok: true}
```

## Next Steps

1. **Build the app** with the updated code
2. **Verify connection** by checking app logs for successful health checks
3. **Test login flow** - should now connect successfully to backend
4. **Test onboarding flow** - should now trigger correctly

## Notes

- The fixes are applied in both the main repo (`mobile-app-main`) and intermediary repo (`mobile-app-safe-push-michael`)
- If you need to override the backend URL during build, use: `--dart-define=BACKEND_URL=https://admin.lingafriq.com`
- The health check endpoint is now correctly pointing to `/healthcheck` which matches the backend route defined in `src/routes/index.route.ts`

# Backend Communication Verification Guide

## Date: January 23, 2026
## Purpose: Verify frontend can communicate with backend

---

## ✅ Frontend Configuration Analysis

### 1. API Base URL Configuration
**Location**: `lib/utils/api.dart` and `lib/services/env_config.dart`

**Current Setup**:
- Base URL is configured via `EnvConfig.backendBaseUrl`
- Default: `https://api.lingafriq.com`
- Can be overridden via `--dart-define=BACKEND_URL=<your-url>` during build
- The `Api.baseurl` getter ensures URL ends with `/`

**Expected Format**: `https://api.lingafriq.com/` (with trailing slash)

### 2. HTTP Client Configuration
**Location**: `lib/providers/dio_provider.dart`

**Settings**:
- ✅ Base URL: `Api.baseurl`
- ✅ Connect Timeout: 120 seconds
- ✅ Send Timeout: 120 seconds  
- ✅ Receive Timeout: 120 seconds
- ✅ Automatic token injection via interceptor
- ✅ Token refresh on 401 errors
- ✅ Rate limit handling (429 errors)

### 3. Authentication Flow
**Location**: `lib/providers/dio_provider.dart` (lines 40-61)

**How it works**:
1. Token is loaded from `SharedPreferences` on app start
2. Token is automatically added to all requests (except auth endpoints)
3. On 401 error, token is automatically refreshed
4. If refresh fails, user is logged out

---

## 🔍 Endpoint Mapping Verification

### Critical Onboarding Endpoints

| Frontend Call | Backend Route | Full Backend Path | Status |
|--------------|---------------|-------------------|--------|
| `${Api.baseurl}onboarding/check-username` | `GET /onboarding/check-username` | `/onboarding/check-username` | ✅ **VERIFIED** |
| `${Api.baseurl}api/onboarding/save/` | `POST /api/onboarding/save/` | `/api/onboarding/save/` | ✅ **VERIFIED** |
| `ApiService.post('/onboarding/placement-test')` | `POST /onboarding/placement-test` | `/onboarding/placement-test` | ⚠️ **NEEDS CHECK** |
| `ApiService.post('/onboarding/profile-setup')` | `POST /onboarding/profile-setup` | `/onboarding/profile-setup` | ⚠️ **NEEDS CHECK** |
| `ApiService.post('/onboarding/schedule-preferences')` | `POST /onboarding/schedule-preferences` | `/onboarding/schedule-preferences` | ⚠️ **NEEDS CHECK** |

**Note**: `ApiService` uses relative paths that are appended to `baseUrl` from `EnvConfig.backendBaseUrl`.

---

## 🧪 Backend Testing Checklist

### Step 1: Verify Backend is Running
```bash
# Test health endpoint
curl http://localhost:4000/healthcheck
# OR if using production URL
curl https://api.lingafriq.com/healthcheck
```

**Expected Response**: `{"ok": true}`

---

### Step 2: Test Username Check Endpoint (No Auth Required)

```bash
# Test with available username
curl "http://localhost:4000/onboarding/check-username?username=testuser123"

# Test with taken username (if you have test data)
curl "http://localhost:4000/onboarding/check-username?username=existinguser"
```

**Expected Responses**:
```json
// Available username
{
  "success": true,
  "data": {
    "username": "testuser123",
    "available": true
  }
}

// Taken username
{
  "success": true,
  "data": {
    "username": "existinguser",
    "available": false
  }
}
```

**If this fails**, check:
- ✅ Backend server is running
- ✅ Route is registered in `src/routes/index.route.ts` (line 141)
- ✅ Controller function `checkUsernameAvailability` exists in `src/controllers/onboarding.controller.ts`
- ✅ No CORS issues (if testing from browser)

---

### Step 3: Test Onboarding Save Endpoint (Auth Required)

**First, get a valid JWT token**:
```bash
# Login to get token
curl -X POST http://localhost:4000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'
```

**Then test the endpoint**:
```bash
# Replace YOUR_TOKEN with actual JWT token
curl -X POST http://localhost:4000/api/onboarding/save/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "step": "learning_language",
    "data": {
      "language": "swahili"
    }
  }'
```

**Expected Response**: `{"success": true, ...}`

**If this fails**, check:
- ✅ Token is valid and not expired
- ✅ Route is registered in `src/routes/sync.route.ts` (line 120)
- ✅ Middleware `requireSignin` and `getIdFromJWT` are working
- ✅ Database connection is working

---

### Step 4: Test Other Onboarding Endpoints (Auth Required)

```bash
# Test placement test submission
curl -X POST http://localhost:4000/onboarding/placement-test \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "placement_test_results": {
      "cefr_level": "A1",
      "score": 75
    }
  }'

# Test profile setup
curl -X POST http://localhost:4000/onboarding/profile-setup \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "username": "testuser",
    "avatar_path": "https://example.com/avatar.jpg"
  }'

# Test schedule preferences
curl -X POST http://localhost:4000/onboarding/schedule-preferences \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "daily_duration_minutes": 30,
    "preferred_time_of_day": "morning",
    "reminders_enabled": true
  }'
```

---

### Step 5: Test CORS Configuration (If Testing from Browser)

The backend should allow requests from your mobile app's origin. Check:
- ✅ CORS middleware is configured in `src/app.ts`
- ✅ Mobile app origin is whitelisted
- ✅ Credentials are allowed if needed

---

## 🐛 Common Issues & Solutions

### Issue 1: "Connection Timeout" or "Network Error"
**Possible Causes**:
- Backend server is not running
- Wrong base URL in frontend
- Firewall blocking connection
- Backend is running on different port

**Solution**:
1. Verify backend is running: `curl http://localhost:4000/healthcheck`
2. Check frontend `EnvConfig.backendBaseUrl` matches backend URL
3. If using nginx, verify reverse proxy is configured correctly

---

### Issue 2: "401 Unauthorized"
**Possible Causes**:
- Token is missing or expired
- Token format is incorrect
- Middleware is rejecting valid tokens

**Solution**:
1. Check token is being sent: Look for `Authorization: Bearer <token>` in request headers
2. Verify token is valid: Decode JWT and check expiration
3. Test token refresh endpoint: `POST /auth/refresh` with refresh token

---

### Issue 3: "404 Not Found"
**Possible Causes**:
- Route path mismatch
- Route not registered
- Wrong HTTP method (GET vs POST)

**Solution**:
1. Verify route exists in `src/routes/index.route.ts`
2. Check route path matches exactly (case-sensitive)
3. Verify HTTP method matches (GET, POST, etc.)

---

### Issue 4: "500 Internal Server Error"
**Possible Causes**:
- Database connection issue
- Controller function error
- Missing environment variables

**Solution**:
1. Check backend logs for error details
2. Verify database is connected
3. Check all required environment variables are set

---

## 📋 Quick Verification Script

Run this in your backend directory to test all endpoints:

```bash
#!/bin/bash

BASE_URL="http://localhost:4000"
# Or use: BASE_URL="https://api.lingafriq.com"

echo "Testing Backend Communication..."
echo ""

# 1. Health check
echo "1. Health Check:"
curl -s "$BASE_URL/healthcheck" | jq .
echo ""

# 2. Username check (no auth)
echo "2. Username Check (no auth):"
curl -s "$BASE_URL/onboarding/check-username?username=testuser" | jq .
echo ""

# 3. Get auth token (replace with real credentials)
echo "3. Getting Auth Token:"
TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "YOUR_EMAIL", "password": "YOUR_PASSWORD"}' | jq -r '.accessToken // .access // .token')
echo "Token: ${TOKEN:0:50}..."
echo ""

# 4. Test authenticated endpoints (if token obtained)
if [ ! -z "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
  echo "4. Testing Onboarding Save:"
  curl -s -X POST "$BASE_URL/api/onboarding/save/" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"step": "test", "data": {}}' | jq .
  echo ""
fi

echo "Verification complete!"
```

---

## ✅ What to Confirm on Backend

1. **Server is Running**: `curl http://localhost:4000/healthcheck` returns `{"ok": true}`

2. **Username Check Works**: 
   ```bash
   curl "http://localhost:4000/onboarding/check-username?username=test"
   ```
   Returns JSON with `available: true` or `available: false`

3. **Onboarding Save Works** (with valid token):
   ```bash
   curl -X POST http://localhost:4000/api/onboarding/save/ \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{"step": "test", "data": {}}'
   ```
   Returns success response

4. **Other Onboarding Endpoints Work**:
   - `/onboarding/placement-test` (POST)
   - `/onboarding/profile-setup` (POST)
   - `/onboarding/schedule-preferences` (POST)

5. **CORS is Configured** (if testing from browser/emulator):
   - Backend allows requests from mobile app origin
   - Headers are properly set

6. **Database is Connected**:
   - MongoDB connection is active
   - User queries work

---

## 🎯 Summary

**Frontend is configured correctly** ✅:
- Base URL is configurable via environment
- HTTP client has proper timeouts
- Authentication is handled automatically
- Error handling is in place

**What you need to verify on backend**:
1. ✅ Server is running and accessible
2. ✅ `/onboarding/check-username` endpoint works (no auth)
3. ✅ `/api/onboarding/save/` endpoint works (with auth)
4. ✅ Other onboarding endpoints work (with auth)
5. ✅ CORS is configured (if needed)
6. ✅ Database is connected and working

**If all backend tests pass**, the frontend should be able to communicate successfully! 🎉

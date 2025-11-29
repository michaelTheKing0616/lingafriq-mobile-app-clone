# Backend Integration Status

## Current Status: **READY BUT DISABLED BY DEFAULT**

The backend integration for the loading screen is **fully implemented** but **disabled by default**. The app currently uses local static content, but can be switched to use the backend API.

## What's Already Integrated

### ✅ Backend (Node.js)
- **Database Model**: `LoadingScreenContent` model created in MongoDB
- **API Endpoints**: 
  - `GET /api/loading-screen` - Get random content (excludes user's viewed items)
  - `GET /api/loading-screen/country/:country` - Filter by country
  - `GET /api/loading-screen/language/:language` - Filter by language
- **User Tracking**: User model tracks `lastLoadingContentId` and `viewedLoadingContent` array
- **Authentication**: All endpoints require JWT authentication
- **Route Registration**: Routes are registered in the main router

### ✅ Flutter App
- **API Method**: `getLoadingScreenContent()` added to `ApiProvider`
- **Provider Updated**: `LoadingScreenProvider` supports both local and backend content
- **Feature Flag**: `use_backend_loading_content` flag in SharedPreferences
- **Fallback**: If backend fails, automatically falls back to local content
- **API Endpoint**: Correctly configured as `api/loading-screen`

## How It Works

### Current Flow (Local Content - Default)
```
App Launch
  ↓
LoadingScreenProvider._loadContent()
  ↓
Checks: use_backend_loading_content = false (default)
  ↓
Uses: LoadingScreenContentData.defaultContent (static list)
  ↓
Selects random content (excluding recently viewed)
  ↓
Saves to SharedPreferences
  ↓
Displays content
```

### Backend Flow (When Enabled)
```
App Launch
  ↓
LoadingScreenProvider._loadContent()
  ↓
Checks: use_backend_loading_content = true
  ↓
Calls: ApiProvider.getLoadingScreenContent()
  ↓
HTTP GET: /api/loading-screen
  Headers: Authorization: JWT <token>
  ↓
Backend:
  - Validates JWT token
  - Gets user's viewed content from database
  - Queries MongoDB for available content
  - Excludes user's recently viewed items
  - Returns random content
  - Updates user's viewed content in database
  ↓
Flutter receives JSON response
  ↓
Converts to LoadingScreenContent model
  ↓
Updates state
  ↓
Displays content
```

## How to Enable Backend Integration

### Option 1: Enable in Code (For Testing)
Add this to your app initialization (e.g., in `main.dart` or after login):

```dart
// After user logs in
ref.read(loadingScreenProvider.notifier).setUseBackend(true);
```

### Option 2: Enable via Settings Screen
Add a toggle in your settings screen:

```dart
SwitchListTile(
  title: Text('Use Backend Loading Content'),
  value: ref.watch(loadingScreenProvider.notifier).useBackend,
  onChanged: (value) {
    ref.read(loadingScreenProvider.notifier).setUseBackend(value);
  },
)
```

### Option 3: Enable for All Users (Production)
Change the default in `loading_screen_provider.dart`:

```dart
// Change this line:
final useBackend = _prefs.getBool(_useBackendKey) ?? false;

// To this:
final useBackend = _prefs.getBool(_useBackendKey) ?? true; // Default to true
```

## Prerequisites for Backend Integration

### 1. Backend Must Be Running
- Node.js backend server must be running
- MongoDB must be connected
- API endpoint `/api/loading-screen` must be accessible

### 2. Content Must Be in Database
Before enabling backend, you need to populate the database with content:

```javascript
// Example: Add content to MongoDB
db.loadingScreenContent.insertMany([
  {
    id: "swahili_kenya_1",
    country: "Kenya",
    countryFlag: "🇰🇪",
    greeting: "Karibu!",
    greetingTranslation: "Welcome!",
    language: "Swahili",
    fact: "Did you know? 'Jambo' is a common Swahili greeting used across East Africa.",
    imageUrl: "https://cdn.lingafriq.com/images/loading/swahili_kenya_1.png",
    isPublished: true,
    isFeatured: false
  },
  // ... more content
]);
```

### 3. User Authentication Required
- User must be logged in (JWT token required)
- Token is automatically added by `DioInterceptor` in `dio_provider.dart`

## Testing Backend Integration

### Step 1: Verify Backend Endpoint
```bash
# Test with curl (replace <JWT_TOKEN> with actual token)
curl -X GET http://admin.lingafriq.com/api/loading-screen \
  -H "Authorization: JWT <JWT_TOKEN>"
```

### Step 2: Enable in App
```dart
// In your app, after login:
ref.read(loadingScreenProvider.notifier).setUseBackend(true);
```

### Step 3: Check Logs
- Backend logs should show API calls
- Flutter logs should show content loading
- If backend fails, check console for fallback message

## Migration from Local to Backend

### Phase 1: Parallel Running (Current)
- Backend ready but disabled
- Local content works as before
- No breaking changes

### Phase 2: Gradual Rollout
1. Enable for beta testers
2. Monitor backend performance
3. Fix any issues
4. Gradually enable for more users

### Phase 3: Full Migration
1. Enable by default for all users
2. Keep local content as fallback
3. Eventually remove local content (optional)

## Troubleshooting

### Backend Not Working?
1. **Check Backend Status**: Is the server running?
2. **Check Authentication**: Is user logged in?
3. **Check Database**: Is content in MongoDB?
4. **Check Logs**: Look for error messages
5. **Fallback**: App automatically uses local content if backend fails

### Content Not Rotating?
- Backend tracks viewed content per user
- If all content viewed, backend resets automatically
- Check user's `viewedLoadingContent` array in database

### API Errors?
- Check network connectivity
- Verify JWT token is valid
- Check backend logs for errors
- Verify API endpoint path is correct

## Next Steps

1. **Populate Database**: Add loading screen content to MongoDB
2. **Test Backend**: Enable for a test user and verify
3. **Monitor Performance**: Check response times and errors
4. **Enable Gradually**: Roll out to more users
5. **Add AI Images**: Integrate AI image generation (future)

## Summary

✅ **Backend is fully integrated and ready**
✅ **App supports both local and backend content**
✅ **Automatic fallback if backend fails**
✅ **Feature flag allows easy enable/disable**
⏸️ **Currently disabled by default (using local content)**

To enable: Set `use_backend_loading_content = true` in SharedPreferences or change the default in code.


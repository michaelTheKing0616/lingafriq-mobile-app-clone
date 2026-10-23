# Network Error Recovery Integration Guide

## ✅ Network Helper Created

### `lib/utils/network_helper.dart`
**World-class network helper utility with error recovery and performance tracking**

**Features:**
- ✅ Automatic error recovery with retry logic
- ✅ Performance tracking for all requests
- ✅ Consistent error handling
- ✅ Offline operation handling
- ✅ Graceful degradation support
- ✅ Sentry integration for error logging

## Usage Examples

### Example 1: Replace Direct Dio Calls

**Before:**
```dart
final response = await dio.get('/api/users');
```

**After:**
```dart
import 'package:lingafriq/utils/network_helper.dart';

final response = await NetworkHelper.get(
  dio,
  '/api/users',
  operationName: 'get_users',
  maxRetries: 3,
);
```

### Example 2: POST Request with Error Recovery

**Before:**
```dart
try {
  final response = await dio.post('/api/messages', data: messageData);
  return response.data;
} catch (e) {
  // Handle error
  return null;
}
```

**After:**
```dart
import 'package:lingafriq/utils/network_helper.dart';

final response = await NetworkHelper.post(
  dio,
  '/api/messages',
  data: messageData,
  operationName: 'send_message',
  maxRetries: 3,
  fallbackResponse: null,
);
return response.data;
```

### Example 3: With Offline Handling

```dart
import 'package:lingafriq/utils/network_helper.dart';

final data = await NetworkHelper.executeWithOfflineHandling(
  onlineOperation: () async {
    final response = await NetworkHelper.get(dio, '/api/data');
    return response.data;
  },
  offlineOperation: () async {
    // Load from local cache
    return await loadFromCache();
  },
  operationName: 'get_data',
);
```

### Example 4: With Graceful Degradation

```dart
import 'package:lingafriq/utils/network_helper.dart';

final result = await NetworkHelper.executeWithGracefulDegradation(
  primaryOperation: () async {
    // Try primary API
    final response = await NetworkHelper.get(dio, '/api/v2/data');
    return response.data;
  },
  fallbackOperation: () async {
    // Fallback to older API
    final response = await NetworkHelper.get(dio, '/api/v1/data');
    return response.data;
  },
  operationName: 'get_data',
);
```

## Integration Steps

### Step 1: Import Network Helper
```dart
import 'package:lingafriq/utils/network_helper.dart';
```

### Step 2: Replace Direct Dio Calls
Find all instances of:
- `dio.get(...)`
- `dio.post(...)`
- `dio.put(...)`
- `dio.delete(...)`
- `dio.patch(...)`

Replace with:
- `NetworkHelper.get(dio, ...)`
- `NetworkHelper.post(dio, ...)`
- `NetworkHelper.put(dio, ...)`
- `NetworkHelper.delete(dio, ...)`
- `NetworkHelper.patch(dio, ...)`

### Step 3: Add Operation Names
Always provide an `operationName` for better tracking:
```dart
NetworkHelper.get(dio, '/api/users', operationName: 'get_users');
```

### Step 4: Configure Retry Logic (Optional)
```dart
NetworkHelper.get(
  dio,
  '/api/users',
  operationName: 'get_users',
  maxRetries: 5, // Custom retry count
  shouldRetry: (error) {
    // Custom retry logic
    return error is DioException && error.type == DioExceptionType.connectionTimeout;
  },
);
```

## Services to Update

Priority services for integration:

1. **High Priority:**
   - `historical_personality_service.dart`
   - `user_generated_content_service.dart`
   - `account_service.dart`
   - `voice_api_service.dart`
   - `advanced_pronunciation_service.dart`

2. **Medium Priority:**
   - `tribes_service.dart`
   - `leaderboards_service.dart`
   - `curriculum_service.dart`
   - `vocabulary_service.dart`
   - `culture_magazine_service.dart`

3. **Low Priority:**
   - `sound_effects_service.dart`
   - `telemetry_service.dart`
   - `polie_cache_service.dart`

## Benefits

✅ **Automatic Error Recovery:**
- Retry failed requests automatically
- Exponential backoff
- Intelligent retry strategy

✅ **Performance Tracking:**
- Track all network operations
- Identify slow endpoints
- Optimize based on metrics

✅ **Better Error Handling:**
- Consistent error handling across app
- Sentry integration
- User-friendly error messages

✅ **Offline Support:**
- Graceful offline handling
- Cache fallback support
- Better user experience

## Status

- ✅ Network Helper Created
- ✅ Error Recovery Integrated
- ✅ Performance Tracking Integrated
- ⏳ Service Integration: **In Progress**
- ⏳ Testing: **Pending**

## Next Steps

1. **Integrate into High Priority Services** - Update critical services first
2. **Test Error Recovery** - Verify retry logic works
3. **Monitor Performance** - Check performance metrics
4. **Update Remaining Services** - Complete integration across all services


# ErrorHandler Integration Guide

## Overview

This guide explains how to integrate ErrorHandler (ErrorBoundary) across all screens in the app to achieve 100% coverage.

## Current Status

- **Total Screens**: ~88
- **Screens with ErrorHandler**: ~78% (estimated ~69 screens)
- **Remaining**: ~19 screens need integration

## Quick Integration Methods

### Method 1: Using ScreenWrapper (Recommended)

Wrap your screen's body with `ScreenWrapper`:

```dart
import 'package:your_app/utils/screen_helpers.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Screen')),
      body: ScreenWrapper(
        onRetry: () {
          // Retry logic
          setState(() {});
        },
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Your screen content
    return ListView(
      children: [
        // ... widgets
      ],
    );
  }
}
```

### Method 2: Using ErrorBoundary Directly

Import and wrap content:

```dart
import 'package:your_app/core/errors/global_error_handler.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Screen')),
      body: ErrorBoundary(
        onRetry: () => setState(() {}),
        child: _buildContent(context),
      ),
    );
  }
}
```

### Method 3: Using Extension Methods (For StatefulWidget)

```dart
import 'package:your_app/utils/screen_helpers.dart';

class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Screen')),
      body: withErrorBoundary(
        _buildContent(context),
        onRetry: () => setState(() {}),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Your content
  }
}
```

### Method 4: Safe Async Operations

For async operations, use the `safeAsync` extension:

```dart
class _MyScreenState extends State<MyScreen> {
  Future<void> loadData() async {
    await safeAsync(
      () async {
        // Your async operation
        final data = await api.fetchData();
        setState(() {
          _data = data;
        });
      },
      onError: (error) {
        // Custom error handling
        print('Error: $error');
      },
      onRetry: loadData,
    );
  }
}
```

## Integration Checklist

### Priority 1: Critical Screens (Complete First)
- [ ] Authentication screens (login, signup, forgot password)
- [ ] Dashboard screens
- [ ] Payment/subscription screens
- [ ] Chat screens (real-time operations)

### Priority 2: Core Features
- [ ] Lesson screens
- [ ] Quiz screens
- [ ] Progress tracking screens
- [ ] Profile screens

### Priority 3: Secondary Features
- [ ] Games screens
- [ ] Social features
- [ ] Settings screens
- [ ] Help/onboarding screens

## Automated Integration Script

For bulk integration, you can use the following pattern:

1. Find all screen files:
   ```bash
   find lib/screens -name "*_screen.dart" -type f
   ```

2. Add import at the top:
   ```dart
   import '../utils/screen_helpers.dart';
   ```

3. Wrap body/content:
   ```dart
   body: ScreenWrapper(
     child: // existing body content
   ),
   ```

## Testing Error Handling

After integration, test error scenarios:

1. **Network errors**: Disconnect network and trigger API calls
2. **Null errors**: Pass null values where not expected
3. **Parse errors**: Return invalid JSON from API
4. **State errors**: Trigger errors during widget build

## Error Recovery Patterns

### Retry Pattern
```dart
ScreenWrapper(
  onRetry: () {
    // Reload data
    _loadData();
  },
  child: // content
)
```

### Graceful Degradation
```dart
ErrorBoundary(
  fallback: Center(
    child: Column(
      children: [
        Icon(Icons.error),
        Text('Unable to load content'),
        ElevatedButton(
          onPressed: () => Navigator.pop(),
          child: Text('Go Back'),
        ),
      ],
    ),
  ),
  child: // content
)
```

## Files That Need Integration

### High Priority
- `lib/screens/auth/*_screen.dart` (if not already integrated)
- `lib/screens/dashboard/*_screen.dart`
- `lib/screens/subscription/*_screen.dart`

### Medium Priority
- `lib/screens/games/*_screen.dart`
- `lib/screens/social/*_screen.dart`
- `lib/screens/tutor/*_screen.dart`

### Low Priority
- `lib/screens/help/*_screen.dart`
- `lib/screens/loading/*_screen.dart`
- `lib/screens/examples/*_screen.dart` (if applicable)

## Notes

- ErrorBoundary catches errors during widget build, but NOT async errors
- Use `safeAsync` for async operations
- Always provide `onRetry` callback for better UX
- Test error scenarios after integration
- Monitor error logs to identify common issues

## Progress Tracking

Update this list as you integrate:

- [x] GlobalErrorHandler at app root (already done)
- [ ] Individual screen error boundaries (~19 remaining)
- [ ] Async error handling in critical flows
- [ ] Error analytics integration

# Quick Start Integration Guide
## Get Started with Implementations in 30 Minutes

**Priority:** Start here to get everything working quickly

---

## Step 1: Backend Route Registration (5 minutes)

**File:** `src/routes/v1/index.route.ts`

Add these imports:
```typescript
import pronunciationRouter from '../pronunciation.route.js';
import historicalPersonalityRouter from '../historicalPersonality.route.js';
```

Add these routes:
```typescript
// Pronunciation routes
router.use('/pronunciation', pronunciationRouter);

// Historical Personality routes
router.use('/personalities', historicalPersonalityRouter);
```

---

## Step 2: Initialize Sentry (5 minutes)

**File:** `lib/main.dart`

Add import:
```dart
import 'services/monitoring/sentry_service.dart';
import 'config/secrets_manager.dart';
```

In `main()` function, before `runApp()`:
```dart
// Initialize Secrets Manager
await SecretsManager().initialize();

// Initialize Sentry
await SentryService().initialize(
  dsn: SecretsManager().sentryDsn ?? '',
  environment: kDebugMode ? 'development' : 'production',
  enablePerformanceMonitoring: true,
);
```

---

## Step 3: Update Environment Variables (5 minutes)

**File:** `.env` (create if doesn't exist)

Add:
```
SENTRY_DSN=your_sentry_dsn_here
BACKEND_API_URL=https://api.lingafriq.com
```

**Backend:** Update `.env` with all required keys (see `.env.example`)

---

## Step 4: Test New Features (15 minutes)

### Test Historical Personalities:
1. Navigate to personality selection screen
2. Select a personality
3. Start a chat
4. Verify conversation works

### Test Advanced Pronunciation:
1. Go to pronunciation screen
2. Record audio
3. Verify analysis works
4. Check real-time feedback

### Test Error Tracking:
1. Trigger an error (disconnect network, etc.)
2. Check Sentry dashboard
3. Verify error is logged

---

## Step 5: Start Systematic Integration

### ErrorHandler Integration:
- Start with `lib/screens/auth/login_screen.dart`
- Follow pattern from `lib/screens/examples/errorhandler_integration_example.dart`
- Continue systematically through all screens

### Performance Utilities:
- Start with search screens
- Follow pattern from `lib/screens/examples/performance_utilities_example.dart`
- Continue systematically

---

## ✅ Quick Checklist

- [ ] Backend routes registered
- [ ] Sentry initialized
- [ ] Secrets Manager initialized
- [ ] Environment variables set
- [ ] Test new features
- [ ] Start ErrorHandler integration
- [ ] Start Performance utilities integration

---

**Time Required:** 30 minutes for setup, then systematic integration

**Status:** Ready to integrate!


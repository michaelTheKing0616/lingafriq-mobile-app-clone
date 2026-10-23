# 🔄 Backend Integration Plan - Complete Implementation

## 📋 **CURRENT STATE ANALYSIS**

### **Data Currently Stored Locally (Should Sync to Backend)**

1. **Gamification Data** (`gamification_provider.dart`)
   - XP, Level, Titles
   - Currencies (Ngwenya, Cowries, Ancestral Beads)
   - Daily Streaks
   - Unlocked Badges
   - Tribe Selection
   - Active Boosters
   - ❌ **NOT SYNCED** - Only local SharedPreferences

2. **Game Sessions** (`game_provider.dart`)
   - Game sessions (start, turns, completion)
   - SRS data (card ease, repetitions, intervals)
   - Telemetry events
   - ❌ **NOT SYNCED** - Only local storage

3. **AI Chat Data** (`ai_chat_provider_groq.dart`)
   - Chat history (per mode)
   - SRS memory (WordMemory)
   - CEFR tracking
   - ❌ **PARTIALLY SYNCED** - Only chat history has backend sync

4. **Progress Tracking** (`progress_tracking_provider.dart`)
   - Lesson completions
   - Quiz scores
   - Activity logs
   - ❌ **NOT SYNCED** - Only local

5. **Onboarding Data** (`onboarding_provider.dart`)
   - User preferences
   - Learning goals
   - Accessibility settings
   - ❌ **NOT SYNCED** - Only local

6. **User Profile** (`user_provider.dart`)
   - ✅ **SYNCED** - Already has backend integration

7. **Leaderboards** (`leaderboard_provider.dart`)
   - ❌ **NOT SYNCED** - Only local mock data

8. **Quests** (`quest_provider.dart`)
   - Quest progress
   - Chapter unlocks
   - ❌ **NOT SYNCED** - Only local

---

## 🎯 **BACKEND ENDPOINTS NEEDED**

### **Gamification Endpoints**
```
POST /api/gamification/sync
GET  /api/gamification/user/:userId
PUT  /api/gamification/user/:userId
POST /api/gamification/badges/unlock
GET  /api/gamification/leaderboard
```

### **Game Endpoints**
```
POST /api/games/session/start
POST /api/games/session/:sessionId/turn
POST /api/games/session/:sessionId/complete
GET  /api/games/srs/user/:userId
PUT  /api/games/srs/user/:userId
POST /api/games/telemetry
```

### **AI Chat Endpoints**
```
POST /api/ai/chat/history
GET  /api/ai/chat/history/:mode
PUT  /api/ai/chat/srs
GET  /api/ai/chat/cefr/:userId
```

### **Progress Endpoints**
```
POST /api/progress/activity
GET  /api/progress/user/:userId
POST /api/progress/lesson/complete
POST /api/progress/quiz/complete
```

### **Onboarding Endpoints**
```
POST /api/onboarding/save
GET  /api/onboarding/user/:userId
```

---

## 🔧 **IMPLEMENTATION PLAN**

### **Phase 1: Backend Sync Infrastructure**
1. Create `BackendSyncProvider` for centralized sync management
2. Implement retry logic with exponential backoff
3. Implement offline queue for failed syncs
4. Add sync status indicators

### **Phase 2: Gamification Sync**
1. Sync XP, levels, currencies on every change
2. Sync badges on unlock
3. Sync streaks daily
4. Fetch leaderboard data from backend

### **Phase 3: Game Data Sync**
1. Sync game sessions in real-time
2. Sync SRS data after each game
3. Batch telemetry events
4. Fetch game cards from backend

### **Phase 4: AI Chat Sync**
1. Sync chat history per mode
2. Sync SRS memory
3. Sync CEFR progress
4. Fetch roleplay scenarios from backend

### **Phase 5: Progress Sync**
1. Sync lesson completions
2. Sync quiz results
3. Sync activity logs
4. Fetch progress analytics

### **Phase 6: Onboarding Sync**
1. Sync onboarding data on completion
2. Fetch user preferences on login
3. Sync accessibility settings

---

## 📝 **FILES TO CREATE/MODIFY**

### **New Files**
1. `lib/providers/backend_sync_provider.dart` - Centralized sync
2. `lib/services/offline_queue_service.dart` - Offline queue
3. `lib/models/sync_status_model.dart` - Sync status tracking

### **Files to Modify**
1. `lib/providers/gamification_provider.dart` - Add backend sync
2. `lib/providers/game_provider.dart` - Add backend sync
3. `lib/providers/ai_chat_provider_groq.dart` - Enhance backend sync
4. `lib/providers/progress_tracking_provider.dart` - Add backend sync
5. `lib/providers/onboarding_provider.dart` - Add backend sync
6. `lib/providers/api_provider.dart` - Add new endpoints

---

## ✅ **BEST PRACTICES TO IMPLEMENT**

1. **Offline-First Architecture**
   - All data stored locally first
   - Sync in background
   - Queue failed syncs
   - Retry with exponential backoff

2. **Data Consistency**
   - Use timestamps for conflict resolution
   - Last-write-wins for simple data
   - Merge strategies for complex data

3. **Performance**
   - Batch sync operations
   - Debounce frequent updates
   - Use background sync
   - Compress large payloads

4. **Error Handling**
   - Graceful degradation
   - User-friendly error messages
   - Automatic retry
   - Manual sync option

5. **Security**
   - Encrypt sensitive data
   - Use secure tokens
   - Validate all inputs
   - Rate limiting

---

## 🚀 **PRIORITY ORDER**

1. **HIGH**: Gamification sync (XP, levels, currencies)
2. **HIGH**: Game sessions and SRS
3. **MEDIUM**: AI chat history and SRS
4. **MEDIUM**: Progress tracking
5. **LOW**: Onboarding data
6. **LOW**: Leaderboards (can be real-time fetch)


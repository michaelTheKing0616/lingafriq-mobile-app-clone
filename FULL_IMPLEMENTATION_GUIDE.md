# Full Implementation Guide - Gamified Social Learning Platform

## 📊 Implementation Status

### ✅ Completed

#### Phase 1: MongoDB Models (100% Complete)
All 14 Mongoose models created in `node-backend-main/src/models/gamification/`:
- ✅ Tribes & Tribe Members
- ✅ Badges & User Badges  
- ✅ Events (canonical event log)
- ✅ Leaderboard Scores
- ✅ Journey Nodes & User Progress
- ✅ Magic Items & User Inventory
- ✅ Competitions & Competition Scores
- ✅ Villages
- ✅ Ancestry (Mentorship)

#### Phase 2: Core Services (50% Complete)
- ✅ Badge Rules Engine (`services/badgeEngine.ts`)
- ✅ Sample Badges JSON (`data/badges.json`)
- ⚠️ Partial: Express Routes (3 of 10+ routes created)

#### Phase 3: Express Routes (30% Complete)
- ✅ `/api/tribes` - Tribe CRUD operations
- ✅ `/api/badges` - Badge management
- ✅ `/api/events` - Event ingestion
- ⚠️ Pending: Leaderboards, Journey, Competitions, Items, Villages, Ancestry, User Lessons

### 🔄 Remaining Work

#### High Priority
1. **Complete Express Routes** (7 more route files needed)
2. **Bull Workers** (5 worker files)
3. **Redis Utilities** (4 utility files)
4. **Socket.io Integration** (Real-time channels)
5. **Flutter Screen Updates** (API integration)

#### Medium Priority
6. **Tests** (Jest unit tests)
7. **Load Testing Scripts**
8. **OpenAPI Documentation**
9. **Migration Scripts**

## 📁 File Structure Created

```
node-backend-main/
├── src/
│   ├── models/
│   │   └── gamification/
│   │       ├── index.ts (exports all models)
│   │       ├── tribe.model.ts
│   │       ├── tribeMember.model.ts
│   │       ├── badge.model.ts
│   │       ├── userBadge.model.ts
│   │       ├── event.model.ts
│   │       ├── leaderboardScore.model.ts
│   │       ├── journeyNode.model.ts
│   │       ├── userJourneyProgress.model.ts
│   │       ├── magicItem.model.ts
│   │       ├── userItem.model.ts
│   │       ├── competition.model.ts
│   │       ├── competitionScore.model.ts
│   │       ├── village.model.ts
│   │       └── ancestry.model.ts
│   ├── services/
│   │   └── badgeEngine.ts (Badge rules engine)
│   ├── routes/
│   │   └── gamification/
│   │       ├── tribes.route.ts
│   │       ├── badges.route.ts
│   │       └── events.route.ts
│   └── data/
│       └── badges.json (Sample badge definitions)
```

## 🚀 Next Steps to Complete Implementation

### Step 1: Complete Express Routes

Create these route files in `src/routes/gamification/`:

1. **leaderboards.route.ts**
   - `GET /api/leaderboards/global?period=weekly`
   - `GET /api/leaderboards/tribe/:tribeId?period=season`
   - `GET /api/leaderboards/village/:lang`

2. **journey.route.ts**
   - `GET /api/journey/:campaign/nodes`
   - `GET /api/journey/:campaign/node/:nodeId`
   - `POST /api/journey/:campaign/node/:nodeId/start`
   - `POST /api/journey/:campaign/node/:nodeId/complete`
   - `GET /api/journey/:userId/progress`

3. **competitions.route.ts**
   - `GET /api/competitions`
   - `POST /api/competitions` (admin)
   - `POST /api/competitions/:id/compute` (admin)
   - `GET /api/competitions/:id/results`

4. **items.route.ts**
   - `GET /api/items`
   - `POST /api/users/:id/items/claim`
   - `POST /api/users/:id/items/use`
   - `GET /api/users/:id/inventory`

5. **villages.route.ts**
   - `GET /api/villages/:lang`
   - `GET /api/villages/:lang/feed`
   - `POST /api/villages/:lang/topic`
   - `POST /api/villages/:lang/faq`

6. **ancestry.route.ts**
   - `GET /api/ancestry/:userId`
   - `POST /api/ancestry/link`
   - `POST /api/ancestry/respond`

7. **userLessons.route.ts** (Send a Lesson)
   - `POST /api/lessons` (create draft)
   - `GET /api/lessons/:id`
   - `POST /api/lessons/:id/publish`
   - `POST /api/lessons/:id/vote`
   - `POST /api/lessons/:id/import-to-srs`
   - `GET /api/lessons/search`

### Step 2: Create Bull Workers

Create in `src/workers/`:

1. **eventProcessor.ts**
   - Process events from queue
   - Update user XP
   - Award badges
   - Update tribe contributions
   - Emit notifications

2. **leaderboardRecompute.ts**
   - Recompute leaderboards (scheduled)
   - Update Redis sorted sets
   - Snapshot to MongoDB

3. **competitionCompute.ts**
   - Compute competition results
   - Apply scoring rules
   - Distribute rewards

4. **badgeEvaluator.ts**
   - Evaluate badge criteria
   - Award badges
   - (Can be part of eventProcessor)

5. **anomalyDetector.ts**
   - Detect suspicious activity
   - Flag accounts for review

### Step 3: Redis Utilities

Create in `src/utils/redis/`:

1. **leaderboard.ts**
   - `incrementScore(leaderboardId, userId, points)`
   - `getRank(leaderboardId, userId)`
   - `getTopN(leaderboardId, n)`
   - `snapshotToMongo(leaderboardId)`

2. **presence.ts**
   - User online/offline tracking
   - Last seen timestamps

3. **rateLimit.ts**
   - Rate limiting middleware
   - Per-user, per-endpoint limits

4. **cache.ts**
   - Generic caching utilities
   - TTL management

### Step 4: Socket.io Integration

Add to `src/socket/`:

1. **channels.ts**
   - Define channel names
   - User notifications
   - Tribe activity
   - Village feeds
   - Leaderboard updates
   - Competition updates

2. **handlers.ts**
   - Socket connection handlers
   - Channel subscriptions
   - Message broadcasting

### Step 5: Flutter Integration

Update existing screens in `mobile-app-main/lib/screens/`:

1. **Update API calls** in existing screens:
   - `badge_collection_screen.dart`
   - `leaderboard_screen.dart`
   - `tribe_selection_screen.dart`
   - `quest_screen.dart`
   - `seasonal_events_screen.dart`
   - `magic_items_screen.dart`
   - `tribe_vs_tribe_screen.dart`
   - `language_villages_screen.dart`
   - `ancestral_tree_screen.dart`

2. **Add Socket.io listeners** for real-time updates

3. **Add error handling** and loading states

4. **Create missing screens**:
   - Send a Lesson screen
   - Lesson Editor
   - Moderator Dashboard (Flutter)

## 🔧 Configuration Needed

### Environment Variables

Add to `.env`:
```env
# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Bull Queue
QUEUE_REDIS_URL=redis://localhost:6379

# Event Signing
EVENT_SECRET=your-secret-key-here

# Socket.io
SOCKET_IO_CORS_ORIGIN=*
```

### Dependencies to Install

```bash
npm install bull redis socket.io @types/bull
npm install --save-dev @types/redis
```

## 📝 Integration Notes

1. **Authentication**: All routes need JWT middleware
2. **Error Handling**: Use consistent error response format
3. **Validation**: Use Joi or express-validator
4. **Logging**: Add Winston or similar
5. **Testing**: Use Jest for unit tests
6. **Documentation**: Generate OpenAPI spec

## 🎯 Quick Start

1. **Install dependencies**: `npm install`
2. **Set up Redis**: `docker run -d -p 6379:6379 redis`
3. **Run migrations**: (Create migration scripts)
4. **Seed data**: (Create seed scripts for badges, items, etc.)
5. **Start server**: `npm run dev`
6. **Start workers**: `npm run workers`

## 📚 Documentation

- See `COMPREHENSIVE_IMPLEMENTATION_STATUS.md` for detailed status
- See `FEATURE_ANALYSIS_AND_IMPLEMENTATION_PLAN.md` for feature mapping
- API documentation will be generated from OpenAPI spec


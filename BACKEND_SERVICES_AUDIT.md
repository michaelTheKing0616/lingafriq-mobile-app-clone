# Backend Services Audit – Mobile vs Node Backend

**Date:** January 23, 2026  
**Purpose:** Verify all required backend services for the mobile app (including new screens) are implemented in the node-backend.

---

## 1. Auth & Profile (Edit Profile, Change Password)

| Mobile API | Method | Backend Route | Status |
|------------|--------|---------------|--------|
| `accounts/auth/users/me/`` | GET | `/accounts/auth/users/me` | Implemented |
| `accounts/auth/users/me/` | PUT | `/accounts/auth/users/me` | Implemented |
| `accounts/auth/users/set_password/` | POST | `/accounts/auth/users/set_password/` | Implemented |
| `account/my_user_profile/?id=` | GET | `/accounts/my_user_profile/` | Implemented |

**Conclusion:** Edit Profile and Change Password are fully supported.

---

## 2. User Preferences (Privacy Settings)

| Mobile API | Method | Backend Route | Status |
|------------|--------|---------------|--------|
| `api/user/preferences` | GET | — | **Missing** |
| `api/user/preferences` | PUT | — | **Missing** |

**Conclusion:** Privacy Settings backend sync is **not implemented**. Mobile falls back to local SharedPreferences; backend sync will 404 until added.

---

## 3. Learner Activity (Fill-in-the-Blank, Games)

| Mobile API | Method | Backend Route | Status |
|------------|--------|---------------|--------|
| `api/learner-activity` | POST | — | **Missing** |

**Mobile payload:** `{ user_id, language, activity_type?, metadata?, timestamp }`

**Existing backend:**  
- `POST /api/progress/activity/` expects `{ metrics, timestamp }` (ProgressMetricsModel).  
- `POST /api/progress/:userId/:language/activity` (learnerProgress) expects `{ minutes, type, contentProgress }`, MongoDB ObjectId for userId.

**Conclusion:** Dedicated `POST /api/learner-activity` is **missing**. Mobile uses a different path and payload.

---

## 4. Gamification Progress (ProgressIntegration, Games)

| Mobile API | Method | Backend Route | Status |
|------------|--------|---------------|--------|
| `api/gamification/progress` | GET | — | **Missing** |
| `api/gamification/progress` | POST | — | **Missing** |
| `api/gamification/progress/sync` | POST | — | **Missing** |

**Existing backend:**  
- `GET /api/progress/user/:userId` (sync) – progress by user.  
- `POST /api/progress/activity/` (sync) – sync progress metrics `{ metrics, timestamp }`.

**Conclusion:** Mobile calls `api/gamification/progress` (GET/POST) and `api/gamification/progress/sync`. These routes do **not** exist; backend uses `api/progress/...` instead.

---

## 5. Gamification XP & Sync

| Mobile API | Method | Backend Route | Status |
|------------|--------|---------------|--------|
| `api/gamification/xp/award` | POST | `/api/gamification/xp/award` | Implemented |
| `api/gamification/xp/total?user_id=` | GET | `/api/gamification/xp/total` | Implemented |
| `api/gamification/sync` | POST | `/api/gamification/sync/` | Implemented |
| `api/gamification/users/:userId` | GET | `/api/gamification/user/:userId` | Implemented |

**Conclusion:** XP award, total, and gamification sync are implemented.

---

## 6. Onboarding

| Mobile API | Method | Backend Route | Status |
|------------|--------|---------------|--------|
| `onboarding/check-username` | GET | `/onboarding/check-username` | Implemented |
| `onboarding/placement-test/generate` | GET | `/onboarding/placement-test/generate` | Implemented |
| `api/onboarding/save/` | POST | `/api/onboarding/save/` | Implemented |

**Conclusion:** Onboarding endpoints are implemented.

---

## 7. Other Mobile APIs (Lessons, Quizzes, etc.)

| Mobile API | Backend | Status |
|------------|---------|--------|
| `language` | `/language` | Implemented |
| `lessons/`, `lessons/:id/all` | `/lessons`, etc. | Implemented |
| `history/`, `mannerism/`, `*_quiz` | Various | Implemented |
| `devices/` (FCM) | `/devices` | Implemented |
| `api/experiments/config` | `/api/experiments` | Implemented |
| `api/ai-chat/history` | AI chat routes | Implemented |
| `culture-magazine/*` | `/culture-magazine` | Implemented |
| `api/loading-screen/content` | `/loading-screen`, `/api/loading-screen` | Implemented |

**Conclusion:** Core content and app APIs are implemented.

---

## Summary: Gaps → Implemented

| # | Service | Mobile Expects | Status |
|---|---------|----------------|--------|
| 1 | User preferences | `GET`/`PUT` `api/user/preferences` | **Implemented** – `userPreferences` model, controller, route; mounted at `/api/user` |
| 2 | Learner activity | `POST` `api/learner-activity` | **Implemented** – `learnerActivity` controller; route in sync router at `/api/learner-activity`; stores in `TelemetryModel` |
| 3 | Gamification progress | `GET`/`POST` `api/gamification/progress` | **Implemented** – `getGamificationProgress` / `updateGamificationProgress` in sync controller; routes in sync router |
| 4 | Progress sync | `POST` `api/gamification/progress/sync` | **Implemented** – same handler as `POST /api/gamification/progress` |

---

## Implemented Backend Services (Node)

### 1. **api/user/preferences**
- **Model:** `UserPreferencesModel` (`user_preferences` collection) – `user_id`, `analytics`, `data_sharing`, `personalized_ads`, `location_tracking`, `profile_visibility`, `activity_status`.
- **Controller:** `userPreferences.controller` – `getPreferences`, `updatePreferences`.
- **Routes:** `GET /api/user/preferences`, `PUT /api/user/preferences` (requireSignin).
- **Mount:** `router.use("/api/user", userPreferencesRouter)`.

### 2. **api/learner-activity**
- **Controller:** `learnerActivity.controller` – `recordLearnerActivity`; writes to `TelemetryModel` with `eventType: 'learner_activity'` (or `activity_type` from body).
- **Route:** `POST /api/learner-activity` in sync router (requireSignin, getIdFromJWT).
- **Body:** `{ user_id?, language?, activity_type?, metadata?, timestamp? }`.

### 3. **api/gamification/progress**
- **Handlers:** `getGamificationProgress`, `updateGamificationProgress` in `sync.controller`.
- **Routes:**  
  - `GET /api/gamification/progress` – progress for current user (JWT); returns `{}` when none.  
  - `POST /api/gamification/progress` – body = `metrics` or `{ metrics, timestamp }`; delegates to `syncProgress`.  
  - `POST /api/gamification/progress/sync` – same as POST above.

---

**Last updated:** January 23, 2026

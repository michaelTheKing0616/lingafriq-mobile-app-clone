# Backend Integration Requirements

This document outlines the backend API endpoints that need to be implemented and their expected request/response formats.

## 1. AI Chat History Endpoints

### GET `/api/ai-chat/history`
**Purpose:** Retrieve AI chat history for a specific mode and language combination.

**Query Parameters:**
- `mode` (required): Chat mode string (e.g., "translation", "tutor", "roleplay", "conversation", "vocab", "review")
- `language_code` (required): Language code (e.g., "yoruba", "hausa", "igbo", "en")

**Expected Response:**
```json
{
  "messages": [
    {
      "role": "user",
      "content": "Hello",
      "timestamp": "2024-01-01T00:00:00Z"
    },
    {
      "role": "assistant", 
      "content": "Hi there!",
      "timestamp": "2024-01-01T00:00:01Z"
    }
  ]
}
```

**Alternative Response Format (also supported):**
```json
[
  {
    "role": "user",
    "content": "Hello",
    "timestamp": "2024-01-01T00:00:00Z"
  },
  {
    "role": "assistant",
    "content": "Hi there!",
    "timestamp": "2024-01-01T00:00:01Z"
  }
]
```

**Status Codes:**
- `200 OK`: Success with data
- `404 Not Found`: No history found for this mode/language combination
- `401 Unauthorized`: User not authenticated
- `500 Internal Server Error`: Server error

### POST `/api/ai-chat/history`
**Purpose:** Save AI chat history for a specific mode and language combination.

**Request Body:**
```json
{
  "mode": "translation",
  "language_code": "yoruba",
  "messages": [
    {
      "role": "user",
      "content": "Hello",
      "timestamp": "2024-01-01T00:00:00Z"
    },
    {
      "role": "assistant",
      "content": "Hi there!",
      "timestamp": "2024-01-01T00:00:01Z"
    }
  ]
}
```

**Expected Response:**
- `200 OK` or `201 Created`: Success
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: User not authenticated
- `500 Internal Server Error`: Server error

**Notes:**
- The backend should associate chat history with the authenticated user
- History should be scoped by mode × language_code combination
- Messages should be stored as a list of objects with role, content, and optional timestamp

## 2. Gamification Endpoint

### GET `/api/gamification/users/{userId}`
**Purpose:** Retrieve user gamification data (XP, badges, level, etc.)

**Path Parameters:**
- `userId` (required): User ID

**Expected Response:**
```json
{
  "user_id": "123",
  "xp": 1500,
  "level": 5,
  "total_points": 2500,
  "unlocked_badges": ["badge_1", "badge_2"],
  "current_streak": 7,
  "longest_streak": 14,
  "last_activity_date": "2024-01-01T00:00:00Z"
}
```

**Status Codes:**
- `200 OK`: Success with data
- `404 Not Found`: User gamification data not found
- `401 Unauthorized`: User not authenticated
- `500 Internal Server Error`: Server error

**Notes:**
- Response should match the structure expected by `UserGamificationModel.fromJson()`
- The backend should initialize gamification data when a user is created
- Data should be user-scoped

## Implementation Notes

### Frontend Integration Status

✅ **Implemented:**
- `getAiChatHistory()` method in `ApiProvider` - calls GET endpoint
- `saveAiChatHistory()` method in `ApiProvider` - calls POST endpoint  
- `getGamification()` method in `ApiProvider` - calls GET endpoint
- Frontend falls back to local storage if backend is unavailable
- Frontend syncs to backend after local saves (debounced)

### Frontend Implementation Status ✅

**Completed Frontend Implementation:**
- ✅ `getAiChatHistory()` method in `ApiProvider` - calls GET `/api/ai-chat/history` with query parameters
- ✅ `saveAiChatHistory()` method in `ApiProvider` - calls POST `/api/ai-chat/history` with JSON body
- ✅ `getGamification()` method in `ApiProvider` - calls GET `/api/gamification/users/{userId}`
- ✅ Frontend integration in `ai_chat_provider_groq.dart` - loads from backend, falls back to local storage
- ✅ Frontend integration in `gamification_provider.dart` - syncs with backend
- ✅ Graceful error handling - falls back to local storage if backend fails
- ✅ Debounced backend sync to avoid excessive API calls

### Backend Implementation Checklist

**Required Backend Implementation:**
- [ ] Implement GET `/api/ai-chat/history` endpoint
  - Accept query parameters: `mode` (string), `language_code` (string)
  - Return: `{ "messages": [...] }` or `[...]` array of message objects
  - Scope by authenticated user_id
  - Return 404 if no history found (frontend handles this gracefully)
  
- [ ] Implement POST `/api/ai-chat/history` endpoint (if not already done)
  - Accept JSON body: `{ "mode": string, "language_code": string, "messages": [...] }`
  - Upsert history for user_id + mode + language_code combination
  - Return 200/201 on success
  
- [ ] Implement GET `/api/gamification/users/{userId}` endpoint
  - Return user gamification data as JSON object
  - Initialize default values if user doesn't have gamification data yet
  - Return 404 if user not found (frontend handles this gracefully)
  
- [ ] Ensure endpoints require authentication
  - All endpoints should verify JWT token in Authorization header
  - Return 401 if unauthorized
  
- [ ] Ensure data is properly scoped to users
  - AI chat history: Scope by user_id + mode + language_code (unique constraint)
  - Gamification: Scope by user_id (unique per user)
  
- [ ] Implement proper error handling and status codes
  - 200/201: Success
  - 400: Bad request (invalid parameters/data)
  - 401: Unauthorized (missing/invalid token)
  - 404: Not found (no data for this user/combination)
  - 500: Server error
  
- [ ] Add database tables/models for:
  - AI chat history (scoped by user_id, mode, language_code)
  - User gamification data (scoped by user_id)

### Data Models

#### AI Chat History
```sql
-- Example schema (adjust as needed)
CREATE TABLE ai_chat_history (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  mode VARCHAR(50) NOT NULL,
  language_code VARCHAR(10) NOT NULL,
  messages JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, mode, language_code)
);
```

#### User Gamification
```sql
-- Example schema (adjust as needed)
CREATE TABLE user_gamification (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE,
  xp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  total_points INTEGER DEFAULT 0,
  unlocked_badges JSONB DEFAULT '[]',
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_activity_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## Testing

After backend implementation, test the following:

1. **AI Chat History:**
   - Save history for different mode/language combinations
   - Retrieve saved history
   - Verify history is scoped correctly (different modes/languages are isolated)
   - Test with missing history (should return 404 or empty)

2. **Gamification:**
   - Retrieve user gamification data
   - Verify all expected fields are present
   - Test with new user (should return initialized/default data)

## Error Handling

The frontend gracefully handles backend errors:
- If backend request fails, it falls back to local storage
- Errors are logged but don't break the user experience
- Backend sync is retried on next app launch

Ensure backend endpoints return appropriate HTTP status codes and error messages.

## Summary

### ✅ Frontend is Ready
The Flutter mobile app has been fully updated to:
1. Call backend APIs for AI chat history persistence
2. Call backend API for gamification data
3. Gracefully handle backend errors with local storage fallback
4. Sync data to backend after local operations (debounced)

### ⚠️ Backend Needs Implementation
The backend must implement the following endpoints according to the specifications above:
1. **GET `/api/ai-chat/history`** - Retrieve chat history
2. **POST `/api/ai-chat/history`** - Save chat history  
3. **GET `/api/gamification/users/{userId}`** - Get user gamification data

All endpoints must:
- Require JWT authentication
- Scope data to the authenticated user
- Return appropriate HTTP status codes
- Handle errors gracefully

Once these endpoints are implemented on the backend, the frontend will automatically use them for data persistence and retrieval.


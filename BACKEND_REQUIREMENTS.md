# Backend API Requirements for Grand Features

This document outlines the backend endpoints that need to be implemented in the `node-backend` repository to support all the grand features.

## Base URL
All endpoints should be relative to: `http://admin.lingafriq.com/`

## Authentication
All endpoints (except public ones) require JWT authentication via the `Authorization: Bearer <token>` header.

---

## 1. Progress Tracking & Daily Goals

### GET `/progress/daily_goals/`
**Description**: Get user's daily goals and streak
**Response**:
```json
{
  "goals": [
    {
      "type": "lessons",
      "target": 3,
      "current": 2,
      "date": "2025-01-15",
      "completed": false
    }
  ],
  "streak": 7,
  "lastActivityDate": "2025-01-15"
}
```

### POST `/progress/daily_goals/update/`
**Description**: Update daily goal progress
**Body**:
```json
{
  "type": "lessons",
  "increment": 1
}
```
**Response**: `200 OK`

### GET `/progress/metrics/`
**Description**: Get user's progress metrics
**Response**:
```json
{
  "wordsLearned": 1250,
  "listeningHours": 15.5,
  "speakingHours": 8.2,
  "readingWords": 5000,
  "writtenWords": 300,
  "knownWords": 1200,
  "timeSpentMinutes": 1200,
  "wordsByLanguage": {
    "yoruba": 500,
    "hausa": 300
  },
  "timeByActivity": {
    "lessons": 10.5,
    "quizzes": 5.0,
    "games": 3.0
  }
}
```

### POST `/progress/metrics/update/`
**Description**: Update progress metrics
**Body**: Same structure as GET response
**Response**: `200 OK`

---

## 2. Achievements

### GET `/progress/achievements/`
**Description**: Get all achievements for user
**Response**:
```json
[
  {
    "id": "streak_7",
    "name": "Week Warrior",
    "description": "Maintain a 7-day learning streak",
    "type": "streak",
    "rarity": "uncommon",
    "icon": "🔥",
    "xpReward": 100,
    "unlockedAt": "2025-01-10T10:30:00Z",
    "isUnlocked": true
  }
]
```

### POST `/progress/achievements/unlock/`
**Description**: Unlock an achievement
**Body**:
```json
{
  "achievement_id": "streak_7"
}
```
**Response**: `200 OK`

---

## 3. Global Rankings & Statistics

### GET `/global/stats/`
**Description**: Get global statistics (public endpoint)
**Response**:
```json
{
  "totalUsers": 12500,
  "totalWordsLearned": 2500000,
  "totalHours": 45000,
  "activeLanguages": 12
}
```

### GET `/global/leaderboard/?limit=100`
**Description**: Get global leaderboard
**Response**:
```json
[
  {
    "rank": 1,
    "userId": 123,
    "username": "Amina K.",
    "points": 12500,
    "country": "🇳🇬",
    "avatar": "url"
  }
]
```

### GET `/global/top_languages/`
**Description**: Get top languages by learner count
**Response**:
```json
[
  {
    "name": "Yoruba",
    "learners": 3200
  },
  {
    "name": "Swahili",
    "learners": 2800
  }
]
```

---

## 4. Culture Content

### GET `/culture/content/?type=story`
**Description**: Get culture content (optional type filter: story, music, festival, lore)
**Response**:
```json
[
  {
    "id": "1",
    "title": "The Story of Anansi",
    "description": "A timeless West African folktale",
    "type": "story",
    "imageUrl": "url",
    "audioUrl": "url",
    "content": "Long ago...",
    "language": "English",
    "country": "🇬🇭",
    "publishDate": "2025-01-15T10:00:00Z",
    "tags": ["folktale", "west-africa"],
    "views": 150,
    "isFeatured": true
  }
]
```

### GET `/culture/content/{id}/`
**Description**: Get specific culture content by ID
**Response**: Same structure as array item above

---

## 5. Chat & Social

### GET `/chat/rooms/`
**Description**: Get available chat rooms
**Response**:
```json
[
  {
    "name": "general",
    "userCount": 150,
    "language": null
  },
  {
    "name": "yoruba",
    "userCount": 45,
    "language": "Yoruba"
  }
]
```

### GET `/chat/rooms/{room}/messages/?limit=50`
**Description**: Get chat messages for a room
**Response**:
```json
[
  {
    "id": "msg123",
    "room": "general",
    "message": "Hello everyone!",
    "userId": 123,
    "username": "Amina",
    "timestamp": "2025-01-15T10:30:00Z"
  }
]
```

### GET `/chat/online_users/`
**Description**: Get list of online users
**Response**:
```json
[
  {
    "userId": 123,
    "username": "Amina K.",
    "isOnline": true,
    "lastSeen": "2025-01-15T10:30:00Z"
  }
]
```

---

## 6. Socket.io Events

The backend should implement Socket.io server with the following events:

### Client → Server Events:
- `user_connected` - When user connects
  ```json
  {
    "userId": "123",
    "username": "Amina"
  }
  ```
- `send_message` - Send chat message
  ```json
  {
    "room": "general",
    "message": "Hello!",
    "userId": "123",
    "username": "Amina",
    "timestamp": "2025-01-15T10:30:00Z"
  }
  ```
- `join_room` - Join a chat room
  ```json
  {
    "room": "general"
  }
  ```
- `leave_room` - Leave a chat room
  ```json
  {
    "room": "general"
  }
  ```

### Server → Client Events:
- `online_users` - List of online users
  ```json
  [
    {
      "userId": "123",
      "username": "Amina",
      "isOnline": true
    }
  ]
  ```
- `new_message` - New chat message
  ```json
  {
    "id": "msg123",
    "room": "general",
    "message": "Hello!",
    "userId": "123",
    "username": "Amina",
    "timestamp": "2025-01-15T10:30:00Z"
  }
  ```
- `user_joined` - User joined room
  ```json
  {
    "userId": "123",
    "username": "Amina",
    "room": "general"
  }
  ```
- `user_left` - User left room
  ```json
  {
    "userId": "123",
    "room": "general"
  }
  ```

---

## Implementation Notes

1. **Error Handling**: All endpoints should return appropriate HTTP status codes:
   - `200` - Success
   - `201` - Created
   - `400` - Bad Request
   - `401` - Unauthorized
   - `404` - Not Found
   - `500` - Server Error

2. **Pagination**: For list endpoints, consider adding pagination:
   - `?page=1&limit=50`

3. **Filtering**: Support filtering where applicable:
   - `?type=story` for culture content
   - `?language=yoruba` for various endpoints

4. **Caching**: Consider caching for public endpoints like global stats

5. **Rate Limiting**: Implement rate limiting for chat endpoints

6. **Real-time Updates**: Use Socket.io for real-time features (chat, online users)

---

## Database Schema Suggestions

### daily_goals
- id, user_id, type, target, current, date, completed, created_at, updated_at

### progress_metrics
- id, user_id, words_learned, listening_hours, speaking_hours, reading_words, written_words, known_words, time_spent_minutes, words_by_language (JSON), time_by_activity (JSON), last_updated

### achievements
- id, user_id, achievement_id, unlocked_at

### global_stats
- id, total_users, total_words_learned, total_hours, active_languages, updated_at

### culture_content
- id, title, description, type, image_url, audio_url, video_url, content, language, country, publish_date, tags (JSON), views, is_featured

### chat_messages
- id, room, user_id, username, message, timestamp

### online_users
- user_id, username, is_online, last_seen, socket_id

---

## Testing

Test all endpoints with:
- Valid JWT tokens
- Invalid/missing tokens
- Valid and invalid request bodies
- Edge cases (empty lists, null values, etc.)

---

## Deployment

1. Update Socket.io server URL in `lib/providers/socket_provider.dart` to match your backend
2. Ensure CORS is configured for mobile app domain
3. Set up WebSocket support for Socket.io
4. Configure environment variables for database connections


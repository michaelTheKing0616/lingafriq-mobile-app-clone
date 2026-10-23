# How Backend Work Affects the Mobile App

## Overview

The backend you've set up provides APIs that the mobile app consumes. Here's how everything connects:

---

## 1. Culture Magazine Feature

### Backend Implementation

**API Endpoints:**
- `GET /culture-magazine/articles` - Get all published articles
- `GET /culture-magazine/articles/featured` - Get featured articles
- `GET /culture-magazine/articles/:slug` - Get single article
- `GET /culture-magazine/categories` - Get all categories
- `POST /culture-magazine/articles/:id/like` - Like an article

**Database:**
- Collection: `culturearticles`
- Fields: `title`, `content`, `category`, `country`, `published`, `featured`, etc.

### How Mobile App Uses It

1. **Article List Screen:**
   - App calls: `GET /culture-magazine/articles`
   - Backend filters: `{ published: true }` (only published articles)
   - App displays articles in a list/grid

2. **Featured Articles:**
   - App calls: `GET /culture-magazine/articles/featured`
   - Backend returns: Articles where `featured: true` AND `published: true`
   - App shows featured articles at the top

3. **Article Detail Screen:**
   - App calls: `GET /culture-magazine/articles/:slug`
   - Backend increments `views` counter
   - App displays full article content

4. **Categories Filter:**
   - App calls: `GET /culture-magazine/categories`
   - Backend returns: List of categories with article counts
   - App shows category filter buttons

5. **Like Feature:**
   - User taps like button
   - App calls: `POST /culture-magazine/articles/:id/like`
   - Backend increments `likes` counter
   - App updates UI with new like count

### What This Means

✅ **Published Articles = Visible in App**
- Only articles with `published: true` appear in the app
- Unpublished articles (`published: false`) are hidden

✅ **Featured Articles = Shown Prominently**
- Featured articles appear in special sections
- Users see them first

✅ **Scraper Workflow = Automatic Content**
- Daily scraper adds new articles
- You review and publish them
- They automatically appear in the app

---

## 2. Media Processing Backend

### Backend Implementation

**API Endpoints:**
- `POST /media/upload` - Upload media files
- `GET /media/:id` - Get media details
- `GET /media` - List user's media

**Database:**
- Collection: `media`
- Stores: File paths, processing status, metadata

### How Mobile App Uses It

1. **User Uploads Media:**
   - App uploads image/video to backend
   - Backend processes and stores it
   - App shows upload progress

2. **View Media:**
   - App fetches media from backend
   - Backend serves processed files
   - App displays media in gallery

### What This Means

✅ **User-Generated Content**
- Users can upload photos/videos
- Backend processes and stores them
- Content is available across devices

---

## 3. Global Chat (WebSocket)

### Backend Implementation

**WebSocket Server:**
- Real-time connection via Socket.IO
- Events: `message`, `join`, `leave`, `typing`

**Database:**
- Collection: `chatmessages`
- Stores: Messages, room info, timestamps

### How Mobile App Uses It

1. **Connect to Chat:**
   - App connects to WebSocket server
   - Backend establishes real-time connection
   - Messages sync instantly

2. **Send Message:**
   - User types message
   - App sends via WebSocket
   - Backend broadcasts to all connected users
   - All users see message immediately

3. **Message History:**
   - App loads past messages from database
   - Backend provides paginated history
   - Users see full conversation

### What This Means

✅ **Real-Time Communication**
- Messages appear instantly
- No page refresh needed
- Multiple users chat simultaneously

---

## 4. Private Chats

### Backend Implementation

**WebSocket + REST API:**
- Private room connections
- Message storage per conversation
- User-to-user messaging

**Database:**
- Collection: `chatmessages`
- Fields: `room_id`, `sender`, `receiver`, `message`, `timestamp`

### How Mobile App Uses It

1. **Start Private Chat:**
   - User selects another user
   - App creates/joins private room
   - Backend establishes private WebSocket connection

2. **Send Private Message:**
   - App sends message via WebSocket
   - Backend stores in database
   - Only recipient receives message

3. **View Chat History:**
   - App loads conversation history
   - Backend returns messages for that room
   - Users see full conversation thread

### What This Means

✅ **Private Conversations**
- One-on-one messaging
- Messages stored securely
- History available anytime

---

## 5. User Connections (Social Graph)

### Backend Implementation

**API Endpoints:**
- `POST /connections/request` - Send friend request
- `POST /connections/accept` - Accept request
- `GET /connections/friends` - Get friends list
- `GET /connections/pending` - Get pending requests

**Database:**
- Collection: `userconnections`
- Fields: `requester`, `recipient`, `status` (pending/accepted/blocked)

### How Mobile App Uses It

1. **Send Friend Request:**
   - User taps "Add Friend"
   - App calls: `POST /connections/request`
   - Backend creates connection record
   - Recipient gets notification

2. **Accept Request:**
   - User sees pending request
   - Taps "Accept"
   - App calls: `POST /connections/accept`
   - Backend updates status
   - Users are now connected

3. **View Friends:**
   - App calls: `GET /connections/friends`
   - Backend returns accepted connections
   - App displays friends list

### What This Means

✅ **Social Features**
- Users can connect with each other
- Friend requests and acceptances
- Social graph for recommendations

---

## 6. Comprehensive Curriculum

### Backend Implementation

**API Endpoints:**
- `GET /curriculum/lessons` - Get lessons
- `GET /curriculum/lessons/:id` - Get lesson details
- `POST /curriculum/progress` - Save progress

**Database:**
- Collections: `lessons`, `progress`, `exercises`
- Stores: Lesson content, user progress, exercises

### How Mobile App Uses It

1. **Load Lessons:**
   - App calls: `GET /curriculum/lessons`
   - Backend returns lesson list
   - App displays curriculum

2. **Track Progress:**
   - User completes lesson
   - App calls: `POST /curriculum/progress`
   - Backend saves progress
   - App shows completion status

### What This Means

✅ **Learning Progress**
- Content stored on backend
- Progress synced across devices
- Personalized learning paths

---

## Data Flow Diagram

```
Mobile App                    Backend API                    MongoDB
    │                              │                              │
    │  GET /articles               │                              │
    ├─────────────────────────────>│                              │
    │                              │  Query: {published: true}    │
    │                              ├─────────────────────────────>│
    │                              │                              │
    │                              │  Return: Articles            │
    │                              │<──────────────────────────────┤
    │  Response: Articles          │                              │
    │<──────────────────────────────┤                              │
    │                              │                              │
    │  Display articles in UI     │                              │
    │                              │                              │
```

---

## Key Points

### 1. **Published vs Unpublished**
- **Backend:** Articles have `published: true/false` field
- **Mobile App:** Only fetches articles where `published: true`
- **Result:** Unpublished articles are invisible to users

### 2. **Real-Time Updates**
- **Backend:** WebSocket server broadcasts changes
- **Mobile App:** Receives updates instantly
- **Result:** Live chat, notifications, etc.

### 3. **Data Synchronization**
- **Backend:** Single source of truth
- **Mobile App:** Fetches data on demand
- **Result:** Consistent data across all devices

### 4. **User Actions**
- **Mobile App:** User performs action (like, comment, upload)
- **Backend:** Processes and stores action
- **Result:** Action persists and syncs

---

## Testing the Connection

### Test Culture Magazine API

```bash
# From your server
curl http://localhost:4000/culture-magazine/articles

# Should return only published articles
# Unpublished articles won't appear
```

### Test from Mobile App

1. Open Culture Magazine screen in app
2. Check if articles load
3. Verify only published articles appear
4. Test featured articles section

---

## Summary

**Backend → Mobile App Flow:**

1. **Scraper** adds articles → `published: false`
2. **You review** and publish → `published: true`
3. **Mobile app** fetches articles → Only gets `published: true`
4. **Users see** published articles in the app

**Everything is connected!** The backend controls what the mobile app sees, and the mobile app provides the user interface for all backend features.

---

**The backend is the brain, the mobile app is the face! 🧠📱**


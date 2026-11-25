# LingAfriq Mobile App - Comprehensive Functionality Documentation

## Table of Contents
1. [App Architecture Overview](#app-architecture-overview)
2. [Application Flow (Top to Bottom)](#application-flow-top-to-bottom)
3. [Core Modules & Features](#core-modules--features)
4. [Backend Integration](#backend-integration)
5. [Data Flow & Persistence](#data-flow--persistence)

---

## App Architecture Overview

### Technology Stack
- **Frontend**: Flutter (Dart) with Material 3 Design
- **State Management**: Riverpod (Provider pattern)
- **Backend**: Node.js/Express.js with MongoDB, Redis, Bull Queue
- **AI Integration**: Groq API (LLaMA models) + Hybrid Polie System
- **Real-time**: Socket.io for chat and live updates
- **Storage**: SharedPreferences (local), SecureStorage (tokens), MongoDB (server)
- **Push Notifications**: Firebase Cloud Messaging (FCM)

### Key Design Patterns
- **Provider Pattern**: All state managed through Riverpod providers
- **Repository Pattern**: API calls abstracted through providers
- **Singleton Pattern**: Services like PolieContentGenerator
- **Observer Pattern**: Real-time updates via Socket.io streams

---

## Application Flow (Top to Bottom)

### 1. App Initialization (`main.dart`)

**Entry Point:**
```dart
main() → Firebase.initializeApp() → ProviderScope → MyApp → SplashScreen
```

**What Happens:**
1. **Firebase Initialization**: Sets up FCM for push notifications
2. **ProviderScope Setup**: Initializes Riverpod state management
3. **SharedPreferences**: Loads cached data (languages, user preferences)
4. **System Configuration**: Sets portrait-only orientation
5. **Background Message Handler**: Registers FCM background handler

**Backend Connection:**
- No immediate backend call
- Prepares providers for subsequent API calls

---

### 2. Splash Screen (`splash_screen.dart`)

**Purpose**: Initial app loading and authentication check

**Flow:**
1. Displays LingAfriq branding/logo
2. Checks app version for fresh installs/updates
3. Calls `AuthProvider.navigateBasedOnCondition()`

**Backend Connection:**
- Checks local storage for valid session tokens
- If token exists, validates with backend (implicit on first API call)
- No explicit API call during splash

---

### 3. Onboarding Flow (`kijiji_onboarding_screen.dart`)

**Purpose**: 10-step story-driven introduction to the app

**Steps:**
1. **Welcome Screen**: Introduction to "Kijiji cha Lugha" (Language Village)
2. **Elder Screen**: Explains the wisdom keeper role
3. **Weaver Screen**: Introduces language weaving concept
4. **Rhythm Master**: Explains pronunciation and rhythm
5. **Timekeeper**: Introduces progress tracking
6. **Path Chooser**: Explains learning paths
7. **Griot**: Storytelling and cultural content
8. **Healer**: Error correction and feedback
9. **Placement Test**: Optional language proficiency assessment
10. **Completion**: Transitions to login

**How It Works:**
- Uses `PageView` with `NeverScrollableScrollPhysics` (button navigation only)
- Each screen has animations via `flutter_animate`
- Haptic feedback on page transitions
- Stores completion status in `SharedPreferences`

**Backend Connection:**
- **POST `/api/onboarding/save/`**: Saves onboarding completion data
- Stores: `has_seen_onboarding`, `placement_test_results`, `selected_languages`
- User preferences synced to backend user profile

**Data Persistence:**
- Local: `SharedPreferences` (`has_seen_onboarding` flag)
- Backend: User profile updated with onboarding completion status

---

### 4. Authentication Flow (`auth_provider.dart`)

**Purpose**: User authentication and session management

**Flow:**
```
Splash → Check Session → [Valid? → Main App] → [Invalid? → Login]
```

**Login Process:**
1. User enters email/password (pre-filled if available)
2. **POST `/accounts/auth/jwt/create/`**: Authenticates user
3. Receives JWT token (1 hour TTL) and refresh token (30 days TTL)
4. Stores tokens in `SecureStorage` (encrypted)
5. **GET `/accounts/auth/users/me/`**: Fetches user profile
6. Updates `UserProvider` with profile data
7. **POST `/devices/`**: Registers FCM device token
8. Navigates to `TabsView` (main app)

**Token Management:**
- **Session Token**: Stored in `SecureStorage`, expires in 1 hour
- **Refresh Token**: Stored in `SecureStorage`, expires in 30 days
- **Auto-refresh**: On API 401 errors, automatically refreshes using refresh token
- **Silent Login**: On app restart, checks for valid refresh token and auto-logs in

**Backend Endpoints:**
- `POST /accounts/auth/jwt/create/` - Login
- `GET /accounts/auth/users/me/` - Get user profile
- `POST /devices/` - Register device for push notifications
- `POST /accounts/auth/users/reset_password/` - Password reset

**Data Persistence:**
- **Local**: Tokens in `SecureStorage`, credentials in `SharedPreferences` (if user opts in)
- **Backend**: User session tracked, device registered

---

### 5. Main App Structure (`tabs_view.dart`)

**Purpose**: Main navigation hub with 4 primary tabs

**Tabs:**
1. **Home Tab** (Index 0): Language selection and quick actions
2. **Courses Tab** (Index 1): Structured learning paths
3. **Standings Tab** (Index 2): Leaderboards and rankings
4. **Profile Tab** (Index 3): User profile and settings

**Navigation:**
- Material 3 `NavigationBar` at bottom
- `IndexedStack` for tab persistence (tabs stay in memory)
- App drawer (hamburger menu) for additional features
- Haptic feedback on tab changes

**Backend Connection:**
- Each tab makes independent API calls when loaded
- Tab state persists in memory (no backend calls for tab switching)

---

## Core Modules & Features

### 6. Home Tab (`home_tab.dart`)

**Purpose**: Primary landing screen with language selection

**Components:**

#### 6.1 Language List
- **Data Source**: `GET /language` - Fetches all available languages
- **Caching**: Languages cached in `SharedPreferences` for offline access
- **Display**: Featured languages shown first, then all languages
- **Features**:
  - Language cards with flags, names, progress indicators
  - Search functionality
  - Filter by featured/learning/completed

**Backend Integration:**
- **GET `/language`**: Returns list of all languages with metadata
- Response includes: `id`, `name`, `flag_url`, `is_featured`, `learner_count`
- Cached locally for offline access
- Auto-refreshes when tab is opened

#### 6.2 Language Detail Screen (`language_detail_screen.dart`)
**Accessed**: When user taps a language card

**Features:**
- Language introduction and cultural context
- Quick action buttons:
  - **Start Learning**: Navigates to lessons
  - **Take a Quiz**: Opens quiz selection
  - **View Progress**: Shows learning statistics

**Backend Integration:**
- **GET `/lessons/?language_id={id}`**: Fetches lessons for language
- **GET `/random_quiz/{languageId}/all`**: Gets available quizzes
- **GET `/api/progress/user/{userId}`**: Fetches user progress for language

#### 6.3 Take a Quiz (`take_quiz_screen.dart`)
**Purpose**: Interactive quiz system for language practice

**Flow:**
1. **GET `/random_quiz/{languageId}/all`**: Fetches random quizzes
2. User selects a quiz
3. Quiz questions displayed with multiple choice
4. User answers questions
5. **POST `/random_quiz/{languageId}/questions/{questionId}/inst_ques_detail`**: Submits answer
6. Immediate feedback shown
7. **POST `/api/progress/quiz/complete/`**: Tracks completion
8. XP awarded via `GamificationProvider`

**Backend Integration:**
- **GET `/random_quiz/{languageId}/all`**: Returns quiz list
- **POST `/random_quiz/{languageId}/questions/{questionId}/inst_ques_detail`**: Submits answer
- **POST `/api/progress/quiz/complete/`**: Tracks quiz completion
- **POST `/api/gamification/sync/`**: Updates XP and progress

**Data Persistence:**
- Quiz results stored in backend
- Progress tracked in user profile
- XP and achievements updated in real-time

---

### 7. Courses Tab (`courses_tab.dart`)

**Purpose**: Structured learning paths and curriculum

**Features:**
- **Language Selection**: Choose language to learn
- **Level Selection**: A0 (Beginner) to C2 (Proficient)
- **Lesson List**: Organized by sections and topics
- **Progress Tracking**: Visual progress indicators
- **Completion Status**: Tracks completed lessons

**Backend Integration:**
- **GET `/lessons/?language_id={id}&level={level}`**: Fetches lessons
- **GET `/lessons/{lessonId}/all`**: Gets lesson details
- **POST `/lessons/{lessonId}/lessons/{sectionLessonId}/lesson_lesson`**: Marks tutorial complete
- **POST `/lessons/{lessonId}/lessons/{sectionLessonId}/quiz_detail`**: Marks quiz complete
- **POST `/api/progress/lesson/complete/`**: Tracks lesson completion

**Data Flow:**
1. User selects language → API call for lessons
2. User opens lesson → API call for lesson content
3. User completes tutorial → POST to mark complete
4. User completes quiz → POST to mark complete
5. Progress synced to backend → XP awarded

---

### 8. AI Chat - Polie System

**Purpose**: AI-powered language learning assistant with 6 specialized modes

#### 8.1 Mode Selection (`polie_mode_selection_screen.dart`)
**Flow**: App Drawer → AI Chat → Mode Selection

**Modes:**
1. **Translation Mode**: Bidirectional translation with diacritics enforcement
2. **Tutor Mode**: Adaptive teaching with SRS (Spaced Repetition System)
3. **Roleplay Mode**: Scenario-based conversation practice
4. **Conversation Mode**: Natural dialogue practice
5. **Vocabulary Mode**: Word learning with flashcards
6. **Review Mode**: SRS-based review of learned words

#### 8.2 Language Setup (`ai_chat_language_setup_screen.dart`)
**After Mode Selection:**
- User selects source language (e.g., English)
- User selects target language (e.g., Yoruba)
- Sets up language direction for Polie

#### 8.3 Chat Screen (`ai_chat_screen.dart`)
**Features:**
- Real-time streaming responses
- Mode-specific system prompts
- Chat history scoped by mode × language (separate conversations)
- SRS integration for vocabulary tracking
- CEFR level tracking
- Grammar error detection
- Pronunciation feedback

**How It Works:**
1. User sends message → `GroqChatProvider.sendMessageStream()`
2. Message sanitized and validated
3. **Hybrid Polie System** (if enabled):
   - Routes to appropriate model based on task
   - LLaMA-3.1-70B for dialogue/roleplay
   - NLLB-200 for translation
   - AfriTeVa/AfriT5 for canonical phrases
   - Post-processing: Diacritics enforcement, orthography validation
4. Response streamed word-by-word
5. Response saved to chat history (scoped by mode × language)
6. SRS updated for vocabulary words
7. CEFR level adjusted based on performance

**Backend Integration:**
- **POST `/hybrid-polie/orchestrate`**: Hybrid Polie routing (if enabled)
- **POST `/api/ai/chat/history/sync/`**: Syncs chat history to backend
- **GET `/api/ai/chat/history/{mode}`**: Retrieves chat history for mode
- **POST `/api/ai/chat/srs/sync/`**: Syncs SRS data
- **GET `/api/ai/chat/cefr/{userId}`**: Gets CEFR level

**Data Persistence:**
- **Local**: Chat history in `SharedPreferences` (key: `chat_history_{mode}_{language}`)
- **Backend**: Full chat history synced for cross-device access
- **SRS Data**: Word memory tracked locally and synced to backend

**Polie Content Generation:**
- Uses `PolieContentGenerator` for dynamic content
- Generates proverbs, stories, scenarios, vocabulary
- All content culturally accurate and language-specific

---

### 9. Language Games (`games_screen.dart`)

**Purpose**: 35+ interactive games for language learning

#### 9.1 Game Categories

**Core Language Games:**
1. **Word Match Audio**: Match words to audio pronunciations
2. **Pronunciation Duel**: Pronunciation practice with feedback
3. **Tone Trainer**: Tone pattern recognition
4. **Speed Round**: Fast-paced vocabulary challenges
5. **Story Builder**: Construct sentences to build stories
6. **Roleplay Adventure**: Interactive scenario-based learning
7. **Grammar Detective**: Find and correct grammar errors

**Cultural Games (17 games):**
1. **Proverb Unlocker**: Learn traditional proverbs
2. **Drum Rhythm Shadowing**: Match drum patterns to words
3. **Clan Story Builder**: Reconstruct cultural stories
4. **Market Bargaining**: Practice negotiation phrases
5. **Taxi Survival**: Navigate transportation scenarios
6. **Food Quest**: Learn food vocabulary through quests
7. **Call and Response**: Music-based pronunciation
8. **Greeting Diplomacy**: Learn appropriate greetings
9. **Folktale Reconstruction**: Rebuild traditional tales
10. **Phrase Sniper**: Fast-paced phrase recognition
11. **Liar Liar**: Detect grammatical errors
12. **Village Quest**: NPC conversation scenarios
13. **Accent Puzzle**: Match accents to regions
14. **Flashcard Safari**: AR-style vocabulary scanning
15. **Tongue Twister**: Rapid pronunciation practice
16. **Emoji Translator**: Translate emoji sequences
17. **Rhythm Typing**: Type with drum rhythms
18. **Elders' Blessings**: Learn blessing phrases
19. **Multilingual Relay**: Translation chain challenges
20. **Cultural Etiquette**: Scenario-based etiquette
21. **Drum Word Matching**: Match drum patterns to words

#### 9.2 Game Flow

**For Each Game:**
1. **Game Initialization**:
   - `BaseGameScreen` creates game session
   - **POST `/api/games/session/start/`**: Creates session in backend
   - Loads game content (from Polie or backend)
   - Initializes game state

2. **Gameplay**:
   - User interacts with game
   - Each turn tracked: `completeTurn()`
   - **POST `/api/games/session/{sessionId}/turn/`**: Sends turn data
   - Real-time scoring and feedback
   - Polie generates dynamic content as needed

3. **Game Completion**:
   - `finishGame()` called
   - **POST `/api/games/session/{sessionId}/complete/`**: Finalizes session
   - Calculates accuracy, duration, score
   - **POST `/api/games/telemetry/`**: Sends telemetry data
   - XP awarded via `GamificationProvider`
   - Progress updated

**Backend Integration:**
- **POST `/api/games/session/start/`**: Creates game session
- **POST `/api/games/session/{sessionId}/turn/`**: Records each turn
- **POST `/api/games/session/{sessionId}/complete/`**: Completes session
- **POST `/api/games/telemetry/`**: Sends game analytics
- **GET/PUT `/api/games/srs/user/{userId}`**: Syncs SRS data
- **POST `/api/gamification/sync/`**: Updates XP, badges, achievements

**Data Persistence:**
- Game sessions stored in backend MongoDB
- SRS data synced for vocabulary tracking
- Telemetry data for analytics
- XP and achievements updated in real-time

**Polie Integration:**
- All games use `PolieContentGenerator` for dynamic content
- Content generated on-demand (proverbs, scenarios, vocabulary)
- Culturally accurate and language-specific

---

### 10. Gamification System

**Purpose**: Motivate learning through rewards, competition, and social features

#### 10.1 XP & Levels (`gamification_provider.dart`)
**How It Works:**
- XP awarded for: lessons completed, quizzes passed, games played, daily streaks
- Levels calculated from total XP
- **POST `/api/gamification/sync/`**: Syncs XP and level to backend
- Real-time updates via Socket.io

**Backend Integration:**
- **POST `/api/gamification/sync/`**: Updates user XP and level
- **GET `/api/gamification/user/{userId}`**: Retrieves gamification data
- Socket.io events for real-time XP updates

#### 10.2 Badges (`badge_collection_screen.dart`)
**Purpose**: Achievement system with African-themed badges

**Features:**
- Badge collection display
- Progress toward next badge
- Badge unlocking animations
- Categories: Learning, Social, Cultural, Mastery

**Backend Integration:**
- **GET `/api/badges`**: Fetches available badges
- **POST `/api/badges/award`**: Awards badge to user
- **GET `/api/users/{userId}/badges`**: Gets user's badges
- Badge rules engine evaluates on backend
- Real-time badge notifications via Socket.io

**Data Persistence:**
- Badges stored in MongoDB `user_badges` collection
- Badge progress tracked in user profile
- Badge rules engine evaluates achievements automatically

#### 10.3 Leaderboards (`leaderboard_screen.dart`)
**Purpose**: Competitive rankings across multiple categories

**Types:**
- **Global**: All users worldwide
- **Tribe**: Within user's tribe
- **Village**: Within language village
- **Continental**: By continent
- **Weekly/Monthly/All-Time**: Time-based rankings

**Backend Integration:**
- **GET `/api/leaderboards/{type}`**: Fetches leaderboard data
- Uses Redis sorted sets for fast ranking queries
- Real-time updates via Socket.io
- **POST `/api/leaderboards/update`**: Updates user score

**Data Persistence:**
- Leaderboard scores in Redis (fast queries)
- Historical data in MongoDB
- Auto-updated on XP changes

#### 10.4 The Great Journey (`quest_screen.dart`)
**Purpose**: Long-form story-driven progression system

**Features:**
- Chapter-based story progression
- Each chapter has lessons and challenges
- Story content generated by Polie
- Progress tracked per chapter
- Unlocks next chapter on completion

**Backend Integration:**
- **GET `/api/journey/nodes`**: Fetches journey structure
- **GET `/api/journey/progress/{userId}`**: Gets user progress
- **POST `/api/journey/progress/{userId}`**: Updates progress
- **POST `/api/journey/complete/{nodeId}`**: Marks node complete

**Data Persistence:**
- Journey nodes in MongoDB
- User progress tracked per node
- Story content generated dynamically by Polie

#### 10.5 My Tribe (`tribe_selection_screen.dart`)
**Purpose**: Social learning groups (guilds)

**Features:**
- Join/create tribes
- Tribe chat and collaboration
- Tribe leaderboards
- Tribe challenges

**Backend Integration:**
- **GET `/api/tribes`**: Lists available tribes
- **POST `/api/tribes/join`**: Joins a tribe
- **POST `/api/tribes/create`**: Creates new tribe
- **GET `/api/tribes/{tribeId}/members`**: Gets tribe members
- Socket.io for tribe chat

**Data Persistence:**
- Tribes in MongoDB `tribes` collection
- Tribe members in `tribe_members` collection
- Tribe chat messages in MongoDB

#### 10.6 Language Villages (`language_villages_screen.dart`)
**Purpose**: Language-specific communities

**Features:**
- Join villages for specific languages
- Village-specific leaderboards
- Village events and challenges
- Cultural content sharing

**Backend Integration:**
- **GET `/api/villages`**: Lists villages
- **POST `/api/villages/join`**: Joins village
- **GET `/api/villages/{villageId}/leaderboard`**: Village rankings

#### 10.7 Tribe vs Tribe (`tribe_vs_tribe_screen.dart`)
**Purpose**: Competitive events between tribes

**Features:**
- Scheduled competitions
- Team-based challenges
- Real-time score tracking
- Rewards for winners

**Backend Integration:**
- **GET `/api/competitions`**: Lists active competitions
- **POST `/api/competitions/{id}/participate`**: Joins competition
- **GET `/api/competitions/{id}/scores`**: Gets competition scores
- Socket.io for real-time updates

#### 10.8 Magic Items (`magic_items_screen.dart`)
**Purpose**: Temporary buffs and power-ups

**Features:**
- Purchase items with in-app currency (Ngwenya, Cowries)
- Items provide temporary XP boosts, streak protection, etc.
- Item effects tracked and applied automatically

**Backend Integration:**
- **GET `/api/items`**: Lists available items
- **POST `/api/items/purchase`**: Purchases item
- **GET `/api/users/{userId}/items`**: Gets user's inventory
- Item effects applied on backend

#### 10.9 Seasonal Events (`seasonal_events_screen.dart`)
**Purpose**: Limited-time events and challenges

**Features:**
- Time-limited events
- Special rewards
- Event-specific leaderboards
- Cultural celebrations

**Backend Integration:**
- **GET `/api/events`**: Lists active events
- **POST `/api/events/{id}/participate`**: Joins event
- **GET `/api/events/{id}/leaderboard`**: Event rankings

---

### 11. Social Features

#### 11.1 Global Chat (`global_chat_screen.dart`)
**Purpose**: Community-wide messaging

**Features:**
- Real-time messaging via Socket.io
- Language-specific channels
- Message moderation (AutoMod)
- User mentions and reactions

**Backend Integration:**
- **Socket.io**: Real-time message broadcasting
- **POST `/chat/rooms/{room}/messages/`**: Sends message
- **GET `/chat/rooms/{room}/messages/`**: Loads message history
- **POST `/moderation/check`**: AutoMod checks messages
- Messages stored in MongoDB

**Data Persistence:**
- Messages in MongoDB `chat_messages` collection
- Real-time delivery via Socket.io
- Message history paginated

#### 11.2 Private Chat (`private_chat_list_screen.dart`, `private_chat_screen.dart`)
**Purpose**: One-on-one messaging

**Features:**
- User-to-user messaging
- Chat list with last message preview
- Read receipts
- Typing indicators

**Backend Integration:**
- **Socket.io**: Private message delivery
- **GET `/chat/private/conversations`**: Gets chat list
- **POST `/chat/private/message`**: Sends private message
- Messages stored in MongoDB

#### 11.3 User Connections (`user_connections_screen.dart`)
**Purpose**: Find and connect with other learners

**Features:**
- Search users
- Send connection requests
- View user profiles
- Language learning partners

**Backend Integration:**
- **GET `/connections/users`**: Searches users
- **POST `/connections/request`**: Sends connection request
- **POST `/connections/accept`**: Accepts request
- Connections stored in MongoDB

#### 11.4 Ancestral Tree (`ancestral_tree_screen.dart`)
**Purpose**: Mentorship and learning lineage

**Features:**
- View learning mentors
- Track learning lineage
- Mentor-student relationships
- Knowledge sharing

**Backend Integration:**
- **GET `/api/ancestry/{userId}`**: Gets user's tree
- **POST `/api/ancestry/mentor`**: Sets mentor
- Ancestry data in MongoDB

---

### 12. Progress & Analytics

#### 12.1 Progress Dashboard (`progress_dashboard_screen.dart`)
**Purpose**: Comprehensive learning analytics

**Features:**
- Learning streaks
- Words learned count
- Time spent learning
- Accuracy metrics
- Language proficiency levels (CEFR)
- Weekly/monthly summaries

**Backend Integration:**
- **GET `/api/progress/user/{userId}`**: Gets progress data
- **POST `/api/progress/activity/`**: Tracks activities
- Progress calculated from: lessons, quizzes, games, chat interactions

**Data Persistence:**
- Progress metrics in MongoDB
- Real-time calculations
- Historical data for trends

#### 12.2 Daily Goals (`daily_goals_screen.dart`)
**Purpose**: Set and track daily learning targets

**Features:**
- Set daily XP goals
- Set daily time goals
- Streak tracking
- Goal completion rewards

**Backend Integration:**
- **GET `/progress/daily_goals/`**: Gets goals
- **POST `/progress/daily_goals/update/`**: Updates goals
- **POST `/progress/daily_goals/update_streak/`**: Updates streak
- Goals stored in user profile

#### 12.3 Global Progress (`global_progress_screen.dart`)
**Purpose**: Community-wide statistics

**Features:**
- Total users learning
- Total words learned
- Most popular languages
- Community achievements

**Backend Integration:**
- **GET `/global/stats/`**: Gets global statistics
- **GET `/global/leaderboard/`**: Global rankings
- Aggregated from all user data

---

### 13. Content Features

#### 13.1 Culture Magazine (`culture_magazine_screen.dart`)
**Purpose**: Cultural articles and content

**Features:**
- Featured articles
- Categories: History, Traditions, Food, Music, etc.
- Article reading with vocabulary highlights
- Favorite articles
- View tracking

**Backend Integration:**
- **GET `/culture-magazine/articles`**: Lists articles
- **GET `/culture-magazine/articles/featured`**: Featured articles
- **GET `/culture-magazine/articles/{slug}`**: Article details
- **POST `/culture-magazine/articles/{id}/view`**: Tracks view
- **POST `/culture-magazine/articles/{id}/favorite`**: Toggles favorite
- Articles stored in MongoDB
- Polie generates fallback content if API fails

**Data Persistence:**
- Articles in MongoDB
- User favorites tracked
- View analytics stored

#### 13.2 Media Import (`import_media_screen.dart`)
**Purpose**: Import external content for learning

**Features:**
- Import from URL
- Extract text content
- Create lessons from content
- Polie-powered content extraction

**Backend Integration:**
- **POST `/media/import`**: Imports media
- **POST `/content/generate`**: Generates lesson from content
- Uses Polie to extract and summarize content
- Creates structured lessons

#### 13.3 Curriculum (`curriculum_screen.dart`)
**Purpose**: Structured learning curriculum

**Features:**
- Organized by levels (A0-C2)
- Lesson progression
- Completion tracking
- Navigation to lessons

**Backend Integration:**
- **GET `/lessons/?language_id={id}`**: Gets curriculum
- **POST `/api/progress/lesson/complete/`**: Tracks completion
- Curriculum structure in MongoDB

---

### 14. Settings & Profile

#### 14.1 User Profile (`user_profile_screen.dart`)
**Purpose**: User account management

**Features:**
- Profile editing
- Avatar upload
- Language preferences
- Notification settings
- Logout

**Backend Integration:**
- **GET `/account/my_user_profile/`**: Gets profile
- **PUT `/accounts/auth/users/{id}/`**: Updates profile
- **POST `/account/update/`**: Updates account
- Profile stored in MongoDB

#### 14.2 Settings (`settings_screen.dart`)
**Purpose**: App configuration

**Features:**
- Notification preferences
- Language settings
- Theme (light/dark)
- Privacy settings
- Data export

**Backend Integration:**
- **GET `/notifications/`**: Gets notification settings
- **POST `/notifications/`**: Updates settings
- Settings synced to backend

---

## Backend Integration

### API Architecture

**Base URL**: `http://admin.lingafriq.com/`

**Authentication:**
- JWT tokens in `Authorization: Bearer {token}` header
- Token refresh on 401 errors
- Secure token storage in `SecureStorage`

**Key Endpoints by Category:**

#### Authentication
- `POST /accounts/auth/jwt/create/` - Login
- `GET /accounts/auth/users/me/` - Get user profile
- `POST /accounts/auth/users/reset_password/` - Password reset

#### Languages & Lessons
- `GET /language` - Get all languages
- `GET /lessons/?language_id={id}` - Get lessons
- `POST /lessons/{id}/lessons/{sectionId}/lesson_lesson` - Complete tutorial
- `POST /lessons/{id}/lessons/{sectionId}/quiz_detail` - Complete quiz

#### Quizzes
- `GET /random_quiz/{languageId}/all` - Get random quizzes
- `POST /random_quiz/{languageId}/questions/{questionId}/inst_ques_detail` - Submit answer

#### Gamification
- `POST /api/gamification/sync/` - Sync gamification data
- `GET /api/gamification/user/{userId}` - Get user gamification
- `GET /api/badges` - Get badges
- `POST /api/badges/award` - Award badge
- `GET /api/leaderboards/{type}` - Get leaderboard
- `GET /api/tribes` - Get tribes
- `POST /api/tribes/join` - Join tribe
- `GET /api/journey/nodes` - Get journey nodes
- `POST /api/journey/progress/{userId}` - Update journey progress

#### Games
- `POST /api/games/session/start/` - Start game session
- `POST /api/games/session/{sessionId}/turn/` - Complete turn
- `POST /api/games/session/{sessionId}/complete/` - End game
- `POST /api/games/telemetry/` - Send game telemetry

#### AI Chat
- `POST /hybrid-polie/orchestrate` - Hybrid Polie routing
- `POST /api/ai/chat/history/sync/` - Sync chat history
- `GET /api/ai/chat/history/{mode}` - Get chat history
- `POST /api/ai/chat/srs/sync/` - Sync SRS data

#### Progress
- `GET /api/progress/user/{userId}` - Get progress
- `POST /api/progress/activity/` - Track activity
- `POST /api/progress/lesson/complete/` - Complete lesson
- `POST /api/progress/quiz/complete/` - Complete quiz

#### Social
- `GET /chat/rooms/` - Get chat rooms
- `POST /chat/rooms/{room}/messages/` - Send message
- `GET /connections/users` - Search users
- `POST /connections/request` - Send connection request

#### Content
- `GET /culture-magazine/articles` - Get articles
- `POST /content/generate` - Generate content
- `POST /media/import` - Import media

### Real-time Features (Socket.io)

**Channels:**
- `global_chat` - Global chat messages
- `private_chat_{userId}` - Private messages
- `tribe_{tribeId}` - Tribe chat
- `village_{villageId}` - Village updates
- `competition_{competitionId}` - Competition updates
- `leaderboard_updates` - Leaderboard changes

**Events:**
- `message` - New message
- `typing` - User typing
- `user_online` - User came online
- `user_offline` - User went offline
- `xp_update` - XP changed
- `badge_unlocked` - Badge awarded
- `leaderboard_update` - Leaderboard changed

---

## Data Flow & Persistence

### Local Storage (SharedPreferences)

**Stored Data:**
- `has_seen_onboarding` - Onboarding completion
- `cached_languages` - Language list cache
- `user_{email}` - User profile data
- `chat_history_{mode}_{language}` - Chat history
- `srs_memory` - Spaced repetition data
- `cefr_info` - CEFR level data
- App version for update detection

### Secure Storage

**Stored Data:**
- Session token (JWT, 1 hour TTL)
- Refresh token (30 days TTL)
- User email
- User profile (encrypted)

### Backend Storage (MongoDB)

**Collections:**
- `users` - User accounts
- `languages` - Language data
- `lessons` - Lesson content
- `quizzes` - Quiz questions
- `game_sessions` - Game session data
- `chat_messages` - Chat messages
- `tribes` - Tribe data
- `badges` - Badge definitions
- `user_badges` - User badge awards
- `leaderboard_scores` - Leaderboard data
- `journey_nodes` - Journey structure
- `user_journey_progress` - Journey progress
- `competitions` - Competition data
- `events` - Event data
- `telemetry` - Analytics data

### Redis (Caching & Real-time)

**Usage:**
- Leaderboard sorted sets (fast rankings)
- Session data
- Rate limiting
- Real-time presence tracking

### Data Synchronization

**Sync Strategy:**
1. **Optimistic Updates**: UI updates immediately, syncs in background
2. **Conflict Resolution**: Server timestamp wins
3. **Offline Support**: Local cache for offline access
4. **Background Sync**: Periodic sync when online
5. **Real-time Updates**: Socket.io for live changes

**Sync Endpoints:**
- `POST /api/gamification/sync/` - Sync gamification
- `POST /api/games/srs/sync/` - Sync SRS
- `POST /api/ai/chat/history/sync/` - Sync chat
- `POST /api/progress/activity/` - Sync progress

---

## Summary

The LingAfriq app is a comprehensive language learning platform that combines:

1. **Structured Learning**: Courses, lessons, quizzes
2. **AI-Powered Assistance**: Polie with 6 specialized modes
3. **Gamification**: XP, badges, leaderboards, tribes, competitions
4. **Social Learning**: Chat, connections, mentorship
5. **Cultural Content**: Articles, stories, games
6. **Progress Tracking**: Analytics, goals, streaks
7. **Real-time Features**: Socket.io for live updates

All features are fully integrated with the backend for persistence, real-time updates, and cross-device synchronization. The app uses Polie (AI) for dynamic content generation, ensuring culturally accurate and engaging learning experiences.


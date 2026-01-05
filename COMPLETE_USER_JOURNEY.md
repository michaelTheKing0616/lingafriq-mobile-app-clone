# Complete User Journey - From App Open to Every Feature

## 🚀 Moment-by-Moment User Experience

### 0. App Installation & First Launch

#### Installation
1. User downloads from App Store/Play Store
2. App installs (~50-100MB)
3. Permissions requested:
   - Network (required)
   - Storage (for offline content)
   - Microphone (for pronunciation)
   - Notifications (for reminders)

#### First Launch (Cold Start)
```
Time: 0.0s - App icon tapped
├─ Flutter engine initializes
├─ main() function executes
│  ├─ WidgetsFlutterBinding.ensureInitialized()
│  ├─ ImageCacheManager.configureCache()
│  ├─ Firebase.initializeApp()
│  ├─ Offline services initialize
│  ├─ Auth services initialize
│  ├─ Localization detects device language
│  └─ Sentry monitoring starts
│
Time: 1.5-2.5s - SplashScreen appears
├─ Splash animation plays
├─ App checks:
│  ├─ Is user authenticated? → No
│  ├─ Is onboarding complete? → No
│  └─ Any cached data? → Check
│
Time: 2.5-3.0s - Navigate to OnboardingScreen
└─ First-time user flow begins
```

---

### 1. Onboarding Flow (First-Time Users)

#### Screen 1: Welcome (5-10 seconds)
```
User sees:
- App logo animation
- Welcome message
- "Get Started" button

User action:
- Taps "Get Started"

System:
- Navigate to Language Selection
```

#### Screen 2: Language Selection (30-60 seconds)
```
User sees:
- List of 13+ African languages:
  * Yoruba, Hausa, Igbo, Swahili
  * Zulu, Xhosa, Amharic, Twi
  * Afrikaans, Pidgin, Wolof, Somali
- "Select your target language(s)"
- Multi-select enabled

User actions:
- Selects 1-3 languages
- Taps "Continue"

System:
- Saves selections to backend: POST /onboarding/language-selection
- Navigate to Personalization
```

#### Screen 3: Personalization (30-45 seconds)
```
User sees:
- Name input field
- Avatar selection (12+ options)
- Learning style preferences:
  * Visual learner
  * Auditory learner
  * Kinesthetic learner
- Daily goal selector (5, 10, 15, 20 minutes)

User actions:
- Enters name
- Selects avatar
- Chooses learning style
- Sets daily goal
- Taps "Continue"

System:
- Saves to backend: POST /onboarding/personalization
- Navigate to Placement Test (optional)
```

#### Screen 4: Placement Test (Optional, 2-5 minutes)
```
User sees:
- "Take a quick test to find your level"
- "Skip" option available
- Adaptive quiz interface

If user takes test:
- 5-10 questions
- Difficulty adjusts based on answers
- Real-time feedback

User actions:
- Answers questions
- OR taps "Skip"

System:
- If taken: POST /api/placement-test
  - Calculates level (A1, A2, B1, B2, C1, C2)
  - Saves to user profile
- Navigate to Permissions
```

#### Screen 5: Permissions (10-20 seconds)
```
User sees:
- Permission requests:
  * Microphone (for pronunciation practice)
  * Notifications (for daily reminders)
  * Storage (for offline downloads)

User actions:
- Grants/denies permissions
- Taps "Continue"

System:
- Saves permission status
- Navigate to Onboarding Complete
```

#### Screen 6: Onboarding Complete (5 seconds)
```
User sees:
- Celebration animation
- "Welcome to LingAfriq!"
- "Start Learning" button

User actions:
- Taps "Start Learning"

System:
- POST /onboarding/complete
- Navigate to TabsView (Home tab)
```

**Total Onboarding Time:** 2-7 minutes

---

### 2. Main App Experience

#### 2.1 Home/Dashboard Tab (First View)

```
User lands on Home tab

Screen loads:
├─ Daily goal widget (top)
│  ├─ Progress bar
│  ├─ "5/10 minutes today"
│  └─ Streak indicator: "🔥 3 day streak"
│
├─ Quick actions (middle)
│  ├─ "Continue Lesson" button
│  ├─ "Daily Challenge" card
│  └─ "Play a Game" button
│
├─ Recent progress (below)
│  ├─ Last lesson completed
│  ├─ XP earned today
│  └─ Badges unlocked
│
├─ Recommendations (bottom)
│  ├─ "Recommended for you"
│  ├─ Lesson cards
│  └─ Game suggestions
│
└─ Leaderboard preview (bottom)
   ├─ "You're #42 this week"
   └─ Top 3 users
```

**Data Loading:**
- `GET /api/gamification/xp` - XP data
- `GET /api/gamification/streak` - Streak
- `GET /api/leaderboards?limit=3` - Top users
- `GET /api/personalization/recommendations` - Recommendations

**User Actions:**
1. **Tap "Continue Lesson"**
   - Navigate to Learn tab
   - Open last lesson
   
2. **Tap "Daily Challenge"**
   - Open challenge screen
   - Show challenge details
   - Start challenge

3. **Tap "Play a Game"**
   - Navigate to Games tab
   - Show game selection

4. **Tap Recommendation Card**
   - Navigate to content detail
   - Start lesson/game

---

#### 2.2 Learn Tab - Lesson Experience

```
User navigates to Learn tab

Screen shows:
├─ Language selector (top)
│  └─ Selected: "Yoruba"
│
├─ Section list
│  ├─ Section 1: Greetings (3/5 lessons)
│  ├─ Section 2: Numbers (0/4 lessons)
│  ├─ Section 3: Family (0/6 lessons)
│  └─ ... (scrollable)
│
└─ Search bar (top)
   └─ Filter lessons
```

**User taps "Section 1: Greetings"**

```
Lesson list appears:
├─ Lesson 1: Basic Greetings ✅
├─ Lesson 2: Formal Greetings ✅
├─ Lesson 3: Time-based Greetings ✅
├─ Lesson 4: Greeting Responses (current)
└─ Lesson 5: Cultural Context (locked)
```

**User taps "Lesson 4: Greeting Responses"**

```
Lesson detail screen loads:
├─ Header
│  ├─ Back button
│  ├─ Lesson title
│  └─ Progress: "3/5 items"
│
├─ Lesson items (scrollable)
│  ├─ Item 1: Introduction ✅
│  │  └─ Text + Audio
│  │
│  ├─ Item 2: Vocabulary ✅
│  │  ├─ Word cards
│  │  └─ Audio pronunciation
│  │
│  ├─ Item 3: Grammar ✅
│  │  ├─ Grammar rules
│  │  └─ Examples
│  │
│  ├─ Item 4: Practice (current)
│  │  ├─ Interactive exercises
│  │  └─ Submit button
│  │
│  └─ Item 5: Quiz (locked)
│     └─ "Complete practice first"
│
└─ Bottom navigation
   ├─ Previous item
   ├─ Next item
   └─ Complete lesson
```

**User completes practice:**

```
1. User answers questions
2. Taps "Submit"
3. System evaluates:
   - POST /api/lessons/:id/items/:itemId/complete
   - Polie evaluates (if applicable)
4. Feedback appears:
   - ✅ Correct answers highlighted
   - ❌ Incorrect with explanations
   - Rive character reacts (celebrate/encourage)
5. XP awarded:
   - +10 XP for practice
   - Streak maintained
   - Progress updated
6. Next item unlocks
```

**User completes quiz:**

```
1. User answers all quiz questions
2. Taps "Complete Quiz"
3. System evaluates:
   - POST /api/lessons/:id/complete
   - All items marked complete
4. Results screen:
   - Score: "8/10"
   - XP earned: "+50 XP"
   - Badge unlocked: "First Lesson Complete!"
   - Rive character celebrates
5. Options:
   - "Continue to next lesson"
   - "Review mistakes"
   - "Back to lessons"
```

**Backend Calls:**
- `GET /lessons?language=yor` - List lessons
- `GET /lessons/:id` - Lesson details
- `GET /lessons/:id/items` - Lesson items
- `POST /api/user-lessons/complete` - Mark complete
- `POST /api/gamification/xp/award` - Award XP

---

#### 2.3 Games Tab - Game Experience

```
User navigates to Games tab

Screen shows:
├─ Game categories
│  ├─ Cultural Games (6)
│  ├─ Language Games (7)
│  ├─ Pronunciation Games (5)
│  └─ ... (more categories)
│
├─ Featured games (top)
│  └─ "Proverb Unlocker" (recommended)
│
└─ All games grid (scrollable)
   └─ 37+ game cards
```

**User taps "Proverb Unlocker"**

```
Game screen loads:
├─ Header
│  ├─ Back button
│  ├─ Game title
│  ├─ Score: "0/5"
│  └─ Round: "1/5"
│
├─ Rive character (animated guide)
│  └─ Shows encouraging emotion
│
├─ Game content (middle)
│  ├─ Proverb display:
│  │  "Ọmọ tí ó bá dàgbà, ó máa rí ìgbà"
│  │  (Translation: "A child who grows up will see time")
│  │
│  └─ Question: "What does this mean?"
│
├─ Answer options (below)
│  ├─ Option A: "Time waits for no one"
│  ├─ Option B: "Patience is a virtue" ✅ (correct)
│  ├─ Option C: "Youth is fleeting"
│  └─ Option D: "Age brings wisdom"
│
└─ Progress meter (bottom)
   └─ "Round 1 of 5"
```

**User selects answer:**

```
1. User taps "Option B"
2. System processes:
   - POST /v1/polie/evaluate-game-turn
   - Polie evaluates answer
   - NO RANDOM LOGIC - AI-driven
3. Feedback appears (1-2 seconds):
   - ✅ Correct answer highlighted
   - Rive character celebrates
   - "+20 XP" animation
   - Streak updated: "🔥 2"
4. Auto-advance after 3 seconds:
   - Next round loads
   - New proverb appears
```

**User completes game:**

```
After 5 rounds:
1. Results screen:
   - Final score: "4/5"
   - Accuracy: "80%"
   - XP earned: "+100 XP"
   - Streak: "🔥 5"
   - Badge unlocked: "Proverb Master!"
2. Rive character celebrates
3. Options:
   - "Play Again"
   - "Try Another Game"
   - "Back to Games"
```

**Backend Calls:**
- `POST /v1/game-content` - Generate game content
- `POST /v1/polie/evaluate-game-turn` - Evaluate turn
- `POST /v1/polie/rive-state` - Update Rive animation
- `POST /api/gamification/xp/award` - Award XP

---

#### 2.4 Chat/Social Tab

**AI Chat Experience:**

```
User navigates to Chat tab
├─ Tab selector (top)
│  ├─ "AI Chat" (selected)
│  ├─ "Private Chat"
│  └─ "Classroom"
│
└─ AI Chat screen
   ├─ Chat history (scrollable)
   │  └─ Previous conversations
   │
   ├─ New chat button (floating)
   │  └─ "Start Conversation"
   │
   └─ Language selector
      └─ "Yoruba" (selected)
```

**User starts conversation:**

```
1. User taps "Start Conversation"
2. Chat interface appears:
   ├─ Header: "AI Tutor - Yoruba"
   ├─ Message input (bottom)
   └─ Chat area (middle)
3. User types: "How do I say 'good morning'?"
4. User taps send
5. System processes:
   - POST /hybrid-polie/chat
   - Polie generates response
6. Response appears (2-3 seconds):
   - "Good morning in Yoruba is 'Ẹ káàrọ̀'"
   - Audio pronunciation button
   - Cultural context: "Used until 12 PM"
7. Conversation continues...
```

**Private Chat Experience:**

```
User switches to "Private Chat" tab

Screen shows:
├─ Contact list
│  ├─ Online users (green dot)
│  ├─ Offline users (gray)
│  └─ Search bar
│
└─ Recent conversations
   └─ Last 10 chats
```

**User selects contact:**

```
1. User taps contact
2. Chat screen opens:
   ├─ Header: Contact name + status
   ├─ Message history (scrollable)
   ├─ Input field (bottom)
   │  ├─ Text input
   │  ├─ Voice message button
   │  └─ Media button
   └─ Send button
3. Real-time messaging via Socket.io
4. Messages appear instantly
```

**Classroom Chat Experience:**

```
User switches to "Classroom" tab

Screen shows:
├─ Available classrooms
│  ├─ "Yoruba Practice Room" (12 users)
│  ├─ "Hausa Conversation" (8 users)
│  └─ "Swahili Beginners" (5 users)
│
└─ "Create Classroom" button
```

**User joins classroom:**

```
1. User taps "Yoruba Practice Room"
2. LiveKit connection established
3. Classroom screen:
   ├─ Participant list (side)
   ├─ Main audio area
   ├─ Chat panel (bottom)
   └─ Controls:
      ├─ Mute/Unmute
      ├─ Leave room
      └─ Raise hand
4. Real-time audio streaming
5. Practice conversation with others
```

---

#### 2.5 Profile Tab

```
User navigates to Profile tab

Screen shows:
├─ Profile header
│  ├─ Avatar
│  ├─ Name
│  ├─ Level: "12" (with progress bar)
│  └─ XP: "2,450 / 3,000"
│
├─ Statistics cards
│  ├─ Streak: "🔥 7 days"
│  ├─ Lessons: "23 completed"
│  ├─ Games: "45 played"
│  └─ Words: "156 learned"
│
├─ Achievements section
│  ├─ Badges grid
│  └─ "View All" button
│
├─ Progress section
│  ├─ Language progress bars
│  └─ "View Details" button
│
└─ Settings section
   ├─ Account settings
   ├─ Notifications
   ├─ Language preferences
   ├─ Offline content
   └─ About
```

**User taps "Achievements":**

```
Achievements screen:
├─ Badge categories
│  ├─ Learning badges (8/12)
│  ├─ Streak badges (3/5)
│  ├─ Cultural badges (2/8)
│  └─ Special badges (1/3)
│
├─ Badge details
│  └─ Tap badge for description
│
└─ Progress indicators
   └─ "2 more lessons for next badge"
```

---

### 3. Advanced Features

#### 3.1 Offline Mode

```
User goes offline:
1. App detects no connection
2. Offline indicator appears
3. User can still:
   - Access downloaded lessons
   - Play downloaded games
   - Review vocabulary
   - View progress
4. Changes queued for sync
5. When online:
   - Background sync starts
   - Changes uploaded
   - New content downloaded
```

#### 3.2 Social Audio Rooms

```
User navigates to Social Audio:
1. Browse available rooms
2. Join room
3. LiveKit connects
4. Real-time audio streaming
5. Practice with other learners
6. Leave room when done
```

#### 3.3 Culture Magazine

```
User opens Culture Magazine:
1. Browse articles
2. Read cultural content
3. Learn language tips
4. View stories
5. Bookmark favorites
```

---

## 🎯 Key User Flows Summary

### Learning Flow
```
Home → Learn Tab → Select Language → 
Select Section → Select Lesson → 
Complete Items → Quiz → 
XP Awarded → Badge Unlocked → 
Next Lesson Suggested
```

### Gaming Flow
```
Home → Games Tab → Select Game → 
Load Content (Polie) → Play Turn → 
Polie Evaluates → Feedback → 
Rive Animation → XP Awarded → 
Next Round or Complete
```

### Social Flow
```
Home → Chat Tab → Select Type → 
AI Chat: Ask Question → Get Response
Private Chat: Select Contact → Message
Classroom: Join Room → Practice
```

### Progress Flow
```
Any Activity → Complete → 
XP Awarded → Streak Updated → 
Progress Saved → 
Leaderboard Updated → 
Recommendations Updated
```

---

## ⏱️ Performance Benchmarks

### Target Times
- **App Launch:** < 3 seconds
- **Screen Navigation:** < 500ms
- **API Response:** < 500ms (p95)
- **Game Load:** < 2 seconds
- **Lesson Load:** < 1.5 seconds
- **Chat Response:** < 3 seconds

### Current Performance
- ✅ Image caching (fast loads)
- ✅ Offline-first (instant offline)
- ✅ Background sync (non-blocking)
- ✅ Optimized API calls
- ✅ Database indexes

---

## 🎨 User Experience Highlights

### Visual Delight
- ✅ Rive animated character (reacts to everything)
- ✅ Smooth animations throughout
- ✅ Material 3 design
- ✅ Pan-African color scheme
- ✅ Premium UI components

### Engagement
- ✅ 37+ games (more than competitors)
- ✅ Comprehensive gamification
- ✅ Social features
- ✅ Real-time feedback
- ✅ Cultural authenticity

### Accessibility
- ✅ Offline support
- ✅ Multiple languages
- ✅ Adaptive difficulty
- ✅ Clear feedback
- ✅ Error recovery

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Status:** Complete User Journey Documentation


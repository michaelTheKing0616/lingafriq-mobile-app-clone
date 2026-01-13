# Complete UI Inventory for FigmaMake - LingAfriq Mobile App

## App Overview
**App Name**: LingAfriq  
**Purpose**: African Language Learning Mobile Application  
**Target Platforms**: iOS & Android  
**Design Style Needed**: Modern, Colorful, African-inspired, Engaging, Educational  
**Primary Colors**: Green (#007A3D), Orange (#FF6B35), Gold (#FCD116), Purple (#7B2CBF), Red (#CE1126)  
**Theme Support**: Light and Dark mode

---

## 🎨 SCREEN INVENTORY (36 Screens Total)

### 📱 AUTHENTICATION & ONBOARDING (6 Screens)

#### 1. **Splash Screen / Loading Screen**
**Purpose**: First screen shown when app opens, displays Africa facts  
**Components**:
- App logo (centered)
- Circular illustration of African person (rotating different people)
- Greeting in local language (e.g., "Sannu" - Hausa, "Jambo" - Swahili)
- Translation of greeting in English
- Interesting fact about Africa (rotating facts)
- Loading progress indicator (animated bar)
- Minimum display time: 3-4 seconds

**Design Requirements**:
- Dark background with gradient (deep green to black)
- Gold accents
- Circular avatar with African patterns/stripes
- Animated progress bar
- Large readable text for facts

---

#### 2. **Onboarding Screen (Kijiji - The Language Village)** - 10 Steps
**Purpose**: Multi-step story-driven onboarding that collects user preferences

**Step 1: Welcome Screen**
- Title: "Welcome to Kijiji cha Lugha" (The Language Village)
- Subtitle: "Your journey begins here"
- Baobab tree illustration (or African nature icon)
- Large "Begin Journey" button
- Skip button (top right)
- African savanna gradient background

**Step 2: The Elder (Age & Purpose)**
- Character: Mzee Kato (elder illustration/icon)
- Dialogue: "Welcome, traveler. I am Mzee Kato, keeper of the village memory."
- Question: "Who are you?"
- Age selection chips: CHILD | TEEN | ADULT
- Learning reason multi-select chips: HERITAGE | TRAVEL | SCHOOL | BUSINESS | CURIOSITY
- Next button (disabled until selections made)
- Progress indicator at top (10 dots)

**Step 3: The Weaver (Language & Level)**
- Character: Adisa the Weaver (weaver/artisan icon)
- Dialogue: "I am Adisa, the Weaver. Choose the threads of your voice."
- Language selection chips: Swahili, Yoruba, Amharic, Zulu, Hausa, Igbo
- Proficiency selection: BEGINNER | INTERMEDIATE | ADVANCED
- Next button

**Step 4: Rhythm Master (Learning Style)**
- Character: Nuru (drum/music icon)
- Dialogue: "I am Nuru the Rhythm Master. Tap the drum that sings to your spirit."
- Learning style chips: AUDIO | VISUAL | STORIES | DRILLS | CONVERSATION
- Next button

**Step 5: Timekeeper (Schedule)**
- Character: Zawadi (clock/time icon)
- Dialogue: "I am Zawadi, keeper of time. When shall we train your tongue?"
- Duration slider: 5-25 minutes per day
- Time of day chips: SUNRISE | MIDDAY | SUNSET | NIGHT
- Next button

**Step 6: Path Chooser (Goals)**
- Title: "Choose your path"
- Grid of 6 goal cards:
  - Travel (flight icon)
  - Heritage (heart icon)
  - Business (briefcase icon)
  - Academic (book icon)
  - Confidence (microphone icon)
  - Brain Training (brain icon)
- Next button

**Step 7: The Griot (Personality)**
- Character: Amina the Griot (storyteller icon)
- Dialogue: "I am Amina the Griot. How shall I speak to you?"
- Tone preference: PLAYFUL | ENCOURAGING | SERIOUS
- Gamification level: HIGH | MEDIUM | MINIMAL
- Next button

**Step 8: The Healer (Accessibility)**
- Character: Healer icon
- Dialogue: "I am the Healer. Let me make your journey smooth."
- Accessibility toggles:
  - Large Text (switch)
  - High Contrast (switch)
  - Dyslexia-friendly (switch)
  - Sound Off (switch)
  - Motion Reduction (switch)
- Next button (always enabled)

**Step 9: Social Preferences**
- Title: "Build your clan"
- Social preference chips: SOLO | BUDDIES | COMMUNITY | TEACHER_GUIDED
- Next button

**Step 10: Naming & Placement**
- Icon: Celebration
- Dialogue: "A learner without a name is a drum without a rhythm!"
- Username text input field
- "Begin Test" button (skips placement test for now)
- Completes onboarding

**Design Requirements**:
- African savanna gradient background (#D4A574 to #8B6F47)
- White text on gradient
- Circular character icons
- Animated transitions between steps
- Progress dots at top
- White action buttons with green text
- Skip button (first 3 screens only)

---

#### 3. **Login Screen**
**Purpose**: User authentication  
**Components**:
- App logo with title
- Email input field (pre-filled if saved)
- Password input field (show/hide toggle)
- "Forgot password?" link
- Large "Login" button
- "Don't have an account? Sign up" link
- Loading overlay when authenticating

**Design Requirements**:
- Clean, minimal design
- White background with subtle gradient
- Green primary button
- Form validation indicators
- Smooth transitions

---

#### 4. **Sign Up Screen**
**Purpose**: New user registration  
**Components**:
- Email input field
- Username input field
- First name input field
- Last name input field
- Nationality selector (dropdown with flags)
- Password input field (with strength indicator)
- Confirm password input field
- "Agree to privacy terms" checkbox with link
- Large "Sign Up" button
- "Already have an account? Login" link

**Design Requirements**:
- Similar to login screen
- Password strength indicator (red/yellow/green)
- Flag icons for nationality

---

#### 5. **Forgot Password Screen**
**Purpose**: Password reset  
**Components**:
- Email input field
- "Send Reset Link" button
- Back button
- Success message display

---

#### 6. **Modern Onboarding Screen** (Alternative)
**Purpose**: Simpler 4-screen onboarding  
**4 Screens with**:
- Top image (illustration)
- Bottom background image
- Title text
- Description text
- Dot indicators
- Forward arrow button

---

### 🏠 MAIN APP STRUCTURE (4 Main Tabs)

#### 7. **Main Tabs View (Bottom Navigation)**
**Purpose**: Main app navigation container  
**Components**:
- Bottom navigation bar with 4 tabs:
  - 🏠 Home (icon: home_rounded)
  - 📚 Courses (icon: folder_copy_rounded)
  - 📊 Standings/Leaderboard (icon: bar_chart_rounded)
  - 👤 Profile (icon: person_rounded)
- Floating action button (if applicable)
- Navigation drawer (hamburger menu)

**Design Requirements**:
- Curved top border on bottom nav (24px radius)
- Green background (#007A3D)
- White/orange active icons
- Shadow on bottom nav
- Smooth tab transitions

---

### 🏠 HOME TAB SCREENS (6 Screens)

#### 8. **Home Tab / Dashboard**
**Purpose**: Main landing page showing featured languages  
**Components**:
- **Header**:
  - Hamburger menu icon (opens drawer)
  - Rotating greeting text ("Sannu da zuwa", "Wehcome o", "Karibu", etc.)
  - User's name display
  - Top gradient box (green gradient)
  
- **Content**:
  - "Featured Languages" section title
  - Subtitle: "Start your learning journey"
  - Grid of language cards (2-3 columns, responsive)
  - Each card shows:
    - Language background image
    - Language name overlay
    - Featured badge (if applicable)
  - "More Languages" section
  - Search bar for all languages
  - Pull to refresh functionality

**Design Requirements**:
- Gradient header (green)
- Card-based grid layout
- Large beautiful language images
- Smooth scrolling
- Refresh indicator

---

#### 9. **Language Detail Screen**
**Purpose**: Shows details about a specific language  
**Components**:
- Language background header
- Language name
- Introduction text
- Statistics (total lessons, total quizzes, completion %)
- Action buttons:
  - "Take a Lesson" (green)
  - "Take a Quiz" (orange)
  - "View History"
  - "View Mannerisms"
- Back button

---

#### 10. **Take a Lesson Screen** (Lessons List)
**Purpose**: Shows all available lessons for a language  
**Components**:
- Header with language name
- Section list (expandable):
  - Section title
  - Section description
  - Lesson count
- Each lesson card:
  - Lesson number
  - Lesson title
  - Completion status (checkmark if done)
  - Lock icon if not unlocked
  - Points/score display
- Back button
- Filter options (All, Completed, Locked)

---

#### 11. **Lesson Detail Screen** (Individual Lesson)
**Purpose**: Display lesson content with audio/video  
**Components**:
- Lesson title
- Video player (for lesson video)
- Audio player controls
- Lesson content text
- Vocabulary list with:
  - Word in African language
  - Translation
  - Play audio button for each word
- "Mark as Complete" button
- Next lesson button
- Back button

---

#### 12. **Take a Quiz Screen** (Quiz Selection Map)
**Purpose**: Interactive map to select quiz type  
**Components**:
- Background: African map illustration
- Quiz type buttons positioned on map:
  - "Random Quiz" bubble
  - "Language Quiz" bubble
  - "History Quiz" bubble
- Back button
- Hamburger menu
- Animated bubbles

**Design Requirements**:
- Map-style background
- Circular quiz type buttons
- Gradient effects
- Playful positioning

---

#### 13. **Quiz Detail Screen** (Taking a Quiz)
**Purpose**: Display quiz questions and collect answers  
**Components**:
- Question number indicator (Q1/10)
- Question text (large, centered)
- 4 answer option cards
- Progress bar
- Timer (if timed quiz)
- Score display
- Skip button
- Submit button
- Back button

**Design Requirements**:
- Large question text
- Clear answer cards
- Visual feedback on selection
- Confetti animation on correct answer

---

#### 14. **Quiz Results Screen**
**Purpose**: Show quiz performance  
**Components**:
- Score display (large, centered)
- Percentage circle chart
- Correct/Incorrect breakdown
- "Review Answers" button
- "Try Again" button
- "Return Home" button
- Reward badges (if applicable)

---

#### 15. **Search Languages Page**
**Purpose**: Search and filter all available languages  
**Components**:
- Search bar
- Language list (filtered)
- Each item shows:
  - Language name
  - Flag/icon
  - Number of lessons
  - Difficulty level
- Close/Back button

---

### 📚 COURSES TAB SCREENS (3 Screens)

#### 16. **Courses Tab**
**Purpose**: Browse all available courses/languages  
**Components**:
- Header with title "My Courses"
- List/Grid of enrolled languages
- "Browse All Languages" button
- Each course card:
  - Language image
  - Language name
  - Progress bar
  - Last accessed date
  - Continue button

---

#### 17. **History Sections Screen**
**Purpose**: Learn about history of people who speak the language  
**Components**:
- Language header
- List of history sections:
  - Section title
  - Section thumbnail image
  - Duration/length indicator
  - Completion status
- Back button

---

#### 18. **Mannerisms Screen**
**Purpose**: Learn cultural mannerisms and etiquette  
**Components**:
- Language header
- List of mannerism topics:
  - Topic title (e.g., "Greetings", "Eating etiquette")
  - Topic icon
  - Video thumbnail
  - Duration
- Back button

---

### 📊 STANDINGS/LEADERBOARD TAB SCREENS (3 Screens)

#### 19. **Standings Tab**
**Purpose**: View leaderboard rankings  
**Components**:
- Header with gradient
- Greeting text
- Gold bar illustration
- Segmented control: GLOBAL | COUNTRY
- Leaderboard list:
  - Rank number (or 🏆 for top 3)
  - User avatar
  - Username
  - Country flag
  - Points/score
  - Highlight current user
- Refresh indicator

**Design Requirements**:
- Gradient header (gold/orange)
- Trophy icons for top 3
- Highlighted row for current user
- Smooth scrolling
- Pull to refresh

---

#### 20. **Global Tab** (Within Standings)
**Purpose**: Global leaderboard  
**Components**:
- Same as Standings Tab but filtered to global users

---

#### 21. **Country Tab** (Within Standings)
**Purpose**: Country-specific leaderboard  
**Components**:
- Same as Standings Tab but filtered to user's country
- Country flag header

---

### 👤 PROFILE TAB SCREENS (8 Screens)

#### 22. **Profile Tab** (Main Profile View)
**Purpose**: User's personal profile summary  
**Components**:
- Header section:
  - User avatar (circular, large)
  - Username
  - Level badge
  - Total XP
  - Edit profile button
- Stats cards:
  - Lessons completed
  - Quizzes taken
  - Days active
  - Current streak
- Recent activity list
- Settings button
- Logout button

---

#### 23. **Profile Edit Screen**
**Purpose**: Edit user profile information  
**Components**:
- Avatar upload/change button
- Username field
- First name field
- Last name field
- Email field (read-only)
- Nationality selector
- Bio text area
- Save button
- Cancel button
- Back button

---

#### 24. **User Profile Screen** (Viewing Another User)
**Purpose**: View another user's profile  
**Components**:
- User avatar
- Username
- Nationality flag
- Level and XP
- Stats (lessons, quizzes, streak)
- "Send Message" button
- "Add Friend" button
- Back button

**Design Requirements**:
- Gradient header (red to orange)
- Pattern overlay
- Stat cards with icons
- Action buttons at bottom

---

#### 25. **About Us Screen**
**Purpose**: Information about LingAfriq  
**Components**:
- App logo
- Mission statement
- Team information
- Social media links
- Contact information
- Back button

---

#### 26. **App Policy Screen**
**Purpose**: Privacy policy and terms  
**Components**:
- Policy title
- Scrollable policy text
- Accept button (if needed)
- Back button

---

#### 27. **Change Password Screen**
**Purpose**: Update user password  
**Components**:
- Current password field
- New password field
- Confirm new password field
- Password strength indicator
- "Update Password" button
- Back button

---

#### 28. **Suggest Language Screen**
**Purpose**: Users can suggest languages to add  
**Components**:
- Language name input
- Country/Region input
- Why you want this language (text area)
- Number of speakers (optional)
- Submit button
- Back button

---

#### 29. **Delete Account Dialog**
**Purpose**: Confirm account deletion  
**Components**:
- Warning icon
- Warning message
- "Are you sure?" text
- Consequences list
- "Delete Account" button (red)
- "Cancel" button
- Confirmation checkbox

---

### 🎮 GAME SCREENS (6 Screens)

#### 30. **Games Screen** (Game Selection)
**Purpose**: Choose which language game to play  
**Components**:
- Header: "Language Games" with subtitle "Learn through play"
- Language selector (if multiple languages learned)
- Game type cards (3 cards):
  1. **Word Match Game**
     - Icon: puzzle pieces
     - Title: "Word Match"
     - Description: "Match words to their translations"
     - Difficulty indicator
     - Play button
     
  2. **Speed Challenge**
     - Icon: lightning bolt
     - Title: "Speed Challenge"
     - Description: "Answer as fast as you can"
     - High score display
     - Play button
     
  3. **Pronunciation Game**
     - Icon: microphone
     - Title: "Pronunciation Practice"
     - Description: "Listen and identify correct pronunciation"
     - Play button
- Leaderboard preview
- Back button
- Drawer menu button

**Design Requirements**:
- Gradient header
- Large game cards with icons
- Colorful, playful design
- Score displays
- Animated icons

---

#### 31. **Word Match Game**
**Purpose**: Match African words to English translations  
**Components**:
- Timer display
- Score display
- Grid of word cards:
  - Left column: African language words
  - Right column: English translations
- Match indicator lines
- "Submit" button
- "Give Up" button
- Lives/attempts remaining
- Back button

**Design Requirements**:
- Card-based layout
- Matching animation (connecting lines)
- Color coding for matches
- Timer countdown

---

#### 32. **Speed Challenge Game**
**Purpose**: Quick-fire translation questions  
**Components**:
- Large countdown timer
- Question counter (1/20)
- Question text
- 4 answer buttons (large, colorful)
- Score running total
- Streak counter
- Combo multiplier indicator
- Sound effects toggle
- Pause button
- Back button

**Design Requirements**:
- High energy colors
- Large buttons
- Prominent timer
- Streak animations
- Combo visual effects

---

#### 33. **Pronunciation Game**
**Purpose**: Listen and identify correct pronunciation  
**Components**:
- Large speaker icon/button (play audio)
- Question text: "Which pronunciation is correct?"
- 4 option cards with:
  - Play button icon
  - Pronunciation text/phonetic
  - Visual waveform (optional)
- Score display
- Question counter
- Lives remaining
- Hint button
- Back button

**Design Requirements**:
- Audio-focused design
- Large play buttons
- Visual feedback on audio playing
- Clear option cards

---

#### 34. **Language Games Screen** (Alternate)
**Purpose**: Alternative game launcher  
**Components**:
- Game selection with language filter
- Recent scores
- Achievements earned from games

---

#### 35. **Game Results/Score Screen**
**Purpose**: Show game performance after completion  
**Components**:
- Final score (large, animated)
- Stars rating (1-3 stars)
- Accuracy percentage
- Time taken
- XP earned
- Leaderboard position
- "Play Again" button
- "Share Score" button
- "Return to Games" button
- Back button

---

### 🎯 GOAL & PROGRESS SCREENS (4 Screens)

#### 36. **Daily Goals Screen**
**Purpose**: Show daily learning goals and streak  
**Components**:
- **Streak Card**:
  - Fire emoji (🔥)
  - "[X] Day Streak" (large)
  - Motivational message
  - Green gradient background
  - Glow effect
  
- **Goals List** (each goal card):
  - Icon (emoji)
  - Goal title (e.g., "Complete Lessons")
  - Progress: "X / Y"
  - Progress bar (0-100%)
  - Completion badge (✓ Done)
  - Clickable to navigate to feature
  
- Goal types:
  - Complete Lessons (📚)
  - Take Quizzes (🎯)
  - Play Games (🎮)
  - Chat with Polie (💬)
  - Learn Words (📝)
  
- Back button
- Refresh functionality

**Design Requirements**:
- Green gradient streak card
- White/semi-transparent goal cards
- Circular progress indicators
- Achievement badges
- Motivational colors

---

#### 37. **Daily Challenges Screen**
**Purpose**: Special daily challenges for bonus rewards  
**Components**:
- Challenge cards:
  - Challenge title
  - Challenge description
  - Reward display (XP/badges)
  - Time remaining countdown
  - Progress indicator
  - Accept/Start button
- Completed challenges section
- Back button

---

#### 38. **Progress Dashboard / Activity Distribution Screen**
**Purpose**: Detailed progress analytics  
**Components**:
- **Overview Cards** (row of 4):
  - Words Learned (📚)
  - Known Words (✨)
  - Listening Hours (🎧)
  - Speaking Hours (🎤)
  
- **Charts**:
  - Words learned over time (line chart)
  - Activity distribution (pie chart):
    - Lessons time
    - Quiz time
    - Game time
    - Chat time
  - Time spent per day (bar chart)
  - Weekly progress (heatmap calendar)
  
- **Insights**:
  - Best learning time
  - Most productive day
  - Current level (CEFR: A1, A2, B1, B2, C1, C2)
  
- Filter buttons: Week | Month | Year | All Time
- Export data button
- Back button

**Design Requirements**:
- Card-based metrics
- Colorful charts
- Green/orange/gold color scheme
- Smooth animations
- fl_chart library usage

---

#### 39. **Global Progress Screen**
**Purpose**: Community-wide statistics and global ranking  
**Components**:
- **Header**:
  - Gradient background (gold to orange)
  - Trophy icon
  - Title: "Global Ranking"
  - Subtitle: "Top learners worldwide"
  
- **Global Stats Cards**:
  - Total Users (🌍)
  - Total Words Learned (📚)
  - Total Hours (⏱️)
  - Active Languages (🗣️)
  
- **Top Languages Chart** (bar chart):
  - Top 5 most learned languages
  - Learner count for each
  - Color-coded bars
  
- **Top Learners List**:
  - Rank (#1, #2, #3 with trophies)
  - User avatar
  - Username
  - Country flag
  - Total points
  - Highlight for top 3
  
- Refresh button
- Back button

**Design Requirements**:
- Gold gradient header
- Trophy icons for winners
- Flag emojis
- Colorful bar charts
- Prominent stats

---

### 🏆 ACHIEVEMENT SCREENS (1 Screen)

#### 40. **Achievements Screen**
**Purpose**: Display earned and locked achievements/badges  
**Components**:
- **Header**:
  - Gradient background (gold to orange)
  - Trophy icon (large)
  - Title: "Achievements"
  - Subtitle: "Your rewards & badges"
  - Back button
  
- **Level & XP Card** (top):
  - Current level (large)
  - Total XP
  - XP progress to next level (progress bar)
  - Star icon
  - Stats: Unlocked count, Total count, Completion %
  
- **Tabs**: Badges | Streaks | XP
  
- **Badges Tab** (3-column grid):
  - Each achievement card:
    - Icon/emoji (large)
    - Achievement name
    - Description
    - XP reward (+X XP)
    - Rarity indicator (common, rare, epic, legendary)
    - Unlock date
    - Locked badges are greyed out (40% opacity)
    - Border color based on rarity
  
- **Streaks Tab**:
  - Large fire icon
  - Current streak days
  - Weekly calendar visualization
  - Longest streak
  
- **XP Tab**:
  - Total XP (large)
  - Level display
  - XP to next level
  - Progress bar
  - XP breakdown by activity

**Design Requirements**:
- Gradient header
- Card grid for badges
- Rarity color coding:
  - Common: Grey
  - Uncommon: Green
  - Rare: Blue
  - Epic: Purple
  - Legendary: Orange/Gold
- Locked items: Low opacity with lock icon
- Glow effects for unlocked items

---

### 💬 CHAT & SOCIAL SCREENS (6 Screens)

#### 41. **AI Chat Select Screen**
**Purpose**: Choose between Translation and Tutor mode  
**Components**:
- **Header**:
  - Gradient background (purple to red)
  - Pattern overlay
  - AI icon (auto_awesome_rounded)
  - Title: "AI Language Assistant"
  - Subtitle: "Choose how you'd like to practice"
  - Back button
  
- **Mode Cards** (2 large cards):
  
  1. **Translator Mode Card**:
     - Icon: translate_rounded
     - Title: "Translator Mode"
     - Description: "Instant translations between English and Swahili. Perfect for quick lookups."
     - Badge: "Quick & Easy"
     - Gradient: Green to Blue
     - Tap to enter
     
  2. **Tutor Mode Card**:
     - Icon: school_rounded
     - Title: "Tutor Mode"
     - Description: "Practice conversations with your AI tutor. Get feedback and corrections."
     - Badge: "Interactive Learning"
     - Gradient: Red to Orange
     - Tap to enter

**Design Requirements**:
- Large tappable cards
- Gradient backgrounds
- Clear mode distinction
- Icons and badges
- Smooth animations

---

#### 42. **AI Chat Screen** (The Main Chat Interface)
**Purpose**: Chat with Polie AI assistant  
**Components**:
- **Top App Bar**:
  - Drawer/menu button
  - "LingAfriq Polyglot (Polie)" title
  - Message count subtitle
  - Language direction button
  - Mute/unmute volume button (🔊/🔇)
  - Delete chat button
  - Back button
  
- **Mode Selector** (Segmented button):
  - Translation mode
  - Tutor mode
  - Visual indicator of active mode
  
- **Chat Messages Area**:
  - User messages (right side, colored bubble)
  - AI messages (left side, different color)
  - Timestamp on each message
  - Typing indicator when AI is responding
  - Streaming text display
  - Scroll to bottom button
  - Empty state: "Start a conversation with Polie"
  
- **Input Area** (bottom):
  - Text input field
  - Microphone button (for voice input)
  - Send button
  - Recording indicator (when recording)
  - Character count (optional)

**Design Requirements**:
- Material 3 design
- Green primary color
- Distinct message bubbles
- Smooth scrolling
- Voice input waveform animation
- Typing indicator dots
- Gradient backgrounds for messages

---

#### 43. **Global Chat Screen**
**Purpose**: Public chat rooms by language/topic  
**Components**:
- **Header**:
  - Gradient background (green to blue)
  - Back button
  - Title with language/room name
  - Online users count
  - Room selector dropdown
  
- **Room Selection** (chips):
  - General
  - Language-specific rooms
  - Help & Questions
  - Cultural Exchange
  
- **Chat Area**:
  - Messages from all users
  - User avatar + username + message
  - Timestamp
  - Current user messages highlighted
  - Auto-scroll to bottom
  
- **Online Users Sidebar** (collapsible):
  - List of online users
  - Green dot indicator
  - Tap to view profile or send DM
  
- **Input Area**:
  - Message text field
  - Emoji button
  - Send button
  - Connection status indicator

**Design Requirements**:
- Room-based layout
- User avatars
- Online indicators (green dots)
- Smooth message animations
- Different colors per user

---

#### 44. **Private Chat List Screen**
**Purpose**: List of private conversations  
**Components**:
- **Header**:
  - Gradient background (purple to red)
  - Title: "Private Chats"
  - Back button
  - New chat button
  
- **Search Bar**:
  - Search conversations
  - Filter icon
  
- **Chat List**:
  - Each chat item:
    - User avatar
    - Username
    - Last message preview
    - Timestamp
    - Unread count badge (if any)
    - Online status indicator
  - Empty state: "No messages yet"
  
- **Floating Action Button**:
  - "New Chat" button

**Design Requirements**:
- List-based layout
- Unread badges (red circle with number)
- Green online dot
- Swipe actions (delete, archive)
- Time formatting (Just now, 5m ago, Yesterday)

---

#### 45. **Private Chat Screen** (1-on-1 Chat)
**Purpose**: Private messaging with another user  
**Components**:
- **App Bar**:
  - Back button
  - User avatar
  - Username
  - Online status (green dot or "Last seen...")
  - Video call button (optional)
  - More options (block, report)
  
- **Chat Messages**:
  - User messages (right, blue bubble)
  - Other user messages (left, grey bubble)
  - Timestamps
  - Read receipts (checkmarks)
  - Typing indicator
  
- **Input Area**:
  - Text field
  - Attachment button
  - Emoji button
  - Send button
  - Voice message button

**Design Requirements**:
- Distinct bubbles for sender/receiver
- Read receipts
- Smooth scrolling
- Message animations

---

#### 46. **User Connections Screen** (Connect with Users)
**Purpose**: Find and connect with other learners  
**Components**:
- **Header**:
  - Title: "Connect with Learners"
  - Back button
  - "Private chats" button (top right)
  
- **Search Bar**:
  - Placeholder: "Search users..."
  - Search icon
  - Filters: By language, by country, by level
  
- **Connection Status Indicator**:
  - Connected/Disconnected status
  - Online user count
  
- **User List**:
  - Each user card:
    - Avatar
    - Username
    - Country flag
    - Languages learning (chips)
    - Level badge
    - Online status (green dot)
    - "Connect" or "Message" button
  - Empty state: "No users found"
  
- **Filter Chips**:
  - All
  - Online
  - Learning Same Language
  - Same Country

**Design Requirements**:
- Card-based user list
- Online indicators
- Language chips
- Clear action buttons

---

### 📰 CONTENT SCREENS (2 Screens)

#### 47. **Culture Magazine Screen** (Cultural Magazinet)
**Purpose**: Articles and content about African culture  
**Components**:
- **Header**:
  - Gradient background (orange to purple)
  - Newspaper icon
  - Title: "Cultural Magazines"
  - Subtitle: "Explore African culture"
  - Back button
  
- **Featured Section**:
  - Large featured article card:
    - Cover image
    - Article title
    - Author/source
    - Read time
    - Category badge
  
- **Tabs**: Featured | History | Culture | Language | Music | Food
  
- **Article Grid** (2 columns):
  - Each article card:
    - Thumbnail image
    - Title
    - Excerpt (2 lines)
    - Category tag
    - Read time
    - Bookmark icon
  
- **Search/Filter**:
  - Search articles
  - Category filter
  - Country filter
  
- Empty state: "No articles available"

**Design Requirements**:
- Magazine-style layout
- Beautiful images
- Category color coding
- Card shadows
- Bookmark feature

---

#### 48. **Import Media Screen**
**Purpose**: Import and share user's own content  
**Components**:
- **Header**:
  - Gradient background (green to blue)
  - Upload icon
  - Title: "Media Import"
  - Subtitle: "Share your content with the community"
  - Back button
  
- **Upload Options** (3 cards):
  1. **Upload File**:
     - File icon
     - "Choose File" button
     - Supported formats list
     
  2. **Enter URL**:
     - Link icon
     - URL text field
     - "Import from URL" button
     
  3. **Paste Text**:
     - Text icon
     - Large text area
     - "Import Text" button
  
- **Language Selector**:
  - "Select language for this content"
  - Dropdown with languages
  
- **Preview Section** (after import):
  - Content preview
  - Edit button
  - Submit button
  
- **Imported Items List**:
  - User's previously imported content
  - Edit/Delete options

**Design Requirements**:
- Upload-focused design
- Clear CTAs
- File type icons
- Progress indicators for upload

---

### 📚 CURRICULUM & LEARNING SCREENS (4 Screens)

#### 49. **Comprehensive Curriculum Screen**
**Purpose**: View structured learning curriculum  
**Components**:
- **Header**:
  - Title: "Comprehensive Curriculum"
  - Back button
  - Refresh button
  
- **Language Selector**:
  - Chip-based selector
  - All available curriculum languages
  
- **Loading State**:
  - Progress indicator
  - "Loading curriculum..." text
  
- **Empty State**:
  - Book icon
  - "No curriculum loaded"
  - Error message (if applicable)
  - "Load Curriculum" button
  - "Try Expanded Bundle" link
  
- **Curriculum Content** (when loaded):
  - **Level Cards** (A1, A2, B1, B2):
    - Level title
    - Progress bar
    - Unit count
    - Completion status
    - Expand/collapse
    
  - **Unit Cards** (within levels):
    - Unit number and title
    - Lesson list
    - Progress indicator
    
  - **Lesson Items**:
    - Lesson title
    - Vocabulary count
    - Exercise count
    - Completion checkmark
    - Locked/unlocked state

**Design Requirements**:
- Expandable/collapsible sections
- Progress indicators
- Lock icons for locked content
- Clear level hierarchy
- CEFR color coding

---

#### 50. **Curriculum Viewer Screen**
**Purpose**: View specific curriculum lesson content  
**Components**:
- Lesson content viewer
- Navigation between lessons
- Progress tracking

---

#### 51. **Listening Quiz Screen**
**Purpose**: Listening comprehension practice  
**Components**:
- Audio player
- Question text
- Answer options
- Progress indicator
- Score display

---

#### 52. **Shadowing Exercise Screen**
**Purpose**: Practice speaking by shadowing native speakers  
**Components**:
- Audio player (plays native speaker)
- Record button (user records themselves)
- Playback buttons
- Waveform visualization
- Pronunciation scoring
- Retry button

---

### ⚙️ SETTINGS & UTILITY SCREENS (3 Screens)

#### 53. **Settings Screen**
**Purpose**: App configuration and preferences  
**Components**:
- **Header**:
  - Gradient background (green to blue)
  - Settings icon (gear)
  - Title: "Settings"
  - Back button
  
- **Settings Sections**:
  
  1. **Notifications**:
     - Daily reminders (toggle)
     - Achievement alerts (toggle)
     - Leaderboard updates (toggle)
     - Time picker for reminders
     
  2. **Audio**:
     - Sound effects (toggle)
     - Voice output (toggle)
     - TTS speed slider
     - Volume control
     
  3. **Display**:
     - Dark mode (toggle - auto/light/dark)
     - Text size selector (Small, Medium, Large)
     - High contrast mode (toggle)
     
  4. **Learning**:
     - Daily goal (dropdown: 10min, 15min, 20min, 30min)
     - Difficulty preference (Beginner, Intermediate, Advanced)
     - Remind to practice (toggle)
     
  5. **Account**:
     - Change password
     - Update email
     - Delete account
     - Privacy settings
     
  6. **About**:
     - App version
     - Terms of service
     - Privacy policy
     - Licenses
     - Contact support

**Design Requirements**:
- Grouped sections with headers
- Toggle switches (iOS/Android style)
- Slider controls
- Dropdown selectors
- Dividers between sections
- Icons for each setting

---

#### 54. **Modern Dashboard Screen** (Alternative Home)
**Purpose**: Alternative dashboard layout  
**Components**:
- Quick stats
- Recent activity
- Shortcuts to features
- Recommended next lesson

---

### 🎓 ADDITIONAL LEARNING SCREENS (3 Screens)

#### 55. **Introduction Screen** (Language Introduction)
**Purpose**: First-time introduction to a new language  
**Components**:
- Language name and flag
- Welcome video or images
- Brief history
- "Why learn this language?"
- "Skip intro" button
- "Continue" button
- Don't show again checkbox

---

#### 56. **Language Detail/Information Screen**
**Purpose**: Detailed information about the language  
**Components**:
- Language name
- Flag/region map
- Number of speakers
- Countries where spoken
- Difficulty rating
- Sample phrases
- History section
- Cultural facts
- "Start Learning" button

---

#### 57. **Quiz Correction/Results Screen**
**Purpose**: Review quiz answers with explanations  
**Components**:
- Question review list:
  - Question text
  - User's answer (with ✓ or ✗)
  - Correct answer (if wrong)
  - Explanation
- Score summary at top
- "Continue" button
- "Retake Quiz" button

---

## 🎨 REUSABLE COMPONENTS & WIDGETS

### Navigation Components

#### 58. **App Drawer** (Side Menu)
**Purpose**: Main navigation menu  
**Components**:
- **Header Section**:
  - User avatar
  - Username
  - Level badge
  
- **Menu Items** (with icons):
  - 🏠 Home
  - 👤 Profile
  - 💬 AI Chat
  - 🎮 Language Games
  - 🎯 Daily Goals
  - 📊 Progress Dashboard
  - 🏆 Achievements
  - 🌍 Global Progress
  - 📤 Import Media
  - 📰 Culture Magazine
  - 👥 Connect with Users
  - 💭 Global Chat
  - 🔒 Private Chats
  - 📚 Comprehensive Curriculum
  - ⚙️ Settings
  - 📋 App Policy
  
- **Logout Button** (bottom):
  - Red/warning color
  - Confirmation dialog

**Design Requirements**:
- Gradient header
- List of nav items
- Icons for each item
- Highlight active item
- Smooth slide animation

---

### UI Components

#### 59. **Top Gradient Box**
**Purpose**: Reusable gradient header component  
**Components**:
- Gradient background
- Rounded bottom corners
- Shadow
- Content slot

---

#### 60. **Primary Button**
**Purpose**: Main action button used throughout app  
**Components**:
- Text label
- Optional icon
- Loading state
- Disabled state
- Various colors (green, orange, red)

**Variants**:
- Filled button
- Outlined button
- Text button

---

#### 61. **Primary Text Field**
**Purpose**: Standard input field  
**Components**:
- Label text
- Hint text
- Input field
- Validation message
- Show/hide toggle (for passwords)
- Prefix/suffix icons

---

#### 62. **Modern Language Card**
**Purpose**: Card displaying a language with image  
**Components**:
- Background image
- Language name overlay
- Featured badge
- Gradient overlay for readability
- Tap to select
- Completion indicator

---

#### 63. **Error Boundary Widget**
**Purpose**: Catch and display errors gracefully  
**Components**:
- Error icon (red)
- Error title
- Error message
- Retry button
- Back button
- Support contact link

---

#### 64. **Loading Overlay**
**Purpose**: Full-screen loading indicator  
**Components**:
- Semi-transparent overlay
- Circular progress indicator
- Loading text
- Cancel button (optional)

---

#### 65. **App Logo Widget**
**Purpose**: Reusable logo component  
**Components**:
- LingAfriq logo image
- Configurable size
- Optional animation

---

#### 66. **Greeting Builder Widget**
**Purpose**: Displays greetings with user name  
**Components**:
- Greeting text (rotating)
- User name
- Time-based greeting (Good morning, etc.)

---

#### 67. **Achievement Badge Widget**
**Purpose**: Display achievement/badge  
**Components**:
- Badge icon
- Badge name
- Rarity indicator
- Unlock animation

---

#### 68. **Progress Circle Widget**
**Purpose**: Circular progress indicator  
**Components**:
- Circle with percentage
- Color coding by progress
- Animated fill

---

#### 69. **Stat Card Widget**
**Purpose**: Display statistics  
**Components**:
- Icon
- Value (large number)
- Label text
- Background color/gradient
- Shadow

---

#### 70. **Language Chip Widget**
**Purpose**: Small language tag/chip  
**Components**:
- Language name
- Flag emoji
- Optional close button
- Color coding

---

## 📊 SCREEN CATEGORIES SUMMARY

### By Feature:
- **Authentication**: 6 screens
- **Main Navigation**: 4 tabs
- **Home/Languages**: 6 screens
- **Learning (Lessons/Quizzes)**: 8 screens
- **Games**: 6 screens
- **Social/Chat**: 6 screens
- **Progress/Goals**: 5 screens
- **Profile**: 8 screens
- **Settings**: 3 screens
- **Content**: 2 screens

### Total: **54 Main Screens + 16 Reusable Components = 70 UI Elements**

---

## 🎯 FIGMAMAKE PROMPT TEMPLATE

Use this format for each screen:

```
Create a modern, beautiful mobile app screen for [SCREEN NAME]

App Context: African language learning app called LingAfriq
Screen Purpose: [PURPOSE]
Target Users: Language learners (teens to adults)

Design Style:
- Modern, clean, Material 3 design
- African-inspired with warm colors
- Use gradients: Green (#007A3D), Orange (#FF6B35), Gold (#FCD116), Purple (#7B2CBF), Red (#CE1126)
- Support both light and dark mode
- Playful but professional
- Highly engaging and motivational

Screen Components:
[LIST COMPONENTS WITH DESCRIPTIONS]

Layout Requirements:
- Mobile-first (428x926 design size)
- Safe area aware
- Smooth animations
- Accessibility-friendly
- Touch-friendly tap targets (min 44x44)

Additional Requirements:
[SPECIFIC TO EACH SCREEN]
```

---

## 📝 NOTES FOR FIGMAMAKE

### Design Principles:
1. **African Cultural Elements**: Use patterns, colors, and imagery inspired by African art and culture
2. **Learning-Focused**: Clear, readable, non-distracting
3. **Gamification**: Progress bars, badges, rewards, celebrations
4. **Motivational**: Encouraging messages, achievements, streaks
5. **Community**: Social features, leaderboards, connections
6. **Accessibility**: High contrast, large text options, screen reader friendly

### Color Usage Guidelines:
- **Green (#007A3D)**: Primary actions, success, learning
- **Orange (#FF6B35)**: Secondary actions, games, fun
- **Gold (#FCD116)**: Achievements, rewards, premium
- **Purple (#7B2CBF)**: Social, communication, AI features
- **Red (#CE1126)**: Warnings, challenges, competitive

### Typography:
- **Font Family**: Dosis (currently used)
- **Weights**: 100, 300, 400, 500, 600, 700, 800
- **Sizes**: Responsive using Flutter ScreenUtil

### African Patterns to Consider:
- Kente cloth patterns
- Adinkra symbols
- Mudcloth designs
- Tribal geometric patterns
- Savanna landscapes
- Baobab trees
- African wildlife silhouettes

---

## 🚀 PRIORITY FOR REDESIGN

### High Priority (Most Used):
1. Home Tab/Dashboard
2. AI Chat Screen
3. Take a Quiz Screen
4. Daily Goals Screen
5. Achievements Screen

### Medium Priority:
6. Profile screens
7. Game screens
8. Leaderboard
9. Settings

### Lower Priority:
10. Content screens
11. Social features
12. Utility screens

---

This inventory provides everything FigmaMake needs to generate beautiful, modern UIs for every single screen in your app!


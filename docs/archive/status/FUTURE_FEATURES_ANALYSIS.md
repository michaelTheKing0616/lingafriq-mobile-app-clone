# Future Features Analysis - Empty onPressed Handlers

## Date: January 23, 2026
## Purpose: Identify all empty onPressed handlers and determine if features can be implemented now

---

## 📋 SUMMARY OF EMPTY HANDLERS

### ✅ **FEATURES THAT CAN BE IMPLEMENTED NOW** (Screens Already Exist)

#### 1. **Settings Screen Navigation** ✅
- **Location**: `modern_dashboard_screen.dart:152`
- **Current**: Empty handler for settings button
- **Feature**: Navigate to settings screen
- **Status**: ✅ **CAN IMPLEMENT** - `SettingsScreenMaterial3` exists
- **Implementation**: 
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SettingsScreenMaterial3()),
  );
  ```

#### 2. **Lessons List Navigation** ✅
- **Location**: `modern_dashboard_screen.dart:333` ("Continue Learning" quick action)
- **Current**: Empty handler with comment "Navigate to lessons"
- **Feature**: Navigate to lessons list screen
- **Status**: ✅ **CAN IMPLEMENT** - `LessonsListScreen` exists
- **Note**: Need to determine which language to show (may need language selection first)

#### 3. **Subscription Screen Navigation** ✅
- **Location**: `offline_content_screen.dart:59`
- **Current**: Empty handler with comment "Navigate to subscription screen"
- **Feature**: Navigate to subscription screen
- **Status**: ✅ **CAN IMPLEMENT** - `SubscriptionScreen` exists
- **Implementation**:
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SubscriptionScreen()),
  );
  ```

#### 4. **Pronunciation Game Navigation** ✅
- **Location**: `games_screen.dart:263`
- **Current**: Empty handler with comment "Navigate to pronunciation game"
- **Feature**: Navigate to pronunciation game
- **Status**: ✅ **CAN IMPLEMENT** - `pronunciation_game.dart` exists
- **Implementation**:
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => PronunciationGameScreen()),
  );
  ```

#### 5. **Speed Challenge Game Navigation** ✅
- **Location**: `games_screen.dart:273`
- **Current**: Empty handler with comment "Navigate to speed challenge game"
- **Feature**: Navigate to speed challenge game
- **Status**: ✅ **CAN IMPLEMENT** - `speed_challenge_game.dart` exists
- **Implementation**:
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SpeedChallengeGameScreen()),
  );
  ```

#### 6. **Dashboard "See All" Button** ✅
- **Location**: `dashboard_screen_material3.dart:251`
- **Current**: Empty handler for "See All" button in "Continue Learning" section
- **Feature**: Show all lessons/continue learning items
- **Status**: ✅ **CAN IMPLEMENT** - Can navigate to lessons list or show expanded view
- **Implementation**: Navigate to `LessonsListScreen` or show bottom sheet with all items

---

### ⚠️ **FEATURES NEEDING NEW SCREENS** (Screens Don't Exist Yet)

#### 7. **Edit Profile Screen** ⚠️
- **Location**: `settings_screen_material3.dart:250`
- **Current**: Empty handler for "Edit Profile" list tile
- **Feature**: Edit user profile (name, email, avatar, etc.)
- **Status**: ⚠️ **NEEDS NEW SCREEN** - No `EditProfileScreen` found
- **Implementation Required**: 
  - Create `EditProfileScreen` widget
  - Add form fields for: first name, last name, email, avatar
  - Add API call to update profile
  - Add validation

#### 8. **Change Password Screen** ⚠️
- **Location**: `settings_screen_material3.dart:256`
- **Current**: Empty handler for "Change Password" list tile
- **Feature**: Change user password
- **Status**: ⚠️ **NEEDS NEW SCREEN** - No `ChangePasswordScreen` found
- **Implementation Required**:
  - Create `ChangePasswordScreen` widget
  - Add form fields: current password, new password, confirm password
  - Add API call to change password
  - Add validation and security checks

#### 9. **Privacy Settings Screen** ⚠️
- **Location**: `settings_screen_material3.dart:262`
- **Current**: Empty handler for "Privacy Settings" list tile
- **Feature**: Configure privacy settings (data sharing, analytics, etc.)
- **Status**: ⚠️ **NEEDS NEW SCREEN** - No `PrivacySettingsScreen` found
- **Implementation Required**:
  - Create `PrivacySettingsScreen` widget
  - Add toggles for: analytics, data sharing, personalized ads, etc.
  - Add API calls to save preferences
  - Add local storage for preferences

#### 10. **Fill in the Blank Game** ⚠️
- **Location**: `games_screen.dart:253`
- **Current**: Empty handler with comment "Navigate to fill in the blank game"
- **Feature**: Fill in the blank game screen
- **Status**: ⚠️ **NEEDS NEW SCREEN** - No `FillInTheBlankGameScreen` found
- **Implementation Required**:
  - Create `FillInTheBlankGameScreen` widget
  - Implement game logic for sentence completion
  - Add scoring and progress tracking
  - Integrate with gamification system

#### 11. **Vocabulary Category Filter** ⚠️
- **Location**: `vocabulary_flashcard_screen.dart:82`
- **Current**: Empty handler with comment "Show category filter"
- **Feature**: Show filter dialog/sheet for vocabulary categories
- **Status**: ⚠️ **NEEDS IMPLEMENTATION** - Filter UI needed
- **Implementation Required**:
  - Create filter bottom sheet or dialog
  - Add category selection UI
  - Filter vocabulary list by selected categories
  - Save filter preferences

#### 12. **Classroom Participants Button** ⚠️
- **Location**: `classroom_chat_livekit_screen.dart:134` (mentioned in audit)
- **Current**: Empty handler for participants button
- **Feature**: Show list of participants in classroom
- **Status**: ⚠️ **NEEDS IMPLEMENTATION** - Participants list UI needed
- **Implementation Required**:
  - Create participants list bottom sheet or screen
  - Show list of current participants
  - Show participant status (muted, video on/off, etc.)
  - Add participant actions (mute, kick, etc.) if user is host

#### 13. **Curriculum Lesson Detail Navigation** ✅
- **Location**: `lib/screens/tutor/curriculum_viewer_screen.dart:96` (mentioned in audit)
- **Current**: Empty handler for lesson detail navigation
- **Feature**: Navigate to lesson detail screen
- **Status**: ✅ **CAN IMPLEMENT** - `LessonDetailScreen` exists at `lib/screens/curriculum/lesson_detail_screen.dart`
- **Implementation**: 
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => LessonDetailScreen(
        lesson: lesson, // Need lesson object
        language: language, // Need language string
        level: level, // Need level string
      ),
    ),
  );
  ```
- **Note**: Need to verify what data is available in curriculum_viewer_screen to pass to LessonDetailScreen

#### 14. **Free Tier Selection** ✅ (Intentional)
- **Location**: `subscription_screen.dart:64`
- **Current**: Empty handler for free tier selection
- **Feature**: Select free tier (no action needed)
- **Status**: ✅ **INTENTIONAL** - Free tier doesn't require action, already active
- **Note**: This is correct behavior - free tier is already active, no action needed

---

## 🎯 IMPLEMENTATION PRIORITY

### **HIGH PRIORITY** (Easy Wins - Screens Exist)
1. ✅ Settings screen navigation (`modern_dashboard_screen.dart:152`)
2. ✅ Subscription screen navigation (`offline_content_screen.dart:59`)
3. ✅ Pronunciation game navigation (`games_screen.dart:263`)
4. ✅ Speed challenge game navigation (`games_screen.dart:273`)
5. ✅ Dashboard "See All" button (`dashboard_screen_material3.dart:251`)

### **MEDIUM PRIORITY** (Screens Exist, Need Context)
6. ✅ Lessons list navigation (`modern_dashboard_screen.dart:333`)
   - Need to determine language selection flow

### **LOW PRIORITY** (Require New Screens)
7. ⚠️ Edit Profile Screen
8. ⚠️ Change Password Screen
9. ⚠️ Privacy Settings Screen
10. ⚠️ Fill in the Blank Game
11. ⚠️ Vocabulary Category Filter
12. ⚠️ Classroom Participants Button
13. ⚠️ Curriculum Lesson Detail Navigation (needs verification)

---

## 📝 RECOMMENDED ACTION PLAN

### **Phase 1: Quick Wins (Can Do Now)**
Implement all features where screens already exist:
1. Add navigation to existing screens (settings, subscription, games)
2. Add "See All" functionality to dashboard
3. Test navigation flows

### **Phase 2: New Screens (Requires Development)**
Create new screens for:
1. Edit Profile Screen
2. Change Password Screen
3. Privacy Settings Screen
4. Fill in the Blank Game
5. Vocabulary Category Filter
6. Classroom Participants UI

### **Phase 3: Verification**
1. Verify if lesson detail screen exists for curriculum viewer
2. Test all implemented navigation flows
3. Ensure proper error handling

---

## 🔍 FILES TO MODIFY

### **Immediate (Screens Exist)**
1. `lib/screens/dashboard/modern_dashboard_screen.dart` - Lines 152, 333
2. `lib/screens/dashboard/dashboard_screen_material3.dart` - Line 251
3. `lib/screens/offline/offline_content_screen.dart` - Line 59
4. `lib/screens/games/games_screen.dart` - Lines 253, 263, 273

### **Future (New Screens Needed)**
1. `lib/screens/settings/settings_screen_material3.dart` - Lines 250, 256, 262
2. `lib/screens/vocabulary/vocabulary_flashcard_screen.dart` - Line 82
3. `lib/screens/classroom/classroom_chat_livekit_screen.dart` - Line 134
4. `lib/screens/curriculum/curriculum_viewer_screen.dart` - Line 96 (verify first)

---

## ✅ NEXT STEPS

1. **Verify lesson detail screen exists** - Search for lesson detail screen
2. **Implement Phase 1 features** - Add navigation to existing screens
3. **Create implementation plan for Phase 2** - Design new screens
4. **Test all navigation flows** - Ensure proper routing

---

**Last Updated**: January 23, 2026

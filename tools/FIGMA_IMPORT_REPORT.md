# Figma Import Audit Report

## Overview
**Source**: `LingAfiq UI-UX/Static UI Screens Design/`  
**Format**: React/TypeScript (Web Components)  
**Target**: Flutter/Dart (Mobile App)  
**Total Screens**: 18 designed screens  
**Conversion Type**: React → Flutter

---

## 📱 EXPORTED SCREEN INVENTORY

### Authentication & Onboarding (6 Screens)
1. ✅ **SplashScreen.tsx** - Loading screen with Africa facts
2. ✅ **OnboardingScreen.tsx** - Kijiji multi-step onboarding
3. ✅ **ModernOnboardingScreen.tsx** - Simple 4-step onboarding
4. ✅ **LoginScreen.tsx** - User authentication
5. ✅ **SignUpScreen.tsx** - New user registration
6. ✅ **ForgotPasswordScreen.tsx** - Password reset

### Main App Screens (12 Screens)
7. ✅ **MainTabsScreen.tsx** - Bottom navigation with 4 tabs
8. ✅ **HomeScreen.tsx** - Featured languages dashboard
9. ✅ **LanguageDetailScreen.tsx** - Language information
10. ✅ **LessonsListScreen.tsx** - Available lessons
11. ✅ **LessonDetailScreen.tsx** - Individual lesson content
12. ✅ **QuizSelectionMapScreen.tsx** - Quiz type selection map
13. ✅ **TakeQuizScreen.tsx** - Quiz interface
14. ✅ **AIChatScreen.tsx** - Chat with Polie AI
15. ✅ **DailyGoalsScreen.tsx** - Daily learning goals
16. ✅ **AchievementsScreen.tsx** - Badges and rewards

### Index File
17. ✅ **AllScreensIndex.tsx** - Screen navigation index

### Support Components
18. ✅ **ImageWithFallback.tsx** - Image component with fallback

---

## 🔄 CONVERSION REQUIREMENTS

### All Screens Require:
✅ **React → Flutter Conversion**
- Replace React components with Flutter widgets
- Replace JSX/TSX with Dart
- Replace CSS/Tailwind with Flutter styling
- Replace HTML elements with Material/Cupertino widgets

✅ **Web APIs → Mobile APIs**
- Replace `useState` → `State` management (Riverpod/StatefulWidget)
- Replace `useEffect` → `initState()` / `didChangeDependencies()`
- Replace `onClick` → `onTap` / `onPressed`
- Replace CSS classes → `BoxDecoration` / `TextStyle`

✅ **Dependencies to Add**
- None - Flutter has everything built-in!
- Already using: hooks_riverpod, flutter_screenutil

---

## 📦 ASSETS NEEDED

### Images Referenced in Screens:
1. Language background images (Unsplash URLs in Figma - need to download/replace)
2. App logo
3. African person illustrations
4. Pattern backgrounds
5. Flag emojis/icons

### Fonts:
- ✅ **Dosis** - Already in project (`assets/fonts/`)
- Weights: 100, 300, 400, 500, 600, 700, 800

### Icons:
- ✅ Using Material Icons (built into Flutter)
- lucide-react icons → Material Icons equivalent

---

## 🛠️ MIGRATION PLAN

### Phase 1: Direct Replacement (Simple Screens)
**Target**: Screens with similar existing Flutter implementations  
**Action**: Update styling to match Figma designs

1. **SplashScreen.tsx → lib/screens/splash/splash_screen.dart**
   - ✅ Already exists
   - **Action**: Update colors, layout, animations to match Figma
   - **Complexity**: LOW
   - **Time**: 1 hour

2. **LoginScreen.tsx → lib/screens/auth/login_screen.dart**
   - ✅ Already exists
   - **Action**: Update styling, add gradient background
   - **Complexity**: LOW
   - **Time**: 1 hour

3. **SignUpScreen.tsx → lib/screens/auth/sign_up_screen.dart**
   - ✅ Already exists
   - **Action**: Update styling, match Figma design
   - **Complexity**: LOW
   - **Time**: 1 hour

4. **ForgotPasswordScreen.tsx → lib/screens/auth/forgot_password_screen.dart**
   - ✅ Already exists
   - **Action**: Update styling
   - **Complexity**: LOW
   - **Time**: 30 min

---

### Phase 2: Enhanced Replacement (Medium Complexity)
**Target**: Screens that need significant UI updates

5. **HomeScreen.tsx → lib/screens/tabs_view/home/home_tab.dart**
   - ✅ Already exists
   - **Action**: Update grid layout, card design, gradient header
   - **Complexity**: MEDIUM
   - **Time**: 2 hours
   - **Changes Needed**:
     - Update language card design
     - Add search bar styling
     - Update gradient colors
     - Improve grid spacing

6. **MainTabsScreen.tsx → lib/screens/tabs_view/tabs_view.dart**
   - ✅ Already exists
   - **Action**: Update bottom nav styling, curved top edge
   - **Complexity**: MEDIUM
   - **Time**: 1.5 hours

7. **DailyGoalsScreen.tsx → lib/screens/goals/daily_goals_screen.dart**
   - ✅ Already exists
   - **Action**: Update card design, progress bars, streak card
   - **Complexity**: MEDIUM
   - **Time**: 2 hours

8. **AchievementsScreen.tsx → lib/screens/achievements/achievements_screen.dart**
   - ✅ Already exists
   - **Action**: Update badge grid, rarity colors, header design
   - **Complexity**: MEDIUM
   - **Time**: 2 hours

9. **AIChatScreen.tsx → lib/screens/ai_chat/ai_chat_screen.dart**
   - ✅ Already exists
   - **Action**: Update message bubbles, input field, mode selector
   - **Complexity**: MEDIUM
   - **Time**: 2.5 hours

---

### Phase 3: Complex Screens (Structural Changes)
**Target**: Screens with different layouts or new features

10. **OnboardingScreen.tsx → lib/screens/onboarding/kijiji_onboarding_screen.dart**
    - ✅ Already exists (10-step version)
    - **Action**: Update each step's visual design
    - **Complexity**: HIGH
    - **Time**: 3 hours
    - **Changes**: Update gradients, icons, chip designs, progress indicators

11. **ModernOnboardingScreen.tsx → lib/screens/onboarding/modern_onboarding_screen.dart**
    - ✅ Already exists
    - **Action**: Update image layouts, dot indicators
    - **Complexity**: MEDIUM
    - **Time**: 1.5 hours

12. **LanguageDetailScreen.tsx → lib/screens/tabs_view/home/language_detail_screen.dart**
    - ✅ Already exists
    - **Action**: Update layout, button designs
    - **Complexity**: MEDIUM
    - **Time**: 2 hours

13. **LessonsListScreen.tsx → lib/lessons/screens/lessons_list_screen.dart**
    - ✅ Already exists
    - **Action**: Update lesson card design, section headers
    - **Complexity**: MEDIUM
    - **Time**: 2 hours

14. **LessonDetailScreen.tsx**
    - ⚠️ Needs to be located/verified
    - **Action**: Create or update lesson detail view
    - **Complexity**: HIGH
    - **Time**: 3 hours

15. **QuizSelectionMapScreen.tsx → lib/screens/tabs_view/home/take_quiz_screen.dart**
    - ✅ Already exists (map-based)
    - **Action**: Update map background, bubble designs
    - **Complexity**: LOW
    - **Time**: 1 hour

16. **TakeQuizScreen.tsx**
    - ⚠️ Part of quiz flow (detail_types/quiz_screen.dart)
    - **Action**: Update quiz UI, answer cards, progress
    - **Complexity**: MEDIUM
    - **Time**: 2 hours

---

## 📋 CONVERSION CHECKLIST BY SCREEN

### For Each Screen:
- [ ] Extract design tokens (colors, spacing, fonts)
- [ ] Map React components to Flutter widgets
- [ ] Convert CSS classes to BoxDecoration/TextStyle
- [ ] Replace web images with network/asset images
- [ ] Add state management (Riverpod)
- [ ] Implement navigation
- [ ] Add error handling
- [ ] Test in light/dark mode
- [ ] Verify responsiveness

---

## 🎨 DESIGN TOKENS EXTRACTED FROM FIGMA

### Colors (Confirmed):
```dart
// Primary Colors
static const primaryGreen = Color(0xFF007A3D);
static const primaryOrange = Color(0xFFFF6B35);
static const accentGold = Color(0xFFFCD116);
static const primaryPurple = Color(0xFF7B2CBF);
static const primaryRed = Color(0xFFCE1126);

// Gradients
static const africanSavanna = LinearGradient(
  colors: [Color(0xFF007A3D), Color(0xFF005a2d), Colors.black],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

static const africanSunset = LinearGradient(
  colors: [Color(0xFFFCD116), Color(0xFFFF6B35)],
);

static const purpleToRed = LinearGradient(
  colors: [Color(0xFF7B2CBF), Color(0xFFCE1126)],
);
```

### Typography:
```dart
// Using Dosis font family (already loaded)
fontFamily: 'dosis'
weights: 100, 300, 400, 500, 600, 700, 800

// Responsive sizes using ScreenUtil
fontSize: 14.sp, 16.sp, 18.sp, 20.sp, 24.sp, 28.sp, 36.sp
```

### Spacing:
```dart
// From Figma designs
spacing_xs: 4.sp
spacing_s: 8.sp
spacing_m: 12.sp
spacing_l: 16.sp
spacing_xl: 24.sp
spacing_xxl: 32.sp
```

### Border Radius:
```dart
radius_s: 8
radius_m: 12
radius_l: 16
radius_xl: 20
radius_round: 100 (fully rounded)
```

---

## 🔧 TECHNICAL CONVERSION NOTES

### React → Flutter Mapping:

| React/Web | Flutter Equivalent |
|-----------|-------------------|
| `<div>` | `Container` / `Column` / `Row` |
| `<button>` | `ElevatedButton` / `TextButton` / `IconButton` |
| `<input>` | `TextField` |
| `<img>` | `Image.network` / `Image.asset` / `CachedNetworkImage` |
| `className="..."` | `BoxDecoration` / `TextStyle` |
| `onClick` | `onPressed` / `onTap` |
| `useState` | `StatefulWidget` + `setState` / Riverpod state |
| `useEffect` | `initState()` / `didChangeDependencies()` |
| `map()` | `List.map()` / `ListView.builder` |
| Tailwind `flex` | `Flex` / `Row` / `Column` |
| Tailwind `grid` | `GridView` |
| CSS animations | `AnimatedContainer` / `flutter_animate` |

---

## 📦 ASSET MIGRATION

### Current Assets (Already in App):
✅ `assets/fonts/Dosis-*.ttf` - All weights
✅ `assets/images/` - Various images
✅ `assets/alphabets/` - Alphabet images

### New Assets from Figma (Need to Download):
⚠️ Language images (currently Unsplash URLs) - Need to:
1. Download or keep as network images
2. Add to `assets/images/languages/`
3. Update image paths in screens

### Recommended Approach:
- Keep as **CachedNetworkImage** for dynamic loading
- Add local fallback images
- Already using `cached_network_image` package ✅

---

## 🚀 IMPLEMENTATION STRATEGY

### Option A: Gradual Migration (RECOMMENDED)
**Approach**: Update existing Flutter screens one by one with Figma designs

**Pros**:
- No breaking changes
- App remains functional throughout
- Can test each screen individually
- Easier to review and revert if needed

**Cons**:
- Takes longer
- Manual work

**Steps**:
1. Start with authentication screens (Login, SignUp)
2. Update main dashboard (Home, Tabs)
3. Update learning screens (Lessons, Quiz)
4. Update social screens (Chat, Goals)
5. Test and refine

**Timeline**: 2-3 weeks (1-2 screens per day)

---

### Option B: Complete Redesign (Risky)
**Approach**: Create new screen files from Figma, swap all at once

**Pros**:
- Complete refresh
- Consistent design language
- Faster bulk work

**Cons**:
- High risk of breaking functionality
- Need to reconnect all backend logic
- Harder to test incrementally

**Timeline**: 1 week intensive work

---

## 💡 RECOMMENDED PLAN

### Week 1: Foundation & Auth Screens
- [ ] Update theme tokens to match Figma exactly
- [ ] Convert SplashScreen
- [ ] Convert LoginScreen
- [ ] Convert SignUpScreen
- [ ] Convert ForgotPasswordScreen
- [ ] Test authentication flow

### Week 2: Main Navigation & Home
- [ ] Convert MainTabsScreen (bottom navigation)
- [ ] Convert HomeScreen (language grid)
- [ ] Update drawer menu design
- [ ] Test navigation

### Week 3: Learning Screens
- [ ] Convert OnboardingScreen (10 steps)
- [ ] Convert LanguageDetailScreen
- [ ] Convert LessonsListScreen
- [ ] Convert QuizSelectionMapScreen
- [ ] Convert TakeQuizScreen
- [ ] Test learning flow

### Week 4: Advanced Features
- [ ] Convert AIChatScreen
- [ ] Convert DailyGoalsScreen
- [ ] Convert AchievementsScreen
- [ ] Final testing and refinements

---

## 🎯 PRIORITY SCREENS

### High Priority (User-Facing, High Traffic):
1. **SplashScreen** - First impression
2. **HomeScreen** - Main dashboard
3. **AIChatScreen** - Core feature
4. **TakeQuizScreen** - Core learning
5. **DailyGoalsScreen** - Engagement

### Medium Priority:
6. **LoginScreen** / **SignUpScreen** - One-time use
7. **LessonsListScreen** - Important but functional
8. **AchievementsScreen** - Motivational
9. **MainTabsScreen** - Navigation

### Lower Priority:
10. **OnboardingScreen** - One-time use
11. **LanguageDetailScreen** - Informational
12. **ForgotPasswordScreen** - Rarely used

---

## 🔨 CONVERSION TEMPLATE

### For Each Screen:

**1. Analyze Figma Component**:
```tsx
// Example from Figma
<div className="bg-gradient-to-b from-[#007A3D] to-black">
  <button className="bg-[#FCD116] text-white px-6 py-3 rounded-full">
    Begin Journey
  </button>
</div>
```

**2. Convert to Flutter**:
```dart
// Flutter equivalent
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF007A3D), Colors.black],
    ),
  ),
  child: ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFFCD116),
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
      ),
    ),
    child: Text('Begin Journey'),
  ),
)
```

---

## 📊 COMPLEXITY MATRIX

| Screen | Existing | Complexity | Time | Priority |
|--------|----------|------------|------|----------|
| SplashScreen | ✅ | LOW | 1h | HIGH |
| LoginScreen | ✅ | LOW | 1h | MEDIUM |
| SignUpScreen | ✅ | LOW | 1h | MEDIUM |
| ForgotPassword | ✅ | LOW | 0.5h | LOW |
| ModernOnboarding | ✅ | MEDIUM | 1.5h | LOW |
| OnboardingScreen | ✅ | HIGH | 3h | MEDIUM |
| MainTabsScreen | ✅ | MEDIUM | 1.5h | HIGH |
| HomeScreen | ✅ | MEDIUM | 2h | HIGH |
| LanguageDetail | ✅ | MEDIUM | 2h | MEDIUM |
| LessonsList | ✅ | MEDIUM | 2h | MEDIUM |
| LessonDetail | ⚠️ | HIGH | 3h | MEDIUM |
| QuizSelection | ✅ | LOW | 1h | MEDIUM |
| TakeQuiz | ✅ | MEDIUM | 2h | HIGH |
| AIChat | ✅ | MEDIUM | 2.5h | HIGH |
| DailyGoals | ✅ | MEDIUM | 2h | HIGH |
| Achievements | ✅ | MEDIUM | 2h | HIGH |

**Total Estimated Time**: 30-35 hours

---

## ✅ NEXT STEPS

### Immediate Actions:
1. ✅ Create branch `figma-screens/import-audit` - DONE
2. ✅ Create this audit report - DONE
3. ⏳ Review Figma screens with stakeholder
4. ⏳ Prioritize which screens to convert first
5. ⏳ Begin conversion starting with highest priority

### Decision Needed:
**Do you want to**:
- **A)** Convert all 18 screens to match Figma designs?
- **B)** Only update high-priority screens (5-6 screens)?
- **C)** Create a hybrid (keep some current, update others)?

### My Recommendation:
**Option B** - Update high-priority, user-facing screens:
1. SplashScreen
2. HomeScreen  
3. AIChatScreen
4. DailyGoalsScreen
5. AchievementsScreen
6. TakeQuizScreen

This gives maximum visual impact with minimal risk.

---

## 📝 NOTES

### Advantages of Figma Designs:
- ✅ Modern, beautiful UI
- ✅ Consistent design language
- ✅ African cultural elements
- ✅ Professional appearance

### Challenges:
- ⚠️ React → Flutter conversion takes time
- ⚠️ Need to preserve existing functionality
- ⚠️ Backend integration must be maintained
- ⚠️ Testing required for each screen

### Risk Mitigation:
- Convert one screen at a time
- Test thoroughly before moving to next
- Keep old code as backup
- Use feature flags if possible

---

**Report Created**: December 3, 2024  
**Status**: ✅ AUDIT COMPLETE  
**Recommendation**: Proceed with Phase 1 (Simple screens first)


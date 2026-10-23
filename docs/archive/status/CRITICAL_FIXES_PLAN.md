# Critical Fixes Plan - Release Stability

## Root Causes Identified

### 1. Navigation Issues
- New Figma-themed screens expect `onBack` callback parameter
- Drawer navigation doesn't pass `onBack` parameter
- This causes screens to not have back navigation

### 2. Language Loading Issues
- `languagesProvider` is `autoDispose` - disposes when tab changes
- No error handling for network failures
- No caching mechanism for offline access

### 3. Blank Screens
- Theme conflict: Old screens vs new Figma Make screens
- Screens don't handle null/empty state properly
- Error boundaries present but not catching all errors

### 4. AI Chat Issues
- Works from Daily Goals but not from drawer
- Different navigation paths
- Mode (translation/tutor) state persists across both modes

### 5. Quiz Loading Issues
- JWT token not being refreshed properly
- API provider not setting token correctly after login

## Fixes to Implement

### Priority 1: Navigation & Back Buttons (ALL SCREENS)
1. Update all screen constructors to handle `onBack` parameter properly
2. Provide default `Navigator.pop(context)` if `onBack` is null
3. Ensure ALL screens have visible back button

### Priority 2: Language Loading Stability
1. Remove `autoDispose` from `languagesProvider`
2. Add caching layer with SharedPreferences
3. Add retry logic with exponential backoff
4. Show cached data while refreshing

### Priority 3: Fix Blank Screens
1. Add loading states to ALL screens
2. Add error states with retry buttons
3. Ensure text colors work in light/dark mode
4. Test each screen individually

### Priority 4: AI Chat Enhancements
1. Separate chat history for translation vs tutor mode
2. Add mute button for TTS
3. Replace TTS voice with African accent voices
4. Add language selection UI
5. Make modes truly different (translation = instant, tutor = progressive)

### Priority 5: Quiz & JWT Token
1. Ensure token refresh on pre-filled login
2. Add token validation before quiz API calls
3. Add loading indicator with timeout
4. Add error message if token invalid

### Priority 6: Daily Goals Linking
1. Link "Complete lessons" to LessonsListScreen
2. Link "Take quizzes" to TakeQuizScreen with language selection
3. Show language selector before navigation

### Priority 7: Curriculum Loading
1. Fix asset path loading
2. Add better error messages
3. Test expanded bundle path
4. Add fallback content

### Priority 8: Private Chats
1. Test socket connection
2. Add connection status indicator
3. Add error handling for failed connections
4. Add retry mechanism

## Implementation Order
1. Fix navigation & back buttons (30 min)
2. Fix language loading with caching (20 min)
3. Fix blank screens - Profile, Progress, Settings, etc (40 min)
4. Fix AI chat navigation & mode separation (30 min)
5. Add TTS mute button (10 min)
6. Fix quiz loading & JWT tokens (20 min)
7. Link daily goals to modules (15 min)
8. Fix curriculum loading (15 min)
9. Test private chats (20 min)
10. Replace TTS voices (30 min)
11. Final testing & stability check (30 min)

## Total Est: 4-5 hours of focused work


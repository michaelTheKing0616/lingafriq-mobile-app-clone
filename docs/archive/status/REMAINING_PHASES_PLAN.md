# Remaining Phases Implementation Plan

## Phase 2: Global Navigation & UI Consistency ✅ (Mostly Complete)
**Status**: Screens already have back buttons and navigation. Standard AppBar widget created for future use.

**Completed**:
- ✅ Created `StandardAppBar` widget for consistent navigation
- ✅ Screens already have proper back buttons
- ✅ App drawer navigation is consistent

**Remaining**:
- Audit all screens for Material 3 compliance
- Ensure consistent spacing and typography

## Phase 4: Auth, JWT & False Offline State
**Status**: In Progress

**Issues to Fix**:
1. **False Offline Detection**: "No Internet connection" appearing when online
   - Check `connection_status_indicator.dart`
   - Audit network connectivity checks in `api_provider.dart`
   - Fix connectivity detection logic

2. **JWT Token Refresh**:
   - Audit `auth_provider.dart` for token refresh logic
   - Ensure automatic token refresh on 401 errors
   - Add silent re-authentication

3. **Error Handling**:
   - Clear error messages for auth failures
   - Proper handling of expired tokens
   - Retry logic for network errors

**Files to Check**:
- `lib/providers/auth_provider.dart`
- `lib/widgets/connection_status_indicator.dart`
- `lib/providers/api_provider.dart`
- `lib/providers/dio_provider.dart`

## Phase 5: Quiz Module Infinite Loading Fix
**Status**: Pending

**Issues to Fix**:
1. **Infinite Loading**:
   - Check `lib/detail_types/quiz_screen.dart`
   - Verify API calls and timeouts
   - Add retry logic

2. **Old Loading Screen**:
   - Replace with new dynamic loading screen
   - Ensure proper error states

**Files to Check**:
- `lib/detail_types/quiz_screen.dart`
- `lib/providers/api_provider.dart` (quiz-related methods)

## Phase 8: Games Module
**Status**: Pending

**Tasks**:
1. Register all 35+ cultural games
2. Ensure each game is playable
3. Wire to backend
4. Remove hardcoded limitations

**Files to Check**:
- `lib/screens/games/games_screen.dart`
- `lib/providers/game_provider.dart`
- Backend game routes

## Phase 9: Gamification & Story Modes
**Status**: Pending

**Tasks**:
1. Remove dummy XP usage
2. Ensure story modes generate real AI content via Polie
3. XP only awarded after content consumption
4. Backend persistence for stories

**Files to Check**:
- `lib/providers/gamification_provider.dart`
- Story mode screens
- XP integration with Polie

## Phase 10: Chat System Revamp
**Status**: Pending

**Tasks**:
1. Implement global chat using `chat_bundle`
2. Implement private chat using `chat_mode_revamp`
3. Real-time feel with WebSocket
4. Modern UX
5. Backend wiring
6. Message persistence
7. Error handling

**Files to Check**:
- `lib/screens/chat/global_chat_screen.dart`
- `lib/screens/chat/private_chat_list_screen.dart`
- `lib/providers/chat_socket_provider.dart`
- `lib/providers/private_chat_provider.dart`

## Phase 11: Duplicate Consolidation & Final Hardening
**Status**: Pending

**Tasks**:
1. Identify duplicate implementations (Profile, Leaderboards, etc.)
2. Consolidate to most complete version
3. Add defensive null handling
4. Add retry logic
5. Meaningful error messages
6. Logging

**Files to Check**:
- All provider files
- All screen files
- Look for duplicate models/services

## Implementation Priority

1. **Phase 4** (Auth/JWT/Offline) - Critical for app functionality
2. **Phase 5** (Quiz Loading) - High user impact
3. **Phase 9** (Gamification) - Core feature
4. **Phase 10** (Chat) - Social feature
5. **Phase 8** (Games) - Content feature
6. **Phase 11** (Hardening) - Quality improvement


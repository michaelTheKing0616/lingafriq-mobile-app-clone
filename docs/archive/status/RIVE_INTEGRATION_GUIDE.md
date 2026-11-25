# Rive Integration Guide

## Quick Start

### 1. Add Rive Guide to Any Screen

**Option A: Use ScaffoldWithRive (Easiest)**
```dart
import 'package:lingafriq/widgets/scaffold_with_rive.dart';

ScaffoldWithRive(
  appBar: AppBar(title: Text('My Screen')),
  body: YourContent(),
  showRiveGuide: true, // Optional, defaults to true
)
```

**Option B: Add to Stack**
```dart
import 'package:lingafriq/widgets/rive_global_guide.dart';

Stack(
  children: [
    YourContent(),
    Positioned(
      top: 16,
      right: 16,
      child: RiveGlobalGuide(
        width: 100.w,
        height: 100.h,
      ),
    ),
  ],
)
```

### 2. Trigger Reactions

**Automatic (Already Integrated):**
- ✅ XP gains
- ✅ Level ups
- ✅ Badge unlocks
- ✅ Streak milestones
- ✅ Lesson/quiz/game completions
- ✅ Mistakes

**Manual (If Needed):**
```dart
final riveService = ref.read(riveGamificationServiceProvider);

// React to custom events
riveService.reactToXPGain(50);
riveService.reactToPerfectScore();
riveService.reactToMistake();
riveService.reactToLessonComplete();
```

### 3. Create Rive Asset

1. Open Rive editor (rive.app)
2. Design character with state machine
3. Name state machine: `GuideStateMachine`
4. Add inputs: `isListening`, `isSpeaking`, `confidence`, `emotion`
5. Export as `game_guide.riv`
6. Place in `assets/rive/`
7. Run `flutter pub get`

See `RIVE_ASSET_SPECIFICATIONS.md` for detailed requirements.

## Integration Points

### Already Integrated
- ✅ All game screens (BaseGameScreen)
- ✅ Gamification provider
- ✅ Gamification integration helper
- ✅ Backend state persistence

### Can Be Added
- Home screen
- Profile screen
- Leaderboard
- Any custom screen

## Backend

State is automatically saved/loaded via:
- `POST /v1/polie/rive-state` - Save
- `GET /v1/polie/rive-state` - Load

No manual API calls needed - handled by `RiveGamificationService`.

## Testing

1. **Without Rive File**: Should show fallback icon ✅
2. **With Rive File**: Should show animated character ✅
3. **State Persistence**: Character state should persist across app restarts ✅
4. **Reactions**: Character should react to gamification events ✅

## Troubleshooting

**Rive not showing?**
- Check `assets/rive/` directory exists
- Verify `pubspec.yaml` includes `assets/rive/`
- Check console for loading errors

**Reactions not working?**
- Verify `RiveGamificationService` is initialized
- Check gamification events are firing
- Verify controller is set

**State not persisting?**
- Check backend endpoint is accessible
- Verify user is logged in
- Check network connectivity


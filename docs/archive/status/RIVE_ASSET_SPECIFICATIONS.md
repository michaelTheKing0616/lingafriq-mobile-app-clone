# Rive Asset Specifications

## Overview

The Rive guide character is the **soul of the app**. It provides emotional feedback and makes the learning experience feel alive.

## File Location

```
assets/rive/game_guide.riv
```

## State Machine Name

```
GuideStateMachine
```

## Required State Machine Inputs

| Input Name    | Type   | Range/Values                    | Description                          |
|---------------|--------|---------------------------------|--------------------------------------|
| `isListening` | Bool   | true/false                      | Character is listening to user input |
| `isSpeaking`  | Bool   | true/false                      | Character is speaking/teaching       |
| `confidence`  | Number | 0.0 to 1.0                      | User's confidence/accuracy level     |
| `emotion`     | Number | 0-4 (see enum below)            | Current emotional state              |

## Emotion Enum Mapping

| Value | Emotion      | Visual Description                    | When to Use                          |
|-------|--------------|---------------------------------------|--------------------------------------|
| 0     | `idle`       | Neutral, relaxed pose                 | Default state, waiting for input     |
| 1     | `thinking`   | Hand on chin, contemplative           | Processing, analyzing                |
| 2     | `encouraging`| Warm smile, open arms                 | Good effort, keep going              |
| 3     | `proud`      | Big smile, thumbs up, celebration     | Perfect score, excellent work         |
| 4     | `disappointed`| Gentle frown, supportive gesture    | Mistake made, but encouraging        |

## Required States

The state machine should have these states:

1. **Idle** - Default resting state
2. **Listening** - Active listening pose (when `isListening` is true)
3. **Speaking** - Teaching/explaining pose (when `isSpeaking` is true)
4. **Thinking** - Processing/analyzing pose
5. **Encouraging** - Supportive, warm expression
6. **Proud** - Celebration animation
7. **Disappointed** - Gentle, supportive expression

## Animation Requirements

### Transitions
- All transitions should be smooth (e.g., 300-500ms)
- Use easing curves (ease-in-out)
- No jarring cuts

### Character Design
- **Style**: Friendly, approachable, culturally neutral but warm
- **Features**: 
  - Expressive eyes
  - Animated mouth (for speaking state)
  - Hand gestures (for encouragement/celebration)
  - Subtle body movement (breathing, idle animation)

### Performance
- Optimize for mobile (60fps)
- Use efficient bone/IK rigging
- Keep file size under 500KB if possible

## Integration Code

The Flutter code expects this structure:

```dart
// In RiveGameGuideController
void initialize(Artboard artboard) {
  final stateMachine = artboard.stateMachines.firstWhere(
    (sm) => sm.name == 'GuideStateMachine',
  );
  
  // Find inputs
  _isListening = stateMachine.inputs.firstWhere(
    (input) => input.name == 'isListening',
  ) as SMIBool;
  
  _confidence = stateMachine.inputs.firstWhere(
    (input) => input.name == 'confidence',
  ) as SMINumber;
  
  // ... etc
}
```

## Testing Checklist

- [ ] State machine named "GuideStateMachine"
- [ ] All 4 inputs present and named correctly
- [ ] Emotion transitions smoothly between all states
- [ ] Listening state activates when `isListening = true`
- [ ] Speaking state activates when `isSpeaking = true`
- [ ] Confidence value (0-1) affects character expression
- [ ] Proud state plays celebration animation
- [ ] Disappointed state shows supportive expression
- [ ] File size is reasonable (< 500KB)
- [ ] Animation runs at 60fps on mobile devices

## Design Guidelines

1. **Cultural Sensitivity**: Character should be welcoming to all African cultures
2. **Accessibility**: Clear, readable expressions
3. **Performance**: Optimized for mobile devices
4. **Consistency**: Same character across all games

## Example Rive File Structure

```
game_guide.riv
├── Artboard: "GuideCharacter"
│   ├── State Machine: "GuideStateMachine"
│   │   ├── Input: "isListening" (Bool)
│   │   ├── Input: "isSpeaking" (Bool)
│   │   ├── Input: "confidence" (Number 0-1)
│   │   ├── Input: "emotion" (Number 0-4)
│   │   ├── State: "Idle"
│   │   ├── State: "Listening"
│   │   ├── State: "Speaking"
│   │   ├── State: "Thinking"
│   │   ├── State: "Encouraging"
│   │   ├── State: "Proud"
│   │   └── State: "Disappointed"
│   └── Layers: [Character Art, Animations, etc.]
```

## Resources

- [Rive Documentation](https://rive.app/community/using-rive/docs)
- [Rive Flutter Integration](https://pub.dev/packages/rive)
- [State Machine Best Practices](https://rive.app/community/using-rive/docs/state-machines)

## Next Steps

1. Design character in Rive editor
2. Create state machine with required inputs
3. Add animations for each state
4. Test in Flutter app
5. Optimize file size and performance


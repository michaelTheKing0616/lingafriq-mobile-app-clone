# Rive Assets Directory

## Overview

This directory contains Rive animation files for the guide character.

## Required File

**`game_guide.riv`** - The main guide character animation file

## Specifications

See `RIVE_ASSET_SPECIFICATIONS.md` in the project root for complete requirements.

### Quick Requirements

- State Machine Name: `GuideStateMachine`
- Required Inputs:
  - `isListening` (bool)
  - `isSpeaking` (bool)
  - `confidence` (number 0-1)
  - `emotion` (number 0-5)
- Required States:
  - idle
  - thinking
  - listening
  - speaking
  - encouraging
  - proud
  - disappointed
  - happy

## File Size

Target: < 500KB for optimal mobile performance

## Testing

After adding the Rive file:
1. Run `flutter pub get`
2. Restart the app
3. Complete a lesson/quiz/game
4. Verify character animates correctly

## Fallback

If the Rive file is not present, the app will show a fallback icon. This allows the app to work while the Rive asset is being created.

## Resources

- [Rive Editor](https://rive.app)
- [Rive Flutter Package](https://pub.dev/packages/rive)
- [Rive Documentation](https://rive.app/community/using-rive/docs)


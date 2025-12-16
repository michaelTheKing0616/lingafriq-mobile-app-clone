# Git Commands for Pushing Updates

## Mobile App Repository

### Navigate to mobile app directory
```bash
cd C:\Users\HP\Desktop\LingAfriqMobile\mobile-app-main
```

### Check current status
```bash
git status
```

### Add all changes
```bash
git add .
```

### Commit changes
```bash
git commit -m "feat: Complete gamification frontend widgets, add UI revamp plan, update to v1.6.0+113

- Add XP progress widget with Material 3 design
- Add badge gallery widget with unlock animations
- Add streak indicator widget with fire animations
- Create comprehensive UI revamp plan
- Update version to 1.6.0+113
- Add defensive programming improvements
- Complete all 11 phases of app improvements"
```

### Push to repository
```bash
git push origin main
```

### If pushing to a different branch
```bash
git push origin <branch-name>
```

## Backend Repository

### Navigate to backend directory
```bash
cd C:\Users\HP\Downloads\node-backend-main\node-backend-main
```

### Check current status
```bash
git status
```

### Add all changes
```bash
git add .
```

### Commit changes
```bash
git commit -m "feat: Add AI chat history persistence, XP service, update to v1.6.0

- Add AI chat history model, controller, and routes
- Implement server-authoritative XP service
- Add anti-cheat mechanisms for XP
- Update version to 1.6.0
- Improve error handling and validation"
```

### Push to repository
```bash
git push origin main
```

### If pushing to a different branch
```bash
git push origin <branch-name>
```

## Summary of Changes

### Mobile App (v1.6.0+113)
- ✅ Gamification frontend widgets (XP, badges, streaks)
- ✅ UI revamp plan document
- ✅ Defensive programming improvements
- ✅ Safe API call utility
- ✅ All 11 phases completed

### Backend (v1.6.0)
- ✅ AI chat history persistence
- ✅ Server-authoritative XP service
- ✅ Anti-cheat mechanisms
- ✅ Improved error handling

## Notes
- Make sure you're on the correct branch before pushing
- Review changes with `git diff` before committing
- Consider creating a pull request if working with a team
- Tag the release if this is a production release: `git tag v1.6.0 && git push origin v1.6.0`


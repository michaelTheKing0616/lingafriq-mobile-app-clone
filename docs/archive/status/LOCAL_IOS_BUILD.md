# Building iOS App Locally

## Prerequisites
⚠️ **iOS builds require macOS with Xcode installed.** You cannot build iOS apps on Windows or Linux.

## Option 1: Build on macOS (Recommended)

If you have access to a Mac:

1. **Install Xcode:**
   ```bash
   # Install from App Store or download from developer.apple.com
   ```

2. **Install CocoaPods:**
   ```bash
   sudo gem install cocoapods
   ```

3. **Navigate to project:**
   ```bash
   cd mobile-app-main
   ```

4. **Get dependencies:**
   ```bash
   flutter pub get
   cd ios
   pod install
   cd ..
   ```

5. **Build for release (unsigned archive):**
   ```bash
   flutter build ios --release --no-codesign
   ```
   This creates an archive at: `build/ios/archive/Runner.xcarchive`

6. **Build signed IPA (requires Apple Developer account):**
   ```bash
   flutter build ipa --release
   ```
   This creates an IPA at: `build/ios/ipa/*.ipa`

## Option 2: Use GitHub Actions (Current Setup)

Since you're on Windows, the easiest way is to use GitHub Actions:

1. **Check workflow status:**
   - Go to: https://github.com/lingafriq/mobile-app/actions
   - Find the latest workflow run
   - Check if `build-ios` job succeeded

2. **Download artifact:**
   - Click on the workflow run
   - Scroll to "Artifacts" section
   - Download `ios-build-<version>`

3. **If build failed:**
   - Check the logs for errors
   - Common issues:
     - Missing code signing (builds unsigned archive)
     - CocoaPods errors
     - Xcode version compatibility

## Option 3: Use Cloud Mac Services

If you don't have a Mac, consider:
- **MacStadium** (paid cloud Mac service)
- **MacinCloud** (rental Mac service)
- **GitHub Actions** (free for public repos, limited for private)

## Current Version

Your current version is: **1.5.7+89**

To build with a specific version:
```bash
# Update pubspec.yaml first
version: 1.5.7+90

# Then build
flutter build ipa --release
```

## Troubleshooting

### "No signing certificate found"
- Build unsigned: `flutter build ios --release --no-codesign`
- Or set up code signing in Xcode

### "Pod install failed"
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### "Xcode version incompatible"
- Update Xcode to latest version
- Or update Flutter: `flutter upgrade`


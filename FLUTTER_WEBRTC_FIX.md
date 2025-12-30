# Flutter WebRTC Build Fix

## Problem
The `flutter_webrtc` plugin uses deprecated Flutter embedding APIs, causing compilation errors:
```
error: cannot find symbol
import io.flutter.plugin.common.PluginRegistry.Registrar;
```

## Solution
We use `livekit_client` (which uses `dart_webrtc`) instead of `flutter_webrtc`. However, `flutter_webrtc` may still be pulled in as a transitive dependency. We've implemented multiple layers of protection:

### 1. Gradle-Level Exclusions
- **`android/app/build.gradle`**: Disables tasks and excludes configurations for `flutter_webrtc`
- **`android/settings.gradle`**: Prevents the plugin project from being fully initialized
- **`android/exclude_webrtc.gradle`**: Comprehensive exclusion script for all compilation tasks

### 2. Plugin Registry Removal
- **`scripts/remove_webrtc_plugin.ps1`**: PowerShell script to remove `flutter_webrtc` from `.flutter-plugins`
- **`scripts/remove_webrtc_plugin.sh`**: Bash script for Linux/CI environments

### 3. ProGuard Rules
- **`android/app/proguard-rules.pro`**: Rules to handle any remaining references

## Usage

### For Local Development
After running `flutter pub get`, run:
```powershell
# Windows
.\scripts\remove_webrtc_plugin.ps1
```

```bash
# Linux/Mac/CI
chmod +x scripts/remove_webrtc_plugin.sh
./scripts/remove_webrtc_plugin.sh
```

### For CI/CD
Add to your build pipeline after `flutter pub get`:
```yaml
- name: Remove flutter_webrtc plugin
  run: ./scripts/remove_webrtc_plugin.sh
```

## Verification
The build should complete without the `Registrar` compilation errors. The app uses `livekit_client` for WebRTC functionality, which doesn't have these issues.


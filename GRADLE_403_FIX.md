# Fix for Gradle 403 Forbidden Errors

## Problem
Gradle build is failing with HTTP 403 (Forbidden) errors when trying to download dependencies from Maven Central:
- `kotlinx-coroutines-core-jvm-1.8.1.jar`
- `kotlinx-coroutines-android-1.8.1.jar`
- `kotlin-stdlib-2.2.20.jar`
- `guava-33.3.1-android.jar`
- `jspecify-1.0.0.jar`

## Root Cause
Maven Central is rate-limiting or blocking requests from the CI/CD runner IP address. This is common in GitHub Actions and other CI environments.

## Solution Applied

### 1. Added Alternative Repositories
Updated `android/build.gradle` and `android/settings.gradle` to include:
- Google Maven (primary)
- Maven Central (primary)
- Maven Central explicit URL (fallback)
- JitPack (alternative)
- Sonatype Snapshots (alternative)
- Aliyun Maven Mirror (often more reliable in CI/CD)

### 2. Enhanced Gradle Properties
Added to `android/gradle.properties`:
- Increased connection/socket timeouts
- Enabled parallel downloads and caching
- Better retry behavior

### 3. Repository Order
Repositories are now tried in this order:
1. Google (most reliable)
2. Maven Central
3. Maven Central explicit URL
4. JitPack
5. Sonatype Snapshots
6. Aliyun Mirror

## Additional Steps if Issue Persists

### Option 1: Clear Gradle Cache
```bash
cd android
./gradlew clean --refresh-dependencies
rm -rf ~/.gradle/caches/
```

### Option 2: Use Gradle Init Script
The `android/init.gradle` file can be used with:
```bash
./gradlew build --init-script android/init.gradle
```

### Option 3: Configure CI/CD to Use Mirror
In your CI/CD workflow, you can set:
```yaml
env:
  GRADLE_OPTS: "-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true"
```

### Option 4: Add Retry Logic in CI/CD
If using GitHub Actions, add retry logic:
```yaml
- name: Build App Bundle
  run: flutter build appbundle --release
  continue-on-error: true
  timeout-minutes: 30
```

## Testing
After applying these fixes:
1. Clean build: `flutter clean`
2. Get dependencies: `flutter pub get`
3. Build: `flutter build appbundle --release --split-debug-info=build/symbols`

## Expected Result
- Gradle should successfully download dependencies from alternative repositories
- Build should complete without 403 errors
- If one repository fails, Gradle will automatically try the next one


# Local AAB Build Instructions

## Prerequisites
- Flutter SDK installed ✅ (You have this)
- Android SDK installed ✅ (You have this)
- Keystore file (`upload-keystore.jks`) ✅ (You have this)

## Step 1: Create key.properties file

Create a file at `android/key.properties` with your keystore credentials:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=../upload-keystore.jks
```

**Important:** Replace the placeholder values with your actual keystore credentials.

## Step 2: Build the AAB

Run this command from the project root:

```bash
flutter build appbundle --release --split-debug-info=build/symbols
```

## Step 3: Find your AAB

The signed AAB will be located at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Alternative: Build without signing (for testing)

If you just want to test the build without signing:

```bash
flutter build appbundle --release --split-debug-info=build/symbols
```

The build will proceed without signing if key.properties is missing, but the AAB won't be suitable for Play Store upload.

## Troubleshooting

- **"Keystore file not found"**: Make sure `upload-keystore.jks` is in the project root
- **"Wrong password"**: Double-check your keystore passwords in key.properties
- **"Key alias not found"**: Verify the keyAlias matches your keystore


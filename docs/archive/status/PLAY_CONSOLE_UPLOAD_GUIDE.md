# Google Play Console Upload Guide

## Uploading AAB with Mapping File

When uploading to Play Console, you need to upload **both** the AAB and the mapping.txt file:

### Step 1: Upload AAB
1. Go to: **Play Console** → **Your App** → **Release** → **Production** (or your track)
2. Click **Create new release**
3. Upload the `.aab` file

### Step 2: Upload Mapping File (Deobfuscation File)
1. In the same release page, scroll down to **Deobfuscation file**
2. Click **Upload** and select `mapping.txt`
3. This file is generated automatically when `minifyEnabled = true` in `build.gradle`

### Important Notes:

- **Version Code**: Must be higher than the last production version (currently 91+)
- **Mapping File**: Required for crash analysis when using R8/ProGuard obfuscation
- **Signing**: Ensure you're using the same signing key as previous releases

## Fixing "Can't rollout" Error

This error occurs when:
1. **Version code is too low** - Must be higher than production (91+)
2. **Signing key mismatch** - Must use the same keystore as previous releases
3. **Package name changed** - Must match existing app

### Solution:
- ✅ Ensure version code is 91 or higher
- ✅ Use the same keystore file (`upload-keystore.jks`)
- ✅ Verify package name matches: `com.owlab.lingafriq`

## Current Configuration

- **Package Name**: `com.owlab.lingafriq`
- **Minification**: Enabled (`minifyEnabled = true`)
- **Mapping File**: Generated at `build/app/outputs/mapping/release/mapping.txt`
- **Version**: Starts from 91 (last prod was 90)

## Workflow Artifacts

After the GitHub Actions workflow completes:
1. Download the artifact: `android-aab-<version>`
2. Extract both files:
   - `LingAfriq-<version>.aab` → Upload as App Bundle
   - `mapping.txt` → Upload as Deobfuscation file

## Troubleshooting

### "No mapping.txt found"
- Check that `minifyEnabled = true` in `android/app/build.gradle`
- Check workflow logs for mapping file location
- File should be at: `build/app/outputs/mapping/release/mapping.txt`

### "Version code conflict"
- Ensure version in `pubspec.yaml` is 1.5.7+91 or higher
- Workflow automatically ensures minimum version 91

### "Signing key mismatch"
- Verify you're using the same keystore as previous releases
- Check GitHub secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`


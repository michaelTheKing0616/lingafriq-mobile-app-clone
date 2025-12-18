# Fixing "Can't Rollout" Upgrade Error

## ✅ What We Fixed

1. **Version Code**: Ensured build number starts from 91+ (last prod was 90)
2. **Mapping File**: Enabled minification and included mapping.txt
3. **Signing**: Using same keystore via GitHub secrets

## ⚠️ CRITICAL: Package Name Check

**✅ FIXED**: Updated package name to `com.owlab.lingafriq` to match production.

All Android files have been updated:
- `build.gradle` - namespace and applicationId
- All `AndroidManifest.xml` files
- `MainActivity.kt` - package declaration and file location
- `proguard-rules.pro` - keep rules

## How to Verify Production Package Name

1. Go to Play Console → Your App → Setup → App identity
2. Check the **Package name** field
3. Ensure your `build.gradle` matches exactly

## Other Causes of Upgrade Errors

### 1. Signing Key Mismatch
- ✅ Fixed: Using same keystore via GitHub secrets
- Verify: Check Play Console → Setup → App signing → App signing key certificate

### 2. Version Code Too Low
- ✅ Fixed: Workflow ensures version ≥ 91
- Verify: Check Play Console → Release → Production → Version code

### 3. Package Name Mismatch
- ⚠️ **CHECK THIS**: Ensure `applicationId` matches production exactly

### 4. Play App Signing Configuration
- If using Play App Signing, ensure upload key matches
- Check: Play Console → Setup → App signing

## Next Steps

1. **Verify package name** in Play Console
2. **Update build.gradle** if needed to match production
3. **Rebuild** with correct package name
4. **Upload** new AAB with version code 91+

## Testing the Fix

After fixing package name (if needed):
1. Build will have version code 91+
2. Package name matches production
3. Same signing key
4. Should allow upgrades ✅


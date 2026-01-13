# iOS Build Setup Guide

## Current Status
The workflow is configured to build iOS, but **code signing is optional**. 

## Option 1: Build Without Signing (Current Default)
- ✅ Works immediately - no setup required
- ✅ Creates an unsigned archive
- ⚠️ Requires manual signing in Xcode before App Store submission
- ⚠️ Cannot be installed on devices directly

**Use this if:** You want to build and sign manually in Xcode later.

## Option 2: Automatic Code Signing (Recommended for CI/CD)

To enable automatic signing, add these secrets to your GitHub repository:

### Required GitHub Secrets:

1. **IOS_BUILD_CERTIFICATE_BASE64**
   - Export your iOS Distribution Certificate (.p12 file)
   - Base64 encode it: `base64 -i certificate.p12 | pbcopy`
   - Add to GitHub Secrets

2. **IOS_P12_PASSWORD**
   - Password for your .p12 certificate file
   - Add to GitHub Secrets

3. **IOS_KEYCHAIN_PASSWORD**
   - Temporary keychain password (can be any secure string)
   - Add to GitHub Secrets

4. **IOS_PROVISIONING_PROFILE_BASE64**
   - Download your App Store Distribution Provisioning Profile
   - Base64 encode it: `base64 -i profile.mobileprovision | pbcopy`
   - Add to GitHub Secrets

### Steps to Get Certificates:

1. **Export Certificate:**
   - Open Keychain Access on Mac
   - Find "Apple Distribution: [Your Name]" certificate
   - Right-click → Export → Save as .p12
   - Set a password

2. **Get Provisioning Profile:**
   - Go to [Apple Developer Portal](https://developer.apple.com/account/resources/profiles/list)
   - Download your App Store Distribution profile
   - Save as .mobileprovision

3. **Base64 Encode:**
   ```bash
   # On Mac/Linux:
   base64 -i certificate.p12 | pbcopy
   base64 -i profile.mobileprovision | pbcopy
   
   # On Windows (PowerShell):
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.p12"))
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("profile.mobileprovision"))
   ```

4. **Add to GitHub:**
   - Go to: `https://github.com/lingafriq/mobile-app/settings/secrets/actions`
   - Click "New repository secret"
   - Add each secret with the names above

## Option 3: Use Fastlane Match (Advanced)

For better certificate management, consider using Fastlane Match:
- Automatically manages certificates and profiles
- Better for teams
- Requires additional setup

## Current Workflow Behavior

- **With Secrets:** Builds signed IPA ready for App Store
- **Without Secrets:** Builds unsigned archive (manual signing required)

## Troubleshooting

### "No Accounts" Error
- Add Apple Developer account credentials (Option 2 above)
- Or use manual signing workflow

### "No profiles found"
- Ensure provisioning profile matches bundle ID: `com.owlab.lingafriq`
- Download correct profile from Apple Developer Portal

### Build succeeds but IPA missing
- Check artifact uploads in workflow logs
- Unsigned builds create .zip instead of .ipa

## Next Steps

1. **For immediate builds:** Use Option 1 (current setup)
2. **For automated releases:** Set up Option 2 (add secrets)
3. **For production:** Consider Option 3 (Fastlane Match)


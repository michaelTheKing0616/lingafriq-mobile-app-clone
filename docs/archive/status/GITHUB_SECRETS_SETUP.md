# GitHub Secrets Setup Instructions

## ⚠️ IMPORTANT: Security Best Practice

**DO NOT commit the keystore file to the repository.** Instead, use GitHub Secrets to store it securely.

## Step 1: Get the Base64 Encoded Keystore

The keystore has been encoded to `keystore_base64.txt`. Copy the entire contents of this file.

## Step 2: Add GitHub Secrets

Go to your repository: https://github.com/michaelTheKing0616/lingafriq-mobile-app-clone

1. Navigate to: **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"** and add these 4 secrets:

### Secret 1: KEYSTORE_BASE64
- **Name**: `KEYSTORE_BASE64`
- **Value**: Paste the entire contents of `keystore_base64.txt` (the base64 encoded keystore)

### Secret 2: KEYSTORE_PASSWORD
- **Name**: `KEYSTORE_PASSWORD`
- **Value**: `MyStorePass123!`

### Secret 3: KEY_PASSWORD
- **Name**: `KEY_PASSWORD`
- **Value**: `MyStorePass123!`

### Secret 4: KEY_ALIAS
- **Name**: `KEY_ALIAS`
- **Value**: `upload`

## Step 3: Verify Workflow

Once secrets are added, the GitHub Actions workflow will:
1. Decode the keystore from `KEYSTORE_BASE64`
2. Create `android/key.properties` with your credentials
3. Build a signed AAB automatically

## Security Notes

- ✅ Keystore is stored securely in GitHub Secrets (encrypted)
- ✅ Keystore file is NOT in the repository
- ✅ Only authorized users with repository access can use the secrets
- ✅ Secrets are never exposed in logs or build outputs


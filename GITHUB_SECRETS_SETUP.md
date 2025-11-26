# Setting Up GitHub Secrets for API Keys

## Current Code Status

✅ **The code IS set up** to use GitHub secrets via `String.fromEnvironment('GROQ_API_KEY')`

The Groq provider reads the API key from compile-time environment variables, which can be passed via `--dart-define` during the Flutter build process.

## Step-by-Step Setup

### Step 1: Add GitHub Secret

1. Go to your GitHub repository: `https://github.com/lingafriq/mobile-app` (or your clone repo)
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add:
   - **Name**: `GROQ_API_KEY`
   - **Value**: Your Groq API key (get it from https://console.groq.com/)
   - Click **Add secret**

### Step 2: GitHub Actions Workflow (Already Updated!)

The workflow has been updated to automatically use the secret. It will:
- Pass `GROQ_API_KEY` to the Flutter build via `--dart-define`
- Build will work even if the secret is not set (with a warning)

### Step 3: Verify It Works

1. Push a commit to trigger the workflow
2. Check the build logs - you should see the API key being passed (it won't be visible in logs for security)
3. The app will be built with the API key embedded

## Local Development

For local development, you can set the environment variable:

### Windows PowerShell:
```powershell
$env:GROQ_API_KEY="your_groq_api_key_here"
flutter run
```

### Windows CMD:
```cmd
set GROQ_API_KEY=your_groq_api_key_here
flutter run
```

### Linux/Mac:
```bash
export GROQ_API_KEY="your_groq_api_key_here"
flutter run
```

### Or use --dart-define directly:
```bash
flutter run --dart-define=GROQ_API_KEY=your_groq_api_key_here
```

## How It Works

1. **GitHub Secret** → Stored securely in GitHub
2. **Workflow** → Passes secret as environment variable
3. **Flutter Build** → `--dart-define=GROQ_API_KEY=...` passes it to Dart
4. **Code** → `String.fromEnvironment('GROQ_API_KEY')` reads it at compile time

## Security Considerations

⚠️ **Important**: API keys embedded in the app binary can be extracted by reverse engineering the APK/IPA.

### For Production Apps, Consider:

1. **Backend Proxy** (Recommended)
   - Store API key on your backend server
   - App calls your backend, backend calls Groq
   - Key never leaves your server

2. **Key Restrictions**
   - In Groq console, set IP whitelist
   - Set rate limits
   - Monitor usage

3. **Key Rotation**
   - Rotate keys periodically
   - If a key is exposed, revoke it immediately

## Current Implementation

The code in `lib/providers/ai_chat_provider_groq.dart`:

```dart
static String get _groqApiKey {
  const envKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: 'YOUR_GROQ_API_KEY');
  return envKey;
}
```

This reads the key at compile time. If not provided, it uses the placeholder `'YOUR_GROQ_API_KEY'`.

## Testing

After setting up the secret:

1. **In CI/CD**: The workflow will automatically use it
2. **Locally**: Set the environment variable or use `--dart-define`
3. **Verify**: The app should be able to make API calls to Groq

## Troubleshooting

### "AI Chat is not configured" error
- Check that `GROQ_API_KEY` secret is set in GitHub
- Verify the secret name matches exactly: `GROQ_API_KEY`
- For local dev, ensure environment variable is set

### Build succeeds but API calls fail
- Verify the API key is valid in Groq console
- Check API key permissions
- Ensure the key hasn't been revoked

## Next Steps

1. ✅ Add `GROQ_API_KEY` secret to GitHub
2. ✅ Workflow is already updated
3. ✅ Code is ready to use it
4. 🚀 Push a commit to test!

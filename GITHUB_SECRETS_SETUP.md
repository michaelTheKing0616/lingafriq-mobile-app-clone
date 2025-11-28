# Setting Up GitHub Secrets for API Keys

## Current Code Status

✅ **The code IS set up** to use GitHub secrets via `String.fromEnvironment()` for:
- `GROQ_API_KEY` - For AI chat functionality
- `STABILITY_AI_KEY` - For AI image generation (recommended)
- `HUGGINGFACE_API_KEY` - Alternative for AI images
- `REPLICATE_API_KEY` - Alternative for AI images
- `LEONARDO_API_KEY` - Alternative for AI images

All providers read API keys from compile-time environment variables, which can be passed via `--dart-define` during the Flutter build process.

## Step-by-Step Setup

### Step 1: Add GitHub Secrets

1. Go to your GitHub repository: `https://github.com/lingafriq/mobile-app` (or your clone repo)
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each API key you need:

#### Required: GROQ_API_KEY (for AI Chat)
- **Name**: `GROQ_API_KEY`
- **Value**: Your Groq API key (get it from https://console.groq.com/)
- **Purpose**: Powers the AI chat/tutor functionality
- Click **Add secret**

#### Optional: STABILITY_AI_KEY (for AI Image Generation - Recommended)
- **Name**: `STABILITY_AI_KEY`
- **Value**: Your Stability AI API key (get it from https://platform.stability.ai/account/keys)
- **Purpose**: Generates dynamic African person portraits for loading screen
- **Free Tier**: 25 images/month
- **Placeholder**: `YOUR_STABILITY_AI_KEY` (if not set, will use fallback)
- Click **Add secret**

#### Optional: HUGGINGFACE_TOKEN (for AI Image Generation - Fallback)
- **Name**: `HUGGINGFACE_TOKEN`
- **Value**: Your existing Hugging Face token (from previous setup)
- **Purpose**: Fallback for AI image generation if Stability AI is not available
- **Note**: This is the existing token you already have configured
- Click **Add secret** (if not already added)

#### Alternative Image APIs (optional):
- **REPLICATE_API_KEY**: For Replicate API ($5 free credit)
- **LEONARDO_API_KEY**: For Leonardo.ai (150 free images/day)

**Note**: The code will automatically use whichever key is available. Priority: Stability AI → Hugging Face → Replicate → Leonardo

### Step 2: GitHub Actions Workflow

The workflow should be updated to pass all API keys to the Flutter build. It will:
- Pass `GROQ_API_KEY` to the Flutter build via `--dart-define`
- Pass `STABILITY_AI_KEY` (or other image API key) via `--dart-define`
- Build will work even if secrets are not set (with a warning)

**Example workflow configuration:**
```yaml
- name: Build APK
  run: |
    flutter build apk --release \
      --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }} \
      --dart-define=STABILITY_AI_KEY=${{ secrets.STABILITY_AI_KEY }}
```

**Note**: If you don't have a workflow yet, see the "GitHub Actions Workflow Setup" section below.

### Step 3: Verify It Works

1. Push a commit to trigger the workflow
2. Check the build logs - you should see the API key being passed (it won't be visible in logs for security)
3. The app will be built with the API key embedded

## Local Development

For local development, you can set the environment variables:

### Windows PowerShell:
```powershell
$env:GROQ_API_KEY="your_groq_api_key_here"
$env:STABILITY_AI_KEY="your_stability_ai_key_here"
$env:HUGGINGFACE_TOKEN="your_huggingface_token_here"
flutter run
```

### Windows CMD:
```cmd
set GROQ_API_KEY=your_groq_api_key_here
set STABILITY_AI_KEY=your_stability_ai_key_here
set HUGGINGFACE_TOKEN=your_huggingface_token_here
flutter run
```

### Linux/Mac:
```bash
export GROQ_API_KEY="your_groq_api_key_here"
export STABILITY_AI_KEY="your_stability_ai_key_here"
export HUGGINGFACE_TOKEN="your_huggingface_token_here"
flutter run
```

### Or use --dart-define directly:
```bash
flutter run \
  --dart-define=GROQ_API_KEY=your_groq_api_key_here \
  --dart-define=STABILITY_AI_KEY=your_stability_ai_key_here \
  --dart-define=HUGGINGFACE_TOKEN=your_huggingface_token_here
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

### Groq API Key (AI Chat)
The code in `lib/providers/ai_chat_provider_groq.dart`:

```dart
static String get _groqApiKey {
  const envKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: 'YOUR_GROQ_API_KEY');
  return envKey;
}
```

### AI Image API Keys
The code in `lib/services/ai_image_service.dart`:

```dart
static String? get _apiKey {
  // Tries multiple providers in order of preference
  const stabilityKey = String.fromEnvironment('STABILITY_AI_KEY', defaultValue: '');
  if (stabilityKey.isNotEmpty && stabilityKey != 'YOUR_STABILITY_AI_KEY') {
    return stabilityKey;
  }
  // ... tries other providers
  return null;
}
```

This reads keys at compile time. If not provided, it returns `null` and falls back to placeholder images.

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

## GitHub Actions Workflow Setup

If you don't have a workflow file yet, create `.github/workflows/build.yml`:

```yaml
name: Build and Release

on:
  push:
    branches: [ fresh-main, main ]
  pull_request:
    branches: [ fresh-main, main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build APK
        run: |
          flutter build apk --release \
            --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }} \
            --dart-define=STABILITY_AI_KEY=${{ secrets.STABILITY_AI_KEY }} \
            --dart-define=HUGGINGFACE_API_KEY=${{ secrets.HUGGINGFACE_API_KEY }} \
            --dart-define=REPLICATE_API_KEY=${{ secrets.REPLICATE_API_KEY }} \
            --dart-define=LEONARDO_API_KEY=${{ secrets.LEONARDO_API_KEY }}
      
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

**Note**: The workflow will work even if some secrets are not set. Only set the secrets you're actually using.

## Next Steps

1. ✅ Add `GROQ_API_KEY` secret to GitHub (required for AI chat)
2. ✅ Add `STABILITY_AI_KEY` secret to GitHub (optional, for image generation)
3. ✅ Create/update GitHub Actions workflow (if not exists)
4. ✅ Code is ready to use secrets
5. 🚀 Push a commit to test!

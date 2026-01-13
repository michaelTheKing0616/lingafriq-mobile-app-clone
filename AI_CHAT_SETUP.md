# AI Chat Feature Setup Guide

## ✅ **NOW USING HUGGING FACE (FREE, NO CREDIT CARD REQUIRED!)**

## Overview
The AI Language Tutor feature uses **Hugging Face Inference API** (FREE) to provide conversational language learning support for African languages including:
- Swahili (Kiswahili)
- Yoruba
- Igbo
- Hausa
- Zulu
- Xhosa
- Amharic
- Pidgin English (Nigerian Pidgin)
- Twi
- Afrikaans
- And many other African languages

## Why Hugging Face?
Hugging Face was chosen because:
1. **100% FREE** - No credit card required (1,000 requests/month)
2. **Good multilingual support** - Multiple models available
3. **Easy integration** - Simple REST API
4. **No upfront costs** - Perfect for testing and small apps
5. **Easy to switch** - Can upgrade to paid tier or switch models anytime

## Setup Instructions (2 Minutes!)

### Step 1: Get FREE Hugging Face Token
1. Go to [Hugging Face](https://huggingface.co/)
2. Sign up (or log in) - **No credit card required!**
3. Navigate to [API Tokens](https://huggingface.co/settings/tokens)
4. Click "New token"
5. Name it: "LingAfriq Mobile App"
6. Select "Read" access
7. Click "Generate token"
8. **Copy the token immediately** (you won't see it again!)

### Step 2: Configure Token in App
Open `lib/providers/ai_chat_provider_huggingface.dart` and replace:
```dart
static const String _apiKey = 'YOUR_HUGGINGFACE_TOKEN';
```
with your actual token:
```dart
static const String _apiKey = 'hf_your_actual_token_here';
```

### Step 3: Secure API Key (Recommended for Production)
For production apps, **DO NOT** hardcode the API key. Instead:

**Option A: Environment Variables**
1. Create a `.env` file in the project root:
   ```
   OPENAI_API_KEY=sk-your-actual-api-key-here
   ```
2. Add `flutter_dotenv` to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_dotenv: ^5.1.0
   ```
3. Load in `main.dart`:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   void main() async {
     await dotenv.load(fileName: ".env");
     // ... rest of your code
   }
   ```
4. Use in `ai_chat_provider.dart`:
   ```dart
   static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
   ```

**Option B: Backend Proxy (Most Secure)**
- Create a backend endpoint that proxies requests to OpenAI
- Store API key securely on your server
- App calls your backend instead of OpenAI directly

### Step 4: Test the Feature
1. Run the app: `flutter run`
2. Open the drawer menu (hamburger icon)
3. Tap "AI Language Tutor"
4. Try sending a message like "How do I say hello in Swahili?"

## Features

### Current Features
- ✅ Real-time chat interface
- ✅ Message history persistence
- ✅ Pan-African themed UI
- ✅ Support for multiple African languages
- ✅ Clear chat functionality
- ✅ Loading states and error handling
- ✅ Suggestion chips for quick start

### Future Enhancements
- [ ] Language selection dropdown
- [ ] Voice input/output
- [ ] Conversation templates
- [ ] Grammar correction mode
- [ ] Vocabulary practice mode
- [ ] Cultural context explanations
- [ ] Offline mode with cached responses

## API Costs
OpenAI GPT-4 pricing (as of 2024):
- Input: ~$30 per 1M tokens
- Output: ~$60 per 1M tokens

**Estimated costs per conversation:**
- Average message: ~50 tokens
- Average response: ~200 tokens
- Cost per exchange: ~$0.00002 (very affordable!)

## Troubleshooting

### "Invalid API key" Error
- Verify your API key is correct
- Check that you've replaced `YOUR_OPENAI_API_KEY` in the code
- Ensure your OpenAI account has credits/billing set up

### "Rate limit exceeded" Error
- You've hit OpenAI's rate limits
- Wait a few minutes and try again
- Consider upgrading your OpenAI plan for higher limits

### Connection Timeout
- Check your internet connection
- Verify OpenAI API is accessible from your region
- Consider adding retry logic for production

## Alternative AI Models

If you want to switch to a different AI provider:

### Google Gemini
- Good multilingual support
- Competitive pricing
- Update API endpoint and authentication in `ai_chat_provider.dart`

### Anthropic Claude
- Excellent for long conversations
- Strong reasoning capabilities
- Similar API structure to OpenAI

### Lugha-Llama (Research)
- Specialized for African languages
- Open-source but requires self-hosting
- More complex setup, better for research

## Support
For issues or questions:
1. Check OpenAI API documentation: https://platform.openai.com/docs
2. Review error messages in the app
3. Check your OpenAI account dashboard for usage and errors


# Free AI Image Generation API Keys Guide

This guide shows you how to get **free API keys** for AI image generation services to create dynamic African person portraits for the loading screen.

## 🎯 Best Free Options

### Option 1: Stability AI (Stable Diffusion) - **RECOMMENDED** ⭐

**Why it's best:**
- ✅ **25 free credits per month** (enough for ~25 images)
- ✅ High-quality images
- ✅ Fast generation
- ✅ Good for portraits
- ✅ Easy API integration

**Steps to get free API key:**

1. **Sign up for free account:**
   - Go to: https://platform.stability.ai/
   - Click "Sign Up" or "Get Started"
   - Use your email or Google/GitHub account

2. **Get your API key:**
   - After signing up, go to: https://platform.stability.ai/account/keys
   - Click "Create API Key"
   - Copy your API key (starts with `sk-...`)
   - **Important:** Save it securely - you won't see it again!

3. **Check your free credits:**
   - Go to: https://platform.stability.ai/account/credits
   - You should see **25 free credits** per month
   - Each image costs 1 credit

4. **Update the code:**
   ```dart
   // In lib/services/ai_image_service.dart
   static const String _apiKey = 'sk-your-stability-ai-key-here';
   static const String _baseUrl = 'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image';
   ```

5. **Implementation example:**
   ```dart
   static Future<String> generatePersonImage({
     required String country,
     required String language,
     String? style,
   }) async {
     final prompt = _buildPrompt(country: country, language: language, style: style);
     
     final response = await http.post(
       Uri.parse(_baseUrl),
       headers: {
         'Authorization': 'Bearer $_apiKey',
         'Content-Type': 'application/json',
         'Accept': 'application/json',
       },
       body: jsonEncode({
         'text_prompts': [
           {
             'text': prompt,
             'weight': 1.0,
           }
         ],
         'cfg_scale': 7,
         'height': 1024,
         'width': 1024,
         'samples': 1,
         'steps': 30,
       }),
     );
     
     if (response.statusCode == 200) {
       final data = jsonDecode(response.body);
       final base64Image = data['artifacts'][0]['base64'];
       // Convert base64 to URL or save to file
       return 'data:image/png;base64,$base64Image';
     } else {
       throw Exception('Failed to generate image: ${response.statusCode}');
     }
   }
   ```

---

### Option 2: Hugging Face Inference API - **FREE** 🆓

**Why it's good:**
- ✅ **Completely free** (with rate limits)
- ✅ Multiple models available
- ✅ No credit card required
- ⚠️ Slower than paid options
- ⚠️ Rate limited (but fine for loading screen images)

**Steps to get free API key:**

1. **Sign up:**
   - Go to: https://huggingface.co/join
   - Create a free account

2. **Get your token:**
   - Go to: https://huggingface.co/settings/tokens
   - Click "New token"
   - Name it (e.g., "LingAfriq Image Generation")
   - Select "Read" permission
   - Copy the token (starts with `hf_...`)

3. **Choose a model:**
   - Recommended: `stabilityai/stable-diffusion-xl-base-1.0`
   - Or: `runwayml/stable-diffusion-v1-5`
   - Browse models: https://huggingface.co/models?pipeline_tag=text-to-image

4. **Update the code:**
   ```dart
   static const String _apiKey = 'hf_your-huggingface-token-here';
   static const String _modelId = 'stabilityai/stable-diffusion-xl-base-1.0';
   static const String _baseUrl = 'https://api-inference.huggingface.co/models/$_modelId';
   ```

5. **Implementation example:**
   ```dart
   static Future<String> generatePersonImage({
     required String country,
     required String language,
     String? style,
   }) async {
     final prompt = _buildPrompt(country: country, language: language, style: style);
     
     final response = await http.post(
       Uri.parse(_baseUrl),
       headers: {
         'Authorization': 'Bearer $_apiKey',
         'Content-Type': 'application/json',
       },
       body: jsonEncode({
         'inputs': prompt,
       }),
     );
     
     if (response.statusCode == 200) {
       // Hugging Face returns base64 image
       final base64Image = base64Encode(response.bodyBytes);
       return 'data:image/png;base64,$base64Image';
     } else if (response.statusCode == 503) {
       // Model is loading, wait and retry
       await Future.delayed(Duration(seconds: 10));
       return generatePersonImage(country: country, language: language, style: style);
     } else {
       throw Exception('Failed to generate image: ${response.statusCode}');
     }
   }
   ```

---

### Option 3: Replicate API - **FREE TRIAL** 🎁

**Why it's good:**
- ✅ **$5 free credit** to start
- ✅ High-quality models
- ✅ Easy to use
- ⚠️ Requires credit card (but won't charge if you stay within free tier)

**Steps to get free API key:**

1. **Sign up:**
   - Go to: https://replicate.com/
   - Click "Sign Up"
   - Use email or GitHub

2. **Get your API token:**
   - Go to: https://replicate.com/account/api-tokens
   - Click "Create token"
   - Copy the token (starts with `r8_...`)

3. **Check free credits:**
   - You get $5 free credit
   - Each image costs ~$0.002-0.01 (very cheap!)
   - $5 = ~500-2500 images

4. **Update the code:**
   ```dart
   static const String _apiKey = 'r8_your-replicate-token-here';
   static const String _baseUrl = 'https://api.replicate.com/v1/predictions';
   static const String _modelVersion = 'stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b';
   ```

---

### Option 4: Leonardo.ai - **FREE TIER** 🎨

**Why it's good:**
- ✅ **150 free images per day**
- ✅ Excellent quality
- ✅ Good for portraits
- ⚠️ Requires account setup

**Steps:**

1. Sign up: https://leonardo.ai/
2. Go to API settings
3. Generate API key
4. Use their REST API

---

## 📝 Complete Implementation Example

Here's a complete example using **Stability AI** (recommended):

```dart
// lib/services/ai_image_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIImageService {
  // Replace with your actual API key
  static const String _apiKey = 'sk-your-key-here';
  static const String _baseUrl = 'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image';

  static Future<String> generatePersonImage({
    required String country,
    required String language,
    String? style,
  }) async {
    final prompt = _buildPrompt(country: country, language: language, style: style);
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'text_prompts': [
            {
              'text': prompt,
              'weight': 1.0,
            }
          ],
          'cfg_scale': 7,
          'height': 1024,
          'width': 1024,
          'samples': 1,
          'steps': 30,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final base64Image = data['artifacts'][0]['base64'];
        
        // Option 1: Return as data URL (for immediate display)
        return 'data:image/png;base64,$base64Image';
        
        // Option 2: Save to file and return path
        // final file = await _saveBase64Image(base64Image, '$country_$language.png');
        // return file.path;
      } else {
        final error = jsonDecode(response.body);
        throw Exception('API Error: ${error['message']}');
      }
    } catch (e) {
      print('Error generating image: $e');
      // Fallback to placeholder
      return 'assets/images/loading/placeholder.png';
    }
  }

  static String _buildPrompt({
    required String country,
    required String language,
    String? style,
  }) {
    final styleText = style ?? 'traditional';
    return 'A beautiful professional portrait photograph of an African person from $country, '
        'representing $language culture, wearing $styleText African attire, '
        'head and shoulders, centered composition, circular frame suitable, '
        'high quality, cultural authenticity, diverse representation, '
        'positive representation, studio lighting, professional photography, '
        'warm skin tones, detailed traditional patterns, authentic jewelry';
  }

  // Helper to save base64 image to file
  static Future<File> _saveBase64Image(String base64String, String filename) async {
    final bytes = base64Decode(base64String);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/loading_images/$filename');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file;
  }
}
```

## 🔐 Security Best Practices

**NEVER commit API keys to Git!**

1. **Use environment variables:**
   ```dart
   static String get _apiKey {
     const envKey = String.fromEnvironment('STABILITY_AI_KEY', defaultValue: '');
     if (envKey.isEmpty) {
       // Try to load from secure storage
       return ''; // Or load from encrypted storage
     }
     return envKey;
   }
   ```

2. **Or use a secrets file (gitignored):**
   ```dart
   // lib/config/secrets.dart (add to .gitignore)
   class Secrets {
     static const String stabilityAiKey = 'your-key-here';
   }
   ```

3. **For production, use backend:**
   - Store API key on your server
   - Make API calls from backend
   - Return image URLs to app

## 📦 Required Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0  # For API calls
  path_provider: ^2.1.4  # Already added
```

## 🚀 Quick Start Checklist

- [ ] Choose an API provider (Stability AI recommended)
- [ ] Sign up and get API key
- [ ] Add `http` package to `pubspec.yaml`
- [ ] Update `AIImageService` with your API key
- [ ] Test with one image generation
- [ ] Implement caching for generated images
- [ ] Update loading screen content to use generated images

## 💡 Tips

1. **Batch generate images** during development, then cache them
2. **Use consistent prompts** for similar style across all images
3. **Test prompts** in the provider's web interface first
4. **Cache images locally** to avoid regenerating
5. **Have fallback images** in case API fails

## 🆘 Troubleshooting

**"Invalid API key"**
- Check you copied the full key
- Verify key hasn't expired
- Check for extra spaces

**"Rate limit exceeded"**
- Wait a bit and retry
- Consider upgrading plan
- Use caching to reduce API calls

**"Model not found"**
- Check model ID is correct
- Verify model is available in your region
- Try a different model

**Images not loading**
- Check base64 encoding
- Verify image format (PNG/JPG)
- Check file permissions if saving locally

## 📚 Additional Resources

- **Stability AI Docs:** https://platform.stability.ai/docs
- **Hugging Face Docs:** https://huggingface.co/docs/api-inference
- **Replicate Docs:** https://replicate.com/docs
- **Flutter HTTP Package:** https://pub.dev/packages/http

---

**Recommendation:** Start with **Stability AI** (25 free images/month) for the best balance of quality and free tier. Once you have enough images, you can switch to using cached/local images to avoid API costs.


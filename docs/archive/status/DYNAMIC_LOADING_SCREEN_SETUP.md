# Dynamic Loading Screen Setup Guide

## Overview

The dynamic loading screen is a culturally rich, engaging loading experience that showcases:
- **Rotating images** of African people from various countries (Nigeria, South Africa, Kenya, etc.)
- **Dynamic greetings** in local languages (Swahili, Yoruba, Zulu, etc.)
- **Interesting facts** about Africa and African languages
- **Smooth loading animations** with progress indicators

## Current Implementation

### ✅ Completed Features

1. **Dynamic Loading Screen Component** (`lib/screens/loading/dynamic_loading_screen.dart`)
   - Beautiful UI matching the design concept
   - Circular illustration of African person
   - Greeting display with translation
   - Interesting fact display
   - Animated progress bar

2. **Content Management** (`lib/models/loading_screen_content.dart`)
   - Data model for loading screen content
   - Curated list of 10+ content entries covering:
     - Swahili (Kenya, Tanzania)
     - Yoruba (Nigeria)
     - Zulu (South Africa)
     - Igbo (Nigeria)
     - Hausa (Nigeria)
     - Amharic (Ethiopia)
     - Xhosa (South Africa)
     - Twi (Ghana)

3. **Content Rotation Provider** (`lib/providers/loading_screen_provider.dart`)
   - Smart rotation system that avoids showing recently viewed content
   - Preference-based storage to track viewed content
   - Methods to filter by country or language

4. **AI Image Service** (`lib/services/ai_image_service.dart`)
   - Framework for AI image generation integration
   - Ready for API integration (DALL-E, Midjourney, Stable Diffusion, etc.)

5. **App Integration**
   - Integrated into `SplashScreen` for app initialization
   - Shows for 3 seconds during app startup

## Setting Up AI-Generated Images

### Option 1: DALL-E API (OpenAI)

1. **Get API Key**: Sign up at https://platform.openai.com/
2. **Update Service**: Modify `lib/services/ai_image_service.dart`:

```dart
static const String _apiKey = 'your-openai-api-key';
static const String _baseUrl = 'https://api.openai.com/v1/images/generations';

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
      'prompt': prompt,
      'n': 1,
      'size': '512x512',
      'response_format': 'url',
    }),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data'][0]['url'] as String;
  } else {
    throw Exception('Failed to generate image: ${response.statusCode}');
  }
}
```

### Option 2: Stable Diffusion API

1. **Get API Key**: Sign up at https://stability.ai/
2. **Update Service**: Similar to DALL-E but with Stability AI endpoints

### Option 3: Custom AI Service

1. **Set up your own AI image generation service**
2. **Update `AIImageService`** to call your API
3. **Implement caching** for generated images

### Option 4: Pre-generated Images (Recommended for MVP)

1. **Generate images manually** using AI tools (DALL-E, Midjourney, etc.)
2. **Store in assets**: `assets/images/loading/`
3. **Update content entries** to use asset paths:

```dart
LoadingScreenContent(
  id: 'swahili_kenya_1',
  imageUrl: 'assets/images/loading/swahili_kenya_1.png',
  // ... rest of content
),
```

## Adding New Content

### Add New Country/Language Entry

1. **Edit** `lib/models/loading_screen_content.dart`
2. **Add to** `LoadingScreenContentData.defaultContent`:

```dart
LoadingScreenContent(
  id: 'language_country_unique_id',
  imageUrl: 'assets/images/loading/your_image.png',
  country: 'Country Name',
  countryFlag: '🇺🇳', // Use emoji flag
  greeting: 'Local Greeting',
  greetingTranslation: 'English Translation',
  language: 'Language Name',
  fact: 'Interesting fact about the language or country',
),
```

### Add More Facts

Create a separate facts database or expand the existing entries with multiple facts per language.

## Image Requirements

### Recommended Specifications

- **Format**: PNG or JPG
- **Size**: 512x512px (circular crop)
- **Style**: Professional portrait, culturally authentic
- **Background**: Should work with circular crop (person centered)
- **Diversity**: Represent various African ethnicities and cultures

### AI Prompt Template

```
A beautiful portrait of an African person from [COUNTRY], 
representing [LANGUAGE] culture, in traditional attire, 
professional photography, high quality, cultural authenticity, 
diverse representation, positive representation, 
circular frame suitable, centered composition
```

## Content Pipeline Workflow

### Current Workflow

1. **App Starts** → Shows `DynamicLoadingScreen`
2. **Provider Loads** → Selects random content (avoiding recent)
3. **Image Loads** → From asset or network URL
4. **Progress Animates** → 3 seconds
5. **Navigation** → To onboarding or main app

### Future Enhancement: Dynamic Content Updates

1. **Backend API** → Serve content from database
2. **CDN** → Host AI-generated images
3. **Caching** → Cache images locally
4. **Analytics** → Track which content performs best

## Configuration

### Adjust Loading Duration

In `lib/screens/splash/splash_screen.dart`:

```dart
Timer(const Duration(seconds: 3), () { // Change duration here
  // ...
});
```

### Adjust Content Rotation

In `lib/providers/loading_screen_provider.dart`:

```dart
// Keep only last 5 viewed to allow rotation
if (updatedViewed.length > 5) { // Change number here
  updatedViewed.removeAt(0);
}
```

## Testing

### Test Content Rotation

1. **Clear app data** or uninstall/reinstall
2. **Launch app multiple times** to see different content
3. **Verify** that content doesn't repeat immediately

### Test Image Loading

1. **Add test images** to `assets/images/loading/`
2. **Update pubspec.yaml** to include assets
3. **Verify** images load correctly

## Next Steps

1. ✅ **Basic Implementation** - DONE
2. 🔄 **Add Real Images** - Generate or source images
3. 🔄 **AI Integration** - Set up API for dynamic generation
4. 🔄 **Backend Integration** - Move content to database
5. 🔄 **Analytics** - Track engagement with different content
6. 🔄 **A/B Testing** - Test different content variations

## Assets Directory Structure

```
assets/
  images/
    loading/
      swahili_kenya_1.png
      swahili_tanzania_1.png
      yoruba_nigeria_1.png
      yoruba_nigeria_2.png
      zulu_south_africa_1.png
      zulu_south_africa_2.png
      igbo_nigeria_1.png
      hausa_nigeria_1.png
      amharic_ethiopia_1.png
      xhosa_south_africa_1.png
      twi_ghana_1.png
```

## Notes

- The loading screen is designed to be culturally respectful and authentic
- All content should be reviewed for accuracy and cultural sensitivity
- Images should represent diverse African ethnicities and cultures
- Facts should be educational and engaging
- The system is designed to be easily extensible for more content


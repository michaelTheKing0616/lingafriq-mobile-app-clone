/// Service for AI-generated image pipeline
/// This service can be integrated with various AI image generation APIs:
/// - Stability AI (Stable Diffusion) - RECOMMENDED: 25 free images/month
/// - Hugging Face Inference API - FREE with rate limits
/// - Replicate API - $5 free credit
/// - Leonardo.ai - 150 free images/day
/// 
/// See FREE_AI_IMAGE_API_GUIDE.md for detailed setup instructions
/// 
/// API Key Configuration:
/// - Set via GitHub Secret: STABILITY_AI_KEY (for Stability AI - primary)
/// - Or use: HUGGINGFACE_TOKEN (fallback - existing token from previous setup)
/// - Or use: REPLICATE_API_KEY, LEONARDO_API_KEY
/// - For local dev: Use --dart-define or environment variables
/// - See GITHUB_SECRETS_SETUP.md for complete setup
/// 
/// Note: GROQ_API_KEY is used separately for Polie AI chat feature
class AIImageService {
  /// Get API key from environment variable (set via GitHub Secrets or --dart-define)
  /// Supports multiple providers - set the appropriate secret based on your choice
  static String? get _apiKey {
    // Try Stability AI first (recommended)
    const stabilityKey = String.fromEnvironment('STABILITY_AI_KEY', defaultValue: '');
    if (stabilityKey.isNotEmpty && stabilityKey != 'YOUR_STABILITY_AI_KEY') {
      return stabilityKey;
    }
    
    // Try Hugging Face (using existing HUGGINGFACE_TOKEN)
    const hfKey = String.fromEnvironment('HUGGINGFACE_TOKEN', defaultValue: '');
    if (hfKey.isNotEmpty && hfKey != 'YOUR_HUGGINGFACE_TOKEN') {
      return hfKey;
    }
    
    // Try Replicate
    const replicateKey = String.fromEnvironment('REPLICATE_API_KEY', defaultValue: '');
    if (replicateKey.isNotEmpty && replicateKey != 'YOUR_REPLICATE_API_KEY') {
      return replicateKey;
    }
    
    // Try Leonardo.ai
    const leonardoKey = String.fromEnvironment('LEONARDO_API_KEY', defaultValue: '');
    if (leonardoKey.isNotEmpty && leonardoKey != 'YOUR_LEONARDO_API_KEY') {
      return leonardoKey;
    }
    
    return null;
  }
  
  /// Get the API provider being used based on which key is available
  static String get _provider {
    const stabilityKey = String.fromEnvironment('STABILITY_AI_KEY', defaultValue: '');
    if (stabilityKey.isNotEmpty && stabilityKey != 'YOUR_STABILITY_AI_KEY') {
      return 'stability';
    }
    const hfKey = String.fromEnvironment('HUGGINGFACE_TOKEN', defaultValue: '');
    if (hfKey.isNotEmpty && hfKey != 'YOUR_HUGGINGFACE_TOKEN') {
      return 'huggingface';
    }
    const replicateKey = String.fromEnvironment('REPLICATE_API_KEY', defaultValue: '');
    if (replicateKey.isNotEmpty && replicateKey != 'YOUR_REPLICATE_API_KEY') {
      return 'replicate';
    }
    const leonardoKey = String.fromEnvironment('LEONARDO_API_KEY', defaultValue: '');
    if (leonardoKey.isNotEmpty && leonardoKey != 'YOUR_LEONARDO_API_KEY') {
      return 'leonardo';
    }
    return 'none';
  }
  
  /// Get the base URL based on the provider
  static String get _baseUrl {
    switch (_provider) {
      case 'stability':
        return 'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image';
      case 'huggingface':
        return 'https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0';
      case 'replicate':
        return 'https://api.replicate.com/v1/predictions';
      case 'leonardo':
        return 'https://cloud.leonardo.ai/api/rest/v1/generations';
      default:
        return '';
    }
  }

  /// Generate an AI image of an African person from a specific country
  /// 
  /// Parameters:
  /// - country: The country name (e.g., "Nigeria", "South Africa", "Kenya")
  /// - language: The language name (e.g., "Yoruba", "Zulu", "Swahili")
  /// - style: Optional style preference (e.g., "traditional", "modern", "cultural")
  /// 
  /// Returns: URL or path of the generated image
  /// 
  /// Note: Requires API key to be set via GitHub Secret or --dart-define
  /// If no API key is available, returns placeholder image path
  static Future<String> generatePersonImage({
    required String country,
    required String language,
    String? style,
  }) async {
    // Check if API key is available
    final apiKey = _apiKey;
    if (apiKey == null || _provider == 'none') {
      // No API key configured, return placeholder
      print('AI Image Service: No API key configured. Using placeholder image.');
      return 'assets/images/loading/placeholder.png';
    }

    // TODO: Implement actual API call based on provider
    // See FREE_AI_IMAGE_API_GUIDE.md for complete implementation examples
    // 
    // Example for Stability AI:
    // final prompt = _buildPrompt(country: country, language: language, style: style);
    // 
    // final response = await http.post(
    //   Uri.parse(_baseUrl),
    //   headers: {
    //     'Authorization': 'Bearer $apiKey',
    //     'Content-Type': 'application/json',
    //     'Accept': 'application/json',
    //   },
    //   body: jsonEncode({
    //     'text_prompts': [{'text': prompt, 'weight': 1.0}],
    //     'cfg_scale': 7,
    //     'height': 1024,
    //     'width': 1024,
    //     'samples': 1,
    //     'steps': 30,
    //   }),
    // );
    // 
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   final base64Image = data['artifacts'][0]['base64'];
    //   // Save to file or return as data URL
    //   return 'data:image/png;base64,$base64Image';
    // } else {
    //   throw Exception('Failed to generate image: ${response.statusCode}');
    // }

    // For now, return placeholder until API implementation is complete
    print('AI Image Service: API key configured for $_provider, but implementation pending.');
    return 'assets/images/loading/placeholder.png';
  }

  /// Build a prompt for AI image generation
  static String _buildPrompt({
    required String country,
    required String language,
    String? style,
  }) {
    final styleText = style ?? 'traditional';
    return 'A beautiful portrait of an African person from $country, '
        'representing $language culture, in $styleText attire, '
        'professional photography, high quality, cultural authenticity, '
        'diverse representation, positive representation';
  }

  /// Batch generate images for all countries/languages
  /// This can be called periodically to refresh the image library
  static Future<Map<String, String>> generateImageLibrary() async {
    final countries = [
      'Nigeria',
      'South Africa',
      'Kenya',
      'Tanzania',
      'Ghana',
      'Ethiopia',
    ];

    final languages = [
      'Yoruba',
      'Zulu',
      'Swahili',
      'Igbo',
      'Hausa',
      'Xhosa',
      'Twi',
      'Amharic',
    ];

    final imageMap = <String, String>{};

    for (final country in countries) {
      for (final language in languages) {
        try {
          final imageUrl = await generatePersonImage(
            country: country,
            language: language,
          );
          imageMap['${country}_$language'] = imageUrl;
        } catch (e) {
          // Log error but continue
          print('Error generating image for $country/$language: $e');
        }
      }
    }

    return imageMap;
  }

  /// Cache management: Download and cache images locally
  static Future<void> cacheImages(Map<String, String> imageUrls) async {
    // TODO: Implement image caching
    // Use packages like:
    // - cached_network_image (already in use)
    // - flutter_cache_manager
    // - path_provider (for local storage)
  }
}


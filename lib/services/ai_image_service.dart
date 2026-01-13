import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

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
      debugPrint('AI Image Service: No API key configured. Using placeholder image.');
      return 'assets/images/loading/placeholder.png';
    }

    try {
      final prompt = _buildPrompt(country: country, language: language, style: style);

      if (_provider == 'stability') {
        // Stability text-to-image JSON API
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'text_prompts': [
              {'text': prompt, 'weight': 1.0}
            ],
            'cfg_scale': 7,
            'height': 768,
            'width': 768,
            'samples': 1,
            'steps': 30,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final artifacts = (data['artifacts'] as List?) ?? [];
          if (artifacts.isNotEmpty && artifacts[0]['base64'] != null) {
            final base64Image = artifacts[0]['base64'] as String;
            return 'data:image/png;base64,$base64Image';
          }
        } else {
          debugPrint(
              'AI Image Service: Stability API error ${response.statusCode} ${response.body}');
        }
      } else if (_provider == 'huggingface') {
        // Hugging Face Inference API (image bytes)
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'inputs': prompt}),
        );

        if (response.statusCode == 200 &&
            response.headers['content-type'] != null &&
            response.headers['content-type']!.startsWith('image/')) {
          final base64Image = base64Encode(response.bodyBytes);
          final mime = response.headers['content-type'] ?? 'image/png';
          return 'data:$mime;base64,$base64Image';
        } else {
          debugPrint(
              'AI Image Service: Hugging Face API error ${response.statusCode} ${response.body}');
        }
      } else if (_provider == 'replicate') {
        // Replicate text-to-image: create prediction then poll until completed.
        // NOTE: Requires REPLICATE_MODEL_VERSION to be set for full production use.
        const modelVersion =
            String.fromEnvironment('REPLICATE_MODEL_VERSION', defaultValue: '');
        if (modelVersion.isEmpty) {
          debugPrint('AI Image Service: REPLICATE_MODEL_VERSION not set, skipping.');
        } else {
          final createRes = await http.post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Token $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'version': modelVersion,
              'input': {'prompt': prompt},
            }),
          );

          if (createRes.statusCode == 201 || createRes.statusCode == 200) {
            final data = jsonDecode(createRes.body) as Map<String, dynamic>;
            final getUrl = data['urls']?['get']?.toString();
            if (getUrl != null) {
              // Simple polling loop with small timeout budget
              for (var i = 0; i < 10; i++) {
                await Future.delayed(const Duration(seconds: 2));
                final statusRes = await http.get(
                  Uri.parse(getUrl),
                  headers: {'Authorization': 'Token $apiKey'},
                );
                if (statusRes.statusCode != 200) continue;
                final statusData =
                    jsonDecode(statusRes.body) as Map<String, dynamic>;
                final status = statusData['status']?.toString();
                if (status == 'succeeded') {
                  final outputs = statusData['output'] as List?;
                  if (outputs != null && outputs.isNotEmpty) {
                    // Replicate returns hosted URLs
                    return outputs.first.toString();
                  }
                  break;
                } else if (status == 'failed' || status == 'canceled') {
                  debugPrint('AI Image Service: Replicate prediction $status');
                  break;
                }
              }
            }
          } else {
            debugPrint(
                'AI Image Service: Replicate create error ${createRes.statusCode} ${createRes.body}');
          }
        }
      } else {
        debugPrint('AI Image Service: Provider $_provider not implemented, falling back.');
      }
    } catch (e) {
      debugPrint('AI Image Service: Error generating image: $e');
    }

    // Fallback: placeholder
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
    try {
      final cache = DefaultCacheManager();
      for (final entry in imageUrls.entries) {
        final url = entry.value;
        if (url.startsWith('http')) {
          await cache.downloadFile(url);
        }
      }
    } catch (e) {
      debugPrint('AI Image Service: Error caching images: $e');
    }
  }
}


/// Environment Configuration
/// Centralized access to environment variables and API keys
/// Keys are injected via GitHub Actions secrets during build

class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();
  
  /// Groq API Key for LLaMA access
  /// Set via: --dart-define=GROQ_API_KEY=xxx during build
  static String get groqApiKey {
    const key = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
    return key;
  }
  
  /// HuggingFace API Token for NLLB-200 and AfriTeVa
  /// Set via: --dart-define=HUGGINGFACE_TOKEN=xxx during build
  static String get huggingFaceToken {
    const token = String.fromEnvironment('HUGGINGFACE_TOKEN', defaultValue: '');
    return token;
  }
  
  /// Stability AI Key for image generation (if needed)
  /// Set via: --dart-define=STABILITY_AI_KEY=xxx during build
  static String get stabilityAiKey {
    const key = String.fromEnvironment('STABILITY_AI_KEY', defaultValue: '');
    return key;
  }
  
  /// Check if Groq API is configured
  static bool get isGroqConfigured => groqApiKey.isNotEmpty;
  
  /// Check if HuggingFace is configured
  static bool get isHuggingFaceConfigured => huggingFaceToken.isNotEmpty;
  
  /// Check if Stability AI is configured
  static bool get isStabilityAiConfigured => stabilityAiKey.isNotEmpty;
  
  /// Backend base URL
  /// IMPORTANT: Update this default to your actual backend API URL
  /// Set via: --dart-define=BACKEND_URL=https://api.lingafriq.com during build
  /// If using nginx reverse proxy, ensure it points to the backend port (e.g., http://localhost:4000)
  static String get backendBaseUrl {
    const url = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://api.lingafriq.com');
    return url;
  }
  
  /// Get all configuration status for debugging
  static Map<String, bool> get configurationStatus => {
    'groq': isGroqConfigured,
    'huggingface': isHuggingFaceConfigured,
    'stability': isStabilityAiConfigured,
  };
}


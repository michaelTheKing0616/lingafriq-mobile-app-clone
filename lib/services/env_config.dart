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
  
  /// MFA (Montreal Forced Aligner) Service URL for pronunciation scoring
  /// Set via: --dart-define=MFA_SERVICE_URL=xxx during build
  /// Optional - falls back to basic scoring if not configured
  static String? get mfaServiceUrl {
    const url = String.fromEnvironment('MFA_SERVICE_URL', defaultValue: '');
    return url.isNotEmpty ? url : null;
  }
  
  /// Check if MFA service is configured
  static bool get isMFAConfigured => mfaServiceUrl != null && mfaServiceUrl!.isNotEmpty;
  
  /// Backend base URL
  /// For production: set via --dart-define=BACKEND_URL=https://your-api.com during build.
  /// Ensure the backend has CORS configured to allow your app origin (e.g. in backend env: CORS_ORIGIN).
  /// Default matches production at admin.lingafriq.com; override for staging/local.
  static String get backendBaseUrl {
    const url = String.fromEnvironment('BACKEND_URL', defaultValue: 'https://admin.lingafriq.com');
    return url;
  }
  
  /// Get all configuration status for debugging
  static Map<String, bool> get configurationStatus => {
    'groq': isGroqConfigured,
    'huggingface': isHuggingFaceConfigured,
    'stability': isStabilityAiConfigured,
    'mfa': isMFAConfigured,
  };
}


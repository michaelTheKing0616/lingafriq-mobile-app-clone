// Environment Configuration
// Centralized access to environment variables and API keys
// Keys are injected via GitHub Actions secrets during build
// Production defaults avoid localhost; override via --dart-define during build.

class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  /// Backend API base URL (alias for backendBaseUrl)
  static String get baseUrl => backendBaseUrl;

  /// CDN/base URL for static assets (e.g. media served via nginx)
  static String get cdnUrl {
    const url = String.fromEnvironment('CDN_URL', defaultValue: 'https://admin.lingafriq.com');
    return url;
  }

  /// WebSocket base URL for real-time connections
  static String get wsUrl {
    const url = String.fromEnvironment('WS_URL', defaultValue: 'wss://admin.lingafriq.com');
    return url;
  }

  /// App/website base URL for legal, support, and magazine links
  static String get appWebUrl {
    const url = String.fromEnvironment('APP_WEB_URL', defaultValue: 'https://lingafriq.com');
    return url;
  }

  /// Legacy backend URL prefixes to migrate in avatar/profile URLs.
  /// Historical server URLs that may appear in stored profile data.
  static const List<String> legacyBackendUrlPrefixes = [
    'http://34.121.156.251:8000/',
    'http://34.67.162.25:8000/',
    'http://64.227.113.179:8000/',
    'https://api.lingafriq.com/',
  ];

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
  /// Set via --dart-define=BACKEND_URL=https://your-api.com during build.
  /// Production: https://admin.lingafriq.com (nginx → localhost:4000).
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


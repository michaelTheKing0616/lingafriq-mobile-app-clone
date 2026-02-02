/// Centralized URL constants for the LingAfriq app.
/// All external service URLs should be defined here or via EnvConfig/SecretsManager.
/// Verified against official docs (Jan 2025).
/// See APP_URLS_AUDIT.md for full audit and override instructions.

class UrlConstants {
  UrlConstants._();

  // ─── Hugging Face ─────────────────────────────────────────────────────────
  /// Hugging Face Serverless Inference API – for model inference (TTS, translation, image, etc.).
  /// Docs: https://huggingface.co/docs/api-inference/en/getting-started
  static const String huggingFaceServerlessBase = 'https://api-inference.huggingface.co';

  /// Hugging Face Inference Providers router – for OpenAI-compatible chat only.
  /// Docs: https://huggingface.co/docs/api-inference/quicktour
  static const String huggingFaceRouterBase = 'https://router.huggingface.co';

  /// Model inference URL (TTS, translation, image, etc.). Use serverless API.
  static String huggingFaceModel(String modelId) =>
      '$huggingFaceServerlessBase/models/$modelId';

  /// Hugging Face token settings (for user-facing links).
  static const String huggingFaceTokens = 'https://huggingface.co/settings/tokens';

  /// Fallback base for pronunciation/STT when PRONUNCIATION_API_URL is not set (router or serverless).
  static const String huggingFacePronunciationFallback = 'https://api-inference.huggingface.co';

  // ─── Groq (AI Chat) ───────────────────────────────────────────────────────
  /// Groq API chat completions (OpenAI-compatible). Verified Jan 2025.
  /// Docs: https://console.groq.com/docs/openai
  static const String groqChatCompletions =
      'https://api.groq.com/openai/v1/chat/completions';

  // ─── LingAfriq Backend & Web ──────────────────────────────────────────────
  /// Backend API default (override via BACKEND_URL / BACKEND_API_URL at build or runtime).
  static const String backendDefault = 'https://api.lingafriq.com';

  /// App/website base for legal and support links.
  static const String appWebBase = 'https://lingafriq.com';

  static const String termsUrl = '$appWebBase/terms';
  static const String privacyUrl = '$appWebBase/privacy';
  static const String supportEmail = 'mailto:contact@lingafriq.com?subject=LingAfriq%20Support';

  // ─── LiveKit (Live Classroom) ─────────────────────────────────────────────
  /// LiveKit WebSocket URL (project-specific; set via backend token endpoint).
  static const String liveKitWss = 'wss://lingafriq.livekit.cloud';
}

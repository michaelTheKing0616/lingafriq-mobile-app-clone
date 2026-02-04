/// Centralized URL constants for the LingAfriq app.
/// All external service URLs should be defined here or via EnvConfig/SecretsManager.
/// Verified against official docs (Jan 2025).
/// See APP_URLS_AUDIT.md for full audit and override instructions.

class UrlConstants {
  UrlConstants._();

  // ─── Hugging Face ─────────────────────────────────────────────────────────
  /// Primary inference base (router; api-inference.huggingface.co is deprecated).
  /// Docs: https://huggingface.co/docs/api-inference/quicktour
  static const String huggingFaceServerlessBase = 'https://router.huggingface.co';

  /// Hugging Face Inference Providers router – for chat and model inference.
  static const String huggingFaceRouterBase = 'https://router.huggingface.co';

  /// Model inference URL (TTS, translation, image, etc.).
  static String huggingFaceModel(String modelId) =>
      '$huggingFaceRouterBase/models/$modelId';

  /// Hugging Face token settings (for user-facing links).
  static const String huggingFaceTokens = 'https://huggingface.co/settings/tokens';

  /// Fallback base for pronunciation/STT when PRONUNCIATION_API_URL is not set.
  static const String huggingFacePronunciationFallback = 'https://router.huggingface.co';

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

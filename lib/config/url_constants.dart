// Centralized URL constants for the LingAfriq app.
// All external service URLs should be defined here or via EnvConfig/SecretsManager.
// Verified against official docs (Feb 2026):
//   - Groq: https://console.groq.com/docs/models (llama-3.3-70b-versatile, whisper-large-v3)
//   - HuggingFace: https://huggingface.co/docs/api-inference (router.huggingface.co)
//   - Stability AI: https://platform.stability.ai/docs (SDXL 1024)
//   - Replicate: https://replicate.com/docs/reference/http (v1/predictions)
// See APP_URLS_AUDIT.md for full audit and override instructions.

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

  /// Groq Whisper audio transcriptions (OpenAI-compatible).
  static const String groqAudioTranscriptions =
      'https://api.groq.com/openai/v1/audio/transcriptions';

  // ─── LingAfriq Backend & Web ──────────────────────────────────────────────
  /// Backend API default (override via BACKEND_URL / BACKEND_API_URL at build or runtime).
  /// Production: nginx at admin.lingafriq.com proxies to Node backend on :4000.
  static const String backendDefault = 'https://admin.lingafriq.com';

  /// App/website base for legal and support links.
  static const String appWebBase = 'https://lingafriq.com';

  static const String termsUrl = '$appWebBase/terms';
  static const String privacyUrl = '$appWebBase/privacy';
  static const String supportEmail = 'mailto:contact@lingafriq.com?subject=LingAfriq%20Support';

  // ─── LiveKit (Live Classroom) ─────────────────────────────────────────────
  /// LiveKit WebSocket URL (project-specific; set via backend token endpoint).
  static const String liveKitWss = 'wss://lingafriq.livekit.cloud';

  // ─── Connectivity probe ───────────────────────────────────────────────────
  /// Well-known URL for internet connectivity checks (not backend-specific).
  static const String connectivityProbe = 'https://www.google.com';
}

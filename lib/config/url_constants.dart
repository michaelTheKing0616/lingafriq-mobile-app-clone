// Centralized URL constants for the LingAfriq app.
// All external service URLs should be defined here or via EnvConfig/SecretsManager.
// No direct AI-provider endpoints: model calls go through the backend gateway.
// Verified against official docs (Feb 2026):
//   - Stability AI: https://platform.stability.ai/docs (SDXL 1024)
//   - Replicate: https://replicate.com/docs/reference/http (v1/predictions)
// See APP_URLS_AUDIT.md for full audit and override instructions.

class UrlConstants {
  UrlConstants._();

  // ─── Hugging Face ─────────────────────────────────────────────────────────
  /// Fallback base for pronunciation/STT when PRONUNCIATION_API_URL is not set.
  static const String huggingFacePronunciationFallback = 'https://router.huggingface.co';

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

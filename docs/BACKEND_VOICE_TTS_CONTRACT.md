# Voice / TTS contract (Node gateway → Python services)

See also: [Intron integration plan](INTRON_INTEGRATION.md) (live STT vs this TTS stack).


## Primary: device-independent MMS-TTS (`GET /api/tts`)

**Production path for lesson/pronunciation audio:** the Flutter app uses **server-only** synthesis. No `flutter_tts` or system voices.

| Piece | Role |
|--------|------|
| **Mobile** | `VoiceApiService.synthesizeSpeech` → `GET /api/tts?language=…&text=…` (Bearer auth). Plays WAV via `just_audio` (`tts_provider.dart`). |
| **Node** | `src/routes/mmsTts.route.ts` — validates language against `mmsTtsLanguageMap.ts`, optional file cache (`TTS_CACHE_DIR`), proxies to Python with `TTS_SERVICE_URL` (default `http://127.0.0.1:8001`). |
| **Python** | `tts-mms-service/` — FastAPI, `facebook/mms-tts-{iso639-3}`, binds to **127.0.0.1** only. |

Environment:

- `TTS_SERVICE_URL` — Python sidecar base URL (internal).
- `TTS_CACHE_DIR` — WAV cache directory (optional; defaults under backend `.cache/tts`).
- `TTS_PROXY_TIMEOUT_MS` — upstream timeout (default 20000).

Pidgin / Nigerian Pidgin uses MMS `eng` with response header `X-Pidgin-Fallback: true` when applicable; UI may show an “approximate voice” disclaimer (`TtsPlayButton.pidginDisclaimer`).

**Limits:** `text` max **500** characters per request; longer copy should be split by product logic before calling TTS.

---

## Legacy: `POST /api/voice/tts/synthesize`

Older gateway in `src/routes/voice.route.ts` that proxies to `VOICE_SERVICE_URL` with provider routing (`xtts_v2`, `mms_tts`, `piper`). The mobile **no longer** uses this for default playback after the MMS-TTS migration; kept for compatibility with other clients if needed.

---

## Canonical accent profiles (legacy voice route)

| Language | `accentProfile` | Notes |
|----------|-----------------|-------|
| English | **`en-NG`** | **Never** use `en-AF` — `AF` is ISO Afghanistan. |

## Response expectations

- Successful synthesis returns audio bytes with a consistent `Content-Type` (`audio/wav` for MMS path).
- Errors must be non-200 with JSON; **never** empty 200 bodies on failure.

## Versioning

- Changes to `MMS_TTS_LANGUAGE_MAP` or Python inference are contract revisions; deploy mobile + Node + Python together.

charter: v2

# ADR-008 — Stage-1 TTS vendors and licence exclusions (P6-045)

Status: **Accepted** (Tope, 2026-10-27). Records EP-§7.5-09…18, EP-§7.2-31, EP-§7.1-14 and unblocks P6-046+.

## Context

Dynamic TTS (AI tutor turns, personas, uncached phrases) must use **commercially licensed** vendors only. Curriculum audio stays **human-recorded** (§6.6). The companion stack doc (`docs/plan/LINGAFRIQ_AI_MODEL_STACK.md` §3.3, EXT-01) compares Intron, Spitch, Azure, Google Chirp 3 HD, ElevenLabs v3, and Gemini TTS. **Intron remains server-gated** (`AI_INTRON_ENABLED` + Doppler `INTRON_API_KEY`) until ops enable it; routing defaults to Spitch or cloud fallbacks where configured.

Swahili primary/fallback for static/dynamic routing is already fixed by **P5-065** (`assets/data/audio/sw_tts_decision.json`).

## Decision — primary and fallback per Stage-1 language

| Language | Primary (dynamic TTS) | Fallback chain | Notes |
|---|---|---|---|
| Yoruba (`yo`) | Intron TTS | Spitch | Tone-marked NFC text only; diacritic validator before synthesis |
| Igbo (`ig`) | Intron TTS | Spitch | Dotted vowels + tone marks required on teaching strings |
| Hausa (`ha`) | Intron TTS | Spitch → ElevenLabs v3 | Lexicon-marked forms for teaching items |
| Nigerian Pidgin (`pcm`) | Intron TTS | Spitch | Register/naturalness over tone |
| Swahili (`sw`) | Google Chirp 3 HD `sw-KE` | Intron → Chirp → Azure `sw-KE` | Per P5-065 blind-test artefact; tie/poor MOS uses same chain |
| isiZulu (`zu`) | Azure Neural `zu-ZA` (ThandoNeural / ThembaNeural) | Custom commissioned voice (P6-048) | No Intron TTS (English-accent only for zu) |
| isiXhosa (`xh`) | **Commissioned custom voice** (P6-048, EXT-12) | None commercially | No vendor dynamic TTS; `routeTts` returns `voice_coming` until custom voice passes gates (P5-068, P5-069 interim corpus for static items) |

Gateway implementation reference: `node-backend/src/services/ai/providerRouter.ts` (`routeTts`). Mobile per-language wrappers (P5-060…067) mirror this table.

## Decision — excluded models (non-commercial unless relicensed)

| Model | Licence | Action |
|---|---|---|
| **YarnGPT** (`yarn-gpt`) | CC-BY-NC-SA 4.0 | **Excluded** — `licence_register.csv` |
| **MMS-TTS** | CC-BY-NC 4.0 | **Excluded** — remove from any production router |
| **XTTS-v2** (`coqui-xtts-v2`) | Coqui Public Model Licence (non-commercial) | **Excluded** — no commercial licence available |

Persona voice cloning must use vendor custom-voice programmes with signed consent, not XTTS/MMS.

## isiXhosa mandate

No commercial vendor offers a native isiXhosa neural voice suitable for teaching (Intron English-accent only; Lelapa TTS not shipped). **Commissioned native f/m voices and a permissively licensed training stack** (P6-048) are the mandated route; dynamic TTS stays disabled until tone-accuracy gates pass (P6-046, P6-055).

## References

- ELEVATION §7.5:L1449–L1460, §7.1:L1349–L1366
- `docs/plan/LINGAFRIQ_AI_MODEL_STACK.md` §3.3, §9
- `assets/data/audio/sw_tts_decision.json` (P5-065)
- `assets/data/audio/xh_voice_decision.json` (P5-068)
- DECISIONS D9 / EXT-01

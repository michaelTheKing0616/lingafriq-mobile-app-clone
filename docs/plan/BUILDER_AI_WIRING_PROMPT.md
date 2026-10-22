# LingAfriq: wire TTS, STT and LLM (builder brief)

**Source of truth:** `~/LingAfriq/lingafriq/LINGAFRIQ_AI_MODEL_STACK.md`. Read §0 (summary table), §1 (non-commercial parts to replace), §3 (per-function picks), §9 (architecture and phased rollout) and §11 (items to verify) before you write any code.

**Intron status:** the Intron account is set up but **not connected yet**. The code in `node-backend` (`intron.service.ts`, `intronLanguageMap.ts`) exists, but no key is wired in production and the mobile app never calls it. Add the key only as a server-side env var (`INTRON_API_KEY`), never on the client. Build everything so it runs with Intron switched off (feature flag plus fallbacks), and switches on cleanly once the key is set.

## Do
1. **Router in `node-backend`:** one provider router per task and language (stt, tts, llm, realtime), driven by config rather than hard-coded. All provider keys stay server-side.
2. **STT:** Intron Sahara is primary for all seven languages. Point `pronunciation_service.dart` and `/api/voice/stt/transcribe` at the router instead of Whisper (Whisper has no ig, zu, xh or pcm). Self-hosted Omnilingual ASR (Apache-2.0) is the fallback.
3. **TTS:** Intron for yo, ig, ha, pcm and sw; Azure `zu-ZA` for isiZulu; isiXhosa waits for the custom voice, so show a clear "voice coming" state and play human curriculum audio meanwhile. Spitch is the secondary provider. **Remove MMS-TTS from the route (CC-BY-NC).** Human curriculum audio always comes before TTS.
4. **LLM and personas:** use the models in §3.1–3.2. Historical Personas must keep open free chat with any African historical figure, alongside the grounded mode.
5. **Realtime voice:** Gemini Live native audio for sw, yo, ha and zu; a cascade (STT → LLM → TTS) for ig, pcm and xh.
6. **Moderation and privacy:** follow §3.11 and §5. Don't record minors' calls.
7. **Evals:** set up the per-language eval harness from §8 before switching providers on by default.

## Rules
- Use only commercially licensed models. Log each one in the licence register (§6).
- Never cut a feature. Fix it and route it instead.
- Every provider call needs a timeout, a retry, a fallback, and a log entry (provider, language, latency, cost).
- Deliver: the router, env template, flags, the updated mobile calls, tests, and a short note on what is still waiting for Intron's key.

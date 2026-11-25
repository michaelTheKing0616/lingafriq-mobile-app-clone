charter: v2

# ADR-007 — AI Gateway runtime and transports (P6-001)

Status: **Accepted** (Tope, 2026-10-27). Records EP-§7.2-04 and unblocks P6-002+.

## Context

Elevation §7.2 places a single **AI Gateway** between the Flutter app and providers. The gateway must own authN/Z, quotas, prompts, routing, safety, and telemetry. Stage-1 also needs **GPU speech workers** (Omnilingual ASR, aligner, scorer, custom TTS) and an existing **Python** `lingafriq-voice-service` stub. The companion stack doc (`docs/plan/LINGAFRIQ_AI_MODEL_STACK.md` §9.1, EXT-01) already sketches a **node-backend** gateway module.

Candidates considered:

| Option | Pros | Cons |
|---|---|---|
| **TypeScript gateway in `node-backend`** | JWT auth, `/ai/*` routes, OpenAPI client to admin, Jest coverage, Doppler injection, SigLIP and Intron proxies already live | Not ideal for on-box GPU inference |
| **Python gateway (FastAPI)** | Natural home for torch/onnx workers | Duplicates auth, billing, and admin contracts; splits test tooling |
| **Split: TS edge + Python workers only** | Clear boundary: orchestration vs inference | Requires internal service auth (chosen pattern below) |

## Decision

### Gateway runtime

The **AI Gateway is TypeScript in `node-backend`** (module under `src/routes/ai.route.ts`, `vision.route.ts`, and follow-on P6 cards). It may later deploy as its own service **without changing the client contract**. Secrets stay server-side (Doppler / GCP Secret Manager per EXT-01). **No provider API keys in the Flutter client.**

**Python** is reserved for **GPU-bound speech and content-inference workers**, not for the gateway control plane:

- `lingafriq-voice-service` (interim STT/TTS HTTP; gateway proxies with auth)
- Curriculum content-engine Python (`tools/content/`, linters, eval harness)
- Future self-hosted pools: Omnilingual ASR, forced aligner, pronunciation scorer, MADLAD — each a **private HTTP/gRPC worker** the gateway calls with service credentials

Reasons for TypeScript at the edge: reuse existing **node-backend** session/JWT middleware, **D21** cost clamps, OpenTelemetry spans (`ai.gateway`), integration tests (`P6-086`, trace tests), and the **OpenAPI → Dart** client generation path. Python workers stay stateless inference; routing, fallbacks, and kill switches live in the gateway.

### Transports (Flutter ↔ platform)

| Surface | Transport | Owner | Modes / examples |
|---|---|---|---|
| Text chat, tutor, translate, grading, structured JSON, vision (SigLIP), content flags | **HTTPS** REST; **SSE** where streaming text is required | `node-backend` gateway | Polie text, Tutor Explain, Translator, Point-and-Say match, `/ai/*` |
| Realtime voice conversation, barge-in, avatar lip-sync pipeline | **WebRTC** via **LiveKit** (app ships `livekit_client`) | Gateway mints/joins sessions; agents on P6-075+ | Polie Conversation, Scenario Roleplay, Live Translate |
| Legacy/binary speech upload, batch STT/TTS, pronunciation score | **HTTPS** to gateway → internal **HTTP** to voice/scorer workers | Gateway authZ; workers private | `/speech/transcribe`, `/speech/synthesize`, `/speech/score` |
| Admin studio AI ops, prompt registry | **HTTPS** to `node-backend` / admin BFF | Staff SSO + 2FA | P4-163, P4-164 |

The app sends **only the user JWT** to the gateway on HTTPS/WSS/LiveKit token exchange — never vendor keys.

### Conformance checks (later P6 cards)

| Check | Where |
|---|---|
| Gateway mode enum and auth | P6-002 |
| Client keys removed | P6-019 |
| LiveKit session minting | P6-075 |
| Intron primary STT | P6-020 (Intron stays **off** until server flag + contract) |

## References

- ELEVATION §7.2:L1367–L1387
- `docs/plan/LINGAFRIQ_AI_MODEL_STACK.md` §9.1
- DECISIONS D21 (gateway cost clamps), D9 / EXT-01

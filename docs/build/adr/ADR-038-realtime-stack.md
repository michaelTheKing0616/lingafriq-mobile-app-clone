charter: v2

# ADR-038 — Realtime messaging transport (P9-900)

Status: **Accepted** (Tope, 2026-10-28). Records EP-§9.5-02 and unblocks P9-903+ realtime hardening cards.

## Context

Elevation §9.5 requires horizontally scaled realtime with room authorisation, versioned event schemas, rate limits, and load-testing to **10k concurrent connections per node** before large launch events. The product also requires **MLS E2EE** for adult 1:1 and small groups (§9.4) while **under-18** messaging stays **non-E2EE** inside guardian-approved circles so moderation can run server-side.

`node-backend` already ships **Socket.IO** with JWT auth, room ACL, moderation hooks, presence, and live-translate namespaces (`socket.service.ts`, `roomAcl.service.ts`, `moderationClient`).

## Options compared

Planning figures below are **[estimate]** for vendor list prices and a 3-node GKE/Compute footprint (not commitments). Concurrent connections (CCU) means simultaneous open socket sessions.

| Option | 10k CCU [estimate] | 100k CCU [estimate] | Data residency | E2EE (MLS) | Minor / moderation hooks |
|---|---|---|---|---|---|
| **Self-hosted Socket.IO + Redis adapter** | ~USD 800–2.5k/mo (3× compute + Redis HA + egress) | ~USD 6–18k/mo (10–15 nodes + Redis cluster + egress) | Full: pin regions (e.g. `africa-south1`, `europe-west1`); Mongo/Redis co-located | **Compatible:** MLS ciphertext is opaque application payload; server routes envelopes only | **Native:** `screenChatText`, room ACL, minor tier blocks, block list — already in tree |
| **Ably** | ~USD 3–8k/mo at published message tiers | ~USD 25–60k/mo+ at scale | EU/US regions; Africa edge not guaranteed | **Poor fit:** hosted channels assume server-readable payloads for their moderation product | Requires parallel moderation pipeline; under-18 non-E2EE still needs our policy layer |
| **Pusher Channels** | ~USD 2–5k/mo | ~USD 20–45k/mo+ | US/EU hosting | **Poor fit:** same as Ably for MLS | Same; no substitute for guardian-circle policy |
| **Stream Chat** | ~USD 4–10k/mo MAU-priced | ~USD 40–120k/mo+ at MAU scale | US/EU | **Rejected for adult E2EE DMs:** Stream is optimised for server-side moderation and search | Strong hosted moderation, but contradicts MLS default for adults and duplicates Village chat model |

Managed vendors win **time-to-first-feature** for a greenfield chat UI; they lose on **unit economics at 100k CCU**, **Africa data-placement control**, and **MLS-first adult messaging** without a custom crypto layer on top of their APIs.

## Decision

**Primary realtime stack:** self-hosted **Socket.IO 4.x** with the **Redis adapter** for pub/sub across API nodes, **sticky sessions** at the load balancer, **presence in Redis with TTL**, **Zod-validated event schemas** (`liveTranslate/protocol.ts` pattern extended to Village/chat), **per-socket rate limits**, and **horizontal scale on GCP** (secrets via **Doppler**).

**Not adopted as primary transport:** Ably, Pusher Channels, Stream Chat. They may be revisited only for a **non-E2EE**, **hosted-moderation** slice if product scope shrinks (see reversal).

**LiveKit** (already used for voice/realtime translation per ADR-007) stays the **WebRTC media plane**; it does not replace Socket.IO for chat, presence, or gamekit matchmaking events.

## Reversal trigger

Re-evaluate managed realtime (Ably first) if **either**:

1. Load tests fail to sustain **10k CCU per node** with p95 delivery under Elevation budgets for **two consecutive release candidates**, or
2. Operational cost of Redis + Socket.IO fleet exceeds **2×** the Ably estimate at the same CCU **and** product scope drops MLS for adult DMs (explicit DECISIONS.md amendment required).

## Consequences

- P9-903 wires Redis adapter + sticky-session documentation in deploy manifests.
- P9-912+ extend Zod schemas for Village events on the same transport.
- E2EE cards (P9 E-P9-E2EE) implement MLS on opaque payloads over this stack; under-18 paths remain plaintext-to-server for moderation.

## References

- ELEVATION.md §9.4 (E2EE / minors), §9.5 (realtime)
- `node-backend/src/services/socket.service.ts`
- P9-900 — `docs/build/cards/P9/P9-900.yaml`

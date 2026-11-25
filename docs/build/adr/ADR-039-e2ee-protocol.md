charter: v2

# ADR-039 — E2EE protocol: MLS versus Signal (P9-937)

Status: **Accepted** (Tope, 2026-10-28). Records EP-§9.3-02; unblocks P9-938–P9-941 delivery and crypto implementation cards.

## Context

ELEVATION §9.3 requires **E2EE for adult 1:1 and small groups**, **server-side ciphertext-only storage**, **per-device cursors**, **data-only pushes** (no plaintext in FCM/APNs for E2EE threads), and **no E2EE for under-18 DMs outside guardian-approved, moderated circles** (already enforced in `messagingPolicy.service.ts`).

ADR-038 chose **Socket.IO + Redis** as the realtime transport with **opaque MLS ciphertext** as application payloads. This ADR fixes the **cryptographic protocol** and **library stack** for Dart (Flutter) and Node.

## Options compared

| Criterion | **MLS (RFC 9420)** | **Signal protocol (libsignal)** |
| --- | --- | --- |
| **Group size (Circles 5–50, village rooms)** | Native group ratchet; one protocol for 1:1 and groups | Strong 1:1; groups historically use sender-key / separate paths; harder to unify with 50-member circles |
| **Multi-device** | Key packages per device; epoch updates on join/leave | Multi-device supported in Signal apps; server assists pre-key bundles; recovery UX vendor-specific |
| **Node library maturity** | `@wireapp/openmls-js` **0.1.0**, **MIT** (OpenMLS WASM); delivery service can alternatively host **OpenMLS Rust** in the voice/crypto worker if JS API gaps block P9-938 | `@privacyresearch/libsignal-protocol-typescript`, **GPL-3.0-only** — copyleft risk for linked mobile + server product |
| **Dart / Flutter maturity** | **`openmls` 3.3.0** on pub.dev, **MIT**, Rust OpenMLS via FFI | `libsignal_protocol_dart` **0.8.2**, pure Dart; no first-party MLS parity |
| **Server cost** | Store **KeyPackages**, **Welcome**, and **MLS ciphertext blobs** only; no per-message server crypto beyond routing; epoch size grows with group membership but bounded at ≤50 for Circles | Similar ciphertext-only storage; pre-key replenishment and session state per 1:1 pair; group sender-key fan-out still server-mediated |
| **Key recovery UX** | **No message-key escrow.** Account recovery = new device keys + optional **user-held backup secret** (export/print) and guardian-assisted re-invite to circles; lost device cannot decrypt old history without backup | Same product constraint; Signal’s “PIN backup” model is **not** copied — LingAfriq uses guardian + optional learner backup artefact documented in P9-941 |
| **Moderation / minors** | Under-18 moderated paths stay **plaintext-to-server** (non-E2EE); adult MLS threads opaque to server | Same split; Signal stack offers no advantage for moderated minor circles |
| **Alignment with ADR-038** | **Direct match** (MLS payloads on Socket.IO) | Would require parallel envelope format or downgrade ADR-038 assumption |

## Decision

**Adopt MLS (RFC 9420) as the sole E2EE protocol** for adult 1:1 and small-group chat (including Circles up to 50 members).

**Chosen libraries and pinned versions (commercial use):**

| Runtime | Library | Version | Licence | Role |
| --- | --- | --- | --- | --- |
| Flutter / Dart | `openmls` | **3.3.0** | MIT | Client encrypt/decrypt, group epoch, device keys |
| Node (delivery service) | `@wireapp/openmls-js` | **0.1.0** | MIT | KeyPackage ingest, Welcome routing, ciphertext persistence API for P9-938 |

**Not adopted:** Signal protocol / libsignal for product E2EE — GPL TypeScript bindings and split 1:1 vs group story conflict with Circles and ADR-038.

**Crypto audit plan:** independent review of MLS integration (key storage, backup flow, and server ciphertext handling) **before G9 pass**, scheduled with the **EXT-17** penetration test window; findings tracked in the same remediation ledger as P9-935.

## Consequences

- P9-938 implements the MLS delivery service (ciphertext + key packages only; secrets via **Doppler**).
- P9-939 enables MLS by default on adult threads; minors remain on existing moderated, non-E2EE policy.
- P9-941 push payloads remain **data-only** (no message body) for MLS threads.
- Learning overlays (Tone Lens, gloss) stay **on-device** on decrypted plaintext; server AI on message text stays **opt-in per message** (§9.3).

## References

- ELEVATION.md §9.3–§9.4
- ADR-038-realtime-stack.md
- `node-backend/src/services/messagingPolicy.service.ts`
- `node-backend/src/guards/messageIdempotency.guard.ts`
- P9-937 — `docs/build/cards/P9/P9-937.yaml`

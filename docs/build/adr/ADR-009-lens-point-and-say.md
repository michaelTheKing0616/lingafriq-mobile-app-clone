charter: v2

# ADR-009 — Lens hub and Point & Say pipeline (P7-900)

Status: **Accepted** (builder default, Tope may override, 2026-10-27). Records EP-§17.6-15 and unblocks P7 Lens build cards.

## Context

Elevation §17.6 names the camera hub **Lens** and keeps **Point & Say** as the object-labeling flow. The app already registers route `point-and-say` → `PointAndSayScreen`. Later cards add on-device MobileNetV4 (P7-945), dictionary mapping (P7-946), optional SigLIP gateway fallback (P7-950, P6-086), and the global Lens sheet (P3-046) with Live Translate and Import Media.

## Decision

### Naming

- **Lens** — learner-facing name for the camera hub and related flows (Point & Say, Live Translate, Import Media, OCR/signs in later cards).
- **Point & Say** — the object-in-frame labeling and speak-back flow; not renamed.

### Pipeline stages (in order)

| Stage | Responsibility | Primary cards |
|---|---|---|
| 1. Capture | Full-screen camera, detection overlays | P7-902 |
| 2. On-device labels | Bundled MobileNetV4 Conv-Small TFLite; top-3 scores; no upload in airplane mode | P7-945 |
| 3. Curated object set | Map ImageNet-style labels to the licensed African object inventory | P7-903 |
| 4. Living dictionary | Lexicon-grounded target word, human audio before TTS (P6-085) | P7-946 |
| 5. Server vision (optional) | SigLIP match via AI gateway only after explicit image opt-in | P7-950, P6-086 |
| 6. Practice & collection | Pronunciation/tone scoring, FSRS collection | P7-908, P7-909 |

ML Kit generic object detection (food/home/fashion/plant/place) is **not** the Point & Say classifier result once P7-945 ships.

### Routes and entry

- **Retained:** named route `point-and-say` and `PointAndSayScreen` (AC5, P7-945).
- **Future global entry:** top-bar camera → Lens sheet with Point & Say, Live Translate, Import Media (P3-046); does not remove `point-and-say`.

### Privacy and gateway

- No photo or embedding leaves the device during stage 2.
- Server vision (stage 5) requires learner opt-in; gateway-only, no client model keys (ADR-007).

## Alternatives considered

| Option | Rejected because |
|---|---|
| Rename route to `lens/point-and-say` | Breaks deep links and existing Drift `point_and_say` queue keys |
| Server-only vision | Fails airplane mode and latency bar (§18.4) |
| ML Kit labels as shipping classifier | AC3 on P7-945 forbids the five-way ML Kit label as the result |

## Consequences

- P7-902+ Lens UI cards use **Lens** in copy keys (`lens.*`); Point & Say remains the mode name inside Lens.
- `docs/build/DECISIONS.md` row **P7-900** must be signed before any P7 Lens **build** card leaves Draft (card AC2).

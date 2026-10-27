charter: v2

# ADR-032 — Avatar economy and identity rules (P11-030)

Status: **Accepted** (Tope, 2026-10-27). Records EP-§4.2-54, ELEVATION §4.4, and aligns with ADR-020 Cowries sinks.

## Context

Learner avatars share the `CharacterVM` rig (ADR-030) with Polie and village hosts. ELEVATION §4.4 requires customisation that reflects **demonstrated skill**, not vanity grinding, and forbids pay-to-look-better pressure on children. ADR-020 already routes **soft-currency** avatar cosmetics through `cosmetic_avatar` Cowries sinks with server inventory keys.

## Decision

### Item classes (what each channel may grant)

| Class | Source | Examples | Spend / unlock rule |
| --- | --- | --- | --- |
| **Mastery (earned)** | Server after verified can-do, tone checkpoint, or quest chapter completion | Region-authentic fila/gele after “Greetings & respect”; “Talking Drum” prop after tone checkpoint; quest badge overlays | **Not** sold for Cowries or fiat; entitlement id is `mastery:<can_do_id>` or `mastery:<quest_reward_id>` |
| **Progression (earned)** | Server streak / competence milestones (P10-901 XP evidence), not raw XP vanity | Pathfinder sash, weekly competence frame | Same as mastery; no reroll or loot-box reveal |
| **Soft cosmetic (Cowries)** | `POST /api/rewards/shop/purchase` → `cosmetic_avatar` sink (ADR-020) | Kente cloak, Adinkra crown (catalog ids in `sinks.service.ts`) | Deduct Cowries server-side; grant `cosmetic:<item_id>` inventory key; **never** grant power or lesson advantage |
| **Fiat cosmetic (adult-only)** | IAP / subscription cosmetic SKUs (future storefront) | Premium outfit palette bundles marked `fiat_cosmetic` | **18+ only** (`purchase-guard.service.ts`); separate inventory namespace `fiat_cosmetic:<sku>`; minors never see purchase CTAs |
| **Default / free** | Onboarding + base rig | Default skin tone palette, starter hair, Polie-adjacent neutral outfit | Always equipped; no paywall |

**Mastery vs cosmetic:** mastery items may change hair, headwear, top, bottom, accessory, or prop slots on `CharacterVM` (§4.3 artboard properties). Cowries and fiat items may only change **cosmetic slots** explicitly tagged `cosmetic_only` in the item manifest; they **cannot** unlock can-do-gated mastery ids.

### What shows mastery (shared surfaces)

- **Profile and Passport:** equipped mastery props and chapter badges render on the learner avatar; Cowries cosmetics are optional overlays.
- **Village chat:** stickers/reactions (§4.4) may use the rig with **learned-phrase** audio; mastery props appear; fiat cosmetics follow the same rules as equipped loadout.
- **Share cards (“I can now say…”)** include the learner avatar, phrase text, and audio; no shop CTA on minor accounts.

### Minors, loot boxes, and entitlements

- **Child and teen bands (D11):** no real-money purchases (`MINOR_PURCHASE_BLOCKED`); no fiat cosmetic SKUs in catalog responses; Cowries **earned in-app** may spend on `cosmetic_avatar` only (ADR-020).
- **No loot boxes, gacha, or random cosmetic drops** — every item has a fixed id, price, and description before purchase.
- **Server-verified entitlements only:** equip/loadout APIs reject client-supplied unlock lists; inventory keys are read from the reward ledger / shop purchase records (`sinks.service.ts`, `RewardLedger.ts`).
- **Cultural items:** region-authentic mastery cosmetics require cultural-consultant sign-off in the item manifest (`cultural_note`, reviewer id) before the mastery id can be granted (EXT-14 gate for publish).

## Consequences

- P11-054+ avatar shop UI must filter SKUs by age band and item class.
- New avatar catalog entries declare `item_class`: `mastery` \| `progression` \| `cosmetic_avatar` \| `fiat_cosmetic`.
- P10-912 monetisation guardrails extend to block fiat cosmetic equip attempts for minors.

## Alternatives considered

- **All cosmetics Cowries-only** — Rejected; ELEVATION §4.4 allows adult-only real-money cosmetics with strict age gates.
- **XP shop for avatar items** — Rejected; conflicts with §4.4 “demonstrated skill” and P10-901 competence evidence rules.

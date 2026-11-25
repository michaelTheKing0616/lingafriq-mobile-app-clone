# CharacterChip artboard spec (32 / 48 / 64 px)

Status: **Accepted** (builder, 2026-10-27). Implements ELEVATION §4.2 L906–L909, §4.3 L919, EP-§4.2-39…46, EP-§4.3-03. Card **P11-039**. Parent rig: `lingafriq_cast.riv` / `lingafriq_cast.contract.json` (`CharacterChip` artboard). Depends on **P11-037** (cast contract); **P11-028** character bibles remain EXT-14/16 gated — chip geometry does not wait on consultant sign-off.

Reference (layout hierarchy only, no asset copy): **Duolingo** league roster chips and **Apple Messages** Memoji stickers at 40–64 pt — large brows, simplified nose, mouth as primary expression carrier.

## Purpose

`CharacterChip` is the list / leaderboard / notification avatar surface. It must remain legible when rasterised at **32**, **48**, and **64** logical px without sharing the full `Character` hair-line detail.

## Canvas and scale

| Field | Value |
| --- | --- |
| Artboard name | `CharacterChip` |
| Design canvas | 128 × 128 px (1:1) |
| Safe circle | 112 px diameter, centred |
| Export display sizes | 32, 48, 64 px (`displaySizes` in contract) |
| Scale to 64 px display | 0.5× from canvas |
| Minimum stroke at 64 px display | **≥ 2 px** → **≥ 4 px** on the 128 canvas |

## Layer stack (chip-only)

Use the contract subset only; do not mount `L1 Body` or full garment outlines on chip.

| Order | Layer | Chip treatment |
| --- | --- | --- |
| Back | `L6 Build` | Flat skin fill + optional single mass shadow (no garment seams) |
| | `L7 Face Shape` | Rounded head; ears as **one** merged shape each (no inner ear lines) |
| | `L2 Face` | **Exaggerated brows** (see below); eyes as filled ovals + 4 px pupil disk |
| | `L4 Blink` | Full-lid blink; no lash hairs |
| | `L5 Mouth` | **Exaggerated mouth** shapes; lip line ≥ 4 px canvas |

Hair, headwear, and outfit on chip: **silhouette masses only** — max **two** closed paths per slot; no individual strands, flyaways, or &lt; 4 px gaps between hair strokes.

## Simplified face (AC1)

- **Brows:** each brow is one thick tapered stroke or filled chevron; vertical separation from eye ≥ 6 px canvas; outer brow extends past eye outer corner by ≥ 4 px.
- **Eyes:** white sclera optional at 64 px; at 32 px export, eyes may be pupil + brow only.
- **Nose:** single soft triangle or omitted entirely at 32 px; if drawn, one fill, no nostril lines.
- **Mouth:** primary emotion signal; width ≥ 40% of face width at canvas; teeth only as a single mid-tone block (no per-tooth lines).

Bind the same `expression` and `activity` enums as full `Character` (ADR-030 / contract); chip states must include at minimum: `neutral`, `happy`, `encouraging`, `thinking`, `concerned`.

## Stroke and hair rules (AC2)

At **64 px display** (0.5× canvas):

- Every intentional outline or lip line ≥ **2 px**.
- Hair: use **helmet / cap / bun mass**; cornrows and braids collapse to parallel **≥ 4 px** canvas bands (see `cultural_design_bible.md` chip notes).
- No decorative lines thinner than 4 px canvas anywhere on chip layers.
- Polie preset on chip: crest and collar read as **two** shapes max; orbit accessory omitted below 48 px display.

## 1-bit silhouette test (AC3)

Procedure (automated in **P11-040** goldens; manual gate until then):

1. Render `CharacterChip` at 32, 48, and 64 px with `expression` ∈ {`neutral`, `happy`, `concerned`} and `activity` = `idle`.
2. Flatten to alpha; threshold to 1-bit (any α &gt; 127 = ink).
3. **Pass** if: (a) ink forms a single connected head+shoulders blob; (b) brow ridge and mouth each contribute a separate horizontal ink band in the middle third of the bbox; (c) pairwise Hamming distance between expression silhouettes at the same size is ≥ 8% of pixels (expressions distinguishable).

Record results in CI via `test/avatars/goldens/chip_golden_test.dart` (P11-040).

## Modular slots on chip

| Property | Chip rule |
| --- | --- |
| `hair` | Mass artboard only; swap allowed |
| `headwear` | Mass only; may replace hair silhouette |
| `top` | Collar / neckline hint only; no sleeves below 48 px |
| `bottom` | Omitted on chip |
| `accessory` | Omitted below 48 px display |

## EXT-16

Final illustrated `.riv` polish may require external Rive artists (**EXT-16**). This spec is binding for in-repo stub geometry and CI contract tests until EXT-16 delivers production art.

## Reviewer checklist

- [ ] AC1 simplified face with exaggerated brows and mouth documented above
- [ ] AC2 minimum stroke table and no thin hair strands
- [ ] AC3 silhouette procedure and expression distinguishability threshold
- [ ] Aligns with `CharacterChip` in `lingafriq_cast.contract.json`

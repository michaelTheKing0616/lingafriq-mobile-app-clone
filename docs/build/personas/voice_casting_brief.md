charter: v2

# Persona voice casting brief (P11-022)

Status: **Accepted** (builder, 2026-10-27). Implements EP-§8.4-01…03 and ties to P11-007 (`personaVoiceSynthesised` / `PersonaSynthVoiceLabel`).

## Policy

1. **One voice per v1 persona** — exactly one primary speaking voice (human actor or interim synthesised pipeline). Shaka’s `narrated_as_told_by` mode uses one **narrator** voice; figure lines in `figure_quote` claims use the same pipeline unless a separate human narrator is contracted later (still one narrator actor slot).
2. **Human recording or clone** — permitted only with signed **voice consent** plus a **buy-out or work-for-hire licence** on file in `docs/build/licence_register.csv` (or linked artefact). Without both, casting status stays `rejected` and no clone training runs (Spitch custom voice, ElevenLabs PVC, or in-house VITS-class — per `LINGAFRIQ_AI_MODEL_STACK.md`, Intron stays off until server-gated).
3. **Synthesised interim (v1 ship)** — ELEVATION §8.4 allows synthesised voices when clearly labelled. All persona audio uses server TTS only (no client keys). UI must show the persistent AI badge (P11-007 AC1–AC2) and **`Synthesised voice`** while audio plays (P11-007 AC3, `lib/l10n/app_en.arb` → `personaVoiceSynthesised`).
4. **EXT-13** — native talent contracts and estate-aligned casting for publish-grade human voices remain **open**; rows below stay `synthesised_interim` until EXT-13 closes and a human `voice_actor` replaces the interim provider name.

## v1 roster casting table (ADR-031)

| `persona_id` | Target language (BCP-47) | Regional accent (casting brief) | v1 `voice_actor` (interim) | TTS route (server, cites EXT-01) | `delivery_mode` | Clone allowed |
| --- | --- | --- | --- | --- | --- | --- |
| `yaa_asantewaa` | `tw` (Asante Twi) | Asante, Kumasi-adjacent; female elder register | **Interim:** server synthesised — Intron Twi (gated) | Intron → fallback per gateway `ttsRouting` when `tw` gated | `first_person` | No until CAST-YAA-01 consent+licence |
| `nkrumah_kwame` | `en` (+ teaching glosses `nzi`) | Ghanaian English; Nzema only in cited glosses, not default TTS | **Interim:** server synthesised — commercial English neural (gateway default EN) | Licensed cloud TTS chain (no MMS/XTTS NC) | `first_person` | No until CAST-NKR-01 consent+licence |
| `shaka_zulu` | `zu` | KwaZulu-Natal isiZulu; narrator is adult historian register | **Interim:** server synthesised — Azure `zu-ZA` (Thando/Themba per P6-054) | Azure `zu-ZA` → Intron Zulu-English when gated | `narrated_as_told_by` | No until CAST-SHA-01 consent+licence |
| `ahmed_baba` | `ar` | West African Arabic scholarly register (Timbuktu context); not MSA-only broadcast | **Interim:** server synthesised — Intron Arabic (gated) | Intron → gateway fallback when `ar` not gated | `first_person` | No until CAST-AHB-01 consent+licence |
| `thomas_mofolo` | `st` | Sesotho literary register; Lesotho/South African Sesotho | **Interim:** server synthesised — Intron Sotho (gated) | Intron → Chirp-class fallback only if listed for Sotho in EXT-01 | `first_person` | No until CAST-MOF-01 consent+licence |

### Human casting slots (post–EXT-13)

When EXT-13 closes, replace the interim `voice_actor` with **one contracted human** per row (same `persona_id`). Required artefacts per slot:

| Slot ID | Persona | Gender/register note (casting only, not performance script) |
| --- | --- | --- |
| CAST-YAA-01 | Yaa Asantewaa | Female; Asante Twi native |
| CAST-NKR-01 | Kwame Nkrumah | Male; Ghanaian English native |
| CAST-SHA-01 | Shaka narrator | Adult; isiZulu KZN native; historian narrator tone |
| CAST-AHB-01 | Ahmed Baba | Male; Arabic suitable for Sahel scholarly portrayal |
| CAST-MOF-01 | Thomas Mofolo | Male; Sesotho native; literary pace |

## Clone / consent checklist (AC2)

| Step | Requirement | On failure |
| --- | --- | --- |
| 1 | Written voice consent (name, date, scope, revoke clause) | **Reject** voice; keep synthesised interim |
| 2 | Licence row in `licence_register.csv` (buy-out or WFH, commercial use, persona scope) | **Reject** clone; no training job |
| 3 | Legal review if estate/figure sensitivity (EXT-15 historian gate for publish) | Block **human** publish; synth interim may still demo with labels |
| 4 | No Coqui XTTS / MMS-TTS NC models for commercial persona clone | Use vendor custom voice or self-trained on **licensed** studio takes only |

## Labelling (AC3 / P11-007)

- **Chat / mission / bust / share:** persistent `AI recreation` badge (non-dismissible).
- **Session start:** how-built preamble before in-character audio.
- **Any synthesised audio:** show `PersonaSynthVoiceLabel` with copy key `personaVoiceSynthesised` for the full clip duration.
- **Dynamic TTS honesty:** persona lines routed through server TTS also carry product-wide dynamic TTS honesty rules (P5-075) in addition to persona synth chip.

## Ledger

| Card | Evidence | Reviewer |
| --- | --- | --- |
| P11-022 | This brief + `test/content/test_voice_casting_brief.py` | Pending T4 |

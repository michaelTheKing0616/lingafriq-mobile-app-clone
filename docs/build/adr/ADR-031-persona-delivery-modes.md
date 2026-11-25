charter: v2

# ADR-031 — Persona delivery modes and v1 roster (P11-001)

Status: **Accepted** (Tope, 2026-10-27). Records EP-§8.3-29…32, decision D14, and unblocks P11-002 onward.

## Decision

### v1 roster (five curated figures)

Confirms D14 (Tope, 2026-10-22). These are the **only** figures that ship as fully authored v1 persona experiences (quest + dossier + evals). Open-ended chat with other figures from the extended registry is unchanged.

| `persona_id` | Display name | Primary target language(s) | `delivery_mode` |
| --- | --- | --- | --- |
| `yaa_asantewaa` | Yaa Asantewaa | Asante Twi (`tw`) | `first_person` |
| `nkrumah_kwame` | Kwame Nkrumah | English, Nzema (`en`, `nzi` teaching notes) | `first_person` |
| `shaka_zulu` | Shaka kaSenzangakhona | isiZulu (`zu`) | `narrated_as_told_by` |
| `ahmed_baba` | Ahmed Baba | Arabic (`ar`) with Songhai context | `first_person` |
| `thomas_mofolo` | Thomas Mofolo | Sesotho (`st`) | `first_person` |

**Mode rationale (summary):**

- **Yaa Asantewaa, Nkrumah, Ahmed Baba, Mofolo** — ELEVATION §8.2 “sit with history” quests are authored in-character; first-person speech matches the answer contract and classroom debrief flow.
- **Shaka** — §8.3 requires age-appropriate treatment of violence and avoids glorification of military campaigns. A named historian-narrator frame (`narrated_as_told_by`) keeps the learner in dialogue with history without first-person combat endorsement. Native and historian review (EXT-15) still gates publish.

### Living-memory policy (not in v1 roster)

Figures such as **Nelson Mandela**, **Thomas Sankara**, and **Patrice Lumumba** may appear in the extended registry but **must not** use `first_person` until `docs/build/external/EXT-15-estate-guidance.json` records family or estate guidance per figure. Until then, only `narrated_as_told_by` is allowed, with the narrator labelled in UI and prompts.

### Narrated-mode answer contract (server validation spec)

Implemented in **P11-003** (`validatePersonaAnswerContract`). Until then, CI may run the fixture checks in `test/content/test_adr_031.py`.

When `delivery_mode === narrated_as_told_by`:

1. **`speech_text`** — Must not use first-person self-reference for the historical figure (regex bundle below). The narrator may use “I” only when clearly the modern narrator, not the figure.
2. **`narrator_label`** — Required non-empty string on every turn (e.g. “A Zulu historian tells this story”).
3. **`claims[]`** — Each claim includes `perspective`: `documented` \| `inferred` \| `legend` (existing contract) **and** `voice`: `narrator` \| `figure_quote`. Figure speech in narrated mode must use `voice: figure_quote` and be wrapped in quotation or attribution in `speech_text`.
4. **UI** — Persistent “AI recreation” disclosure (P1-026) plus visible narrator chip when mode is narrated.

**First-person forbidden patterns** (case-insensitive, applied to `speech_text` when mode is narrated; extend per language in P11-003):

```text
\b(I|me|my|mine|we|us|our|ours)\b
```

(English baseline; Twi/Zulu/Arabic/Sesotho first-person morphemes are added in the persona schema card, not invented here.)

When `delivery_mode === first_person`, the narrator fields are omitted and the figure may use first-person within the knowledge horizon (§8.3).

## Consequences

- Persona dossiers (P11-010…014) declare `delivery_mode` from this table.
- P11-005 UI chips distinguish documented vs inferred claims; narrated mode adds narrator labelling.
- Historian review (EXT-15) remains **Blocked-External** for publish gates; this ADR does not waive EXT-15.

## Alternatives considered

- **All five first-person** — Rejected for Shaka given §8.3 sensitivity rules and existing safety blocklist history (ELEVATION §8.1).
- **All five narrated** — Rejected; it weakens the authored quest design in §8.2 for Yaa Asantewaa and scholars where first-person pedagogy is the product goal.

# RTM extraction brief (charter: v2)

Token charter: do only what this brief asks; read only the assigned line range (Read with offset/limit); no narration; output is the CSV file plus a ≤5-line report.

## Task
Read the assigned line range of one source file once and write one CSV of atomic requirements.

## Output file
`docs/build/rtm_parts/<part>.csv` with header exactly:
`req_id,source_doc,anchor,type,verbatim_hook,priority,owner,card_ids,status`

## Row rules
- One row per atomic, checkable obligation. A table → one row per table row. A numbered or bulleted list → one row per item; a sub-bullet with its own obligation → its own row. A number or target (ms, %, KB, fps, count) → its own `metric` row.
- `req_id`: `<PREFIX>-§<subsection>-<nn>` (nn = 01.. within that subsection), e.g. `EP-§3.4-07`, `CP-§3.3-02`. Use the named schemes when the brief for your chunk says so (e.g. `AV-step1`, `OB-step3`, `REV-01`, `RM-P1-04`).
- `source_doc`: `ELEVATION` or `CURRICULUM`.
- `anchor`: `§<subsection>:L<line>` or `§<subsection>:L<from>-L<to>` using the file's line numbers.
- `type`: one of `requirement|constraint|metric|decision|risk|external|informational`. Use `external` when a human, vendor, licence, purchase or legal sign-off is needed. Use `informational` for audit findings that only describe current state (keep them; they anchor defects).
- `verbatim_hook`: ≤12 words copied from the source line (truncate, never paraphrase). Quote the field if it contains a comma.
- `priority`: `P0` only for §1 / §16.1 material; `P1` for §16.2 and anything the text calls P1 or "first"; `P2` for §16.3; `MS` for moonshots; default `P1`.
- `owner`: `agent` (buildable by the pipeline), `Tope` (a decision), `external` (human/vendor/legal).
- `card_ids`: leave empty. `status`: `Open`.
- Skip items already captured mechanically: the §1 P0-n table, the §18.2–18.7 feature deep-dives (F-nnn) and standalone `[verify]/[purchase]/[quote]/[Unverified]/[estimate]` tags (keep the requirement they sit in; do not create a second "verify" row).
- Where the text names a vendor/model (Gemini 3.1 Pro, GPT-5 class, Intron, Spitch, Azure zu-ZA, MADLAD-400, ZulMorph, NaijaML…), keep the name in the hook. Never substitute.
- Where the text cites a companion doc (`LINGAFRIQ_AI_MODEL_STACK.md`, `LINGAFRIQ_ELEVATION_PLAN.md`), add a row of type `external` with hook starting `companion:`.

## Report (≤5 lines)
File path · row count · counts by type · up to 3 ambiguities (line number + ≤10 words each). Nothing else.

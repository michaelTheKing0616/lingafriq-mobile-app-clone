# Copy rules (P10-940)

Aligned with ELEVATION §15 (warm UI copy) and Playbook §9 / §15.4.

## Error messages (`app_en.arb`)

Every learner-facing error string must use **three short sentences**:

1. **What happened** — plain outcome (`Couldn't score…`, `Connection lost`, `Microphone is blocked`).
2. **Why** — specific cause (too quiet, network dropped, permission denied).
3. **What next** — one action (`Try again closer to the mic`, `Tap Reconnect`, `Open Settings and allow the microphone`).

Placeholders such as `{error}` are allowed; the checker normalizes them when counting sentences.

CI: `python3 scripts/copy/error_copy_check.py`

## Village voice scope

- **System UI** (tabs, buttons, labels, errors, toasts): clear, warm **product** English. No folktale register.
- **Character dialogue** (Polie in-character lines, persona speech): village voice is allowed **only** when the ARB entry sets `"voice": "character"` or the key prefix is `character_dialogue_` / `persona_dialogue_`.

Markers blocked outside character scope are listed in `scripts/copy/village_voice_markers.txt`.

## Related gates

- P10-938: em dash, banned hype words, verb-first buttons (`lint_ui_strings.py`).
- P10-939: grade-7 readability and Publish → Published continuity (`readability_gate.py`, `name_continuity.py`).

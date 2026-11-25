# lingafriq_cast.riv — version log

Single runtime source: `assets/rive/lingafriq_cast.riv`. Do not commit a second copy under `avatars/`.

## Pinned export (CI gate)

```riv-pin
source_riv: assets/rive/lingafriq_cast.riv
rive_editor: Rive CLI 1.6
export_format_major: 7
export_format_minor: 3
content_sha256: 3dbd8434e7b4c4744cf996190e2b088eb22d235858c82061264675d8e9be75f6
content_bytes: 298228
```

## Changelog

### 2026-10-27 — cast v3.2 (P11-036)

- **Rive editor:** Rive CLI 1.6 (see `assets/rive/lingafriq/RIVE_BUILD_SPEC.md` §1).
- **Export format:** 7.3 (binary header after `RIVE` magic).
- **Notes:** Initial version-controlled pin for `lingafriq_cast.riv`; CI runs `scripts/avatars/check_riv_version.py --gate`.

### 2026-10-27 — Polie state transitions verified (P11-041)

- **Notes:** Activity enum + legacy triggers on `CastSession`; idle blink/gaze bindings; `maxTransitionMs` 300; hallway record at 64 px (`state_transition_test.dart`).

### 2026-10-27 — Polie rig integration verified (P11-037)

- **Notes:** `Character`, `CharacterChip`, and `Bust` artboards; `CharacterSM` layers L1–L5; Polie preset with crest/suit/hover/orbit parts; contract + `test_p11_037_polie_cast_integration.py` + `contract_test.dart` gate.

charter: v2

# ADR-030 — CharacterVM production contract (P11-029)

Status: **Accepted** (Tope, 2026-10-27). Resolves CONFLICTS C5 and supersedes legacy avatar expression specs.

## Decision

### Production `expression` enum (CharacterVM face)

Union of ELEVATION §4.3 L880 and L930 expression lists:

`neutral`, `happy`, `proud`, `curious`, `concerned`, `surprised`, `thinking`, `encouraging`, `playful`, `focused`

Persona answer contract field `emotion` (P11-003) must be one of these values. Legacy free-text `emotion_tone` strings map to this enum at validation time (`calm` → `neutral`); unmapped values fail closed.

### Numeric and gaze contract (§4.3)

Supersedes README 0–5 scales, plan 0–100 emotion sliders, and engine `mouthOpenness` / `lipRounding` inputs.

| Property | Type | Range |
| --- | --- | --- |
| `expression` | enum above | — |
| `intensity` | number | 0..1 (default 0.6 when omitted) |
| `gazeX`, `gazeY` | number | −1..1 |
| `activity` | enum | `idle`, `speaking`, `listening`, `thinking` (per §4.3) |

Rive **data-binding View Model** (`CharacterVM`) is the only runtime contract. No new State Machine Input (SMI) wiring.

## Consequences

- P11-003 validates persona `emotion` against this enum.
- P11-035 codegen emits Dart types from this ADR.
- Deprecated state-machine avatar drivers remain read-only until AvatarDirector (P11-049).

## Alternatives considered

- **Smaller enum (L880 only)** — Rejected; drops `playful` and `focused` used in chip and lesson flows.
- **Keep 0–100 sliders** — Rejected; inconsistent with Rive VM bindings.

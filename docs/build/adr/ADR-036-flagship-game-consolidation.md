charter: v2

# ADR-036 — Play hub flagship consolidation (six pairs → ten headliners) (P8-916)

Status: **Accepted** (Tope, 2026-10-27). Implements ELEVATION §10.3 L1769–L1772 and P8-918 headliner registry.

## Context

The Arcade ships **ten flagship games** (P8-918 `kArcadeHeadlinerOrder`) while **37+ legacy mini-games** remain on skill shelves. Six legacy pairs must merge mechanics into flagships without dropping features (No-Cut).

## Decision

| Flagship card | Legacy harvest sources | No-Cut |
| --- | --- | --- |
| **P8-920** Talking Drum | `lib/screens/games/cultural/drum_word_game.dart` (drum→word perception), `lib/games/drum_rhythm/*` (rhythm shadow patterns) | Rhythm typing, word-choice perception, production contour compare |
| **P8-922** Market Haggle | `lib/screens/games/market_bargaining_screen.dart` | Bargaining turns, voice roleplay |
| **P8-923** Danfo / Matatu Rush | `lib/screens/games/taxi_survival_screen.dart` | Listening survival rounds |
| **P8-924** Proverb Weaver | `lib/games/proverb_unlocker/*`, `lib/screens/games/cultural/proverb_unlocker_game.dart` | Unlock + weave mechanics |
| **P8-928** Greeting Gauntlet | `lib/screens/games/greeting_diplomacy_screen.dart` | Register-aware greeting chains |
| **P8-929** Echo Karaoke | `lib/screens/games/pronunciation_karaoke_screen.dart` | Karaoke pitch line + shadowing |

Until a flagship card is **Done** and passes parity review, the legacy game **stays tappable** on its skill shelf (`AllGamesRegistry` listings). Headliner tiles show **Coming soon** until the elevation card id is listed in `kArcadeHeadlinerShippedElevationCards`.

## Consequences

- P8-920 implements the Talking Drum flagship (`lib/games/talking_drum/*`) and routes legacy Drum Word entry through it.
- Remaining flagship cards (P8-922–P8-929) follow the same harvest + shelf coexistence pattern.
- GameKit speaking turns continue to use **E-P6-SCORER** only (no client model keys).

## Alternatives considered

- **Delete legacy games when flagship ships** — Rejected; violates No-Cut and P8-917 shelf coverage until parity sign-off.

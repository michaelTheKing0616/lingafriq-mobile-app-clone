# Production Reliability Audit Matrix (Mobile)

This matrix tracks **user-visible features** end-to-end (UI → provider/service → API route), with a bias toward **production correctness**:
- No TODO/stub/“mock” fallbacks that fabricate data
- Clear auth requirements
- Offline-first where appropriate (queue + sync / curated local content)

## Legend
- **Verified (code)**: Frontend call sites + backend route/controller exist and align
- **Resilient**: Has local fallback or safe empty-state (no fabricated data)
- **Needs runtime verification**: Requires live backend + valid credentials/device capabilities

---

## Core flows

| Feature | Frontend entry | Backend | Auth | Offline/fallback | Status |
|---|---|---|---|---|---|
| Onboarding + Placement test | `lib/screens/onboarding/*` | `GET /api/onboarding/placement-test/generate` | Public (rate-limited) | Pads to minimum local bank | **Verified (code)** |
| Post-onboarding routing | `enhanced_onboarding_flow_screen.dart` | N/A | N/A | Routes to Login if unauth | **Verified (code)** |
| Login / Signup | `lib/screens/auth/world_class_*` + `auth_provider.dart` | `POST /auth/jwt/create/`, `POST /auth/jwt/refresh/`, `POST /accounts/auth/users/` | Public | Safe errors | **Verified (code)** |

## AI / Tutor

| Feature | Frontend entry | Backend | Auth | Offline/fallback | Status |
|---|---|---|---|---|---|
| AI Assistant chat (history) | `api_provider.dart` | `POST /api/ai/chat/history/sync/`, `GET /api/ai/chat/history/:mode` | Yes | Sync queue | **Verified (code)** |
| Tutor: Translate | `tutor_translation_mode_screen.dart` | optional | optional | Hybrid orchestrator | **Resilient** |
| Tutor: Grammar | `tutor_grammar_mode_screen.dart` | optional | optional | Groq fallback | **Resilient** |
| Tutor: Story / Dialogue / Assess | `lib/screens/tutor/*` | optional | optional | Groq fallback | **Resilient** |
| Tutor: Pronunciation | `tutor_pronunciation_mode_screen.dart` | `POST /api/pronunciation/advanced/analyze` | Yes | Groq fallback | **Needs runtime verification** |

## Games / SRS / Telemetry

| Feature | Frontend entry | Backend | Auth | Offline/fallback | Status |
|---|---|---|---|---|---|
| Game sessions sync | `api_provider.dart` | `POST /api/games/session/start/` | Yes | Sync queue | **Verified (code)** |
| SRS sync | `api_provider.dart` | `PUT /api/games/srs/user/:userId` | Yes | Local SRS persisted | **Verified (code)** |
| Game telemetry | `api_provider.dart` | `POST /api/games/telemetry/` | Yes | Batched client-side | **Verified (code)** |
| Language games catalog | `games_screen_material3.dart` | N/A | N/A | Always routable; in-game error states | **Verified (code)** |
| Phrase cards content | `game_provider.dart` | Polie content endpoints | optional | Curated fallback phrase bank | **Resilient** |

## Social / Community

| Feature | Frontend entry | Backend | Auth | Offline/fallback | Status |
|---|---|---|---|---|---|
| Private chat entry | App drawer | Chat routes | Yes | N/A | **Needs runtime verification** |
| Social audio | `social_audio/*` | `/api/social-audio/*` | Yes | Safe empty-state | **Needs runtime verification** |
| Ancestry graph | `screens/social/ancestral_tree_screen.dart` | `GET /api/ancestry/me` | Yes | No mock; empty-state | **Verified (code)** |

## Content / Media

| Feature | Frontend entry | Backend | Auth | Offline/fallback | Status |
|---|---|---|---|---|---|
| Culture magazine | `culture_magazine_screen_enhanced.dart` | `GET /api/culture/articles?published=true` | Optional | Robust parsing + empty-state | **Verified (code)** |
| Import media + Transcribe | `import_media_screen_enhanced.dart` | `/api/media/*` | Yes | Validated language dropdown | **Needs runtime verification** |

## UX integrity (anti-placeholder)

| Area | Fix | Status |
|---|---|---|
| Hardcoded “stats” | Dashboard/Profile now use `gamificationProvider` values | **Done** |
| Mock/fabricated leaderboards | Removed fabricated entries; rely on cache/real API | **Done** |
| Mock ancestry tree | Uses `/api/ancestry/me`; no fabricated data | **Done** |
| Disabled/empty tap handlers | Removed `onTap: () {}` stubs; wired real navigation/actions | **Done** |
| “SOON” game badges + TODO template | Removed | **Done** |

---

## Next runtime checks (recommended)
These are the remaining items that can’t be fully proven by static code inspection alone:
- Auth token acquisition + refresh behavior (login/signup + token persistence)
- Media upload/transcription end-to-end (requires backend + storage)
- Social audio room creation/join (requires backend + LiveKit credentials)
- Pronunciation analyze endpoint (requires mic permission + backend model)


# Comprehensive TODO — LingAfriq Production Readiness

All tasks from backend/mobile fixes, Live Classroom, and app translation. Check off only when **fully** done.

---

## ✅ COMPLETED

- [x] **Duplicate onboarding saves** — Mobile: idempotent POST (flag `onboarding_backend_sync_done`). Backend: `POST /onboarding/complete` in onboarding.controller + route; single upsert per user.
- [x] **Groq 400 / HF 410 and template fallback** — Backend: log status + errorBody on Groq non-200 and on HF 410; template fallback already returns `{ content: string }`.
- [x] **Yorùbá → language-code mapping (hybrid-polie)** — Backend: added kiswahili, isizulu, isixhosa, yorùbá to Google + NLLB maps in hybrid-polie.controller.
- [x] **Mobile: parse template fallback for Grammar/Dialogue/Stories** — ai_chat_screen_new: _extractResponseFromMode + _buildModeSpecificContent parse JSON content for grammar/explain, story, dialogue; top-level _tryParseJsonContent.
- [x] **App drawer bug when language = Yoruba** — Use Scaffold.maybeOf(context)?.openDrawer() and Directionality LTR on tabs scaffold.

---

## 🔲 PENDING / IN PROGRESS

- [x] **Fix Biometric feature** — Added try/catch and user feedback in settings when enabling biometric; BiometricAuth already handles errors and returns false.
- [x] **App language Yoruba: automatic app content translation** — Added `AppStrings.tr(key)` and `app_strings.dart` with en/yo/fr/sw for drawer, bottom nav, settings, Live Classroom labels; drawer and nav use AppStrings so changing app language shows translated UI.
- [x] **Live Classroom UI: world-class redesign** — Minimal header with LIVE pill + room name; Teacher badge when role is admin/officer; glassmorphism floating action bar (blur + dark); Video/Audio/Leave controls; Pan-African colors; participants dialog and whiteboard toggle kept.
- [x] **Live Classroom: use token role + canPublish** — Token response parsed for `role` and `canPublish`; listeners (canPublish: false) have mic disabled and cannot enable; Teacher badge shown for admin/officer.
- [ ] **CEFR 500** — Redeploy backend with build that has correct `../models/learnerProgress.model.js` in dist/routes/sync.route.js (user/deploy step).
- [ ] **Phase 2 Live Classroom** — Hand raise, promote/demote, per blueprint doc (later).

---

## Reference

- Backend AI completion: `node-backend-main/src/controllers/aiCompletion.controller.ts`, `aiServiceFallback.ts`
- Backend onboarding: `onboarding.controller.ts` (completeOnboarding), `onboarding.route.ts` (/complete)
- Mobile onboarding: `enhanced_onboarding_flow_screen.dart` (_completeOnboarding)
- Mobile AI chat: `ai_chat_screen_new.dart` (_extractResponseFromMode, _buildModeSpecificContent)
- Live Classroom: `live_classroom_screen_material3.dart`; token: `api/chat/classroom/:roomId/token` returns role, canPublish
- App locale: `DynamicLocalizationService`; no ARB/translations yet → need string lookup for app content translation

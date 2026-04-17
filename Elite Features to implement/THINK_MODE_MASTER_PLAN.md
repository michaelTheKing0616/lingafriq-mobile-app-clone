# Think Mode — Master Plan (LingAfriq Mobile)

**Status:** **Elite production program in progress** — implement **all 241+ Flutter screen files** (and accompanying **Node/backend** APIs) until **live readiness** is met. Work may span many sessions; chunk by epic, merge focused PRs.  
**Scope:** Full app surface + backend parity: lessons, paths, quizzes, games hub, lexicon pipeline, AI/Polie, villages, chat, classroom, feed, settings, onboarding, and **mockup HTML parity** where product requires it.  
**Canonical mockups:** `mobile-app-main/Elite Features to implement/` (see §2).  
**Curated game lexicon seed:** `african_language_game_database.xlsx` (see **§5 Epic B.3**).

---

## 0. Elite program — all screens + production readiness

### 0.1 Inventory

| Surface | Count (approx.) | Notes |
|--------|------------------|--------|
| `lib/**/_screen*.dart` and related | **241+** | Primary deliverable: each route reachable, non-dead CTAs, real or honest empty/error states. |
| Mockup HTML (`stitch_private_chat/.../code.html`) | **~88** | Epic vertical slices; not all need 1:1 pixels if Flutter equivalent meets UX contract. |
| Backend (`node-backend`) | All routes used by screens | Auth, lessons, games, lexicon, chat, WA, learning sync — **contract-tested** where feasible. |

**Screen → route → API matrix (required):** Maintain a spreadsheet or markdown table: `screen_id` → Flutter route/widget → API endpoints → owner → P0/P1/P2/P3. Update as screens ship.

### 0.2 Live readiness checklist (must pass for “done”)

1. **Navigation:** Primary and secondary CTAs navigate; back stack sensible; deep links documented.
2. **Data:** Loading / **error** / **empty** states are explicit; no infinite spinners; retry paths exist.
3. **Auth & permissions:** Guest vs signed-in behavior defined; no silent failure on 401/403.
4. **Offline / flaky network:** User-visible messaging; queue/retry where product promises it.
5. **Observability:** Critical paths log structured breadcrumbs (no secrets); crashes actionable.
6. **Tests:** Non-trivial logic has unit/widget tests; **regression** for lesson completion and quiz exit (see §0.4).
7. **CI:** Repository CI runs analyze/tests on push; **local** `flutter analyze` optional during heavy multi-file work — rely on CI before release (team policy).

### 0.3 Honest status — do not mark “green” without qualification

| Item | Previous risk | Current direction |
|------|----------------|-------------------|
| **P2 Games empty state** | Empty UI existed on **legacy** `GamesScreen` only; **primary** route used `GamesScreenMaterial3` with a **hardcoded** language list. | **Addressed in app:** `GamesScreenMaterial3` now uses **`languagesForGamesProvider`** (API), loading/error/empty parity with legacy, bundled **game_content** awareness when word count is 0. Further: merge or dedupe the two hubs if product wants one code path. |
| **P1 Adaptive / Literal** | Toggle in `TutorTranslationModeScreen` did not change orchestrator/Groq behavior. | **Addressed in app:** `translationStyle` passed into `HybridPolieOrchestrator.orchestrate` (metadata) and **Groq fallback** prompts (literal vs natural). NLLB paths remain style-agnostic; metadata records intent. |
| **P2 Lexicon Excel pipeline** | Only Dart models + empty repository — **not** complete per spec. | **Still open:** xlsx inventory, idempotent import, staging/promote, admin/CI. **Landed this sprint:** Node `GET /api/lexicon/search`, `GET /api/lexicon/:lemma`, `POST /api/lexicon` (draft, auth), Mongo model + demo seed; Flutter `LexiconRepository` + `AfricanLexiconEntry` JSON mapping + `lexiconRepositoryProvider`. |
| **P2 Lexicon expansion funnel** | No LLM batch job, review queue, unified backend API — stub only. | **Partially addressed:** read/search + draft create path; **still open:** LLM batch job, curator review queue UI, Excel import script per §5 B.3.3–B.3.4. |
| **P3 Mockup slices** | Only a small Polie CTA on `VillagesHubScreen`; epic HTML sweep not done. | **Barely started** — treat P3 as multi-sprint; cluster by village / chat / classroom (§6). |
| **take_quiz_screen.dart** | Not unified with `LessonFlowScreen` completion auditing. | **Code-reviewed:** `QuizScreen` / `CorrectionScreen` use `isTakeQuiz` branches that `Navigator.pop(true/false)`; single- and multi-question paths award/mark complete appropriately. |
| **LessonFlowNotifier last section** | Regressions possible without tests. | **UI contract tests** in `lesson_completion_state_test.dart`; **full notifier + mocked `markAsComplete`** integration test still optional. |

### 0.4 Recommended improvements (quality bar)

1. **Games:** Keep **one** canonical games entry (Material 3 + API) or document why two screens remain.
2. **Translation:** Optionally thread `translationStyle` into backend translate API when supported (cache keys).
3. **Lexicon:** Wire games/Polie features to `lexiconRepositoryProvider`; finish admin Excel import + promotion workflow.
4. **Mockups:** Per-screen checklist (app bar, spacing, typography) vs `code.html`; optional screenshot diff for hero flows.

---

## 1. Purpose & how to use this document

This is the **single planning artifact** for the workstream described in product review. Implementation should proceed **phase by phase**; do not merge unrelated epics in one PR.

**Definition of done (global):**

- No dead primary CTAs (buttons navigate and perform documented actions).
- Loading / error / empty states are explicit.
- CI green for touched packages (`flutter analyze` / tests as configured); add tests where logic is non-trivial.

---

## 2. Mockup & design sources (inventory)

| Location | Contents |
|----------|----------|
| `Elite Features to implement/DESIGN.md` | High-level design notes |
| `Elite Features to implement/stitch_private_chat/stitch_private_chat/` | **~88** `code.html` screens (dashboard, village, chat, classroom, learning path, games-adjacent, etc.) |
| `Elite Features to implement/stitch_private_chat/stitch_private_chat/ubuntu_pulse/DESIGN.md` | Subsystem notes |

**Deliverable before pixel-pass:** Spreadsheet or table: `screen_id → Flutter route (existing/new) → API → owner epic → P0/P1/P2`.

---

## 3. Architecture principles

1. **Single source of truth (SSOT) for “Lessons hub”**  
   The flow with **Africa map**, links to **Lessons**, **Mannerisms**, **History**, and **Take Quiz** must be the **only** canonical entry. All dashboard / deep links / tabs must call one navigation helper (e.g. `LessonHubRoute.open(...)`) so behavior cannot drift.

2. **Data-driven learning path**  
   Path nodes must come from **curriculum/API + progress**, not hardcoded demo lists.

3. **Explicit lesson completion state**  
   Completion UI must not rely on index math that the state machine never reaches (see §4.3).

4. **Translation languages ≠ app UI language**  
   Use a dedicated `TranslationLanguageOption` (BCP-47 + names) for Polie Translation mode; do not overload `AppLanguage` (used for app locale).

5. **Mockup fidelity = UI + behavior**  
   A screen is “done” only when it matches the mockup **and** implements navigation, data, and failure modes.

---

## 4. Epic A — Lessons

### A.1 SSOT routing

**Problem:** “Lessons” links are inconsistent; hub is only clearly reachable from **Courses** tab.

**Work:**

1. Identify the exact widget that implements the **Africa map hub** (candidates: `language_detail_screen`, `swahili_village_map_screen`, or composed flow).
2. Grep for navigations to `LessonsListScreen`, `LearningPathScreen`, `LessonFlowScreen`, and string literals `"Lessons"`.
3. Centralize entry through SSOT; document in one line in this file’s changelog when done.

**Acceptance:** From Dashboard, Courses, and any other entry point, “Lessons” leads to the **same** hub and consistent back stack.

### A.2 Learning path — nodes not opening lessons

**Root cause (verified in code):** `LearningPathScreen` uses a **hardcoded** `_lessons` list; `GestureDetector.onTap` for unlocked nodes only triggers **haptics** — no `Navigator.push` to `LessonFlowScreen`.

**Work:**

1. Fetch or derive lesson nodes for the current language (same source as `section_lessons_list` / lesson detail APIs).
2. Map node states: locked / active / completed from user progress.
3. `onTap` → navigate with `lessonId`, `sectionLessons`, `lessonTitle` as required by `LessonFlowScreen`.

**Acceptance:** Tapping an unlocked node opens the real lesson flow; locked nodes show rationale (snackbar / tooltip).

### A.3 Quizzes never “finish”

**Root cause (verified in code):** `LessonFlowScreen` completion uses:

`allCompleted && currentSectionIndex >= sections.length`

But `nextSection()` only increments while `hasMoreSections` (`currentSectionIndex < sections.length - 1`). On the **last** section, `nextSection()` is a no-op, so `currentSectionIndex` may **never** reach `sections.length`, and the completion screen may never show.

**Work:**

1. On successful `completeSection` for the **final** section, either:
   - set `currentSectionIndex` to `sections.length`, **or**
   - add `lessonFinished: true` to state, **or**
   - push `LessonRecapScreen` / completion route directly.
2. Add unit tests for: single-section lesson, multi-section, last section = quiz.
3. Verify standalone **Take Quiz** flow (`take_quiz_screen.dart`) if users hit the bug there too.

**Acceptance:** After the last question of the last quiz, user sees completion/recap and can exit cleanly.

---

## 5. Epic B — Games

### B.1 Empty or trivial content

**Problem:** Some languages have no or minimal game content; UX feels broken.

**Work:**

1. Backend audit: game-content endpoints, per-language keys, admin seeding.
2. Client: `game_router` / per-game screens — **empty state** (copy + illustration + suggest switch language or browse courses).
3. Product: minimum content tier per language (define N items per game type) + seeding pipeline alignment with ops (`TTS_SCRAPER_SEEDING_FULL_OPS` style discipline).

**Acceptance:** No silent blank games; user always understands why content is missing and what to do next.

### B.2 Games “don’t make sense”

**Work:** Short design pass per game type: objective, rules, feedback, XP. Align copy with curriculum team if available.

### B.3 African language word repository (Excel seed + scalable amassing)

**Goal:** A **single, queryable lexicon** powers **all** games (matching pairs, pronunciation, quizzes, Polie-assisted vocab modes, etc.), with clear **provenance** and **quality tiers**—not one-off spreadsheets per feature.

#### B.3.1 Use of `african_language_game_database.xlsx`

**Location:** [Elite Features to implement/african_language_game_database.xlsx](african_language_game_database.xlsx) (authoritative curated seed; keep under version control or export **CSV** alongside for readable diffs in PRs).

**Intelligent use (not a one-shot import):**

1. **Schema discovery (first task):** Document sheets, column headers, language identifiers, and duplicates. Map columns to a **canonical schema** (below). If multiple sheets exist, define merge rules.
2. **Normalization pipeline:** Import script (Node or Python in `node-backend` / `scripts/`) reads xlsx → validates → outputs **idempotent** JSON or SQL seed → **staging** table → promote to production after validation counts.
3. **Deduping:** Unicode NFC normalization; language-specific casing where safe; reject or merge rows with same `(language_id, lemma_normalized)`.
4. **Tagging:** Set `source_tier = curated_excel` and `source_ref` (sheet/row) for traceability.

#### B.3.2 Canonical lexicon record (conceptual)

| Field | Purpose |
|-------|---------|
| `id` | Stable UUID |
| `language` | ISO 639-3 or BCP-47 (align with app + backend) |
| `lemma` | Surface form in target language |
| `gloss_en` (and optional `gloss_fr`, …) | Meaning for games / hints |
| `pos` | noun, verb, … (optional) |
| `difficulty` | e.g. A1–C2 or 1–5 |
| `tags` | topic: food, family, … |
| `source_tier` | `curated_excel` \| `llm_suggested` \| `scrape_licensed` \| `community_pending` |
| `license` / `attribution` | Required for scraped/third-party data |
| `review_status` | `draft` \| `approved` \| `rejected` |

Games and Polie **only consume `approved`** rows for production, unless in dev/staging.

#### B.3.3 Other means to amass a very large corpus (multi-source funnel)

Use a **funnel + review**, not raw LLM output in production without a tier:

1. **LLM-assisted expansion (Groq / existing stack):** Batch jobs: “Given approved seed words and topic X, propose N **new** lemmas + English glosses in JSON schema.” Outputs go to **`llm_suggested` + `draft`**; **human or trusted reviewer** promotes to `approved`. Keeps orthography mistakes out of live games.
2. **Backend scraping / existing pipelines:** Reuse or extend **node-backend** scrapers (with `TTS_SCRAPER_SEEDING_FULL_OPS`-style discipline): rate limits, robots/license checks, store `source_url` + `license`.
3. **Wiktionary / open dictionaries:** Only where license permits; batch import with attribution field populated.
4. **Community UGC:** “Suggest a word” flows → moderation queue → same schema.
5. **Polie AI consumption:** Polie does **not** invent the canonical list alone; it may **select**, **explain**, or **drill** words drawn from the lexicon API; free-form chat can still suggest words but they should be **labeled** as non-curated unless cross-checked.

#### B.3.4 API and client behavior

- **Backend:** e.g. `GET /api/lexicon/sample?language=&gameType=&count=&difficulty=` returning approved entries; optional `POST` for admin seed/import.
- **Mobile:** game routers call **one** `LexiconService` / repository; **cache** per language; **fallback copy** when count &lt; threshold (already planned in B.1).
- **CI:** Optional job: “import xlsx → validate min N words per language for tier-1 languages.”

**Acceptance:** Excel seed is imported without duplication; at least one game type reads from the shared API; expansion path is documented with review gate; Polie modes that need vocab pull from the same store.

---

## 6. Epic C — AI Chat mode & mockup screens

### C.1 Dummy UI / broken CTAs (e.g. “Enter the Village”)

**Work:**

1. Trace AI Chat entry (`PolieModeSelectionScreen`, village-related screens).
2. Wire primary CTAs to `VillageNavigation` / real routes (`language_villages_screen`, `villages_hub_screen`, etc.).
3. Replace placeholder lists with providers + API or explicit empty states.

### C.2 “All screens in mockup folders”

**Scope control:** ~88 HTML screens — implement as **epic vertical slices**, not one mega-PR.

**Suggested epic clusters:**

| Cluster | Mockup examples | Notes |
|---------|-----------------|-------|
| Village / hub | `language_village`, `villages_hub`, `swahili_village_map`, `village_market`, `village_caf`, `elder_s_hut` | Tie to `VillageNavigation` |
| Chat | `private_chat`, `global_chat`, `chat_inbox`, `call_history` | Verify send/receive already improved |
| Classroom | `classroom_lobby`, `live_classroom`, `practice_room` | Needs backend contracts |
| Learning | `learning_path`, `tonal_lesson`, `lesson_recap`, `flashcard_focus` | Overlaps Epic A |
| Meta | `dashboard`, `welcome`, `language_selection` | Entry coherence |

**Acceptance (per screen in scope):** Navigate in/out; primary action works; loading/error handled.

---

## 7. Epic D — Polie Translation mode (flexible language pairs)

### D.1 Requirement

User must change **source** and **target** in the Translation UI to **any** pair supported by the **LLM path** (English, French, Chinese, Japanese, African↔African, etc.), independent of onboarding language.

### D.2 Current state

- `TutorTranslationModeScreen` uses `AppLanguage.values` — excludes many world languages.
- `HybridPolieOrchestrator` + Groq fallback can support arbitrary pairs if prompts receive correct names/codes.

### D.3 Implementation plan

1. Add `TranslationLanguageOption` (code, display names); searchable dual dropdowns.
2. Curate list: African set + high-value world languages; extend STT map only where speech is supported; otherwise **typing-only** with label.
3. Orchestrator: if backend/NLLB cannot serve pair → **LLM-only** path with cache key `(text, src, tgt, model)`.
4. Backend (if hybrid translate requires fixed pairs): extend API to accept ISO/BCP-47 strings or bypass to client LLM when unsupported.

**Acceptance:** Yoruba→Japanese, English↔any listed language, African↔African; clear offline behavior.

---

## 8. Epic E — Mockup fidelity pass

1. Per-screen checklist: app bar, spacing, typography, radii, icons vs `code.html`.
2. Use existing tokens (`polie_design_tokens`, `ModernGriotTypography`, etc.); extend tokens only with a short DESIGN delta.
3. Screenshot diff optional for critical screens.

---

## 9. Recommended build order (for “Build” button)

| Phase | Contents | Rationale |
|-------|----------|-----------|
| **P0** | Epic A.2, A.3, A.1 (path + completion + SSOT) | Unblocks core learning |
| **P1** | Epic D (translation flexibility) | Isolated feature; high user value |
| **P2** | Epic B (games empty states + **lexicon repo** B.3 + content plan) | Depends on content pipeline + DB/API |
| **P3** | Epic C + E (mockup slices + fidelity) | Largest surface; parallelizable by cluster |

---

## 10. Open decision (product)

Confirm whether **P3** starts with **Village + AI Chat** cluster only, or **full parallel** mockup sweep. Default recommendation: **Village + AI Chat first**.

---

## 11. Changelog

| Date | Author | Note |
|------|--------|------|
| 2026-04-08 | Planning | Initial Think Mode master plan created for Build handoff |
| 2026-04-08 | Planning | Added Epic B.3 African lexicon: `african_language_game_database.xlsx`, multi-source funnel, Polie/games API alignment |
| 2026-04-10 | Elite program | §0 added: 241+ screens + backend live-readiness; honest gap table; GamesScreenMaterial3 API parity + translationStyle wiring; CI note |
| 2026-04-10 | Elite program | Lexicon: Node `/api/lexicon` routes + Mongo `african_lexicon_entries` + demo seed; Flutter `LexiconRepository` + JSON tests; `api_contract` lexicon tests; §0.3 table refresh |

---

*End of Think Mode Master Plan*

#!/usr/bin/env python3
"""One-off generator for P7 Learn feature cards F-007..F-034. Delete after use."""
from __future__ import annotations

import textwrap
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/build/cards/P7"

BASE_DEPS = ["E-P3-DESIGN-SYSTEM", "E-P2-PLATFORM"]
CONTENT = "E-P5-CONTENT-REAL"
SCORER = "E-P6-SCORER"
CONTAIN = "E-P1-CONTAINMENT"

UX = {
    "states": ["skeleton", "empty", "error", "offline", "ai_unavailable", "under_review"],
    "tokens": ["design-system only"],
    "motion_tier": "product",
    "a11y": ["semantics", "reduced_motion", "200% text"],
    "goldens": ["light", "dark"],
}


def card(
    fid: str,
    title: str,
    anchor: str,
    files: list[str],
    *,
    current: str,
    defects: list[str],
    elevation: list[str],
    ux: list[str],
    hub_placement: str,
    unlock: str = "per §17.4",
    harvest: list[str] | None = None,
    extra_req: list[str] | None = None,
    deps: list[str] | None = None,
    size: str = "M",
    score: int = 5,
    blast: int = 1,
    ambiguity: int = 1,
    coupling: int = 2,
    depth: int = 1,
    worker: str | None = None,
    tester: str = "T2",
    reviewer: str = "T2",
    tags: list[str] | None = None,
    p0: bool = False,
    ext: list[str] | None = None,
    acs: list[str],
) -> dict:
    worker = worker or ("T3" if score >= 7 else "T2")
    if reviewer == "T2" and (blast >= 2 or score >= 7):
        reviewer = worker
    req = [fid, f"{fid}.D", f"{fid}.E", f"{fid}.U", f"{fid}.L"] + (extra_req or [])
    d = list(BASE_DEPS)
    if deps:
        d.extend(deps)
    fa = [f"lib/{p}" if not p.startswith("lib/") else p for p in files[:12]]
    slug = fid.replace("-", "_").lower()
    c = {
        "charter": "v2",
        "id": fid,
        "kind": "feature",
        "inherits": "FEATURE_BASE",
        "title": title,
        "phase": "P7",
        "epic": "E-P7-HUBS",
        "hub": "Learn",
        "req_ids": req,
        "depends_on": d,
        "size": size,
        "difficulty": {
            "score": score,
            "blast": blast,
            "ambiguity": ambiguity,
            "coupling": coupling,
            "depth": depth,
            "size": 0,
        },
        "tiers": {
            "worker": worker,
            "tester": tester,
            "reviewer": reviewer,
            "justification": f"score {score}: hub feature delta spec",
        },
        "token_budget": 30000 if size == "S" else (200000 if size == "L" else 80000),
        "file_allowlist": fa,
        "context_anchors": [f"ELEVATION.md#{anchor}"],
        "delta": {
            "current_state": current,
            "defects_to_fix": defects,
            "elevation_to_build": elevation,
            "ux_and_render": ux,
            "hub_placement": hub_placement,
            "unlock_stage": unlock,
        },
        "acceptance_criteria": [{"id": f"AC{i+1}", "text": t} for i, t in enumerate(acs)],
        "test_plan": {
            "unit": ["domain rules for feature delta"],
            "integration": ["navigation and data wiring from hub placement"],
            "e2e": ["primary happy path from Lives in entry"],
            "a11y": ["goldens at 100%/200% text", "semantics order"],
            "content": ["honest labels on shown curriculum or media"],
        },
        "user_facing": True,
        "ux_spec": {
            **UX,
            "copy_keys": [f"learn.{slug}.*"],
        },
        "tags": tags or [],
        "p0_area": p0,
        "dod_evidence": [
            "tester report",
            "goldens diff",
            "coverage on touched domain code",
            "ledger row",
        ],
        "risks": [],
        "gate": "HUB",
        "external_blockers": ext or [],
        "status": "Draft",
    }
    if harvest:
        c["delta"]["harvest_list"] = harvest
    return c


FEATURES: list[dict] = []

# F-007 through F-034 — built via helper calls in main


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    specs = build_specs()
    for spec in specs:
        path = OUT / f"{spec['id']}.yaml"
        path.write_text(
            yaml.dump(spec, sort_keys=False, allow_unicode=True, width=120, default_flow_style=False),
            encoding="utf-8",
        )
    print(f"wrote {len(specs)} cards to {OUT}")


def build_specs() -> list[dict]:
    return [
        card(
            "F-007",
            "Elevate Lessons map / Courses",
            "§18.3:L3593-L3613",
            [
                "screens/lessons/lessons_map_entry_screen.dart",
                "screens/tabs_view/courses/courses_tab.dart",
                "lessons/screens/lessons_list_screen.dart",
                "screens/curriculum/curriculum_screen_material3.dart",
                "screens/curriculum/curriculum_screen.dart",
                "screens/tutor/curriculum_viewer_screen.dart",
            ],
            current="Routed course map works but pulls template curriculum and duplicates entry points.",
            defects=[
                "Placeholder or template curriculum (P0-16) with four redundant entry points.",
                "No can-do framing on units.",
            ],
            elevation=[
                "One Path map per language with CEFR regions, unit stops, can-dos, downloads, and border checkpoints.",
                "Keep list and teacher outline as modes of the same map.",
            ],
            ux=[
                "Vertical journey with region art, per-unit progress ring, pinned current unit, offline badge.",
            ],
            hub_placement="Learn tab (root).",
            harvest=[
                "lib/screens/curriculum/curriculum_screen.dart",
                "lib/screens/tutor/curriculum_viewer_screen.dart",
            ],
            extra_req=["P0-16"],
            deps=[CONTENT],
            p0=True,
            acs=[
                "Given template curriculum is retired, when the learner opens Path, then units show native-verified can-do labels only.",
                "Given unrouted curriculum variants, when the map loads, then a single routed map exposes list and outline modes.",
                "Given an offline pack exists, when viewing a unit, then an offline badge reflects download state.",
            ],
        ),
        card(
            "F-008",
            "Elevate Authentic Path (A1–C1)",
            "§18.3:L3614-L3628",
            [
                "screens/curriculum/authentic_curriculum_entry_screen.dart",
                "screens/lesson/authentic_lesson_flow_screen.dart",
            ],
            current="Authentic path route works but content is template-repetitive.",
            defects=["Content quality fails P0-16; track name overpromises authenticity."],
            elevation=[
                "Real-world track with licensed authentic media and scaffolding, unlocked from A2 beside core Path.",
            ],
            ux=["Media-first cards with transcript toggle, Tone Lens, and tap-to-gloss."],
            hub_placement='Learn → Path → "Real-world" lane (A2+).',
            unlock="A2+ for Real-world lane",
            extra_req=["P0-16"],
            deps=[CONTENT],
            p0=True,
            acs=[
                "Given learner below A2, when opening Real-world lane, then access is gated with an honest unlock message.",
                "Given licensed media items, when a lesson opens, then transcript, Tone Lens, and gloss work without client AI keys.",
                "Given P0-16 content removed, when browsing the track, then no template-repeat lesson bodies appear.",
            ],
        ),
        card(
            "F-009",
            "Elevate Lesson Flow",
            "§18.3:L3629-L3640",
            [
                "screens/lesson/lesson_flow_screen.dart",
                "screens/lesson/lesson_flow_stages.dart",
            ],
            current="Ten-stage player works but content lacks audio and fixed stages.",
            defects=["Template content, missing audio, non-adaptive stage sequence."],
            elevation=[
                "Adaptive player: input → noticing → guided practice → speaking → mini-check with skip-when-mastered.",
                "Every item includes native audio and a Why sheet.",
            ],
            ux=["Full-screen one task per screen, haptics within 160 ms, segmented progress bar."],
            hub_placement="Opened from Path and Today.",
            deps=[CONTENT],
            acs=[
                "Given mastered skills, when starting a lesson, then skipped stages do not appear in the progress bar.",
                "Given any lesson item, when displayed, then native audio plays and Why sheet is available.",
                "Given offline cache, when playing a downloaded lesson, then flow completes without network.",
            ],
        ),
        card(
            "F-010",
            "Elevate Lesson detail & Level certificate",
            "§18.3:L3641-L3654",
            [
                "screens/curriculum/lesson_detail_screen.dart",
                "screens/curriculum/level_certificate_screen.dart",
            ],
            current="Lesson detail and certificate screens work from curriculum pushes.",
            defects=["Certificates are not evidence-based or verifiable."],
            elevation=[
                "Lesson detail shows can-dos, words, culture note, and preview audio.",
                "Certificates become Open Badges 3.0 can-do credentials linked to Passport.",
            ],
            ux=["Certificate shows learner avatar and QR verification link."],
            hub_placement="Learn → Path → lesson; Me → Credentials.",
            deps=[CONTENT],
            acs=[
                "Given a completed level, when viewing certificate, then QR resolves to verifiable badge metadata.",
                "Given lesson detail, when opened, then can-dos, word list, culture note, and preview audio render.",
                "Given badge backend unavailable, when viewing certificate, then honest error state appears without fake success.",
            ],
        ),
        card(
            "F-011",
            "Elevate Learning Path (personal plan)",
            "§18.3:L3655-L3665",
            ["screens/learning/learning_path_screen.dart"],
            current="Personal learning-path route works but overlaps course map conceptually.",
            defects=["Duplicates the course map instead of a distinct plan view."],
            elevation=[
                'My plan view: learner goal mapped to units, weekly targets, ETA to next can-do.',
            ],
            ux=["Timeline with milestones and editable goal."],
            hub_placement='Learn → Path → "My plan".',
            deps=[CONTENT],
            acs=[
                "Given a learner goal, when saving plan, then weekly targets and ETA update on the timeline.",
                "Given Path progress, when opening My plan, then milestones reflect real unit completion only.",
            ],
        ),
        card(
            "F-012",
            "Elevate Placement test",
            "§18.3:L3666-L3678",
            [
                "screens/onboarding/placement_test_screen.dart",
                "screens/onboarding/placement_quiz_screen.dart",
            ],
            current="Placement works on primary screen; quiz variant is unrouted duplicate.",
            defects=["Not adaptive; no speaking component."],
            elevation=[
                "Adaptive ~3-minute CAT with listening, reading, and one speaking prompt; retakeable placement on Path.",
            ],
            ux=['Calm one item per screen with clear "skip, I\'m a beginner" option.'],
            hub_placement='Onboarding; Learn → Path → "Retake placement".',
            harvest=["lib/screens/onboarding/placement_quiz_screen.dart"],
            deps=[CONTENT],
            score=6,
            coupling=2,
            depth=2,
            acs=[
                "Given onboarding, when placement runs, then listening, reading, and speaking items adapt within ~3 minutes.",
                "Given beginner skip, when chosen, then learner lands on A1 start without fake scores.",
                "Given retake from Path, when completed, then Path position updates from server-validated results.",
            ],
        ),
        card(
            "F-013",
            "Elevate Grammar Hub",
            "§18.3:L3679-L3694",
            [
                "screens/grammar/grammar_hub_screen.dart",
                "screens/grammar/grammar_lesson_screen.dart",
                "screens/grammar/grammar_exercise_screen.dart",
            ],
            current="Grammar routes work with repeated template grammar lines.",
            defects=["Grammar content repeats thin template lines from §6."],
            elevation=[
                "Pattern Library cards with plain-language explanation, audio examples, contrasts, errors, and interactive builders.",
                "Linked from lessons and Polie explanations.",
            ],
            ux=["Colour-coded morphology (not colour-only); swipeable examples."],
            hub_placement="Learn → Patterns.",
            deps=[CONTENT],
            acs=[
                "Given a pattern card, when opened, then five audio examples and common-error contrast render.",
                "Given lesson link, when tapped from a lesson, then matching pattern opens in hub.",
            ],
        ),
        card(
            "F-014",
            "Elevate Vocabulary Builder",
            "§18.3:L3695-L3706",
            ["screens/content/vocabulary_builder_screen.dart"],
            current="Themed vocabulary route works; media and tone data are thin.",
            defects=["Stock or remote images with spinners; words lack audio and tone data."],
            elevation=[
                "Themed packs with native audio, Tone Lens, culturally reviewed images, add-all-to-review, Living Dictionary link.",
            ],
            ux=["Picture grid: tap to hear, long-press opens Word Card."],
            hub_placement="Learn → Words → Packs.",
            deps=[CONTENT],
            ext=["EXT-13"],
            acs=[
                "Given a pack word, when tapped, then native audio plays with Tone Lens data.",
                "Given add-all, when confirmed, then words enqueue to FSRS review without duplicate rows.",
            ],
        ),
        card(
            "F-015",
            "Elevate My Words & Review (SRS)",
            "§18.3:L3707-L3727",
            [
                "screens/vocabulary/vocabulary_screen.dart",
                "screens/vocabulary/flashcard_review_screen.dart",
                "screens/vocabulary/vocabulary_flashcard_screen.dart",
                "screens/ai_chat/review_dashboard_screen.dart",
                "screens/ai_chat/vocabulary_dashboard_screen.dart",
            ],
            current="Review routes work; multiple SRS implementations and unrouted dashboards remain.",
            defects=[
                "Four separate SRS implementations; no FSRS; saves from chat/personas/games do not flow here.",
            ],
            elevation=[
                "Single FSRS-6 review fed by every save action; Insights tab with forecast, retention, hardest words, tone errors.",
            ],
            ux=["Audio-first review card, swipe grades, speak-it button; charts from real data."],
            hub_placement="Learn → Words → Review / Insights; Today pulls due items.",
            harvest=[
                "lib/screens/vocabulary/vocabulary_flashcard_screen.dart",
                "lib/screens/ai_chat/review_dashboard_screen.dart",
                "lib/screens/ai_chat/vocabulary_dashboard_screen.dart",
            ],
            size="L",
            score=7,
            blast=2,
            coupling=2,
            depth=2,
            acs=[
                "Given a word saved in chat, when review opens, then the same card appears in FSRS queue once.",
                "Given due cards, when Insights loads, then forecast and retention charts use server data only.",
                "Given legacy SRS screens, when menu navigates, then only unified review and Insights remain reachable.",
            ],
        ),
        card(
            "F-016",
            "Elevate Review Rush (gamified review)",
            "§18.3:L3728-L3741",
            ["screens/review/gamified_review_screen.dart"],
            current="Gamified review screen exists unrouted but wired to real providers.",
            defects=["Not reachable from any menu."],
            elevation=[
                "90-second sprint over due cards; combo multipliers reward accuracy only; updates FSRS like normal review.",
            ],
            ux=["Arcade skin on shared review card; reduced-motion variant."],
            hub_placement='Learn → Words → Review → "Rush"; Play → Quick games.',
            size="S",
            score=4,
            blast=1,
            coupling=1,
            depth=1,
            worker="T1",
            acs=[
                "Given due cards, when Rush starts, then 90-second timer runs and grades update FSRS.",
                "Given menu entry from Review, when tapped, then gamified_review route opens.",
            ],
        ),
        card(
            "F-017",
            "Elevate Listening Practice",
            "§18.3:L3742-L3756",
            [
                "screens/content/listening_practice_screen.dart",
                "screens/tutor/listening_quiz_screen.dart",
            ],
            current="Listening practice works; tutor quiz screen is unrouted duplicate mode.",
            defects=["Content lacks real audio per §6."],
            elevation=[
                "Ear training at native speed with regional accents, slow-down, diacritic-aware dictation; quiz merged as mode.",
            ],
            ux=["Waveform with tap-to-replay; transcript after answering."],
            hub_placement="Learn → Skills → Listening.",
            harvest=["lib/screens/tutor/listening_quiz_screen.dart"],
            deps=[CONTENT],
            ext=["EXT-13"],
            acs=[
                "Given a listening item, when played, then licensed native audio streams with accent metadata.",
                "Given quiz mode, when selected, then same audio pipeline runs without separate unrouted screen.",
            ],
        ),
        card(
            "F-018",
            "Elevate Writing Practice",
            "§18.3:L3757-L3768",
            ["screens/content/writing_practice_screen.dart"],
            current="Writing route works but calls Groq from client for feedback.",
            defects=["Client AI key dependency (P0-3); regex diacritic enforcer can corrupt input."],
            elevation=[
                "Write and check with diacritic bar, progressive tone grading, gateway AI feedback with uncertainty labels.",
                "Handwriting mode for Ge'ez, N'Ko, and Adlam.",
            ],
            ux=["Inline corrections via popover; never auto-replace learner text."],
            hub_placement="Learn → Skills → Writing.",
            extra_req=["P0-3"],
            deps=[CONTAIN],
            p0=True,
            score=6,
            depth=2,
            acs=[
                "Given writing submission, when checked, then feedback uses AI gateway only with no client keys.",
                "Given tone-unclear spans, when feedback shows, then uncertainty copy appears instead of false precision.",
                "Given diacritic bar input, when submitted, then text is not silently rewritten by regex enforcer.",
            ],
        ),
        card(
            "F-019",
            "Elevate Phrase DNA",
            "§18.3:L3769-L3781",
            [
                "screens/learning/phrase_dna/phrase_dna_templates_screen.dart",
                "screens/learning/phrase_dna/phrase_dna_session_screen.dart",
            ],
            current="Phrase DNA templates and session routes work on thin templates.",
            defects=["Templates reuse same thin content pool."],
            elevation=[
                "Speakable sentence frames with learner word slots, tone sandhi context, and scored full-sentence production.",
            ],
            ux=["Slot chips snap in place; Tone Lens updates live."],
            hub_placement="Learn → Skills → Phrase DNA; Speak → Warm-ups.",
            deps=[CONTENT, SCORER],
            tags=["shows_score"],
            acs=[
                "Given filled slots, when learner speaks sentence, then real scorer results display without fake scores.",
                "Given sandhi language, when slots change, then Tone Lens reflects contextual tone shifts.",
            ],
        ),
        card(
            "F-020",
            "Elevate Tone & Rhythm Trainer",
            "§18.3:L3782-L3797",
            [
                "screens/learning/tone_rhythm/tone_rhythm_trainer_screen.dart",
                "screens/practice/tone_drill_screen.dart",
            ],
            current="Tone rhythm trainer works; separate drill screen is unrouted.",
            defects=["Simplified one H/M/L tone model for all languages."],
            elevation=[
                "Tone Gym with perception drills, live pitch production vs native contour, per-language inventories, progression ladder.",
            ],
            ux=["Large pitch canvas; native vs learner contours; shape and label, not colour-only."],
            hub_placement="Speak → Tone Gym (also Learn → Skills).",
            harvest=["lib/screens/practice/tone_drill_screen.dart"],
            tags=["shows_score", "tts_tonal"],
            deps=[SCORER],
            size="L",
            score=7,
            blast=2,
            coupling=2,
            depth=2,
            ext=["EXT-13"],
            acs=[
                "Given production drill, when learner speaks, then live contour overlays native reference from real scorer.",
                "Given Yoruba vs Hausa, when drill loads, then inventory matches language-specific tone system.",
                "Given reduced motion, when drills run, then static contour comparison replaces animated overlay.",
            ],
        ),
        card(
            "F-021",
            "Elevate Tonal Lesson (Village)",
            "§18.3:L3798-L3808",
            ["screens/village/tonal_lesson_screen.dart"],
            current="Tonal lesson route works but isolated from Tone Gym and Path.",
            defects=["No linkage to Tone Gym or Path tone units."],
            elevation=[
                "Story-led tone lesson linked to Tone Gym practice and Path tone introduction units.",
            ],
            ux=["Character-led scene with Tone Lens on every line."],
            hub_placement="Learn → Path (tone units); Speak → Tone Gym → Lessons.",
            deps=[CONTENT],
            tags=["tts_tonal"],
            acs=[
                "Given tone unit on Path, when opened, then story lesson links to matching Tone Gym drills.",
                "Given every dialogue line, when rendered, then Tone Lens wraps target-language text.",
            ],
        ),
        card(
            "F-022",
            "Elevate Language Quiz",
            "§18.3:L3809-L3821",
            [
                "language_quiz/screens/language_quiz_sections_screen.dart",
                "screens/tabs_view/home/take_quiz_screen.dart",
            ],
            current="Quiz entry from home works with placeholder MCQ bundles.",
            defects=["Placeholder items; no calibration to learner level."],
            elevation=[
                "Merge into item bank: unit checkpoints and adaptive quizzes with rationales and audio.",
            ],
            ux=["Clean MCQ/listening templates; results update can-do."],
            hub_placement='Learn → Path → Checkpoints; Today → "Quick quiz".',
            deps=[CONTENT],
            acs=[
                "Given unit checkpoint, when quiz completes, then can-do updates from server-scored items only.",
                "Given placeholder MCQ text, when item bank loads, then Sample MCQ strings never appear.",
            ],
        ),
        card(
            "F-023",
            "Elevate History & History Quiz",
            "§18.3:L3822-L3833",
            [
                "history/screens/history_list_screen.dart",
                "history_quiz/screens/history_quiz_sections_screen.dart",
            ],
            current="History list and quiz sections work from home/drawer pushes.",
            defects=["Facts lack sourcing and historian review."],
            elevation=[
                "Living History stories with sources, persona links, and quizzes citing the story; historian-reviewed.",
            ],
            ux=['Story cards with "Sources" footer and persona portrait chip.'],
            hub_placement="Learn → Culture → History; Speak → Personas cross-link.",
            acs=[
                "Given a history story, when opened, then sources footer lists reviewed citations.",
                "Given quiz question, when shown, then rationale references the story segment.",
            ],
        ),
        card(
            "F-024",
            "Elevate Mannerisms & etiquette",
            "§18.3:L3834-L3844",
            ["mannerisms/screens/mannerism_list_screen.dart"],
            current="Mannerisms list works as text-only cultural list.",
            defects=["Text list only; no practice or video."],
            elevation=[
                "Etiquette cards with commissioned video, why copy, and Greeting Gauntlet practice rounds.",
            ],
            ux=["Card stack with gesture illustrations and regional variant flags."],
            hub_placement="Learn → Culture → Etiquette.",
            ext=["EXT-16"],
            acs=[
                "Given etiquette card, when practice starts, then video or illustration loads with regional variant label.",
                "Given Greeting Gauntlet, when round completes, then progress saves without fake participants.",
            ],
        ),
        card(
            "F-025",
            "Elevate Cultural Hub",
            "§18.3:L3845-L3855",
            ["screens/content/cultural_hub_screen.dart"],
            current="Cultural hub route works as one of several culture entry points.",
            defects=["Fragmented culture entry points across magazine, heritage, history, mannerisms."],
            elevation=[
                "Culture landing in Learn organizing Magazine, History, Etiquette, Heritage archive, Proverbs, Music.",
            ],
            ux=["Editorial layout with featured story and shelves."],
            hub_placement="Learn → Culture (root).",
            acs=[
                "Given Learn Culture root, when opened, then shelves link to Magazine, History, Etiquette, Archive, Proverbs, Music.",
            ],
        ),
        card(
            "F-026",
            "Elevate Culture Magazine",
            "§18.3:L3856-L3874",
            [
                "screens/magazine/culture_magazine_screen_enhanced.dart",
                "screens/magazine/culture_magazine_screen.dart",
                "screens/magazine/culture_magazine_enhanced_features.dart",
            ],
            current="Enhanced magazine route works; legacy screen unrouted; client Groq for AI features.",
            defects=[
                "Client AI keys (P0-3); backend generates unreviewed AI articles.",
            ],
            elevation=[
                "Bilingual leveled articles with gloss, native narration, save-words, commissioned author credits; AI drafts labelled and reviewed.",
            ],
            ux=["Typography-led Andika/Noto layout; reading progress; offline save."],
            hub_placement="Learn → Culture → Magazine; Today → culture card.",
            harvest=["lib/screens/magazine/culture_magazine_screen.dart"],
            extra_req=["P0-3"],
            deps=[CONTAIN],
            p0=True,
            score=6,
            depth=2,
            acs=[
                "Given AI-assisted article, when displayed, then draft/review label shows before body text.",
                "Given reader saves words, when tapped, then words flow to My Words without client Groq calls.",
            ],
        ),
        card(
            "F-027",
            "Elevate Heritage Milestones",
            "§18.3:L3875-L3887",
            ["screens/learning/heritage_milestones_screen.dart"],
            current="Heritage milestones route works with generic milestone copy.",
            defects=["Milestones are generic, not family-specific."],
            elevation=[
                "Family heritage milestones with self-report and optional private audio memories in family album.",
            ],
            ux=["Timeline with photos and voice memories; private by default."],
            hub_placement="Me → Heritage; Today celebrates milestones.",
            acs=[
                "Given milestone capture, when saved, then visibility defaults private until learner opts in.",
            ],
        ),
        card(
            "F-028",
            "Elevate FLB Heritage Archive",
            "§18.3:L3888-L3899",
            [
                "screens/heritage/flb_heritage_archive_screen.dart",
                "screens/heritage/flb_heritage_detail_screen.dart",
            ],
            current="Archive list and detail routes work; licensing unclear.",
            defects=["Provenance and licensing of items unclear."],
            elevation=[
                "Living Archive with consent-recorded folktales, oríkì, songs, proverbs; transcript, Tone Lens, contributor credit, licence.",
            ],
            ux=["Museum-like detail: audio first, then text."],
            hub_placement="Learn → Culture → Archive.",
            ext=["EXT-13"],
            acs=[
                "Given archive item, when detail opens, then licence, contributor credit, and consent status display.",
            ],
        ),
        card(
            "F-029",
            "Elevate Dialect Preference",
            "§18.3:L3900-L3911",
            ["screens/learning/dialect_preference_screen.dart"],
            current="Dialect preference route works but does not affect content.",
            defects=["Dialect choice does not switch dialect-tagged audio yet."],
            elevation=[
                "Dialect lanes with per-item audio variants, difference notes, and hear-other-dialect toggle on Word Card.",
            ],
            ux=["Map picker with sample audio per dialect."],
            hub_placement="Me → Settings → Language & dialect; Word Card toggle.",
            ext=["EXT-13"],
            acs=[
                "Given dialect selection, when content plays, then audio matches selected dialect variant when available.",
            ],
        ),
        card(
            "F-030",
            "Elevate Living Dictionary",
            "§18.3:L3912-L3923",
            [
                "screens/vocabulary/living_dictionary_screen.dart",
                "services/learning/living_dictionary_service.dart",
            ],
            current="Living dictionary route works as per-user list; see §17.7 evidence.",
            defects=[
                "Per-user list only; no shared verified lexicon or promotion path.",
            ],
            elevation=[
                "Two-layer lexicon: verified shared entries with badges and rich fields; My Words links to verified lemmas.",
                "Suggest-verify-promote loop via Village queue; global long-press and search; pan-African cognate strip; offline pack.",
            ],
            ux=[
                "Word Card bottom sheet with tone-safe lemma, contours, multi-speaker audio, dialect chips, honest verification badges.",
            ],
            hub_placement="Global search and long-press; Learn → Words.",
            deps=["P7-920", "P7-921"],
            size="L",
            score=7,
            blast=2,
            coupling=2,
            depth=2,
            acs=[
                "Given learner suggests a word, when natives verify, then entry promotes to verified lexicon with credit.",
                "Given saved My Word with verified match, when Word Card opens, then rich verified fields display.",
                "Given offline pack synced, when searching, then top entries and audio load without network.",
            ],
        ),
        card(
            "F-031",
            "Elevate Offline Downloads",
            "§18.3:L3924-L3936",
            ["screens/offline/offline_content_screen.dart"],
            current="Offline screen wired to providers but unrouted.",
            defects=["Offline screen unreachable despite market need."],
            elevation=[
                "Downloads hub: per-unit packs, storage meter, Wi-Fi-only toggle, auto-next-unit, offline Tone Gym when model ships.",
            ],
            ux=["List shows pack size, progress, and sync status."],
            hub_placement="Me → Downloads; Path download icon per unit.",
            size="S",
            score=4,
            blast=1,
            coupling=1,
            depth=1,
            worker="T1",
            acs=[
                "Given Me Downloads, when opened, then offline_content route is reachable with sync status.",
                "Given unit on Path, when download tapped, then pack progress persists via offline providers.",
            ],
        ),
        card(
            "F-032",
            "Elevate Language detail & Suggest a language",
            "§18.3:L3937-L3950",
            [
                "screens/tabs_view/home/language_detail_screen.dart",
                "screens/tabs_view/profile/suggest_language_screen.dart",
            ],
            current="Language detail and suggest-language pushes work; suggestions disappear.",
            defects=["Language suggestions are not visible on a public waitlist."],
            elevation=[
                "Language pages show speakers, regions, L0–L3 readiness, sample phrase; suggest flow feeds Waves 2–4 waitlist and native reviewer signup.",
            ],
            ux=["Map, audio sample, readiness badge, waitlist counter."],
            hub_placement='Learn → language switcher → "All languages".',
            acs=[
                "Given suggest submission, when saved, then entry appears on public waitlist counter.",
            ],
        ),
        card(
            "F-033",
            "Elevate Passport (proctored test & credential)",
            "§18.3:L3951-L3964",
            [
                "screens/passport/passport_proctored_session_screen.dart",
                "screens/passport/passport_credential_screen.dart",
            ],
            current="Passport UI routes work; scoring and content not yet valid.",
            defects=["Invalid scoring/content; unclear proctoring privacy terms."],
            elevation=[
                "Evidence portfolio plus adaptive proctored test mapped to CEFR with published methodology and verifiable credential.",
            ],
            ux=["Formal calm UI; privacy explanation before camera activates."],
            hub_placement="Me → Credentials (unlocks at A2).",
            unlock="A2",
            deps=[CONTENT, SCORER],
            tags=["issues_credential"],
            size="L",
            score=8,
            blast=3,
            ambiguity=1,
            coupling=2,
            depth=2,
            reviewer="T3",
            acs=[
                "Given learner below A2, when opening Passport, then feature stays locked with honest criteria.",
                "Given proctoring start, when camera requested, then privacy copy must be acknowledged first.",
                "Given real scoring unavailable, when test ends, then no credential is issued and UI states why.",
            ],
        ),
        card(
            "F-034",
            "Elevate Lesson Recap",
            "§18.3:L3965-L3978",
            ["screens/learning/lesson_recap_screen.dart"],
            current="Lesson recap screen exists unrouted.",
            defects=["Lessons end without consolidation or retrieval moment."],
            elevation=[
                "60-second post-lesson recap: three retrieval questions, new words with audio/Tone Lens, scored aloud sentence, what's next; auto FSRS enqueue.",
            ],
            ux=["Card stack, large type, one celebratory moment without confetti spam."],
            hub_placement="End of every lesson (Learn → lesson → recap).",
            deps=[CONTENT, SCORER],
            tags=["shows_score"],
            size="S",
            score=5,
            acs=[
                "Given lesson completion, when flow ends, then recap route opens automatically.",
                "Given recap speak prompt, when learner responds, then scored result uses real scorer only.",
                "Given new words in recap, when finished, then words enter FSRS queue once.",
            ],
        ),
    ]


if __name__ == "__main__":
    main()

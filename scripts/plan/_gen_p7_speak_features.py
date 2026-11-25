#!/usr/bin/env python3
"""One-off generator for P7 Speak feature cards F-035..F-054."""
import yaml
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/build/cards/P7"
COMMON_UX = {
    "states": ["skeleton", "empty", "error", "offline", "ai_unavailable", "under_review"],
    "tokens": ["design-system only"],
    "motion_tier": "product",
    "a11y": ["semantics", "reduced_motion", "200% text"],
    "goldens": ["light", "dark"],
}


def card(**kw):
    base = {
        "charter": "v2",
        "kind": "feature",
        "inherits": "FEATURE_BASE",
        "phase": "P7",
        "epic": "E-P7-HUBS",
        "hub": "Speak",
        "gate": "HUB",
        "status": "Draft",
        "user_facing": True,
        "p0_area": False,
        "external_blockers": [],
        "dod_evidence": ["tester report", "goldens diff", "coverage on touched domain code", "ledger row"],
        "risks": [],
        "tags": [],
        "token_budget": 80000,
        "size": "M",
        "difficulty": {"score": 5, "blast": 1, "ambiguity": 1, "coupling": 1, "depth": 1, "size": 1},
        "tiers": {
            "worker": "T2",
            "tester": "T2",
            "reviewer": "T2",
            "justification": "score 5: Speak hub feature elevation",
        },
    }
    base.update(kw)
    base.setdefault("ux_spec", {**COMMON_UX, "copy_keys": [f"{base['id'].lower()}.*"]})
    return base


def tutor_mode(fid, title, anchor, files, **opts):
    req = [fid, f"{fid}.D", f"{fid}.E", f"{fid}.U", f"{fid}.L", opts.get("p0", "P0-3")]
    req.extend(opts.get("extra_req", []))
    dep = ["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT"]
    tags = []
    if opts.get("shows"):
        dep.append("E-P6-SCORER")
        tags.append("shows_score")
    score = opts.get("score", 6 if opts.get("shows") else 5)
    tiers = (
        {"worker": "T3", "tester": "T2", "reviewer": "T3", "justification": f"score {score}: tutor/scoring"}
        if score >= 7
        else {"worker": "T2", "tester": "T2", "reviewer": "T2", "justification": f"score {score}: tutor mode via gateway"}
    )
    diff = {
        "score": score,
        "blast": 2 if score >= 7 else 1,
        "ambiguity": 1,
        "coupling": 2 if opts.get("shows") else 1,
        "depth": 2 if score >= 7 else 1,
        "size": 0 if score >= 7 else (0 if opts.get("shows") else 1),
    }
    d = {
        "current_state": "Routed tutor UI with direct client Groq calls.",
        "defects_to_fix": [
            "Client key dependency with silent release fallbacks.",
            "No grounding in approved curriculum content.",
        ],
        "elevation_to_build": opts.get(
            "elevation_extra",
            ["Mode uses shared tutor shell through the AI gateway with approved grounding rules."],
        ),
        "ux_and_render": [
            "Shared tutor shell with avatar header, mode chip, transcript, mic, and feedback drawer beyond the shared bar."
        ],
        "hub_placement": "Speak → Polie → mode chips.",
        "unlock_stage": "per §17.4",
    }
    if opts.get("harvest"):
        d["harvest_list"] = opts["harvest"]
    ac = [
        {
            "id": "AC1",
            "text": "Given release build, when the learner opens this tutor mode, then all AI calls use the gateway and failures surface typed errors.",
        },
        {
            "id": "AC2",
            "text": "Given an active session, when the learner uses the mic, then transcript and feedback drawer update without client-side provider keys.",
        },
    ]
    if opts.get("shows"):
        ac.append(
            {
                "id": "AC3",
                "text": "Given the learner completes the exercise, when scoring runs, then results use E-P6-SCORER outputs and never fabricated rhythm or placeholder scores.",
            }
        )
    else:
        ac.append(
            {
                "id": "AC3",
                "text": "Given grounding rules for this mode, when Polie responds, then outputs follow elevation constraints and cite approved content where required.",
            }
        )
    ac.extend(opts.get("ac_extra", []))
    kw = dict(
        id=fid,
        title=title,
        req_ids=req,
        depends_on=dep,
        tags=tags,
        difficulty=diff,
        tiers=tiers,
        p0_area=True,
        file_allowlist=files,
        context_anchors=[f"ELEVATION.md#§18.4:{anchor}"],
        delta=d,
        acceptance_criteria=ac,
        test_plan={
            "unit": ["mode-specific logic"],
            "integration": ["gateway tutor session"],
            "e2e": [f"Speak → Polie → {fid}"],
            "a11y": ["goldens at 100%/200% text", "semantics"],
            "content": opts.get("content", []),
        },
    )
    for k in ("external_blockers", "size", "token_budget"):
        if k in opts:
            kw[k] = opts[k]
    return card(**kw)


def main():
    cards = [
        card(
            id="F-035",
            title="Elevate Polie AI Tutor workspace",
            req_ids=["F-035", "F-035.D", "F-035.E", "F-035.U", "F-035.L", "P0-3"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT"],
            size="L",
            token_budget=200000,
            difficulty={"score": 7, "blast": 2, "ambiguity": 1, "coupling": 2, "depth": 2, "size": 0},
            tiers={
                "worker": "T3",
                "tester": "T2",
                "reviewer": "T3",
                "justification": "score 7: voice-first Polie via gateway with streaming and consolidation",
            },
            p0_area=True,
            file_allowlist=[
                "lib/screens/ai_chat/polie_workspace_screen.dart",
                "lib/screens/ai_chat/ai_chat_select_screen.dart",
                "lib/screens/ai_chat/ai_mode_selection_screen.dart",
                "lib/screens/ai_chat/polie_mode_selection_screen.dart",
                "lib/screens/ai_chat/ai_chat_language_setup_screen.dart",
                "lib/screens/ai_chat/ai_chat_screen.dart",
                "lib/screens/ai_chat/ai_chat_screen_with_tracking.dart",
                "lib/screens/ai_chat/conversation_enhanced_screen.dart",
                "lib/providers/ai_chat_provider_groq.dart",
            ],
            context_anchors=["ELEVATION.md#§18.4:L3979-L4003"],
            delta={
                "current_state": "Routed Polie workspace with client-side Groq calls and five unrouted chat variants.",
                "defects_to_fix": [
                    "Monolithic workspace screen with client API keys and no backend streaming.",
                    "Silent AI fallbacks and swallowed errors.",
                ],
                "elevation_to_build": [
                    "Voice-first hold-to-talk with live transcript, Tone Lens, recasts, hint ladder, and save phrase.",
                    "Mode chips and learner-model-aware replies through the AI gateway with streaming and lip-sync avatar.",
                ],
                "ux_and_render": [
                    "Large target-language chat with tap gloss and avatar bust showing listen/think/speak states.",
                    "Explicit AI-unavailable state; no silent fake replies.",
                ],
                "hub_placement": "Speak tab root → Polie.",
                "unlock_stage": "per §17.4",
                "harvest_list": ["Tracking and enhanced conversation flows from unrouted ai_chat_screen variants."],
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given release build without client keys, when the learner opens Polie and holds to talk, then audio transcribes via the gateway with streaming replies and no Groq client calls.",
                },
                {
                    "id": "AC2",
                    "text": "Given Polie replies in the target language, when the learner taps a line, then Tone Lens and gloss appear and save-phrase persists to the outbox offline.",
                },
                {
                    "id": "AC3",
                    "text": "Given AI gateway failure, when the learner sends a message, then ai_unavailable state shows what failed and next steps without placeholder success copy.",
                },
                {
                    "id": "AC4",
                    "text": "Given unrouted legacy chat screens, when navigation is audited, then only the consolidated Polie workspace route remains wired from Speak.",
                },
            ],
            test_plan={
                "unit": ["gateway mode enum mapping", "hint ladder state machine"],
                "integration": ["Polie hold-to-talk streaming", "offline outbox sync"],
                "e2e": ["Speak → Polie voice session"],
                "a11y": ["goldens at 100%/200% text", "semantics on mic and chips"],
                "content": [],
            },
        ),
        tutor_mode(
            "F-036",
            "Elevate Tutor Dialogue mode",
            "L4004-L4019",
            ["lib/screens/tutor/tutor_dialogue_mode_screen.dart"],
            shows=True,
            elevation_extra=[
                "Scripted-goal dialogues with improvised Polie inside human scenarios.",
                "Score goal completion, politeness, and accuracy; replay with alternate personas.",
            ],
            ac_extra=[
                {
                    "id": "AC4",
                    "text": "Given a completed dialogue, when the summary opens, then goal, politeness, and accuracy scores reflect server scoring not client guesses.",
                }
            ],
        ),
        tutor_mode(
            "F-037",
            "Elevate Tutor Grammar mode",
            "L4020-L4033",
            ["lib/screens/tutor/tutor_grammar_mode_screen.dart"],
            elevation_extra=[
                "Retrieval-only answers from the Pattern Library with cited pattern cards.",
                "Spawn three-item micro-drills; explanations in learner L1.",
            ],
            content=["pattern library citations"],
        ),
        tutor_mode(
            "F-038",
            "Elevate Tutor Story mode",
            "L4034-L4048",
            ["lib/screens/tutor/tutor_story_mode_screen.dart"],
            elevation_extra=[
                "Choose-your-path stories at learner level using known and due words.",
                "Native TTS narration, comprehension checks, AI-generated label, human review path to shared library.",
            ],
        ),
        tutor_mode(
            "F-039",
            "Elevate Tutor Translation mode",
            "L4049-L4063",
            ["lib/screens/tutor/tutor_translation_mode_screen.dart"],
            harvest=["Unrouted enhanced_translation_screen.dart alignment and register UI."],
            elevation_extra=[
                "Translate-and-teach with word alignment and register options.",
                "Commercial MT stack with per-pair confidence badges.",
            ],
        ),
        tutor_mode(
            "F-040",
            "Elevate Tutor Pronunciation mode",
            "L4065-L4080",
            ["lib/screens/tutor/tutor_pronunciation_mode_screen.dart"],
            shows=True,
            score=7,
            extra_req=["P0-18"],
            external_blockers=["EXT-13"],
            harvest=["Unrouted practice/pronunciation_practice_screen.dart flows."],
            elevation_extra=[
                "Real GOP and tone scoring with native contour overlay.",
                "Remove fake rhythm multiplier scoring.",
            ],
        ),
        tutor_mode(
            "F-041",
            "Elevate Tutor Assess mode",
            "L4081-L4094",
            ["lib/screens/tutor/tutor_assess_mode_screen.dart"],
            shows=True,
            elevation_extra=[
                "Five-minute adaptive oral interview lite rated against can-do descriptors.",
                "Native-rater calibration feeds Passport evidence portfolio.",
            ],
            ac_extra=[
                {
                    "id": "AC4",
                    "text": "Given a finished assess session, when results display, then can-do ratings and portfolio evidence come from server rubric not client text.",
                }
            ],
        ),
        card(
            id="F-042",
            title="Elevate Tutor dashboard",
            req_ids=["F-042", "F-042.D", "F-042.E", "F-042.U", "F-042.L"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT", "E-P6-SCORER"],
            file_allowlist=[
                "lib/screens/tutor/tutor_dashboard_screen.dart",
                "lib/screens/ai_chat/tutor_progress_dashboard_screen.dart",
            ],
            context_anchors=["ELEVATION.md#§18.4:L4095-L4107"],
            delta={
                "current_state": "Routed mode list; unrouted tutor progress dashboard duplicate.",
                "defects_to_fix": ["Modes listed without recommendation or weak-skill targeting."],
                "elevation_to_build": [
                    "Coach view recommending next mode from weak skills.",
                    "Progress tab with speaking minutes, tone accuracy trend, and conversation goals.",
                ],
                "ux_and_render": ["Recommended ribbon on cards and small honest charts beyond shared bar."],
                "hub_placement": "Speak → Polie → Coach.",
                "unlock_stage": "per §17.4",
                "harvest_list": ["tutor_progress_dashboard_screen.dart as the Progress tab."],
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given learner skill telemetry, when the coach opens, then a recommended mode appears with rationale tied to weak skills.",
                },
                {
                    "id": "AC2",
                    "text": "Given historical speaking data, when the progress tab loads, then minutes, tone trend, and goals charts use server metrics not placeholders.",
                },
                {
                    "id": "AC3",
                    "text": "Given unrouted progress dashboard, when Speak → Polie → Coach is opened, then a single consolidated dashboard route remains.",
                },
            ],
            test_plan={
                "unit": ["recommendation ranking"],
                "integration": ["progress metrics API"],
                "e2e": ["Speak → Polie → Coach"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": [],
            },
        ),
        card(
            id="F-043",
            title="Elevate Shadowing (revived)",
            req_ids=["F-043", "F-043.D", "F-043.E", "F-043.U", "F-043.L", "P0-3"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT", "E-P6-SCORER"],
            tags=["shows_score"],
            p0_area=True,
            external_blockers=["EXT-13"],
            difficulty={"score": 6, "blast": 1, "ambiguity": 1, "coupling": 2, "depth": 2, "size": 0},
            tiers={
                "worker": "T2",
                "tester": "T2",
                "reviewer": "T2",
                "justification": "score 6: shadowing revival with alignment scoring",
            },
            file_allowlist=["lib/screens/tutor/shadowing_exercise_screen.dart"],
            context_anchors=["ELEVATION.md#§18.4:L4108-L4121"],
            delta={
                "current_state": "Unrouted shadowing screen with client Groq usage.",
                "defects_to_fix": ["Feature unreachable from Speak/Today.", "Client key dependency on AI paths."],
                "elevation_to_build": [
                    "Shadow Me: native clip with karaoke highlighting from forced alignment.",
                    "Tone contour comparison and two-minute Today slot.",
                ],
                "ux_and_render": ["Lyrics-style transcript, dual waveform, and slow toggle beyond shared bar."],
                "hub_placement": "Speak → Practice → Shadowing; Today slot.",
                "unlock_stage": "per §17.4",
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given Speak → Practice, when Shadowing is chosen, then the revived route loads native clip and mic capture.",
                },
                {
                    "id": "AC2",
                    "text": "Given the learner shadows audio, when alignment completes, then word highlight and tone contour scores use E-P6-SCORER not client mocks.",
                },
                {
                    "id": "AC3",
                    "text": "Given Today daily slot, when shadowing is due, then a two-minute session entry appears and completes honestly offline-capable.",
                },
            ],
            test_plan={
                "unit": ["alignment highlight timing"],
                "integration": ["scoring overlay"],
                "e2e": ["Speak → Shadowing"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": [],
            },
        ),
        card(
            id="F-044",
            title="Elevate Conversation Scenarios and Roleplay",
            req_ids=["F-044", "F-044.D", "F-044.E", "F-044.U", "F-044.L", "P0-3"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT"],
            p0_area=True,
            file_allowlist=[
                "lib/screens/content/conversation_scenarios_screen.dart",
                "lib/screens/ai_chat/roleplay_scenario_selection_screen.dart",
                "lib/screens/ai_chat/roleplay_completion_summary_screen.dart",
                "lib/screens/ai_chat/roleplay_progress_dashboard_screen.dart",
            ],
            context_anchors=["ELEVATION.md#§18.4:L4122-L4142"],
            delta={
                "current_state": "Scenarios route works; selection, summary, and progress dashboards unrouted.",
                "defects_to_fix": ["No closure or progression without summary and progress.", "Client AI dependency."],
                "elevation_to_build": [
                    "Scenario Theatre library with goals and cast.",
                    "Completion summary and scene passport progress dashboard; shared engine for market and greeting scenarios.",
                ],
                "ux_and_render": ["Illustrated scene cards and summary replay of key moments beyond shared bar."],
                "hub_placement": "Speak → Scenarios.",
                "unlock_stage": "per §17.4",
                "harvest_list": ["Wire roleplay selection, completion summary, and progress dashboard into Scenarios flow."],
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given a finished roleplay scene, when the learner exits, then completion summary shows goals, phrases, corrections, and saveable words.",
                },
                {
                    "id": "AC2",
                    "text": "Given multiple scenarios completed, when progress opens, then scene passport stamps reflect server state not local mocks.",
                },
                {
                    "id": "AC3",
                    "text": "Given release build, when roleplay runs, then AI uses gateway containment without client Groq keys.",
                },
            ],
            test_plan={
                "unit": ["scene passport aggregation"],
                "integration": ["roleplay gateway session"],
                "e2e": ["Speak → Scenarios full loop"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": [],
            },
        ),
        card(
            id="F-045",
            title="Elevate Conversation Analytics",
            req_ids=["F-045", "F-045.D", "F-045.E", "F-045.U", "F-045.L"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM"],
            difficulty={"score": 4, "blast": 0, "ambiguity": 1, "coupling": 1, "depth": 1, "size": 1},
            tiers={
                "worker": "T2",
                "tester": "T2",
                "reviewer": "T2",
                "justification": "score 4: revive analytics charts from collected data",
            },
            file_allowlist=["lib/screens/ai_chat/conversation_analytics_screen.dart"],
            context_anchors=["ELEVATION.md#§18.4:L4143-L4154"],
            delta={
                "current_state": "Unrouted analytics screen wired to conversationAnalyticsServiceProvider.",
                "defects_to_fix": ["Insight data collected but never shown to learners."],
                "elevation_to_build": [
                    "How I speak: words used vs avoided, utterance length, code-switch rate, tone accuracy trend, frequent corrections.",
                    "One actionable suggestion per week.",
                ],
                "ux_and_render": ["Simple charts each with an explanation line beyond shared bar."],
                "hub_placement": "Speak → Coach → Insights; Me → Progress.",
                "unlock_stage": "per §17.4",
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given stored conversation analytics, when Speak → Coach → Insights opens, then charts render from the service without empty placeholder panels.",
                },
                {
                    "id": "AC2",
                    "text": "Given a weekly refresh, when insights load, then exactly one actionable suggestion displays with honest empty states when data is insufficient.",
                },
                {
                    "id": "AC3",
                    "text": "Given Me → Progress, when the learner views speaking insights, then the same metrics match Speak coach insights.",
                },
            ],
            test_plan={
                "unit": ["analytics aggregation"],
                "integration": ["conversationAnalyticsServiceProvider"],
                "e2e": ["Speak → Insights"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": [],
            },
        ),
        card(
            id="F-046",
            title="Elevate Speak Engine Lab coaches",
            req_ids=["F-046", "F-046.D", "F-046.E", "F-046.U", "F-046.L"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT", "E-P6-SCORER"],
            tags=["shows_score"],
            file_allowlist=[
                "lib/screens/learning/speak_engine_lab_screen.dart",
                "lib/services/learning/code_switch_session_service.dart",
                "lib/services/learning/register_coach_service.dart",
            ],
            context_anchors=["ELEVATION.md#§18.4:L4155-L4169"],
            delta={
                "current_state": "Routed speak-engine-lab backed by code-switch and register coach services.",
                "defects_to_fix": ["Lab framing hides two distinct coach features."],
                "elevation_to_build": [
                    "Split Code-Switch Coach for natural mixed speech scored for naturalness.",
                    "Respect Coach rewrites for elder, peer, and child registers with honorifics.",
                ],
                "ux_and_render": ["Side-by-side casual vs respectful cards with audio beyond shared bar."],
                "hub_placement": "Speak → Practice → Code-Switch Coach / Respect Coach.",
                "unlock_stage": "per §17.4",
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given Speak → Practice, when Code-Switch Coach runs, then naturalness score comes from E-P6-SCORER after gateway evaluation.",
                },
                {
                    "id": "AC2",
                    "text": "Given Respect Coach, when the learner picks elder, peer, or child target, then rewritten sentences show honorific rules for the active language.",
                },
                {
                    "id": "AC3",
                    "text": "Given navigation, when the lab route opens, then two named coach entry points appear instead of a single experimental lab label.",
                },
            ],
            test_plan={
                "unit": ["register rewrite rules"],
                "integration": ["code switch scoring"],
                "e2e": ["Speak → Practice coaches"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": [],
            },
        ),
        card(
            id="F-047",
            title="Elevate Speak Missions",
            req_ids=["F-047", "F-047.D", "F-047.E", "F-047.U", "F-047.L", "P0-3"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT", "E-P6-SCORER"],
            tags=["shows_score"],
            p0_area=True,
            file_allowlist=["lib/screens/content/speak_mission_evaluate_screen.dart"],
            context_anchors=["ELEVATION.md#§18.4:L4170-L4181"],
            delta={
                "current_state": "UI records audio and calls Groq from client for evaluation.",
                "defects_to_fix": ["Client AI dependency.", "Evaluation not grounded in a rubric."],
                "elevation_to_build": [
                    "Weekly real-world speaking missions with rubric-based evaluation.",
                    "Optional share to circle; ties to Daily Challenges.",
                ],
                "ux_and_render": ["Mission checklist, recording sheet, and rubric feedback beyond shared bar."],
                "hub_placement": "Speak → Missions; Today → Challenges.",
                "unlock_stage": "per §17.4",
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given an active mission, when the learner submits a recording, then rubric feedback is returned via gateway using E-P6-SCORER criteria not ad-hoc client text.",
                },
                {
                    "id": "AC2",
                    "text": "Given Today challenges, when a weekly speak mission is live, then Speak → Missions and Today stay in sync on completion state.",
                },
                {
                    "id": "AC3",
                    "text": "Given release build, when evaluation runs, then no client Groq keys are present and failures show typed errors.",
                },
            ],
            test_plan={
                "unit": ["rubric mapping"],
                "integration": ["mission evaluation API"],
                "e2e": ["Speak → Missions"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": [],
            },
        ),
        card(
            id="F-048",
            title="Elevate Historical Personas",
            req_ids=["F-048", "F-048.D", "F-048.E", "F-048.U", "F-048.L", "P0-13", "P0-14", "P0-15"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT", "E-P11-PERSONAS-AVATARS"],
            tags=["enables_persona"],
            p0_area=True,
            external_blockers=["EXT-16"],
            file_allowlist=[
                "lib/screens/personalities/personality_selection_screen.dart",
                "lib/screens/personalities/personality_chat_screen.dart",
            ],
            context_anchors=["ELEVATION.md#§18.4:L4182-L4196"],
            delta={
                "current_state": "Routed historical personas with backend persona service safety and data issues.",
                "defects_to_fix": [
                    "Ungrounded answers and persona AI-disclosure violations (P0-13/14/15).",
                    "Incorrect persona metadata and empty source citations.",
                ],
                "elevation_to_build": [
                    "Grounded cited AI-disclosed personas with illustrated story chapters and target-language voice.",
                    "Historian review and curated collections.",
                ],
                "ux_and_render": [
                    "Rive portrait busts, sources drawer on every answer, AI recreation label beyond shared bar."
                ],
                "hub_placement": "Speak → Personas.",
                "unlock_stage": "per §17.4",
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given any persona answer, when text renders, then sources drawer lists citations and AI recreation label is visible.",
                },
                {
                    "id": "AC2",
                    "text": "Given gateway containment rules, when chat runs, then persona never denies being AI and avoids canned ungrounded fallbacks.",
                },
                {
                    "id": "AC3",
                    "text": "Given persona catalog, when selection opens, then metadata matches verified historian-reviewed records without known bad entries.",
                },
            ],
            test_plan={
                "unit": ["citation payload rendering"],
                "integration": ["persona gateway with containment"],
                "e2e": ["Speak → Personas chat"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": ["historian-reviewed sources"],
            },
        ),
        card(
            id="F-049",
            title="Elevate Persona Missions",
            req_ids=["F-049", "F-049.D", "F-049.E", "F-049.U", "F-049.L", "P0-13"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT", "E-P11-PERSONAS-AVATARS"],
            tags=["enables_persona"],
            p0_area=True,
            file_allowlist=[
                "lib/screens/persona_missions/persona_missions_hub_screen.dart",
                "lib/screens/persona_missions/persona_mission_setup_screen.dart",
                "lib/screens/persona_missions/persona_mission_session_screen.dart",
            ],
            context_anchors=["ELEVATION.md#§18.4:L4197-L4211"],
            delta={
                "current_state": "Routed mission UI with client Groq session calls failing silently in release.",
                "defects_to_fix": ["P0-13 canned fallback phrase instead of grounded dialogue."],
                "elevation_to_build": [
                    "Story-chapter missions with era scene, branching dialogue, cultural debrief with sources, and history-linked rewards.",
                ],
                "ux_and_render": ["Illustrated scene header, ambient audio, objective tracker beyond shared bar."],
                "hub_placement": "Speak → Personas → Missions.",
                "unlock_stage": "per §17.4",
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given an active persona mission session, when the learner speaks, then dialogue continues via gateway without the canned P0-13 fallback.",
                },
                {
                    "id": "AC2",
                    "text": "Given mission completion, when debrief shows, then cultural notes include sources and reward ties to persona history.",
                },
                {
                    "id": "AC3",
                    "text": "Given release build, when session AI fails, then typed error displays instead of silent Groq client failure.",
                },
            ],
            test_plan={
                "unit": ["mission branch state"],
                "integration": ["persona mission gateway"],
                "e2e": ["Speak → Personas → Missions"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": [],
            },
        ),
        card(
            id="F-050",
            title="Elevate LingChat AI conversation entry",
            hub="Village",
            req_ids=["F-050", "F-050.D", "F-050.E", "F-050.U", "F-050.L", "P0-3"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT", "F-035"],
            p0_area=True,
            size="S",
            token_budget=30000,
            difficulty={"score": 4, "blast": 0, "ambiguity": 1, "coupling": 2, "depth": 1, "size": 0},
            tiers={
                "worker": "T2",
                "tester": "T2",
                "reviewer": "T2",
                "justification": "score 4: thin chat entry reusing Polie engine",
            },
            file_allowlist=["lib/screens/chat/lingchat_ai_conversation_screen.dart"],
            context_anchors=["ELEVATION.md#§18.4:L4212-L4223"],
            delta={
                "current_state": "Thin routed wrapper duplicating Polie modes from Village chats.",
                "defects_to_fix": ["Duplicate Polie surface separate from consolidated engine."],
                "elevation_to_build": [
                    "Practice with Polie pinned DM from chat list reusing consolidated Polie engine.",
                    "Optional persona practice entry from chats.",
                ],
                "ux_and_render": ["Pinned chat contact with AI label beyond shared bar."],
                "hub_placement": "Village → Chats → pinned Polie (AI).",
                "unlock_stage": "per §17.4",
                "harvest_list": ["Retire duplicate logic in lingchat wrapper in favor of F-035 engine routes."],
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given Village → Chats, when Polie (AI) pinned contact opens, then session uses F-035 Polie engine not a separate Groq client wrapper.",
                },
                {
                    "id": "AC2",
                    "text": "Given release build, when chat practice starts, then no client API keys are bundled in lingchat_ai route.",
                },
                {
                    "id": "AC3",
                    "text": "Given persona practice from chat, when selected, then navigation lands in contained persona or Polie mode without duplicate transcripts.",
                },
            ],
            test_plan={
                "unit": ["chat deeplink to Polie"],
                "integration": ["pinned contact routing"],
                "e2e": ["Village → Polie AI chat"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": [],
            },
        ),
        card(
            id="F-051",
            title="Elevate Synthetic Voice Styles",
            req_ids=["F-051", "F-051.D", "F-051.E", "F-051.U", "F-051.L", "P0-24"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P6-SCORER"],
            tags=["tts_tonal"],
            p0_area=True,
            file_allowlist=["lib/screens/settings/synthetic_voice_styles_screen.dart"],
            context_anchors=["ELEVATION.md#§18.4:L4224-L4235"],
            delta={
                "current_state": "Routed voice styles using non-commercial MMS-TTS and removed-voice models.",
                "defects_to_fix": ["Non-commercial voice models violate licensing (P0-24)."],
                "elevation_to_build": [
                    "Commercial voice picker per language with preview, gender, region, speed.",
                    "Selected voice becomes Polie voice; clearly labelled synthetic.",
                ],
                "ux_and_render": ["Voice cards with play sample and region tag beyond shared bar."],
                "hub_placement": "Me → Settings → Voice; Speak → Polie settings.",
                "unlock_stage": "per §17.4",
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given yo/ig/ha voice lists, when the learner previews a voice, then only licensed commercial providers play and P0-24 models are removed.",
                },
                {
                    "id": "AC2",
                    "text": "Given a chosen voice, when Polie speaks, then the same voice id is used in Speak settings and Me → Voice.",
                },
                {
                    "id": "AC3",
                    "text": "Given tonal languages, when sample audio plays, then tone-safe output is validated via E-P6-SCORER tonal QA hooks.",
                },
            ],
            test_plan={
                "unit": ["voice provider allowlist"],
                "integration": ["Polie voice binding"],
                "e2e": ["Me → Voice picker"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": [],
            },
        ),
        card(
            id="F-052",
            title="Elevate Point and Say Lens",
            req_ids=["F-052", "F-052.D", "F-052.E", "F-052.U", "F-052.L", "P0-18", "P0-24"],
            depends_on=[
                "E-P2-PLATFORM",
                "E-P3-DESIGN-SYSTEM",
                "E-P1-CONTAINMENT",
                "E-P6-SCORER",
                "P7-908",
                "P7-912",
            ],
            tags=["shows_score"],
            p0_area=True,
            external_blockers=["EXT-13"],
            size="L",
            token_budget=200000,
            difficulty={"score": 7, "blast": 2, "ambiguity": 1, "coupling": 2, "depth": 2, "size": 0},
            tiers={
                "worker": "T3",
                "tester": "T2",
                "reviewer": "T3",
                "justification": "score 7: Lens vision, OCR, and real pronunciation scoring",
            },
            file_allowlist=[
                "lib/screens/ar/point_and_say_screen.dart",
                "lib/services/offline/point_and_say_queue_service.dart",
                "lib/services/media/media_import_service.dart",
                "lib/services/hybrid_polie/translation_service.dart",
            ],
            context_anchors=["ELEVATION.md#§18.4:L4236-L4245", "ELEVATION.md#§17.6:L2343-L2391"],
            delta={
                "current_state": "Routed point-and-say with ML Kit labels, unsafe translation chain, and placeholder tone scoring.",
                "defects_to_fix": [
                    "Free-text language entry causes typos.",
                    "Coarse English ML labels and non-commercial or anonymous translation.",
                    "No native audio; placeholder tone endpoint (P0-18).",
                    "Latin OCR mangling diacritics.",
                ],
                "elevation_to_build": [
                    "Lens pipeline: on-device boxes plus server vision for culturally grounded labels with confidence.",
                    "Word Cards with lexicon audio, Say step with GOP+tone overlay, FSRS collection and Home Safari quests.",
                    "OCR mode with diacritic restore; offline top-300 pack; privacy and minor photo rules.",
                ],
                "ux_and_render": [
                    "Full-screen camera with breathing boxes flipping to Word Card, profile language chip, haptics and avatar celebration.",
                    "Reduced-motion variant beyond shared bar.",
                ],
                "hub_placement": "Global Lens button; Learn/Speak contextual.",
                "unlock_stage": "per §17.4",
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given camera capture, when labels render, then learner profile language is used without free-text language field and grounded labels show confidence.",
                },
                {
                    "id": "AC2",
                    "text": "Given hold-to-speak on a Word Card, when scoring completes, then P7-908 Lens GOP+tone scores display and queue syncs via P7-912 offline path.",
                },
                {
                    "id": "AC3",
                    "text": "Given OCR on a sign, when text is recognized, then diacritic-aware pass runs and read-aloud uses verified lexicon or labelled synthetic audio.",
                },
                {
                    "id": "AC4",
                    "text": "Given non-commercial translation providers, when Lens translate runs, then only licensed commercial MT/TTS paths remain.",
                },
            ],
            test_plan={
                "unit": ["label confidence UI", "queue sync"],
                "integration": ["P7-908 scoring client", "P7-912 exists gate"],
                "e2e": ["Lens → Point and Say → speak feedback"],
                "a11y": ["goldens at 100%/200% text", "reduced_motion variant"],
                "content": ["Living Dictionary grounding"],
            },
        ),
        card(
            id="F-053",
            title="Elevate Live Translate Bridge",
            req_ids=["F-053", "F-053.D", "F-053.E", "F-053.U", "F-053.L", "P0-4", "P0-5"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT"],
            p0_area=True,
            external_blockers=["EXT-13"],
            difficulty={"score": 7, "blast": 2, "ambiguity": 1, "coupling": 2, "depth": 2, "size": 0},
            tiers={
                "worker": "T3",
                "tester": "T2",
                "reviewer": "T3",
                "justification": "score 7: two-party live ASR/MT bridge",
            },
            file_allowlist=[
                "lib/screens/live_translate/live_translate_screen.dart",
                "lib/services/live_translate/live_translate_client.dart",
            ],
            context_anchors=["ELEVATION.md#§18.4:L4246-L4263"],
            delta={
                "current_state": "Drawer live translate UI streaming on-device STT over Socket.IO.",
                "defects_to_fix": [
                    "On-device STT fails for major African source languages.",
                    "Socket inherits P0-4/5 auth weaknesses.",
                ],
                "elevation_to_build": [
                    "Conversation Bridge: turn-taking two-language session with server ASR and commercial MT.",
                    "Tone Lens per turn and saved mini-lesson transcript.",
                ],
                "ux_and_render": [
                    "Split-screen facing layout, large mic buttons, confidence indicator beyond shared bar."
                ],
                "hub_placement": "Global Lens → Bridge; Speak → Practice.",
                "unlock_stage": "per §17.4",
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given Yoruba or Igbo as a source language, when a turn is recorded, then server ASR transcribes instead of unsupported on-device recognizer.",
                },
                {
                    "id": "AC2",
                    "text": "Given each translated turn, when text displays, then Tone Lens and learn-this-phrase actions appear and transcript saves as a lesson.",
                },
                {
                    "id": "AC3",
                    "text": "Given socket connection, when live translate runs, then P0-4/5 hardened auth is enforced without silent mock transcripts.",
                },
            ],
            test_plan={
                "unit": ["turn state machine"],
                "integration": ["live_translate_client gateway ASR"],
                "e2e": ["Lens Bridge two-party flow"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": [],
            },
        ),
        card(
            id="F-054",
            title="Elevate Import Media OCR and clips",
            req_ids=["F-054", "F-054.D", "F-054.E", "F-054.U", "F-054.L"],
            depends_on=["E-P2-PLATFORM", "E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT", "E-P5-CONTENT-REAL"],
            file_allowlist=[
                "lib/screens/media/import_media_screen.dart",
                "lib/screens/media/media_clip_player_screen.dart",
                "lib/services/media/media_import_service.dart",
            ],
            context_anchors=["ELEVATION.md#§18.4:L4264-L4280"],
            delta={
                "current_state": "Routed import media with ML Kit Latin OCR and backend transcription generation.",
                "defects_to_fix": [
                    "Latin OCR mangles stacked tone marks.",
                    "Generated learning content lacks review status.",
                ],
                "elevation_to_build": [
                    "Import songs, voice notes, or photos into personal lessons with transcript, glosses, Tone Lens, flashcards, and shadowing clip.",
                    "Server diacritic-aware OCR; private by default with copyright notice on share.",
                ],
                "ux_and_render": ["Import sheet with honest processing steps beyond shared bar."],
                "hub_placement": "Global Lens → Import; share-sheet target.",
                "unlock_stage": "per §17.4",
            },
            acceptance_criteria=[
                {
                    "id": "AC1",
                    "text": "Given an imported image with tone marks, when OCR completes, then diacritic-aware server pass preserves stacked marks or shows honest low-confidence state.",
                },
                {
                    "id": "AC2",
                    "text": "Given imported audio, when lesson generation finishes, then flashcards and shadowing clip carry content labels and review state from E-P5-CONTENT-REAL.",
                },
                {
                    "id": "AC3",
                    "text": "Given share attempt, when user confirms, then copyright notice appears and default remains private.",
                },
            ],
            test_plan={
                "unit": ["import pipeline steps UI"],
                "integration": ["media_import_service backend OCR"],
                "e2e": ["Lens Import share target"],
                "a11y": ["goldens at 100%/200% text", "semantics"],
                "content": ["generated lesson labelling"],
            },
        ),
    ]
    for c in cards:
        path = OUT / f"{c['id']}.yaml"
        with path.open("w") as f:
            yaml.dump(c, f, default_flow_style=False, sort_keys=False, allow_unicode=True, width=120)
    print(f"Wrote {len(cards)} cards to {OUT}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""One-off generator for P8 play slice A feature cards (charter: v2)."""
from __future__ import annotations

import textwrap
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/build/cards/P8"

BASE_DEPS = ["E-P8-PLAY", "E-P3-DESIGN-SYSTEM", "E-P2-PLATFORM"]
GAME_DEPS = ["P8-900", "P8-912"] + BASE_DEPS

UX = {
    "states": ["skeleton", "empty", "error", "offline", "ai_unavailable", "under_review"],
    "tokens": ["design-system only"],
    "motion_tier": "product",
    "a11y": ["semantics", "reduced_motion", "200% text"],
    "goldens": ["light", "dark"],
}


def card(d: dict) -> str:
    d = dict(d)
    d["charter"] = "v2"
    d["inherits"] = "FEATURE_BASE"
    d["gate"] = "HUB"
    d["status"] = "Draft"
    d["user_facing"] = True
    d.setdefault("risks", [])
    d.setdefault("external_blockers", [])
    d.setdefault("dod_evidence", [
        "tester report",
        "goldens diff",
        "coverage on touched domain code",
        "ledger row",
    ])
    return yaml.dump(d, sort_keys=False, allow_unicode=True, width=120)


def game_ux(slug: str) -> dict:
    u = dict(UX)
    u["copy_keys"] = [f"{slug}.*"]
    return u


def mk(
    fid: str,
    title: str,
    anchor: str,
    files: list[str],
    *,
    depends: list[str],
    current: str,
    defects: list[str],
    elevation: list[str],
    ux: list[str],
    hub_placement: str,
    harvest: list[str] | None = None,
    tags: list[str] | None = None,
    p0: bool = False,
    extra_req: list[str] | None = None,
    size: str = "M",
    score: int = 5,
    ext: list[str] | None = None,
    acs: list[tuple[str, str]],
) -> dict:
    parts = {"blast": 1, "ambiguity": 1, "coupling": 2, "depth": 1, "size": 0}
    if score == 6:
        parts["depth"] = 2
    elif score == 7:
        parts = {"blast": 2, "ambiguity": 1, "coupling": 2, "depth": 2, "size": 0}
    worker = "T3" if score >= 7 else "T2"
    reviewer = "T3" if score >= 7 or p0 else "T2"
    slug = fid.lower().replace("-", "_")
    req = [fid, f"{fid}.D", f"{fid}.E", f"{fid}.U", f"{fid}.L"] + (extra_req or [])
    delta = {
        "current_state": current,
        "defects_to_fix": defects,
        "elevation_to_build": elevation,
        "ux_and_render": ux,
        "hub_placement": hub_placement,
        "unlock_stage": "per §17.4",
    }
    if harvest:
        delta["harvest_list"] = harvest
    return {
        "id": fid,
        "kind": "feature",
        "title": f"Elevate {title}",
        "phase": "P8",
        "epic": "E-P8-PLAY",
        "hub": "Play",
        "req_ids": req,
        "depends_on": depends,
        "size": size,
        "difficulty": {"score": score, **parts},
        "tiers": {
            "worker": worker,
            "tester": "T2",
            "reviewer": reviewer,
            "justification": f"score {score}: {parts['blast']} blast, coupling {parts['coupling']}",
        },
        "token_budget": 80000 if size == "M" else (200000 if size == "L" else 30000),
        "file_allowlist": [f"lib/{p}" if not p.startswith("lib/") else p for p in files[:12]],
        "context_anchors": [anchor],
        "delta": delta,
        "acceptance_criteria": [{"id": f"AC{i+1}", "text": t} for i, (_, t) in enumerate(acs)],
        "test_plan": {
            "unit": ["game rules", "content binding"],
            "integration": ["GameKit session", "learner model writeback"],
            "e2e": ["Play shelf launch to results"],
            "a11y": ["goldens at 100%/200% text", "semantics"],
            "content": ["lexicon pool has audio for target language"],
        },
        "ux_spec": game_ux(slug.replace("f_", "")),
        "tags": tags or [],
        "p0_area": p0,
    }


CARDS: list[dict] = []

CARDS.append(
    mk(
        "F-055",
        "Games Arcade (hub & catalogue)",
        "ELEVATION.md#§18.5:L4281-L4302",
        [
            "screens/games/games_screen_material3.dart",
            "screens/games/games_screen.dart",
            "screens/games/games_enhanced_with_all_games.dart",
            "screens/games/game_catalog.dart",
            "screens/games/game_router.dart",
            "screens/games/language_games_screen.dart",
            "screens/games/language_games_screen_components.dart",
            "screens/games/lazy_game_list.dart",
        ],
        depends=BASE_DEPS,
        current="Three routed catalogues work; parallel unrouted language_games and lazy_list variants remain.",
        defects=[
            "Three competing catalogues fragment discovery.",
            "Play hub does not reliably update the learner model after sessions.",
        ],
        elevation=[
            "Single Arcade with skill shelves including For you today, Tone and Sound, Words, Grammar, Speaking, Culture, Traditional, Multiplayer, Classroom.",
            "Each card shows trained skill and learner mastery; lazy loading retained.",
        ],
        ux=[
            "Shelf layout with unified game art, skill chips, New and Event ribbons.",
        ],
        hub_placement="Play tab (root).",
        harvest=[
            "Route language_games_screen variants into the unified Arcade.",
            "Keep lazy_game_list as the loading strategy inside one catalogue.",
        ],
        size="L",
        score=6,
        acs=[
            (
                "AC1",
                "Given a signed-in learner, when they open Play, then one Arcade shows all shelves and no alternate catalogue route remains reachable.",
            ),
            (
                "AC2",
                "Given a completed game session, when the learner returns to the Arcade, then mastery chips on that game reflect the learner model update.",
            ),
            (
                "AC3",
                "Given lazy loading, when a shelf scrolls, then games load incrementally without blocking the Play tab.",
            ),
        ],
    )
)

CARDS.append(
    mk(
        "F-056",
        "Game shell, guides & results (revived)",
        "ELEVATION.md#§18.5:L4303-L4322",
        [
            "screens/games/templates/game_template_shell.dart",
            "screens/games/game_onboarding_overlay.dart",
            "screens/games/game_start_guide_screen.dart",
            "screens/games/game_mastery_results_screen.dart",
            "screens/games/victory_results_screen.dart",
            "screens/games/universal_loading_screen.dart",
            "screens/games/universal_game_screen.dart",
            "screens/games/templates/template_timed_quiz.dart",
        ],
        depends=["P8-900"] + BASE_DEPS,
        current="Overlay and shell work; mastery results exist but start guide, victory, universal screens and templates are unrouted.",
        defects=[
            "Results screens differ per game with no shared mastery feedback.",
        ],
        elevation=[
            "One GameKit frame with ~10s first-play how-to from the start guide.",
            "Mastery results show improved words and skills, mistake replay with audio, add-to-review, replay; every game reports to the learner model.",
        ],
        ux=[
            "Consistent header with timer, score, quit; skill bars on results; confetti only on personal bests.",
        ],
        hub_placement="Inside every game.",
        harvest=[
            "Wire game_start_guide_screen, victory_results, universal_loading, universal_game_screen and timed quiz template into GameKit.",
            "Standardize on game_mastery_results_screen for all games.",
        ],
        acs=[
            (
                "AC1",
                "Given first launch of any game, when the session starts, then a skippable how-to plays once and routes through GameKit.",
            ),
            (
                "AC2",
                "Given a finished round, when results appear, then the mastery screen lists skill deltas, mistakes with audio, and add-to-review actions.",
            ),
            (
                "AC3",
                "Given any game completion, when the session ends, then learner model receives a verified play event without swallowed errors.",
            ),
        ],
    )
)

GAME_META = [
    (
        "F-057",
        "Word Match",
        "L4323-L4336",
        ["screens/games/word_match_game.dart"],
        "Play → Words shelf.",
        [],
        [],
        [
            "Due-word driven pairs with audio on every tap.",
            "Tone-twin round contrasts words differing only in tone.",
        ],
        [],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given due words in the learner model, when Word Match starts, then turns prioritize due items before filler pool words.",
            ),
            (
                "AC2",
                "Given a tone-twin round, when the learner selects a card, then both minimal-pair words play audio and the correct tone match is scored.",
            ),
            (
                "AC3",
                "Given session end, when results show, then GameKit mastery lists updated vocabulary skills.",
            ),
        ],
    ),
    (
        "F-058",
        "Word Match (audio)",
        "L4337-L4350",
        ["screens/games/word_match_audio_game.dart"],
        "Play → Tone & Sound shelf.",
        [],
        [],
        [
            "Listening-first flow: hear prompt, then match meaning.",
            "Speaker voices rotate regions to build accent tolerance.",
        ],
        [],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given a round start, when any target-language prompt appears, then audio plays automatically before choices unlock.",
            ),
            (
                "AC2",
                "Given multiple sessions, when audio plays, then speaker region rotates across turns per session policy.",
            ),
            (
                "AC3",
                "Given completion, when results render, then they use the shared GameKit mastery screen.",
            ),
        ],
    ),
    (
        "F-059",
        "Fill in the Blank",
        "L4351-L4363",
        ["screens/games/fill_in_the_blank_game.dart"],
        "Play → Grammar shelf.",
        [],
        [],
        [
            "Cloze items from real dialogues with diacritic-aware input.",
            "Hint action replays line audio without revealing the answer.",
        ],
        [],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given a cloze item, when the learner types an answer, then diacritics are validated and incorrect marks show typed vs expected.",
            ),
            (
                "AC2",
                "Given the learner taps Hint, when audio plays, then the blank text stays hidden.",
            ),
            (
                "AC3",
                "Given session end, when results show, then grammar skills updated reflect dialogue source tags.",
            ),
        ],
    ),
    (
        "F-060",
        "Picture–Word Association",
        "L4364-L4377",
        ["screens/games/picture_word_association_screen.dart"],
        "Play → Words shelf.",
        [],
        ["shows_score"],
        [
            "Culturally reviewed illustrations for local foods, clothing, and places.",
            "Say-it bonus awards points only when speech scorer returns a verified result.",
        ],
        ["E-P6-SCORER"],
        6,
        "M",
        ["EXT-16"],
        False,
        None,
        [
            (
                "AC1",
                "Given illustration assets missing for a word, when the game loads, then the card shows content-under-review rather than a placeholder image.",
            ),
            (
                "AC2",
                "Given say-it bonus with scorer unavailable, when the learner finishes, then UI shows practice mode with no numeric pronunciation score.",
            ),
            (
                "AC3",
                "Given scorer available, when speech is verified, then bonus points match server-side scoring only.",
            ),
        ],
    ),
    (
        "F-061",
        "Memory Map",
        "L4392-L4405",
        ["screens/games/memory_map_screen.dart"],
        "Play → Words shelf.",
        [],
        [],
        [
            "Flip-to-hear audio cards for each pair.",
            "Family-themed decks foreground kinship vocabulary for heritage learners.",
        ],
        [],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given a face-down card, when the learner flips it, then target-language audio plays before the match check.",
            ),
            (
                "AC2",
                "Given family deck selected, when pairs deal, then kinship terms draw from the lexicon pool with audio.",
            ),
            (
                "AC3",
                "Given a completed board, when results show, then matched words appear on the mastery summary.",
            ),
        ],
    ),
    (
        "F-062",
        "Speed Challenge",
        "L4406-L4419",
        ["screens/games/speed_challenge_game.dart"],
        "Play → Words shelf.",
        [],
        [],
        [
            "Adaptive pacing targets 80–85% success rate.",
            "Calm mode removes the timer for accessibility.",
        ],
        [],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given adaptive mode, when accuracy drifts below 80%, then question interval lengthens until success rate returns toward 85%.",
            ),
            (
                "AC2",
                "Given calm mode enabled, when a session runs, then no countdown timer is shown and scoring still completes.",
            ),
            (
                "AC3",
                "Given session end, when results show, then vocabulary skills reflect timed performance.",
            ),
        ],
    ),
    (
        "F-063",
        "Speed Round",
        "L4420-L4433",
        ["screens/games/speed_round_game.dart", "screens/games/speed_challenge_game.dart"],
        "Play → Words shelf.",
        ["Merge Speed Round mechanics into Speed Challenge as Sprint and Rounds modes."],
        [],
        [
            "Expose Sprint and Rounds as two modes inside one Speed Challenge entry.",
        ],
        [],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given the Words shelf, when the learner opens Speed Challenge, then mode picker offers Sprint and Rounds without a separate Speed Round route.",
            ),
            (
                "AC2",
                "Given Rounds mode, when a round completes, then scoring and results match GameKit standards.",
            ),
            (
                "AC3",
                "Given legacy Speed Round deep links, when opened, then they redirect to Rounds mode inside Speed Challenge.",
            ),
        ],
    ),
    (
        "F-064",
        "Story Builder",
        "L4434-L4447",
        ["screens/games/story_builder_game.dart"],
        "Play → Grammar shelf.",
        [],
        ["under18_social"],
        [
            "Build illustrated audio stories from the learner level.",
            "Finished stories can be shared to circles with safety controls.",
        ],
        ["E-P9-SAFETY"],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given learner level data, when a story generates, then sentence order pulls from level-appropriate dialogue content with audio.",
            ),
            (
                "AC2",
                "Given a completed story, when the learner shares to a circle, then under-18 safety policies gate visibility before send.",
            ),
            (
                "AC3",
                "Given share blocked, when the learner attempts send, then an honest error explains the policy block.",
            ),
        ],
    ),
    (
        "F-065",
        "Grammar Detective",
        "L4448-L4461",
        ["screens/games/grammar_detective_game.dart"],
        "Play → Grammar shelf.",
        [],
        [],
        [
            "Village mystery framing for grammar cases.",
            "Each solved case unlocks a Pattern Library card.",
        ],
        [],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given a mystery case, when the learner finds the error, then feedback cites the grammar pattern involved.",
            ),
            (
                "AC2",
                "Given a solved case, when results confirm success, then a Pattern Library card unlocks in the learner profile.",
            ),
            (
                "AC3",
                "Given wrong accusation, when the learner submits, then mistake audio replays without fake success.",
            ),
        ],
    ),
    (
        "F-066",
        "Grammar Jam",
        "L4462-L4475",
        ["screens/games/grammar_jam_screen.dart"],
        "Play → Grammar shelf.",
        [],
        [],
        [
            "Rhythm-paced sentence building over commissioned Afrobeats or amapiano beds.",
            "Beat cadence follows syllable timing in the target language.",
        ],
        [],
        6,
        "M",
        ["EXT-13"],
        False,
        None,
        [
            (
                "AC1",
                "Given licensed beat assets loaded, when gameplay runs, then sentence slots advance on syllable-aligned beats.",
            ),
            (
                "AC2",
                "Given beat assets unavailable, when the learner starts, then an offline-safe rhythm fallback plays without silent failure.",
            ),
            (
                "AC3",
                "Given session completion, when results show, then grammar skills update through GameKit.",
            ),
        ],
    ),
    (
        "F-067",
        "Greeting Diplomacy",
        "L4476-L4491",
        ["screens/games/greeting_diplomacy_screen.dart"],
        "Play → Culture shelf.",
        [],
        ["enables_persona"],
        [
            "Evolve into Greeting Gauntlet with time, person, and setting matrix.",
            "Avatar gestures accompany spoken answer options.",
        ],
        [],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given a scenario, when choices render, then time-of-day, addressee, and setting are all visible context chips.",
            ),
            (
                "AC2",
                "Given an answer selection, when audio plays, then the learner avatar performs the matching gesture.",
            ),
            (
                "AC3",
                "Given incorrect greeting, when submitted, then feedback explains the cultural mismatch.",
            ),
        ],
    ),
    (
        "F-068",
        "Market Bargaining",
        "L4492-L4505",
        ["screens/games/market_bargaining_screen.dart"],
        "Play → Speaking shelf.",
        [],
        ["shows_score"],
        [
            "Market Haggle voice roleplay with distinct trader personalities.",
            "Numbers practice plus politeness scoring from real speech analysis.",
        ],
        ["E-P6-SCORER"],
        7,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given haggle turn, when the learner speaks an offer, then mic capture runs and no random price acceptance occurs without recognized speech.",
            ),
            (
                "AC2",
                "Given scorer unavailable, when politeness would be scored, then UI shows practice mode without fabricated politeness percent.",
            ),
            (
                "AC3",
                "Given scorer available, when a bargain completes, then politeness and numeric accuracy scores come from verified scorer output.",
            ),
        ],
    ),
    (
        "F-069",
        "Quiz Chef",
        "L4506-L4519",
        ["screens/games/quiz_chef_screen.dart"],
        "Play → Culture shelf.",
        [],
        [],
        [
            "Recipe lessons for dishes like jollof, egusi, ugali, or chakalaka.",
            "Learner follows spoken instructions in the target language step by step.",
        ],
        [],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given a recipe step, when instructions play, then target-language audio precedes interactive choices.",
            ),
            (
                "AC2",
                "Given wrong ingredient order, when submitted, then feedback references the spoken step without fake success.",
            ),
            (
                "AC3",
                "Given recipe completion, when results show, then culture and listening skills update in the learner model.",
            ),
        ],
    ),
    (
        "F-070",
        "Roleplay Adventure",
        "L4520-L4534",
        ["screens/games/roleplay_adventure_game.dart"],
        "Play → Speaking shelf.",
        [],
        [],
        [
            "Share Scenario Theatre engine for multi-scene trips.",
            "Adventures chain locations such as Lagos, Ibadan, and Ọ̀ṣogbo.",
        ],
        [],
        6,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given an adventure start, when scenes progress, then branching uses Scenario Theatre state rather than isolated hard-coded paths.",
            ),
            (
                "AC2",
                "Given a scene transition, when the learner continues, then location metadata and audio update consistently.",
            ),
            (
                "AC3",
                "Given adventure completion, when results show, then speaking skills reflect multi-scene performance.",
            ),
        ],
    ),
    (
        "F-071",
        "Taxi Survival",
        "L4535-L4550",
        ["screens/games/taxi_survival_screen.dart"],
        "Play → Tone & Sound shelf.",
        [],
        [],
        [
            "Rebrand as Danfo or Matatu Rush with native-speed conductor calls.",
            "Learner boards the correct bus from recorded announcements.",
        ],
        [],
        6,
        "M",
        ["EXT-13"],
        False,
        None,
        [
            (
                "AC1",
                "Given a rush scenario, when conductor audio plays, then clips are native-speed recordings tagged by route.",
            ),
            (
                "AC2",
                "Given multiple bus options, when the learner selects, then correctness uses announcement content not random success.",
            ),
            (
                "AC3",
                "Given completion, when results show, then listening skills update via GameKit.",
            ),
        ],
    ),
    (
        "F-072",
        "Tone Trainer",
        "L4551-L4565",
        ["screens/games/tone_trainer_game.dart"],
        "Play → Tone & Sound shelf.",
        [],
        ["shows_score", "tts_tonal"],
        [
            "Per-language tone inventories with minimal pairs and recorded audio.",
            "Progress feeds the Tone Gym ladder with honest per-language rules.",
        ],
        ["E-P6-SCORER"],
        6,
        "M",
        [],
        True,
        ["P0-17"],
        [
            (
                "AC1",
                "Given Swahili selected, when Tone Trainer loads, then no High-Mid-Low lexical tone UI is shown.",
            ),
            (
                "AC2",
                "Given Igbo with downstep pairs, when a minimal pair plays, then scoring uses language-specific tone inventory not a global HML template.",
            ),
            (
                "AC3",
                "Given session completion, when results show, then Tone Gym ladder progress updates from verified tone identification.",
            ),
        ],
    ),
    (
        "F-073",
        "Pronunciation Duel",
        "L4566-L4580",
        ["screens/games/pronunciation_duel_game.dart"],
        "Play → Speaking shelf.",
        [],
        ["shows_score", "under18_social"],
        [
            "Real mic capture and scorer-backed duels on minimal pairs.",
            "Async friend duels; practice mode without score until scorer ships.",
        ],
        ["E-P6-SCORER", "E-P9-SAFETY"],
        7,
        "M",
        [],
        True,
        ["P0-18"],
        [
            (
                "AC1",
                "Given duel mode before scorer ready, when the learner finishes, then no random 75–95% score appears and practice mode copy is shown.",
            ),
            (
                "AC2",
                "Given scorer ready, when both players submit recordings, then winner uses verified pronunciation scores only.",
            ),
            (
                "AC3",
                "Given under-18 account, when inviting a friend duel, then safety policies gate matchmaking before the invite sends.",
            ),
        ],
    ),
    (
        "F-074",
        "Pronunciation Game",
        "L4581-L4596",
        ["screens/games/pronunciation_game.dart"],
        "Play → Speaking shelf.",
        ["Fold pronunciation_game rounds into Tone Gym ladder as a game mode."],
        ["shows_score"],
        [
            "Merge rounds into Tone Gym ladder as a dedicated mode.",
            "All scoring paths use verified pronunciation analysis.",
        ],
        ["E-P6-SCORER"],
        7,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given Tone Gym entry, when the learner selects pronunciation mode, then rounds formerly in pronunciation_game run inside the ladder.",
            ),
            (
                "AC2",
                "Given unscored recording path, when a round ends, then UI shows honest unavailable scoring not fabricated percentages.",
            ),
            (
                "AC3",
                "Given verified scoring, when results show, then ladder tier progress updates from server events.",
            ),
        ],
    ),
    (
        "F-075",
        "Pronunciation Karaoke",
        "L4581-L4596",
        ["screens/games/pronunciation_karaoke_screen.dart"],
        "Play → Speaking shelf.",
        [],
        ["shows_score"],
        [
            "Echo Karaoke with real F0 contour overlay.",
            "Licensed songs plus children's rhymes and praise phrases.",
        ],
        ["E-P6-SCORER"],
        7,
        "M",
        ["EXT-13"],
        True,
        ["P0-18"],
        [
            (
                "AC1",
                "Given karaoke mode before pitch analysis ships, when the learner sings, then no 60–95 random pitch score displays.",
            ),
            (
                "AC2",
                "Given scorer available, when performance completes, then F0 line compares learner trace to reference honestly.",
            ),
            (
                "AC3",
                "Given licensed track selected, when playback starts, then only licensed assets play or content-under-review shows.",
            ),
        ],
    ),
    (
        "F-076",
        "Emoji Translator",
        "L4597-L4610",
        ["screens/games/emoji_translator_screen.dart"],
        "Play → Words shelf.",
        [],
        ["under18_social"],
        [
            "Emoji stories convert to target-language sentences.",
            "Send finished sentence as a chat sticker from the learner avatar.",
        ],
        ["E-P9-SAFETY"],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given emoji sequence, when translation completes, then sentence uses lexicon-backed words with audio preview.",
            ),
            (
                "AC2",
                "Given send-to-chat, when under-18 policies block sticker share, then send is blocked with visible reason.",
            ),
            (
                "AC3",
                "Given allowed share, when sticker sends, then payload contains no PII beyond avatar identity token.",
            ),
        ],
    ),
    (
        "F-077",
        "Elders' Blessings",
        "L4611-L4625",
        ["screens/games/elders_blessings_screen.dart"],
        "Play → Culture shelf.",
        [],
        ["enables_persona"],
        [
            "Elder avatar delivers blessings for life events like birth, marriage, or travel.",
            "Learner responds with culturally reviewed lines from consultants.",
        ],
        [],
        5,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given a life event scenario, when blessing plays, then elder avatar animation and audio match reviewed content labels.",
            ),
            (
                "AC2",
                "Given learner response options, when one is chosen, then feedback cites cultural appropriateness not random success.",
            ),
            (
                "AC3",
                "Given content pending review, when scenario loads, then content-under-review state shows instead of placeholder copy.",
            ),
        ],
    ),
    (
        "F-078",
        "Folktale Reconstruction",
        "L4626-L4639",
        ["screens/games/folktale_reconstruction_screen.dart"],
        "Play → Culture shelf.",
        [],
        ["shows_score"],
        [
            "Àlọ́, hadithi, and iintsomi tales rebuild then learner narrates with scoring.",
            "Tale sources come from the Living Archive not the thin word pool.",
        ],
        ["E-P6-SCORER", "E-P5-CONTENT-REAL"],
        7,
        "M",
        [],
        False,
        None,
        [
            (
                "AC1",
                "Given a tale from Living Archive, when scenes shuffle, then reorder checks use archive metadata and illustrations.",
            ),
            (
                "AC2",
                "Given narration phase with scorer unavailable, when recording finishes, then UI shows practice mode without fabricated narration score.",
            ),
            (
                "AC3",
                "Given scorer available, when narration completes, then pronunciation score reflects verified analysis only.",
            ),
        ],
    ),
]

COMMON_DEFECTS = [
    "Thin static word pool without reliable audio.",
    "No learner-model writeback after play.",
    "Legacy per-game results instead of GameKit mastery.",
    "Hard-coded UI strings bypass l10n.",
]

COMMON_UX = [
    "GameKit frame with unified illustration style and audio on every target-language item.",
    "Reduced-motion variant respects system setting.",
]

for row in GAME_META:
    (
        fid,
        title,
        lines,
        files,
        hub,
        harvest,
        tags,
        elevation,
        extra_deps,
        score,
        size,
        ext,
        p0,
        extra_req,
        acs,
    ) = row
    if fid == "F-078":
        deps = ["P8-900"] + BASE_DEPS + list(extra_deps)
    else:
        deps = list(GAME_DEPS) + list(extra_deps)
    c = mk(
        fid,
        title,
        f"ELEVATION.md#§18.5:{lines}",
        files,
        depends=deps,
        current="Routed from Arcade via game_router; content still uses the legacy 85–118 word pool without audio.",
        defects=list(COMMON_DEFECTS),
        elevation=elevation,
        ux=COMMON_UX,
        hub_placement=hub,
        harvest=harvest or None,
        tags=tags,
        p0=p0,
        extra_req=extra_req,
        size=size,
        score=score,
        ext=ext,
        acs=acs,
    )
    if ext:
        c["external_blockers"] = ext
    CARDS.append(c)

for c in CARDS:
    path = OUT / f"{c['id']}.yaml"
    path.write_text(card(c), encoding="utf-8")

print(f"wrote {len(CARDS)} cards to {OUT}")

#!/usr/bin/env python3
"""Audit consolidation harvest lists and leftover variant imports.

Reads the harvest_list entries on P3-065 through P3-070 and writes
docs/build/design/HARVEST_REPORT.md. Each listed part is Moved, Dropped,
Kept, or Unresolved. Dropped text is copied from the source card. Approver
is Unrecorded. P3-072 stays Draft because this repo has no human approver.

The scan reads import, export, and part directives under lib/. A file a
consolidation card said was deleted or moved under legacy/ still imported
from lib/ exits 1 and the report names that import. Template files P3-068
kept, because a test or BaseGameScreen still imports them, are Kept and do
not fail the run. Product files are not deleted or moved.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
CARD_IDS = ("P3-065", "P3-066", "P3-067", "P3-068", "P3-069", "P3-070")
CARD_DIR = ROOT / "docs" / "build" / "cards" / "P3"
DEFAULT_OUT = ROOT / "docs" / "build" / "design" / "HARVEST_REPORT.md"
STATUSES = ("Moved", "Dropped", "Kept", "Unresolved")

# Files the cards said were deleted, plus variant filenames that now live
# under legacy/. Basename match is exact, so ai_chat_screen.dart does not
# match ai_chat_screen_new.dart, and onboarding_screen.dart does not match
# unified_onboarding_screen.dart.
REMOVED_BASENAMES = {
    "ai_chat_screen.dart": "P3-065: already deleted in 514e70e1 and had no route.",
    "ai_chat_screen_new.dart": "P3-065: already deleted in 514e70e1 and had no route.",
    "ai_chat_screen_with_tracking.dart": "P3-065: already deleted in 514e70e1 and had no route.",
    "conversation_enhanced_screen.dart": "P3-065: already deleted in 514e70e1 and had no route.",
    "ai_mode_selection_screen.dart": "P3-065: moved to legacy/ai_chat/.",
    "enhanced_onboarding_flow_screen.dart": (
        "File is under legacy/onboarding/. P3-067 does not say moved to legacy."
    ),
    "kijiji_onboarding_screen.dart": (
        "File is under legacy/onboarding/. P3-067 does not say moved to legacy."
    ),
    "modern_onboarding_screen.dart": (
        "File is under legacy/onboarding/. P3-067 does not say moved to legacy."
    ),
    "onboarding_screen.dart": (
        "File is under legacy/onboarding/. P3-067 does not say moved to legacy."
    ),
    "onboarding_screen_material3.dart": (
        "File is under legacy/onboarding/. P3-067 does not say moved to legacy."
    ),
    "create_quiz_screen_enhanced.dart": "P3-070: quiz enhanced file is deleted.",
    "create_story_screen_enhanced.dart": "P3-070: story enhanced file is deleted.",
}

# P3-069 says the old tablet file was deleted. The surviving catalog names
# this path. The GameKit file games/proverb_unlocker/proverb_unlocker_game.dart
# does not contain this marker and is not a failure.
OLD_TABLET_MARKER = "cultural/proverb_unlocker_game.dart"

# P3-068 kept these because the shell test still builds GameTemplateShell
# and BaseGameScreen still imports the shell. A lib/ reference is Kept.
KEPT_TEMPLATE_BASENAMES = {
    "game_template_shell.dart",
    "template_match_board.dart",
    "template_narrative.dart",
    "template_pronunciation.dart",
    "template_rhythm.dart",
    "template_strategic.dart",
    "template_timed_quiz.dart",
}

DIRECTIVE_RE = re.compile(
    r"""^\s*(?:import|export|part)\s+(?!of\b)['"]([^'"]+)['"]"""
)


def row(card: str, item: str, entry: str, status: str, text: str) -> dict[str, str]:
    if status not in STATUSES:
        raise ValueError(status)
    if status == "Dropped" and not text.strip():
        raise ValueError(f"dropped row needs the card's reason: {entry}")
    return {
        "card": card,
        "item": item,
        "entry": entry,
        "status": status,
        "text": text,
        "approver": "Unrecorded" if status == "Dropped" else "n/a",
    }


def _p065() -> list[dict[str, str]]:
    card = "P3-065"
    best = "best parts of each: tracking hooks, mode selection, enhanced conversation controls"
    deleted = "Already deleted in 514e70e1 and had no route."
    rows = [
        row(card, "ai_chat_screen.dart", "ai_chat_screen.dart", "Dropped", deleted),
        row(card, "ai_chat_screen_new.dart", "ai_chat_screen_new.dart", "Dropped", deleted),
        row(
            card,
            "ai_chat_screen_with_tracking.dart",
            "ai_chat_screen_with_tracking.dart",
            "Dropped",
            deleted,
        ),
        row(
            card,
            "conversation_enhanced_screen.dart",
            "conversation_enhanced_screen.dart",
            "Dropped",
            deleted,
        ),
        row(
            card,
            "ai_mode_selection_screen.dart",
            "ai_mode_selection_screen.dart",
            "Moved",
            "Moved to legacy/ai_chat/ after ai_chat_select started building the Polie workspace.",
        ),
    ]
    harvested = (
        "legacy mode-id map",
        "Surprise Me limited to modes that have a panel",
        "Conversation on the mode rail",
        "progress button for the tracking dashboards",
        "conversation turn counts and session record on leave",
        "tutor keyword notes merged into the existing tutor session",
        "roleplay turn notes",
        "auto-correction toggle",
        "topic chips from conversation analytics with the enhanced-screen fallback",
    )
    for entry in harvested:
        rows.append(row(card, best, entry, "Moved", entry))
    dropped = (
        "ai_chat_screen.dart tracking, mode selection, and enhanced controls are not present in the variant. Same route as Polie mode conversation.",
        "ai_chat_screen_new.dart per-mode HTTP bodies are the same route as the Polie mode surfaces, which already call the gateway.",
        "Grammar and pronunciation stay off the rail because the workspace panel for those modes is empty.",
        "Assessment is the same route as Polie mode review.",
        "Empty-state starter chips in the tracking chat are the same route as the mode intro banners.",
        "The tracking screen's corrections list was never appended to.",
        "A second correction prompt was not copied, because it would add another user turn.",
        "Roleplay completion navigation stays on the roleplay scenario flow.",
        "Vocab free-text addWord was not copied, because scoreSrs already stores the card.",
    )
    for entry in dropped:
        rows.append(row(card, best, entry, "Dropped", entry))
    return rows


def _p066() -> list[dict[str, str]]:
    card = "P3-066"
    ideas = "roster, notes, assignments, privacy and speaker queue ideas from the variants"
    rows: list[dict[str, str]] = []

    def add(item: str, status: str, entries: tuple[str, ...]) -> None:
        for entry in entries:
            rows.append(row(card, item, entry, status, entry))

    add(
        "classroom_session_screen.dart",
        "Moved",
        (
            "session list, active session, optional agenda, check-in, offline outbox queue, sync",
            "live phases, recording consent, recording banner, retention line, teacher start recording, leave",
            "shouldPersistClassAv, classSessionPhaseLabel, consent and recording copy",
        ),
    )
    add(
        "classroom_session_screen.dart",
        "Dropped",
        (
            "two em dashes in the queued check-in line and the recording indicator were replaced with periods. The card forbids an em dash. The meaning is unchanged.",
        ),
    )
    add(
        "classroom_lobby_screen.dart",
        "Moved",
        (
            "practice-room catalog from tribes with includeClassrooms",
            "class code join",
            "filter chips All, Starting Soon, My Languages. They change selection only. The source does not filter the list.",
            "room card language, title, Community classroom, participant count, HOT when members_count is over 20",
            "Notes opens /classroom-notes",
            "Queue opens /speaker-queue",
            "host and room open the live classroom room",
            "empty and error copy",
        ),
    )
    add(
        "classroom_lobby_screen.dart",
        "Dropped",
        (
            "empty language_tag rendered an em dash. The chip is omitted when the tag is empty.",
            "host and room tap opened LiveClassroomScreenMaterial3. That screen is not one of the four variants. The action now opens LiveClassroomScreen.",
        ),
    )
    add(
        "live_classroom_mobile_screen.dart",
        "Moved",
        (
            "mute toggle",
            "active lesson card",
            "listener online dots and listener count",
            "reactions with the party and clap marks",
            "host speaking label",
        ),
    )
    add(
        "live_classroom_mobile_screen.dart",
        "Dropped",
        ("more_vert has no onPressed and builds no menu",),
    )
    add(
        "classroom_v2_route_args.dart",
        "Moved",
        (
            "LiveClassroomScreen.fromRouteArguments uses ClassroomV2RouteArgs.parse for tribeId and tribeName",
        ),
    )
    add(
        "classroom_v2_route_args.dart",
        "Kept",
        (
            "the file stays. classroom-roster-v2, classroom-assignments-v2, classroom-privacy-v2, and classroom-student-requests-v2 still call it, and classroom_v2_route_args_test.dart imports it. Those routes are outside this consolidation.",
        ),
    )
    add(
        "classroom_v2_route_args.dart",
        "Dropped",
        (
            "missingTribeIdScaffold is not applied on the live classroom. A missing tribe id opens the practice-room catalog. The scaffold stays on the routes that require a tribe id.",
        ),
    )
    for name in ("roster", "assignments", "privacy"):
        rows.append(
            row(
                card,
                ideas,
                name,
                "Unresolved",
                "not present in the variant",
            )
        )
    rows.append(
        row(
            card,
            ideas,
            "notes",
            "Moved",
            "classroom_lobby_screen.dart opens /classroom-notes with tribeId and roomName",
        )
    )
    rows.append(
        row(
            card,
            ideas,
            "speaker queue",
            "Moved",
            "classroom_lobby_screen.dart opens /speaker-queue with tribeId and roomName",
        )
    )
    return rows


def _p067() -> list[dict[str, str]]:
    card = "P3-067"
    rows: list[dict[str, str]] = []

    def add(item: str, status: str, entries: tuple[str, ...]) -> None:
        for entry in entries:
            rows.append(row(card, item, entry, status, entry))

    story = "kijiji_onboarding_screen.dart village story"
    add(
        story,
        "Moved",
        (
            "optional panel on the unified welcome step",
            "spoken lines in screen order: welcome, Pa LingAfriq, who you are, why you are learning, Adisa the Weaver, Nuru the Rhythm Master, Zawadi, choose your path, Amina the Griot, the Healer, build your clan, the naming line, let us see where you stand",
        ),
    )
    add(
        story,
        "Dropped",
        (
            "age, reason, language, level, duration, path, tone, and gamification controls. The unified steps already save those answers.",
            "healer switches. Titles are camelCase keys split by a regex, not strings from the catalogue.",
            "clan chips. Labels are the raw ids solo, buddies, community, and teacher_guided.",
            "rhythm options. Labels are the raw ids audio, visual, stories, drills, and conversation. The unified learning-style step already saves those ids.",
            "three self-report placement prompts inside _PlacementTestScreen. They assign fixed levels A0 through B2. The unified flow already opens PlacementTestScreen when self_reported_level is unsure. This card does not copy those prompts.",
        ),
    )
    add(
        "enhanced_onboarding_flow_screen.dart",
        "Dropped",
        (
            "proficiency language, learning language, age, reasons, daily time, primary goal, learning style, app tone, schedule, and profile. The unified steps already save those keys.",
            "proficiency_level and pace_preference. Nothing else in lib reads those keys. Pace options render the raw ids slow, steady, fast, and surprise.",
            "the placement dialog. Unified already asks, then opens PlacementTestScreen.",
            "no generateAppRoute entry. The class was only constructed by its own file.",
        ),
    )
    add(
        "modern_onboarding_screen.dart",
        "Dropped",
        (
            "four marketing pages. Get started calls setOnboardingSeen, registerDevice, and TabsViewMaterial3. It does not read the path card.",
            "path cards call updatePath, including dialect, and then the next screen ignores selectedPath.",
            "onboardingExplore54Countries2000LanguagesAnd is the frozen unverified language-count claim in MARKETING_CLAIMS_FREEZE.md.",
            "no generateAppRoute entry and no other file constructed the class.",
        ),
    )
    add(
        "onboarding_screen.dart",
        "Dropped",
        (
            "page 4 calls navigateOffAll(TabsViewMaterial3) and saves no answers.",
            "three descriptions are hard-coded English, including the frozen 2000-language claim.",
            "no generateAppRoute entry and no other file constructed the class.",
        ),
    )
    add(
        "onboarding_screen_material3.dart",
        "Moved",
        (
            "its build method already returned UnifiedOnboardingScreen. auth_provider, sign_in_options, and passkey_service now construct UnifiedOnboardingScreen directly.",
        ),
    )
    add(
        "onboarding_screen_material3.dart",
        "Dropped",
        ("the wrapper class. It had no other child.",),
    )
    add(
        "placement_quiz_screen.dart",
        "Dropped",
        (
            "loads questions with PlacementTestService.loadQuestionsForLanguage and scores them with PlacementTestService.evaluate. The file contains no question text.",
            "updatePlacementTest and updateProficiency write onboardingProvider.placementTestResults. No reachable screen reads that field.",
            "no generateAppRoute entry and no other file constructed the class. Unified opens PlacementTestScreen instead.",
        ),
    )
    add(
        "placement_test_screen.dart",
        "Kept",
        (
            "the unified completion dialog already pushes this screen when self_reported_level is unsure. Questions come from the generate endpoint and PlacementTestService. This card does not copy a question into a new widget. Moving the file would leave that dialog with no screen.",
        ),
    )
    return rows


def _p068() -> list[dict[str, str]]:
    card = "P3-068"
    templates = "7 game templates"
    rows: list[dict[str, str]] = []
    moved = (
        "template_match_board.dart play slot board, action slot controls",
        "template_narrative.dart play slot narrativeContent, action slot actions",
        "template_pronunciation.dart play slot content, action slot micControls",
        "template_rhythm.dart play slot rhythmArea, action slot controls",
        "template_strategic.dart play slot board, action slot controls",
        "template_timed_quiz.dart play slot questionArea, action slot actions",
        "GameKitTemplateFrame places those slots on the shared game shell",
    )
    for entry in moved:
        rows.append(row(card, templates, entry, "Moved", entry))
    rows.append(
        row(
            card,
            templates,
            "seventh template",
            "Unresolved",
            "seventh: not present. A seventh named template class is not present. The card stays Draft.",
        )
    )
    kept_files = (
        "template_match_board.dart",
        "template_narrative.dart",
        "template_pronunciation.dart",
        "template_rhythm.dart",
        "template_strategic.dart",
        "template_timed_quiz.dart",
    )
    kept_reason = (
        "The six template files stay. No route builds them. "
        "test/games/game_template_shell_test.dart still builds GameTemplateShell, "
        "and that test is outside this card."
    )
    for entry in kept_files:
        rows.append(row(card, templates, entry, "Kept", kept_reason))
    rows.append(
        row(
            card,
            templates,
            "game_template_shell.dart",
            "Kept",
            "game_template_shell.dart stays. BaseGameScreen and that shell test import it. The live loader now also shows a harvested loading fact.",
        )
    )

    loading = "universal loading screen"
    for entry in (
        "Five loading facts, with the caller's fact winning even when it is empty",
        "Skip only when a skip callback is set",
        "Back only when the route can pop",
        "Dot index (value * 3).floor() clamped to 0, 1, or 2",
        "Pulse 2400 ms, progress 8 s, dots 1800 ms",
        "LingAfriq, Did You Know?, and Skip",
        "BaseGameScreen and UniversalGameScreen show the fact while a game loads",
    ):
        rows.append(row(card, loading, entry, "Moved", entry))
    for entry in (
        "Three em dashes in the Yoruba, Ge'ez, and Wolof facts were replaced with periods. The card forbids an em dash. The meaning is unchanged.",
        "Unseeded Random() on the live path was replaced with Random(language or game id hash) so the same language or game shows the same fact. The list and nextInt pick are unchanged.",
        "Full-page ModernGriot scaffold, pulse rings, and gradient bar stay on the old screen. A second scaffold inside the game shell would stack app bars. The old screen has no route.",
    ):
        rows.append(row(card, loading, entry, "Dropped", entry))

    game = "universal game screen"
    rows.append(
        row(
            card,
            game,
            "lib/screens/games/universal_game_screen.dart",
            "Unresolved",
            "screens_path: not present. lib/screens/games/universal_game_screen.dart is not present.",
        )
    )
    rows.append(
        row(
            card,
            game,
            "lib/games/gamekit/universal_game_screen.dart",
            "Moved",
            "The GameKit screen already plays a generic game. It now shows the harvested loader, and a start guide when the caller passes one.",
        )
    )
    rows.append(
        row(
            card,
            game,
            "GameMasteryResultsScreen",
            "Kept",
            "End of play still opens GameMasteryResultsScreen. Elevation revives that screen as the standard results view. Replacing it would drop skill deltas.",
        )
    )

    guide = "start guide"
    for entry in (
        "Character name and title, game title, mission objective, cultural tip",
        "XP label +N XP",
        "How to Play keeps the first three steps and drops the rest",
        "Start Mission and Review Vocabulary",
    ):
        rows.append(row(card, guide, entry, "Moved", entry))
    rows.append(
        row(
            card,
            guide,
            "Hero art, bento grid, and pattern background",
            "Dropped",
            "Hero art, bento grid, and pattern background. They are decoration on an unrouted screen. The steps, labels, and actions are the behavior.",
        )
    )

    victory = "victory results"
    for entry in (
        "Mission complete, XP as +N, vocabulary, score, idioms, griot rank, mastery percent",
        "Mastery bar value is mastery percent divided by 100",
        "Claim Rewards and Replay Mission",
    ):
        rows.append(row(card, victory, entry, "Moved", entry))
    for entry in (
        "Glow animation and glass stat cards. They are decoration on an unrouted screen. The totals and actions are the behavior.",
        "UniversalGameScreen does not replace mastery results with this view. See universal_game_screen kept.",
    ):
        rows.append(row(card, victory, entry, "Dropped", entry))
    return rows


def _p069() -> list[dict[str, str]]:
    card = "P3-069"
    rewrite = "games/proverb_unlocker GameKit rewrite"
    live = "live random-logic version content and proverb data"
    rows = [
        row(
            card,
            rewrite,
            "GameKit game, factory, scoring, feedback, and screen",
            "Kept",
            "GameKit game, factory, scoring, feedback, and screen",
        ),
        row(
            card,
            live,
            "Six live fallback proverbs, with id, language, original, translation, meaning, and cefr",
            "Kept",
            "Six live fallback proverbs, with id, language, original, translation, meaning, and cefr",
        ),
        row(
            card,
            live,
            "Meaning choice, seeded blank indexes, token order, and the fill-match check",
            "Kept",
            "Meaning choice, seeded blank indexes, token order, and the fill-match check",
        ),
    ]
    dropped = (
        (
            "Unseeded Random shuffle and blank picker",
            "Replaced by Random(seed) so the same seed returns the same proverb and outcome",
        ),
        (
            "Invented fallback proverb and meaning distractors",
            "Wisdom comes from experience, A common greeting, A traditional dance, A type of food, and A weather saying are not in the live proverb list",
        ),
        (
            "Polie proverb text on the played path",
            "Polie can return text that is not in the harvested list, including that invented fallback",
        ),
        (
            "Placeholder tokens such as word0",
            "They are not proverb words. Token options use words from the harvested proverbs only",
        ),
        (
            "Ancestral tablet widgets",
            "The arcade route now builds the GameKit screen. No route builds the old tablet file, which was deleted after the catalog and seed test held the proverb text",
        ),
    )
    for entry, reason in dropped:
        rows.append(row(card, live, entry, "Dropped", reason))
    return rows


def _p070() -> list[dict[str, str]]:
    card = "P3-070"
    translation = "enhanced_translation_screen.dart"
    rows = [
        row(
            card,
            translation,
            "class now builds LiveTranslateScreen",
            "Moved",
            "The class now builds LiveTranslateScreen with the same source language, target language, and initial text.",
        ),
        row(
            card,
            translation,
            "primary, alternatives, grammar, and cultural notes parsed from the caption",
            "Moved",
            "primary, alternatives, grammar, and cultural notes parsed from the caption",
        ),
        row(
            card,
            translation,
            "the 5000 character guard",
            "Moved",
            "the 5000 character guard",
        ),
        row(
            card,
            translation,
            "a history entry and star toggle on mt.final",
            "Moved",
            "a history entry and star toggle on mt.final",
        ),
        row(
            card,
            translation,
            "the structured prompt text kept beside the parser",
            "Moved",
            "the structured prompt text kept beside the parser",
        ),
        row(
            card,
            translation,
            "client Groq sendMessage call, retry loop, and failure snackbars",
            "Dropped",
            "The live screen already translates on the session socket and already reconnects.",
        ),
        row(
            card,
            translation,
            "fade and slide around the result cards, and the three hide chips",
            "Dropped",
            "A section is shown only when the parse found it.",
        ),
        row(
            card,
            translation,
            "source-word grammar fallback rows",
            "Kept",
            "Source-word grammar fallback rows (part of speech word, no explanation) are still parsed and tested, and the live screen hides them so a plain caption does not list every word.",
        ),
        row(
            card,
            "enhanced chat variant",
            "enhanced chat variant",
            "Unresolved",
            "P3-065 already folded conversation_enhanced_screen.dart. That file is still absent. Polie files were not edited and the old chat screen was not recreated.",
        ),
        row(
            card,
            "enhanced feed variant",
            "enhanced feed variant",
            "Unresolved",
            "No file under lib/screens/feed has enhanced in the name. Survivor is XFeedHomeScreen (route x-feed-home). Nothing moved.",
        ),
        row(
            card,
            "enhanced profile variant",
            "enhanced profile variant",
            "Unresolved",
            "No file under lib/screens/profile has enhanced in the name. Survivor is ProfileScreenMaterial3. Nothing moved.",
        ),
        row(
            card,
            "enhanced settings variant",
            "enhanced settings variant",
            "Unresolved",
            "No file under lib/screens/settings has enhanced in the name. Survivor is SettingsScreenMaterial3 (route settings). Nothing moved.",
        ),
        row(
            card,
            "enhanced curriculum variant",
            "enhanced curriculum variant",
            "Unresolved",
            "No file under lib/screens/curriculum has enhanced in the name. Survivor is LessonsMapEntryScreen (route curriculum). Nothing moved.",
        ),
        row(
            card,
            "enhanced practice variant",
            "enhanced practice variant",
            "Unresolved",
            "No file under lib/screens/practice has enhanced in the name. Survivors are pronunciation_practice_screen.dart, conversation_practice_screen.dart, and tone_drill_screen.dart. Nothing moved.",
        ),
    ]
    ugc = "enhanced UGC variant"
    for entry, text in (
        (
            "lesson badge ids from grammar, cultural, and canonical checks",
            "lesson badge ids from grammar, cultural, and canonical checks",
        ),
        (
            "validate POST /user-content/validate, the score line, and the validation details screen",
            "validate POST /user-content/validate, the score line, and the validation details screen",
        ),
        (
            "quiz title, question, option, and answer checks plus badges",
            "quiz title, question, option, and answer checks plus badges",
        ),
        (
            "story title and content checks plus badges",
            "story title and content checks plus badges",
        ),
        (
            "CreateLessonScreenEnhanced extends CreateLessonScreen",
            "That class now extends CreateLessonScreen, because the drawer files are outside this card.",
        ),
    ):
        rows.append(row(card, ugc, entry, "Moved", text))
    for entry, reason in (
        (
            "enhanced lesson POST /user-content/lessons with qualityBadges",
            "The live service has no qualityBadges field and that service is outside this card. Badges are still shown.",
        ),
        (
            "lesson loading overlay sentence",
            "The live create button already shows a spinner.",
        ),
        (
            "enhanced quiz second question editor",
            "The live screen already edits four options and a correct answer.",
        ),
    ):
        rows.append(row(card, ugc, entry, "Dropped", reason))
    return rows


LEDGER: list[dict[str, str]] = _p065() + _p066() + _p067() + _p068() + _p069() + _p070()


def load_harvest_lists(cards_dir: Path) -> dict[str, list[str]]:
    found: dict[str, list[str]] = {}
    for card_id in CARD_IDS:
        path = cards_dir / f"{card_id}.yaml"
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        items = data.get("harvest_list") or []
        found[card_id] = [str(item) for item in items]
    return found


def uncovered_items(lists: dict[str, list[str]], ledger: list[dict[str, str]] | None = None) -> list[str]:
    rows = LEDGER if ledger is None else ledger
    covered = {(row["card"], row["item"]) for row in rows}
    missing: list[str] = []
    for card_id, items in lists.items():
        for item in items:
            if (card_id, item) not in covered:
                missing.append(f"{card_id}: {item}")
    return missing


def counts(ledger: list[dict[str, str]] | None = None) -> dict[str, int]:
    rows = LEDGER if ledger is None else ledger
    tally = Counter(row["status"] for row in rows)
    return {status: tally.get(status, 0) for status in STATUSES}


def _basename(uri: str) -> str:
    path = uri.split("?", 1)[0].replace("\\", "/")
    return path.rstrip("/").split("/")[-1]


def _path_has_legacy_dir(uri: str) -> bool:
    parts = uri.split("?", 1)[0].replace("\\", "/").split("/")
    return "legacy" in parts


def classify_uri(uri: str) -> tuple[str, str] | None:
    """Return (kind, note) for a directive URI, or None when it is not in scope.

    kind is 'removed' or 'kept'. Kept wins for the template files P3-068
    said stay.
    """
    base = _basename(uri)
    if base in KEPT_TEMPLATE_BASENAMES:
        return (
            "kept",
            "P3-068 kept this file because a test or BaseGameScreen still imports the shell.",
        )
    if OLD_TABLET_MARKER in uri.replace("\\", "/"):
        return ("removed", "P3-069: the old tablet file was deleted.")
    if base in REMOVED_BASENAMES:
        return ("removed", REMOVED_BASENAMES[base])
    if _path_has_legacy_dir(uri):
        return ("removed", "Import path is under legacy/.")
    return None


def _display_path(path: Path, root: Path | None) -> str:
    if root is not None:
        try:
            return path.resolve().relative_to(root.resolve()).as_posix()
        except ValueError:
            pass
    return path.as_posix()


def scan_lib(
    lib_dir: Path,
    root: Path | None = None,
) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    removed: list[dict[str, str]] = []
    kept: list[dict[str, str]] = []
    if not lib_dir.is_dir():
        return removed, kept
    for path in sorted(lib_dir.rglob("*.dart")):
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except UnicodeDecodeError:
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        for number, line in enumerate(lines, start=1):
            match = DIRECTIVE_RE.match(line)
            if match is None:
                continue
            uri = match.group(1)
            classified = classify_uri(uri)
            if classified is None:
                continue
            kind, note = classified
            hit = {
                "path": _display_path(path, root),
                "line": str(number),
                "uri": uri,
                "basename": _basename(uri),
                "note": note,
            }
            if kind == "removed":
                removed.append(hit)
            else:
                kept.append(hit)
    return removed, kept


def _cell(value: str) -> str:
    return value.replace("|", "/").replace("\n", " ").strip()


def render_report(
    *,
    lists: dict[str, list[str]],
    missing: list[str],
    removed: list[dict[str, str]],
    kept_hits: list[dict[str, str]],
    lib_dir: Path,
    card_status: str,
) -> str:
    tally = counts()
    lines: list[str] = [
        "# Consolidation harvest report",
        "",
        "Card P3-072. Status stays Draft.",
        "",
        "This report lists every harvest_list item on P3-065, P3-066, P3-067, P3-068, P3-069, and P3-070. A harvest_list line that the source card split into parts has one row per part. Status is Moved, Dropped, Kept, or Unresolved. Dropped rows copy the reason already written on the source card. Approver is Unrecorded. This repo has no human approver, so P3-072 is not marked Done.",
        "",
        f"P3-072 card file status read by this run: {card_status}.",
        "",
        "P3-068 stays Draft. A seventh named template class is not in the repo. This report does not invent one. The old template shell is still imported. P3-068 says game_template_shell.dart stays because BaseGameScreen and test/games/game_template_shell_test.dart import it, and the six template files stay because that test still builds GameTemplateShell. Those references are Kept, not a scan failure. P3-068 also says the old files were not deleted, lib/screens/games/universal_game_screen.dart is not present, and lib/games/base_game_screen.dart is not present.",
        "",
        (
            f"Counts: Moved {tally['Moved']}, Dropped {tally['Dropped']}, "
            f"Kept {tally['Kept']}, Unresolved {tally['Unresolved']}."
        ),
        "",
        "## Ledger",
        "",
        "| Card | Harvest list item | Entry | Status | Card text | Approver |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for entry in LEDGER:
        lines.append(
            "| {card} | {item} | {name} | {status} | {text} | {approver} |".format(
                card=_cell(entry["card"]),
                item=_cell(entry["item"]),
                name=_cell(entry["entry"]),
                status=_cell(entry["status"]),
                text=_cell(entry["text"]),
                approver=_cell(entry["approver"]),
            )
        )
    lines.extend(
        [
            "",
            "## Harvest list coverage",
            "",
        ]
    )
    if missing:
        lines.append("These harvest_list items have no row. No reason was invented for them.")
        for item in missing:
            lines.append(f"- {item}")
    else:
        lines.append("Every harvest_list item on the six cards has at least one row above.")
    lines.extend(["", "Items read from the cards:", ""])
    for card_id in CARD_IDS:
        lines.append(f"- {card_id}: {len(lists.get(card_id, []))} harvest_list items")
    lines.extend(
        [
            "",
            "## Import scan",
            "",
            f"Scanned `{lib_dir.as_posix()}` for import, export, and part directives.",
            "Comments are not imports. The GameKit proverb file is not the deleted tablet. A path must contain cultural/proverb_unlocker_game.dart to match the old tablet.",
            "",
            "Scan set the cards named as deleted or moved to legacy:",
            "",
            "- ai_chat_screen.dart, ai_chat_screen_new.dart, ai_chat_screen_with_tracking.dart, conversation_enhanced_screen.dart. P3-065 says they were already deleted in 514e70e1 and had no route.",
            "- ai_mode_selection_screen.dart. P3-065 says it moved to legacy/ai_chat/.",
            "- cultural/proverb_unlocker_game.dart. P3-069 says the old tablet file was deleted. The surviving catalog names that path. lib/games/proverb_unlocker/proverb_unlocker_game.dart is the survivor.",
            "- create_quiz_screen_enhanced.dart and create_story_screen_enhanced.dart. P3-070 says the quiz and story enhanced files are deleted.",
            "",
            "Also scanned, because the files are under legacy/onboarding/. P3-067's harvest_audit does not say moved to legacy. An import from lib/ would still be a remaining variant import:",
            "",
            "- enhanced_onboarding_flow_screen.dart",
            "- kijiji_onboarding_screen.dart",
            "- modern_onboarding_screen.dart",
            "- onboarding_screen.dart",
            "- onboarding_screen_material3.dart",
            "",
            "Not in the failure set:",
            "",
            "- placement_test_screen.dart. P3-067 says the file stays.",
            "- classroom_v2_route_args.dart. P3-066 says the file stays. P3-066 does not say the other classroom variant files were deleted or moved to legacy, so those names are not a failure set.",
            "- game_template_shell.dart and the six template files. P3-068 says they stay.",
            "- enhanced_translation_screen.dart and create_lesson_screen_enhanced.dart. P3-070 says the navigation helper still constructs the translation screen and the drawer still opens the lesson class. Those files were not described as deleted.",
            "",
        ]
    )
    if removed:
        lines.append("Remaining imports from lib/. The script exits 1. The imports were not deleted.")
        lines.append("")
        for hit in removed:
            lines.append(
                f"- {hit['path']}:{hit['line']} imports `{hit['uri']}` ({hit['note']})"
            )
    else:
        lines.append("No lib/ import of a deleted or legacy variant. Exit 0.")
    lines.extend(["", "Kept template references in lib/. These are not failures.", ""])
    if kept_hits:
        for hit in kept_hits:
            lines.append(f"- {hit['path']}:{hit['line']} references `{hit['uri']}`")
    else:
        lines.append("- None in this lib tree.")
    lines.extend(
        [
            "",
            "P3-068 kept game_template_shell.dart because BaseGameScreen and the shell test import it. The shell test lives under test/ and is outside this lib scan. harvested_frame.dart also imports the shell. That is the same kept file, so it is listed here and does not fail the scan.",
            "",
        ]
    )
    return "\n".join(lines)


def read_card_status(cards_dir: Path, card_id: str = "P3-072") -> str:
    path = cards_dir / f"{card_id}.yaml"
    if not path.is_file():
        return "missing"
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    return str(data.get("status", "missing"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Audit consolidation harvest lists.")
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--cards", type=Path, default=None)
    parser.add_argument("--lib", type=Path, default=None)
    parser.add_argument("--out", type=Path, default=None)
    parser.add_argument("--no-write", action="store_true")
    args = parser.parse_args(argv)

    root = args.root.resolve()
    cards_dir = (args.cards or (root / "docs" / "build" / "cards" / "P3")).resolve()
    lib_dir = (args.lib or (root / "lib")).resolve()
    out_path = args.out
    if out_path is None and not args.no_write:
        out_path = root / "docs" / "build" / "design" / "HARVEST_REPORT.md"

    lists = load_harvest_lists(cards_dir)
    missing = uncovered_items(lists)
    removed, kept_hits = scan_lib(lib_dir, root)
    status = read_card_status(cards_dir)
    report = render_report(
        lists=lists,
        missing=missing,
        removed=removed,
        kept_hits=kept_hits,
        lib_dir=Path(_display_path(lib_dir, root)),
        card_status=status,
    )
    if "\u2014" in report or "\u2013" in report:
        print("harvest_check: report contains an em dash or en dash", file=sys.stderr)
        return 1
    if out_path is not None:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(report, encoding="utf-8")

    tally = counts()
    print(
        "harvest_check: Moved {Moved}, Dropped {Dropped}, Kept {Kept}, Unresolved {Unresolved}".format(
            **tally
        )
    )
    print(f"harvest_check: P3-072 status {status}")
    if missing:
        for item in missing:
            print(f"harvest_check: uncovered {item}", file=sys.stderr)
        return 1
    if removed:
        for hit in removed:
            print(
                f"harvest_check: remaining import {hit['path']}:{hit['line']} {hit['uri']}",
                file=sys.stderr,
            )
        return 1
    print("harvest_check: no remaining import of a deleted or legacy variant")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

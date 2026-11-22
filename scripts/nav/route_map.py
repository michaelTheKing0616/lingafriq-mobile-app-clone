#!/usr/bin/env python3
"""Map every registered route and drawer item onto one hub.

Reads the named-route table in lib/my_app.dart and the drawer items in
lib/screens/tabs_view/app_drawer/. Writes docs/build/design/ROUTE_MAP.csv.

Each row has one home hub (Today, Learn, Speak, Play, Village, or Me), one
job (learn it, say it, or live it), and one unlock stage from ELEVATION.md
§17.4. Chat, status, clips, and the X-style Square sit in Village and each
names one learning loop. A route or drawer item with no home fails the run
and is listed. Routes are not removed.
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import re
import sys
from pathlib import Path
from typing import NamedTuple

HUBS = ("Today", "Learn", "Speak", "Play", "Village", "Me")
JOBS = ("learn it", "say it", "live it")
STAGES = (
    "Day 1",
    "Account created",
    "Week 1 / A1 unit 3",
    "A2",
    "B1",
    "native speaker (any level)",
)
SURFACES = ("", "chat", "status", "clips", "square")
SOCIAL_SURFACES = ("chat", "status", "clips", "square")

APP_REL = "lib/my_app.dart"
DRAWER_RELS = (
    "lib/screens/tabs_view/app_drawer/app_drawer.dart",
    "lib/screens/tabs_view/app_drawer/app_drawer_material3.dart",
)
ARB_REL = "lib/l10n/app_en.arb"
OUT_REL = "docs/build/design/ROUTE_MAP.csv"

DAY1 = "Day 1"
ACCOUNT = "Account created"
WEEK1 = "Week 1 / A1 unit 3"
A2 = "A2"
B1 = "B1"
NATIVE = "native speaker (any level)"
LEARN = "learn it"
SAY = "say it"
LIVE = "live it"

TOKEN = {
    "ai": "AI",
    "api": "API",
    "ugc": "UGC",
    "flb": "FLB",
    "wa": "WA",
    "dna": "DNA",
    "vs": "vs",
    "x": "X",
    "v2": "v2",
}

_KEY_LINE = re.compile(r"""^\s*(?:'([^']+)'|"([^"]+)")\s*:""")
_LABEL = re.compile(
    r"""label:\s*('(?:\\.|[^'\\])*'|"[^"]*"|l10nOf\(context\)\.(\w+)|l10n\.(\w+))"""
)


class Home(NamedTuple):
    hub: str
    job: str
    unlock_stage: str
    learning_loop: str
    surface: str = ""


class DrawerItem(NamedTuple):
    key: str
    source: str
    line: int


class Row(NamedTuple):
    kind: str
    key: str
    label: str
    hub: str
    job: str
    unlock_stage: str
    learning_loop: str
    surface: str
    source: str


def _home(
    hub: str,
    job: str,
    stage: str,
    loop: str,
    surface: str = "",
) -> Home:
    if hub not in HUBS:
        raise ValueError(f"hub {hub!r} is outside the six hubs")
    if job not in JOBS:
        raise ValueError(f"job {job!r} is not learn it, say it, or live it")
    if stage not in STAGES:
        raise ValueError(f"unlock stage {stage!r} is not in §17.4")
    if not loop or any(mark in loop for mark in ("|", ";")):
        raise ValueError(f"learning loop {loop!r} must be one name")
    if surface not in SURFACES:
        raise ValueError(f"surface {surface!r} is not chat, status, clips, or square")
    if surface in SOCIAL_SURFACES and hub != "Village":
        raise ValueError(f"{surface} loop {loop!r} must sit in Village")
    return Home(hub, job, stage, loop, surface)


def _merge(*parts: dict[str, Home]) -> dict[str, Home]:
    merged: dict[str, Home] = {}
    for part in parts:
        overlap = set(merged).intersection(part)
        if overlap:
            names = ", ".join(sorted(overlap))
            raise ValueError(f"duplicate placement keys: {names}")
        merged.update(part)
    return merged


# Placement follows ELEVATION.md §3.2, §3.3, and §17. Lens and Search are
# global tools, so their routes take a home in one of the six hubs.
_TODAY = {
    "daily_goals": _home("Today", LEARN, DAY1, "Today session"),
    "quest": _home("Today", LEARN, DAY1, "Village quest"),
    "events": _home("Today", LIVE, DAY1, "Village festival"),
    "friend-quests": _home("Today", LEARN, ACCOUNT, "Friend quest"),
    "create-friend-quest": _home("Today", LEARN, ACCOUNT, "Friend quest"),
    "Dashboard": _home("Today", LEARN, DAY1, "Today session"),
    "shellFriendQuests": _home("Today", LEARN, ACCOUNT, "Friend quest"),
}
_LEARN = {
    "curriculum": _home("Learn", LEARN, DAY1, "Path lesson"),
    "lesson-flow": _home("Learn", LEARN, DAY1, "Path lesson"),
    "Lessons": _home("Learn", LEARN, DAY1, "Path lesson"),
    "authentic-path": _home("Learn", LEARN, A2, "Real-world track"),
    "shellAuthenticPathA1C1": _home("Learn", LEARN, A2, "Real-world track"),
    "grammar-hub": _home("Learn", LEARN, DAY1, "Grammar drill"),
    "grammar-lesson": _home("Learn", LEARN, DAY1, "Grammar drill"),
    "grammar-exercise": _home("Learn", LEARN, DAY1, "Grammar drill"),
    "shellGrammarHub": _home("Learn", LEARN, DAY1, "Grammar drill"),
    "learning-path": _home("Learn", LEARN, DAY1, "My plan"),
    "shellLearningPath": _home("Learn", LEARN, DAY1, "My plan"),
    "vocabulary-builder": _home("Learn", LEARN, DAY1, "Words and review"),
    "my-vocabulary": _home("Learn", LEARN, DAY1, "Words and review"),
    "flashcard-review": _home("Learn", LEARN, DAY1, "Words and review"),
    "living-dictionary": _home("Learn", LEARN, DAY1, "Words and review"),
    "phrase-dna-templates": _home("Learn", LEARN, DAY1, "Words and review"),
    "shellVocabularyBuilder": _home("Learn", LEARN, DAY1, "Words and review"),
    "shellFlashcardReview": _home("Learn", LEARN, DAY1, "Words and review"),
    "shellLivingDictionary": _home("Learn", LEARN, DAY1, "Words and review"),
    "shellPhraseDna": _home("Learn", LEARN, DAY1, "Words and review"),
    "listening-practice": _home("Learn", LEARN, DAY1, "Listening input"),
    "shellListeningPractice": _home("Learn", LEARN, DAY1, "Listening input"),
    "writing-practice": _home("Learn", LEARN, DAY1, "Writing retrieval"),
    "shellWritingPractice": _home("Learn", LEARN, DAY1, "Writing retrieval"),
    "tone-rhythm-trainer": _home("Learn", SAY, DAY1, "Tone practice"),
    "tonal-lesson": _home("Learn", SAY, DAY1, "Tone practice"),
    "shellToneRhythm": _home("Learn", SAY, DAY1, "Tone practice"),
    "magazine": _home("Learn", LEARN, DAY1, "Culture shelf"),
    "heritage-milestones": _home("Learn", LEARN, DAY1, "Culture shelf"),
    "flb-heritage-archive": _home("Learn", LEARN, DAY1, "Culture shelf"),
    "flb-heritage-detail": _home("Learn", LEARN, DAY1, "Culture shelf"),
    "cultural-hub": _home("Learn", LEARN, DAY1, "Culture shelf"),
    "shellCulturalMagazine": _home("Learn", LEARN, DAY1, "Culture shelf"),
    "shellHeritageMilestones": _home("Learn", LEARN, DAY1, "Culture shelf"),
    "drawerFlbHeritageArchive": _home("Learn", LEARN, DAY1, "Culture shelf"),
    "shellCulturalHub": _home("Learn", LEARN, DAY1, "Culture shelf"),
    "dialect-preference": _home("Learn", LEARN, DAY1, "Dialect choice"),
    "shellDialectPreference": _home("Learn", LEARN, DAY1, "Dialect choice"),
    "script-track": _home("Learn", LEARN, DAY1, "Script practice"),
    "stroke-order-practice": _home("Learn", LEARN, DAY1, "Script practice"),
    "passport-proctored": _home("Learn", LEARN, A2, "Passport evidence"),
    "passport-credential": _home("Learn", LEARN, A2, "Passport evidence"),
    "import_media": _home("Learn", LEARN, DAY1, "Import a sign and read it"),
    "shellImportMedia": _home("Learn", LEARN, DAY1, "Import a sign and read it"),
}
_SPEAK = {
    "ai_chat_select": _home("Speak", SAY, DAY1, "Polie conversation"),
    "polie_mode_selection": _home("Speak", SAY, DAY1, "Polie conversation"),
    "lingchat_ai": _home("Speak", SAY, DAY1, "Polie conversation"),
    "shellAiChat": _home("Speak", SAY, DAY1, "Polie conversation"),
    "shellPolieTutor": _home("Speak", SAY, DAY1, "Polie conversation"),
    "shellTutorMode": _home("Speak", SAY, DAY1, "Polie conversation"),
    "conversation-scenarios": _home("Speak", SAY, WEEK1, "Scenario dialogue"),
    "shellConversationScenarios": _home("Speak", SAY, WEEK1, "Scenario dialogue"),
    "historical-personas": _home("Speak", SAY, WEEK1, "Persona mission"),
    "shellHistoricalPersonas": _home("Speak", SAY, WEEK1, "Persona mission"),
    "shellPersonaMissions": _home("Speak", SAY, WEEK1, "Persona mission"),
    "speak-engine-lab": _home("Speak", SAY, A2, "Code-switch and respect practice"),
    "synthetic-voice-styles": _home("Speak", SAY, DAY1, "Hear a voice and shadow it"),
    "point-and-say": _home("Speak", SAY, DAY1, "Point, hear, and say"),
    "shellPointSay": _home("Speak", SAY, DAY1, "Point, hear, and say"),
    "shellLiveTranslate": _home("Speak", SAY, DAY1, "Conversation Bridge"),
}
_PLAY = {
    "games": _home("Play", LEARN, DAY1, "Arcade retrieval"),
    "flashcard-focus": _home("Play", LEARN, DAY1, "Arcade retrieval"),
    "matching-pairs": _home("Play", LEARN, DAY1, "Arcade retrieval"),
    "Games": _home("Play", LEARN, DAY1, "Arcade retrieval"),
    "games_api_languages": _home("Play", LEARN, ACCOUNT, "Arcade retrieval"),
    "games_enhanced_catalog": _home("Play", LEARN, ACCOUNT, "Arcade retrieval"),
    "challenge-friend": _home("Play", LEARN, ACCOUNT, "Challenge a friend"),
}
_VILLAGE = {
    "villages": _home("Village", LIVE, ACCOUNT, "Village place"),
    "villages-hub": _home("Village", LIVE, ACCOUNT, "Village place"),
    "language-village": _home("Village", LIVE, ACCOUNT, "Village place"),
    "language-village-place": _home("Village", LIVE, ACCOUNT, "Village place"),
    "swahili-village-map": _home("Village", LIVE, ACCOUNT, "Village place"),
    "village-market": _home("Village", LIVE, ACCOUNT, "Village place"),
    "village-cafe": _home("Village", LIVE, ACCOUNT, "Village place"),
    "shellLanguageVillages": _home("Village", LIVE, ACCOUNT, "Village place"),
    "elder-hut": _home("Village", LIVE, B1, "Ask an elder and save the proverb"),
    "tribe-selection": _home("Village", LIVE, ACCOUNT, "Circle practice"),
    "tribe_selection": _home("Village", LIVE, ACCOUNT, "Circle practice"),
    "tribe-hub": _home("Village", LIVE, ACCOUNT, "Circle practice"),
    "tribe-discovery": _home("Village", LIVE, ACCOUNT, "Circle practice"),
    "my-tribe": _home("Village", LIVE, ACCOUNT, "Circle practice"),
    "village-circles": _home("Village", LIVE, ACCOUNT, "Circle practice"),
    "shellMyTribes": _home("Village", LIVE, ACCOUNT, "Circle practice"),
    "tribe": _home("Village", LIVE, ACCOUNT, "Circle Clash"),
    "tribe_vs_tribe": _home("Village", LIVE, ACCOUNT, "Circle Clash"),
    "tribal-duel": _home("Village", LIVE, ACCOUNT, "Circle Clash"),
    "inter-tribe-leaderboard": _home("Village", LIVE, ACCOUNT, "Circle Clash"),
    "global_chat": _home("Village", LIVE, WEEK1, "Language Squares", "chat"),
    "shellGlobalChat": _home("Village", LIVE, WEEK1, "Language Squares", "chat"),
    "private-chat-inbox": _home("Village", LIVE, WEEK1, "Language-exchange DMs", "chat"),
    "shellPrivateChat": _home("Village", LIVE, WEEK1, "Language-exchange DMs", "chat"),
    "wa-starred": _home("Village", LIVE, WEEK1, "Saved phrases", "chat"),
    "wa-media-gallery": _home("Village", LIVE, WEEK1, "Saved phrases", "chat"),
    "call-history": _home("Village", LIVE, WEEK1, "Save phrases from a call", "chat"),
    "wa-status": _home("Village", LIVE, WEEK1, "Language Status", "status"),
    "wa-status-create": _home("Village", LIVE, WEEK1, "Language Status", "status"),
    "wa-status-view": _home("Village", LIVE, WEEK1, "Language Status", "status"),
    "snap-inbox": _home("Village", LIVE, A2, "Clips", "clips"),
    "snap-story-feed": _home("Village", LIVE, A2, "Clips", "clips"),
    "snap-camera": _home("Village", LIVE, A2, "Clips", "clips"),
    "snap-streaks": _home("Village", LIVE, A2, "Clips", "clips"),
    "snap-viewer": _home("Village", LIVE, A2, "Clips", "clips"),
    "x-feed-home": _home("Village", LIVE, ACCOUNT, "Square", "square"),
    "x-compose": _home("Village", LIVE, ACCOUNT, "Square", "square"),
    "x-post-detail": _home("Village", LIVE, ACCOUNT, "Square", "square"),
    "x-notifications": _home("Village", LIVE, ACCOUNT, "Square", "square"),
    "x-explore": _home("Village", LIVE, ACCOUNT, "Square", "square"),
    "x-lists": _home("Village", LIVE, ACCOUNT, "Square", "square"),
    "x-profile": _home("Village", LIVE, ACCOUNT, "Square", "square"),
    "explore-community": _home("Village", LIVE, ACCOUNT, "Square", "square"),
    "search-community": _home("Village", LIVE, ACCOUNT, "Square", "square"),
    "community-profile": _home("Village", LIVE, ACCOUNT, "Square", "square"),
    "shellCommunityFeed": _home("Village", LIVE, ACCOUNT, "Square", "square"),
    "connections": _home("Village", LIVE, ACCOUNT, "Find a language partner"),
    "friend-profile": _home("Village", LIVE, ACCOUNT, "Find a language partner"),
    "share-progress": _home("Village", LIVE, ACCOUNT, "Share a phrase you learned"),
    "social-hub": _home("Village", LIVE, ACCOUNT, "Pick one village loop"),
    "shellSocialHub": _home("Village", LIVE, ACCOUNT, "Pick one village loop"),
    "ancestral_tree": _home("Village", LIVE, ACCOUNT, "See who you helped"),
    "live-classroom": _home("Village", LEARN, ACCOUNT, "Classroom lesson"),
    "classroom-lobby": _home("Village", LEARN, ACCOUNT, "Classroom lesson"),
    "classroom-notes": _home("Village", LEARN, ACCOUNT, "Classroom lesson"),
    "classroom-student-requests-v2": _home("Village", LEARN, ACCOUNT, "Classroom lesson"),
    "classroom-roster-v2": _home("Village", LEARN, ACCOUNT, "Classroom lesson"),
    "classroom-assignments-v2": _home("Village", LEARN, ACCOUNT, "Classroom lesson"),
    "classroom-privacy-v2": _home("Village", LEARN, ACCOUNT, "Classroom lesson"),
    "shellLiveClassroom": _home("Village", LEARN, ACCOUNT, "Classroom lesson"),
    "speaker-queue": _home("Village", SAY, ACCOUNT, "Classroom lesson"),
    "practice-session": _home("Village", SAY, WEEK1, "Practice room"),
    "practice-room-collaborative": _home("Village", SAY, WEEK1, "Practice room"),
    "session-summary": _home("Village", SAY, WEEK1, "Practice room"),
    "shellPracticeRooms": _home("Village", SAY, WEEK1, "Practice room"),
    "practice-room-setup": _home("Village", SAY, B1, "Host a practice room"),
    "ugc": _home("Village", LIVE, B1, "Create a mini-lesson"),
    "shellCreateContent": _home("Village", LIVE, B1, "Create a mini-lesson"),
    "native-content-review": _home("Village", LIVE, NATIVE, "Native verification"),
    "suggest-fix": _home("Village", LIVE, NATIVE, "Native verification"),
    "contribute_voice": _home("Village", LIVE, NATIVE, "Native verification"),
    "quality-report": _home("Village", LIVE, NATIVE, "Native verification"),
    "shellNativeContentReview": _home("Village", LIVE, NATIVE, "Native verification"),
    "micro-mentor-hub": _home("Village", LIVE, B1, "Mentor session"),
    "staff-micro-mentor-reports": _home("Village", LIVE, B1, "Mentor session"),
    "shellMicroMentorReports": _home("Village", LIVE, B1, "Mentor session"),
    "Micro-Mentors": _home("Village", LIVE, B1, "Mentor session"),
}
_ME = {
    "family-hub": _home("Me", LIVE, ACCOUNT, "Family"),
    "guardian-approvals": _home("Me", LIVE, ACCOUNT, "Family"),
    "guardian-messaging-guide": _home("Me", LIVE, ACCOUNT, "Family"),
    "guardian-child-messages": _home("Me", LIVE, ACCOUNT, "Family"),
    "progress": _home("Me", LIVE, ACCOUNT, "Can-do progress"),
    "achievements": _home("Me", LIVE, ACCOUNT, "Cultural badges"),
    "badges": _home("Me", LIVE, ACCOUNT, "Cultural badges"),
    "Badges": _home("Me", LIVE, ACCOUNT, "Cultural badges"),
    "leaderboard": _home("Me", LIVE, ACCOUNT, "Fair leagues"),
    "Leaderboards": _home("Me", LIVE, ACCOUNT, "Fair leagues"),
    "Profile": _home("Me", LIVE, ACCOUNT, "Learner identity"),
    "settings": _home("Me", LIVE, DAY1, "Settings"),
    "policy": _home("Me", LIVE, DAY1, "Settings"),
    "Settings": _home("Me", LIVE, DAY1, "Settings"),
    "magic_items": _home("Me", LIVE, ACCOUNT, "Avatar wardrobe"),
    "features_guide": _home("Me", LIVE, DAY1, "All features"),
    "stitch-hub": _home("Me", LIVE, DAY1, "All features"),
    "passkey-sign-in": _home("Me", LIVE, DAY1, "Account"),
    "passkey-manage": _home("Me", LIVE, DAY1, "Account"),
    "sign-in-options": _home("Me", LIVE, DAY1, "Account"),
    "email-verification": _home("Me", LIVE, DAY1, "Account"),
}

PLACEMENT = _merge(_TODAY, _LEARN, _SPEAK, _PLAY, _VILLAGE, _ME)

COLUMNS = (
    "kind",
    "key",
    "label",
    "hub",
    "job",
    "unlock_stage",
    "learning_loop",
    "surface",
    "source",
)


def normalize_key(key: str) -> str:
    return (
        key.replace("\u2010", "-")
        .replace("\u2011", "-")
        .replace("\u2013", "-")
        .replace("\u2014", "-")
        .strip()
    )


def humanize(key: str) -> str:
    parts = normalize_key(key).replace("_", "-").split("-")
    words = [TOKEN.get(part, part.capitalize()) for part in parts if part]
    return " ".join(words)


def _map_body(text: str) -> str:
    marker = "final routes = <String, WidgetBuilder>{"
    start = text.find(marker)
    if start < 0:
        raise ValueError("lib/my_app.dart has no named-route table")
    open_brace = start + len(marker) - 1
    i = open_brace
    depth = 0
    limit = len(text)
    in_string = None
    line_comment = False
    block_comment = False
    while i < limit:
        char = text[i]
        nxt = text[i + 1] if i + 1 < limit else ""
        if line_comment:
            if char == "\n":
                line_comment = False
            i += 1
            continue
        if block_comment:
            if char == "*" and nxt == "/":
                block_comment = False
                i += 2
                continue
            i += 1
            continue
        if in_string:
            if char == "\\":
                i += 2
                continue
            if char == in_string:
                in_string = None
            i += 1
            continue
        if char == "/" and nxt == "/":
            line_comment = True
            i += 2
            continue
        if char == "/" and nxt == "*":
            block_comment = True
            i += 2
            continue
        if char in ("'", '"'):
            in_string = char
            i += 1
            continue
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[open_brace : i + 1]
        i += 1
    raise ValueError("named-route table is missing its closing brace")


def parse_routes(text: str) -> list[str]:
    """Return registered route names in source order."""
    keys: list[str] = []
    seen: set[str] = set()
    duplicates: list[str] = []
    for line in _map_body(text).splitlines():
        code = line.split("//", 1)[0]
        match = _KEY_LINE.match(code)
        if not match:
            continue
        name = match.group(1) or match.group(2)
        if name in seen:
            duplicates.append(name)
            continue
        seen.add(name)
        keys.append(name)
    if duplicates:
        listed = ", ".join(duplicates)
        raise ValueError(f"duplicate route: {listed}")
    return keys


def _argument_span(text: str, open_paren: int) -> tuple[str, int]:
    depth = 0
    i = open_paren
    limit = len(text)
    in_string = None
    while i < limit:
        char = text[i]
        if in_string:
            if char == "\\":
                i += 2
                continue
            if char == in_string:
                in_string = None
            i += 1
            continue
        if char in ("'", '"'):
            in_string = char
            i += 1
            continue
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return text[open_paren : i + 1], i + 1
        i += 1
    raise ValueError("drawer item is missing its closing parenthesis")


def _unquote(literal: str) -> str:
    body = literal[1:-1]
    return body.replace("\\'", "'").replace('\\"', '"')


def parse_drawer_items(text: str, source: str) -> list[DrawerItem]:
    """Return _DrawerItem call sites. The widget constructor is not an item."""
    items: list[DrawerItem] = []
    token = "_DrawerItem("
    start = 0
    while True:
        found = text.find(token, start)
        if found < 0:
            break
        window = text[max(0, found - 8) : found]
        if "const" in window:
            start = found + len(token)
            continue
        arguments, end = _argument_span(text, found + len(token) - 1)
        match = _LABEL.search(arguments)
        if match:
            raw = match.group(1)
            if raw.startswith(("'", '"')):
                key = _unquote(raw)
            else:
                key = match.group(2) or match.group(3) or raw
            line = text.count("\n", 0, found) + 1
            items.append(DrawerItem(normalize_key(key), source, line))
        start = end
    return items


def load_english_labels(root: Path) -> dict[str, str]:
    path = root / ARB_REL
    if not path.exists():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    return {key: value for key, value in data.items() if isinstance(value, str)}


def _label_for(key: str, english: dict[str, str], kind: str) -> str:
    if key in english:
        return english[key]
    if kind == "route":
        return humanize(key)
    return key


def audit(routes: list[str], drawers: list[DrawerItem]) -> list[str]:
    """List routes and drawer items that have no single valid home."""
    problems: list[str] = []
    for name in routes:
        home = PLACEMENT.get(name)
        if home is None:
            problems.append(f"unmapped route: {name}")
            continue
        problems.extend(_home_problems("route", name, home))
    for item in drawers:
        home = PLACEMENT.get(item.key)
        if home is None:
            problems.append(f"unmapped drawer: {item.source}:{item.line}:{item.key}")
            continue
        problems.extend(_home_problems("drawer", item.key, home))
    return problems


def _home_problems(kind: str, key: str, home: Home) -> list[str]:
    problems: list[str] = []
    if home.hub not in HUBS or home.job not in JOBS or home.unlock_stage not in STAGES:
        problems.append(f"unmapped {kind}: {key}")
    if home.surface in SOCIAL_SURFACES and (
        home.hub != "Village" or not home.learning_loop.strip()
    ):
        problems.append(f"social surface without a Village learning loop: {kind} {key}")
    return problems


def build_rows(
    routes: list[str],
    drawers: list[DrawerItem],
    english: dict[str, str],
) -> list[Row]:
    rows = [
        Row(
            kind="route",
            key=name,
            label=_label_for(name, english, "route"),
            hub=PLACEMENT[name].hub,
            job=PLACEMENT[name].job,
            unlock_stage=PLACEMENT[name].unlock_stage,
            learning_loop=PLACEMENT[name].learning_loop,
            surface=PLACEMENT[name].surface,
            source=APP_REL,
        )
        for name in routes
    ]
    rows.extend(
        Row(
            kind="drawer",
            key=item.key,
            label=_label_for(item.key, english, "drawer"),
            hub=PLACEMENT[item.key].hub,
            job=PLACEMENT[item.key].job,
            unlock_stage=PLACEMENT[item.key].unlock_stage,
            learning_loop=PLACEMENT[item.key].learning_loop,
            surface=PLACEMENT[item.key].surface,
            source=f"{item.source}:{item.line}",
        )
        for item in drawers
    )
    rows.sort(key=lambda row: (row.kind, row.key, row.source))
    return rows


def render(rows: list[Row]) -> str:
    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=COLUMNS, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        writer.writerow(row._asdict())
    return buffer.getvalue()


def load_tree(root: Path) -> tuple[list[str], list[DrawerItem]]:
    app = root / APP_REL
    if not app.exists():
        raise FileNotFoundError(app)
    routes = parse_routes(app.read_text(encoding="utf-8"))
    drawers: list[DrawerItem] = []
    for rel in DRAWER_RELS:
        path = root / rel
        if not path.exists():
            continue
        drawers.extend(parse_drawer_items(path.read_text(encoding="utf-8"), rel))
    return routes, drawers


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Write the route-to-hub map.")
    parser.add_argument("--root", default=".", help="Repository root")
    parser.add_argument("--out", default="", help="CSV path; default writes ROUTE_MAP.csv")
    parser.add_argument(
        "--check",
        action="store_true",
        help="Fail if the map is incomplete or the CSV drifted",
    )
    args = parser.parse_args(argv)
    root = Path(args.root)
    try:
        routes, drawers = load_tree(root)
    except (OSError, ValueError) as exc:
        print(exc, file=sys.stderr)
        return 1

    print(f"registered routes: {len(routes)}")
    problems = audit(routes, drawers)
    if problems:
        for problem in problems:
            print(problem)
        return 1

    rows = build_rows(routes, drawers, load_english_labels(root))
    text = render(rows)
    destination = Path(args.out) if args.out else root / OUT_REL
    if args.check and not args.out:
        destination = root / OUT_REL
    if args.check:
        if not destination.exists():
            print(f"missing {destination}")
            return 1
        current = destination.read_text(encoding="utf-8")
        if current != text:
            print(f"ROUTE_MAP.csv drifted from {APP_REL}")
            return 1
        print(f"drawer items: {len(drawers)}")
        print(f"checked {destination}")
        return 0

    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(text, encoding="utf-8")
    print(f"drawer items: {len(drawers)}")
    print(f"wrote {destination}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

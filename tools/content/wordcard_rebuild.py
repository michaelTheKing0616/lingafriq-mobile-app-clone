"""Rebuild legacy Word Card fields; WC-001/002 lint (P5-004, ELEVATION §6.1)."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence

from tools.content_engine.legacy.tone_claims import (
    LexiconLookup,
    TonalTarget,
    apply_change,
    format_lexicon_tone_note,
    lexicon_tone_pattern,
    nfc,
    plan_tone_claim_change,
)

CARD_ID = "P5-004"
DEFAULT_GAME_CONTENT = "assets/data/game_content.json"
RULE_WC001 = "WC-001"
RULE_WC002 = "WC-002"

_KIT_LANG: dict[str, str] = {
    "yoruba": "yo",
    "hausa": "ha",
    "igbo": "ig",
    "swahili": "sw",
    "zulu": "zu",
    "xhosa": "xh",
    "nigerian_pidgin": "pcm",
    "pidgin": "pcm",
}

# ELEVATION §6.1:L1130 — three topics truncated mid-parenthesis (restored from english_meaning).
_TOPIC_BY_ID: dict[int, str] = {
    1: "Good morning (to elders/group)",
    454: "Hello (to many / respect)",
    589: "Hello (plural/respect)",
}

_FALSE_TONE_CLAIM = "High tone on àárọ̀ marks respect"


@dataclass(frozen=True)
class LintFinding:
    rule_id: str
    word_id: object
    field: str
    detail: str


@dataclass(frozen=True)
class RebuildStats:
    words: int
    topics_restored: int
    p0_17_cleared: int
    phonetic_rebuilt: int


def repo_root(start: Path | None = None) -> Path:
    here = (start or Path(__file__)).resolve()
    for parent in (here, *here.parents):
        if (parent / "pubspec.yaml").is_file():
            return parent
    raise FileNotFoundError("mobile app root (pubspec.yaml) not found")


def kit_lang_for(language: object) -> str | None:
    if not isinstance(language, str):
        return None
    return _KIT_LANG.get(language)


def is_truncated_topic(topic: object) -> bool:
    if not isinstance(topic, str):
        return False
    text = topic.strip()
    return bool(text) and "(" in text and ")" not in text


def topic_restoration(word: Mapping[str, Any]) -> str | None:
    wid = word.get("id")
    if isinstance(wid, int) and wid in _TOPIC_BY_ID:
        return _TOPIC_BY_ID[wid]
    meaning = word.get("english_meaning")
    if isinstance(meaning, str):
        candidate = meaning.strip()
        if candidate and "(" in candidate and ")" in candidate:
            return candidate
    return None


def is_p0_17_flagged(word: Mapping[str, Any]) -> bool:
    cite = word.get("tone_citation")
    if isinstance(cite, str) and "P0-17" in cite:
        return True
    note = word.get("tonal_note")
    if isinstance(note, str) and _FALSE_TONE_CLAIM in note:
        return True
    return False


def lexicon_ipa(lookup: LexiconLookup | None, kit_lang: str, surface: str) -> str | None:
    if lookup is None:
        return None
    lexeme = lookup(kit_lang, nfc(surface))
    if lexeme is None:
        return None
    raw_ipa = lexeme.get("ipa")
    if isinstance(raw_ipa, str) and raw_ipa.strip():
        return raw_ipa.strip()
    g2p = lexeme.get("g2p")
    if isinstance(g2p, Mapping):
        gipa = g2p.get("ipa")
        if isinstance(gipa, str) and gipa.strip():
            return gipa.strip()
    return None


def _normalize_empty_phonetic(word: dict[str, Any]) -> None:
    guide = word.get("phonetic_guide")
    if guide == "" or (isinstance(guide, str) and not guide.strip()):
        word["phonetic_guide"] = None


def rebuild_phonetic_guide(
    word: dict[str, Any],
    lookup: LexiconLookup | None,
    kit_lang: str | None,
) -> bool:
    surface = word.get("word")
    if not isinstance(surface, str) or not kit_lang:
        _normalize_empty_phonetic(word)
        return False

    guide = word.get("phonetic_guide")
    note = word.get("tonal_note")
    guide_s = guide.strip() if isinstance(guide, str) else ""
    note_s = note.strip() if isinstance(note, str) else ""
    changed = False

    if guide_s and note_s and guide_s == note_s:
        word["phonetic_guide"] = lexicon_ipa(lookup, kit_lang, surface)
        changed = True
    elif guide_s == "":
        word["phonetic_guide"] = None
        changed = guide is not None and guide != ""

    _normalize_empty_phonetic(word)
    post_guide = word.get("phonetic_guide")
    post_note = word.get("tonal_note")
    if (
        isinstance(post_guide, str)
        and post_guide.strip()
        and isinstance(post_note, str)
        and post_guide.strip() == post_note.strip()
    ):
        word["phonetic_guide"] = lexicon_ipa(lookup, kit_lang, surface)
        changed = True
    return changed


def clear_p0_17_tone_rule(
    word: dict[str, Any],
    lookup: LexiconLookup | None,
    kit_lang: str | None,
) -> bool:
    if not is_p0_17_flagged(word):
        return False
    word.pop("tone_citation", None)
    surface = word.get("word")
    if not isinstance(surface, str) or not kit_lang:
        word["tonal_note"] = None
        return True

    locator = f"game_content#words[{word.get('id')}]"
    lang_key = word.get("language")
    if not isinstance(lang_key, str):
        lang_key = ""
    target = TonalTarget(locator, lang_key, kit_lang, surface, word, "tonal_note")
    change = plan_tone_claim_change(target, lookup)
    if change is not None:
        apply_change(target, change)
    else:
        note = word.get("tonal_note")
        if isinstance(note, str) and note.strip() and not note.strip().startswith("tone_pattern:"):
            word["tonal_note"] = None
    return True


def rebuild_word_card(
    word: dict[str, Any],
    lookup: LexiconLookup | None = None,
) -> tuple[dict[str, Any], dict[str, int]]:
    out = dict(word)
    counts = {"topics_restored": 0, "p0_17_cleared": 0, "phonetic_rebuilt": 0}
    kit_lang = kit_lang_for(out.get("language"))

    if is_truncated_topic(out.get("topic")):
        restored = topic_restoration(out)
        if restored:
            out["topic"] = restored
            counts["topics_restored"] = 1

    if clear_p0_17_tone_rule(out, lookup, kit_lang):
        counts["p0_17_cleared"] = 1

    if rebuild_phonetic_guide(out, lookup, kit_lang):
        counts["phonetic_rebuilt"] = 1

    return out, counts


def lint_word_card(word: Mapping[str, Any]) -> tuple[LintFinding, ...]:
    findings: list[LintFinding] = []
    wid = word.get("id", "?")

    topic = word.get("topic")
    if is_truncated_topic(topic):
        findings.append(
            LintFinding(
                RULE_WC002,
                wid,
                "topic",
                f"truncated mid-parenthesis: {topic!r}",
            ),
        )

    guide = word.get("phonetic_guide")
    note = word.get("tonal_note")
    guide_s = guide.strip() if isinstance(guide, str) else ""
    note_s = note.strip() if isinstance(note, str) else ""
    if guide_s and note_s and guide_s == note_s:
        findings.append(
            LintFinding(
                RULE_WC001,
                wid,
                "phonetic_guide",
                "phonetic_guide equals tonal_note",
            ),
        )
    return tuple(findings)


def lint_word_cards(words: Sequence[Mapping[str, Any]]) -> tuple[LintFinding, ...]:
    out: list[LintFinding] = []
    for word in words:
        out.extend(lint_word_card(word))
    return tuple(out)


def rebuild_game_words(
    words: Sequence[Mapping[str, Any]],
    lookup: LexiconLookup | None = None,
) -> tuple[list[dict[str, Any]], RebuildStats]:
    rebuilt: list[dict[str, Any]] = []
    topics = p0 = phonetic = 0
    for row in words:
        if not isinstance(row, dict):
            continue
        new_row, counts = rebuild_word_card(row, lookup)
        rebuilt.append(new_row)
        topics += counts["topics_restored"]
        p0 += counts["p0_17_cleared"]
        phonetic += counts["phonetic_rebuilt"]
    stats = RebuildStats(
        words=len(rebuilt),
        topics_restored=topics,
        p0_17_cleared=p0,
        phonetic_rebuilt=phonetic,
    )
    return rebuilt, stats


def run_rebuild(
    root: Path | None = None,
    *,
    dry_run: bool = False,
    game_path: Path | None = None,
    lexicon_lookup: LexiconLookup | None = None,
) -> tuple[RebuildStats, tuple[LintFinding, ...], Path]:
    if game_path is not None:
        game_file = game_path
    else:
        game_file = repo_root(root) / DEFAULT_GAME_CONTENT
    data = json.loads(game_file.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise TypeError("game content root must be an object")
    words = data.get("words")
    if not isinstance(words, list):
        raise ValueError("game content missing words array")

    rebuilt, stats = rebuild_game_words(words, lexicon_lookup)
    findings = lint_word_cards(rebuilt)
    if not dry_run:
        data["words"] = rebuilt
        game_file.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return stats, findings, game_file


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Rebuild legacy Word Card fields (P5-004).")
    parser.add_argument("--dry-run", action="store_true", help="Compute changes without writing.")
    parser.add_argument("--repo-root", type=Path, default=None)
    parser.add_argument("--game-content", type=Path, default=None)
    parser.add_argument(
        "--lint-only",
        action="store_true",
        help="Lint current game_content without rebuilding.",
    )
    args = parser.parse_args(argv)

    base = repo_root(args.repo_root)
    game_file = args.game_content if args.game_content is not None else base / DEFAULT_GAME_CONTENT
    if args.lint_only:
        data = json.loads(game_file.read_text(encoding="utf-8"))
        words = data.get("words") if isinstance(data, dict) else []
        findings = lint_word_cards(words if isinstance(words, list) else [])
        for f in findings:
            print(f"lint\t{f.rule_id}\tid={f.word_id}\t{f.field}\t{f.detail}")
        return 1 if findings else 0

    stats, findings, path = run_rebuild(
        args.repo_root,
        dry_run=args.dry_run,
        game_path=args.game_content,
    )
    print(
        f"words={stats.words}\ttopics_restored={stats.topics_restored}\t"
        f"p0_17_cleared={stats.p0_17_cleared}\tphonetic_rebuilt={stats.phonetic_rebuilt}",
    )
    for f in findings:
        print(f"lint\t{f.rule_id}\tid={f.word_id}\t{f.field}\t{f.detail}")
    if findings:
        return 1
    if not args.dry_run:
        print(f"game_content\t{path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

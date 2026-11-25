#!/usr/bin/env python3
"""P10-938: Lint English UI strings in app_en.arb (em dash, banned copy, verb-first buttons)."""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ARB = ROOT / "lib" / "l10n" / "app_en.arb"
DEFAULT_BANNED = Path(__file__).resolve().parent / "banned_words.txt"

EM_DASH = "\u2014"
BUTTON_DESC_RE = re.compile(r"button", re.IGNORECASE)
FIRST_WORD_RE = re.compile(r"^[\s(]*([A-Za-z]+)")

# Imperative / verb-led UI labels (first word must match, case-insensitive).
VERB_FIRST_WORDS = frozenset(
    {
        "add",
        "apply",
        "cancel",
        "close",
        "confirm",
        "continue",
        "delete",
        "edit",
        "end",
        "finish",
        "go",
        "hear",
        "interrupt",
        "join",
        "learn",
        "leave",
        "listen",
        "log",
        "move",
        "open",
        "play",
        "publish",
        "reconnect",
        "refresh",
        "remove",
        "retry",
        "save",
        "see",
        "send",
        "share",
        "show",
        "sign",
        "skip",
        "start",
        "starting",
        "stop",
        "submit",
        "take",
        "try",
    }
)


@dataclass(frozen=True)
class LintFinding:
    key: str
    rule: str
    message: str


def load_banned_words(path: Path) -> list[str]:
    words: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        token = line.strip()
        if not token or token.startswith("#"):
            continue
        words.append(token)
    return words


def parse_arb(path: Path) -> tuple[dict[str, str], dict[str, dict]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    strings: dict[str, str] = {}
    meta: dict[str, dict] = {}
    for key, value in data.items():
        if key.startswith("@@"):
            continue
        if key.startswith("@") and isinstance(value, dict):
            meta[key[1:]] = value
        elif isinstance(value, str) and not key.startswith("@"):
            strings[key] = value
    return strings, meta


def is_button_label(key: str, meta: dict[str, dict]) -> bool:
    if key.endswith("Button"):
        return True
    entry = meta.get(key)
    if not entry:
        return False
    desc = entry.get("description", "")
    if not isinstance(desc, str):
        return False
    if "tab label" in desc.lower():
        return False
    return bool(BUTTON_DESC_RE.search(desc))


def first_word(text: str) -> str | None:
    m = FIRST_WORD_RE.match(text.strip())
    return m.group(1) if m else None


def lint_string_value(key: str, text: str, banned: list[str]) -> list[LintFinding]:
    findings: list[LintFinding] = []
    if EM_DASH in text:
        findings.append(
            LintFinding(key, "EM_DASH", f"{key}: UI string must not contain an em dash (U+2014)")
        )
    lower = text.lower()
    for word in banned:
        if re.search(rf"\b{re.escape(word)}\b", lower):
            findings.append(
                LintFinding(key, "BANNED_WORD", f"{key}: banned product copy contains '{word}'")
            )
    return findings


def lint_button_verb(key: str, text: str) -> LintFinding | None:
    word = first_word(text)
    if not word:
        return LintFinding(key, "BUTTON_NOT_VERB", f"{key}: button label has no leading verb")
    if word.lower() not in VERB_FIRST_WORDS:
        return LintFinding(
            key,
            "BUTTON_NOT_VERB",
            f"{key}: button label must start with a verb (got '{word}')",
        )
    return None


def lint_arb(arb_path: Path, banned_path: Path) -> list[LintFinding]:
    banned = load_banned_words(banned_path)
    strings, meta = parse_arb(arb_path)
    findings: list[LintFinding] = []
    for key, text in strings.items():
        findings.extend(lint_string_value(key, text, banned))
        if is_button_label(key, meta):
            verb_issue = lint_button_verb(key, text)
            if verb_issue:
                findings.append(verb_issue)
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description="Lint LingAfriq English UI strings (P10-938)")
    parser.add_argument("--arb", type=Path, default=DEFAULT_ARB)
    parser.add_argument("--banned", type=Path, default=DEFAULT_BANNED)
    args = parser.parse_args()

    if not args.arb.is_file():
        print(f"ARB file missing: {args.arb}", file=sys.stderr)
        return 1
    if not args.banned.is_file():
        print(f"Banned words file missing: {args.banned}", file=sys.stderr)
        return 1

    findings = lint_arb(args.arb, args.banned)
    if findings:
        for f in findings:
            print(f"{f.rule}: {f.message}", file=sys.stderr)
        return 1
    print(f"OK: {args.arb} ({len(parse_arb(args.arb)[0])} strings)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

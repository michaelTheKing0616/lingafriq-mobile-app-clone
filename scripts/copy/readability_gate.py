#!/usr/bin/env python3
"""P10-939: Grade-7 readability gate for English UI strings in app_en.arb."""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.copy.lint_ui_strings import parse_arb  # noqa: E402
DEFAULT_ARB = ROOT / "lib" / "l10n" / "app_en.arb"

MIN_WORDS_FOR_GRADE = 8
MAX_GRADE = 7.0

# Curated sample for AC3 warm-copy checklist (20 strings).
SAMPLE_REVIEW_KEYS: tuple[str, ...] = (
    "flbHeritageEmptyMessage",
    "gameWordMatchConnectMeaningSubtitle",
    "labelBetaCopy",
    "pron_unavailable",
    "persona_error_retry",
    "liveTranslateSpeechUnavailable",
    "flbHeritageLoadError",
    "liveTranslateConnectionLost",
    "persona_ai_disclosure",
    "liveTranslateCouldNotPlayAudio",
    "content_not_available_yet",
    "liveTranslateMicPermissionRequired",
    "flbHeritageSearchHint",
    "liveTranslateSourceLanguageLabel",
    "liveTranslateTargetLanguageLabel",
    "liveTranslateInvalidSession",
    "flbHeritageMissingContent",
    "welcomeMessage",
    "polieTutorNoSavedCardsYet",
    "pron_scoring_soon",
)

WORD_RE = re.compile(r"[A-Za-z']+")
NON_ENGLISH_SCRIPT_RE = re.compile(
    r"[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\u0900-\u097F"
    r"\u0980-\u09FF\u0E00-\u0E7F\u4E00-\u9FFF\u3040-\u30FF\u0400-\u04FF]"
)
PLACEHOLDER_RE = re.compile(r"\b(TODO|FIXME|Lorem|lorem ipsum|xxx)\b", re.IGNORECASE)
ROBOTIC_RE = re.compile(
    r"\b(please be advised|kindly note that|at this time we|utilize|leverage)\b",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class GateFinding:
    key: str
    rule: str
    message: str


@dataclass(frozen=True)
class SkippedString:
    key: str
    reason: str


def count_words(text: str) -> int:
    return len(WORD_RE.findall(text))


def flesch_kincaid_grade(text: str) -> float:
    sentences = max(1, len(re.findall(r"[.!?]+", text)))
    words = WORD_RE.findall(text)
    word_count = max(1, len(words))
    syllables = 0
    for w in words:
        groups = re.findall(r"[aeiouy]+", w.lower())
        syllables += max(1, len(groups))
    return 0.39 * (word_count / sentences) + 11.8 * (syllables / word_count) - 15.59


def is_probably_english(text: str) -> bool:
    if NON_ENGLISH_SCRIPT_RE.search(text):
        return False
    letters = re.findall(r"[A-Za-z]", text)
    if not letters:
        return False
    ascii_letters = sum(1 for c in letters if ord(c) < 128)
    return ascii_letters / len(letters) >= 0.85


def warmth_check(key: str, text: str) -> list[GateFinding]:
    findings: list[GateFinding] = []
    if PLACEHOLDER_RE.search(text):
        findings.append(
            GateFinding(key, "COPY_PLACEHOLDER", f"{key}: copy must not contain placeholder text")
        )
    if ROBOTIC_RE.search(text):
        findings.append(
            GateFinding(key, "COPY_ROBOTIC", f"{key}: copy sounds robotic or corporate")
        )
    stripped = text.strip()
    if len(stripped) < 3:
        findings.append(GateFinding(key, "COPY_TOO_SHORT", f"{key}: copy is too short to be useful"))
    return findings


def gate_string(key: str, text: str) -> tuple[list[GateFinding], SkippedString | None]:
    if not is_probably_english(text):
        return [], SkippedString(key, "non_english")
    findings: list[GateFinding] = []
    if count_words(text) >= MIN_WORDS_FOR_GRADE:
        grade = flesch_kincaid_grade(text)
        if grade > MAX_GRADE:
            findings.append(
                GateFinding(
                    key,
                    "READABILITY_GRADE",
                    f"{key}: Flesch-Kincaid grade {grade:.1f} exceeds {MAX_GRADE} (8+ words)",
                )
            )
    return findings, None


def gate_arb(arb_path: Path) -> tuple[list[GateFinding], list[SkippedString]]:
    strings, _meta = parse_arb(arb_path)
    findings: list[GateFinding] = []
    skipped: list[SkippedString] = []
    for key, text in strings.items():
        hits, skip = gate_string(key, text)
        findings.extend(hits)
        if skip:
            skipped.append(skip)
    return findings, skipped


def sample_review(arb_path: Path) -> list[GateFinding]:
    strings, _meta = parse_arb(arb_path)
    findings: list[GateFinding] = []
    missing: list[str] = []
    for key in SAMPLE_REVIEW_KEYS:
        text = strings.get(key)
        if text is None:
            missing.append(key)
            continue
        findings.extend(warmth_check(key, text))
    if missing:
        findings.append(
            GateFinding(
                "SAMPLE_KEYS",
                "SAMPLE_KEY_MISSING",
                f"sample review keys missing from ARB: {', '.join(missing)}",
            )
        )
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description="Grade-7 readability gate (P10-939)")
    parser.add_argument("--arb", type=Path, default=DEFAULT_ARB)
    parser.add_argument("--sample-review", action="store_true", help="Run 20-string warm-copy checklist")
    args = parser.parse_args()

    if not args.arb.is_file():
        print(f"ARB file missing: {args.arb}", file=sys.stderr)
        return 1

    findings, skipped = gate_arb(args.arb)
    if args.sample_review:
        findings.extend(sample_review(args.arb))

    for s in skipped:
        print(f"SKIP: {s.key} ({s.reason})", file=sys.stdout)

    if findings:
        for f in findings:
            print(f"{f.rule}: {f.message}", file=sys.stderr)
        return 1

    strings, _ = parse_arb(args.arb)
    print(f"OK: {args.arb} ({len(strings)} strings, {len(skipped)} skipped)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

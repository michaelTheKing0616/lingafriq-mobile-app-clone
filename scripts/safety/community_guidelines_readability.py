#!/usr/bin/env python3
"""P9-933: Grade-8 readability gate for English community guidelines ARB."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ARB = ROOT / "lib" / "l10n" / "community_guidelines_en.arb"
MAX_GRADE = 8.0
RULE_BODY_PREFIX = "guidelines.rule."
EXAMPLE_SUFFIX = ".example"

WORD_RE = re.compile(r"[A-Za-z']+")


def flesch_kincaid_grade(text: str) -> float:
    sentences = max(1, len(re.findall(r"[.!?]+", text)))
    words = WORD_RE.findall(text)
    word_count = max(1, len(words))
    syllables = 0
    for w in words:
        groups = re.findall(r"[aeiouy]+", w.lower())
        syllables += max(1, len(groups))
    return 0.39 * (word_count / sentences) + 11.8 * (syllables / word_count) - 15.59


def main() -> int:
    if not ARB.is_file():
        print(f"missing {ARB}", file=sys.stderr)
        return 1
    data = json.loads(ARB.read_text(encoding="utf-8"))
    failures: list[str] = []
    for key, value in data.items():
        if not key.startswith(RULE_BODY_PREFIX) or not key.endswith(EXAMPLE_SUFFIX):
            continue
        if not isinstance(value, str) or not value.strip():
            failures.append(f"{key}: empty example")
            continue
        grade = flesch_kincaid_grade(value)
        if grade > MAX_GRADE:
            failures.append(f"{key}: grade {grade:.1f} > {MAX_GRADE}")
    if failures:
        for f in failures:
            print(f, file=sys.stderr)
        return 1
    print(f"OK: {ARB} rule examples at or below grade {MAX_GRADE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

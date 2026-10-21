#!/usr/bin/env python3
"""Fail the build when curriculum content contains placeholder or template text.

Usage: python3 scripts/ci/placeholder_linter.py <path> [<path> ...]

Each path may be a file or a directory (scanned recursively). Only content
files (see CONTENT_SUFFIXES) are inspected. Exit codes:
  0  no placeholder/template content found
  1  one or more files flagged; each is listed on stderr with the matched pattern
  2  usage error, missing path, or unreadable file
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

CONTENT_SUFFIXES = frozenset({".json", ".yaml", ".yml", ".csv", ".txt", ".md"})

PLACEHOLDER_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("lorem ipsum", re.compile(r"\blorem\s+ipsum\b", re.IGNORECASE)),
    ("TODO marker", re.compile(r"\bTODO\b")),
    ("TBD marker", re.compile(r"\bTBD\b")),
    ("[PLACEHOLDER] token", re.compile(r"\[\s*PLACEHOLDER\s*\]", re.IGNORECASE)),
    ("template lesson", re.compile(r"\btemplate\s+lesson\b", re.IGNORECASE)),
    ("numbered word slot", re.compile(r"\b(?:[A-Za-z]{2,4}_)?word\d+[a-z]?\b")),
    ("numbered meaning slot", re.compile(r"\bmeaning \d+[a-z]?\b")),
    ("stub gloss", re.compile(r"\bexample meaning\b", re.IGNORECASE)),
    ("stub vocab entry", re.compile(r'"word"\s*:\s*"example"\s*,\s*"meaning"\s*:\s*"sample"')),
    ("sample-format bundle", re.compile(r'"format"\s*:\s*"[^"]*\bsample\b[^"]*"', re.IGNORECASE)),
    ("numbered topic title", re.compile(r"\bTopic \d+ \((?:A1|A2|B1|B2|C1|C2)\)")),
    ("numbered objective slot", re.compile(r"\bCommunicative objective \d+\b")),
)


def iter_content_files(root: Path) -> list[Path]:
    """Return content files under root (or root itself if it is a content file), sorted."""
    if root.is_file():
        return [root] if root.suffix.lower() in CONTENT_SUFFIXES else []
    return sorted(
        p for p in root.rglob("*") if p.is_file() and p.suffix.lower() in CONTENT_SUFFIXES
    )


def find_placeholder_patterns(text: str) -> list[str]:
    """Return the names of every placeholder pattern present in text."""
    return [name for name, pattern in PLACEHOLDER_PATTERNS if pattern.search(text)]


def main(argv: list[str]) -> int:
    if not argv:
        print("usage: placeholder_linter.py <path> [<path> ...]", file=sys.stderr)
        return 2

    flagged: list[tuple[Path, list[str]]] = []
    for raw in argv:
        root = Path(raw)
        if not root.exists():
            print(f"placeholder_linter: path not found: {root}", file=sys.stderr)
            return 2
        for path in iter_content_files(root):
            try:
                text = path.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError) as error:
                print(f"placeholder_linter: cannot read {path}: {error}", file=sys.stderr)
                return 2
            matches = find_placeholder_patterns(text)
            if matches:
                flagged.append((path, matches))

    if flagged:
        print(
            f"placeholder_linter: {len(flagged)} file(s) contain placeholder/template content:",
            file=sys.stderr,
        )
        for path, matches in flagged:
            print(f"  {path}: {', '.join(matches)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

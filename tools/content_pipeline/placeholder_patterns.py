"""Placeholder text patterns for v2 content CI (P4-106). No bypass flag."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

PLACEHOLDER_RE = re.compile(r"word\d|\bexample\b|\bsample\b|\blorem\b", re.IGNORECASE)


@dataclass(frozen=True)
class PlaceholderHit:
    path: Path
    line: int
    column: int
    matched: str


def scan_file(path: Path) -> list[PlaceholderHit]:
    """Scan one text file line-by-line for forbidden placeholder markers."""
    hits: list[PlaceholderHit] = []
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return hits
    for line_no, line in enumerate(text.splitlines(), start=1):
        for match in PLACEHOLDER_RE.finditer(line):
            hits.append(
                PlaceholderHit(
                    path=path,
                    line=line_no,
                    column=match.start() + 1,
                    matched=match.group(0),
                )
            )
    return hits


def scan_tree(root: Path) -> list[PlaceholderHit]:
    """Scan JSON and JSONL files under root (skips .git)."""
    if root.is_file():
        return scan_file(root) if root.suffix.lower() in {".json", ".jsonl"} else []

    hits: list[PlaceholderHit] = []
    for path in sorted(root.rglob("*")):
        if not path.is_file() or ".git" in path.parts:
            continue
        if path.suffix.lower() not in {".json", ".jsonl"}:
            continue
        hits.extend(scan_file(path))
    return hits

#!/usr/bin/env python3
# charter: v2
"""Fail CI when a word copies phonetic_guide onto tonal_note.

Usage: python3 scripts/ci/check_tone_claims.py <json-file>

Exit codes:
  0  no word has a non-empty phonetic_guide equal to tonal_note
  1  one or more copied tone claims
  2  usage error, missing path, or unreadable file
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def words_of(data: object) -> list[dict]:
    if isinstance(data, list):
        return [w for w in data if isinstance(w, dict)]
    if isinstance(data, dict):
        for key in ("words", "vocabulary", "items"):
            val = data.get(key)
            if isinstance(val, list):
                return [w for w in val if isinstance(w, dict)]
    return []


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        sys.stderr.write("Usage: python3 scripts/ci/check_tone_claims.py <json-file>\n")
        return 2
    path = Path(argv[1])
    if not path.is_file():
        sys.stderr.write(f"missing file: {path}\n")
        return 2
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        sys.stderr.write(f"unreadable json: {path}: {exc}\n")
        return 2

    copied = 0
    for word in words_of(data):
        guide = word.get("phonetic_guide") or ""
        note = word.get("tonal_note")
        if guide and guide == note:
            copied += 1
            sys.stderr.write(f"copied phonetic_guide==tonal_note id={word.get('id')}\n")
    if copied:
        sys.stderr.write(f"{copied} word(s) copy phonetic_guide onto tonal_note\n")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

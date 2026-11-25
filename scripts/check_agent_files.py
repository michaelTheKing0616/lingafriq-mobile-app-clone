#!/usr/bin/env python3
"""T0 gate: every agent-facing file must carry the `charter: v2` reference (charter: v2).

Usage:
  python3 scripts/check_agent_files.py            # check all agent-facing files
  python3 scripts/check_agent_files.py --staged   # pre-commit: only staged files
  python3 scripts/check_agent_files.py --diff <base>  # CI: files changed vs <base>

Agent-facing files: .cursor/rules/*.mdc, AGENTS.md, docs/build/templates/*,
docs/build/cards/**/*.yaml, docs/build/briefs/**/*, docs/build/*_BRIEF.md,
docs/build/rtm_parts/EXTRACTION_BRIEF.md, and any *.md/*.yaml/*.mdc/*.txt under
.cursor/ or docs/build/ whose name contains agent|prompt|brief|card|rule.
Exit 1 lists each offending file. No network, no model.
"""
from __future__ import annotations

import fnmatch
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARKER = re.compile(r"charter:\s*v2")
PATTERNS = [
    ".cursor/rules/*.mdc",
    "AGENTS.md",
    "docs/build/templates/*",
    "docs/build/cards/**/*.yaml",
    "docs/build/briefs/**/*",
    "docs/build/*_BRIEF.md",
    "docs/build/rtm_parts/EXTRACTION_BRIEF.md",
]
NAME_HINT = re.compile(r"agent|prompt|brief|card|rule", re.I)
TEXT_SUFFIXES = {".md", ".mdc", ".yaml", ".yml", ".txt"}


def is_agent_facing(rel: str) -> bool:
    if any(fnmatch.fnmatch(rel, p) for p in PATTERNS):
        return True
    path = Path(rel)
    in_scope = rel.startswith(".cursor/") or rel.startswith("docs/build/")
    return in_scope and path.suffix in TEXT_SUFFIXES and bool(NAME_HINT.search(path.name))


def candidate_files(argv: list[str]) -> list[Path]:
    if "--staged" in argv:
        out = subprocess.run(["git", "diff", "--cached", "--name-only", "--diff-filter=AM"], cwd=ROOT, capture_output=True, text=True, check=True).stdout
        return [ROOT / l for l in out.splitlines() if l]
    if "--diff" in argv:
        base = argv[argv.index("--diff") + 1]
        out = subprocess.run(["git", "diff", "--name-only", "--diff-filter=AM", base], cwd=ROOT, capture_output=True, text=True, check=True).stdout
        return [ROOT / l for l in out.splitlines() if l]
    # Only the directories that can hold agent-facing files; skips vendored and generated trees.
    roots = [ROOT / ".cursor", ROOT / "docs" / "build", ROOT / "AGENTS.md"]
    files: list[Path] = []
    for r in roots:
        if r.is_file():
            files.append(r)
        elif r.is_dir():
            files.extend(p for p in r.rglob("*") if p.is_file())
    return files


def main(argv: list[str]) -> int:
    failures: list[str] = []
    checked = 0
    for path in candidate_files(argv):
        rel = path.relative_to(ROOT).as_posix()
        if not is_agent_facing(rel) or not path.exists():
            continue
        checked += 1
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError as exc:
            failures.append(f"{rel}: unreadable ({exc})")
            continue
        if not MARKER.search(text):
            failures.append(f"{rel}: missing `charter: v2`")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        print(f"check_agent_files: {len(failures)} failure(s) in {checked} file(s)", file=sys.stderr)
        return 1
    print(f"check_agent_files: OK ({checked} agent-facing file(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""Fail UI copy that boasts, fakes a precise score, or uses an em dash.

Rules:
- banned-word: World-class, Elite, or Seamless inside a user-visible string
- em-dash: an em dash inside a user-visible string
- fake-confidence: a numeric literal assigned to confidence, not a measured field

Comments are not UI copy. Generated localisation files are not scanned.
A recorded baseline may hold existing hits. A new hit fails CI and names the
rule, file, and line.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

BANNED = re.compile(r"\b(?:world-class|world class|elite|seamless)\b", re.IGNORECASE)
EM_DASH = "—"
STRINGS = re.compile(r"""('(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")""")
FAKE_CONFIDENCE = re.compile(
    r"\bconfidence\s*[:=]\s*(?:\d+(?:\.\d+)?|'[^']*'|\"[^\"]*\")",
)
SKIP_PARTS = {"generated", ".dart_tool"}


def _ui_lines(path: Path) -> list[tuple[int, str]]:
    rows = []
    for index, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        stripped = line.strip()
        if stripped.startswith("//") or stripped.startswith("*") or stripped.startswith("/*"):
            continue
        code = line.split("//", 1)[0]
        rows.append((index, code))
    return rows


def scan(root: Path) -> list[tuple[str, str, int, str]]:
    findings = []
    lib = root / "lib"
    if not lib.exists():
        return findings
    for path in sorted(lib.rglob("*.dart")):
        if any(part in SKIP_PARTS for part in path.parts):
            continue
        rel = path.relative_to(root).as_posix()
        for index, code in _ui_lines(path):
            for match in STRINGS.finditer(code):
                literal = match.group(0)
                if BANNED.search(literal):
                    word = BANNED.search(literal).group(0)
                    findings.append(("banned-word", rel, index, word))
                if EM_DASH in literal:
                    findings.append(("em-dash", rel, index, EM_DASH))
                if re.search(r"confidence", literal, re.IGNORECASE) and re.search(r"\d", literal):
                    findings.append(("fake-confidence", rel, index, "confidence"))
            in_ui = rel.startswith("lib/screens/") or rel.startswith("lib/widgets/")
            if in_ui and FAKE_CONFIDENCE.search(code):
                findings.append(("fake-confidence", rel, index, "confidence"))
    return findings


def _key(item: tuple[str, str, int, str]) -> str:
    rule, path, line, detail = item
    return f"{rule}\t{path}:{line}\t{detail}"


def load_baseline(path: Path) -> set[str]:
    if not path.exists():
        return set()
    raw = json.loads(path.read_text(encoding="utf-8"))
    return set(raw.get("allowed", []))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--baseline", default="scripts/lint/honest_copy_baseline.json")
    parser.add_argument("--write-baseline", action="store_true")
    args = parser.parse_args(argv)
    root = Path(args.root)
    baseline_path = Path(args.baseline)
    if not baseline_path.is_absolute():
        baseline_path = root / baseline_path
    findings = scan(root)
    keys = sorted({_key(item) for item in findings})
    if args.write_baseline:
        baseline_path.write_text(
            json.dumps({"allowed": keys}, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"honest-copy: wrote {len(keys)}")
        return 0
    allowed = load_baseline(baseline_path)
    fresh = [item for item in findings if _key(item) not in allowed]
    if not fresh:
        print(f"honest-copy: {len(findings)} recorded, 0 new")
        return 0
    lines = ["honest-copy: fail"]
    for rule, path, line, detail in fresh[:13]:
        lines.append(f"{rule} {path}:{line} {detail}")
    if len(fresh) > 13:
        lines.append(f"+{len(fresh) - 13} more")
    print("\n".join(lines))
    return 1


if __name__ == "__main__":
    sys.exit(main())

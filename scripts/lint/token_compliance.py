#!/usr/bin/env python3
"""Fail when new design code leaves the token set, and ratchet colour literals.

Rules:
- color-literal: Color(0x...) anywhere under lib/ or widgetbook/
- font-family, font-size, spacing-literal, user-string: lib/design/ and widgetbook/ only

A file absent from the colour baseline is allowed zero colour literals.
A baselined file may not exceed its recorded count. The run prints the count.
A failing run exits 1 and prints at most 15 lines.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

COLOR = ("color-literal", r"Color\s*\(\s*0x[0-9A-Fa-f]+")
FONT_FAMILY = ("font-family", r"""fontFamily\s*:\s*['\"]""")
FONT_SIZE = ("font-size", r"fontSize\s*:\s*\d")
SPACING = ("spacing-literal", r"EdgeInsets(?:\.\w+)?\(\s*\d+(?:\.\d+)?")
USER_STRING = ("user-string", r"""\bText\s*\(\s*['\"]""")

STRICT_PREFIXES = ("lib/design/", "widgetbook/")
SCAN_PREFIXES = ("lib/", "widgetbook/")
SUMMARY_LIMIT = 15


def _compile():
    import re

    return [(rule, re.compile(pattern)) for rule, pattern in (
        COLOR, FONT_FAMILY, FONT_SIZE, SPACING, USER_STRING,
    )]


RULES = _compile()


def rel_path(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def dart_files(root: Path) -> list[Path]:
    found = []
    for prefix in SCAN_PREFIXES:
        base = root / prefix
        if not base.exists():
            continue
        found.extend(p for p in base.rglob("*.dart") if p.is_file())
    return sorted(found)


def line_hits(text: str, pattern) -> list[int]:
    hits = []
    for index, line in enumerate(text.splitlines(), start=1):
        if pattern.search(line):
            hits.append(index)
    return hits


def colour_counts(root: Path) -> dict[str, int]:
    pattern = dict(RULES)["color-literal"]
    counts = {}
    for path in dart_files(root):
        hits = line_hits(path.read_text(encoding="utf-8"), pattern)
        if hits:
            counts[rel_path(path, root)] = len(hits)
    return counts


def lint(root: Path, baseline: dict[str, int]) -> list[tuple[str, str, int]]:
    findings = []
    by_rule = dict(RULES)
    for path in dart_files(root):
        rel = rel_path(path, root)
        text = path.read_text(encoding="utf-8")
        colour_lines = line_hits(text, by_rule["color-literal"])
        allowed = baseline.get(rel, 0)
        if len(colour_lines) > allowed:
            for line in colour_lines:
                findings.append(("color-literal", rel, line))
        if rel.startswith(STRICT_PREFIXES):
            for rule in ("font-family", "font-size", "spacing-literal", "user-string"):
                for line in line_hits(text, by_rule[rule]):
                    findings.append((rule, rel, line))
    return findings


def summary(findings: list[tuple[str, str, int]], total: int, baseline_total: int) -> str:
    if not findings:
        return f"token-compliance: color-literal {total} (baseline {baseline_total})\n"
    rows = [f"{rule} {path}:{line}" for rule, path, line in findings]
    header = "token-compliance: fail"
    body_budget = SUMMARY_LIMIT - 1
    if len(rows) <= body_budget:
        lines = [header, *rows]
    else:
        kept = rows[: body_budget - 1]
        hidden = len(rows) - len(kept)
        lines = [header, *kept, f"+{hidden} more"]
    return "\n".join(lines) + "\n"


def load_baseline(path: Path) -> dict[str, int]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    counts = raw["colorLiteral"]
    return {key: int(counts[key]) for key in counts}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--baseline", default="scripts/lint/token_baseline.json")
    parser.add_argument("--write-baseline", action="store_true")
    args = parser.parse_args(argv)
    root = Path(args.root)
    baseline_path = Path(args.baseline)
    if not baseline_path.is_absolute():
        baseline_path = root / baseline_path
    counts = colour_counts(root)
    if args.write_baseline:
        payload = {"colorLiteral": counts}
        baseline_path.parent.mkdir(parents=True, exist_ok=True)
        baseline_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        print(f"token-compliance: wrote {sum(counts.values())} color-literal")
        return 0
    baseline = load_baseline(baseline_path)
    findings = lint(root, baseline)
    text = summary(findings, sum(counts.values()), sum(baseline.values()))
    sys.stdout.write(text)
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())

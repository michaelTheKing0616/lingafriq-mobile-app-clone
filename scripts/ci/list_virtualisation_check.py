#!/usr/bin/env python3
# charter: v2
"""P12-010: List virtualisation + prefer_const baseline gate for lib/screens.

Usage:
  python3 scripts/ci/list_virtualisation_check.py [--root .]
  python3 scripts/ci/list_virtualisation_check.py --check-const-baseline
  python3 scripts/ci/list_virtualisation_check.py --self-test

Exit codes:
  0  pass
  1  violation (stderr lists file:line)
  2  usage / missing baseline / flutter analyze failed
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

DEFAULT_ROOT = Path(__file__).resolve().parents[2]
SCREENS_GLOB = "lib/screens"
CONST_BASELINE = Path(__file__).resolve().parent / "p12_010_prefer_const_baseline.tsv"

LIST_VIEW_RE = re.compile(r"\bListView\b")
LIST_VIEW_VARIANT_RE = re.compile(r"^\s*\.\s*(builder|separated|custom)\s*\(")
EAGER_CHILDREN_RE = re.compile(
    r"children\s*:\s*([a-zA-Z_]\w*)\s*\.\s*map\s*\(",
)
SPREAD_MAP_RE = re.compile(r"\.\.\.\s*[a-zA-Z_]\w*\s*\.\s*map\s*\(")
FOR_IN_RE = re.compile(r"\bfor\s*\(\s*final\s+\w+\s+in\s+([a-zA-Z_]\w*)")
PREFER_CONST_RULES = frozenset(
    {"prefer_const_constructors", "prefer_const_literals_to_create_immutables"},
)


def _matching_paren_end(text: str, open_idx: int) -> int:
    depth = 0
    i = open_idx
    while i < len(text):
        ch = text[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
        elif ch in "\"'":
            quote = ch
            i += 1
            while i < len(text):
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == quote:
                    break
                i += 1
        i += 1
    return -1


def find_listview_violations(path: Path, rel: str) -> list[str]:
    try:
        source = path.read_text(encoding="utf-8")
    except OSError as exc:
        return [f"{rel}:0 LISTVIEW_READ_ERROR {exc}"]

    errors: list[str] = []
    for match in LIST_VIEW_RE.finditer(source):
        start = match.start()
        after = source[match.end() :]
        if LIST_VIEW_VARIANT_RE.match(after):
            continue
        open_paren = source.find("(", match.end())
        if open_paren < 0:
            continue
        end_paren = _matching_paren_end(source, open_paren)
        if end_paren < 0:
            continue
        block = source[open_paren : end_paren + 1]
        if "children:" not in block:
            continue
        line = source[:start].count("\n") + 1
        if EAGER_CHILDREN_RE.search(block) or SPREAD_MAP_RE.search(block):
            errors.append(f"{rel}:{line} LISTVIEW_EAGER_CHILDREN")
            continue
        for for_match in FOR_IN_RE.finditer(block):
            collection = for_match.group(1)
            if collection in {"const", "widgets"}:
                continue
            errors.append(f"{rel}:{line} LISTVIEW_EAGER_CHILDREN")
            break
    return errors


def scan_screens(root: Path) -> list[str]:
    screens = root / SCREENS_GLOB
    if not screens.is_dir():
        return [f"{SCREENS_GLOB}:0 SCREENS_DIR_MISSING"]
    errors: list[str] = []
    for path in sorted(screens.rglob("*.dart")):
        rel = path.relative_to(root).as_posix()
        errors.extend(find_listview_violations(path, rel))
    return errors


def load_const_baseline(path: Path) -> set[tuple[str, str, str]]:
    if not path.is_file():
        raise FileNotFoundError(f"CONST_BASELINE_MISSING: {path}")
    rows: set[tuple[str, str, str]] = set()
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) != 3:
            raise ValueError(f"CONST_BASELINE_INVALID: {raw}")
        rows.add((parts[0], parts[1], parts[2]))
    return rows


def run_flutter_analyze_const(root: Path) -> set[tuple[str, str, str]]:
    flutter = "flutter"
    proc = subprocess.run(
        [flutter, "analyze"],
        cwd=root,
        capture_output=True,
        text=True,
        check=False,
    )
    combined = proc.stdout + proc.stderr
    if proc.returncode not in (0, 1):
        raise RuntimeError(f"FLUTTER_ANALYZE_FAILED: exit {proc.returncode}\n{combined[:2000]}")
    hits: set[tuple[str, str, str]] = set()
    for line in combined.splitlines():
        if "prefer_const_" not in line:
            continue
        parts = [p.strip() for p in line.split(" • ")]
        if len(parts) < 4:
            continue
        rule = parts[3]
        if rule not in PREFER_CONST_RULES:
            continue
        loc = parts[2]
        if ":" not in loc:
            continue
        path, ln, _col = loc.split(":", 2)
        hits.add((path.strip(), ln, rule))
    return hits


def check_const_baseline(root: Path, baseline_path: Path) -> list[str]:
    baseline = load_const_baseline(baseline_path)
    current = run_flutter_analyze_const(root)
    new_hits = current - baseline
    if new_hits:
        return sorted(f"{p}:{ln} {rule} CONST_BASELINE_NEW" for p, ln, rule in new_hits)
    if len(current) > len(baseline):
        return [f"CONST_BASELINE_COUNT_GROWTH current={len(current)} baseline={len(baseline)}"]
    return []


def self_test() -> int:
    import tempfile

    bad = """
import 'package:flutter/material.dart';
class W extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <String>['a','b'];
    return ListView(children: items.map((e) => Text(e)).toList());
  }
}
"""
    good = """
import 'package:flutter/material.dart';
class W extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemCount: 0, itemBuilder: (_, __) => const SizedBox());
  }
}
"""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        screens = root / "lib" / "screens"
        screens.mkdir(parents=True)
        (screens / "bad.dart").write_text(bad, encoding="utf-8")
        (screens / "good.dart").write_text(good, encoding="utf-8")
        errs = scan_screens(root)
        if len(errs) != 1 or "bad.dart" not in errs[0]:
            print(f"self-test listview failed: {errs}", file=sys.stderr)
            return 1
    print("self-test ok")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="P12-010 list virtualisation + const baseline")
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--check-const-baseline", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        return self_test()

    errors: list[str] = []
    if args.check_const_baseline:
        try:
            errors.extend(check_const_baseline(args.root, CONST_BASELINE))
        except (FileNotFoundError, ValueError, RuntimeError) as exc:
            print(str(exc), file=sys.stderr)
            return 2
        return 1 if errors else 0

    errors.extend(scan_screens(args.root))
    try:
        errors.extend(check_const_baseline(args.root, CONST_BASELINE))
    except (FileNotFoundError, ValueError, RuntimeError) as exc:
        print(str(exc), file=sys.stderr)
        return 2

    if errors:
        for err in errors:
            print(err, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

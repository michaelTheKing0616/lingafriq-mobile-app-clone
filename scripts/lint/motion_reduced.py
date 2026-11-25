#!/usr/bin/env python3
"""Fail a new design animation that ignores reduced motion.

Scans Dart added under lib/design/ in the git diff against
origin/cloud-handoff. Added lines that use AnimationController or
TweenAnimationBuilder fail when those added lines do not read
disableAnimations or LingMotionScope. Existing app screens are not scanned.
Pass --root to treat a fixture tree's lib/design Dart as all-new lines.
This is not a whole-repo scan.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ANIM = re.compile(r"\b(?:AnimationController|TweenAnimationBuilder)\b")
READ = re.compile(r"\bdisableAnimations\w*\b|\bLingMotionScope\b")


def mask_non_code(src: str) -> str:
    chars = list(src)
    index = 0
    length = len(chars)
    while index < length:
        if chars[index] == "/" and index + 1 < length and chars[index + 1] == "/":
            while index < length and chars[index] != "\n":
                chars[index] = " "
                index += 1
            continue
        if chars[index] == "/" and index + 1 < length and chars[index + 1] == "*":
            chars[index] = " "
            chars[index + 1] = " "
            index += 2
            while index + 1 < length and not (chars[index] == "*" and chars[index + 1] == "/"):
                if chars[index] != "\n":
                    chars[index] = " "
                index += 1
            if index < length:
                chars[index] = " "
            if index + 1 < length:
                chars[index + 1] = " "
            index += 2
            continue
        if chars[index] == "r" and index + 1 < length and chars[index + 1] in "'\"":
            index += 1
            index = _mask_string(chars, index, raw=True)
            continue
        if chars[index] in "'\"":
            index = _mask_string(chars, index, raw=False)
            continue
        index += 1
    return "".join(chars)


def _mask_string(chars: list[str], index: int, raw: bool) -> int:
    quote = chars[index]
    triple = index + 2 < len(chars) and chars[index + 1] == quote and chars[index + 2] == quote
    chars[index] = " "
    index += 1
    if triple:
        chars[index] = " "
        chars[index + 1] = " "
        index += 2
        closer = quote * 3
        while index + 2 < len(chars) and "".join(chars[index : index + 3]) != closer:
            if not raw and chars[index] == "\\" and index + 1 < len(chars):
                if chars[index] != "\n":
                    chars[index] = " "
                index += 1
                if chars[index] != "\n":
                    chars[index] = " "
                index += 1
                continue
            if chars[index] != "\n":
                chars[index] = " "
            index += 1
        for _ in range(3):
            if index < len(chars):
                chars[index] = " "
                index += 1
        return index
    while index < len(chars):
        if not raw and chars[index] == "\\" and index + 1 < len(chars):
            chars[index] = " "
            index += 1
            if chars[index] != "\n":
                chars[index] = " "
            index += 1
            continue
        if chars[index] == quote or chars[index] == "\n":
            if chars[index] != "\n":
                chars[index] = " "
            return index + 1
        chars[index] = " "
        index += 1
    return index


def added_design_dart(root: Path, base: str) -> dict[str, set[int]]:
    proc = subprocess.run(
        ["git", "diff", "-U0", base, "--", "lib/design"],
        cwd=root,
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "git diff failed")
    files: dict[str, set[int]] = {}
    current: str | None = None
    new_line = 0
    for line in proc.stdout.splitlines():
        if line.startswith("+++ "):
            path = line[4:].strip().strip('"')
            if path.startswith("b/"):
                path = path[2:]
            if path.startswith("lib/design/") and path.endswith(".dart") and "/screens/" not in path:
                current = path
                files.setdefault(current, set())
            else:
                current = None
            continue
        if current is None:
            continue
        if line.startswith("@@"):
            match = re.search(r"\+(\d+)", line)
            new_line = int(match.group(1)) if match else 0
            continue
        if line.startswith("+"):
            files[current].add(new_line)
            new_line += 1
        elif line.startswith("-") or line.startswith("\\"):
            continue
        else:
            new_line += 1
    return files


def fixture_files(root: Path) -> dict[str, set[int]]:
    base = root / "lib" / "design"
    files: dict[str, set[int]] = {}
    if not base.is_dir():
        return files
    for path in sorted(base.rglob("*.dart")):
        if not path.is_file():
            continue
        rel = path.relative_to(root).as_posix()
        if not rel.startswith("lib/design/") or "/screens/" in rel:
            continue
        count = len(path.read_text(encoding="utf-8", errors="replace").splitlines())
        files[rel] = set(range(1, count + 1))
    return files


def findings_in(path: str, source: str, added_lines: set[int]) -> list[tuple[str, int]]:
    masked_lines = mask_non_code(source).splitlines()
    hits: list[int] = []
    reads = False
    for number in sorted(added_lines):
        if number < 1 or number > len(masked_lines):
            continue
        line = masked_lines[number - 1]
        if READ.search(line):
            reads = True
        if ANIM.search(line):
            hits.append(number)
    if not hits or reads:
        return []
    return [(path, number) for number in hits]


def scan(root: Path, files: dict[str, set[int]]) -> list[tuple[str, int]]:
    found: list[tuple[str, int]] = []
    for rel, added in sorted(files.items()):
        if rel.startswith("lib/screens/") or "/screens/" in rel:
            continue
        if not rel.startswith("lib/design/") or not rel.endswith(".dart"):
            continue
        path = root / rel
        if not path.is_file():
            continue
        source = path.read_text(encoding="utf-8", errors="replace")
        found.extend(findings_in(rel, source, added))
    return found


def collect(root: Path, base: str, fixture: bool) -> list[tuple[str, int]]:
    files = fixture_files(root) if fixture else added_design_dart(root, base)
    return scan(root, files)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        help="Fixture tree. Every lib/design Dart line counts as added. Skips git.",
    )
    parser.add_argument("--repo", help="Git working tree. Defaults to this repo.")
    parser.add_argument("--base", default="origin/cloud-handoff")
    args = parser.parse_args(argv)
    fixture = args.root is not None
    root = Path(args.root) if fixture else (Path(args.repo) if args.repo else ROOT)
    try:
        found = collect(root, args.base, fixture)
    except RuntimeError as exc:
        print("motion-reduced: fail")
        print(exc)
        return 2
    lines = ["motion-reduced: fail" if found else "motion-reduced: ok"]
    for path, line in found:
        lines.append(f"{path}:{line}: new animation does not read reduced motion")
    lines.append("not scanned: existing app screens")
    print("\n".join(lines))
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())

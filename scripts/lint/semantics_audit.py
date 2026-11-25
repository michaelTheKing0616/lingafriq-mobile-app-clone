#!/usr/bin/env python3
# Semantics( under lib/: 972. Elevation section 13.7 says 471.
# This lint does not scan existing app screens.
"""Fail a new interactive design widget that has no screen-reader label.

Scans Dart added under lib/design/ in the git diff against origin/cloud-handoff.
A public Widget class is interactive when it is a button, switch, or text
field, or when its name ends in Button, Tile, or Field. The file fails when
that class is new and the file has no Semantics wrapper and no semanticsLabel.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

CLASS_START = re.compile(r"(?m)^[ \t]*(?:abstract[ \t]+)?class[ \t]+([A-Za-z_]\w*)\b")
STATE_CLASS = re.compile(r"\bclass\s+\w+\s+extends\s+State\s*<\s*(\w+)\s*>")
CONTROL = re.compile(
    r"\b(?:"
    r"(?:Elevated|Text|Outlined|Icon|Filled|FloatingAction|Ling|Cupertino)Button"
    r"|CupertinoSwitch|Switch"
    r"|TextFormField|TextField|LingTextField"
    r")(?:\.\w+)?\s*\("
)
SUFFIXES = ("Button", "Tile", "Field", "Switch")


def count_semantics(lib: Path) -> int:
    if not lib.is_dir():
        return 0
    total = 0
    for path in lib.rglob("*.dart"):
        total += path.read_text(encoding="utf-8", errors="replace").count("Semantics(")
    return total


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


def _brace_end(masked: str, open_index: int) -> int:
    depth = 0
    index = open_index
    while index < len(masked):
        char = masked[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index + 1
        index += 1
    return len(masked)


def _line_of(src: str, index: int) -> int:
    return src.count("\n", 0, index) + 1


def _is_widget(header: str) -> bool:
    # StatelessWidget and StatefulWidget have no word boundary before Widget.
    return re.search(r"Widget\b", header) is not None


def _interactive(name: str, body: str) -> bool:
    if name.endswith(SUFFIXES):
        return True
    return CONTROL.search(body) is not None


def _state_bodies(masked: str) -> dict[str, str]:
    bodies: dict[str, list[str]] = {}
    for match in STATE_CLASS.finditer(masked):
        cursor = match.end()
        while cursor < len(masked) and masked[cursor] not in "{;":
            cursor += 1
        if cursor >= len(masked) or masked[cursor] != "{":
            continue
        bodies.setdefault(match.group(1), []).append(masked[cursor : _brace_end(masked, cursor)])
    return {name: "\n".join(parts) for name, parts in bodies.items()}


def findings_in(path: str, source: str, added_lines: set[int]) -> list[tuple[str, int, str]]:
    masked = mask_non_code(source)
    if "Semantics" in masked or "semanticsLabel" in masked:
        return []
    states = _state_bodies(masked)
    found: list[tuple[str, int, str]] = []
    for match in CLASS_START.finditer(masked):
        name = match.group(1)
        if name.startswith("_"):
            continue
        line = _line_of(source, match.start())
        if line not in added_lines:
            continue
        cursor = match.end()
        while cursor < len(masked) and masked[cursor] not in "{;":
            cursor += 1
        if cursor >= len(masked) or masked[cursor] != "{":
            continue
        header = masked[match.end() : cursor]
        if not _is_widget(header):
            continue
        body = masked[cursor : _brace_end(masked, cursor)] + states.get(name, "")
        if _interactive(name, body):
            found.append((path, line, name))
    return found


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
            if path.startswith("lib/design/") and path.endswith(".dart"):
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


def scan(root: Path, base: str) -> list[tuple[str, int, str]]:
    found: list[tuple[str, int, str]] = []
    for rel, added in sorted(added_design_dart(root, base).items()):
        if rel.startswith("lib/screens/"):
            continue
        path = root / rel
        if not path.is_file():
            continue
        source = path.read_text(encoding="utf-8", errors="replace")
        found.extend(findings_in(rel, source, added))
    return found


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--base", default="origin/cloud-handoff")
    args = parser.parse_args(argv)
    root = Path(args.root)
    count = count_semantics(root / "lib")
    try:
        found = scan(root, args.base)
    except RuntimeError as exc:
        print("semantics-audit: fail")
        print(exc)
        return 2
    lines = [
        "semantics-audit: fail" if found else "semantics-audit: ok",
    ]
    for path, line, name in found:
        lines.append(f"missing-label {path}:{line} {name}")
    lines.append(f"Semantics( under lib/: {count}")
    lines.append("not scanned: existing app screens")
    print("\n".join(lines))
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Fail when new design code uses an emoji as an Icon or as a button's only child.

Scope is added lines under lib/design/ compared with a git base
(default origin/cloud-handoff), plus untracked Dart files in that tree.
Pass --root to scan a fixture as if every line were new. A full scan of the
existing app is not the default. A failing run prints file and line, then
exits 1.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ICON_CALL = re.compile(r"(?<![A-Za-z0-9_])Icon\s*\(")
BUTTON_CALL = re.compile(
    r"(?<![A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*Button)"
    r"(?:\s*\.\s*[A-Za-z_][A-Za-z0-9_]*)?\s*\("
)
HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


def line_of(src: str, index: int) -> int:
    return src.count("\n", 0, index) + 1


def is_emoji_base(char: str) -> bool:
    code = ord(char)
    if 0x1F1E6 <= code <= 0x1F1FF:
        return True
    if 0x1F000 <= code <= 0x1FAFF:
        return True
    if 0x2600 <= code <= 0x27BF:
        return True
    if 0x2B00 <= code <= 0x2BFF:
        return True
    return False


def is_emoji_companion(char: str) -> bool:
    code = ord(char)
    return code in (0x200D, 0xFE0F) or 0x1F3FB <= code <= 0x1F3FF


def contains_emoji(text: str) -> bool:
    return any(is_emoji_base(char) for char in text)


def emoji_only(text: str) -> bool:
    saw = False
    for char in text:
        if char.isspace():
            continue
        if is_emoji_base(char):
            saw = True
            continue
        if is_emoji_companion(char):
            continue
        return False
    return saw


def unescape(body: str) -> str:
    out: list[str] = []
    index = 0
    hexdigits = "0123456789abcdefABCDEF"
    while index < len(body):
        if body[index] != "\\" or index + 1 >= len(body):
            out.append(body[index])
            index += 1
            continue
        nxt = body[index + 1]
        if nxt == "u" and index + 6 <= len(body) and all(c in hexdigits for c in body[index + 2 : index + 6]):
            out.append(chr(int(body[index + 2 : index + 6], 16)))
            index += 6
            continue
        if nxt == "u" and index + 3 < len(body) and body[index + 2] == "{":
            end = body.find("}", index + 3)
            if end != -1 and all(c in hexdigits for c in body[index + 3 : end]):
                out.append(chr(int(body[index + 3 : end], 16)))
                index = end + 1
                continue
        out.append(nxt)
        index += 2
    return "".join(out)


def decode_literal(literal: str) -> str:
    raw = literal.startswith("r'") or literal.startswith('r"') or literal.startswith("r'''") or literal.startswith('r"""')
    token = literal[1:] if raw else literal
    if token.startswith("'''") or token.startswith('"""'):
        body = token[3:-3]
    else:
        body = token[1:-1]
    if raw:
        return body
    return unescape(body)


def match_string(src: str, index: int) -> int | None:
    raw = False
    cursor = index
    if src.startswith("r", cursor) and cursor + 1 < len(src) and src[cursor + 1] in "'\"":
        raw = True
        cursor += 1
    if cursor >= len(src) or src[cursor] not in "'\"":
        return None
    quote = src[cursor]
    triple = src.startswith(quote * 3, cursor)
    if triple:
        cursor += 3
        closer = quote * 3
        while cursor < len(src) and not src.startswith(closer, cursor):
            if not raw and src[cursor] == "\\":
                cursor += 2
                continue
            cursor += 1
        if src.startswith(closer, cursor):
            cursor += 3
        return cursor
    cursor += 1
    while cursor < len(src):
        if not raw and src[cursor] == "\\":
            cursor += 2
            continue
        if src[cursor] == quote:
            return cursor + 1
        if src[cursor] == "\n":
            return None
        cursor += 1
    return None


def strip_comments(src: str) -> str:
    out: list[str] = []
    index = 0
    length = len(src)
    while index < length:
        if src.startswith("//", index):
            while index < length and src[index] != "\n":
                out.append(" ")
                index += 1
            continue
        if src.startswith("/*", index):
            out.append("  ")
            index += 2
            while index < length and not src.startswith("*/", index):
                out.append("\n" if src[index] == "\n" else " ")
                index += 1
            if index < length:
                out.append("  ")
                index += 2
            continue
        end = match_string(src, index)
        if end is not None:
            out.append(src[index:end])
            index = end
            continue
        out.append(src[index])
        index += 1
    return "".join(out)


def string_spans(src: str) -> list[tuple[int, int]]:
    spans: list[tuple[int, int]] = []
    index = 0
    length = len(src)
    while index < length:
        end = match_string(src, index)
        if end is not None:
            spans.append((index, end))
            index = end
            continue
        index += 1
    return spans


def inside(index: int, spans: list[tuple[int, int]]) -> bool:
    for start, end in spans:
        if start <= index < end:
            return True
        if start > index:
            return False
    return False


def call_end(src: str, open_paren: int) -> int:
    depth = 0
    index = open_paren
    while index < len(src):
        end = match_string(src, index)
        if end is not None:
            index = end
            continue
        char = src[index]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return index + 1
        index += 1
    return len(src)


def string_literals(src: str, start: int, end: int) -> list[tuple[int, str]]:
    found: list[tuple[int, str]] = []
    index = start
    while index < end:
        stop = match_string(src, index)
        if stop is not None and stop <= end:
            found.append((index, src[index:stop]))
            index = stop
            continue
        index += 1
    return found


def value_end(src: str, start: int, call_close: int) -> int:
    index = start
    depth = 0
    while index < call_close - 1:
        stop = match_string(src, index)
        if stop is not None:
            index = stop
            continue
        char = src[index]
        if char in "([{":
            depth += 1
        elif char in ")]}":
            if depth == 0:
                return index
            depth -= 1
        elif char == "," and depth == 0:
            return index
        index += 1
    return call_close - 1


def named_values(src: str, open_paren: int, end: int) -> list[tuple[str, int, int]]:
    values: list[tuple[str, int, int]] = []
    index = open_paren + 1
    while index < end - 1:
        stop = match_string(src, index)
        if stop is not None:
            index = stop
            continue
        char = src[index]
        if char.isalpha() or char == "_":
            start_name = index
            index += 1
            while index < end and (src[index].isalnum() or src[index] == "_"):
                index += 1
            name = src[start_name:index]
            look = index
            while look < end and src[look] in " \t\r\n":
                look += 1
            if look < end and src[look] == ":":
                value_start = look + 1
                value_stop = value_end(src, value_start, end)
                values.append((name, value_start, value_stop))
                index = value_stop
                continue
            continue
        index += 1
    return values


def boundary(src: str, index: int) -> bool:
    if index >= len(src):
        return True
    return not (src[index].isalnum() or src[index] == "_")


def skip_const(src: str, index: int, end: int) -> int:
    while index < end and src[index] in " \t\r\n":
        index += 1
    if src.startswith("const", index) and boundary(src, index + 5):
        index += 5
        while index < end and src[index] in " \t\r\n":
            index += 1
    return index


def button_child_line(src: str, value_start: int, value_end_index: int) -> int | None:
    index = skip_const(src, value_start, value_end_index)
    if index >= value_end_index:
        return None
    stop = match_string(src, index)
    if stop is not None and stop <= value_end_index:
        if src[stop:value_end_index].strip() == "" and emoji_only(decode_literal(src[index:stop])):
            return line_of(src, index)
        return None
    if not src.startswith("Text", index) or not boundary(src, index + 4):
        return None
    after = index + 4
    while after < value_end_index and src[after] in " \t\r\n":
        after += 1
    if after >= value_end_index or src[after] != "(":
        return None
    text_end = call_end(src, after)
    literals = string_literals(src, after, text_end)
    if not literals:
        return None
    first_at, first_lit = literals[0]
    if emoji_only(decode_literal(first_lit)):
        return line_of(src, first_at)
    return None


def icon_lines(src: str, open_paren: int, end: int) -> list[int]:
    lines: list[int] = []
    for at, literal in string_literals(src, open_paren, end):
        if contains_emoji(decode_literal(literal)):
            lines.append(line_of(src, at))
    return lines


def button_lines(src: str, open_paren: int, end: int) -> list[int]:
    lines: list[int] = []
    for name, start, stop in named_values(src, open_paren, end):
        if name not in ("child", "icon"):
            continue
        found = button_child_line(src, start, stop)
        if found is not None:
            lines.append(found)
    return lines


def offending_lines(src: str) -> list[int]:
    cleaned = strip_comments(src)
    spans = string_spans(cleaned)
    lines: list[int] = []
    for match in ICON_CALL.finditer(cleaned):
        if inside(match.start(), spans):
            continue
        open_paren = match.end() - 1
        lines.extend(icon_lines(cleaned, open_paren, call_end(cleaned, open_paren)))
    for match in BUTTON_CALL.finditer(cleaned):
        if inside(match.start(), spans):
            continue
        open_paren = match.end() - 1
        lines.extend(button_lines(cleaned, open_paren, call_end(cleaned, open_paren)))
    return sorted(set(lines))


def parse_diff(diff: str) -> dict[str, set[int]]:
    added: dict[str, set[int]] = {}
    path: str | None = None
    new_line = 0
    for line in diff.splitlines():
        if line.startswith("+++ b/"):
            path = line[6:]
            if path.startswith("lib/design/") and path.endswith(".dart"):
                added.setdefault(path, set())
            else:
                path = None
            continue
        if line.startswith("+++ "):
            path = None
            continue
        if path is None:
            continue
        hunk = HUNK.match(line)
        if hunk:
            new_line = int(hunk.group(1))
            continue
        if line.startswith("+"):
            added[path].add(new_line)
            new_line += 1
            continue
        if line.startswith("-") or line.startswith("\\"):
            continue
        new_line += 1
    return added


def git_text(repo: Path, args: list[str]) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=repo,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        message = (result.stderr or result.stdout).strip() or "git failed"
        raise RuntimeError(message)
    return result.stdout


def changed_files(repo: Path, base: str) -> dict[str, set[int] | None]:
    added: dict[str, set[int] | None] = {
        path: lines for path, lines in parse_diff(
            git_text(repo, ["diff", "-U0", "--diff-filter=AM", base, "--", "lib/design"])
        ).items()
    }
    untracked = git_text(
        repo,
        ["ls-files", "--others", "--exclude-standard", "--", "lib/design"],
    )
    for rel in untracked.splitlines():
        if rel.endswith(".dart"):
            added[rel] = None
    return added


def scan_file(text: str, added: set[int] | None) -> list[int]:
    found = offending_lines(text)
    if added is None:
        return found
    return [line for line in found if line in added]


def findings_for(root: Path, files: dict[str, set[int] | None]) -> list[tuple[str, int]]:
    found: list[tuple[str, int]] = []
    for rel, added in files.items():
        path = root / rel
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for line in scan_file(text, added):
            found.append((rel, line))
    return sorted(set(found))


def fixture_files(root: Path) -> dict[str, set[int] | None]:
    base = root / "lib" / "design"
    if not base.exists():
        return {}
    files: dict[str, set[int] | None] = {}
    for path in sorted(base.rglob("*.dart")):
        if path.is_file():
            files[path.relative_to(root).as_posix()] = None
    return files


def collect(root: Path, base: str, fixture: bool) -> list[tuple[str, int]]:
    if fixture:
        return findings_for(root, fixture_files(root))
    return findings_for(root, changed_files(root, base))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", help="Scan this tree as all-new design code. Skips git.")
    parser.add_argument("--repo", help="Git working tree. Defaults to the repo that holds this script.")
    parser.add_argument("--base", default="origin/cloud-handoff")
    args = parser.parse_args(argv)
    if args.root is not None:
        root = Path(args.root)
        fixture = True
    else:
        root = Path(args.repo) if args.repo else ROOT
        fixture = False
    try:
        found = collect(root, args.base, fixture)
    except RuntimeError as exc:
        print(f"no-emoji-icons: {exc}", file=sys.stderr)
        return 1
    if not found:
        print("no-emoji-icons: ok")
        return 0
    for path, line in found:
        print(f"{path}:{line}: emoji used as an icon")
    return 1


if __name__ == "__main__":
    sys.exit(main())

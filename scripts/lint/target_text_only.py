#!/usr/bin/env python3
"""Fail when new design code renders a target-language string with plain Text.

Scope is lib/design/ only. Screens under the rest of lib/ are not failed.
A target-language string contains a non-ASCII letter or a combining mark
(the glyph proof, Yoruba tones, Ge'ez, N'Ko, Tifinagh, Adlam). ASCII UI copy
is left alone. TargetText is the allowed renderer.

A failing run prints each file and line, then exits 1.
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from pathlib import Path

ASSIGN = re.compile(
    r"""\b(?:static\s+)?(?:const|final|var)\s+(?:String\s+)?([A-Za-z_]\w*)\s*=\s*("""
    r"""r?(?:'''[\s\S]*?'''|\"\"\"[\s\S]*?\"\"\"|'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\")"""
    r""")"""
)


def line_of(src: str, index: int) -> int:
    return src.count("\n", 0, index) + 1


def is_target_language(text: str) -> bool:
    for char in text:
        if ord(char) < 128:
            continue
        category = unicodedata.category(char)
        if category.startswith("L") or category.startswith("M"):
            return True
    return False


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


def _ident(char: str) -> bool:
    return char.isalnum() or char == "_"


def text_call_paren(src: str, index: int) -> int | None:
    if not src.startswith("Text", index):
        return None
    if index > 0 and _ident(src[index - 1]):
        return None
    cursor = index + 4
    while cursor < len(src) and src[cursor] in " \t\r\n":
        cursor += 1
    if cursor < len(src) and src[cursor] == "(":
        return cursor
    return None


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
    found = []
    index = start
    while index < end:
        stop = match_string(src, index)
        if stop is not None and stop <= end:
            found.append((index, src[index:stop]))
            index = stop
            continue
        index += 1
    return found


def first_argument(src: str, open_paren: int, end: int) -> str:
    depth = 0
    index = open_paren + 1
    start = index
    while index < end:
        stop = match_string(src, index)
        if stop is not None:
            index = stop
            continue
        char = src[index]
        if char == "(":
            depth += 1
        elif char == ")":
            if depth == 0:
                return src[start:index]
            depth -= 1
        elif char == "," and depth == 0:
            return src[start:index]
        index += 1
    return src[start:end]


def assigned_names(src: str) -> set[str]:
    names = set()
    for match in ASSIGN.finditer(src):
        if is_target_language(decode_literal(match.group(2))):
            names.add(match.group(1))
    return names


def offending_lines(src: str, names: set[str]) -> list[int]:
    lines: list[int] = []
    index = 0
    length = len(src)
    while index < length:
        if src.startswith("//", index):
            newline = src.find("\n", index)
            index = length if newline < 0 else newline + 1
            continue
        if src.startswith("/*", index):
            end = src.find("*/", index + 2)
            index = length if end < 0 else end + 2
            continue
        end = match_string(src, index)
        if end is not None:
            index = end
            continue
        paren = text_call_paren(src, index)
        if paren is None:
            index += 1
            continue
        end = call_end(src, paren)
        for literal_at, literal in string_literals(src, index, end):
            if is_target_language(decode_literal(literal)):
                lines.append(line_of(src, literal_at))
        argument = first_argument(src, paren, end).strip()
        if re.fullmatch(r"[A-Za-z_]\w*", argument) and argument in names:
            lines.append(line_of(src, index))
        if re.search(r"\bglyphProof\b", argument):
            lines.append(line_of(src, index))
        index = end
    return lines


def lint(root: Path) -> list[tuple[str, int]]:
    base = root / "lib" / "design"
    if not base.exists():
        return []
    findings: list[tuple[str, int]] = []
    for path in sorted(base.rglob("*.dart")):
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        rel = path.relative_to(root).as_posix()
        for line in offending_lines(text, assigned_names(text)):
            findings.append((rel, line))
    unique = sorted(set(findings))
    return unique


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    args = parser.parse_args(argv)
    findings = lint(Path(args.root))
    if not findings:
        print("target-text-only: ok")
        return 0
    for path, line in findings:
        print(f"{path}:{line}")
    return 1


if __name__ == "__main__":
    sys.exit(main())

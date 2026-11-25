#!/usr/bin/env python3
"""Fail a new catch that swallows an error.

A catch fails when its body is empty, only a comment, or only a print
that then continues. A catch that rethrows, throws, or returns an error
state does not fail. The scan reads added lines in a git diff, so a catch
already on the base does not fail. A fixture file is scanned as if it
were new, and it is not the whole app.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

SUMMARY_LIMIT = 15
KINDS = ("empty-catch", "comment-only", "print-continue")
PRINT_NAME = re.compile(
    r"(?:print|debugPrint|log|developer\.log|stdout\.writeln|stderr\.writeln|stdout\.write|stderr\.write)\s*\("
)
CONTINUE_NAME = re.compile(r"(?:continue|break)(?:\s+\w+)?\s*$")


def _is_ident(ch: str) -> bool:
    return ch.isalnum() or ch == "_"


def _find_catches(source: str) -> list[tuple[int, str]]:
    """Return (line of the catch keyword, raw body) for each catch."""
    bodies: list[tuple[int, str]] = []
    i = 0
    n = len(source)
    line = 1
    while i < n:
        ch = source[i]
        if ch == "\n":
            line += 1
            i += 1
            continue
        if ch == "/" and i + 1 < n and source[i + 1] == "/":
            i += 2
            while i < n and source[i] != "\n":
                i += 1
            continue
        if ch == "/" and i + 1 < n and source[i + 1] == "*":
            i += 2
            while i + 1 < n and not (source[i] == "*" and source[i + 1] == "/"):
                if source[i] == "\n":
                    line += 1
                i += 1
            i = min(n, i + 2)
            continue
        if ch in ("'", '"'):
            i, line = _skip_string(source, i, line)
            continue
        if source.startswith("catch", i) and _catch_word(source, i):
            catch_line = line
            i += 5
            opened = _skip_to_brace(source, i, line)
            if opened is None:
                continue
            i, line, body = opened
            bodies.append((catch_line, body))
            continue
        i += 1
    return bodies


def _catch_word(source: str, index: int) -> bool:
    before = source[index - 1] if index else ""
    after = source[index + 5] if index + 5 < len(source) else ""
    if before and _is_ident(before):
        return False
    if after and _is_ident(after):
        return False
    return True


def _raw_prefix(source: str, index: int) -> bool:
    if index == 0 or source[index - 1] not in ("r", "R"):
        return False
    before = source[index - 2] if index >= 2 else ""
    return not before or not _is_ident(before)


def _skip_string(source: str, index: int, line: int) -> tuple[int, int]:
    quote = source[index]
    raw = _raw_prefix(source, index)
    triple = source.startswith(quote * 3, index)
    token = quote * 3 if triple else quote
    i = index + len(token)
    n = len(source)
    while i < n:
        ch = source[i]
        if ch == "\n":
            line += 1
        if not raw and ch == "\\":
            if i + 1 < n and source[i + 1] == "\n":
                line += 1
            i += 2
            continue
        if source.startswith(token, i):
            return i + len(token), line
        i += 1
    return n, line


def _skip_to_brace(source: str, index: int, line: int) -> tuple[int, int, str] | None:
    i = index
    n = len(source)
    while i < n:
        ch = source[i]
        if ch == "\n":
            line += 1
            i += 1
            continue
        if ch == "/" and i + 1 < n and source[i + 1] == "/":
            i += 2
            while i < n and source[i] != "\n":
                i += 1
            continue
        if ch == "/" and i + 1 < n and source[i + 1] == "*":
            i += 2
            while i + 1 < n and not (source[i] == "*" and source[i + 1] == "/"):
                if source[i] == "\n":
                    line += 1
                i += 1
            i = min(n, i + 2)
            continue
        if ch in ("'", '"'):
            i, line = _skip_string(source, i, line)
            continue
        if ch == "{":
            return _read_body(source, i + 1, line)
        i += 1
    return None


def _read_body(source: str, index: int, line: int) -> tuple[int, int, str]:
    i = index
    n = len(source)
    depth = 1
    chars: list[str] = []
    while i < n and depth:
        ch = source[i]
        if ch == "\n":
            line += 1
            chars.append(ch)
            i += 1
            continue
        if ch == "/" and i + 1 < n and source[i + 1] == "/":
            while i < n and source[i] != "\n":
                chars.append(source[i])
                i += 1
            continue
        if ch == "/" and i + 1 < n and source[i + 1] == "*":
            chars.append(source[i])
            chars.append(source[i + 1])
            i += 2
            while i + 1 < n and not (source[i] == "*" and source[i + 1] == "/"):
                if source[i] == "\n":
                    line += 1
                chars.append(source[i])
                i += 1
            if i + 1 < n:
                chars.append(source[i])
                chars.append(source[i + 1])
                i += 2
            continue
        if ch in ("'", '"'):
            end, line = _skip_string(source, i, line)
            chars.append(source[i:end])
            i = end
            continue
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i + 1, line, "".join(chars)
        chars.append(ch)
        i += 1
    return n, line, "".join(chars)


def _strip_comments(source: str) -> str:
    out: list[str] = []
    i = 0
    n = len(source)
    while i < n:
        ch = source[i]
        if ch == "/" and i + 1 < n and source[i + 1] == "/":
            i += 2
            while i < n and source[i] != "\n":
                i += 1
            continue
        if ch == "/" and i + 1 < n and source[i + 1] == "*":
            i += 2
            while i + 1 < n and not (source[i] == "*" and source[i + 1] == "/"):
                if source[i] == "\n":
                    out.append("\n")
                i += 1
            i = min(n, i + 2)
            continue
        if ch in ("'", '"'):
            end, _ = _skip_string(source, i, 1)
            out.append('""')
            i = end
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def _statements(code: str) -> list[str]:
    parts: list[str] = []
    buf: list[str] = []
    depth = 0
    for ch in code:
        if ch in "({[":
            depth += 1
            buf.append(ch)
        elif ch in ")}]":
            depth = max(0, depth - 1)
            buf.append(ch)
        elif ch == ";" and depth == 0:
            text = "".join(buf).strip()
            if text:
                parts.append(text)
            buf = []
        else:
            buf.append(ch)
    tail = "".join(buf).strip()
    if tail:
        parts.append(tail)
    return parts


def _is_print(statement: str) -> bool:
    text = statement.strip()
    match = PRINT_NAME.match(text)
    if not match:
        return False
    open_at = text.find("(", match.end() - 1)
    depth = 0
    for index in range(open_at, len(text)):
        ch = text[index]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return text[index + 1 :].strip() == ""
    return False


def _is_continue(statement: str) -> bool:
    return CONTINUE_NAME.match(statement.strip()) is not None


def classify(body: str) -> str | None:
    """Name the swallow, or return None when the catch keeps the error."""
    raw = body.strip()
    code = _strip_comments(body)
    if not re.search(r"[A-Za-z0-9_]", code):
        if "//" in raw or "/*" in raw:
            return "comment-only"
        return "empty-catch"
    statements = _statements(code)
    if statements and all(_is_print(item) or _is_continue(item) for item in statements):
        return "print-continue"
    return None


def scan_source(path: str, source: str) -> list[tuple[str, str, int]]:
    findings = []
    for line, body in _find_catches(source):
        kind = classify(body)
        if kind is not None:
            findings.append((kind, path, line))
    return findings


def added_rows(diff: str) -> list[tuple[str, int, str]]:
    """Added lines only. Context and deletions stay out."""
    path = ""
    new_line = 0
    rows: list[tuple[str, int, str]] = []
    for raw in diff.splitlines():
        if raw.startswith("diff --git "):
            path = ""
            continue
        if raw.startswith("+++ "):
            name = raw[4:].strip()
            if name == "/dev/null":
                path = ""
            elif name.startswith("b/"):
                path = name[2:]
            else:
                path = name
            continue
        if raw.startswith("@@"):
            match = re.search(r"\+(\d+)", raw)
            new_line = int(match.group(1)) if match else 1
            continue
        if not path or raw.startswith("--- ") or raw.startswith("index ") or raw.startswith("\\"):
            continue
        if raw.startswith("+"):
            rows.append((path, new_line, raw[1:]))
            new_line += 1
        elif raw.startswith("-"):
            continue
        else:
            new_line += 1
    return rows


def scan_diff(diff: str) -> list[tuple[str, str, int]]:
    grouped: dict[str, list[tuple[int, str]]] = {}
    for path, line, text in added_rows(diff):
        if path.endswith(".dart"):
            grouped.setdefault(path, []).append((line, text))
    findings = []
    for path, lines in grouped.items():
        source = "\n".join(text for _, text in lines)
        line_map = [line for line, _ in lines]
        for index, body in _find_catches(source):
            kind = classify(body)
            if kind is None:
                continue
            file_line = line_map[index - 1] if 0 < index <= len(line_map) else index
            findings.append((kind, path, file_line))
    return findings


def git_diff(root: Path, base: str) -> str:
    result = subprocess.run(
        ["git", "diff", "-U0", base],
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "git diff failed")
    return result.stdout


def summary(findings: list[tuple[str, str, int]]) -> str:
    if not findings:
        return "no-swallowed-errors: 0 new\n"
    rows = [f"{kind} {path}:{line}" for kind, path, line in findings]
    header = "no-swallowed-errors: fail"
    budget = SUMMARY_LIMIT - 1
    if len(rows) <= budget:
        lines = [header, *rows]
    else:
        kept = rows[: budget - 1]
        hidden = len(rows) - len(kept)
        lines = [header, *kept, f"+{hidden} more"]
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--base", default="origin/cloud-handoff")
    parser.add_argument("--fixture-file", help="Scan this source as new code")
    parser.add_argument("--diff-file", help="Scan added lines in this unified diff")
    args = parser.parse_args(argv)
    if args.fixture_file and args.diff_file:
        print("no-swallowed-errors: pass one of --fixture-file or --diff-file", file=sys.stderr)
        return 2
    if args.fixture_file:
        path = Path(args.fixture_file)
        findings = scan_source(path.as_posix(), path.read_text(encoding="utf-8"))
    elif args.diff_file:
        findings = scan_diff(Path(args.diff_file).read_text(encoding="utf-8"))
    else:
        findings = scan_diff(git_diff(Path(args.root), args.base))
    sys.stdout.write(summary(findings))
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Build a pseudo locale that makes English strings 40 percent longer.

Vowels take accents, the result is wrapped in brackets, and a tilde pad
brings the inner text to 40 percent over the source length. Placeholders
and ICU plural or select branches stay intact. Shell and onboarding keys
are the ones CI lays out.

--self-test checks the expansion rules.
--emit prints JSON for those keys: source, pseudo, and the string to lay out.
--fail-key prints that key and exits 1, which is how an overflow report fails CI.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path

ACCENTS = {
    "a": "à",
    "e": "é",
    "i": "î",
    "o": "ö",
    "u": "ü",
    "A": "À",
    "E": "É",
    "I": "Î",
    "O": "Ö",
    "U": "Ü",
    "y": "ÿ",
    "Y": "Ÿ",
}
PAD = "~"
BRACKETS = ("[", "]")
SCOPE_PREFIXES = ("shell", "onboarding")
PLACEHOLDER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
ICU_MARK = re.compile(r",\s*(?:plural|select|selectordinal)\s*,")


def extra_count(length: int) -> int:
    """Characters added so the inner text is 40 percent longer."""
    if length <= 0:
        return 0
    return math.ceil(length * 0.4)


def _accent(text: str) -> str:
    return "".join(ACCENTS.get(char, char) for char in text)


def _split_protected(message: str) -> list[tuple[str, bool]]:
    """Split a message into literal and balanced-brace segments."""
    parts: list[tuple[str, bool]] = []
    index = 0
    buffer: list[str] = []
    while index < len(message):
        if message[index] != "{":
            buffer.append(message[index])
            index += 1
            continue
        if buffer:
            parts.append(("".join(buffer), False))
            buffer = []
        depth = 0
        start = index
        while index < len(message):
            if message[index] == "{":
                depth += 1
            elif message[index] == "}":
                depth -= 1
                if depth == 0:
                    index += 1
                    break
            index += 1
        parts.append((message[start:index], True))
    if buffer:
        parts.append(("".join(buffer), False))
    return parts


def pseudo(message: str) -> str:
    """Return [accented message plus a 40 percent pad]."""
    pieces: list[str] = []
    for text, protected in _split_protected(message):
        pieces.append(text if protected else _accent(text))
    inner = "".join(pieces) + (PAD * extra_count(len(message)))
    return f"{BRACKETS[0]}{inner}{BRACKETS[1]}"


def _innermost_literals(message: str) -> list[str]:
    literals: list[str] = []
    for chunk in re.findall(r"\{([^{}]*)\}", message):
        if PLACEHOLDER.fullmatch(chunk):
            continue
        stripped = chunk.strip()
        if stripped:
            literals.append(stripped)
    return literals


def layout_text(message: str) -> str:
    """The string a screen would paint, with placeholders filled by a short name."""
    if ICU_MARK.search(message):
        branches = _innermost_literals(message)
        chosen = max(branches, key=len) if branches else message
        return pseudo(chosen).replace("{", "").replace("}", "")
    filled = re.sub(r"\{[A-Za-z_][A-Za-z0-9_]*\}", "Ada", message)
    return pseudo(filled)


def _load_arb(path: Path) -> dict[str, str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    messages: dict[str, str] = {}
    for key, value in data.items():
        if str(key).startswith("@"):
            continue
        if not isinstance(value, str):
            continue
        if key.startswith(SCOPE_PREFIXES):
            messages[key] = value
    return messages


def emit(arb: Path) -> dict[str, dict[str, str]]:
    payload: dict[str, dict[str, str]] = {}
    for key, source in _load_arb(arb).items():
        payload[key] = {
            "source": source,
            "pseudo": pseudo(source),
            "layout": layout_text(source),
        }
    return payload


def _assert_expansion(source: str) -> None:
    result = pseudo(source)
    if not (result.startswith(BRACKETS[0]) and result.endswith(BRACKETS[1])):
        raise SystemExit(f"pseudo locale missing brackets: {result}")
    inner = result[1:-1]
    expected = len(source) + extra_count(len(source))
    if len(inner) != expected:
        raise SystemExit(
            f"{source!r} inner length {len(inner)} != {expected} ({result})"
        )
    accented = _accent(source)
    for char in accented:
        if char not in inner and char not in "{}":
            # Placeholders are copied whole, so compare outside them.
            continue
    for original, marked in ACCENTS.items():
        if original in source and marked not in result and "{" not in source:
            raise SystemExit(f"{source!r} did not accent {original}: {result}")


def self_test() -> None:
    _assert_expansion("Home")
    home = pseudo("Home")
    if "ö" not in home or "é" not in home:
        raise SystemExit(f"Home did not take accents: {home}")
    held = pseudo("Hello {name}")
    if "{name}" not in held:
        raise SystemExit(f"placeholder was rewritten: {held}")
    if "é" not in held or "ö" not in held:
        raise SystemExit(f"Hello did not take accents: {held}")
    _assert_expansion("Hello {name}")
    _assert_expansion("Continue")
    sample = "{count, plural, =1{1 day} other{{count} days}}"
    shown = layout_text(sample)
    if "plural" in shown or shown.startswith("{"):
        raise SystemExit(f"layout kept ICU syntax: {shown}")
    if not shown.startswith("["):
        raise SystemExit(f"layout lost brackets: {shown}")
    print("pseudo locale self-test passed")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--arb",
        type=Path,
        default=Path("lib/l10n/app_en.arb"),
        help="English ARB to read",
    )
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--emit", action="store_true")
    parser.add_argument(
        "--fail-key",
        help="Print this key and exit 1. CI uses this when a golden overflows.",
    )
    args = parser.parse_args(argv)
    if args.fail_key:
        print(args.fail_key)
        return 1
    if args.self_test:
        self_test()
        return 0
    if args.emit:
        json.dump(emit(args.arb), sys.stdout, ensure_ascii=False, indent=2)
        sys.stdout.write("\n")
        return 0
    parser.error("pass --self-test, --emit, or --fail-key")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())

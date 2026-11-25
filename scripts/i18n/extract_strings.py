#!/usr/bin/env python3
"""Scan lib/ for hard-coded user-visible string literals.

Prints the remaining count. A literal that is not already in
scripts/i18n/string_baseline.json fails the run (the ratchet). Shell and
onboarding stay at zero after extraction. Placeholders and plurals in
lib/l10n/app_en.arb must be valid ICU; a malformed message fails the run.

--extract writes new keys into lib/l10n/app_en.arb with a feature prefix
and replaces the literals it extracted. It does not translate other locales.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

CLEAN_PREFIXES = (
    "lib/screens/onboarding/",
    "lib/avatars/onboarding/",
    "lib/screens/tabs_view/",
    "lib/screens/home_screen.dart",
)
SKIP_PARTS = {"generated"}
SKIP_SUFFIXES = (".g.dart", ".freezed.dart", ".gr.dart")
TEXT_CALLEES = {"Text", "AutoSizeText", "SelectableText", "TextSpan"}
COPY_CALLEES = {"_bidi", "_tr"}
STRONG_PARAMS = {
    "hintText",
    "labelText",
    "helperText",
    "errorText",
    "tooltip",
    "semanticLabel",
    "semanticsLabel",
    "buttonText",
    "counterText",
    "prefixText",
    "suffixText",
}
WEAK_PARAMS = {
    "label",
    "title",
    "subtitle",
    "hint",
    "message",
    "text",
    "placeholder",
    "caption",
    "header",
    "footer",
    "description",
    "content",
    "body",
    "question",
    "announcement",
    "banner",
    "dialogTitle",
    "errorMessage",
    "emptyMessage",
    "loadingText",
    "primaryLabel",
    "secondaryLabel",
    "actionLabel",
    "accessibilityLabel",
}
UI_VALUE_KEYS = {
    "name",
    "label",
    "title",
    "subtitle",
    "desc",
    "description",
    "script",
    "region",
    "hint",
    "message",
    "body",
    "question",
    "caption",
    "text",
    "hear",
    "tap",
    "button",
    "primary",
    "secondary",
    "header",
    "footer",
    "placeholder",
    "dialogue",
    "dialog",
    "semanticlabel",
    "tooltip",
}
EXCLUDED_CALLEES = {
    "debugPrint",
    "print",
    "log",
    "fine",
    "info",
    "warning",
    "severe",
    "shout",
    "config",
    "RegExp",
    "Key",
    "ValueKey",
    "PageStorageKey",
    "ObjectKey",
    "AssetImage",
    "NetworkImage",
    "ExactAssetImage",
    "File",
    "Directory",
    "Uri",
    "Locale",
    "Color",
    "Duration",
    "Exception",
    "FormatException",
    "ArgumentError",
    "StateError",
    "AssertionError",
    "UnsupportedError",
    "UnimplementedError",
    "RangeError",
    "FlutterError",
    "Error",
    "DateFormat",
    "RegExp",
}
LOG_METHODS = {
    "error",
    "info",
    "warning",
    "warn",
    "debug",
    "fine",
    "finer",
    "finest",
    "log",
    "d",
    "i",
    "w",
    "e",
    "v",
    "wtf",
    "severe",
    "fatal",
    "trace",
    "verbose",
    "shout",
    "config",
}
PLURAL_CATEGORIES = {"zero", "one", "two", "few", "many", "other"}
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


@dataclass
class Interp:
    expr: str
    name: str


@dataclass
class Tok:
    kind: str
    text: str
    start: int
    end: int
    line: int
    value: str = ""
    interps: list[Interp] = field(default_factory=list)


@dataclass
class Finding:
    path: str
    line: int
    start: int
    end: int
    text: str
    reason: str
    interps: list[Interp] = field(default_factory=list)


def _line_of(src: str, index: int) -> int:
    return src.count("\n", 0, index) + 1


def _decode_escape(body: str, index: int) -> tuple[str, int]:
    if index >= len(body):
        return "\\", index
    char = body[index]
    simple = {"n": "\n", "r": "\r", "t": "\t", "b": "\b", "f": "\f", "\\": "\\", "'": "'", '"': '"', "$": "$", "/": "/"}
    if char in simple:
        return simple[char], index + 1
    if char == "u" and index + 1 < len(body) and body[index + 1] == "{":
        end = body.find("}", index + 2)
        if end == -1:
            return char, index + 1
        hex_digits = body[index + 2 : end]
        try:
            return chr(int(hex_digits, 16)), end + 1
        except ValueError:
            return char, index + 1
    if char == "u" and index + 5 <= len(body):
        hex_digits = body[index + 1 : index + 5]
        try:
            return chr(int(hex_digits, 16)), index + 5
        except ValueError:
            return char, index + 1
    if char == "x" and index + 3 <= len(body):
        hex_digits = body[index + 1 : index + 3]
        try:
            return chr(int(hex_digits, 16)), index + 3
        except ValueError:
            return char, index + 1
    return char, index + 1


def _parse_interpolation(body: str, index: int) -> tuple[str, int]:
    if index < len(body) and body[index] == "{":
        depth = 1
        cursor = index + 1
        while cursor < len(body) and depth:
            if body[cursor] in "'\"":
                quote = body[cursor]
                cursor += 1
                while cursor < len(body) and body[cursor] != quote:
                    if body[cursor] == "\\":
                        cursor += 2
                        continue
                    cursor += 1
                cursor += 1
                continue
            if body[cursor] == "{":
                depth += 1
            elif body[cursor] == "}":
                depth -= 1
            cursor += 1
        return body[index + 1 : cursor - 1], cursor
    match = IDENT.match(body, index)
    if not match:
        return "", index
    return match.group(0), match.end()


def _scan_string_end(src: str, index: int, closer: str, raw: bool) -> int:
    """Index of the closing quote. Interpolations may contain the quote."""
    cursor = index
    while cursor < len(src):
        if src.startswith(closer, cursor):
            return cursor
        if not raw and src[cursor] == "\\":
            cursor += 2
            continue
        if not raw and src[cursor] == "$" and cursor + 1 < len(src):
            if src[cursor + 1] == "{":
                _, cursor = _parse_interpolation(src, cursor + 1)
                continue
            if src[cursor + 1].isalpha() or src[cursor + 1] == "_":
                cursor += 2
                while cursor < len(src) and (src[cursor].isalnum() or src[cursor] == "_"):
                    cursor += 1
                continue
        if not raw and len(closer) == 1 and src[cursor] == "\n":
            return cursor
        cursor += 1
    return len(src)


def _parse_quoted(src: str, index: int) -> Tok | None:
    raw = False
    if src[index] == "r" and index + 1 < len(src) and src[index + 1] in "'\"":
        raw = True
        index += 1
    if index >= len(src) or src[index] not in "'\"":
        return None
    quote = src[index]
    triple = src.startswith(quote * 3, index)
    start = index - (1 if raw else 0)
    line = _line_of(src, start)
    cursor = index + (3 if triple else 1)
    closer = quote * (3 if triple else 1)
    body_start = cursor
    if triple:
        end = _scan_string_end(src, cursor, closer, raw)
        body = src[body_start:end]
        token_end = end + (len(closer) if src.startswith(closer, end) else 0)
    else:
        end = _scan_string_end(src, cursor, quote, raw)
        body = src[body_start:end]
        token_end = end + (1 if end < len(src) and src[end] == quote else 0)
    value_parts: list[str] = []
    interps: list[Interp] = []
    used_names: set[str] = set()
    pos = 0
    while pos < len(body):
        if not raw and body[pos] == "\\":
            decoded, pos = _decode_escape(body, pos + 1)
            value_parts.append(decoded)
            continue
        if not raw and body[pos] == "$":
            expr, pos = _parse_interpolation(body, pos + 1)
            if not expr:
                value_parts.append("$")
                continue
            name = _placeholder_name(expr, used_names)
            interps.append(Interp(expr=expr.strip(), name=name))
            value_parts.append("{" + name + "}")
            continue
        value_parts.append(body[pos])
        pos += 1
    return Tok(
        kind="string",
        text=src[start:token_end],
        start=start,
        end=token_end,
        line=line,
        value="".join(value_parts),
        interps=interps,
    )


def _placeholder_name(expr: str, used: set[str]) -> str:
    ident = expr.strip()
    if re.fullmatch(r"_?[A-Za-z][A-Za-z0-9_]*", ident):
        base = ident.lstrip("_") or "value"
    else:
        base = "value"
    if not base[0].isalpha():
        base = "value"
    name = base
    index = 2
    while name in used:
        name = f"{base}{index}"
        index += 1
    used.add(name)
    return name


def lex(src: str) -> list[Tok]:
    tokens: list[Tok] = []
    index = 0
    length = len(src)
    while index < length:
        if src.startswith("//", index):
            index = src.find("\n", index)
            if index == -1:
                break
            continue
        if src.startswith("/*", index):
            end = src.find("*/", index + 2)
            index = length if end == -1 else end + 2
            continue
        if src[index] in " \t\r\n":
            index += 1
            continue
        if src[index] == "r" and index + 1 < length and src[index + 1] in "'\"":
            token = _parse_quoted(src, index)
            if token:
                tokens.append(token)
                index = token.end
                continue
        if src[index] in "'\"":
            token = _parse_quoted(src, index)
            if token:
                tokens.append(token)
                index = token.end
                continue
        match = IDENT.match(src, index)
        if match:
            tokens.append(
                Tok("ident", match.group(0), match.start(), match.end(), _line_of(src, match.start()))
            )
            index = match.end()
            continue
        tokens.append(Tok("punct", src[index], index, index + 1, _line_of(src, index)))
        index += 1
    return tokens


def _merge_adjacent(src: str, tokens: list[Tok]) -> list[Tok]:
    merged: list[Tok] = []
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if token.kind != "string":
            merged.append(token)
            index += 1
            continue
        value = token.value
        interps = list(token.interps)
        end = token.end
        cursor = index
        while cursor + 1 < len(tokens):
            nxt = tokens[cursor + 1]
            between = src[end : nxt.start]
            if nxt.kind == "string" and between.strip() == "":
                value += nxt.value
                interps.extend(nxt.interps)
                end = nxt.end
                cursor += 1
                continue
            if (
                nxt.kind == "punct"
                and nxt.text == "+"
                and cursor + 2 < len(tokens)
                and tokens[cursor + 2].kind == "string"
                and src[end : nxt.start].strip() == ""
                and src[nxt.end : tokens[cursor + 2].start].strip() == ""
            ):
                value += tokens[cursor + 2].value
                interps.extend(tokens[cursor + 2].interps)
                end = tokens[cursor + 2].end
                cursor += 2
                continue
            break
        if cursor != index:
            merged.append(
                Tok("string", src[token.start : end], token.start, end, token.line, value, _renumber(interps))
            )
        else:
            merged.append(token)
        index = cursor + 1
    return merged


def _renumber(interps: list[Interp]) -> list[Interp]:
    used: set[str] = set()
    out: list[Interp] = []
    for item in interps:
        name = item.name
        base = name
        index = 2
        while name in used:
            name = f"{base}{index}"
            index += 1
        used.add(name)
        out.append(Interp(item.expr, name))
    return out


def _callee_at(tokens: list[Tok], paren_index: int) -> tuple[str, bool]:
    """Return (name, dotted) for the call whose '(' is tokens[paren_index]."""
    cursor = paren_index - 1
    if cursor < 0:
        return "", False
    if tokens[cursor].kind == "ident" and tokens[cursor].text == "const":
        cursor -= 1
    dotted = False
    if cursor >= 1 and tokens[cursor].kind == "ident" and tokens[cursor - 1].text == ".":
        dotted = True
        return tokens[cursor].text, dotted
    if cursor >= 0 and tokens[cursor].kind == "ident":
        return tokens[cursor].text, False
    return "", False


def _enclosing_call(tokens: list[Tok], index: int) -> tuple[str, bool] | None:
    depth = 0
    cursor = index - 1
    while cursor >= 0:
        token = tokens[cursor]
        if token.text == ")" or token.text == "]" or token.text == "}":
            depth += 1
        elif token.text in "([{":
            if depth == 0 and token.text == "(":
                return _callee_at(tokens, cursor)
            if depth == 0:
                return None
            depth -= 1
        cursor -= 1
    return None


def _is_annotation(tokens: list[Tok], index: int) -> bool:
    call = _find_open_paren(tokens, index)
    if call is None:
        return False
    name_at = call - 1
    if name_at >= 0 and tokens[name_at].text == "const":
        name_at -= 1
    if name_at >= 1 and tokens[name_at - 1].text == "@":
        return True
    if name_at >= 2 and tokens[name_at - 1].text == "." and tokens[name_at - 2].text == "@":
        return True
    return False


def _find_open_paren(tokens: list[Tok], index: int) -> int | None:
    depth = 0
    cursor = index - 1
    while cursor >= 0:
        token = tokens[cursor]
        if token.text in ")]}":
            depth += 1
        elif token.text in "([{":
            if depth == 0:
                return cursor if token.text == "(" else None
            depth -= 1
        cursor -= 1
    return None


def _technical(value: str) -> bool:
    stripped = value.strip()
    if not any(ch.isalpha() for ch in stripped):
        return True
    if len(stripped) < 2:
        return True
    lower = stripped.lower()
    if lower.startswith(("http://", "https://", "package:", "dart:", "asset:", "assets/", "./", "../")):
        return True
    if re.search(r"\.(png|jpe?g|gif|webp|svg|json|riv|mp3|wav|ogg|m4a|mp4|ttf|otf|arb|dart|md|webp)$", lower):
        return True
    if re.fullmatch(r"#[0-9a-fA-F]{3,8}", stripped):
        return True
    if re.fullmatch(r"[a-z0-9_./:+\-]+", stripped):
        return True
    if re.fullmatch(r"[yMdHhms:\-/.\s]+", stripped) and any(ch in stripped for ch in "yMdH"):
        return True
    return False


def _excluded_call(name: str, dotted: bool) -> bool:
    if name in EXCLUDED_CALLEES:
        return True
    if name.endswith("Exception") or name.endswith("Error"):
        return True
    if dotted and name in LOG_METHODS:
        return True
    return False


UI_DIRS = (
    "lib/screens/",
    "lib/widgets/",
    "lib/games/",
    "lib/avatars/",
    "lib/features/",
    "lib/l10n/",
)


def _prompt_like(value: str) -> bool:
    text = value.strip()
    lowered = text.lower()
    if len(text) > 180:
        return True
    if lowered.startswith(("you are ", "bearer ", "todo", "fixme")):
        return True
    if any(marker in text for marker in ("RULES:", "JSON only", "Bearer ", "```", "SELECT ", "INSERT ")):
        return True
    if text.count("{") > 4:
        return True
    return False


def _classify(tokens: list[Tok], index: int, path: str) -> str | None:
    token = tokens[index]
    if token.kind != "string":
        return None
    if _is_annotation(tokens, index):
        return None
    if index + 1 < len(tokens) and tokens[index + 1].text == ":":
        # `? 'yes' : 'no'` uses a colon that is not a map key.
        if not (index > 0 and tokens[index - 1].text == "?"):
            return None
    if index > 0 and tokens[index - 1].text == "case":
        return None
    if not any(ch.isalpha() for ch in token.value):
        return None
    slot = _ui_slot(tokens, index)
    if slot and not _technical(token.value):
        return slot
    # A one-word label in a widget slot ('Home', 'Retry') is still UI.
    if slot and any(ch.isalpha() for ch in token.value) and len(token.value.strip()) >= 2:
        if not _technical(token.value):
            return slot
        # 'en' / 'yo' in a text slot is a code, not copy.
        if not re.fullmatch(r"[a-z0-9_./:+\-]+", token.value.strip()):
            return slot
    if _technical(token.value) or _prompt_like(token.value):
        return None
    # Translation tables under lib/l10n are still hard-coded copy.
    if (
        path.startswith("lib/l10n/")
        and index > 0
        and tokens[index - 1].text == ":"
        and any(ch.isalpha() for ch in token.value)
    ):
        return "map-value"
    if not re.search(r"\s", token.value):
        if _map_value_key(tokens, index) and path.startswith(UI_DIRS):
            return "map-value"
        return None
    if not path.startswith(UI_DIRS):
        return None
    call = _enclosing_call(tokens, index)
    if call and _excluded_call(call[0], call[1]):
        return None
    if index > 0 and tokens[index - 1].text in {"throw", "assert"}:
        return None
    return "sentence"


def _map_value_key(tokens: list[Tok], index: int) -> str | None:
    if index < 2:
        return None
    if tokens[index - 1].text != ":":
        return None
    key = tokens[index - 2]
    if key.kind != "string":
        return None
    if key.value.strip().lower() in UI_VALUE_KEYS and not _technical(tokens[index].value):
        return key.value
    if key.value.strip().lower() in UI_VALUE_KEYS and any(ch.isalpha() for ch in tokens[index].value):
        if not re.fullmatch(r"[a-z0-9_./:+\-]+", tokens[index].value.strip()):
            return key.value
    return None


def _ui_slot(tokens: list[Tok], index: int) -> str | None:
    if index > 0 and tokens[index - 1].text == ":":
        if index < 2 or tokens[index - 2].kind != "ident":
            return None
        param = tokens[index - 2].text
        call = _enclosing_call(tokens, index)
        name = call[0] if call else ""
        dotted = call[1] if call else False
        if call and _excluded_call(name, dotted):
            return None
        if param in STRONG_PARAMS:
            return "param"
        if param in WEAK_PARAMS and name[:1].isupper():
            return "param"
        if param in WEAK_PARAMS and name in COPY_CALLEES:
            return "param"
        return None
    if index > 0 and tokens[index - 1].text in {"(", ","}:
        paren = _find_open_paren(tokens, index)
        if paren is None:
            return None
        name, dotted = _callee_at(tokens, paren)
        if _excluded_call(name, dotted):
            return None
        # First string argument only, so later positional args (styles, keys)
        # are not swept up. _tr's second argument is an existing translation.
        first = _first_string_arg(tokens, paren)
        if first != index:
            return None
        if name in TEXT_CALLEES or name in COPY_CALLEES:
            return "call"
    return None


def _first_string_arg(tokens: list[Tok], paren_index: int) -> int | None:
    depth = 0
    cursor = paren_index + 1
    while cursor < len(tokens):
        token = tokens[cursor]
        if token.text in "([{":
            depth += 1
        elif token.text in ")]}":
            if depth == 0:
                return None
            depth -= 1
        elif depth == 0 and token.kind == "string":
            if cursor > 0 and tokens[cursor - 1].text == ":":
                cursor += 1
                continue
            return cursor
        elif depth == 0 and token.text == "," and False:
            pass
        cursor += 1
    return None


def scan_source(path: str, src: str) -> list[Finding]:
    tokens = _merge_adjacent(src, lex(src))
    found: list[Finding] = []
    for index, token in enumerate(tokens):
        reason = _classify(tokens, index, path)
        if not reason:
            continue
        found.append(
            Finding(
                path=path,
                line=token.line,
                start=token.start,
                end=token.end,
                text=token.value,
                reason=reason,
                interps=list(token.interps),
            )
        )
    return found


def iter_dart_files(root: Path) -> list[Path]:
    lib = root / "lib"
    if not lib.is_dir():
        return []
    files = []
    for path in sorted(lib.rglob("*.dart")):
        if any(part in SKIP_PARTS for part in path.parts):
            continue
        if path.name.endswith(SKIP_SUFFIXES):
            continue
        files.append(path)
    return files


def scan_tree(root: Path) -> list[Finding]:
    found: list[Finding] = []
    for path in iter_dart_files(root):
        rel = path.relative_to(root).as_posix()
        src = path.read_text(encoding="utf-8", errors="replace")
        found.extend(scan_source(rel, src))
    return found


def is_clean(path: str) -> bool:
    return any(path == prefix.rstrip("/") or path.startswith(prefix) for prefix in CLEAN_PREFIXES)


def feature_for(path: str) -> str:
    if "/onboarding/" in f"/{path}" or path.startswith("lib/screens/onboarding") or path.startswith("lib/avatars/onboarding"):
        return "onboarding"
    if path.startswith("lib/screens/tabs_view/") or path == "lib/screens/home_screen.dart":
        return "shell"
    parts = Path(path).parts
    for marker in ("screens", "widgets", "games"):
        if marker in parts:
            index = parts.index(marker)
            if index + 1 < len(parts) - 1:
                return _prefix_token(parts[index + 1])
            return _prefix_token(marker)
    if len(parts) > 2:
        return _prefix_token(parts[1])
    return "app"


def _prefix_token(name: str) -> str:
    words = re.findall(r"[A-Za-z0-9]+", name)
    if not words:
        return "app"
    return words[0].lower() + "".join(word.capitalize() for word in words[1:])


def message_key(feature: str, text: str, existing: dict[str, str]) -> str:
    words = re.findall(r"[A-Za-z0-9]+", text)
    if not words:
        words = ["text"]
    body = words[0].lower() + "".join(word.capitalize() for word in words[1:6])
    body = re.sub(r"[^A-Za-z0-9]", "", body)
    if not body or not body[0].isalpha():
        body = "text" + body
    key = feature + body[0].upper() + body[1:]
    if len(key) > 48:
        key = key[:48]
    if key in existing and existing[key] != text:
        digest = hashlib.sha1(text.encode("utf-8")).hexdigest()[:4]
        key = f"{key}{digest}"
    existing[key] = text
    return key


def findings_by_file(found: list[Finding]) -> dict[str, list[str]]:
    grouped: dict[str, list[str]] = {}
    for item in found:
        grouped.setdefault(item.path, []).append(item.text)
    return grouped


def load_baseline(path: Path) -> dict:
    if not path.exists():
        return {"count": 0, "inventory_count": None, "files": {}}
    return json.loads(path.read_text(encoding="utf-8"))


def ratchet_failures(found: list[Finding], baseline: dict) -> list[str]:
    allowed: dict[str, Counter] = {
        path: Counter(messages) for path, messages in baseline.get("files", {}).items()
    }
    current = findings_by_file(found)
    failures: list[str] = []
    for path, messages in sorted(current.items()):
        if is_clean(path):
            failures.append(f"clean {path} still has {len(messages)} hard-coded UI string(s)")
            continue
        have = Counter(messages)
        base = allowed.get(path, Counter())
        for text, count in sorted(have.items()):
            extra = count - base.get(text, 0)
            if extra > 0:
                preview = text.replace("\n", " ")
                if len(preview) > 80:
                    preview = preview[:77] + "..."
                failures.append(f"+{extra} {path}: {preview}")
    return failures


# --- ICU -----------------------------------------------------------------


class IcuError(ValueError):
    pass


def _parse_message(message: str, index: int = 0, stop: str | None = None) -> tuple[list[str], int]:
    names: list[str] = []
    while index < len(message):
        char = message[index]
        if stop and char == stop:
            return names, index
        if char == "}":
            raise IcuError("unbalanced '}'")
        if char == "'":
            # '' is an escaped apostrophe. A quote that never closes is a
            # literal apostrophe ("Don't"), which gen-l10n already accepts.
            if index + 1 < len(message) and message[index + 1] == "'":
                index += 2
                continue
            close = message.find("'", index + 1)
            if close == -1:
                index += 1
                continue
            index = close + 1
            while index + 1 < len(message) and message[index] == "'" and message[index + 1] == "'":
                index += 2
                close = message.find("'", index)
                if close == -1:
                    break
                index = close + 1
            continue
        if char == "{":
            name, index, nested = _parse_placeholder(message, index)
            names.append(name)
            names.extend(nested)
            continue
        index += 1
    if stop:
        raise IcuError("unclosed placeholder body")
    return names, index


def _parse_placeholder(message: str, index: int) -> tuple[str, int, list[str]]:
    if message[index] != "{":
        raise IcuError("expected '{'")
    cursor = index + 1
    while cursor < len(message) and message[cursor].isspace():
        cursor += 1
    match = IDENT.match(message, cursor)
    if not match:
        raise IcuError("placeholder needs a name")
    name = match.group(0)
    cursor = match.end()
    while cursor < len(message) and message[cursor].isspace():
        cursor += 1
    if cursor >= len(message):
        raise IcuError("unclosed placeholder")
    if message[cursor] == "}":
        return name, cursor + 1, []
    if message[cursor] != ",":
        raise IcuError("malformed placeholder")
    cursor += 1
    while cursor < len(message) and message[cursor].isspace():
        cursor += 1
    kind_match = IDENT.match(message, cursor)
    if not kind_match:
        raise IcuError("placeholder needs a type")
    kind = kind_match.group(0)
    cursor = kind_match.end()
    while cursor < len(message) and message[cursor].isspace():
        cursor += 1
    nested: list[str] = []
    if kind in {"plural", "select", "selectordinal"}:
        if cursor >= len(message) or message[cursor] != ",":
            raise IcuError(f"{kind} needs clauses")
        cursor += 1
        saw_other = False
        saw_clause = False
        while cursor < len(message) and message[cursor] != "}":
            while cursor < len(message) and message[cursor].isspace():
                cursor += 1
            if cursor < len(message) and message[cursor] == "}":
                break
            if cursor < len(message) and message[cursor] == "=":
                cursor += 1
                if cursor >= len(message) or not message[cursor].isdigit():
                    raise IcuError("plural offset needs a number")
                while cursor < len(message) and message[cursor].isdigit():
                    cursor += 1
            else:
                cat = IDENT.match(message, cursor)
                if not cat:
                    raise IcuError(f"malformed {kind} clause")
                category = cat.group(0)
                if kind == "plural" and category not in PLURAL_CATEGORIES and category != "offset":
                    raise IcuError(f"unknown plural category {category}")
                if category == "other":
                    saw_other = True
                cursor = cat.end()
            while cursor < len(message) and message[cursor].isspace():
                cursor += 1
            if cursor >= len(message) or message[cursor] != "{":
                raise IcuError(f"{kind} clause needs a body")
            inner, cursor = _parse_message(message, cursor + 1, stop="}")
            if cursor >= len(message) or message[cursor] != "}":
                raise IcuError("unclosed clause")
            cursor += 1
            nested.extend(inner)
            saw_clause = True
        if not saw_clause:
            raise IcuError(f"{kind} has no clauses")
        if kind == "plural" and not saw_other:
            raise IcuError("plural needs an other clause")
        if cursor >= len(message) or message[cursor] != "}":
            raise IcuError(f"unclosed {kind}")
        return name, cursor + 1, nested
    # number, date, or a simple style. Accept the rest until the matching '}'.
    depth = 1
    while cursor < len(message) and depth:
        if message[cursor] == "{":
            depth += 1
        elif message[cursor] == "}":
            depth -= 1
            if depth == 0:
                break
        cursor += 1
    if cursor >= len(message) or message[cursor] != "}":
        raise IcuError("unclosed placeholder")
    return name, cursor + 1, nested


def validate_message(message: str) -> list[str]:
    names, index = _parse_message(message, 0, None)
    if index != len(message):
        raise IcuError("trailing junk")
    return names


def validate_arb(data: dict) -> list[str]:
    errors: list[str] = []
    for key, value in data.items():
        if key.startswith("@") or not isinstance(value, str):
            continue
        try:
            names = validate_message(value)
        except IcuError as exc:
            errors.append(f"{key}: {exc}")
            continue
        meta = data.get("@" + key)
        if not isinstance(meta, dict):
            if names:
                errors.append(f"{key}: placeholders missing metadata")
            continue
        declared = meta.get("placeholders") or {}
        if not isinstance(declared, dict):
            errors.append(f"{key}: placeholders metadata is not an object")
            continue
        for name in names:
            if name not in declared:
                errors.append(f"{key}: placeholder {{{name}}} is not declared")
        for name in declared:
            if name not in names:
                errors.append(f"{key}: declared placeholder {name} is unused")
    return errors


def arb_path(root: Path) -> Path:
    return root / "lib" / "l10n" / "app_en.arb"


def load_arb(path: Path) -> dict:
    if not path.exists():
        return {"@@locale": "en"}
    return json.loads(path.read_text(encoding="utf-8"))


def append_arb(path: Path, entries: list[tuple[str, str, dict]]) -> None:
    if not entries:
        return
    text = path.read_text(encoding="utf-8") if path.exists() else '{ "@@locale": "en" }\n'
    stripped = text.rstrip()
    if not stripped.endswith("}"):
        raise IcuError(f"{path} is not a JSON object")
    body = stripped[: stripped.rfind("}")]
    if body.rstrip().endswith(","):
        body = body.rstrip()[:-1]
    needs_comma = body.rstrip().endswith("}") or body.rstrip().endswith('"') or body.rstrip().endswith("]")
    # The object is non-empty when anything but whitespace and '{' remains.
    nonempty = body.strip() not in {"", "{"}
    chunks = [body.rstrip()]
    if nonempty and not chunks[-1].endswith(","):
        chunks[-1] = chunks[-1] + ","
    for key, message, meta in entries:
        chunks.append(f"\n  {json.dumps(key, ensure_ascii=False)}: {json.dumps(message, ensure_ascii=False)},")
        meta_text = json.dumps(meta, ensure_ascii=False, indent=2)
        indented = "\n".join(("  " + line) if line else line for line in meta_text.splitlines())
        chunks.append(f"\n  {json.dumps('@' + key)}: {indented}")
        chunks.append(",")
    # Drop the trailing comma before the closing brace.
    if chunks[-1] == ",":
        chunks.pop()
    rendered = "".join(chunks) + "\n}\n"
    data = json.loads(rendered)
    errors = validate_arb(data)
    if errors:
        raise IcuError(errors[0])
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(rendered, encoding="utf-8")
    if not needs_comma:
        return


# --- rewrite -------------------------------------------------------------


def _context_expr(tokens: list[Tok], offset: int) -> str:
    """BuildContext parameter of the function that contains offset."""
    index = 0
    for cursor, token in enumerate(tokens):
        if token.start <= offset:
            index = cursor
        else:
            break
    depth = 0
    for cursor in range(index, -1, -1):
        token = tokens[cursor]
        if token.text == "}":
            depth += 1
        elif token.text == "{":
            if depth == 0:
                for back in range(cursor - 1, max(-1, cursor - 80), -1):
                    if tokens[back].text in {"{", ";"}:
                        break
                    if (
                        tokens[back].text == "BuildContext"
                        and back + 1 < cursor
                        and tokens[back + 1].kind == "ident"
                    ):
                        return tokens[back + 1].text
                return "context"
            depth -= 1
    return "context"


def _call_text(key: str, interps: list[Interp], context_name: str, *, plural_arg: str | None = None) -> str:
    base = f"l10nOf({context_name}).{key}"
    if plural_arg:
        return f"{base}({plural_arg})"
    if not interps:
        return base
    args = []
    for item in interps:
        expr = item.expr.strip()
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", expr):
            # int and String both stringify; the ARB placeholder is a String.
            args.append(f"{expr}.toString()")
        else:
            args.append("'${" + expr + "}'")
    return base + "(" + ", ".join(args) + ")"


def _placeholder_type(expr: str) -> str:
    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", expr.strip()):
        return "String"
    return "String"


def _replace_plural_ternaries(
    src: str,
    feature: str,
    claimed: dict[str, str],
    existing: dict[str, str],
    written_keys: set[str],
) -> tuple[str, list[tuple[str, str, dict]]]:
    """Turn `n == 1 ? 'one' : '$n many'` into one ICU plural."""
    tokens = _merge_adjacent(src, lex(src))
    spans: list[tuple[int, int, str, str, dict]] = []
    for index, token in enumerate(tokens):
        if token.kind != "ident" or index + 6 >= len(tokens):
            continue
        # Lexer emits '==' as two '=' puncts.
        if not (
            index + 7 < len(tokens)
            and tokens[index + 1].text == "="
            and tokens[index + 2].text == "="
            and tokens[index + 3].text == "1"
            and tokens[index + 4].text == "?"
            and tokens[index + 5].kind == "string"
            and tokens[index + 6].text == ":"
            and tokens[index + 7].kind == "string"
        ):
            continue
        name = token.text
        singular = tokens[index + 5].value
        plural = tokens[index + 7].value
        message = "{" + name + ", plural, =1{" + singular + "} other{" + plural + "}}"
        try:
            validate_message(message)
        except IcuError:
            continue
        key = message_key(feature, singular + " " + plural, claimed)
        meta = {
            "description": f"{feature}. {singular[:60]}",
            "placeholders": {name: {"type": "int"}},
        }
        context_name = _context_expr(tokens, token.start)
        call = _call_text(key, [], context_name, plural_arg=name)
        spans.append((token.start, tokens[index + 7].end, call, key, message, meta))
    entries: list[tuple[str, str, dict]] = []
    for start, end, call, key, message, meta in sorted(spans, key=lambda row: row[0], reverse=True):
        if key not in existing and key not in written_keys:
            entries.append((key, message, meta))
            written_keys.add(key)
            existing[key] = message
        src = src[:start] + call + src[end:]
    return src, entries


def _fix_part_imports(root: Path, targets: list[str]) -> None:
    parents: set[Path] = set()
    for rel in targets:
        path = root / rel
        if not path.is_file():
            continue
        src = path.read_text(encoding="utf-8")
        if "l10nOf(" not in src:
            continue
        match = re.match(r"\s*part of\s+'([^']+)'", src)
        if not match:
            continue
        parent = (path.parent / match.group(1)).resolve()
        parents.add(parent)
    for parent in parents:
        if not parent.is_file():
            continue
        text = parent.read_text(encoding="utf-8")
        updated = _ensure_import(text)
        if updated != text:
            parent.write_text(updated, encoding="utf-8")


def extract_files(root: Path, rel_paths: list[str]) -> int:
    arb = load_arb(arb_path(root))
    existing = {key: value for key, value in arb.items() if isinstance(value, str) and not key.startswith("@")}
    # Keep the first message for a key so collisions suffix.
    claimed = dict(existing)
    entries: list[tuple[str, str, dict]] = []
    written_keys: set[str] = set()
    changed = 0
    targets = []
    for rel in rel_paths:
        path = root / rel
        if path.is_dir():
            targets.extend(sorted(p.relative_to(root).as_posix() for p in path.rglob("*.dart")))
        elif path.is_file():
            targets.append(rel)
    for rel in targets:
        if rel.startswith("lib/design/"):
            continue
        path = root / rel
        src = path.read_text(encoding="utf-8")
        feature = feature_for(rel)
        src, plural_entries = _replace_plural_ternaries(src, feature, claimed, existing, written_keys)
        entries.extend(plural_entries)
        found = scan_source(rel, src)
        if not found and not plural_entries:
            if src != path.read_text(encoding="utf-8"):
                path.write_text(src, encoding="utf-8")
                changed += 1
            continue
        tokens = lex(src)
        # Replace from the end so earlier spans stay valid.
        for item in sorted(found, key=lambda row: row.start, reverse=True):
            key_source = item.text
            key = message_key(feature, key_source, claimed)
            if key not in existing and key not in written_keys:
                meta: dict = {"description": f"{feature}. {key_source[:80]}"}
                if item.interps:
                    meta["placeholders"] = {
                        interp.name: {"type": "String"} for interp in item.interps
                    }
                entries.append((key, item.text, meta))
                written_keys.add(key)
                existing[key] = item.text
            context_name = _context_expr(tokens, item.start)
            replacement = _call_text(key, item.interps, context_name)
            src = src[: item.start] + replacement + src[item.end :]
        src = _rewrite_const_fields(src)
        src = _strip_const_expressions(src)
        src = _ensure_import(src)
        path.write_text(src, encoding="utf-8")
        changed += 1
    _fix_part_imports(root, targets)
    if entries:
        append_arb(arb_path(root), entries)
    return changed


def _ensure_import(src: str) -> str:
    if "l10nOf(" not in src:
        return src
    if src.lstrip().startswith("part of "):
        return src
    import_line = "import 'package:lingafriq/l10n/l10n_of.dart';\n"
    if "package:lingafriq/l10n/l10n_of.dart" in src:
        return src
    lines = src.splitlines(keepends=True)
    last_import = -1
    for index, line in enumerate(lines):
        if line.startswith("import "):
            last_import = index
    if last_import == -1:
        return import_line + src
    lines.insert(last_import + 1, import_line)
    return "".join(lines)


def _strip_const_expressions(src: str) -> str:
    tokens = lex(src)
    spans: list[tuple[int, int]] = []
    for index, token in enumerate(tokens):
        if token.kind != "ident" or token.text != "const":
            continue
        expr_end = _const_expr_end(src, token.end)
        if expr_end is None:
            continue
        body = src[token.end : expr_end]
        if "l10nOf(" in body or "(context)" in body:
            spans.append((token.start, token.end))
    for start, end in reversed(spans):
        # Drop the keyword and one following space.
        drop_end = end + 1 if end < len(src) and src[end] == " " else end
        src = src[:start] + src[drop_end:]
    return src


def _const_expr_end(src: str, index: int) -> int | None:
    length = len(src)
    while index < length and src[index].isspace():
        index += 1
    if index >= length:
        return None
    if src[index] == "<":
        index = _match_bracket(src, index, "<", ">")
        if index is None:
            return None
        while index < length and src[index].isspace():
            index += 1
    if index < length and (src[index].isalpha() or src[index] == "_"):
        while index < length and (src[index].isalnum() or src[index] in "._"):
            index += 1
        while index < length and src[index].isspace():
            index += 1
        if index < length and src[index] == "<":
            index = _match_bracket(src, index, "<", ">")
            if index is None:
                return None
            while index < length and src[index].isspace():
                index += 1
        # `const String name =` is a declaration, not a const expression.
        if index < length and (src[index].isalpha() or src[index] == "_"):
            return None
        if index < length and src[index] == "=":
            return None
    if index < length and src[index] in "([{":
        pairs = {"(": ")", "[": "]", "{": "}"}
        return _match_bracket(src, index, src[index], pairs[src[index]])
    return index


def _match_bracket(src: str, index: int, open_ch: str, close_ch: str) -> int | None:
    if index >= len(src) or src[index] != open_ch:
        return None
    depth = 0
    cursor = index
    while cursor < len(src):
        token = _parse_quoted(src, cursor) if src[cursor] in "'\"" or (
            src[cursor] == "r" and cursor + 1 < len(src) and src[cursor + 1] in "'\""
        ) else None
        if token and token.start == cursor:
            cursor = token.end
            continue
        if src.startswith("//", cursor):
            nxt = src.find("\n", cursor)
            cursor = len(src) if nxt == -1 else nxt + 1
            continue
        if src.startswith("/*", cursor):
            nxt = src.find("*/", cursor + 2)
            cursor = len(src) if nxt == -1 else nxt + 2
            continue
        char = src[cursor]
        if char == open_ch:
            depth += 1
        elif char == close_ch:
            depth -= 1
            if depth == 0:
                return cursor + 1
        cursor += 1
    return None


def _class_bounds(src: str, index: int) -> tuple[str, int, int] | None:
    tokens = lex(src)
    depth = 0
    opened: list[tuple[int, int]] = []
    classes: list[tuple[str, int, int]] = []
    for cursor, token in enumerate(tokens):
        if token.text == "{":
            if cursor > 0 and tokens[cursor - 1].kind == "ident":
                # class Name {  or  class Name extends X {
                window = tokens[max(0, cursor - 8) : cursor]
                for back, item in enumerate(window):
                    if item.text == "class" and back + 1 < len(window) and window[back + 1].kind == "ident":
                        opened.append((window[back + 1].text, token.end))
                        break
            depth += 1
        elif token.text == "}":
            depth -= 1
            if opened and depth == len(opened) - 1 or (opened and depth < len(opened)):
                # Close the class whose brace we opened when depth returns.
                pass
    # Brace match classes directly.
    classes = []
    for match in re.finditer(r"\bclass\s+([A-Za-z_]\w*)\b", src):
        brace = src.find("{", match.end())
        if brace == -1:
            continue
        end = _match_bracket(src, brace, "{", "}")
        if end is None:
            continue
        classes.append((match.group(1), match.start(), end))
    for name, start, end in classes:
        if start <= index < end:
            return name, start, end
    return None


def _rewrite_const_fields(src: str) -> str:
    """Turn `static const name = <l10n>...;` into a function of BuildContext."""
    replacements: list[tuple[int, int, str, str]] = []
    for match in re.finditer(r"(?m)^(?P<indent>[ \t]*)(?P<static>static[ \t]+)?const[ \t]+", src):
        start = match.start()
        decl = _read_declaration(src, match.end())
        if decl is None:
            continue
        name, type_name, init, end = decl
        if "l10nOf(" not in init:
            continue
        indent = match.group("indent")
        static = "static " if match.group("static") else ""
        type_part = f"{type_name} " if type_name else ""
        rendered = f"{indent}{static}{type_part}{name}(BuildContext context) => {init.strip()};"
        replacements.append((start, end, rendered, name))
    names = [name for _, _, _, name in replacements]
    for start, end, rendered, _name in reversed(replacements):
        src = src[:start] + rendered + src[end:]
    for name in names:
        match = re.search(rf"\b{re.escape(name)}\(BuildContext context\)", src)
        if not match:
            continue
        bounds = _class_bounds(src, match.start())
        if bounds:
            class_name, class_start, class_end = bounds
            region = _rewrite_name_uses(src[class_start:class_end], name)
            src = src[:class_start] + region + src[class_end:]
            src = re.sub(
                rf"\b{re.escape(class_name)}\.{re.escape(name)}(?!\s*\()",
                f"{class_name}.{name}(context)",
                src,
            )
        else:
            src = _rewrite_name_uses(src, name)
    return src


def _read_declaration(src: str, index: int) -> tuple[str, str | None, str, int] | None:
    length = len(src)
    cursor = index
    while cursor < length and src[cursor].isspace():
        cursor += 1
    type_or_name = _read_type_or_ident(src, cursor)
    if type_or_name is None:
        return None
    first, cursor = type_or_name
    while cursor < length and src[cursor].isspace():
        cursor += 1
    if cursor < length and (src[cursor].isalpha() or src[cursor] == "_"):
        name_match = IDENT.match(src, cursor)
        if not name_match:
            return None
        type_name = first
        name = name_match.group(0)
        cursor = name_match.end()
    else:
        type_name = None
        name = first
    while cursor < length and src[cursor].isspace():
        cursor += 1
    if cursor >= length or src[cursor] != "=":
        return None
    cursor += 1
    init_start = cursor
    end = _statement_end(src, cursor)
    if end is None:
        return None
    init = src[init_start:end].strip()
    if init.endswith(";"):
        init = init[:-1].strip()
        semi = end
    else:
        semi = end
    # end points at the semicolon index or just after it. Normalize to after semicolon.
    if semi < length and src[semi] == ";":
        semi += 1
    return name, type_name, init, semi


def _read_type_or_ident(src: str, index: int) -> tuple[str, int] | None:
    match = IDENT.match(src, index)
    if not match:
        return None
    cursor = match.end()
    text = match.group(0)
    while True:
        while cursor < len(src) and src[cursor].isspace():
            cursor += 1
        if cursor < len(src) and src[cursor] == "<":
            end = _match_bracket(src, cursor, "<", ">")
            if end is None:
                return None
            text += src[cursor:end]
            cursor = end
            continue
        if cursor < len(src) and src[cursor] == ".":
            nxt = IDENT.match(src, cursor + 1)
            if not nxt:
                break
            text += "." + nxt.group(0)
            cursor = nxt.end()
            continue
        if cursor < len(src) and src[cursor] == "?":
            text += "?"
            cursor += 1
            continue
        break
    return text, cursor


def _statement_end(src: str, index: int) -> int | None:
    depth = 0
    cursor = index
    while cursor < len(src):
        if src[cursor] in "'\"" or (src[cursor] == "r" and cursor + 1 < len(src) and src[cursor + 1] in "'\""):
            token = _parse_quoted(src, cursor)
            if token and token.start == cursor:
                cursor = token.end
                continue
        if src.startswith("//", cursor):
            nxt = src.find("\n", cursor)
            cursor = len(src) if nxt == -1 else nxt + 1
            continue
        char = src[cursor]
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth = max(0, depth - 1)
        elif char == ";" and depth == 0:
            return cursor
        cursor += 1
    return None


def _rewrite_name_uses(src: str, name: str) -> str:
    pattern = re.compile(rf"(?<![\w.]){re.escape(name)}(?!\s*[\w(:])")

    def replacer(match: re.Match[str]) -> str:
        return f"{name}(context)"

    return pattern.sub(replacer, src)


def write_baseline(path: Path, found: list[Finding], inventory: int | None) -> None:
    files = {key: value for key, value in findings_by_file(found).items() if not is_clean(key)}
    payload = {
        "elevation_note": 1104,
        "inventory_count": inventory if inventory is not None else len(found),
        "count": sum(len(messages) for messages in files.values()),
        "note": "inventory_count is the user-visible string literals under lib/ before shell and onboarding were extracted. count is the ratchet ceiling after that pass. Elevation section 13.8 said 1104; this scan recorded inventory_count instead.",
        "files": files,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--baseline", default="scripts/i18n/string_baseline.json")
    parser.add_argument("--write-baseline", action="store_true")
    parser.add_argument("--inventory", type=int, default=None, help="Recorded pre-extraction count")
    parser.add_argument("--extract", action="append", default=[], help="Directory or file to extract")
    parser.add_argument("--report", action="store_true")
    args = parser.parse_args(argv)
    root = Path(args.root)
    baseline_path = Path(args.baseline)
    if not baseline_path.is_absolute():
        baseline_path = root / baseline_path
    if args.extract:
        extract_files(root, args.extract)
    found = scan_tree(root)
    if args.report:
        reasons = Counter(item.reason for item in found)
        print(f"i18n-strings: scanned {len(found)}")
        for reason, count in reasons.most_common():
            print(f"  {count} {reason}")
        return 0
    errors = validate_arb(load_arb(arb_path(root))) if arb_path(root).exists() else []
    if args.write_baseline:
        inventory = args.inventory if args.inventory is not None else len(found)
        write_baseline(baseline_path, found, inventory)
        print(f"i18n-strings: wrote {sum(len(v) for v in findings_by_file(found).values())} (inventory {inventory})")
        if errors:
            print("i18n-strings: malformed")
            print("\n".join(errors[:13]))
            return 1
        return 0
    if errors:
        print("i18n-strings: malformed")
        print("\n".join(errors[:13]))
        return 1
    baseline = load_baseline(baseline_path)
    failures = ratchet_failures(found, baseline)
    remaining = len(found)
    inventory = baseline.get("inventory_count")
    extra = f"; inventory {inventory}" if inventory else ""
    if failures:
        lines = [f"i18n-strings: fail", f"remaining {remaining}{extra}"]
        lines.extend(failures[:13])
        if len(failures) > 13:
            lines.append(f"+{len(failures) - 13} more")
        print("\n".join(lines))
        return 1
    print(f"i18n-strings: {remaining} remaining{extra}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

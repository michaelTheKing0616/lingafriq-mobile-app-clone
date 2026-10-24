"""Hausa hooked-letter, display-mark, and teaching-mark lint."""

from __future__ import annotations

import unicodedata
from collections.abc import Mapping

from tools.content_engine.linters.types import LintResult, Span

_TEXT_ROLES = frozenset({"display", "teaching"})
_TONE_LENGTH = frozenset({"\u0300", "\u0301", "\u0302", "\u0304"})
_HOOK_PLAIN: dict[str, frozenset[str]] = {
    "ɓ": frozenset({"b"}),
    "Ɓ": frozenset({"B"}),
    "ɗ": frozenset({"d"}),
    "Ɗ": frozenset({"D"}),
    "ƙ": frozenset({"k"}),
    "Ƙ": frozenset({"K"}),
    "ƴ": frozenset({"y"}),
    "Ƴ": frozenset({"Y"}),
    "\u02bc": frozenset({"\u0027", "\u2019"}),
}


def lint_hausa(item: Mapping, kit: Mapping) -> LintResult:
    """Fail the first of: hook replacement, display mark, unsourced teaching mark."""
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")

    item_id = item["id"]
    text_role = item["text_role"]
    tokens = item["tokens"]
    if text_role not in _TEXT_ROLES:
        raise ValueError(f"unsupported text_role: {text_role!r}")

    for token in tokens:
        result = _lint_token(item_id, token, text_role)
        if result is not None:
            return result

    return LintResult(item_id=item_id, rule_id="HA", span=Span(0, 0), status="pass")


def _lint_token(item_id: str, token: Mapping, text_role: str) -> LintResult | None:
    surface = token["surface"]
    lexicon = token["lexicon"]
    dictionary_sourced = token["dictionary_sourced"]

    lex_clusters = _clusters(lexicon)
    surf_clusters = _clusters(surface)

    for index, (lex_text, _, _) in enumerate(lex_clusters):
        if index >= len(surf_clusters):
            break
        surf_text, start, end = surf_clusters[index]
        lex_base, _ = _base_and_marks(lex_text)
        surf_base, _ = _base_and_marks(surf_text)
        if _is_plain_replacement(lex_base, surf_base):
            return LintResult(
                item_id=item_id,
                rule_id="HA_HOOKED_LETTER",
                span=Span(start, end),
                status="fail",
            )

    if text_role == "display":
        marked = _first_marked_span(surf_clusters)
        if marked is not None:
            start, end = marked
            return LintResult(
                item_id=item_id,
                rule_id="HA_DISPLAY_MARKED",
                span=Span(start, end),
                status="fail",
            )
        return None

    for index, (surf_text, start, end) in enumerate(surf_clusters):
        _, surf_marks = _base_and_marks(surf_text)
        if not surf_marks:
            continue
        if not dictionary_sourced or index >= len(lex_clusters):
            return LintResult(
                item_id=item_id,
                rule_id="HA_MARK_NO_DICT",
                span=Span(start, end),
                status="fail",
            )
        _, lex_marks = _base_and_marks(lex_clusters[index][0])
        if not surf_marks <= lex_marks:
            return LintResult(
                item_id=item_id,
                rule_id="HA_MARK_NO_DICT",
                span=Span(start, end),
                status="fail",
            )
    return None


def _is_plain_replacement(lex_base: str, surf_base: str) -> bool:
    plains = _HOOK_PLAIN.get(lex_base)
    if plains is None or surf_base in _HOOK_PLAIN:
        return False
    folded = surf_base.casefold()
    return any(folded == plain.casefold() for plain in plains)


def _first_marked_span(
    clusters: list[tuple[str, int, int]],
) -> tuple[int, int] | None:
    for text, start, end in clusters:
        _, marks = _base_and_marks(text)
        if marks:
            return start, end
    return None


def _base_and_marks(cluster: str) -> tuple[str, frozenset[str]]:
    nfd = unicodedata.normalize("NFD", cluster)
    if not nfd:
        return "", frozenset()
    marks = frozenset(char for char in nfd[1:] if char in _TONE_LENGTH)
    return nfd[0], marks


def _clusters(text: str) -> list[tuple[str, int, int]]:
    clusters: list[tuple[str, int, int]] = []
    index = 0
    length = len(text)
    while index < length:
        start = index
        index += 1
        while index < length and unicodedata.combining(text[index]) != 0:
            index += 1
        clusters.append((text[start:index], start, index))
    return clusters

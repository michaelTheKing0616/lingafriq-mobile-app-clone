"""Yoruba dot-below, tone, and lexicon-diacritic lint (CURRICULUM §3.3)."""

from __future__ import annotations

import unicodedata
from collections.abc import Mapping

from tools.content_engine.linters.types import LintResult, Span

_ACUTE = "\u0301"
_GRAVE = "\u0300"
_TONES = frozenset({_ACUTE, _GRAVE})
_DOT_BELOW = "\u0323"
_DOT_BASES = frozenset("eosEOS")


def lint_yoruba(item: Mapping, kit: Mapping) -> LintResult:
    """Fail the first of: missing underdot, unmarked syllabic nasal, lexicon mismatch, unmarked token."""
    if not isinstance(kit, Mapping):
        raise TypeError("kit must be a mapping")

    item_id = item["id"]
    learner_facing = item["learner_facing"]
    for token in item["tokens"]:
        result = _lint_token(item_id, token, learner_facing)
        if result is not None:
            return result

    return LintResult(item_id=item_id, rule_id="YO", span=Span(0, 0), status="pass")


def _lint_token(
    item_id: str, token: Mapping, learner_facing: bool
) -> LintResult | None:
    surface = token["surface"]
    lexicon = token["lexicon"]
    syllabic = token["syllabic"]

    dropped = _dotbelow_failure(item_id, surface, lexicon)
    if dropped is not None:
        return dropped

    if syllabic and not _has_tone(surface):
        return LintResult(
            item_id=item_id,
            rule_id="YO_NASAL_TONE",
            span=Span(0, len(surface)),
            status="fail",
        )

    if _nfc(surface) != _nfc(lexicon):
        missing_tone_only = (
            learner_facing
            and _has_tone(lexicon)
            and not _has_tone(surface)
            and _strip_tones(surface) == _strip_tones(lexicon)
        )
        if not missing_tone_only:
            return LintResult(
                item_id=item_id,
                rule_id="YO_DIACRITIC_MISMATCH",
                span=_first_diff_span(surface, lexicon),
                status="fail",
            )

    if learner_facing and _has_tone(lexicon) and not _has_tone(surface):
        return LintResult(
            item_id=item_id,
            rule_id="YO_UNMARKED_TOKEN",
            span=Span(0, len(surface)),
            status="fail",
        )

    return None


def _dotbelow_failure(item_id: str, surface: str, lexicon: str) -> LintResult | None:
    surf_clusters = _clusters(surface)
    for index, (lex_text, _, _) in enumerate(_clusters(lexicon)):
        if not _has_required_underdot(lex_text):
            continue
        if index >= len(surf_clusters):
            end = len(surface)
            return LintResult(
                item_id=item_id,
                rule_id="YO_DOTBELOW",
                span=Span(end, end),
                status="fail",
            )
        surf_text, start, end = surf_clusters[index]
        if _plain_or_dropped_underdot(lex_text, surf_text):
            return LintResult(
                item_id=item_id,
                rule_id="YO_DOTBELOW",
                span=Span(start, end),
                status="fail",
            )
    return None


def _has_required_underdot(cluster: str) -> bool:
    nfd = unicodedata.normalize("NFD", cluster)
    return bool(nfd) and nfd[0] in _DOT_BASES and _DOT_BELOW in nfd


def _plain_or_dropped_underdot(lex_cluster: str, surf_cluster: str) -> bool:
    surf_nfd = unicodedata.normalize("NFD", surf_cluster)
    if not surf_nfd or _DOT_BELOW in surf_nfd:
        return False
    lex_base = unicodedata.normalize("NFD", lex_cluster)[0]
    return surf_nfd[0] == lex_base


def _has_tone(text: str) -> bool:
    nfd = unicodedata.normalize("NFD", text)
    return _ACUTE in nfd or _GRAVE in nfd


def _strip_tones(text: str) -> str:
    nfd = unicodedata.normalize("NFD", text)
    stripped = "".join(char for char in nfd if char not in _TONES)
    return _nfc(stripped)


def _nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text)


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


def _first_diff_span(surface: str, lexicon: str) -> Span:
    lex_clusters = _clusters(lexicon)
    for (surf_text, start, end), (lex_text, _, _) in zip(
        _clusters(surface), lex_clusters
    ):
        if _nfc(surf_text) != _nfc(lex_text):
            return Span(start, end)
    if surface:
        return Span(0, len(surface))
    return Span(0, 0)

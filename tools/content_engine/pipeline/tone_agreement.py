"""Gate tone and diacritics by lexicon, generator, and restorer agreement (P4-061)."""

from __future__ import annotations

import unicodedata
from collections.abc import Mapping, Sequence
from typing import Any

CARD_ID = "P4-061"

_ACUTE = "\u0301"
_GRAVE = "\u0300"
_DOT_BELOW = "\u0323"
_TONE_MARKS = frozenset({_ACUTE, _GRAVE})


class ToneAgreementError(Exception):
    """Tone agreement validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text)


def has_tone_or_teaching_mark(text: str) -> bool:
    """True when the surface carries a tone mark or a dot-below teaching diacritic."""
    nfd = unicodedata.normalize("NFD", text)
    if any(mark in nfd for mark in _TONE_MARKS):
        return True
    return _DOT_BELOW in nfd


def resolve_restorer(kit: Mapping[str, Any]) -> str | None:
    """Return configured restorer tool id, or None when the kit uses two-way agreement only."""
    if not isinstance(kit, Mapping):
        raise ToneAgreementError("KIT_INVALID", "kit must be a mapping")
    raw = kit.get("tone_restorer")
    if raw is None:
        return None
    if not isinstance(raw, str):
        raise ToneAgreementError("KIT_INVALID", "tone_restorer must be a string when present")
    value = raw.strip()
    if not value or value.casefold() == "none":
        return None
    return value


def _token_field(token: Mapping[str, Any], *keys: str) -> str:
    for key in keys:
        value = token.get(key)
        if isinstance(value, str):
            return value
    raise ToneAgreementError("TOKEN_INVALID", "token requires generator and lexicon string fields")


def _evaluate_token(
    token: Mapping[str, Any],
    *,
    restorer_id: str | None,
) -> dict[str, Any]:
    generator = _token_field(token, "generator", "surface")
    lexicon = _token_field(token, "lexicon", "lexicon_form")
    matched = token.get("matched")
    if matched is None:
        matched = bool(lexicon.strip())
    if not isinstance(matched, bool):
        raise ToneAgreementError("TOKEN_INVALID", "token matched must be boolean when present")

    restorer_form: str | None = None
    if restorer_id is not None:
        raw_restorer = token.get("restorer", token.get("restorer_form"))
        if raw_restorer is None:
            return {
                "status": "disagreement",
                "reason": "RESTORER_FORM_MISSING",
                "matched": matched,
                "route": "linguist",
            }
        if not isinstance(raw_restorer, str):
            raise ToneAgreementError("TOKEN_INVALID", "restorer form must be a string")
        restorer_form = raw_restorer

    if not matched:
        if has_tone_or_teaching_mark(generator):
            return {
                "status": "unmatched",
                "reason": "UNMATCHED_TONE_MARKED",
                "matched": False,
                "route": "linguist",
            }
        return {
            "status": "skipped",
            "reason": "UNMATCHED_UNMARKED",
            "matched": False,
            "route": None,
        }

    lex_n = nfc(lexicon)
    gen_n = nfc(generator)
    if lex_n != gen_n:
        return {
            "status": "disagreement",
            "reason": "LEXICON_GENERATOR_MISMATCH",
            "matched": True,
            "route": "linguist",
        }

    if restorer_id is not None and restorer_form is not None:
        if nfc(restorer_form) != lex_n:
            return {
                "status": "disagreement",
                "reason": "RESTORER_MISMATCH",
                "matched": True,
                "route": "linguist",
            }

    return {
        "status": "agree",
        "reason": None,
        "matched": True,
        "route": None,
    }


def evaluate_tone_agreement(
    item: Mapping[str, Any],
    kit: Mapping[str, Any],
) -> dict[str, Any]:
    """Evaluate three-way (or two-way) tone agreement for lexicon-matched tokens."""
    if not isinstance(item, Mapping):
        raise ToneAgreementError("ITEM_INVALID", "item must be a mapping")

    tokens = item.get("tokens")
    if not isinstance(tokens, Sequence) or isinstance(tokens, (str, bytes)):
        raise ToneAgreementError("ITEM_INVALID", "item.tokens must be a list")
    if not tokens:
        raise ToneAgreementError("ITEM_INVALID", "item.tokens must be non-empty")

    restorer_id = resolve_restorer(kit)
    restorer_report = restorer_id if restorer_id is not None else "none"

    rows: list[dict[str, Any]] = []
    linguist_required = False
    agreed = 0
    evaluated = 0

    for index, token in enumerate(tokens):
        if not isinstance(token, Mapping):
            raise ToneAgreementError("TOKEN_INVALID", f"token {index}: must be a mapping")
        row = _evaluate_token(token, restorer_id=restorer_id)
        row["index"] = index
        rows.append(row)
        if row["route"] == "linguist":
            linguist_required = True
        if row["status"] == "agree":
            agreed += 1
            evaluated += 1
        elif row["status"] in ("disagreement", "unmatched"):
            evaluated += 1

    feature: float | None = None
    if evaluated > 0:
        feature = agreed / evaluated

    can_publish = not linguist_required and evaluated > 0 and agreed == evaluated

    return {
        "card_id": CARD_ID,
        "status": "ok" if can_publish else "linguist",
        "can_publish": can_publish,
        "route": "linguist" if linguist_required else ("auto" if can_publish else "linguist"),
        "restorer": restorer_report,
        "token_results": rows,
        "features": {"tone_agreement": feature},
    }


def tone_agreement_feature(result: Mapping[str, Any]) -> float | None:
    """Read the tone_agreement feature from a stage result."""
    features = result.get("features")
    if not isinstance(features, Mapping):
        return None
    value = features.get("tone_agreement")
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return float(value)
    return None

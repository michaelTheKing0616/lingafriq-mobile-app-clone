"""F0 contour vs lexicon tone pattern — automated tone proxy (P5-059, CP-§7-yo-06)."""

from __future__ import annotations

import re
import unicodedata
from collections.abc import Sequence
from dataclasses import dataclass
from typing import Any

CARD_ID = "P5-059"

_TONAL_LANGS = frozenset({"yo", "ig", "ha"})
_HML = frozenset({"H", "M", "L"})
_HA_LEVELS = frozenset({"H", "L", "F"})
_PATTERN_SPLIT = re.compile(r"[\s,\-/]+")


class ToneProxyError(Exception):
    """F0 tone proxy failure."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class ToneProxyResult:
    expected: tuple[str, ...]
    observed: tuple[str, ...]
    matched: bool


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def normalize_tone_pattern(pattern: Sequence[str] | str) -> tuple[str, ...]:
    if isinstance(pattern, str):
        raw = [p for p in _PATTERN_SPLIT.split(nfc(pattern)) if p]
    else:
        raw = [nfc(str(p)) for p in pattern if nfc(str(p))]
    if not raw:
        raise ToneProxyError("TONE_PATTERN_EMPTY", "tone_pattern must be non-empty")
    upper = tuple(p.upper() for p in raw)
    return upper


def f0_to_relative_levels(
    f0_hz: Sequence[float],
    *,
    language_id: str = "yo",
) -> tuple[str, ...]:
    if not f0_hz:
        raise ToneProxyError("F0_EMPTY", "F0 samples must be non-empty")
    values = [float(v) for v in f0_hz]
    lo = min(values)
    hi = max(values)
    if hi - lo < 1e-6:
        return tuple("M" if language_id != "ha" else "L" for _ in values)

    levels: list[str] = []
    for v in values:
        t = (v - lo) / (hi - lo)
        if language_id == "ha":
            if t >= 2 / 3:
                levels.append("H")
            elif t <= 1 / 3:
                levels.append("L")
            else:
                levels.append("F")
        else:
            if t >= 2 / 3:
                levels.append("H")
            elif t <= 1 / 3:
                levels.append("L")
            else:
                levels.append("M")
    return tuple(levels)


def compare_f0_to_tone_pattern(
    tone_pattern: Sequence[str] | str,
    f0_hz: Sequence[float],
    *,
    language_id: str = "yo",
) -> ToneProxyResult:
    lang = language_id.strip().lower()
    if lang not in _TONAL_LANGS:
        raise ToneProxyError("LANGUAGE_NOT_TONAL", f"{language_id} is not a tonal TTS gate language")
    expected = normalize_tone_pattern(tone_pattern)
    if len(f0_hz) != len(expected):
        raise ToneProxyError(
            "F0_SYLLABLE_COUNT",
            f"expected {len(expected)} syllable F0 values, got {len(f0_hz)}",
        )
    observed = f0_to_relative_levels(f0_hz, language_id=lang)
    allowed = _HA_LEVELS if lang == "ha" else _HML
    for label in expected:
        if label not in allowed:
            raise ToneProxyError("TONE_PATTERN_INVALID", f"unsupported tone label {label!r} for {lang}")
    matched = expected == observed
    return ToneProxyResult(expected=expected, observed=observed, matched=matched)


def assert_tone_proxy(
    tone_pattern: Sequence[str] | str,
    f0_hz: Sequence[float],
    *,
    language_id: str = "yo",
) -> ToneProxyResult:
    result = compare_f0_to_tone_pattern(tone_pattern, f0_hz, language_id=language_id)
    if not result.matched:
        raise ToneProxyError(
            "F0_TONE_MISMATCH",
            f"expected {result.expected}, observed {result.observed}",
        )
    return result


def gate_result_payload(result: ToneProxyResult) -> dict[str, Any]:
    return {
        "card_id": CARD_ID,
        "kind": "f0_tone_proxy",
        "expected": list(result.expected),
        "observed": list(result.observed),
        "matched": result.matched,
    }

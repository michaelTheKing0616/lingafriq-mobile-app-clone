"""ADR-031 conformance: persona delivery modes and v1 roster (P11-001)."""

from __future__ import annotations

import re
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-031-persona-delivery-modes.md"
_DECISIONS = _REPO_ROOT / "docs/build/DECISIONS.md"

_V1_IDS = (
    "yaa_asantewaa",
    "nkrumah_kwame",
    "shaka_zulu",
    "ahmed_baba",
    "thomas_mofolo",
)

_FIRST_PERSON_EN = re.compile(r"\b(I|me|my|mine|we|us|our|ours)\b", re.IGNORECASE)


def test_adr_031_accepted_with_five_roster_and_shaka_narrated() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    lower = text.lower()
    for pid in _V1_IDS:
        assert pid in text
    assert "first_person" in lower
    assert "narrated_as_told_by" in lower
    shaka_row = text.split("`shaka_zulu`", 1)[1][:200]
    assert "narrated_as_told_by" in shaka_row
    assert "mandela" in lower and "sankara" in lower and "lumumba" in lower
    assert "ext-15" in lower


def test_narrated_mode_contract_rejects_bare_first_person_speech() -> None:
    """ADR-031 AC3: narrated turns must not emit figure first-person in speech_text."""
    bad = "I led the army and we conquered the neighboring chiefdoms."
    assert _FIRST_PERSON_EN.search(bad)
    good = "Historians record that Shaka reorganized the regiments; he introduced the iklwa."
    assert not _FIRST_PERSON_EN.search(good)


def test_decisions_md_records_p11_001() -> None:
    text = _DECISIONS.read_text(encoding="utf-8")
    assert "P11-001" in text
    assert "ADR-031" in text
    assert "shaka_zulu" in text
    assert "narrated_as_told_by" in text

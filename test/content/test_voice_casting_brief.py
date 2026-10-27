"""P11-022: persona voice casting brief (EP-§8.4-01…03)."""

from __future__ import annotations

import re
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_BRIEF = _REPO_ROOT / "docs/build/personas/voice_casting_brief.md"
_ARB = _REPO_ROOT / "lib/l10n/app_en.arb"

_V1_IDS = (
    "yaa_asantewaa",
    "nkrumah_kwame",
    "shaka_zulu",
    "ahmed_baba",
    "thomas_mofolo",
)


def _table_rows_after(header_marker: str, text: str) -> list[str]:
    idx = text.index(header_marker)
    chunk = text[idx:]
    lines = chunk.splitlines()
    rows: list[str] = []
    in_table = False
    for line in lines:
        if line.startswith("| `persona_id`"):
            in_table = True
            continue
        if not in_table:
            continue
        if not line.startswith("|"):
            break
        if line.startswith("| ---"):
            continue
        rows.append(line)
    return rows


def test_brief_lists_five_personas_with_language_accent_and_voice_actor() -> None:
    text = _BRIEF.read_text(encoding="utf-8")
    assert "Accepted" in text and "P11-022" in text
    rows = _table_rows_after("| `persona_id` |", text)
    assert len(rows) == 5
    for pid in _V1_IDS:
        row = next(r for r in rows if f"`{pid}`" in r)
        cells = [c.strip() for c in row.split("|")[1:-1]]
        assert len(cells) >= 5
        language, accent, voice_actor = cells[1], cells[2], cells[3]
        assert language and accent and voice_actor
        assert re.search(r"[a-z]{2}", language.lower())


def test_clone_requires_consent_and_licence_or_reject() -> None:
    text = _BRIEF.read_text(encoding="utf-8").lower()
    assert "consent" in text and "licence" in text
    assert "reject" in text
    assert "licence_register.csv" in text


def test_synthesised_label_matches_p11_007_arb_key() -> None:
    brief = _BRIEF.read_text(encoding="utf-8")
    arb = _ARB.read_text(encoding="utf-8")
    assert "personaVoiceSynthesised" in brief
    assert "PersonaSynthVoiceLabel" in brief
    m = re.search(r'"personaVoiceSynthesised":\s*"([^"]+)"', arb)
    assert m
    assert m.group(1) in brief


def test_casting_slot_ids_unique() -> None:
    text = _BRIEF.read_text(encoding="utf-8")
    slots = set(re.findall(r"CAST-[A-Z]+-01", text))
    assert slots == {
        "CAST-YAA-01",
        "CAST-NKR-01",
        "CAST-SHA-01",
        "CAST-AHB-01",
        "CAST-MOF-01",
    }

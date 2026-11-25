"""ADR-030 conformance: CharacterVM expression enum (P11-029)."""

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-030-character-vm.md"

_EXPRESSIONS = (
    "neutral",
    "happy",
    "proud",
    "curious",
    "concerned",
    "surprised",
    "thinking",
    "encouraging",
    "playful",
    "focused",
)


def test_adr_030_accepted_union_enum_and_rive_vm() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text and "2026-10-27" in text
    assert "C5" in text
    for expr in _EXPRESSIONS:
        assert f"`{expr}`" in text
    lower = text.lower()
    assert "gazex" in lower.replace(" ", "") or "gazeX" in text
    assert "data-binding view model" in lower or "data-binding View Model" in text
    assert "smi" in lower

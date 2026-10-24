"""pcm, sw, zu and xh language kits (CURRICULUM §3.1 / §3.3)."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest
import yaml

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.kits.kit_schema import (  # noqa: E402
    REQUIRED_SECTIONS,
    KitError,
    validate_kit,
)

_KITS = Path(__file__).resolve().parents[1] / "kits"
_LANGS = ("pcm", "sw", "zu", "xh")
_CONCORD_SLOTS = ("subject", "object", "adjectival", "relative", "possessive")
_BANTU_CLASSES = list(range(1, 16))


def _read_kit(language: str) -> dict[str, Any]:
    path = _KITS / language / "kit.yaml"
    with path.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise AssertionError(f"{language} kit.yaml must be a mapping")
    return data


@pytest.mark.parametrize("language", _LANGS)
def test_kit_passes_validate_kit(language: str) -> None:
    validated = validate_kit(_read_kit(language))
    assert validated["nfc"] == "NFC"
    assert validated["character_set"] == ["Latin"]


@pytest.mark.parametrize("language", ("sw", "zu", "xh"))
def test_noun_class_and_five_concord_slots(language: str) -> None:
    kit = validate_kit(_read_kit(language))
    assert kit["noun_class"]
    concord = kit["concord"]
    for slot in _CONCORD_SLOTS:
        assert slot in concord
        assert concord[slot]


def test_sw_pairs_are_m_wa_and_ki_vi() -> None:
    kit = validate_kit(_read_kit("sw"))
    assert kit["noun_class"]["pairs"] == ["m/wa", "ki/vi"]


@pytest.mark.parametrize("language", ("zu", "xh"))
def test_zu_xh_classes_1_to_15_prefixes_not_enumerated(language: str) -> None:
    kit = validate_kit(_read_kit(language))
    assert kit["noun_class"]["classes"] == _BANTU_CLASSES
    assert kit["noun_class"]["prefixes"] == "not enumerated in §3.3"


@pytest.mark.parametrize("language", ("zu", "xh"))
def test_zu_xh_writing_is_conjunctive(language: str) -> None:
    kit = validate_kit(_read_kit(language))
    assert kit["writing"] == "conjunctive"


def test_pcm_tone_marking_scientific_use() -> None:
    kit = validate_kit(_read_kit("pcm"))
    assert kit["tone_marking"] == "marked only in scientific use"


def test_pcm_nla_normalisation_reference_without_table() -> None:
    kit = validate_kit(_read_kit("pcm"))
    nla = kit["nla_normalisation"]
    assert "Naija Langwej Akademi" in nla["reference"]
    assert nla["table_included"] is False


_EMPTY_SECTION: dict[str, Any] = {
    "character_set": [],
    "nfc": "",
    "tone_marking": "",
    "phone_inventory": [],
    "g2p": {},
    "noun_class": {},
    "concord": {},
    "dialect": "",
    "honorifics": {},
}


@pytest.mark.parametrize("key", REQUIRED_SECTIONS)
def test_deleting_required_section_raises_kit_section_missing(key: str) -> None:
    data = dict(_read_kit("sw"))
    del data[key]
    with pytest.raises(KitError) as exc_info:
        validate_kit(data)
    assert exc_info.value.code == "KIT_SECTION_MISSING"


@pytest.mark.parametrize("key", REQUIRED_SECTIONS)
def test_empty_required_section_raises_kit_section_missing(key: str) -> None:
    data = dict(_read_kit("sw"))
    data[key] = _EMPTY_SECTION[key]
    with pytest.raises(KitError) as exc_info:
        validate_kit(data)
    assert exc_info.value.code == "KIT_SECTION_MISSING"


@pytest.mark.parametrize("language", _LANGS)
def test_linguist_signoff_false(language: str) -> None:
    kit = validate_kit(_read_kit(language))
    assert kit["linguist_signoff"] is False


def _tool_enabled(kit: dict[str, Any], name: str) -> bool:
    if kit.get(name) is True:
        return True
    node = kit.get(name)
    if isinstance(node, dict) and node.get("enabled") is True:
        return True
    tools = kit.get("tools")
    if isinstance(tools, dict):
        entry = tools.get(name)
        if entry is True:
            return True
        if isinstance(entry, dict) and entry.get("enabled") is True:
            return True
    if isinstance(tools, list):
        for row in tools:
            if isinstance(row, dict) and str(row.get("id", "")).lower() == name:
                if row.get("enabled") is True:
                    return True
    return False


@pytest.mark.parametrize("language", _LANGS)
def test_no_kit_enables_intron_or_zulmorph(language: str) -> None:
    kit = validate_kit(_read_kit(language))
    assert _tool_enabled(kit, "intron") is False
    assert _tool_enabled(kit, "zulmorph") is False

"""P13-002 Lanfrica discovery worksheet and FSI / Peace Corps cross-check."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from scripts.content.lanfrica_discovery import (  # noqa: E402
    CARD_ID,
    LanfricaDiscoveryError,
    build_worksheet,
    cross_check_fsi,
    cross_check_peace_corps,
    generate_worksheet,
    parse_lanfrica_payload,
)

_FIXTURE_PAYLOAD = {
    "results": [
        {
            "title": "Yoruba speech corpus sample",
            "url": "https://example.org/datasets/yo-corpus",
            "licence": "CC BY 4.0",
            "resource_type": "corpus",
        },
        {
            "title": "Yoruba lexicon extract",
            "url": "https://example.org/datasets/yo-lex",
            "licence": "CC BY-SA 4.0",
            "resource_type": "lexicon",
        },
    ]
}


def test_parse_lanfrica_payload_requires_fields() -> None:
    rows = parse_lanfrica_payload(_FIXTURE_PAYLOAD)
    assert len(rows) == 2
    assert rows[0]["title"].startswith("Yoruba")


def test_worksheet_lists_discovered_unverified_sources() -> None:
    sheet = generate_worksheet("yo", "Yoruba", fetcher=lambda _lang: _FIXTURE_PAYLOAD)
    assert sheet["card_id"] == CARD_ID
    assert sheet["discovery_only"] is True
    assert sheet["lanfrica_status"] == "discovered_unverified"
    assert len(sheet["sources"]) == 2
    first = sheet["sources"][0]
    assert first["verification"] == "discovered_unverified"
    assert first["link"].startswith("https://")
    assert first["licence"]
    assert first["resource_type"] == "corpus"


@pytest.mark.parametrize(
    ("language_id", "fsi", "peace"),
    [
        ("yo", "yes", "yes"),
        ("ig", "yes", "no"),
        ("zu", "no", "yes"),
        ("ff", "no", "no"),
    ],
)
def test_cross_checks(language_id: str, fsi: str, peace: str) -> None:
    assert cross_check_fsi(language_id) == fsi
    assert cross_check_peace_corps(language_id) == peace


def test_each_source_carries_cross_check_fields() -> None:
    sheet = generate_worksheet("ig", "Igbo", fetcher=lambda _lang: _FIXTURE_PAYLOAD)
    assert sheet["cross_check"]["fsi_language_listed"] == "yes"
    assert sheet["cross_check"]["peace_corps_language_listed"] == "no"
    for row in sheet["sources"]:
        assert row["fsi_language_listed"] == "yes"
        assert row["peace_corps_language_listed"] == "no"


def test_unreachable_lanfrica_fails_loud_without_sources() -> None:
    def _boom(_lang: str) -> dict[str, object]:
        raise LanfricaDiscoveryError("LANFRICA_UNREACHABLE", "offline")

    with pytest.raises(LanfricaDiscoveryError) as exc:
        generate_worksheet("yo", "Yoruba", fetcher=_boom)
    assert exc.value.code == "LANFRICA_UNREACHABLE"


def test_invalid_payload_does_not_emit_worksheet_sources() -> None:
    with pytest.raises(LanfricaDiscoveryError) as exc:
        parse_lanfrica_payload({"results": [{"title": "only title"}]})
    assert exc.value.code == "LANFRICA_RESPONSE_INVALID"


def test_empty_fixture_still_emits_worksheet_with_no_fabricated_rows() -> None:
    sheet = build_worksheet("ff", "Fulfulde", resources=[])
    assert sheet["sources"] == []
    assert sheet["cross_check"]["fsi_language_listed"] == "no"
    dumped = json.dumps(sheet)
    assert "fabricated" not in dumped.lower()

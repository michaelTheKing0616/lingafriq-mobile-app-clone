"""P5-063 licensed human audio registry tests."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.audio.licensed_audio_register import (  # noqa: E402
    CARD_ID,
    LicenceUnregistered,
    LicensedAudioError,
    assert_registered_licence,
    build_document,
    canonical_pools,
    default_register_csv,
    validate_pool_dict,
    write_registry,
)
from tools.content_engine.licences.register_schema import load_register_csv  # noqa: E402


@pytest.fixture()
def register_rows() -> list[dict[str, str]]:
    return load_register_csv(default_register_csv())


def test_card_id() -> None:
    assert CARD_ID == "P5-063"


def test_fsi_pools_public_domain_dated_tone_drills(register_rows: list[dict[str, str]]) -> None:
    pools = canonical_pools(register_rows)
    fsi = [p for p in pools if p.provider == "fsi_tapes"]
    assert len(fsi) == 3
    for pool in fsi:
        assert pool.licence == "public-domain"
        assert pool.quality == "dated"
        assert "tone_drills" in pool.allowed_use


def test_cv_and_fleurs_own_sentences_only(register_rows: list[dict[str, str]]) -> None:
    pools = canonical_pools(register_rows)
    scoped = [p for p in pools if p.provider in ("common_voice", "fleurs")]
    assert len(scoped) == 6
    for pool in scoped:
        assert pool.text_scope == "own_sentences_only"


def test_missing_licence_id_raises(register_rows: list[dict[str, str]]) -> None:
    with pytest.raises(LicenceUnregistered) as exc:
        validate_pool_dict({"provider": "fsi_tapes", "pool_id": "x"}, register_rows)
    assert exc.value.code == "LicenceUnregistered"
    with pytest.raises(LicenceUnregistered):
        assert_registered_licence("", register_rows)
    with pytest.raises(LicenceUnregistered):
        assert_registered_licence("not-a-real-licence", register_rows)


def test_build_document_covers_yo_ig_ha(register_rows: list[dict[str, str]]) -> None:
    doc = build_document(register_rows)
    assert set(doc["languages"]) == {"yo", "ig", "ha"}
    assert len(doc["languages"]["yo"]) == 3


def test_write_registry_round_trip(tmp_path: Path, register_rows: list[dict[str, str]]) -> None:
    out = tmp_path / "licensed_human.json"
    write_registry(out, register_rows)
    assert out.is_file()
    payload = out.read_text(encoding="utf-8")
    assert "fsi-yoruba-tapes" in payload
    assert "own_sentences_only" in payload


def test_fsi_wrong_scope_raises(register_rows: list[dict[str, str]]) -> None:
    bad = {
        "pool_id": "bad",
        "provider": "fsi_tapes",
        "licence_id": "fsi-yoruba",
        "licence": "public-domain",
        "quality": "dated",
        "allowed_use": ["tone_drills"],
        "text_scope": "own_sentences_only",
    }
    with pytest.raises(LicensedAudioError) as exc:
        validate_pool_dict(bad, register_rows)
    assert exc.value.code == "FSI_SCOPE_INVALID"

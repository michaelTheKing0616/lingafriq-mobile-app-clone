"""Signed semver content packs with hash filenames (P4-105)."""

from __future__ import annotations

import json
import sys
import unicodedata
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.pack_builder import (  # noqa: E402
    LEGACY_BUNDLE_DIRS,
    PackBlobInput,
    PackBuildError,
    PackObjectInput,
    apply_pack_diff,
    assert_nfc_normalized,
    blob_storage_name,
    build_pack,
    diff_manifests,
    suggest_semver_bump,
    verify_built_pack,
)
from tools.content_pipeline.pack_signing import (  # noqa: E402
    PackSigningError,
    verify_pack_signature,
)

_FIXTURE_SEED = "11" * 32


def _sample_object(lemma: str = "ọkọ̀") -> dict:
    return {
        "id": "yo.lex.oko.vehicle",
        "lemma": lemma,
        "label": "beta",
        "provenance": {
            "author": "pack-test",
            "created_at": "2026-10-26T00:00:00Z",
            "ai_assisted": False,
            "sources": [
                {
                    "name": "fixture",
                    "licence": "CC0",
                    "uri_or_citation": "fixture",
                    "retrieved_at": "2026-10-26",
                }
            ],
        },
        "claims": [],
        "confidence": 0.5,
        "risk_tags": [],
        "audio": [],
    }


def test_pack_builder_semver_manifest_signature_and_legacy_replacement() -> None:
    pack = build_pack(
        "1.0.0",
        [PackObjectInput("yo.lex.oko.vehicle", "lexeme", _sample_object())],
        [PackBlobInput(b"\x00audio-bytes", "ogg")],
        built_at="2026-10-26T12:00:00Z",
        signing_seed_hex=_FIXTURE_SEED,
    )
    assert pack.manifest["version"] == "1.0.0"
    assert pack.manifest["replaces_legacy_bundles"] == list(LEGACY_BUNDLE_DIRS)
    assert len(pack.manifest["objects"]) == 1
    assert verify_built_pack(pack) is None
    assert verify_pack_signature(pack.manifest, pack.signature, pack.public_key) is None


def test_blob_filename_is_ascii_content_hash_only() -> None:
    name = blob_storage_name(b"fixture", "ogg")
    assert name.endswith(".ogg")
    assert "ọ" not in name
    assert len(name.split(".", 1)[0]) == 64


def test_nfc_violation_fails_build() -> None:
    nfd = unicodedata.normalize("NFD", "ọkọ̀")
    with pytest.raises(PackBuildError) as exc:
        assert_nfc_normalized({"lemma": nfd})
    assert exc.value.code == "NFC_VIOLATION"


def test_tampered_signature_fails_PACK_SIGNATURE_INVALID() -> None:
    pack = build_pack(
        "1.0.0",
        [PackObjectInput("yo.lex.oko.vehicle", "lexeme", _sample_object())],
        [],
        built_at="2026-10-26T12:00:00Z",
        signing_seed_hex=_FIXTURE_SEED,
    )
    err = verify_pack_signature(pack.manifest, "AAAA", pack.public_key)
    assert isinstance(err, PackSigningError)
    assert err.code == "PACK_SIGNATURE_INVALID"


def test_diff_apply_round_trip_byte_identical() -> None:
    old_pack = build_pack(
        "1.0.0",
        [PackObjectInput("yo.lex.oko.vehicle", "lexeme", _sample_object("ọkọ̀"))],
        [PackBlobInput(b"audio-v1", "ogg")],
        built_at="2026-10-26T12:00:00Z",
        signing_seed_hex=_FIXTURE_SEED,
    )
    new_pack = build_pack(
        "1.0.1",
        [PackObjectInput("yo.lex.oko.vehicle", "lexeme", _sample_object("ab"))],
        [PackBlobInput(b"audio-v2", "ogg")],
        built_at="2026-10-26T12:01:00Z",
        signing_seed_hex=_FIXTURE_SEED,
    )
    diff = diff_manifests(old_pack.manifest, new_pack.manifest)
    merged = apply_pack_diff(old_pack.files, diff, new_pack.files)
    content_paths = {
        path: data
        for path, data in new_pack.files.items()
        if path not in ("manifest.json", "signature.txt")
    }
    for path, data in content_paths.items():
        assert merged[path] == data


def test_semver_bump_rules() -> None:
    base = build_pack(
        "1.0.0",
        [PackObjectInput("yo.lex.a", "lexeme", _sample_object("a"))],
        [],
        built_at="2026-10-26T12:00:00Z",
        signing_seed_hex=_FIXTURE_SEED,
    )
    patch = build_pack(
        "1.0.1",
        [PackObjectInput("yo.lex.a", "lexeme", _sample_object("b"))],
        [],
        built_at="2026-10-26T12:01:00Z",
        signing_seed_hex=_FIXTURE_SEED,
    )
    minor = build_pack(
        "1.1.0",
        [
            PackObjectInput("yo.lex.a", "lexeme", _sample_object("b")),
            PackObjectInput("yo.lex.b", "lexeme", _sample_object("c")),
        ],
        [],
        built_at="2026-10-26T12:02:00Z",
        signing_seed_hex=_FIXTURE_SEED,
    )
    major = build_pack(
        "2.0.0",
        [PackObjectInput("yo.lex.c", "lexeme", _sample_object("d"))],
        [],
        built_at="2026-10-26T12:03:00Z",
        signing_seed_hex=_FIXTURE_SEED,
    )
    assert suggest_semver_bump(base.manifest, patch.manifest) == "patch"
    assert suggest_semver_bump(base.manifest, minor.manifest) == "minor"
    assert suggest_semver_bump(base.manifest, major.manifest) == "major"


def test_pack_manifest_schema_loads() -> None:
    schema_path = _REPO_ROOT / "schemas" / "v2" / "content" / "pack_manifest.schema.json"
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    assert schema["properties"]["format"]["const"] == "lingafriq.content_pack.v2"
